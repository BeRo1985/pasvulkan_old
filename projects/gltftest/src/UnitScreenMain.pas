unit UnitScreenMain;
{$ifdef fpc}
 {$mode delphi}
 {$ifdef cpu386}
  {$asmmode intel}
 {$endif}
 {$ifdef cpuamd64}
  {$asmmode intel}
 {$endif}
{$else}
 {$ifdef conditionalexpressions}
  {$if CompilerVersion>=24.0}
   {$legacyifend on}
  {$ifend}
 {$endif}
{$endif}
{$if defined(Win32) or defined(Win64)}
 {$define Windows}
{$ifend}

interface

uses SysUtils,
     Classes,
     Math,
     Vulkan,
     PasMP,
     PasVulkan.Types,
     PasVulkan.Math,
     PasVulkan.Framework,
     PasVulkan.Application,
     PasVulkan.Resources,
     PasVulkan.FrameGraph,
     PasVulkan.Scene3D,
     UnitSkyCubeMap,
     UnitGGXBRDF,
     UnitGGXEnvMapCubeMap,
     UnitCharlieBRDF,
     UnitCharlieEnvMapCubeMap,
     UnitLambertianEnvMapCubeMap,
     UnitSkyBox,
     UnitOrderIndependentTransparencyBuffer,
     UnitOrderIndependentTransparencyImage;

type { TScreenMain }
     TScreenMain=class(TpvApplicationScreen)
      public
        const CascadedShadowMapWidth=512;
              CascadedShadowMapHeight=512;
              CountCascadedShadowMapCascades=4;
              CountOrderIndependentTransparencyLayers=8;
        type { TCascadedShadowMap }
             TCascadedShadowMap=record
              public
               View:TpvScene3D.TView;
               CombinedMatrix:TpvMatrix4x4;
               SplitDepths:TpvVector3;
               Scales:TpvVector2;
             end;
             { TOrderIndependentTransparentViewPort }
             TOrderIndependentTransparentViewPort=packed record
              x:TpvInt32;
              y:TpvInt32;
              z:TpvInt32;
              w:TpvInt32;
             end;
             { TOrderIndependentTransparentUniformBuffer }
             TOrderIndependentTransparentUniformBuffer=packed record
              ViewPort:TOrderIndependentTransparentViewPort;
             end;
             PCascadedShadowMap=^TCascadedShadowMap;
             TCascadedShadowMaps=array[0..CountCascadedShadowMapCascades-1] of TCascadedShadowMap;
             PCascadedShadowMaps=^TCascadedShadowMaps;
             TSwapChainImageCascadedShadowMaps=array[0..MaxSwapChainImages-1] of TCascadedShadowMaps;
             TCascadedShadowMapUniformBuffer=packed record
              Matrices:array[0..CountCascadedShadowMapCascades-1] of TpvMatrix4x4;
              SplitDepths:array[0..CountCascadedShadowMapCascades-1] of TpvVector4; // actually TpvVector2 but because of alignment it is a TpvVector4 here
             end;
             PCascadedShadowMapUniformBuffer=^TCascadedShadowMapUniformBuffer;
             TCascadedShadowMapUniformBuffers=array[0..MaxSwapChainImages-1] of TCascadedShadowMapUniformBuffer;
             TCascadedShadowMapVulkanUniformBuffers=array[0..MaxSwapChainImages-1] of TpvVulkanBuffer;
             { TCascadedShadowMapRenderPass }
             TCascadedShadowMapRenderPass=class(TpvFrameGraph.TRenderPass)
              public
               fVulkanRenderPass:TpvVulkanRenderPass;
               fParent:TScreenMain;
               fResourceDepth:TpvFrameGraph.TPass.TUsedImageResource;
               fVulkanGraphicsCommandBuffer:TpvVulkanCommandBuffer;
               fVulkanGraphicsCommandBufferFence:TpvVulkanFence;
               fVulkanTransferCommandBuffer:TpvVulkanCommandBuffer;
               fVulkanTransferCommandBufferFence:TpvVulkanFence;
               fMeshVertexShaderModule:TpvVulkanShaderModule;
               fMeshFragmentShaderModule:TpvVulkanShaderModule;
               fMeshMaskedFragmentShaderModule:TpvVulkanShaderModule;
               fVulkanPipelineShaderStageMeshVertex:TpvVulkanPipelineShaderStage;
               fVulkanPipelineShaderStageMeshFragment:TpvVulkanPipelineShaderStage;
               fVulkanPipelineShaderStageMeshMaskedFragment:TpvVulkanPipelineShaderStage;
               fVulkanGraphicsPipelines:array[TpvScene3D.TMaterial.TAlphaMode] of TpvScene3D.TGraphicsPipelines;
               fVulkanPipelineLayout:TpvVulkanPipelineLayout;
               constructor Create(const aFrameGraph:TpvFrameGraph;const aParent:TScreenMain); reintroduce;
               destructor Destroy; override;
               procedure Show; override;
               procedure Hide; override;
               procedure AfterCreateSwapChain; override;
               procedure BeforeDestroySwapChain; override;
               procedure Update(const aUpdateSwapChainImageIndex,aUpdateFrameIndex:TpvSizeInt); override;
               procedure Execute(const aCommandBuffer:TpvVulkanCommandBuffer;const aSwapChainImageIndex,aFrameIndex:TpvSizeInt); override;
             end;
             { TCascadedShadowMapResolveRenderPass }
             TCascadedShadowMapResolveRenderPass=class(TpvFrameGraph.TRenderPass)
               private
                type TFragmentStagePushConstants=record
                      CountSamples:Int32;
                     end;
               private
                fParent:TScreenMain;
                fVulkanRenderPass:TpvVulkanRenderPass;
                fResourceInput:TpvFrameGraph.TPass.TUsedImageResource;
                fResourceOutput:TpvFrameGraph.TPass.TUsedImageResource;
                fVulkanSampler:TpvVulkanSampler;
                fVulkanTransferCommandBuffer:TpvVulkanCommandBuffer;
                fVulkanTransferCommandBufferFence:TpvVulkanFence;
                fVulkanVertexShaderModule:TpvVulkanShaderModule;
                fVulkanFragmentShaderModule:TpvVulkanShaderModule;
                fVulkanPipelineShaderStageVertex:TpvVulkanPipelineShaderStage;
                fVulkanPipelineShaderStageFragment:TpvVulkanPipelineShaderStage;
                fVulkanGraphicsPipeline:TpvVulkanGraphicsPipeline;
                fVulkanDescriptorPool:TpvVulkanDescriptorPool;
                fVulkanDescriptorSetLayout:TpvVulkanDescriptorSetLayout;
                fVulkanDescriptorSets:array[0..MaxSwapChainImages-1] of TpvVulkanDescriptorSet;
                fVulkanPipelineLayout:TpvVulkanPipelineLayout;
                fFragmentStagePushConstants:TFragmentStagePushConstants;
               public
                constructor Create(const aFrameGraph:TpvFrameGraph;const aParent:TScreenMain); reintroduce;
                destructor Destroy; override;
                procedure Show; override;
                procedure Hide; override;
                procedure AfterCreateSwapChain; override;
                procedure BeforeDestroySwapChain; override;
                procedure Update(const aUpdateSwapChainImageIndex,aUpdateFrameIndex:TpvSizeInt); override;
                procedure Execute(const aCommandBuffer:TpvVulkanCommandBuffer;const aSwapChainImageIndex,aFrameIndex:TpvSizeInt); override;
             end;
             { TCascadedShadowMapBlurRenderPass }
             TCascadedShadowMapBlurRenderPass=class(TpvFrameGraph.TRenderPass)
               private
                type TFragmentStagePushConstants=record
                      Direction:TpvVector4;
                     end;
               private
                fParent:TScreenMain;
                fVulkanRenderPass:TpvVulkanRenderPass;
                fResourceInput:TpvFrameGraph.TPass.TUsedImageResource;
                fResourceOutput:TpvFrameGraph.TPass.TUsedImageResource;
                fVulkanSampler:TpvVulkanSampler;
                fVulkanTransferCommandBuffer:TpvVulkanCommandBuffer;
                fVulkanTransferCommandBufferFence:TpvVulkanFence;
                fVulkanVertexShaderModule:TpvVulkanShaderModule;
                fVulkanFragmentShaderModule:TpvVulkanShaderModule;
                fVulkanPipelineShaderStageVertex:TpvVulkanPipelineShaderStage;
                fVulkanPipelineShaderStageFragment:TpvVulkanPipelineShaderStage;
                fVulkanGraphicsPipeline:TpvVulkanGraphicsPipeline;
                fVulkanDescriptorPool:TpvVulkanDescriptorPool;
                fVulkanDescriptorSetLayout:TpvVulkanDescriptorSetLayout;
                fVulkanDescriptorSets:array[0..MaxSwapChainImages-1] of TpvVulkanDescriptorSet;
                fVulkanPipelineLayout:TpvVulkanPipelineLayout;
                fFragmentStagePushConstants:TFragmentStagePushConstants;
               public
                constructor Create(const aFrameGraph:TpvFrameGraph;const aParent:TScreenMain;const aHorziontal:boolean); reintroduce;
                destructor Destroy; override;
                procedure Show; override;
                procedure Hide; override;
                procedure AfterCreateSwapChain; override;
                procedure BeforeDestroySwapChain; override;
                procedure Update(const aUpdateSwapChainImageIndex,aUpdateFrameIndex:TpvSizeInt); override;
                procedure Execute(const aCommandBuffer:TpvVulkanCommandBuffer;const aSwapChainImageIndex,aFrameIndex:TpvSizeInt); override;
             end;
             { TForwardRenderPass }
             TForwardRenderPass=class(TpvFrameGraph.TRenderPass)
              public
               fVulkanRenderPass:TpvVulkanRenderPass;
               fParent:TScreenMain;
               fResourceCascadedShadowMap:TpvFrameGraph.TPass.TUsedImageResource;
               fResourceColor:TpvFrameGraph.TPass.TUsedImageResource;
               fResourceDepth:TpvFrameGraph.TPass.TUsedImageResource;
               fVulkanGraphicsCommandBuffer:TpvVulkanCommandBuffer;
               fVulkanGraphicsCommandBufferFence:TpvVulkanFence;
               fVulkanTransferCommandBuffer:TpvVulkanCommandBuffer;
               fVulkanTransferCommandBufferFence:TpvVulkanFence;
               fMeshVertexShaderModule:TpvVulkanShaderModule;
               fMeshFragmentShaderModule:TpvVulkanShaderModule;
               fMeshMaskedFragmentShaderModule:TpvVulkanShaderModule;
               fMeshDepthFragmentShaderModule:TpvVulkanShaderModule;
               fMeshDepthMaskedFragmentShaderModule:TpvVulkanShaderModule;
               fGlobalVulkanDescriptorSetLayout:TpvVulkanDescriptorSetLayout;
               fGlobalVulkanDescriptorPool:TpvVulkanDescriptorPool;
               fGlobalVulkanDescriptorSets:array[0..MaxSwapChainImages-1] of TpvVulkanDescriptorSet;
               fVulkanCascadedShadowMapSampler:TpvVulkanSampler;
               fVulkanPipelineShaderStageMeshVertex:TpvVulkanPipelineShaderStage;
               fVulkanPipelineShaderStageMeshFragment:TpvVulkanPipelineShaderStage;
               fVulkanPipelineShaderStageMeshMaskedFragment:TpvVulkanPipelineShaderStage;
               fVulkanPipelineShaderStageMeshDepthFragment:TpvVulkanPipelineShaderStage;
               fVulkanPipelineShaderStageMeshDepthMaskedFragment:TpvVulkanPipelineShaderStage;
               fVulkanGraphicsPipelines:array[boolean,TpvScene3D.TMaterial.TAlphaMode] of TpvScene3D.TGraphicsPipelines;
               fVulkanPipelineLayout:TpvVulkanPipelineLayout;
               fSkyBox:TSkyBox;
               constructor Create(const aFrameGraph:TpvFrameGraph;const aParent:TScreenMain); reintroduce;
               destructor Destroy; override;
               procedure Show; override;
               procedure Hide; override;
               procedure AfterCreateSwapChain; override;
               procedure BeforeDestroySwapChain; override;
               procedure Update(const aUpdateSwapChainImageIndex,aUpdateFrameIndex:TpvSizeInt); override;
               procedure Execute(const aCommandBuffer:TpvVulkanCommandBuffer;const aSwapChainImageIndex,aFrameIndex:TpvSizeInt); override;
             end;
             { TOrderIndependentTransparencyClearCustomPass }
             TOrderIndependentTransparencyClearCustomPass=class(TpvFrameGraph.TCustomPass)
              private
               fParent:TScreenMain;
              public
               constructor Create(const aFrameGraph:TpvFrameGraph;const aParent:TScreenMain); reintroduce;
               destructor Destroy; override;
               procedure Show; override;
               procedure Hide; override;
               procedure AfterCreateSwapChain; override;
               procedure BeforeDestroySwapChain; override;
               procedure Update(const aUpdateSwapChainImageIndex,aUpdateFrameIndex:TpvSizeInt); override;
               procedure Execute(const aCommandBuffer:TpvVulkanCommandBuffer;const aSwapChainImageIndex,aFrameIndex:TpvSizeInt); override;
             end;
             { TOrderIndependentTransparencyRenderPass }
             TOrderIndependentTransparencyRenderPass=class(TpvFrameGraph.TRenderPass)
              private
               fVulkanRenderPass:TpvVulkanRenderPass;
               fParent:TScreenMain;
               fResourceCascadedShadowMap:TpvFrameGraph.TPass.TUsedImageResource;
               fResourceDepth:TpvFrameGraph.TPass.TUsedImageResource;
               fResourceColor:TpvFrameGraph.TPass.TUsedImageResource;
               fVulkanGraphicsCommandBuffer:TpvVulkanCommandBuffer;
               fVulkanGraphicsCommandBufferFence:TpvVulkanFence;
               fVulkanTransferCommandBuffer:TpvVulkanCommandBuffer;
               fVulkanTransferCommandBufferFence:TpvVulkanFence;
               fMeshVertexShaderModule:TpvVulkanShaderModule;
               fMeshFragmentShaderModule:TpvVulkanShaderModule;
               fMeshMaskedFragmentShaderModule:TpvVulkanShaderModule;
               fGlobalVulkanDescriptorSetLayout:TpvVulkanDescriptorSetLayout;
               fGlobalVulkanDescriptorPool:TpvVulkanDescriptorPool;
               fGlobalVulkanDescriptorSets:array[0..MaxSwapChainImages-1] of TpvVulkanDescriptorSet;
               fVulkanCascadedShadowMapSampler:TpvVulkanSampler;
               fVulkanPipelineShaderStageMeshVertex:TpvVulkanPipelineShaderStage;
               fVulkanPipelineShaderStageMeshFragment:TpvVulkanPipelineShaderStage;
               fVulkanPipelineShaderStageMeshMaskedFragment:TpvVulkanPipelineShaderStage;
               fVulkanGraphicsPipelines:array[TpvScene3D.TMaterial.TAlphaMode] of TpvScene3D.TGraphicsPipelines;
               fVulkanPipelineLayout:TpvVulkanPipelineLayout;
               constructor Create(const aFrameGraph:TpvFrameGraph;const aParent:TScreenMain); reintroduce;
               destructor Destroy; override;
               procedure Show; override;
               procedure Hide; override;
               procedure AfterCreateSwapChain; override;
               procedure BeforeDestroySwapChain; override;
               procedure Update(const aUpdateSwapChainImageIndex,aUpdateFrameIndex:TpvSizeInt); override;
               procedure Execute(const aCommandBuffer:TpvVulkanCommandBuffer;const aSwapChainImageIndex,aFrameIndex:TpvSizeInt); override;
             end;
             { TOrderIndependentTransparencyResolveRenderPass }
             TOrderIndependentTransparencyResolveRenderPass=class(TpvFrameGraph.TRenderPass)
               private
                fParent:TScreenMain;
                fVulkanRenderPass:TpvVulkanRenderPass;
                fResourceOpaque:TpvFrameGraph.TPass.TUsedImageResource;
                fResourceTransparent:TpvFrameGraph.TPass.TUsedImageResource;
                fResourceSurface:TpvFrameGraph.TPass.TUsedImageResource;
                fVulkanTransferCommandBuffer:TpvVulkanCommandBuffer;
                fVulkanTransferCommandBufferFence:TpvVulkanFence;
                fVulkanVertexShaderModule:TpvVulkanShaderModule;
                fVulkanFragmentShaderModule:TpvVulkanShaderModule;
                fVulkanPipelineShaderStageVertex:TpvVulkanPipelineShaderStage;
                fVulkanPipelineShaderStageFragment:TpvVulkanPipelineShaderStage;
                fVulkanGraphicsPipeline:TpvVulkanGraphicsPipeline;
                fVulkanDescriptorPool:TpvVulkanDescriptorPool;
                fVulkanDescriptorSetLayout:TpvVulkanDescriptorSetLayout;
                fVulkanDescriptorSets:array[0..MaxSwapChainImages-1] of TpvVulkanDescriptorSet;
                fVulkanPipelineLayout:TpvVulkanPipelineLayout;
               public
                constructor Create(const aFrameGraph:TpvFrameGraph;const aParent:TScreenMain); reintroduce;
                destructor Destroy; override;
                procedure Show; override;
                procedure Hide; override;
                procedure AfterCreateSwapChain; override;
                procedure BeforeDestroySwapChain; override;
                procedure Update(const aUpdateSwapChainImageIndex,aUpdateFrameIndex:TpvSizeInt); override;
                procedure Execute(const aCommandBuffer:TpvVulkanCommandBuffer;const aSwapChainImageIndex,aFrameIndex:TpvSizeInt); override;
              end;
             { TTonemappingRenderPass }
             TTonemappingRenderPass=class(TpvFrameGraph.TRenderPass)
               private
                fParent:TScreenMain;
                fVulkanRenderPass:TpvVulkanRenderPass;
                fResourceColor:TpvFrameGraph.TPass.TUsedImageResource;
                fResourceSurface:TpvFrameGraph.TPass.TUsedImageResource;
                fVulkanTransferCommandBuffer:TpvVulkanCommandBuffer;
                fVulkanTransferCommandBufferFence:TpvVulkanFence;
                fVulkanVertexShaderModule:TpvVulkanShaderModule;
                fVulkanFragmentShaderModule:TpvVulkanShaderModule;
                fVulkanPipelineShaderStageVertex:TpvVulkanPipelineShaderStage;
                fVulkanPipelineShaderStageFragment:TpvVulkanPipelineShaderStage;
                fVulkanGraphicsPipeline:TpvVulkanGraphicsPipeline;
                fVulkanDescriptorPool:TpvVulkanDescriptorPool;
                fVulkanDescriptorSetLayout:TpvVulkanDescriptorSetLayout;
                fVulkanDescriptorSets:array[0..MaxSwapChainImages-1] of TpvVulkanDescriptorSet;
                fVulkanPipelineLayout:TpvVulkanPipelineLayout;
               public
                constructor Create(const aFrameGraph:TpvFrameGraph;const aParent:TScreenMain); reintroduce;
                destructor Destroy; override;
                procedure Show; override;
                procedure Hide; override;
                procedure AfterCreateSwapChain; override;
                procedure BeforeDestroySwapChain; override;
                procedure Update(const aUpdateSwapChainImageIndex,aUpdateFrameIndex:TpvSizeInt); override;
                procedure Execute(const aCommandBuffer:TpvVulkanCommandBuffer;const aSwapChainImageIndex,aFrameIndex:TpvSizeInt); override;
              end;
              { TAntialiasingRenderPass }
              TAntialiasingRenderPass=class(TpvFrameGraph.TRenderPass)
               private
                fParent:TScreenMain;
                fVulkanRenderPass:TpvVulkanRenderPass;
                fResourceColor:TpvFrameGraph.TPass.TUsedImageResource;
                fResourceSurface:TpvFrameGraph.TPass.TUsedImageResource;
                fVulkanTransferCommandBuffer:TpvVulkanCommandBuffer;
                fVulkanTransferCommandBufferFence:TpvVulkanFence;
                fVulkanVertexShaderModule:TpvVulkanShaderModule;
                fVulkanFragmentShaderModule:TpvVulkanShaderModule;
                fVulkanPipelineShaderStageVertex:TpvVulkanPipelineShaderStage;
                fVulkanPipelineShaderStageFragment:TpvVulkanPipelineShaderStage;
                fVulkanGraphicsPipeline:TpvVulkanGraphicsPipeline;
                fVulkanSampler:TpvVulkanSampler;
                fVulkanDescriptorPool:TpvVulkanDescriptorPool;
                fVulkanDescriptorSetLayout:TpvVulkanDescriptorSetLayout;
                fVulkanImageViews:array[0..MaxSwapChainImages-1] of TpvVulkanImageView;
                fVulkanDescriptorSets:array[0..MaxSwapChainImages-1] of TpvVulkanDescriptorSet;
                fVulkanPipelineLayout:TpvVulkanPipelineLayout;
               public
                constructor Create(const aFrameGraph:TpvFrameGraph;const aParent:TScreenMain); reintroduce;
                destructor Destroy; override;
                procedure Show; override;
                procedure Hide; override;
                procedure AfterCreateSwapChain; override;
                procedure BeforeDestroySwapChain; override;
                procedure Update(const aUpdateSwapChainImageIndex,aUpdateFrameIndex:TpvSizeInt); override;
                procedure Execute(const aCommandBuffer:TpvVulkanCommandBuffer;const aSwapChainImageIndex,aFrameIndex:TpvSizeInt); override;
              end;
      public
       type TSwapChainImageState=record
             Ready:TPasMPBool32;
             FinalViewIndex:TpvSizeInt;
             CountViews:TpvSizeInt;
             CascadedShadowMapViewIndex:TpvSizeInt;
             CountCascadedShadowMapViews:TpvSizeInt;
            end;
            PSwapChainImageState=^TSwapChainImageState;
            TSwapChainImageStates=array[0..MaxSwapChainImages+1] of TSwapChainImageState;
      private
       fWidth:TpvInt32;
       fHeight:TpvInt32;
       fSurfaceMultiviewMask:TpvUInt32;
       fCountSurfaceViews:TpvInt32;
       fVulkanSampleCountFlagBits:TVkSampleCountFlagBits;
       fVulkanShadowMapSampleCountFlagBits:TVkSampleCountFlagBits;
       fCountSurfaceMSAASamples:Int32;
       fCountCascadedShadowMapMSAASamples:Int32;
       fVulkanGraphicsCommandPool:TpvVulkanCommandPool;
       fVulkanGraphicsCommandBuffer:TpvVulkanCommandBuffer;
       fVulkanGraphicsCommandBufferFence:TpvVulkanFence;
       fVulkanTransferCommandPool:TpvVulkanCommandPool;
       fVulkanTransferCommandBuffer:TpvVulkanCommandBuffer;
       fVulkanTransferCommandBufferFence:TpvVulkanFence;
       fVulkanRenderSemaphores:array[0..MaxSwapChainImages-1] of TpvVulkanSemaphore;
       fSkyCubeMap:TSkyCubeMap;
       fGGXBRDF:TGGXBRDF;
       fGGXEnvMapCubeMap:TGGXEnvMapCubeMap;
       fCharlieBRDF:TCharlieBRDF;
       fCharlieEnvMapCubeMap:TCharlieEnvMapCubeMap;
       fLambertianEnvMapCubeMap:TLambertianEnvMapCubeMap;
       fSheenELUT:TpvVulkanTexture;
       fScene3D:TpvScene3D;
       fPrimaryDirectionalLight:TpvScene3D.TLight;
       fFrameGraph:TpvFrameGraph;
       fExternalOutputImageData:TpvFrameGraph.TExternalImageData;
       fCascadedShadowMapRenderPass:TCascadedShadowMapRenderPass;
       fCascadedShadowMapResolveRenderPass:TCascadedShadowMapResolveRenderPass;
       fCascadedShadowMapBlurRenderPasses:array[0..1] of TCascadedShadowMapBlurRenderPass;
       fForwardRenderPass:TForwardRenderPass;
       fOrderIndependentTransparencyClearCustomPass:TOrderIndependentTransparencyClearCustomPass;
       fOrderIndependentTransparencyRenderPass:TOrderIndependentTransparencyRenderPass;
       fOrderIndependentTransparencyResolveRenderPass:TOrderIndependentTransparencyResolveRenderPass;
       fTonemappingRenderPass:TTonemappingRenderPass;
       fAntialiasingRenderPass:TAntialiasingRenderPass;
       fGroup:TpvScene3D.TGroup;
       fGroupInstance:TpvScene3D.TGroup.TInstance;
       fSwapChainImageCascadedShadowMaps:TSwapChainImageCascadedShadowMaps;
       fCascadedShadowMapUniformBuffers:TCascadedShadowMapUniformBuffers;
       fCascadedShadowMapVulkanUniformBuffers:TCascadedShadowMapVulkanUniformBuffers;
       fTime:Double;
       fCameraRotationX:TpvScalar;
       fCameraRotationY:TpvScalar;
       fZoom:TpvScalar;
       fSwapChainImageStates:TSwapChainImageStates;
       fUpdateLock:TPasMPCriticalSection;
       fAnimationIndex:TpvInt32;
       fUseDepthPrepass:boolean;
       fCountOrderIndependentTransparencyLayers:TpvInt32;
       fOrderIndependentTransparentUniformBuffer:TOrderIndependentTransparentUniformBuffer;
       fOrderIndependentTransparentUniformVulkanBuffer:TpvVulkanBuffer;
       fOrderIndependentTransparencyABufferBuffers:array[0..MaxSwapChainImages-1] of TOrderIndependentTransparencyBuffer;
       fOrderIndependentTransparencyAuxImages:array[0..MaxSwapChainImages-1] of TOrderIndependentTransparencyImage;
       fOrderIndependentTransparencySpinLockImages:array[0..MaxSwapChainImages-1] of TOrderIndependentTransparencyImage;
       procedure CalculateCascadedShadowMaps(const aSwapChainImageIndex:Int32;const aViewLeft,aViewRight:TpvScene3D.TView);
      public

       constructor Create; override;

       destructor Destroy; override;

       procedure Show; override;

       procedure Hide; override;

       procedure Resume; override;

       procedure Pause; override;

       procedure Resize(const aWidth,aHeight:TpvInt32); override;

       procedure AfterCreateSwapChain; override;

       procedure BeforeDestroySwapChain; override;

       function CanBeParallelProcessed:boolean; override;

       procedure Update(const aDeltaTime:TpvDouble); override;

       function IsReadyForDrawOfSwapChainImageIndex(const aSwapChainImageIndex:TpvInt32):boolean; override;

       procedure DrawUpdate(const aSwapChainImageIndex:TpvInt32;const aDeltaTime:TpvDouble);

       procedure Draw(const aSwapChainImageIndex:TpvInt32;var aWaitSemaphore:TpvVulkanSemaphore;const aWaitFence:TpvVulkanFence=nil); override;

       function KeyEvent(const aKeyEvent:TpvApplicationInputKeyEvent):boolean; override;

       function PointerEvent(const aPointerEvent:TpvApplicationInputPointerEvent):boolean; override;

       function Scrolled(const aRelativeAmount:TpvVector2):boolean; override;

     end;

implementation

uses PasGLTF,
     UnitApplication,
     PasVulkan.Frustum;

{ TScreenMain.TCascadedShadowMapRenderPass }

constructor TScreenMain.TCascadedShadowMapRenderPass.Create(const aFrameGraph:TpvFrameGraph;const aParent:TScreenMain);
var Index:TpvSizeInt;
begin
inherited Create(aFrameGraph);

 fParent:=aParent;

 Name:='CascadedShadowMap';

 MultiviewMask:=0;
 for Index:=0 to CountCascadedShadowMapCascades-1 do begin
  MultiviewMask:=MultiviewMask or (1 shl Index);
 end;

 Queue:=aFrameGraph.UniversalQueue;

 Size:=TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.Absolute,
                                       CascadedShadowMapWidth,
                                       CascadedShadowMapHeight,
                                       1.0,
                                       CountCascadedShadowMapCascades);

 fResourceDepth:=AddImageDepthOutput('resourcetype_cascadedshadowmap_msaa_depth',
                                     'cascadedshadowmap_msaa_depth',
                                     VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
                                     TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.Clear,
                                                                  TpvVector4.InlineableCreate(1.0,1.0,1.0,1.0)),
                                     [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                    );

end;

destructor TScreenMain.TCascadedShadowMapRenderPass.Destroy;
begin
 inherited Destroy;
end;

procedure TScreenMain.TCascadedShadowMapRenderPass.Show;
var Index:TpvSizeInt;
    Stream:TStream;
begin
 inherited Show;

 fVulkanGraphicsCommandBuffer:=TpvVulkanCommandBuffer.Create(FrameGraph.GraphicsQueue.CommandPool,VK_COMMAND_BUFFER_LEVEL_PRIMARY);

 fVulkanGraphicsCommandBufferFence:=TpvVulkanFence.Create(pvApplication.VulkanDevice);

 fVulkanTransferCommandBuffer:=TpvVulkanCommandBuffer.Create(FrameGraph.TransferQueue.CommandPool,VK_COMMAND_BUFFER_LEVEL_PRIMARY);

 fVulkanTransferCommandBufferFence:=TpvVulkanFence.Create(pvApplication.VulkanDevice);

 Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_vert.spv');
 try
  fMeshVertexShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_depth_frag.spv');
 try
  fMeshFragmentShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_depth_masked_frag.spv');
 try
  fMeshMaskedFragmentShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 fVulkanPipelineShaderStageMeshVertex:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_VERTEX_BIT,fMeshVertexShaderModule,'main');

 fVulkanPipelineShaderStageMeshFragment:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_FRAGMENT_BIT,fMeshFragmentShaderModule,'main');

 fVulkanPipelineShaderStageMeshMaskedFragment:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_FRAGMENT_BIT,fMeshMaskedFragmentShaderModule,'main');

 fVulkanPipelineLayout:=TpvVulkanPipelineLayout.Create(pvApplication.VulkanDevice);
 fVulkanPipelineLayout.AddPushConstantRange(TVkShaderStageFlags(VK_SHADER_STAGE_VERTEX_BIT),0,SizeOf(TpvScene3D.TVertexStagePushConstants));
 fVulkanPipelineLayout.AddDescriptorSetLayout(fParent.fScene3D.MeshVulkanDescriptorSetLayout);
 fVulkanPipelineLayout.AddDescriptorSetLayout(fParent.fScene3D.MaterialVulkanDescriptorSetLayout);
 fVulkanPipelineLayout.AddDescriptorSetLayout(fParent.fScene3D.GlobalVulkanDescriptorSetLayout);
 fVulkanPipelineLayout.Initialize;

end;

procedure TScreenMain.TCascadedShadowMapRenderPass.Hide;
begin

 FreeAndNil(fVulkanPipelineLayout);

 FreeAndNil(fVulkanPipelineShaderStageMeshVertex);

 FreeAndNil(fVulkanPipelineShaderStageMeshFragment);

 FreeAndNil(fVulkanPipelineShaderStageMeshMaskedFragment);

 FreeAndNil(fMeshVertexShaderModule);

 FreeAndNil(fMeshFragmentShaderModule);

 FreeAndNil(fMeshMaskedFragmentShaderModule);

 FreeAndNil(fVulkanTransferCommandBufferFence);
 FreeAndNil(fVulkanTransferCommandBuffer);
 FreeAndNil(fVulkanGraphicsCommandBufferFence);
 FreeAndNil(fVulkanGraphicsCommandBuffer);
 inherited Hide;
end;

procedure TScreenMain.TCascadedShadowMapRenderPass.AfterCreateSwapChain;
var AlphaMode:TpvScene3D.TMaterial.TAlphaMode;
    PrimitiveTopology:TpvScene3D.TPrimitiveTopology;
    DoubleSided:TpvScene3D.TDoubleSided;
    VulkanGraphicsPipeline:TpvVulkanGraphicsPipeline;
begin

 inherited AfterCreateSwapChain;

 fVulkanRenderPass:=VulkanRenderPass;

 for AlphaMode:=Low(TpvScene3D.TMaterial.TAlphaMode) to High(TpvScene3D.TMaterial.TAlphaMode) do begin
  for PrimitiveTopology:=Low(TpvScene3D.TPrimitiveTopology) to High(TpvScene3D.TPrimitiveTopology) do begin
   for DoubleSided:=Low(TpvScene3D.TDoubleSided) to High(TpvScene3D.TDoubleSided) do begin
    FreeAndNil(fVulkanGraphicsPipelines[AlphaMode,PrimitiveTopology,DoubleSided]);
   end;
  end;
 end;

 for AlphaMode:=Low(TpvScene3D.TMaterial.TAlphaMode) to High(TpvScene3D.TMaterial.TAlphaMode) do begin

  for PrimitiveTopology:=Low(TpvScene3D.TPrimitiveTopology) to High(TpvScene3D.TPrimitiveTopology) do begin

   for DoubleSided:=Low(TpvScene3D.TDoubleSided) to High(TpvScene3D.TDoubleSided) do begin

    VulkanGraphicsPipeline:=TpvVulkanGraphicsPipeline.Create(pvApplication.VulkanDevice,
                                                             pvApplication.VulkanPipelineCache,
                                                             0,
                                                             [],
                                                             fVulkanPipelineLayout,
                                                             fVulkanRenderPass,
                                                             VulkanRenderPassSubpassIndex,
                                                             nil,
                                                             0);

    try

     VulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageMeshVertex);
     if AlphaMode=TpvScene3D.TMaterial.TAlphaMode.Mask then begin
      VulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageMeshMaskedFragment);
     end else begin
      VulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageMeshFragment);
     end;

     VulkanGraphicsPipeline.InputAssemblyState.Topology:=TVkPrimitiveTopology(PrimitiveTopology);
     VulkanGraphicsPipeline.InputAssemblyState.PrimitiveRestartEnable:=false;

     VulkanGraphicsPipeline.VertexInputState.AddVertexInputBindingDescription(0,SizeOf(TpvScene3D.TVertex),VK_VERTEX_INPUT_RATE_VERTEX);
     VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(0,0,VK_FORMAT_R32G32B32_SFLOAT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.Position)));
     VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(1,0,VK_FORMAT_R32_UINT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.NodeIndex)));
     VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(2,0,VK_FORMAT_R16G16_SNORM,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.Normal)));
     VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(3,0,VK_FORMAT_R16G16_SNORM,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.Tangent)));
     VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(4,0,VK_FORMAT_R32G32_SFLOAT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.TexCoord0)));
     VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(5,0,VK_FORMAT_R32G32_SFLOAT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.TexCoord1)));
     VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(6,0,VK_FORMAT_R16G16B16A16_SFLOAT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.Color0)));
     VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(7,0,VK_FORMAT_R32_UINT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.MorphTargetVertexBaseIndex)));
     VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(8,0,VK_FORMAT_R32_UINT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.JointBlockBaseIndex)));
     VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(9,0,VK_FORMAT_R32_UINT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.CountJointBlocks)));
     VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(10,0,VK_FORMAT_R32_UINT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.Flags)));

     VulkanGraphicsPipeline.ViewPortState.AddViewPort(0.0,0.0,CascadedShadowMapWidth,CascadedShadowMapHeight,0.0,1.0);
     VulkanGraphicsPipeline.ViewPortState.AddScissor(0,0,CascadedShadowMapWidth,CascadedShadowMapHeight);

     VulkanGraphicsPipeline.RasterizationState.DepthClampEnable:=false;
     VulkanGraphicsPipeline.RasterizationState.RasterizerDiscardEnable:=false;
     VulkanGraphicsPipeline.RasterizationState.PolygonMode:=VK_POLYGON_MODE_FILL;
     if DoubleSided then begin
      VulkanGraphicsPipeline.RasterizationState.CullMode:=TVkCullModeFlags(VK_CULL_MODE_NONE);
     end else begin
      VulkanGraphicsPipeline.RasterizationState.CullMode:=TVkCullModeFlags(VK_CULL_MODE_BACK_BIT);
     end;
     VulkanGraphicsPipeline.RasterizationState.FrontFace:=VK_FRONT_FACE_CLOCKWISE;
     VulkanGraphicsPipeline.RasterizationState.DepthBiasEnable:=true;
     VulkanGraphicsPipeline.RasterizationState.DepthBiasConstantFactor:=1.25;
     VulkanGraphicsPipeline.RasterizationState.DepthBiasClamp:=0.0;
     VulkanGraphicsPipeline.RasterizationState.DepthBiasSlopeFactor:=1.75;
     VulkanGraphicsPipeline.RasterizationState.LineWidth:=1.0;

     VulkanGraphicsPipeline.MultisampleState.RasterizationSamples:=fParent.fVulkanShadowMapSampleCountFlagBits;
     VulkanGraphicsPipeline.MultisampleState.SampleShadingEnable:=false;
     VulkanGraphicsPipeline.MultisampleState.MinSampleShading:=0.0;
     VulkanGraphicsPipeline.MultisampleState.CountSampleMasks:=0;
     VulkanGraphicsPipeline.MultisampleState.AlphaToCoverageEnable:=false;
     VulkanGraphicsPipeline.MultisampleState.AlphaToOneEnable:=false;

     VulkanGraphicsPipeline.ColorBlendState.LogicOpEnable:=false;
     VulkanGraphicsPipeline.ColorBlendState.LogicOp:=VK_LOGIC_OP_COPY;
     VulkanGraphicsPipeline.ColorBlendState.BlendConstants[0]:=0.0;
     VulkanGraphicsPipeline.ColorBlendState.BlendConstants[1]:=0.0;
     VulkanGraphicsPipeline.ColorBlendState.BlendConstants[2]:=0.0;
     VulkanGraphicsPipeline.ColorBlendState.BlendConstants[3]:=0.0;
     if AlphaMode=TpvScene3D.TMaterial.TAlphaMode.Blend then begin
      VulkanGraphicsPipeline.ColorBlendState.AddColorBlendAttachmentState(true,
                                                                          VK_BLEND_FACTOR_SRC_ALPHA,
                                                                          VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
                                                                          VK_BLEND_OP_ADD,
                                                                          VK_BLEND_FACTOR_ONE,
                                                                          VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
                                                                          VK_BLEND_OP_ADD,
                                                                          TVkColorComponentFlags(VK_COLOR_COMPONENT_R_BIT) or
                                                                          TVkColorComponentFlags(VK_COLOR_COMPONENT_G_BIT) or
                                                                          TVkColorComponentFlags(VK_COLOR_COMPONENT_B_BIT) or
                                                                          TVkColorComponentFlags(VK_COLOR_COMPONENT_A_BIT));
     end else begin
      VulkanGraphicsPipeline.ColorBlendState.AddColorBlendAttachmentState(false,
                                                                          VK_BLEND_FACTOR_ZERO,
                                                                          VK_BLEND_FACTOR_ZERO,
                                                                          VK_BLEND_OP_ADD,
                                                                          VK_BLEND_FACTOR_ZERO,
                                                                          VK_BLEND_FACTOR_ZERO,
                                                                          VK_BLEND_OP_ADD,
                                                                          TVkColorComponentFlags(VK_COLOR_COMPONENT_R_BIT) or
                                                                          TVkColorComponentFlags(VK_COLOR_COMPONENT_G_BIT) or
                                                                          TVkColorComponentFlags(VK_COLOR_COMPONENT_B_BIT) or
                                                                          TVkColorComponentFlags(VK_COLOR_COMPONENT_A_BIT));
     end;

     VulkanGraphicsPipeline.DepthStencilState.DepthTestEnable:=true;
     VulkanGraphicsPipeline.DepthStencilState.DepthWriteEnable:=true; //AlphaMode<>TpvScene3D.TMaterial.TAlphaMode.Blend;
     VulkanGraphicsPipeline.DepthStencilState.DepthCompareOp:=VK_COMPARE_OP_LESS_OR_EQUAL;
     VulkanGraphicsPipeline.DepthStencilState.DepthBoundsTestEnable:=false;
     VulkanGraphicsPipeline.DepthStencilState.StencilTestEnable:=false;

     VulkanGraphicsPipeline.Initialize;

     VulkanGraphicsPipeline.FreeMemory;

    finally
     fVulkanGraphicsPipelines[AlphaMode,PrimitiveTopology,DoubleSided]:=VulkanGraphicsPipeline;
    end;

   end;

  end;

 end;

end;

procedure TScreenMain.TCascadedShadowMapRenderPass.BeforeDestroySwapChain;
var AlphaMode:TpvScene3D.TMaterial.TAlphaMode;
    PrimitiveTopology:TpvScene3D.TPrimitiveTopology;
    DoubleSided:TpvScene3D.TDoubleSided;
begin
 for AlphaMode:=Low(TpvScene3D.TMaterial.TAlphaMode) to High(TpvScene3D.TMaterial.TAlphaMode) do begin
  for PrimitiveTopology:=Low(TpvScene3D.TPrimitiveTopology) to High(TpvScene3D.TPrimitiveTopology) do begin
   for DoubleSided:=Low(TpvScene3D.TDoubleSided) to High(TpvScene3D.TDoubleSided) do begin
    FreeAndNil(fVulkanGraphicsPipelines[AlphaMode,PrimitiveTopology,DoubleSided]);
   end;
  end;
 end;
 inherited BeforeDestroySwapChain;
end;

procedure TScreenMain.TCascadedShadowMapRenderPass.Update(const aUpdateSwapChainImageIndex,aUpdateFrameIndex:TpvSizeInt);
begin
 inherited Update(aUpdateSwapChainImageIndex,aUpdateFrameIndex);
end;

procedure TScreenMain.TCascadedShadowMapRenderPass.Execute(const aCommandBuffer:TpvVulkanCommandBuffer;
                                                          const aSwapChainImageIndex,aFrameIndex:TpvSizeInt);
var SwapChainImageState:TScreenMain.PSwapChainImageState;
begin
 inherited Execute(aCommandBuffer,aSwapChainImageIndex,aFrameIndex);

 SwapChainImageState:=@fParent.fSwapChainImageStates[aSwapChainImageIndex];

 if SwapChainImageState^.Ready then begin

  fParent.fScene3D.Draw(fVulkanGraphicsPipelines[TpvScene3D.TMaterial.TAlphaMode.Opaque],
                        aSwapChainImageIndex,
                        1,
                        SwapChainImageState^.CascadedShadowMapViewIndex,
                        SwapChainImageState^.CountCascadedShadowMapViews,
                        aCommandBuffer,
                        fVulkanPipelineLayout,
                        [TpvScene3D.TMaterial.TAlphaMode.Opaque]);

  fParent.fScene3D.Draw(fVulkanGraphicsPipelines[TpvScene3D.TMaterial.TAlphaMode.Mask],
                        aSwapChainImageIndex,
                        1,
                        SwapChainImageState^.CascadedShadowMapViewIndex,
                        SwapChainImageState^.CountCascadedShadowMapViews,
                        aCommandBuffer,
                        fVulkanPipelineLayout,
                        [TpvScene3D.TMaterial.TAlphaMode.Mask]);

{ fParent.fScene3D.Draw(fVulkanGraphicsPipelines[TpvScene3D.TMaterial.TAlphaMode.Blend],
                        aSwapChainImageIndex, // pvApplication.DrawSwapChainImageIndex,
                        0,
                        SwapChainImageState^.FinalViewIndex,
                        SwapChainImageState^.CountViews,
                        aCommandBuffer,
                        fVulkanPipelineLayout,
                        [TpvScene3D.TMaterial.TAlphaMode.Blend]);}

 end;

end;

{ TScreenMain.TCascadedShadowMapResolveRenderPass }

constructor TScreenMain.TCascadedShadowMapResolveRenderPass.Create(const aFrameGraph:TpvFrameGraph;const aParent:TScreenMain);
var Index:TpvSizeInt;
begin

 inherited Create(aFrameGraph);

 fParent:=aParent;

 Name:='CascadedShadowMapResolveRenderPass';

 MultiviewMask:=0;
{for Index:=0 to CountCascadedShadowMapCascades-1 do begin
  MultiviewMask:=MultiviewMask or (1 shl Index);
 end; }

 Queue:=aFrameGraph.UniversalQueue;

//SeparatePhysicalPass:=true;

//SeparateCommandBuffer:=true;

 Size:=TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.Absolute,
                                       CascadedShadowMapWidth,
                                       CascadedShadowMapHeight,
                                       1.0,
                                       CountCascadedShadowMapCascades);

 fResourceInput:=AddImageInput('resourcetype_cascadedshadowmap_msaa_depth',
                               'cascadedshadowmap_msaa_depth',
                               VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                               []//TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                              );

 fResourceOutput:=AddImageOutput('resourcetype_cascadedshadowmap_data',
                                 'cascadedshadowmap_data',
                                 VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                                 TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.Clear,
                                                              TpvVector4.InlineableCreate(1.0,1.0,1.0,1.0)),
                                 [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                );

end;

destructor TScreenMain.TCascadedShadowMapResolveRenderPass.Destroy;
begin
 inherited Destroy;
end;

procedure TScreenMain.TCascadedShadowMapResolveRenderPass.Show;
var Stream:TStream;
begin

 inherited Show;

 fVulkanTransferCommandBuffer:=TpvVulkanCommandBuffer.Create(FrameGraph.TransferQueue.CommandPool,VK_COMMAND_BUFFER_LEVEL_PRIMARY);

 fVulkanTransferCommandBufferFence:=TpvVulkanFence.Create(pvApplication.VulkanDevice);

 Stream:=pvApplication.Assets.GetAssetStream('shaders/msm_resolve_vert.spv');
 try
  fVulkanVertexShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 Stream:=pvApplication.Assets.GetAssetStream('shaders/msm_resolve_frag.spv');
 try
  fVulkanFragmentShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 fVulkanPipelineShaderStageVertex:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_VERTEX_BIT,fVulkanVertexShaderModule,'main');

 fVulkanPipelineShaderStageFragment:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_FRAGMENT_BIT,fVulkanFragmentShaderModule,'main');

 fVulkanGraphicsPipeline:=nil;

 fVulkanSampler:=TpvVulkanSampler.Create(pvApplication.VulkanDevice,
                                         TVkFilter.VK_FILTER_LINEAR,
                                         TVkFilter.VK_FILTER_LINEAR,
                                         TVkSamplerMipmapMode.VK_SAMPLER_MIPMAP_MODE_LINEAR,
                                         VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
                                         VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
                                         VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
                                         0.0,
                                         false,
                                         0.0,
                                         false,
                                         VK_COMPARE_OP_ALWAYS,
                                         0.0,
                                         0.0,
                                         VK_BORDER_COLOR_FLOAT_OPAQUE_BLACK,
                                         false);

end;

procedure TScreenMain.TCascadedShadowMapResolveRenderPass.Hide;
begin
 FreeAndNil(fVulkanSampler);
 FreeAndNil(fVulkanPipelineShaderStageVertex);
 FreeAndNil(fVulkanPipelineShaderStageFragment);
 FreeAndNil(fVulkanFragmentShaderModule);
 FreeAndNil(fVulkanVertexShaderModule);
 FreeAndNil(fVulkanTransferCommandBufferFence);
 FreeAndNil(fVulkanTransferCommandBuffer);
 inherited Hide;
end;

procedure TScreenMain.TCascadedShadowMapResolveRenderPass.AfterCreateSwapChain;
var SwapChainImageIndex:TpvSizeInt;
begin
 inherited AfterCreateSwapChain;

 fVulkanRenderPass:=VulkanRenderPass;

 fVulkanDescriptorPool:=TpvVulkanDescriptorPool.Create(pvApplication.VulkanDevice,
                                                       TVkDescriptorPoolCreateFlags(VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT),
                                                       MaxSwapChainImages);
 fVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,MaxSwapChainImages);
 fVulkanDescriptorPool.Initialize;

 fVulkanDescriptorSetLayout:=TpvVulkanDescriptorSetLayout.Create(pvApplication.VulkanDevice);
 fVulkanDescriptorSetLayout.AddBinding(0,
                                       VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                                       1,
                                       TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                       []);
 fVulkanDescriptorSetLayout.Initialize;

 for SwapChainImageIndex:=0 to FrameGraph.CountSwapChainImages-1 do begin
  fVulkanDescriptorSets[SwapChainImageIndex]:=TpvVulkanDescriptorSet.Create(fVulkanDescriptorPool,
                                                                            fVulkanDescriptorSetLayout);
  fVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(0,
                                                                  0,
                                                                  1,
                                                                  TVkDescriptorType(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER),
                                                                  [TVkDescriptorImageInfo.Create(fVulkanSampler.Handle,
                                                                                                 fResourceInput.VulkanImageViews[SwapChainImageIndex].Handle,
                                                                                                 fResourceInput.ResourceTransition.Layout)],// TVkImageLayout(VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL))],
                                                                  [],
                                                                  [],
                                                                  false
                                                                 );
  fVulkanDescriptorSets[SwapChainImageIndex].Flush;
 end;

 fVulkanPipelineLayout:=TpvVulkanPipelineLayout.Create(pvApplication.VulkanDevice);
 fVulkanPipelineLayout.AddDescriptorSetLayout(fVulkanDescriptorSetLayout);
 fVulkanPipelineLayout.AddPushConstantRange(TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),0,SizeOf(TScreenMain.TCascadedShadowMapResolveRenderPass.TFragmentStagePushConstants));;
 fVulkanPipelineLayout.Initialize;

 fVulkanGraphicsPipeline:=TpvVulkanGraphicsPipeline.Create(pvApplication.VulkanDevice,
                                                           pvApplication.VulkanPipelineCache,
                                                           0,
                                                           [],
                                                           fVulkanPipelineLayout,
                                                           fVulkanRenderPass,
                                                           VulkanRenderPassSubpassIndex,
                                                           nil,
                                                           0);

 fVulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageVertex);
 fVulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageFragment);

 fVulkanGraphicsPipeline.InputAssemblyState.Topology:=VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
 fVulkanGraphicsPipeline.InputAssemblyState.PrimitiveRestartEnable:=false;

 fVulkanGraphicsPipeline.ViewPortState.AddViewPort(0.0,0.0,CascadedShadowMapWidth,CascadedShadowMapHeight,0.0,1.0);
 fVulkanGraphicsPipeline.ViewPortState.AddScissor(0,0,CascadedShadowMapWidth,CascadedShadowMapHeight);

 fVulkanGraphicsPipeline.RasterizationState.DepthClampEnable:=false;
 fVulkanGraphicsPipeline.RasterizationState.RasterizerDiscardEnable:=false;
 fVulkanGraphicsPipeline.RasterizationState.PolygonMode:=VK_POLYGON_MODE_FILL;
 fVulkanGraphicsPipeline.RasterizationState.CullMode:=TVkCullModeFlags(VK_CULL_MODE_NONE);
 fVulkanGraphicsPipeline.RasterizationState.FrontFace:=VK_FRONT_FACE_CLOCKWISE;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasEnable:=false;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasConstantFactor:=0.0;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasClamp:=0.0;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasSlopeFactor:=0.0;
 fVulkanGraphicsPipeline.RasterizationState.LineWidth:=1.0;

 fVulkanGraphicsPipeline.MultisampleState.RasterizationSamples:=VK_SAMPLE_COUNT_1_BIT;
 fVulkanGraphicsPipeline.MultisampleState.SampleShadingEnable:=false;
 fVulkanGraphicsPipeline.MultisampleState.MinSampleShading:=0.0;
 fVulkanGraphicsPipeline.MultisampleState.CountSampleMasks:=0;
 fVulkanGraphicsPipeline.MultisampleState.AlphaToCoverageEnable:=false;
 fVulkanGraphicsPipeline.MultisampleState.AlphaToOneEnable:=false;

 fVulkanGraphicsPipeline.ColorBlendState.LogicOpEnable:=false;
 fVulkanGraphicsPipeline.ColorBlendState.LogicOp:=VK_LOGIC_OP_COPY;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[0]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[1]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[2]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[3]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.AddColorBlendAttachmentState(false,
                                                                      VK_BLEND_FACTOR_SRC_ALPHA,
                                                                      VK_BLEND_FACTOR_DST_ALPHA,
                                                                      VK_BLEND_OP_ADD,
                                                                      VK_BLEND_FACTOR_ONE,
                                                                      VK_BLEND_FACTOR_ZERO,
                                                                      VK_BLEND_OP_ADD,
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_R_BIT) or
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_G_BIT) or
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_B_BIT) or
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_A_BIT));

 fVulkanGraphicsPipeline.DepthStencilState.DepthTestEnable:=true;
 fVulkanGraphicsPipeline.DepthStencilState.DepthWriteEnable:=true;
 fVulkanGraphicsPipeline.DepthStencilState.DepthCompareOp:=VK_COMPARE_OP_ALWAYS;
 fVulkanGraphicsPipeline.DepthStencilState.DepthBoundsTestEnable:=false;
 fVulkanGraphicsPipeline.DepthStencilState.StencilTestEnable:=false;

 fVulkanGraphicsPipeline.Initialize;

 fVulkanGraphicsPipeline.FreeMemory;

end;

procedure TScreenMain.TCascadedShadowMapResolveRenderPass.BeforeDestroySwapChain;
var SwapChainImageIndex:TpvSizeInt;
begin

 FreeAndNil(fVulkanGraphicsPipeline);

 FreeAndNil(fVulkanPipelineLayout);

 for SwapChainImageIndex:=0 to FrameGraph.CountSwapChainImages-1 do begin
  FreeAndNil(fVulkanDescriptorSets[SwapChainImageIndex]);
 end;

 FreeAndNil(fVulkanDescriptorSetLayout);

 FreeAndNil(fVulkanDescriptorPool);

 fVulkanRenderPass:=nil;

 inherited BeforeDestroySwapChain;
end;

procedure TScreenMain.TCascadedShadowMapResolveRenderPass.Update(const aUpdateSwapChainImageIndex,aUpdateFrameIndex:TpvSizeInt);
begin
 inherited Update(aUpdateSwapChainImageIndex,aUpdateFrameIndex);
end;

procedure TScreenMain.TCascadedShadowMapResolveRenderPass.Execute(const aCommandBuffer:TpvVulkanCommandBuffer;const aSwapChainImageIndex,aFrameIndex:TpvSizeInt);
begin
 inherited Execute(aCommandBuffer,aSwapChainImageIndex,aFrameIndex);
 fFragmentStagePushConstants.CountSamples:=fParent.fCountCascadedShadowMapMSAASamples;
 aCommandBuffer.CmdBindDescriptorSets(VK_PIPELINE_BIND_POINT_GRAPHICS,
                                      fVulkanPipelineLayout.Handle,
                                      0,
                                      1,
                                      @fVulkanDescriptorSets[aSwapChainImageIndex].Handle,0,nil);
 aCommandBuffer.CmdPushConstants(fVulkanPipelineLayout.Handle,
                                  TVkShaderStageFlags(TVkShaderStageFlagBits.VK_SHADER_STAGE_FRAGMENT_BIT),
                                  0,
                                  SizeOf(TScreenMain.TCascadedShadowMapResolveRenderPass.TFragmentStagePushConstants),
                                  @fFragmentStagePushConstants);
 aCommandBuffer.CmdBindPipeline(VK_PIPELINE_BIND_POINT_GRAPHICS,fVulkanGraphicsPipeline.Handle);
 aCommandBuffer.CmdDraw(3*CountCascadedShadowMapCascades,1,0,0);
end;

{ TScreenMain.TCascadedShadowMapBlurRenderPass }

constructor TScreenMain.TCascadedShadowMapBlurRenderPass.Create(const aFrameGraph:TpvFrameGraph;const aParent:TScreenMain;const aHorziontal:boolean);
var Index:TpvSizeInt;
begin

 inherited Create(aFrameGraph);

 fParent:=aParent;

 if aHorziontal then begin
  fFragmentStagePushConstants.Direction:=TpvVector4.InlineableCreate(1.0,0.0,0.0,0.0);
  Name:='CascadedShadowMapBlurRenderPass(Horziontal)';
 end else begin
  fFragmentStagePushConstants.Direction:=TpvVector4.InlineableCreate(0.0,1.0,0.0);
  Name:='CascadedShadowMapBlurRenderPass(Vertical)';
 end;

 MultiviewMask:=0;
{for Index:=0 to CountCascadedShadowMapCascades-1 do begin
  MultiviewMask:=MultiviewMask or (1 shl Index);
 end; }

 Queue:=aFrameGraph.UniversalQueue;

//SeparatePhysicalPass:=true;

//SeparateCommandBuffer:=true;

 Size:=TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.Absolute,
                                       CascadedShadowMapWidth,
                                       CascadedShadowMapHeight,
                                       1.0,
                                       CountCascadedShadowMapCascades);

 if aHorziontal then begin

  fResourceInput:=AddImageInput('resourcetype_cascadedshadowmap_data',
                                'cascadedshadowmap_data',
                                VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                                []//TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                               );

  fResourceOutput:=AddImageOutput('resourcetype_cascadedshadowmap_data',
                                  'cascadedshadowmap_data_temporary_blurred',
                                  VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                                  TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.Clear,
                                                               TpvVector4.InlineableCreate(1.0,1.0,1.0,1.0)),
                                  [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                 );


 end else begin

  fResourceInput:=AddImageInput('resourcetype_cascadedshadowmap_data',
                                'cascadedshadowmap_data_temporary_blurred',
                                VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                                []//TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                               );

  fResourceOutput:=AddImageOutput('resourcetype_cascadedshadowmap_data',
                                  'cascadedshadowmap_data_final',
                                  VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                                  TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.Clear,
                                                               TpvVector4.InlineableCreate(1.0,1.0,1.0,1.0)),
                                  [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                 );

 end;

end;

destructor TScreenMain.TCascadedShadowMapBlurRenderPass.Destroy;
begin
 inherited Destroy;
end;

procedure TScreenMain.TCascadedShadowMapBlurRenderPass.Show;
var Stream:TStream;
begin

 inherited Show;

 fVulkanTransferCommandBuffer:=TpvVulkanCommandBuffer.Create(FrameGraph.TransferQueue.CommandPool,VK_COMMAND_BUFFER_LEVEL_PRIMARY);

 fVulkanTransferCommandBufferFence:=TpvVulkanFence.Create(pvApplication.VulkanDevice);

 Stream:=pvApplication.Assets.GetAssetStream('shaders/msm_blur_vert.spv');
 try
  fVulkanVertexShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 Stream:=pvApplication.Assets.GetAssetStream('shaders/msm_blur_frag.spv');
 try
  fVulkanFragmentShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 fVulkanPipelineShaderStageVertex:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_VERTEX_BIT,fVulkanVertexShaderModule,'main');

 fVulkanPipelineShaderStageFragment:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_FRAGMENT_BIT,fVulkanFragmentShaderModule,'main');

 fVulkanGraphicsPipeline:=nil;

 fVulkanSampler:=TpvVulkanSampler.Create(pvApplication.VulkanDevice,
                                         TVkFilter.VK_FILTER_LINEAR,
                                         TVkFilter.VK_FILTER_LINEAR,
                                         TVkSamplerMipmapMode.VK_SAMPLER_MIPMAP_MODE_LINEAR,
                                         VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
                                         VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
                                         VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
                                         0.0,
                                         false,
                                         0.0,
                                         false,
                                         VK_COMPARE_OP_ALWAYS,
                                         0.0,
                                         0.0,
                                         VK_BORDER_COLOR_FLOAT_OPAQUE_BLACK,
                                         false);

end;

procedure TScreenMain.TCascadedShadowMapBlurRenderPass.Hide;
begin
 FreeAndNil(fVulkanSampler);
 FreeAndNil(fVulkanPipelineShaderStageVertex);
 FreeAndNil(fVulkanPipelineShaderStageFragment);
 FreeAndNil(fVulkanFragmentShaderModule);
 FreeAndNil(fVulkanVertexShaderModule);
 FreeAndNil(fVulkanTransferCommandBufferFence);
 FreeAndNil(fVulkanTransferCommandBuffer);
 inherited Hide;
end;

procedure TScreenMain.TCascadedShadowMapBlurRenderPass.AfterCreateSwapChain;
var SwapChainImageIndex:TpvSizeInt;
begin
 inherited AfterCreateSwapChain;

 fVulkanRenderPass:=VulkanRenderPass;

 fVulkanDescriptorPool:=TpvVulkanDescriptorPool.Create(pvApplication.VulkanDevice,
                                                       TVkDescriptorPoolCreateFlags(VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT),
                                                       MaxSwapChainImages);
 fVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,MaxSwapChainImages);
 fVulkanDescriptorPool.Initialize;

 fVulkanDescriptorSetLayout:=TpvVulkanDescriptorSetLayout.Create(pvApplication.VulkanDevice);
 fVulkanDescriptorSetLayout.AddBinding(0,
                                       VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                                       1,
                                       TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                       []);
 fVulkanDescriptorSetLayout.Initialize;

 for SwapChainImageIndex:=0 to FrameGraph.CountSwapChainImages-1 do begin
  fVulkanDescriptorSets[SwapChainImageIndex]:=TpvVulkanDescriptorSet.Create(fVulkanDescriptorPool,
                                                                            fVulkanDescriptorSetLayout);
  fVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(0,
                                                                  0,
                                                                  1,
                                                                  TVkDescriptorType(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER),
                                                                  [TVkDescriptorImageInfo.Create(fVulkanSampler.Handle,
                                                                                                 fResourceInput.VulkanImageViews[SwapChainImageIndex].Handle,
                                                                                                 fResourceInput.ResourceTransition.Layout)],// TVkImageLayout(VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL))],
                                                                  [],
                                                                  [],
                                                                  false
                                                                 );
  fVulkanDescriptorSets[SwapChainImageIndex].Flush;
 end;

 fVulkanPipelineLayout:=TpvVulkanPipelineLayout.Create(pvApplication.VulkanDevice);
 fVulkanPipelineLayout.AddDescriptorSetLayout(fVulkanDescriptorSetLayout);
 fVulkanPipelineLayout.AddPushConstantRange(TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),0,SizeOf(TScreenMain.TCascadedShadowMapBlurRenderPass.TFragmentStagePushConstants));;
 fVulkanPipelineLayout.Initialize;

 fVulkanGraphicsPipeline:=TpvVulkanGraphicsPipeline.Create(pvApplication.VulkanDevice,
                                                           pvApplication.VulkanPipelineCache,
                                                           0,
                                                           [],
                                                           fVulkanPipelineLayout,
                                                           fVulkanRenderPass,
                                                           VulkanRenderPassSubpassIndex,
                                                           nil,
                                                           0);

 fVulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageVertex);
 fVulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageFragment);

 fVulkanGraphicsPipeline.InputAssemblyState.Topology:=VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
 fVulkanGraphicsPipeline.InputAssemblyState.PrimitiveRestartEnable:=false;

 fVulkanGraphicsPipeline.ViewPortState.AddViewPort(0.0,0.0,CascadedShadowMapWidth,CascadedShadowMapHeight,0.0,1.0);
 fVulkanGraphicsPipeline.ViewPortState.AddScissor(0,0,CascadedShadowMapWidth,CascadedShadowMapHeight);

 fVulkanGraphicsPipeline.RasterizationState.DepthClampEnable:=false;
 fVulkanGraphicsPipeline.RasterizationState.RasterizerDiscardEnable:=false;
 fVulkanGraphicsPipeline.RasterizationState.PolygonMode:=VK_POLYGON_MODE_FILL;
 fVulkanGraphicsPipeline.RasterizationState.CullMode:=TVkCullModeFlags(VK_CULL_MODE_NONE);
 fVulkanGraphicsPipeline.RasterizationState.FrontFace:=VK_FRONT_FACE_CLOCKWISE;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasEnable:=false;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasConstantFactor:=0.0;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasClamp:=0.0;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasSlopeFactor:=0.0;
 fVulkanGraphicsPipeline.RasterizationState.LineWidth:=1.0;

 fVulkanGraphicsPipeline.MultisampleState.RasterizationSamples:=VK_SAMPLE_COUNT_1_BIT;
 fVulkanGraphicsPipeline.MultisampleState.SampleShadingEnable:=false;
 fVulkanGraphicsPipeline.MultisampleState.MinSampleShading:=0.0;
 fVulkanGraphicsPipeline.MultisampleState.CountSampleMasks:=0;
 fVulkanGraphicsPipeline.MultisampleState.AlphaToCoverageEnable:=false;
 fVulkanGraphicsPipeline.MultisampleState.AlphaToOneEnable:=false;

 fVulkanGraphicsPipeline.ColorBlendState.LogicOpEnable:=false;
 fVulkanGraphicsPipeline.ColorBlendState.LogicOp:=VK_LOGIC_OP_COPY;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[0]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[1]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[2]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[3]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.AddColorBlendAttachmentState(false,
                                                                      VK_BLEND_FACTOR_SRC_ALPHA,
                                                                      VK_BLEND_FACTOR_DST_ALPHA,
                                                                      VK_BLEND_OP_ADD,
                                                                      VK_BLEND_FACTOR_ONE,
                                                                      VK_BLEND_FACTOR_ZERO,
                                                                      VK_BLEND_OP_ADD,
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_R_BIT) or
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_G_BIT) or
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_B_BIT) or
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_A_BIT));

 fVulkanGraphicsPipeline.DepthStencilState.DepthTestEnable:=true;
 fVulkanGraphicsPipeline.DepthStencilState.DepthWriteEnable:=true;
 fVulkanGraphicsPipeline.DepthStencilState.DepthCompareOp:=VK_COMPARE_OP_ALWAYS;
 fVulkanGraphicsPipeline.DepthStencilState.DepthBoundsTestEnable:=false;
 fVulkanGraphicsPipeline.DepthStencilState.StencilTestEnable:=false;

 fVulkanGraphicsPipeline.Initialize;

 fVulkanGraphicsPipeline.FreeMemory;

end;

procedure TScreenMain.TCascadedShadowMapBlurRenderPass.BeforeDestroySwapChain;
var SwapChainImageIndex:TpvSizeInt;
begin

 FreeAndNil(fVulkanGraphicsPipeline);

 FreeAndNil(fVulkanPipelineLayout);

 for SwapChainImageIndex:=0 to FrameGraph.CountSwapChainImages-1 do begin
  FreeAndNil(fVulkanDescriptorSets[SwapChainImageIndex]);
 end;

 FreeAndNil(fVulkanDescriptorSetLayout);

 FreeAndNil(fVulkanDescriptorPool);

 fVulkanRenderPass:=nil;

 inherited BeforeDestroySwapChain;
end;

procedure TScreenMain.TCascadedShadowMapBlurRenderPass.Update(const aUpdateSwapChainImageIndex,aUpdateFrameIndex:TpvSizeInt);
begin
 inherited Update(aUpdateSwapChainImageIndex,aUpdateFrameIndex);
end;

procedure TScreenMain.TCascadedShadowMapBlurRenderPass.Execute(const aCommandBuffer:TpvVulkanCommandBuffer;const aSwapChainImageIndex,aFrameIndex:TpvSizeInt);
begin
 inherited Execute(aCommandBuffer,aSwapChainImageIndex,aFrameIndex);
 aCommandBuffer.CmdBindDescriptorSets(VK_PIPELINE_BIND_POINT_GRAPHICS,
                                      fVulkanPipelineLayout.Handle,
                                      0,
                                      1,
                                      @fVulkanDescriptorSets[aSwapChainImageIndex].Handle,0,nil);
 aCommandBuffer.CmdPushConstants(fVulkanPipelineLayout.Handle,
                                  TVkShaderStageFlags(TVkShaderStageFlagBits.VK_SHADER_STAGE_FRAGMENT_BIT),
                                  0,
                                  SizeOf(TScreenMain.TCascadedShadowMapBlurRenderPass.TFragmentStagePushConstants),
                                  @fFragmentStagePushConstants);
 aCommandBuffer.CmdBindPipeline(VK_PIPELINE_BIND_POINT_GRAPHICS,fVulkanGraphicsPipeline.Handle);
 aCommandBuffer.CmdDraw(3*CountCascadedShadowMapCascades,1,0,0);
end;

{ TScreenMain.TForwardRenderPass }

constructor TScreenMain.TForwardRenderPass.Create(const aFrameGraph:TpvFrameGraph;const aParent:TScreenMain);
begin
inherited Create(aFrameGraph);

 fParent:=aParent;

 Name:='ForwardRendering';

 MultiviewMask:=fParent.fSurfaceMultiviewMask;

 Queue:=aFrameGraph.UniversalQueue;

 Size:=TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.SurfaceDependent,
                                       1.0,
                                       1.0,
                                       1.0,
                                       fParent.fCountSurfaceViews);

 fResourceCascadedShadowMap:=AddImageInput('resourcetype_cascadedshadowmap_data',
                                           'cascadedshadowmap_data_final',
                                           VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                                           []
                                          );

 if fParent.fVulkanSampleCountFlagBits=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT) then begin

  fResourceColor:=AddImageOutput('resourcetype_color',
                                 'forwardrendering_color',
                                 VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                                 TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.Clear,
                                                              TpvVector4.InlineableCreate(0.0,0.0,0.0,1.0)),
                                 [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                );

  fResourceDepth:=AddImageDepthOutput('resourcetype_depth',
                                      'forwardrendering_depth',
                                      VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
                                      TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.Clear,
                                                                   TpvVector4.InlineableCreate(IfThen(UnitApplication.Application.VirtualReality.ZFar<0.0,0.0,1.0),0.0,0.0,0.0)),
                                      [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                     );

 end else begin

  fResourceColor:=AddImageOutput('resourcetype_msaa_color',
                                 'forwardrendering_msaa_color',
                                 VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                                 TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.Clear,
                                                              TpvVector4.InlineableCreate(0.0,0.0,0.0,1.0)),
                                 [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                );

  fResourceColor:=AddImageResolveOutput('resourcetype_color',
                                        'forwardrendering_color',
                                        'forwardrendering_msaa_color',
                                        VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                                        TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.DontCare,
                                                                     TpvVector4.InlineableCreate(0.0,0.0,0.0,1.0)),
                                        [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                       );

  fResourceDepth:=AddImageDepthOutput('resourcetype_msaa_depth',
                                      'forwardrendering_msaa_depth',
                                      VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
                                      TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.Clear,
                                                                   TpvVector4.InlineableCreate(IfThen(UnitApplication.Application.VirtualReality.ZFar<0.0,0.0,1.0),0.0,0.0,0.0)),
                                      [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                     );

 end;


end;

destructor TScreenMain.TForwardRenderPass.Destroy;
begin
 inherited Destroy;
end;

procedure TScreenMain.TForwardRenderPass.Show;
var Index:TpvSizeInt;
    Stream:TStream;
begin
 inherited Show;

 fVulkanGraphicsCommandBuffer:=TpvVulkanCommandBuffer.Create(FrameGraph.GraphicsQueue.CommandPool,VK_COMMAND_BUFFER_LEVEL_PRIMARY);

 fVulkanGraphicsCommandBufferFence:=TpvVulkanFence.Create(pvApplication.VulkanDevice);

 fVulkanTransferCommandBuffer:=TpvVulkanCommandBuffer.Create(FrameGraph.TransferQueue.CommandPool,VK_COMMAND_BUFFER_LEVEL_PRIMARY);

 fVulkanTransferCommandBufferFence:=TpvVulkanFence.Create(pvApplication.VulkanDevice);

 Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_vert.spv');
 try
  fMeshVertexShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_frag.spv');
 try
  fMeshFragmentShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_masked_frag.spv');
 try
  fMeshMaskedFragmentShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 if fParent.fUseDepthPrepass then begin

  Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_depth_frag.spv');
  try
   fMeshDepthFragmentShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
  finally
   Stream.Free;
  end;

  Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_depth_masked_frag.spv');
  try
   fMeshDepthMaskedFragmentShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
  finally
   Stream.Free;
  end;

 end;

 fVulkanPipelineShaderStageMeshVertex:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_VERTEX_BIT,fMeshVertexShaderModule,'main');

 fVulkanPipelineShaderStageMeshFragment:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_FRAGMENT_BIT,fMeshFragmentShaderModule,'main');

 fVulkanPipelineShaderStageMeshMaskedFragment:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_FRAGMENT_BIT,fMeshMaskedFragmentShaderModule,'main');

 if fParent.fUseDepthPrepass then begin

  fVulkanPipelineShaderStageMeshDepthFragment:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_FRAGMENT_BIT,fMeshDepthFragmentShaderModule,'main');

  fVulkanPipelineShaderStageMeshDepthMaskedFragment:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_FRAGMENT_BIT,fMeshDepthMaskedFragmentShaderModule,'main');

 end;

 fVulkanCascadedShadowMapSampler:=TpvVulkanSampler.Create(pvApplication.VulkanDevice,
                                                          TVkFilter.VK_FILTER_LINEAR,
                                                          TVkFilter.VK_FILTER_LINEAR,
                                                          TVkSamplerMipmapMode.VK_SAMPLER_MIPMAP_MODE_LINEAR,
                                                          VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
                                                          VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
                                                          VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
                                                          0.0,
                                                          false,
                                                          0.0,
                                                          false,
                                                          VK_COMPARE_OP_ALWAYS,
                                                          0.0,
                                                          0.0,
                                                          VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE,
                                                          false);

 fSkyBox:=TSkyBox.Create(fParent.fScene3D,
                         fParent.fSkyCubeMap.DescriptorImageInfo);

end;

procedure TScreenMain.TForwardRenderPass.Hide;
begin

 FreeAndNil(fSkyBox);

 FreeAndNil(fVulkanCascadedShadowMapSampler);

 FreeAndNil(fVulkanPipelineShaderStageMeshVertex);

 FreeAndNil(fVulkanPipelineShaderStageMeshFragment);

 FreeAndNil(fVulkanPipelineShaderStageMeshMaskedFragment);

 if fParent.fUseDepthPrepass then begin

  FreeAndNil(fVulkanPipelineShaderStageMeshDepthFragment);

  FreeAndNil(fVulkanPipelineShaderStageMeshDepthMaskedFragment);

 end;

 FreeAndNil(fMeshVertexShaderModule);

 FreeAndNil(fMeshFragmentShaderModule);

 FreeAndNil(fMeshMaskedFragmentShaderModule);

 if fParent.fUseDepthPrepass then begin

  FreeAndNil(fMeshDepthFragmentShaderModule);

  FreeAndNil(fMeshDepthMaskedFragmentShaderModule);

 end;

 FreeAndNil(fVulkanTransferCommandBufferFence);
 FreeAndNil(fVulkanTransferCommandBuffer);
 FreeAndNil(fVulkanGraphicsCommandBufferFence);
 FreeAndNil(fVulkanGraphicsCommandBuffer);
 inherited Hide;
end;

procedure TScreenMain.TForwardRenderPass.AfterCreateSwapChain;
var SwapChainImageIndex:TpvSizeInt;
    DepthPrePass:boolean;
    AlphaMode:TpvScene3D.TMaterial.TAlphaMode;
    PrimitiveTopology:TpvScene3D.TPrimitiveTopology;
    DoubleSided:TpvScene3D.TDoubleSided;
    VulkanGraphicsPipeline:TpvVulkanGraphicsPipeline;
begin

 inherited AfterCreateSwapChain;

 fVulkanRenderPass:=VulkanRenderPass;

 fGlobalVulkanDescriptorSetLayout:=TpvVulkanDescriptorSetLayout.Create(pvApplication.VulkanDevice);
 fGlobalVulkanDescriptorSetLayout.AddBinding(0,
                                             VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                                             3,
                                             TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                             []);
 fGlobalVulkanDescriptorSetLayout.AddBinding(1,
                                             VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                                             3,
                                             TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                             []);
 fGlobalVulkanDescriptorSetLayout.AddBinding(2,
                                             VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                                             1,
                                             TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                             []);
 fGlobalVulkanDescriptorSetLayout.AddBinding(3,
                                             VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                                             1,
                                             TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                             []);
 fGlobalVulkanDescriptorSetLayout.Initialize;

 fGlobalVulkanDescriptorPool:=TpvVulkanDescriptorPool.Create(pvApplication.VulkanDevice,TVkDescriptorPoolCreateFlags(VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT),length(fGlobalVulkanDescriptorSets));
 fGlobalVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,7*length(fGlobalVulkanDescriptorSets));
 fGlobalVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,1*length(fGlobalVulkanDescriptorSets));
 fGlobalVulkanDescriptorPool.Initialize;

 for SwapChainImageIndex:=0 to FrameGraph.CountSwapChainImages-1 do begin
  fGlobalVulkanDescriptorSets[SwapChainImageIndex]:=TpvVulkanDescriptorSet.Create(fGlobalVulkanDescriptorPool,
                                                                                  fGlobalVulkanDescriptorSetLayout);
  fGlobalVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(0,
                                                                        0,
                                                                        3,
                                                                        TVkDescriptorType(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER),
                                                                        [fParent.fGGXBRDF.DescriptorImageInfo,
                                                                         fParent.fCharlieBRDF.DescriptorImageInfo,
                                                                         fParent.fSheenELUT.DescriptorImageInfo],
                                                                        [],
                                                                        [],
                                                                        false);
  fGlobalVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(1,
                                                                        0,
                                                                        3,
                                                                        TVkDescriptorType(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER),
                                                                        [fParent.fGGXEnvMapCubeMap.DescriptorImageInfo,
                                                                         fParent.fCharlieEnvMapCubeMap.DescriptorImageInfo,
                                                                         fParent.fLambertianEnvMapCubeMap.DescriptorImageInfo],
                                                                        [],
                                                                        [],
                                                                        false);
  fGlobalVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(2,
                                                                        0,
                                                                        1,
                                                                        TVkDescriptorType(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER),
                                                                        [],
                                                                        [fParent.fCascadedShadowMapVulkanUniformBuffers[SwapChainImageIndex].DescriptorBufferInfo],
                                                                        [],
                                                                        false);
  fGlobalVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(3,
                                                                        0,
                                                                        1,
                                                                        TVkDescriptorType(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER),
                                                                        [TVkDescriptorImageInfo.Create(fVulkanCascadedShadowMapSampler.Handle,
                                                                                                       fResourceCascadedShadowMap.VulkanImageViews[SwapChainImageIndex].Handle,
                                                                                                       fResourceCascadedShadowMap.ResourceTransition.Layout)],// TVkImageLayout(VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL))],
                                                                        [],
                                                                        [],
                                                                        false);
  fGlobalVulkanDescriptorSets[SwapChainImageIndex].Flush;
 end;

 fVulkanPipelineLayout:=TpvVulkanPipelineLayout.Create(pvApplication.VulkanDevice);
 fVulkanPipelineLayout.AddPushConstantRange(TVkShaderStageFlags(VK_SHADER_STAGE_VERTEX_BIT),0,SizeOf(TpvScene3D.TVertexStagePushConstants));
 fVulkanPipelineLayout.AddDescriptorSetLayout(fParent.fScene3D.MeshVulkanDescriptorSetLayout);
 fVulkanPipelineLayout.AddDescriptorSetLayout(fParent.fScene3D.MaterialVulkanDescriptorSetLayout);
 fVulkanPipelineLayout.AddDescriptorSetLayout(fParent.fScene3D.GlobalVulkanDescriptorSetLayout);
 fVulkanPipelineLayout.AddDescriptorSetLayout(fGlobalVulkanDescriptorSetLayout);
 fVulkanPipelineLayout.Initialize;

 for DepthPrePass:=false to fParent.fUseDepthPrepass do begin
  for AlphaMode:=Low(TpvScene3D.TMaterial.TAlphaMode) to High(TpvScene3D.TMaterial.TAlphaMode) do begin
   for PrimitiveTopology:=Low(TpvScene3D.TPrimitiveTopology) to High(TpvScene3D.TPrimitiveTopology) do begin
    for DoubleSided:=Low(TpvScene3D.TDoubleSided) to High(TpvScene3D.TDoubleSided) do begin
     FreeAndNil(fVulkanGraphicsPipelines[DepthPrePass,AlphaMode,PrimitiveTopology,DoubleSided]);
    end;
   end;
  end;
 end;

 for DepthPrePass:=false to fParent.fUseDepthPrepass do begin

  for AlphaMode:=Low(TpvScene3D.TMaterial.TAlphaMode) to High(TpvScene3D.TMaterial.TAlphaMode) do begin

   for PrimitiveTopology:=Low(TpvScene3D.TPrimitiveTopology) to High(TpvScene3D.TPrimitiveTopology) do begin

    for DoubleSided:=Low(TpvScene3D.TDoubleSided) to High(TpvScene3D.TDoubleSided) do begin

     VulkanGraphicsPipeline:=TpvVulkanGraphicsPipeline.Create(pvApplication.VulkanDevice,
                                                              pvApplication.VulkanPipelineCache,
                                                              0,
                                                              [],
                                                              fVulkanPipelineLayout,
                                                              fVulkanRenderPass,
                                                              VulkanRenderPassSubpassIndex,
                                                              nil,
                                                              0);

     try

      VulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageMeshVertex);
      if DepthPrePass then begin
       if AlphaMode=TpvScene3D.TMaterial.TAlphaMode.Mask then begin
        VulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageMeshDepthMaskedFragment);
       end else begin
        VulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageMeshDepthFragment);
       end;
      end else begin
       if AlphaMode=TpvScene3D.TMaterial.TAlphaMode.Mask then begin
        VulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageMeshMaskedFragment);
       end else begin
        VulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageMeshFragment);
       end;
      end;

      VulkanGraphicsPipeline.InputAssemblyState.Topology:=TVkPrimitiveTopology(PrimitiveTopology);
      VulkanGraphicsPipeline.InputAssemblyState.PrimitiveRestartEnable:=false;

      VulkanGraphicsPipeline.VertexInputState.AddVertexInputBindingDescription(0,SizeOf(TpvScene3D.TVertex),VK_VERTEX_INPUT_RATE_VERTEX);
      VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(0,0,VK_FORMAT_R32G32B32_SFLOAT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.Position)));
      VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(1,0,VK_FORMAT_R32_UINT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.NodeIndex)));
      VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(2,0,VK_FORMAT_R16G16_SNORM,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.Normal)));
      VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(3,0,VK_FORMAT_R16G16_SNORM,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.Tangent)));
      VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(4,0,VK_FORMAT_R32G32_SFLOAT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.TexCoord0)));
      VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(5,0,VK_FORMAT_R32G32_SFLOAT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.TexCoord1)));
      VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(6,0,VK_FORMAT_R16G16B16A16_SFLOAT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.Color0)));
      VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(7,0,VK_FORMAT_R32_UINT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.MorphTargetVertexBaseIndex)));
      VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(8,0,VK_FORMAT_R32_UINT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.JointBlockBaseIndex)));
      VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(9,0,VK_FORMAT_R32_UINT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.CountJointBlocks)));
      VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(10,0,VK_FORMAT_R32_UINT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.Flags)));

      VulkanGraphicsPipeline.ViewPortState.AddViewPort(0.0,0.0,pvApplication.VulkanSwapChain.Width,pvApplication.VulkanSwapChain.Height,0.0,1.0);
      VulkanGraphicsPipeline.ViewPortState.AddScissor(0,0,pvApplication.VulkanSwapChain.Width,pvApplication.VulkanSwapChain.Height);

      VulkanGraphicsPipeline.RasterizationState.DepthClampEnable:=false;
      VulkanGraphicsPipeline.RasterizationState.RasterizerDiscardEnable:=false;
      VulkanGraphicsPipeline.RasterizationState.PolygonMode:=VK_POLYGON_MODE_FILL;
      if DoubleSided then begin
       VulkanGraphicsPipeline.RasterizationState.CullMode:=TVkCullModeFlags(VK_CULL_MODE_NONE);
      end else begin
       VulkanGraphicsPipeline.RasterizationState.CullMode:=TVkCullModeFlags(VK_CULL_MODE_BACK_BIT);
      end;
      VulkanGraphicsPipeline.RasterizationState.FrontFace:=VK_FRONT_FACE_COUNTER_CLOCKWISE;
      VulkanGraphicsPipeline.RasterizationState.DepthBiasEnable:=false;
      VulkanGraphicsPipeline.RasterizationState.DepthBiasConstantFactor:=0.0;
      VulkanGraphicsPipeline.RasterizationState.DepthBiasClamp:=0.0;
      VulkanGraphicsPipeline.RasterizationState.DepthBiasSlopeFactor:=0.0;
      VulkanGraphicsPipeline.RasterizationState.LineWidth:=1.0;

      VulkanGraphicsPipeline.MultisampleState.RasterizationSamples:=fParent.fVulkanSampleCountFlagBits;
      VulkanGraphicsPipeline.MultisampleState.SampleShadingEnable:=false;
      VulkanGraphicsPipeline.MultisampleState.MinSampleShading:=0.0;
      VulkanGraphicsPipeline.MultisampleState.CountSampleMasks:=0;
      VulkanGraphicsPipeline.MultisampleState.AlphaToCoverageEnable:=false;
      VulkanGraphicsPipeline.MultisampleState.AlphaToOneEnable:=false;

      VulkanGraphicsPipeline.ColorBlendState.LogicOpEnable:=false;
      VulkanGraphicsPipeline.ColorBlendState.LogicOp:=VK_LOGIC_OP_COPY;
      VulkanGraphicsPipeline.ColorBlendState.BlendConstants[0]:=0.0;
      VulkanGraphicsPipeline.ColorBlendState.BlendConstants[1]:=0.0;
      VulkanGraphicsPipeline.ColorBlendState.BlendConstants[2]:=0.0;
      VulkanGraphicsPipeline.ColorBlendState.BlendConstants[3]:=0.0;
      if DepthPrePass then begin
       VulkanGraphicsPipeline.ColorBlendState.AddColorBlendAttachmentState(false,
                                                                           VK_BLEND_FACTOR_ZERO,
                                                                           VK_BLEND_FACTOR_ZERO,
                                                                           VK_BLEND_OP_ADD,
                                                                           VK_BLEND_FACTOR_ZERO,
                                                                           VK_BLEND_FACTOR_ZERO,
                                                                           VK_BLEND_OP_ADD,
                                                                           0);
      end else begin
       if AlphaMode=TpvScene3D.TMaterial.TAlphaMode.Blend then begin
        VulkanGraphicsPipeline.ColorBlendState.AddColorBlendAttachmentState(true,
                                                                            VK_BLEND_FACTOR_SRC_ALPHA,
                                                                            VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
                                                                            VK_BLEND_OP_ADD,
                                                                            VK_BLEND_FACTOR_ONE,
                                                                            VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
                                                                            VK_BLEND_OP_ADD,
                                                                            TVkColorComponentFlags(VK_COLOR_COMPONENT_R_BIT) or
                                                                            TVkColorComponentFlags(VK_COLOR_COMPONENT_G_BIT) or
                                                                            TVkColorComponentFlags(VK_COLOR_COMPONENT_B_BIT) or
                                                                            TVkColorComponentFlags(VK_COLOR_COMPONENT_A_BIT));
       end else begin
        VulkanGraphicsPipeline.ColorBlendState.AddColorBlendAttachmentState(false,
                                                                            VK_BLEND_FACTOR_ZERO,
                                                                            VK_BLEND_FACTOR_ZERO,
                                                                            VK_BLEND_OP_ADD,
                                                                            VK_BLEND_FACTOR_ZERO,
                                                                            VK_BLEND_FACTOR_ZERO,
                                                                            VK_BLEND_OP_ADD,
                                                                            TVkColorComponentFlags(VK_COLOR_COMPONENT_R_BIT) or
                                                                            TVkColorComponentFlags(VK_COLOR_COMPONENT_G_BIT) or
                                                                            TVkColorComponentFlags(VK_COLOR_COMPONENT_B_BIT) or
                                                                            TVkColorComponentFlags(VK_COLOR_COMPONENT_A_BIT));
       end;
      end;

      VulkanGraphicsPipeline.DepthStencilState.DepthTestEnable:=true;
      VulkanGraphicsPipeline.DepthStencilState.DepthWriteEnable:=AlphaMode<>TpvScene3D.TMaterial.TAlphaMode.Blend;
      if UnitApplication.Application.VirtualReality.ZFar<0.0 then begin
       VulkanGraphicsPipeline.DepthStencilState.DepthCompareOp:=VK_COMPARE_OP_GREATER_OR_EQUAL;
      end else begin
       VulkanGraphicsPipeline.DepthStencilState.DepthCompareOp:=VK_COMPARE_OP_LESS_OR_EQUAL;
      end;
      VulkanGraphicsPipeline.DepthStencilState.DepthBoundsTestEnable:=false;
      VulkanGraphicsPipeline.DepthStencilState.StencilTestEnable:=false;

      VulkanGraphicsPipeline.Initialize;

      VulkanGraphicsPipeline.FreeMemory;

     finally
      fVulkanGraphicsPipelines[DepthPrePass,AlphaMode,PrimitiveTopology,DoubleSided]:=VulkanGraphicsPipeline;
     end;

    end;

   end;

  end;

 end;

 fSkyBox.AfterCreateSwapChain(fVulkanRenderPass,
                              fParent.fWidth,
                              fParent.fHeight,
                              fParent.fVulkanSampleCountFlagBits);

end;

procedure TScreenMain.TForwardRenderPass.BeforeDestroySwapChain;
var Index:TpvSizeInt;
    DepthPrePass:boolean;
    AlphaMode:TpvScene3D.TMaterial.TAlphaMode;
    PrimitiveTopology:TpvScene3D.TPrimitiveTopology;
    DoubleSided:TpvScene3D.TDoubleSided;
begin
 fSkyBox.BeforeDestroySwapChain;
 for DepthPrePass:=false to fParent.fUseDepthPrepass do begin
  for AlphaMode:=Low(TpvScene3D.TMaterial.TAlphaMode) to High(TpvScene3D.TMaterial.TAlphaMode) do begin
   for PrimitiveTopology:=Low(TpvScene3D.TPrimitiveTopology) to High(TpvScene3D.TPrimitiveTopology) do begin
    for DoubleSided:=Low(TpvScene3D.TDoubleSided) to High(TpvScene3D.TDoubleSided) do begin
     FreeAndNil(fVulkanGraphicsPipelines[DepthPrePass,AlphaMode,PrimitiveTopology,DoubleSided]);
    end;
   end;
  end;
 end;
 FreeAndNil(fVulkanPipelineLayout);
 for Index:=0 to length(fGlobalVulkanDescriptorSets)-1 do begin
  FreeAndNil(fGlobalVulkanDescriptorSets[Index]);
 end;
 FreeAndNil(fGlobalVulkanDescriptorPool);
 FreeAndNil(fGlobalVulkanDescriptorSetLayout);
 inherited BeforeDestroySwapChain;
end;

procedure TScreenMain.TForwardRenderPass.Update(const aUpdateSwapChainImageIndex,aUpdateFrameIndex:TpvSizeInt);
begin
 inherited Update(aUpdateSwapChainImageIndex,aUpdateFrameIndex);
end;

procedure TScreenMain.TForwardRenderPass.Execute(const aCommandBuffer:TpvVulkanCommandBuffer;
                                                          const aSwapChainImageIndex,aFrameIndex:TpvSizeInt);
var SwapChainImageState:TScreenMain.PSwapChainImageState;
begin
 inherited Execute(aCommandBuffer,aSwapChainImageIndex,aFrameIndex);

 SwapChainImageState:=@fParent.fSwapChainImageStates[aSwapChainImageIndex];

 if SwapChainImageState^.Ready then begin

  fSkyBox.Draw(aSwapChainImageIndex,
               SwapChainImageState^.FinalViewIndex,
               SwapChainImageState^.CountViews,
               aCommandBuffer);

  aCommandBuffer.CmdBindDescriptorSets(VK_PIPELINE_BIND_POINT_GRAPHICS,
                                       fVulkanPipelineLayout.Handle,
                                       3,
                                       1,
                                       @fGlobalVulkanDescriptorSets[aSwapChainImageIndex].Handle,
                                       0,
                                       nil);

  if fParent.fUseDepthPrepass then begin

   fParent.fScene3D.Draw(fVulkanGraphicsPipelines[true,TpvScene3D.TMaterial.TAlphaMode.Opaque],
                         aSwapChainImageIndex,
                         0,
                         SwapChainImageState^.FinalViewIndex,
                         SwapChainImageState^.CountViews,
                         aCommandBuffer,
                         fVulkanPipelineLayout,
                         [TpvScene3D.TMaterial.TAlphaMode.Opaque]);

   fParent.fScene3D.Draw(fVulkanGraphicsPipelines[true,TpvScene3D.TMaterial.TAlphaMode.Mask],
                         aSwapChainImageIndex,
                         0,
                         SwapChainImageState^.FinalViewIndex,
                         SwapChainImageState^.CountViews,
                         aCommandBuffer,
                         fVulkanPipelineLayout,
                         [TpvScene3D.TMaterial.TAlphaMode.Mask]);

  end;

  fParent.fScene3D.Draw(fVulkanGraphicsPipelines[false,TpvScene3D.TMaterial.TAlphaMode.Opaque],
                        aSwapChainImageIndex,
                        0,
                        SwapChainImageState^.FinalViewIndex,
                        SwapChainImageState^.CountViews,
                        aCommandBuffer,
                        fVulkanPipelineLayout,
                        [TpvScene3D.TMaterial.TAlphaMode.Opaque]);

{ fParent.fScene3D.Draw(fVulkanGraphicsPipelines[false,TpvScene3D.TMaterial.TAlphaMode.Mask],
                        aSwapChainImageIndex,
                        0,
                        SwapChainImageState^.FinalViewIndex,
                        SwapChainImageState^.CountViews,
                        aCommandBuffer,
                        fVulkanPipelineLayout,
                        [TpvScene3D.TMaterial.TAlphaMode.Mask]);

  fParent.fScene3D.Draw(fVulkanGraphicsPipelines[false,TpvScene3D.TMaterial.TAlphaMode.Blend],
                        aSwapChainImageIndex,
                        0,
                        SwapChainImageState^.FinalViewIndex,
                        SwapChainImageState^.CountViews,
                        aCommandBuffer,
                        fVulkanPipelineLayout,
                        [TpvScene3D.TMaterial.TAlphaMode.Blend]); }

{ if fParent.fUseDepthPrepass then begin

   fParent.fScene3D.Draw(fVulkanGraphicsPipelines[true,TpvScene3D.TMaterial.TAlphaMode.Mask],
                         aSwapChainImageIndex,
                         0,
                         SwapChainImageState^.FinalViewIndex,
                         SwapChainImageState^.CountViews,
                         aCommandBuffer,
                         fVulkanPipelineLayout,
                         [TpvScene3D.TMaterial.TAlphaMode.Mask]);

  end;}

 end;

end;

{ TScreenMain.TOrderIndependentTransparencyClearCustomPass }

constructor TScreenMain.TOrderIndependentTransparencyClearCustomPass.Create(const aFrameGraph:TpvFrameGraph;const aParent:TScreenMain);
begin
 inherited Create(aFrameGraph);
 fParent:=aParent;
 Name:='OrderIndependentTransparencyClear';
end;

destructor TScreenMain.TOrderIndependentTransparencyClearCustomPass.Destroy;
begin
 inherited Destroy;
end;

procedure TScreenMain.TOrderIndependentTransparencyClearCustomPass.Show;
begin
 inherited Show;
end;

procedure TScreenMain.TOrderIndependentTransparencyClearCustomPass.Hide;
begin
 inherited Hide;
end;

procedure TScreenMain.TOrderIndependentTransparencyClearCustomPass.AfterCreateSwapChain;
begin
 inherited AfterCreateSwapChain;
end;

procedure TScreenMain.TOrderIndependentTransparencyClearCustomPass.BeforeDestroySwapChain;
begin
 inherited BeforeDestroySwapChain;
end;

procedure TScreenMain.TOrderIndependentTransparencyClearCustomPass.Update(const aUpdateSwapChainImageIndex,aUpdateFrameIndex:TpvSizeInt);
begin
 inherited Update(aUpdateSwapChainImageIndex,aUpdateFrameIndex);
end;

procedure TScreenMain.TOrderIndependentTransparencyClearCustomPass.Execute(const aCommandBuffer:TpvVulkanCommandBuffer;const aSwapChainImageIndex,aFrameIndex:TpvSizeInt);
var ClearValue:TVkClearColorValue;
    ClearRanges:TVkImageSubresourceRange;
    MemoryBarrier:TVkMemoryBarrier;
begin
 inherited Execute(aCommandBuffer,aSwapChainImageIndex,aFrameIndex);

 ClearValue.uint32[0]:=0;
 ClearValue.uint32[1]:=0;
 ClearValue.uint32[2]:=0;
 ClearValue.uint32[3]:=0;

//FillChar(ClearRanges,SizeOf(TVkImageSubresourceRange),#0);
 ClearRanges.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
 ClearRanges.baseArrayLayer:=0;
 ClearRanges.baseMipLevel:=0;
 ClearRanges.layerCount:=fParent.fCountSurfaceViews;
 ClearRanges.levelCount:=1;

 aCommandBuffer.CmdClearColorImage(fParent.fOrderIndependentTransparencyAuxImages[aSwapChainImageIndex].VulkanImage.Handle,
                                   VK_IMAGE_LAYOUT_GENERAL,
                                   @ClearValue,
                                   1,
                                   @ClearRanges);

 aCommandBuffer.CmdClearColorImage(fParent.fOrderIndependentTransparencySpinLockImages[aSwapChainImageIndex].VulkanImage.Handle,
                                   VK_IMAGE_LAYOUT_GENERAL,
                                   @ClearValue,
                                   1,
                                   @ClearRanges);

 MemoryBarrier:=TVkMemoryBarrier.Create(TVkAccessFlags(VK_ACCESS_TRANSFER_WRITE_BIT),
                                        TVkAccessFlags(VK_ACCESS_SHADER_READ_BIT) or TVkAccessFlags(VK_ACCESS_SHADER_WRITE_BIT));

 aCommandBuffer.CmdPipelineBarrier(TVkPipelineStageFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
                                   TVkPipelineStageFlags(VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT),
                                   TVkDependencyFlags(VK_DEPENDENCY_BY_REGION_BIT),
                                   1,
                                   @MemoryBarrier,
                                   0,
                                   nil,
                                   0,
                                   nil);

end;

{ TScreenMain.TOrderIndependentTransparencyRenderPass }

constructor TScreenMain.TOrderIndependentTransparencyRenderPass.Create(const aFrameGraph:TpvFrameGraph;const aParent:TScreenMain);
begin
inherited Create(aFrameGraph);

 fParent:=aParent;

 Name:='OrderIndependentTransparencyRendering';

 MultiviewMask:=fParent.fSurfaceMultiviewMask;

 Queue:=aFrameGraph.UniversalQueue;

 Size:=TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.SurfaceDependent,
                                       1.0,
                                       1.0,
                                       1.0,
                                       fParent.fCountSurfaceViews);

 fResourceCascadedShadowMap:=AddImageInput('resourcetype_cascadedshadowmap_data',
                                           'cascadedshadowmap_data_final',
                                           VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                                           []
                                          );

 if fParent.fVulkanSampleCountFlagBits=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT) then begin

  fResourceDepth:=AddImageDepthInput('resourcetype_depth',
                                     'forwardrendering_depth',
                                     VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL,//VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                                     [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                    );

  fResourceColor:=AddImageOutput('resourcetype_color',
                                 'orderindependenttransparency_tailblending_color',
                                 VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                                 TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.Clear,
                                                              TpvVector4.InlineableCreate(0.0,0.0,0.0,0.0)),
                                 [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                );

 end else begin

  fResourceDepth:=AddImageDepthInput('resourcetype_msaa_depth',
                                     'forwardrendering_msaa_depth',
                                     VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL,//VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                                     [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                    );

  fResourceColor:=AddImageOutput('resourcetype_msaa_color',
                                 'orderindependenttransparency_tailblending_msaa_color',
                                 VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                                 TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.Clear,
                                                              TpvVector4.InlineableCreate(0.0,0.0,0.0,0.0)),
                                 [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                );

  fResourceColor:=AddImageResolveOutput('resourcetype_color',
                                        'orderindependenttransparency_tailblending_color',
                                        'orderindependenttransparency_tailblending_msaa_color',
                                        VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                                        TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.DontCare,
                                                                     TpvVector4.InlineableCreate(0.0,0.0,0.0,0.0)),
                                        [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                       );

 end;

end;

destructor TScreenMain.TOrderIndependentTransparencyRenderPass.Destroy;
begin
 inherited Destroy;
end;

procedure TScreenMain.TOrderIndependentTransparencyRenderPass.Show;
var Index:TpvSizeInt;
    Stream:TStream;
    OITVariant:TpvUTF8String;
begin
 inherited Show;

 fVulkanGraphicsCommandBuffer:=TpvVulkanCommandBuffer.Create(FrameGraph.GraphicsQueue.CommandPool,VK_COMMAND_BUFFER_LEVEL_PRIMARY);

 fVulkanGraphicsCommandBufferFence:=TpvVulkanFence.Create(pvApplication.VulkanDevice);

 fVulkanTransferCommandBuffer:=TpvVulkanCommandBuffer.Create(FrameGraph.TransferQueue.CommandPool,VK_COMMAND_BUFFER_LEVEL_PRIMARY);

 fVulkanTransferCommandBufferFence:=TpvVulkanFence.Create(pvApplication.VulkanDevice);

 Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_vert.spv');
 try
  fMeshVertexShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 case TpvVulkanVendorID(pvApplication.VulkanDevice.PhysicalDevice.Properties.vendorID) of
  TpvVulkanVendorID.AMD:begin
   if pvApplication.VulkanDevice.EnabledExtensionNames.IndexOf(VK_EXT_POST_DEPTH_COVERAGE_EXTENSION_NAME)>0 then begin
    // >= RDNA, since VK_EXT_post_depth_coverage exists just from RDNA on.
    OITVariant:='spinlock';
   end else begin
    OITVariant:='simple';
   end;
  end;
  TpvVulkanVendorID.NVIDIA,
  TpvVulkanVendorID.Intel:begin
   if pvApplication.VulkanDevice.EnabledExtensionNames.IndexOf(VK_EXT_POST_DEPTH_COVERAGE_EXTENSION_NAME)>0 then begin
    if (pvApplication.VulkanDevice.EnabledExtensionNames.IndexOf(VK_EXT_FRAGMENT_SHADER_INTERLOCK_EXTENSION_NAME)>0) and
       (pvApplication.VulkanFragmentShaderSampleInterlock or pvApplication.VulkanFragmentShaderPixelInterlock) then begin
     OITVariant:='interlock';
    end else begin
     OITVariant:='spinlock';
    end;
   end else begin
    OITVariant:='simple';
   end;
  end;
  else begin
   OITVariant:='simple';
  end;
 end;

 if fParent.fVulkanSampleCountFlagBits=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT) then begin
  if UnitApplication.Application.VirtualReality.ZFar<0.0 then begin
   Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_oit_'+OITVariant+'_reversedz_frag.spv');
  end else begin
   Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_oit_'+OITVariant+'_frag.spv');
  end;
 end else begin
  if UnitApplication.Application.VirtualReality.ZFar<0.0 then begin
   Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_oit_msaa_'+OITVariant+'_reversedz_frag.spv');
  end else begin
   Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_oit_msaa_'+OITVariant+'_frag.spv');
  end;
 end;
 try
  fMeshFragmentShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 if UnitApplication.Application.VirtualReality.ZFar<0.0 then begin
  Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_oit_'+OITVariant+'_reversedz_masked_frag.spv');
 end else begin
  Stream:=pvApplication.Assets.GetAssetStream('shaders/mesh_oit_'+OITVariant+'_masked_frag.spv');
 end;
 try
  fMeshMaskedFragmentShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 fVulkanPipelineShaderStageMeshVertex:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_VERTEX_BIT,fMeshVertexShaderModule,'main');

 fVulkanPipelineShaderStageMeshFragment:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_FRAGMENT_BIT,fMeshFragmentShaderModule,'main');

 fVulkanPipelineShaderStageMeshMaskedFragment:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_FRAGMENT_BIT,fMeshMaskedFragmentShaderModule,'main');

 fVulkanCascadedShadowMapSampler:=TpvVulkanSampler.Create(pvApplication.VulkanDevice,
                                                          TVkFilter.VK_FILTER_LINEAR,
                                                          TVkFilter.VK_FILTER_LINEAR,
                                                          TVkSamplerMipmapMode.VK_SAMPLER_MIPMAP_MODE_LINEAR,
                                                          VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
                                                          VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
                                                          VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER,
                                                          0.0,
                                                          false,
                                                          0.0,
                                                          false,
                                                          VK_COMPARE_OP_ALWAYS,
                                                          0.0,
                                                          0.0,
                                                          VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE,
                                                          false);

end;

procedure TScreenMain.TOrderIndependentTransparencyRenderPass.Hide;
begin

 FreeAndNil(fVulkanCascadedShadowMapSampler);

 FreeAndNil(fVulkanPipelineShaderStageMeshVertex);

 FreeAndNil(fVulkanPipelineShaderStageMeshFragment);

 FreeAndNil(fVulkanPipelineShaderStageMeshMaskedFragment);

 FreeAndNil(fMeshVertexShaderModule);

 FreeAndNil(fMeshFragmentShaderModule);

 FreeAndNil(fMeshMaskedFragmentShaderModule);

 FreeAndNil(fVulkanTransferCommandBufferFence);
 FreeAndNil(fVulkanTransferCommandBuffer);
 FreeAndNil(fVulkanGraphicsCommandBufferFence);
 FreeAndNil(fVulkanGraphicsCommandBuffer);
 inherited Hide;
end;

procedure TScreenMain.TOrderIndependentTransparencyRenderPass.AfterCreateSwapChain;
var SwapChainImageIndex:TpvSizeInt;
    AlphaMode:TpvScene3D.TMaterial.TAlphaMode;
    PrimitiveTopology:TpvScene3D.TPrimitiveTopology;
    DoubleSided:TpvScene3D.TDoubleSided;
    VulkanGraphicsPipeline:TpvVulkanGraphicsPipeline;
begin

 inherited AfterCreateSwapChain;

 fVulkanRenderPass:=VulkanRenderPass;

 fGlobalVulkanDescriptorSetLayout:=TpvVulkanDescriptorSetLayout.Create(pvApplication.VulkanDevice);
 fGlobalVulkanDescriptorSetLayout.AddBinding(0,
                                             VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                                             3,
                                             TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                             []);
 fGlobalVulkanDescriptorSetLayout.AddBinding(1,
                                             VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                                             3,
                                             TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                             []);
 fGlobalVulkanDescriptorSetLayout.AddBinding(2,
                                             VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                                             1,
                                             TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                             []);
 fGlobalVulkanDescriptorSetLayout.AddBinding(3,
                                             VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                                             1,
                                             TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                             []);
 fGlobalVulkanDescriptorSetLayout.AddBinding(4,
                                             VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT,
                                             1,
                                             TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                             []);
 fGlobalVulkanDescriptorSetLayout.AddBinding(5,
                                             VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER,
                                             1,
                                             TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                             []);
 fGlobalVulkanDescriptorSetLayout.AddBinding(6,
                                             VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
                                             1,
                                             TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                             []);
 fGlobalVulkanDescriptorSetLayout.AddBinding(7,
                                             VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
                                             1,
                                             TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                             []);
 fGlobalVulkanDescriptorSetLayout.AddBinding(8,
                                             VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                                             1,
                                             TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                             []);
 fGlobalVulkanDescriptorSetLayout.Initialize;

 fGlobalVulkanDescriptorPool:=TpvVulkanDescriptorPool.Create(pvApplication.VulkanDevice,TVkDescriptorPoolCreateFlags(VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT),length(fGlobalVulkanDescriptorSets));
 fGlobalVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,7*length(fGlobalVulkanDescriptorSets));
 fGlobalVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT,length(fGlobalVulkanDescriptorSets));
 fGlobalVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,2*length(fGlobalVulkanDescriptorSets));
 fGlobalVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER,1*length(fGlobalVulkanDescriptorSets));
 fGlobalVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,2*length(fGlobalVulkanDescriptorSets));
 fGlobalVulkanDescriptorPool.Initialize;

 for SwapChainImageIndex:=0 to FrameGraph.CountSwapChainImages-1 do begin
  fGlobalVulkanDescriptorSets[SwapChainImageIndex]:=TpvVulkanDescriptorSet.Create(fGlobalVulkanDescriptorPool,
                                                                                  fGlobalVulkanDescriptorSetLayout);
  fGlobalVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(0,
                                                                        0,
                                                                        3,
                                                                        TVkDescriptorType(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER),
                                                                        [fParent.fGGXBRDF.DescriptorImageInfo,
                                                                         fParent.fCharlieBRDF.DescriptorImageInfo,
                                                                         fParent.fSheenELUT.DescriptorImageInfo],
                                                                        [],
                                                                        [],
                                                                        false);
  fGlobalVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(1,
                                                                        0,
                                                                        3,
                                                                        TVkDescriptorType(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER),
                                                                        [fParent.fGGXEnvMapCubeMap.DescriptorImageInfo,
                                                                         fParent.fCharlieEnvMapCubeMap.DescriptorImageInfo,
                                                                         fParent.fLambertianEnvMapCubeMap.DescriptorImageInfo],
                                                                        [],
                                                                        [],
                                                                        false);
  fGlobalVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(2,
                                                                        0,
                                                                        1,
                                                                        TVkDescriptorType(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER),
                                                                        [],
                                                                        [fParent.fCascadedShadowMapVulkanUniformBuffers[SwapChainImageIndex].DescriptorBufferInfo],
                                                                        [],
                                                                        false);
  fGlobalVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(3,
                                                                        0,
                                                                        1,
                                                                        TVkDescriptorType(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER),
                                                                        [TVkDescriptorImageInfo.Create(fVulkanCascadedShadowMapSampler.Handle,
                                                                                                       fResourceCascadedShadowMap.VulkanImageViews[SwapChainImageIndex].Handle,
                                                                                                       fResourceCascadedShadowMap.ResourceTransition.Layout)],// TVkImageLayout(VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL))],
                                                                        [],
                                                                        [],
                                                                        false);
  fGlobalVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(4,
                                                                        0,
                                                                        1,
                                                                        TVkDescriptorType(VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT),
                                                                        [TVkDescriptorImageInfo.Create(VK_NULL_HANDLE,
                                                                                                       fResourceDepth.VulkanImageViews[SwapChainImageIndex].Handle,
                                                                                                       fResourceDepth.ResourceTransition.Layout)],// TVkImageLayout(VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL))],
                                                                        [],
                                                                        [],
                                                                        false);
  fGlobalVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(5,
                                                                        0,
                                                                        1,
                                                                        TVkDescriptorType(VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER),
                                                                        [],
                                                                        [],
                                                                        [fParent.fOrderIndependentTransparencyABufferBuffers[SwapChainImageIndex].VulkanBufferView.Handle],
                                                                        false);
  fGlobalVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(6,
                                                                        0,
                                                                        1,
                                                                        TVkDescriptorType(VK_DESCRIPTOR_TYPE_STORAGE_IMAGE),
                                                                        [fParent.fOrderIndependentTransparencyAuxImages[SwapChainImageIndex].DescriptorImageInfo],
                                                                        [],
                                                                        [],
                                                                        false);
  fGlobalVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(7,
                                                                        0,
                                                                        1,
                                                                        TVkDescriptorType(VK_DESCRIPTOR_TYPE_STORAGE_IMAGE),
                                                                        [fParent.fOrderIndependentTransparencySpinLockImages[SwapChainImageIndex].DescriptorImageInfo],
                                                                        [],
                                                                        [],
                                                                        false);
  fGlobalVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(8,
                                                                        0,
                                                                        1,
                                                                        TVkDescriptorType(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER),
                                                                        [],
                                                                        [fParent.fOrderIndependentTransparentUniformVulkanBuffer.DescriptorBufferInfo],
                                                                        [],
                                                                        false);
  fGlobalVulkanDescriptorSets[SwapChainImageIndex].Flush;
 end;

 fVulkanPipelineLayout:=TpvVulkanPipelineLayout.Create(pvApplication.VulkanDevice);
 fVulkanPipelineLayout.AddPushConstantRange(TVkShaderStageFlags(VK_SHADER_STAGE_VERTEX_BIT),0,SizeOf(TpvScene3D.TVertexStagePushConstants));
 fVulkanPipelineLayout.AddDescriptorSetLayout(fParent.fScene3D.MeshVulkanDescriptorSetLayout);
 fVulkanPipelineLayout.AddDescriptorSetLayout(fParent.fScene3D.MaterialVulkanDescriptorSetLayout);
 fVulkanPipelineLayout.AddDescriptorSetLayout(fParent.fScene3D.GlobalVulkanDescriptorSetLayout);
 fVulkanPipelineLayout.AddDescriptorSetLayout(fGlobalVulkanDescriptorSetLayout);
 fVulkanPipelineLayout.Initialize;

 for AlphaMode:=Low(TpvScene3D.TMaterial.TAlphaMode) to High(TpvScene3D.TMaterial.TAlphaMode) do begin
  for PrimitiveTopology:=Low(TpvScene3D.TPrimitiveTopology) to High(TpvScene3D.TPrimitiveTopology) do begin
   for DoubleSided:=Low(TpvScene3D.TDoubleSided) to High(TpvScene3D.TDoubleSided) do begin
    FreeAndNil(fVulkanGraphicsPipelines[AlphaMode,PrimitiveTopology,DoubleSided]);
   end;
  end;
 end;

 for AlphaMode:=Low(TpvScene3D.TMaterial.TAlphaMode) to High(TpvScene3D.TMaterial.TAlphaMode) do begin

  if AlphaMode=TpvScene3D.TMaterial.TAlphaMode.Opaque then begin
   continue;
  end;

  for PrimitiveTopology:=Low(TpvScene3D.TPrimitiveTopology) to High(TpvScene3D.TPrimitiveTopology) do begin

   for DoubleSided:=Low(TpvScene3D.TDoubleSided) to High(TpvScene3D.TDoubleSided) do begin

    VulkanGraphicsPipeline:=TpvVulkanGraphicsPipeline.Create(pvApplication.VulkanDevice,
                                                             pvApplication.VulkanPipelineCache,
                                                             0,
                                                             [],
                                                             fVulkanPipelineLayout,
                                                             fVulkanRenderPass,
                                                             VulkanRenderPassSubpassIndex,
                                                             nil,
                                                             0);

    try

     VulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageMeshVertex);
     if AlphaMode=TpvScene3D.TMaterial.TAlphaMode.Mask then begin
      VulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageMeshMaskedFragment);
     end else begin
      VulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageMeshFragment);
     end;

     VulkanGraphicsPipeline.InputAssemblyState.Topology:=TVkPrimitiveTopology(PrimitiveTopology);
     VulkanGraphicsPipeline.InputAssemblyState.PrimitiveRestartEnable:=false;

     VulkanGraphicsPipeline.VertexInputState.AddVertexInputBindingDescription(0,SizeOf(TpvScene3D.TVertex),VK_VERTEX_INPUT_RATE_VERTEX);
     VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(0,0,VK_FORMAT_R32G32B32_SFLOAT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.Position)));
     VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(1,0,VK_FORMAT_R32_UINT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.NodeIndex)));
     VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(2,0,VK_FORMAT_R16G16_SNORM,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.Normal)));
     VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(3,0,VK_FORMAT_R16G16_SNORM,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.Tangent)));
     VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(4,0,VK_FORMAT_R32G32_SFLOAT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.TexCoord0)));
     VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(5,0,VK_FORMAT_R32G32_SFLOAT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.TexCoord1)));
     VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(6,0,VK_FORMAT_R16G16B16A16_SFLOAT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.Color0)));
     VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(7,0,VK_FORMAT_R32_UINT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.MorphTargetVertexBaseIndex)));
     VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(8,0,VK_FORMAT_R32_UINT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.JointBlockBaseIndex)));
     VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(9,0,VK_FORMAT_R32_UINT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.CountJointBlocks)));
     VulkanGraphicsPipeline.VertexInputState.AddVertexInputAttributeDescription(10,0,VK_FORMAT_R32_UINT,TVkPtrUInt(pointer(@TpvScene3D.PVertex(nil)^.Flags)));

     VulkanGraphicsPipeline.ViewPortState.AddViewPort(0.0,0.0,pvApplication.VulkanSwapChain.Width,pvApplication.VulkanSwapChain.Height,0.0,1.0);
     VulkanGraphicsPipeline.ViewPortState.AddScissor(0,0,pvApplication.VulkanSwapChain.Width,pvApplication.VulkanSwapChain.Height);

     VulkanGraphicsPipeline.RasterizationState.DepthClampEnable:=false;
     VulkanGraphicsPipeline.RasterizationState.RasterizerDiscardEnable:=false;
     VulkanGraphicsPipeline.RasterizationState.PolygonMode:=VK_POLYGON_MODE_FILL;
     if DoubleSided then begin
      VulkanGraphicsPipeline.RasterizationState.CullMode:=TVkCullModeFlags(VK_CULL_MODE_NONE);
     end else begin
      VulkanGraphicsPipeline.RasterizationState.CullMode:=TVkCullModeFlags(VK_CULL_MODE_BACK_BIT);
     end;
     VulkanGraphicsPipeline.RasterizationState.FrontFace:=VK_FRONT_FACE_COUNTER_CLOCKWISE;
     VulkanGraphicsPipeline.RasterizationState.DepthBiasEnable:=false;
     VulkanGraphicsPipeline.RasterizationState.DepthBiasConstantFactor:=0.0;
     VulkanGraphicsPipeline.RasterizationState.DepthBiasClamp:=0.0;
     VulkanGraphicsPipeline.RasterizationState.DepthBiasSlopeFactor:=0.0;
     VulkanGraphicsPipeline.RasterizationState.LineWidth:=1.0;

     VulkanGraphicsPipeline.MultisampleState.RasterizationSamples:=fParent.fVulkanSampleCountFlagBits;
     if (AlphaMode=TpvScene3D.TMaterial.TAlphaMode.Mask) and (VulkanGraphicsPipeline.MultisampleState.RasterizationSamples<>VK_SAMPLE_COUNT_1_BIT) then begin
      VulkanGraphicsPipeline.MultisampleState.SampleShadingEnable:=true;
      VulkanGraphicsPipeline.MultisampleState.MinSampleShading:=1.0;
      VulkanGraphicsPipeline.MultisampleState.CountSampleMasks:=0;
      VulkanGraphicsPipeline.MultisampleState.AlphaToCoverageEnable:=true;
      VulkanGraphicsPipeline.MultisampleState.AlphaToOneEnable:=false;
     end else begin
      VulkanGraphicsPipeline.MultisampleState.SampleShadingEnable:=false;
      VulkanGraphicsPipeline.MultisampleState.MinSampleShading:=0.0;
      VulkanGraphicsPipeline.MultisampleState.CountSampleMasks:=0;
      VulkanGraphicsPipeline.MultisampleState.AlphaToCoverageEnable:=false;
      VulkanGraphicsPipeline.MultisampleState.AlphaToOneEnable:=false;
     end;

     VulkanGraphicsPipeline.ColorBlendState.LogicOpEnable:=false;
     VulkanGraphicsPipeline.ColorBlendState.LogicOp:=VK_LOGIC_OP_COPY;
     VulkanGraphicsPipeline.ColorBlendState.BlendConstants[0]:=0.0;
     VulkanGraphicsPipeline.ColorBlendState.BlendConstants[1]:=0.0;
     VulkanGraphicsPipeline.ColorBlendState.BlendConstants[2]:=0.0;
     VulkanGraphicsPipeline.ColorBlendState.BlendConstants[3]:=0.0;
     VulkanGraphicsPipeline.ColorBlendState.AddColorBlendAttachmentState(true,
                                                                         VK_BLEND_FACTOR_ONE,
                                                                         VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
                                                                         VK_BLEND_OP_ADD,
                                                                         VK_BLEND_FACTOR_ONE,
                                                                         VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
                                                                         VK_BLEND_OP_ADD,
                                                                         TVkColorComponentFlags(VK_COLOR_COMPONENT_R_BIT) or
                                                                         TVkColorComponentFlags(VK_COLOR_COMPONENT_G_BIT) or
                                                                         TVkColorComponentFlags(VK_COLOR_COMPONENT_B_BIT) or
                                                                         TVkColorComponentFlags(VK_COLOR_COMPONENT_A_BIT));

     VulkanGraphicsPipeline.DepthStencilState.DepthTestEnable:=true;
     VulkanGraphicsPipeline.DepthStencilState.DepthWriteEnable:=false;
     if UnitApplication.Application.VirtualReality.ZFar<0.0 then begin
      VulkanGraphicsPipeline.DepthStencilState.DepthCompareOp:=VK_COMPARE_OP_GREATER_OR_EQUAL;
     end else begin
      VulkanGraphicsPipeline.DepthStencilState.DepthCompareOp:=VK_COMPARE_OP_LESS_OR_EQUAL;
     end;
     VulkanGraphicsPipeline.DepthStencilState.DepthBoundsTestEnable:=false;
     VulkanGraphicsPipeline.DepthStencilState.StencilTestEnable:=false;

     VulkanGraphicsPipeline.Initialize;

     VulkanGraphicsPipeline.FreeMemory;

    finally
     fVulkanGraphicsPipelines[AlphaMode,PrimitiveTopology,DoubleSided]:=VulkanGraphicsPipeline;
    end;

   end;

  end;

 end;

end;

procedure TScreenMain.TOrderIndependentTransparencyRenderPass.BeforeDestroySwapChain;
var Index:TpvSizeInt;
    AlphaMode:TpvScene3D.TMaterial.TAlphaMode;
    PrimitiveTopology:TpvScene3D.TPrimitiveTopology;
    DoubleSided:TpvScene3D.TDoubleSided;
begin
 for AlphaMode:=Low(TpvScene3D.TMaterial.TAlphaMode) to High(TpvScene3D.TMaterial.TAlphaMode) do begin
  for PrimitiveTopology:=Low(TpvScene3D.TPrimitiveTopology) to High(TpvScene3D.TPrimitiveTopology) do begin
   for DoubleSided:=Low(TpvScene3D.TDoubleSided) to High(TpvScene3D.TDoubleSided) do begin
    FreeAndNil(fVulkanGraphicsPipelines[AlphaMode,PrimitiveTopology,DoubleSided]);
   end;
  end;
 end;
 FreeAndNil(fVulkanPipelineLayout);
 for Index:=0 to length(fGlobalVulkanDescriptorSets)-1 do begin
  FreeAndNil(fGlobalVulkanDescriptorSets[Index]);
 end;
 FreeAndNil(fGlobalVulkanDescriptorPool);
 FreeAndNil(fGlobalVulkanDescriptorSetLayout);
 inherited BeforeDestroySwapChain;
end;

procedure TScreenMain.TOrderIndependentTransparencyRenderPass.Update(const aUpdateSwapChainImageIndex,aUpdateFrameIndex:TpvSizeInt);
begin
 inherited Update(aUpdateSwapChainImageIndex,aUpdateFrameIndex);
end;

procedure TScreenMain.TOrderIndependentTransparencyRenderPass.Execute(const aCommandBuffer:TpvVulkanCommandBuffer;
                                                                      const aSwapChainImageIndex,aFrameIndex:TpvSizeInt);
var SwapChainImageState:TScreenMain.PSwapChainImageState;
begin
 inherited Execute(aCommandBuffer,aSwapChainImageIndex,aFrameIndex);

 SwapChainImageState:=@fParent.fSwapChainImageStates[aSwapChainImageIndex];

 if SwapChainImageState^.Ready then begin

  aCommandBuffer.CmdBindDescriptorSets(VK_PIPELINE_BIND_POINT_GRAPHICS,
                                       fVulkanPipelineLayout.Handle,
                                       3,
                                       1,
                                       @fGlobalVulkanDescriptorSets[aSwapChainImageIndex].Handle,
                                       0,
                                       nil);

  fParent.fScene3D.Draw(fVulkanGraphicsPipelines[TpvScene3D.TMaterial.TAlphaMode.Mask],
                        aSwapChainImageIndex,
                        0,
                        SwapChainImageState^.FinalViewIndex,
                        SwapChainImageState^.CountViews,
                        aCommandBuffer,
                        fVulkanPipelineLayout,
                        [TpvScene3D.TMaterial.TAlphaMode.Mask]);

  fParent.fScene3D.Draw(fVulkanGraphicsPipelines[TpvScene3D.TMaterial.TAlphaMode.Blend],
                        aSwapChainImageIndex,
                        0,
                        SwapChainImageState^.FinalViewIndex,
                        SwapChainImageState^.CountViews,
                        aCommandBuffer,
                        fVulkanPipelineLayout,
                        [TpvScene3D.TMaterial.TAlphaMode.Blend]);

 end;

end;

{ TScreenMain.TOrderIndependentTransparencyResolveRenderPass }

constructor TScreenMain.TOrderIndependentTransparencyResolveRenderPass.Create(const aFrameGraph:TpvFrameGraph;const aParent:TScreenMain);
begin

 inherited Create(aFrameGraph);

 fParent:=aParent;

 Name:='OrderIndependentTransparencyResolve';

 MultiviewMask:=fParent.fSurfaceMultiviewMask;

 Queue:=aFrameGraph.UniversalQueue;

//SeparatePhysicalPass:=true;

//SeparateCommandBuffer:=true;

 Size:=TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.SurfaceDependent,
                                       1.0,
                                       1.0,
                                       1.0,
                                       fParent.fCountSurfaceViews);

 fResourceOpaque:=AddImageInput('resourcetype_color',
                                'forwardrendering_color',
                                VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                                [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                               );

 fResourceTransparent:=AddImageInput('resourcetype_color',
                                     'orderindependenttransparency_tailblending_color',
                                     VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                                     [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                    );

 fResourceSurface:=AddImageOutput('resourcetype_color',
                                  'orderindependenttransparency_final_color',
                                  VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                                  TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.Clear,
                                                               TpvVector4.InlineableCreate(0.0,0.0,0.0,1.0)),
                                  [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                 );

end;

destructor TScreenMain.TOrderIndependentTransparencyResolveRenderPass.Destroy;
begin
 inherited Destroy;
end;

procedure TScreenMain.TOrderIndependentTransparencyResolveRenderPass.Show;
var Stream:TStream;
begin

 inherited Show;

 fVulkanTransferCommandBuffer:=TpvVulkanCommandBuffer.Create(FrameGraph.TransferQueue.CommandPool,VK_COMMAND_BUFFER_LEVEL_PRIMARY);

 fVulkanTransferCommandBufferFence:=TpvVulkanFence.Create(pvApplication.VulkanDevice);

 Stream:=pvApplication.Assets.GetAssetStream('shaders/fullscreen_vert.spv');
 try
  fVulkanVertexShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 if fParent.fVulkanSampleCountFlagBits=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT) then begin
  if UnitApplication.Application.VirtualReality.ZFar<0.0 then begin
   Stream:=pvApplication.Assets.GetAssetStream('shaders/oit_resolve_reversedz_frag.spv');
  end else begin
   Stream:=pvApplication.Assets.GetAssetStream('shaders/oit_resolve_frag.spv');
  end;
 end else begin
  if UnitApplication.Application.VirtualReality.ZFar<0.0 then begin
   Stream:=pvApplication.Assets.GetAssetStream('shaders/oit_resolve_msaa_reversedz_frag.spv');
  end else begin
   Stream:=pvApplication.Assets.GetAssetStream('shaders/oit_resolve_msaa_frag.spv');
  end;
 end;
 try
  fVulkanFragmentShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 fVulkanPipelineShaderStageVertex:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_VERTEX_BIT,fVulkanVertexShaderModule,'main');

 fVulkanPipelineShaderStageFragment:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_FRAGMENT_BIT,fVulkanFragmentShaderModule,'main');

 fVulkanGraphicsPipeline:=nil;

end;

procedure TScreenMain.TOrderIndependentTransparencyResolveRenderPass.Hide;
begin
 FreeAndNil(fVulkanPipelineShaderStageVertex);
 FreeAndNil(fVulkanPipelineShaderStageFragment);
 FreeAndNil(fVulkanFragmentShaderModule);
 FreeAndNil(fVulkanVertexShaderModule);
 FreeAndNil(fVulkanTransferCommandBufferFence);
 FreeAndNil(fVulkanTransferCommandBuffer);
 inherited Hide;
end;

procedure TScreenMain.TOrderIndependentTransparencyResolveRenderPass.AfterCreateSwapChain;
var SwapChainImageIndex:TpvSizeInt;
begin
 inherited AfterCreateSwapChain;

 fVulkanRenderPass:=VulkanRenderPass;

 fVulkanDescriptorPool:=TpvVulkanDescriptorPool.Create(pvApplication.VulkanDevice,
                                                       TVkDescriptorPoolCreateFlags(VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT),
                                                       MaxSwapChainImages);
 fVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT,2*MaxSwapChainImages);
 fVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER,1*MaxSwapChainImages);
 fVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,1*MaxSwapChainImages);
 fVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,1*MaxSwapChainImages);
 fVulkanDescriptorPool.Initialize;

 fVulkanDescriptorSetLayout:=TpvVulkanDescriptorSetLayout.Create(pvApplication.VulkanDevice);
 fVulkanDescriptorSetLayout.AddBinding(0,
                                       VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT,
                                       1,
                                       TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                       []);
 fVulkanDescriptorSetLayout.AddBinding(1,
                                       VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT,
                                       1,
                                       TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                       []);
 fVulkanDescriptorSetLayout.AddBinding(2,
                                       VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER,
                                       1,
                                       TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                       []);
 fVulkanDescriptorSetLayout.AddBinding(3,
                                       VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
                                       1,
                                       TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                       []);
 fVulkanDescriptorSetLayout.AddBinding(4,
                                       VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                                       1,
                                       TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                       []);
 fVulkanDescriptorSetLayout.Initialize;

 for SwapChainImageIndex:=0 to FrameGraph.CountSwapChainImages-1 do begin
  fVulkanDescriptorSets[SwapChainImageIndex]:=TpvVulkanDescriptorSet.Create(fVulkanDescriptorPool,
                                                                            fVulkanDescriptorSetLayout);
  fVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(0,
                                                                  0,
                                                                  1,
                                                                  TVkDescriptorType(VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT),
                                                                  [TVkDescriptorImageInfo.Create(VK_NULL_HANDLE,
                                                                                                 fResourceOpaque.VulkanImageViews[SwapChainImageIndex].Handle,
                                                                                                 fResourceOpaque.ResourceTransition.Layout)],// TVkImageLayout(VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL))],
                                                                  [],
                                                                  [],
                                                                  false
                                                                 );
  fVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(1,
                                                                  0,
                                                                  1,
                                                                  TVkDescriptorType(VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT),
                                                                  [TVkDescriptorImageInfo.Create(VK_NULL_HANDLE,
                                                                                                 fResourceTransparent.VulkanImageViews[SwapChainImageIndex].Handle,
                                                                                                 fResourceTransparent.ResourceTransition.Layout)],// TVkImageLayout(VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL))],
                                                                  [],
                                                                  [],
                                                                  false
                                                                 );
  fVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(2,
                                                                  0,
                                                                  1,
                                                                  TVkDescriptorType(VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER),
                                                                  [],
                                                                  [],
                                                                  [fParent.fOrderIndependentTransparencyABufferBuffers[SwapChainImageIndex].VulkanBufferView.Handle],
                                                                  false
                                                                 );
  fVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(3,
                                                                  0,
                                                                  1,
                                                                  TVkDescriptorType(VK_DESCRIPTOR_TYPE_STORAGE_IMAGE),
                                                                  [fParent.fOrderIndependentTransparencyAuxImages[SwapChainImageIndex].DescriptorImageInfo],
                                                                  [],
                                                                  [],
                                                                  false
                                                                 );
  fVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(4,
                                                                  0,
                                                                  1,
                                                                  TVkDescriptorType(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER),
                                                                  [],
                                                                  [fParent.fOrderIndependentTransparentUniformVulkanBuffer.DescriptorBufferInfo],
                                                                  [],
                                                                  false
                                                                 );
  fVulkanDescriptorSets[SwapChainImageIndex].Flush;
 end;

 fVulkanPipelineLayout:=TpvVulkanPipelineLayout.Create(pvApplication.VulkanDevice);
 fVulkanPipelineLayout.AddDescriptorSetLayout(fVulkanDescriptorSetLayout);
 fVulkanPipelineLayout.Initialize;

 fVulkanGraphicsPipeline:=TpvVulkanGraphicsPipeline.Create(pvApplication.VulkanDevice,
                                                           pvApplication.VulkanPipelineCache,
                                                           0,
                                                           [],
                                                           fVulkanPipelineLayout,
                                                           fVulkanRenderPass,
                                                           VulkanRenderPassSubpassIndex,
                                                           nil,
                                                           0);

 fVulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageVertex);
 fVulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageFragment);

 fVulkanGraphicsPipeline.InputAssemblyState.Topology:=VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
 fVulkanGraphicsPipeline.InputAssemblyState.PrimitiveRestartEnable:=false;

 fVulkanGraphicsPipeline.ViewPortState.AddViewPort(0.0,0.0,fParent.fWidth,fParent.fHeight,0.0,1.0);
 fVulkanGraphicsPipeline.ViewPortState.AddScissor(0,0,fParent.fWidth,fParent.fHeight);

 fVulkanGraphicsPipeline.RasterizationState.DepthClampEnable:=false;
 fVulkanGraphicsPipeline.RasterizationState.RasterizerDiscardEnable:=false;
 fVulkanGraphicsPipeline.RasterizationState.PolygonMode:=VK_POLYGON_MODE_FILL;
 fVulkanGraphicsPipeline.RasterizationState.CullMode:=TVkCullModeFlags(VK_CULL_MODE_NONE);
 fVulkanGraphicsPipeline.RasterizationState.FrontFace:=VK_FRONT_FACE_CLOCKWISE;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasEnable:=false;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasConstantFactor:=0.0;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasClamp:=0.0;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasSlopeFactor:=0.0;
 fVulkanGraphicsPipeline.RasterizationState.LineWidth:=1.0;

 fVulkanGraphicsPipeline.MultisampleState.RasterizationSamples:=VK_SAMPLE_COUNT_1_BIT;
 fVulkanGraphicsPipeline.MultisampleState.SampleShadingEnable:=false;
 fVulkanGraphicsPipeline.MultisampleState.MinSampleShading:=0.0;
 fVulkanGraphicsPipeline.MultisampleState.CountSampleMasks:=0;
 fVulkanGraphicsPipeline.MultisampleState.AlphaToCoverageEnable:=false;
 fVulkanGraphicsPipeline.MultisampleState.AlphaToOneEnable:=false;

 fVulkanGraphicsPipeline.ColorBlendState.LogicOpEnable:=false;
 fVulkanGraphicsPipeline.ColorBlendState.LogicOp:=VK_LOGIC_OP_COPY;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[0]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[1]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[2]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[3]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.AddColorBlendAttachmentState(false,
                                                                      VK_BLEND_FACTOR_SRC_ALPHA,
                                                                      VK_BLEND_FACTOR_DST_ALPHA,
                                                                      VK_BLEND_OP_ADD,
                                                                      VK_BLEND_FACTOR_ONE,
                                                                      VK_BLEND_FACTOR_ZERO,
                                                                      VK_BLEND_OP_ADD,
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_R_BIT) or
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_G_BIT) or
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_B_BIT) or
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_A_BIT));

 fVulkanGraphicsPipeline.DepthStencilState.DepthTestEnable:=true;
 fVulkanGraphicsPipeline.DepthStencilState.DepthWriteEnable:=true;
 fVulkanGraphicsPipeline.DepthStencilState.DepthCompareOp:=VK_COMPARE_OP_ALWAYS;
 fVulkanGraphicsPipeline.DepthStencilState.DepthBoundsTestEnable:=false;
 fVulkanGraphicsPipeline.DepthStencilState.StencilTestEnable:=false;

 fVulkanGraphicsPipeline.Initialize;

 fVulkanGraphicsPipeline.FreeMemory;

end;

procedure TScreenMain.TOrderIndependentTransparencyResolveRenderPass.BeforeDestroySwapChain;
var SwapChainImageIndex:TpvSizeInt;
begin

 FreeAndNil(fVulkanGraphicsPipeline);

 FreeAndNil(fVulkanPipelineLayout);

 for SwapChainImageIndex:=0 to FrameGraph.CountSwapChainImages-1 do begin
  FreeAndNil(fVulkanDescriptorSets[SwapChainImageIndex]);
 end;

 FreeAndNil(fVulkanDescriptorSetLayout);

 FreeAndNil(fVulkanDescriptorPool);

 fVulkanRenderPass:=nil;

 inherited BeforeDestroySwapChain;
end;

procedure TScreenMain.TOrderIndependentTransparencyResolveRenderPass.Update(const aUpdateSwapChainImageIndex,aUpdateFrameIndex:TpvSizeInt);
begin
 inherited Update(aUpdateSwapChainImageIndex,aUpdateFrameIndex);
end;

procedure TScreenMain.TOrderIndependentTransparencyResolveRenderPass.Execute(const aCommandBuffer:TpvVulkanCommandBuffer;const aSwapChainImageIndex,aFrameIndex:TpvSizeInt);
begin
 inherited Execute(aCommandBuffer,aSwapChainImageIndex,aFrameIndex);
 aCommandBuffer.CmdBindDescriptorSets(VK_PIPELINE_BIND_POINT_GRAPHICS,
                                      fVulkanPipelineLayout.Handle,
                                      0,
                                      1,
                                      @fVulkanDescriptorSets[aSwapChainImageIndex].Handle,0,nil);
 aCommandBuffer.CmdBindPipeline(VK_PIPELINE_BIND_POINT_GRAPHICS,fVulkanGraphicsPipeline.Handle);
 aCommandBuffer.CmdDraw(3,1,0,0);
end;

{ TScreenMain.TTonemappingRenderPass }

constructor TScreenMain.TTonemappingRenderPass.Create(const aFrameGraph:TpvFrameGraph;const aParent:TScreenMain);
begin

 inherited Create(aFrameGraph);

 fParent:=aParent;

 Name:='Tonemapping';

 MultiviewMask:=fParent.fSurfaceMultiviewMask;

 Queue:=aFrameGraph.UniversalQueue;

//SeparatePhysicalPass:=true;

//SeparateCommandBuffer:=true;

 Size:=TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.SurfaceDependent,
                                       1.0,
                                       1.0,
                                       1.0,
                                       fParent.fCountSurfaceViews);

 fResourceColor:=AddImageInput('resourcetype_color',
                               'orderindependenttransparency_final_color',
                               VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                               [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                              );

 fResourceSurface:=AddImageOutput('resourcetype_color',
                                  'tonemapping_color',
                                  VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                                  TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.Clear,
                                                               TpvVector4.InlineableCreate(0.0,0.0,0.0,1.0)),
                                  [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                 );

end;

destructor TScreenMain.TTonemappingRenderPass.Destroy;
begin
 inherited Destroy;
end;

procedure TScreenMain.TTonemappingRenderPass.Show;
var Stream:TStream;
begin

 inherited Show;

 fVulkanTransferCommandBuffer:=TpvVulkanCommandBuffer.Create(FrameGraph.TransferQueue.CommandPool,VK_COMMAND_BUFFER_LEVEL_PRIMARY);

 fVulkanTransferCommandBufferFence:=TpvVulkanFence.Create(pvApplication.VulkanDevice);

 Stream:=pvApplication.Assets.GetAssetStream('shaders/fullscreen_vert.spv');
 try
  fVulkanVertexShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 Stream:=pvApplication.Assets.GetAssetStream('shaders/tonemapping_frag.spv');
 try
  fVulkanFragmentShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 fVulkanPipelineShaderStageVertex:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_VERTEX_BIT,fVulkanVertexShaderModule,'main');

 fVulkanPipelineShaderStageFragment:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_FRAGMENT_BIT,fVulkanFragmentShaderModule,'main');

 fVulkanGraphicsPipeline:=nil;

end;

procedure TScreenMain.TTonemappingRenderPass.Hide;
begin
 FreeAndNil(fVulkanPipelineShaderStageVertex);
 FreeAndNil(fVulkanPipelineShaderStageFragment);
 FreeAndNil(fVulkanFragmentShaderModule);
 FreeAndNil(fVulkanVertexShaderModule);
 FreeAndNil(fVulkanTransferCommandBufferFence);
 FreeAndNil(fVulkanTransferCommandBuffer);
 inherited Hide;
end;

procedure TScreenMain.TTonemappingRenderPass.AfterCreateSwapChain;
var SwapChainImageIndex:TpvSizeInt;
begin
 inherited AfterCreateSwapChain;

 fVulkanRenderPass:=VulkanRenderPass;

 fVulkanDescriptorPool:=TpvVulkanDescriptorPool.Create(pvApplication.VulkanDevice,
                                                       TVkDescriptorPoolCreateFlags(VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT),
                                                       MaxSwapChainImages);
 fVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT,MaxSwapChainImages);
 fVulkanDescriptorPool.Initialize;

 fVulkanDescriptorSetLayout:=TpvVulkanDescriptorSetLayout.Create(pvApplication.VulkanDevice);
 fVulkanDescriptorSetLayout.AddBinding(0,
                                       VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT,
                                       1,
                                       TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                       []);
 fVulkanDescriptorSetLayout.Initialize;

 for SwapChainImageIndex:=0 to FrameGraph.CountSwapChainImages-1 do begin
  fVulkanDescriptorSets[SwapChainImageIndex]:=TpvVulkanDescriptorSet.Create(fVulkanDescriptorPool,
                                                                            fVulkanDescriptorSetLayout);
  fVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(0,
                                                                  0,
                                                                  1,
                                                                  TVkDescriptorType(VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT),
                                                                  [TVkDescriptorImageInfo.Create(VK_NULL_HANDLE,
                                                                                                 fResourceColor.VulkanImageViews[SwapChainImageIndex].Handle,
                                                                                                 fResourceColor.ResourceTransition.Layout)],// TVkImageLayout(VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL))],
                                                                  [],
                                                                  [],
                                                                  false
                                                                 );
  fVulkanDescriptorSets[SwapChainImageIndex].Flush;
 end;

 fVulkanPipelineLayout:=TpvVulkanPipelineLayout.Create(pvApplication.VulkanDevice);
 fVulkanPipelineLayout.AddDescriptorSetLayout(fVulkanDescriptorSetLayout);
 fVulkanPipelineLayout.Initialize;

 fVulkanGraphicsPipeline:=TpvVulkanGraphicsPipeline.Create(pvApplication.VulkanDevice,
                                                           pvApplication.VulkanPipelineCache,
                                                           0,
                                                           [],
                                                           fVulkanPipelineLayout,
                                                           fVulkanRenderPass,
                                                           VulkanRenderPassSubpassIndex,
                                                           nil,
                                                           0);

 fVulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageVertex);
 fVulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageFragment);

 fVulkanGraphicsPipeline.InputAssemblyState.Topology:=VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
 fVulkanGraphicsPipeline.InputAssemblyState.PrimitiveRestartEnable:=false;

 fVulkanGraphicsPipeline.ViewPortState.AddViewPort(0.0,0.0,fParent.fWidth,fParent.fHeight,0.0,1.0);
 fVulkanGraphicsPipeline.ViewPortState.AddScissor(0,0,fParent.fWidth,fParent.fHeight);

 fVulkanGraphicsPipeline.RasterizationState.DepthClampEnable:=false;
 fVulkanGraphicsPipeline.RasterizationState.RasterizerDiscardEnable:=false;
 fVulkanGraphicsPipeline.RasterizationState.PolygonMode:=VK_POLYGON_MODE_FILL;
 fVulkanGraphicsPipeline.RasterizationState.CullMode:=TVkCullModeFlags(VK_CULL_MODE_NONE);
 fVulkanGraphicsPipeline.RasterizationState.FrontFace:=VK_FRONT_FACE_CLOCKWISE;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasEnable:=false;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasConstantFactor:=0.0;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasClamp:=0.0;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasSlopeFactor:=0.0;
 fVulkanGraphicsPipeline.RasterizationState.LineWidth:=1.0;

 fVulkanGraphicsPipeline.MultisampleState.RasterizationSamples:=VK_SAMPLE_COUNT_1_BIT;
 fVulkanGraphicsPipeline.MultisampleState.SampleShadingEnable:=false;
 fVulkanGraphicsPipeline.MultisampleState.MinSampleShading:=0.0;
 fVulkanGraphicsPipeline.MultisampleState.CountSampleMasks:=0;
 fVulkanGraphicsPipeline.MultisampleState.AlphaToCoverageEnable:=false;
 fVulkanGraphicsPipeline.MultisampleState.AlphaToOneEnable:=false;

 fVulkanGraphicsPipeline.ColorBlendState.LogicOpEnable:=false;
 fVulkanGraphicsPipeline.ColorBlendState.LogicOp:=VK_LOGIC_OP_COPY;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[0]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[1]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[2]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[3]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.AddColorBlendAttachmentState(false,
                                                                      VK_BLEND_FACTOR_SRC_ALPHA,
                                                                      VK_BLEND_FACTOR_DST_ALPHA,
                                                                      VK_BLEND_OP_ADD,
                                                                      VK_BLEND_FACTOR_ONE,
                                                                      VK_BLEND_FACTOR_ZERO,
                                                                      VK_BLEND_OP_ADD,
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_R_BIT) or
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_G_BIT) or
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_B_BIT) or
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_A_BIT));

 fVulkanGraphicsPipeline.DepthStencilState.DepthTestEnable:=true;
 fVulkanGraphicsPipeline.DepthStencilState.DepthWriteEnable:=true;
 fVulkanGraphicsPipeline.DepthStencilState.DepthCompareOp:=VK_COMPARE_OP_ALWAYS;
 fVulkanGraphicsPipeline.DepthStencilState.DepthBoundsTestEnable:=false;
 fVulkanGraphicsPipeline.DepthStencilState.StencilTestEnable:=false;

 fVulkanGraphicsPipeline.Initialize;

 fVulkanGraphicsPipeline.FreeMemory;

end;

procedure TScreenMain.TTonemappingRenderPass.BeforeDestroySwapChain;
var SwapChainImageIndex:TpvSizeInt;
begin

 FreeAndNil(fVulkanGraphicsPipeline);

 FreeAndNil(fVulkanPipelineLayout);

 for SwapChainImageIndex:=0 to FrameGraph.CountSwapChainImages-1 do begin
  FreeAndNil(fVulkanDescriptorSets[SwapChainImageIndex]);
 end;

 FreeAndNil(fVulkanDescriptorSetLayout);

 FreeAndNil(fVulkanDescriptorPool);

 fVulkanRenderPass:=nil;

 inherited BeforeDestroySwapChain;
end;

procedure TScreenMain.TTonemappingRenderPass.Update(const aUpdateSwapChainImageIndex,aUpdateFrameIndex:TpvSizeInt);
begin
 inherited Update(aUpdateSwapChainImageIndex,aUpdateFrameIndex);
end;

procedure TScreenMain.TTonemappingRenderPass.Execute(const aCommandBuffer:TpvVulkanCommandBuffer;const aSwapChainImageIndex,aFrameIndex:TpvSizeInt);
begin
 inherited Execute(aCommandBuffer,aSwapChainImageIndex,aFrameIndex);
 aCommandBuffer.CmdBindDescriptorSets(VK_PIPELINE_BIND_POINT_GRAPHICS,
                                      fVulkanPipelineLayout.Handle,
                                      0,
                                      1,
                                      @fVulkanDescriptorSets[aSwapChainImageIndex].Handle,0,nil);
 aCommandBuffer.CmdBindPipeline(VK_PIPELINE_BIND_POINT_GRAPHICS,fVulkanGraphicsPipeline.Handle);
 aCommandBuffer.CmdDraw(3,1,0,0);
end;

{ TScreenMain.TAntialiasingRenderPass }

constructor TScreenMain.TAntialiasingRenderPass.Create(const aFrameGraph:TpvFrameGraph;const aParent:TScreenMain);
begin

 inherited Create(aFrameGraph);

 fParent:=aParent;

 Name:='Antialiasing';

 MultiviewMask:=fParent.fSurfaceMultiviewMask;

 Queue:=aFrameGraph.UniversalQueue;

//SeparatePhysicalPass:=true;

//SeparateCommandBuffer:=true;

 Size:=TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.SurfaceDependent,
                                       1.0,
                                       1.0,
                                       1.0,
                                       fParent.fCountSurfaceViews);

 if fParent.fVulkanSampleCountFlagBits=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT) then begin
  fResourceColor:=AddImageInput('resourcetype_color',
                                'tonemapping_color',
                                VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                                []
                               );
 end else begin
  fResourceColor:=AddImageInput('resourcetype_color',
                                'tonemapping_color',
                                VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                                [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                               );
 end;

{fResourceSurface:=AddImageOutput('resourcetype_surface',
                                  'resource_surface',
                                  VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                                  TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.Clear,
                                                               TpvVector4.InlineableCreate(0.0,0.0,0.0,1.0)),
                                  [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                                 );}

 fResourceSurface:=AddImageOutput('resourcetype_output_color',
                                  'resource_output',
                                  VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                                  TpvFrameGraph.TLoadOp.Create(TpvFrameGraph.TLoadOp.TKind.Clear,
                                                               TpvVector4.InlineableCreate(0.0,0.0,0.0,1.0)),
                                  [TpvFrameGraph.TResourceTransition.TFlag.Attachment],
                                  TpvFrameGraph.TResourceInstanceType.Default,
                                  fParent.fExternalOutputImageData
                                 );

end;

destructor TScreenMain.TAntialiasingRenderPass.Destroy;
begin
 inherited Destroy;
end;

procedure TScreenMain.TAntialiasingRenderPass.Show;
var Stream:TStream;
begin

 inherited Show;

 fVulkanTransferCommandBuffer:=TpvVulkanCommandBuffer.Create(FrameGraph.TransferQueue.CommandPool,VK_COMMAND_BUFFER_LEVEL_PRIMARY);

 fVulkanTransferCommandBufferFence:=TpvVulkanFence.Create(pvApplication.VulkanDevice);

 Stream:=pvApplication.Assets.GetAssetStream('shaders/fullscreen_vert.spv');
 try
  fVulkanVertexShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 if fParent.fVulkanSampleCountFlagBits=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT) then begin
  Stream:=pvApplication.Assets.GetAssetStream('shaders/antialiasing_frag.spv');
 end else begin
  Stream:=pvApplication.Assets.GetAssetStream('shaders/blit_frag.spv');
 end;
 try
  fVulkanFragmentShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 fVulkanPipelineShaderStageVertex:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_VERTEX_BIT,fVulkanVertexShaderModule,'main');

 fVulkanPipelineShaderStageFragment:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_FRAGMENT_BIT,fVulkanFragmentShaderModule,'main');

 fVulkanGraphicsPipeline:=nil;

 fVulkanSampler:=TpvVulkanSampler.Create(pvApplication.VulkanDevice,
                                         TVkFilter.VK_FILTER_LINEAR,
                                         TVkFilter.VK_FILTER_LINEAR,
                                         TVkSamplerMipmapMode.VK_SAMPLER_MIPMAP_MODE_LINEAR,
                                         VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
                                         VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
                                         VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
                                         0.0,
                                         false,
                                         0.0,
                                         false,
                                         VK_COMPARE_OP_ALWAYS,
                                         0.0,
                                         0.0,
                                         VK_BORDER_COLOR_FLOAT_OPAQUE_BLACK,
                                         false);

end;

procedure TScreenMain.TAntialiasingRenderPass.Hide;
begin
 FreeAndNil(fVulkanSampler);
 FreeAndNil(fVulkanPipelineShaderStageVertex);
 FreeAndNil(fVulkanPipelineShaderStageFragment);
 FreeAndNil(fVulkanFragmentShaderModule);
 FreeAndNil(fVulkanVertexShaderModule);
 FreeAndNil(fVulkanTransferCommandBufferFence);
 FreeAndNil(fVulkanTransferCommandBuffer);
 inherited Hide;
end;

procedure TScreenMain.TAntialiasingRenderPass.AfterCreateSwapChain;
var SwapChainImageIndex:TpvSizeInt;
begin
 inherited AfterCreateSwapChain;

 fVulkanRenderPass:=VulkanRenderPass;

 fVulkanDescriptorPool:=TpvVulkanDescriptorPool.Create(pvApplication.VulkanDevice,
                                                       TVkDescriptorPoolCreateFlags(VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT),
                                                       MaxSwapChainImages);
 if fParent.fVulkanSampleCountFlagBits=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT) then begin
  fVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,MaxSwapChainImages);
 end else begin
  fVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT,MaxSwapChainImages);
 end;
 fVulkanDescriptorPool.Initialize;

 fVulkanDescriptorSetLayout:=TpvVulkanDescriptorSetLayout.Create(pvApplication.VulkanDevice);
 if fParent.fVulkanSampleCountFlagBits=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT) then begin
  fVulkanDescriptorSetLayout.AddBinding(0,
                                        VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                                        1,
                                        TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                        []);
 end else begin
  fVulkanDescriptorSetLayout.AddBinding(0,
                                        VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT,
                                        1,
                                        TVkShaderStageFlags(VK_SHADER_STAGE_FRAGMENT_BIT),
                                        []);
 end;
 fVulkanDescriptorSetLayout.Initialize;

 for SwapChainImageIndex:=0 to FrameGraph.CountSwapChainImages-1 do begin
  fVulkanImageViews[SwapChainImageIndex]:=TpvVulkanImageView.Create(pvApplication.VulkanDevice,
                                                                    fResourceColor.VulkanImages[SwapChainImageIndex],
                                                                    VK_IMAGE_VIEW_TYPE_2D_ARRAY,
                                                                    TpvFrameGraph.TImageResourceType(fResourceColor.ResourceType).Format,
                                                                    VK_COMPONENT_SWIZZLE_IDENTITY,
                                                                    VK_COMPONENT_SWIZZLE_IDENTITY,
                                                                    VK_COMPONENT_SWIZZLE_IDENTITY,
                                                                    VK_COMPONENT_SWIZZLE_IDENTITY,
                                                                    TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT),
                                                                    0,
                                                                    1,
                                                                    0,
                                                                    fParent.fCountSurfaceViews
                                                                   );
  fVulkanDescriptorSets[SwapChainImageIndex]:=TpvVulkanDescriptorSet.Create(fVulkanDescriptorPool,
                                                                            fVulkanDescriptorSetLayout);
  if fParent.fVulkanSampleCountFlagBits=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT) then begin
   fVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(0,
                                                                   0,
                                                                   1,
                                                                   TVkDescriptorType(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER),
                                                                   [TVkDescriptorImageInfo.Create(fVulkanSampler.Handle,
                                                                                                  fResourceColor.VulkanImageViews[SwapChainImageIndex].Handle,
                                                                                                  fResourceColor.ResourceTransition.Layout)],// TVkImageLayout(VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL))],
                                                                   [],
                                                                   [],
                                                                   false
                                                                  );
  end else begin
   fVulkanDescriptorSets[SwapChainImageIndex].WriteToDescriptorSet(0,
                                                                   0,
                                                                   1,
                                                                   TVkDescriptorType(VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT),
                                                                   [TVkDescriptorImageInfo.Create(VK_NULL_HANDLE,
                                                                                                  fResourceColor.VulkanImageViews[SwapChainImageIndex].Handle,
                                                                                                  fResourceColor.ResourceTransition.Layout)],// TVkImageLayout(VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL))],
                                                                   [],
                                                                   [],
                                                                   false
                                                                  );
  end;
  fVulkanDescriptorSets[SwapChainImageIndex].Flush;
 end;

 fVulkanPipelineLayout:=TpvVulkanPipelineLayout.Create(pvApplication.VulkanDevice);
 fVulkanPipelineLayout.AddDescriptorSetLayout(fVulkanDescriptorSetLayout);
 fVulkanPipelineLayout.Initialize;

 fVulkanGraphicsPipeline:=TpvVulkanGraphicsPipeline.Create(pvApplication.VulkanDevice,
                                                           pvApplication.VulkanPipelineCache,
                                                           0,
                                                           [],
                                                           fVulkanPipelineLayout,
                                                           fVulkanRenderPass,
                                                           VulkanRenderPassSubpassIndex,
                                                           nil,
                                                           0);

 fVulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageVertex);
 fVulkanGraphicsPipeline.AddStage(fVulkanPipelineShaderStageFragment);

 fVulkanGraphicsPipeline.InputAssemblyState.Topology:=VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
 fVulkanGraphicsPipeline.InputAssemblyState.PrimitiveRestartEnable:=false;

 fVulkanGraphicsPipeline.ViewPortState.AddViewPort(0.0,0.0,fParent.fWidth,fParent.fHeight,0.0,1.0);
 fVulkanGraphicsPipeline.ViewPortState.AddScissor(0,0,fParent.fWidth,fParent.fHeight);

 fVulkanGraphicsPipeline.RasterizationState.DepthClampEnable:=false;
 fVulkanGraphicsPipeline.RasterizationState.RasterizerDiscardEnable:=false;
 fVulkanGraphicsPipeline.RasterizationState.PolygonMode:=VK_POLYGON_MODE_FILL;
 fVulkanGraphicsPipeline.RasterizationState.CullMode:=TVkCullModeFlags(VK_CULL_MODE_NONE);
 fVulkanGraphicsPipeline.RasterizationState.FrontFace:=VK_FRONT_FACE_CLOCKWISE;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasEnable:=false;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasConstantFactor:=0.0;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasClamp:=0.0;
 fVulkanGraphicsPipeline.RasterizationState.DepthBiasSlopeFactor:=0.0;
 fVulkanGraphicsPipeline.RasterizationState.LineWidth:=1.0;

 fVulkanGraphicsPipeline.MultisampleState.RasterizationSamples:=VK_SAMPLE_COUNT_1_BIT;
 fVulkanGraphicsPipeline.MultisampleState.SampleShadingEnable:=false;
 fVulkanGraphicsPipeline.MultisampleState.MinSampleShading:=0.0;
 fVulkanGraphicsPipeline.MultisampleState.CountSampleMasks:=0;
 fVulkanGraphicsPipeline.MultisampleState.AlphaToCoverageEnable:=false;
 fVulkanGraphicsPipeline.MultisampleState.AlphaToOneEnable:=false;

 fVulkanGraphicsPipeline.ColorBlendState.LogicOpEnable:=false;
 fVulkanGraphicsPipeline.ColorBlendState.LogicOp:=VK_LOGIC_OP_COPY;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[0]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[1]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[2]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.BlendConstants[3]:=0.0;
 fVulkanGraphicsPipeline.ColorBlendState.AddColorBlendAttachmentState(false,
                                                                      VK_BLEND_FACTOR_SRC_ALPHA,
                                                                      VK_BLEND_FACTOR_DST_ALPHA,
                                                                      VK_BLEND_OP_ADD,
                                                                      VK_BLEND_FACTOR_ONE,
                                                                      VK_BLEND_FACTOR_ZERO,
                                                                      VK_BLEND_OP_ADD,
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_R_BIT) or
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_G_BIT) or
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_B_BIT) or
                                                                      TVkColorComponentFlags(VK_COLOR_COMPONENT_A_BIT));

 fVulkanGraphicsPipeline.DepthStencilState.DepthTestEnable:=true;
 fVulkanGraphicsPipeline.DepthStencilState.DepthWriteEnable:=true;
 fVulkanGraphicsPipeline.DepthStencilState.DepthCompareOp:=VK_COMPARE_OP_ALWAYS;
 fVulkanGraphicsPipeline.DepthStencilState.DepthBoundsTestEnable:=false;
 fVulkanGraphicsPipeline.DepthStencilState.StencilTestEnable:=false;

 fVulkanGraphicsPipeline.Initialize;

 fVulkanGraphicsPipeline.FreeMemory;

end;

procedure TScreenMain.TAntialiasingRenderPass.BeforeDestroySwapChain;
var SwapChainImageIndex:TpvSizeInt;
begin

 FreeAndNil(fVulkanGraphicsPipeline);

 FreeAndNil(fVulkanPipelineLayout);

 for SwapChainImageIndex:=0 to FrameGraph.CountSwapChainImages-1 do begin
  FreeAndNil(fVulkanDescriptorSets[SwapChainImageIndex]);
  FreeAndNil(fVulkanImageViews[SwapChainImageIndex]);
 end;

 FreeAndNil(fVulkanDescriptorSetLayout);

 FreeAndNil(fVulkanDescriptorPool);

 fVulkanRenderPass:=nil;

 inherited BeforeDestroySwapChain;
end;

procedure TScreenMain.TAntialiasingRenderPass.Update(const aUpdateSwapChainImageIndex,aUpdateFrameIndex:TpvSizeInt);
begin
 inherited Update(aUpdateSwapChainImageIndex,aUpdateFrameIndex);
end;

procedure TScreenMain.TAntialiasingRenderPass.Execute(const aCommandBuffer:TpvVulkanCommandBuffer;const aSwapChainImageIndex,aFrameIndex:TpvSizeInt);
begin
 inherited Execute(aCommandBuffer,aSwapChainImageIndex,aFrameIndex);
 aCommandBuffer.CmdBindDescriptorSets(VK_PIPELINE_BIND_POINT_GRAPHICS,
                                      fVulkanPipelineLayout.Handle,
                                      0,
                                      1,
                                      @fVulkanDescriptorSets[aSwapChainImageIndex].Handle,0,nil);
 aCommandBuffer.CmdBindPipeline(VK_PIPELINE_BIND_POINT_GRAPHICS,fVulkanGraphicsPipeline.Handle);
 aCommandBuffer.CmdDraw(3,1,0,0);
end;

{ TScreenMain }

constructor TScreenMain.Create;
var GLTF:TPasGLTF.TDocument;
    AssetStream:TStream;
    SampleCounts:TVkSampleCountFlags;
begin
 inherited Create;

 case TpvVulkanVendorID(pvApplication.VulkanDevice.PhysicalDevice.Properties.vendorID) of
  TpvVulkanVendorID.ImgTec,
  TpvVulkanVendorID.ARM,
  TpvVulkanVendorID.Qualcomm,
  TpvVulkanVendorID.Vivante:begin
   // Tile-based GPUs => Use no depth prepass, as it can be counterproductive for those
   fUseDepthPrepass:=false;
  end;
  else begin
   // Immediate-based GPUs => Use depth prepass, as for which it can bring an advantage
   fUseDepthPrepass:=true;
  end;
 end;

 fAnimationIndex:=0;

 FillChar(fCascadedShadowMapVulkanUniformBuffers,SizeOf(TCascadedShadowMapVulkanUniformBuffers),#0);

 fUpdateLock:=TPasMPCriticalSection.Create;

 fScene3D:=TpvScene3D.Create(pvApplication.ResourceManager);

 fPrimaryDirectionalLight:=TpvScene3D.TLight.Create(fScene3D);
 fPrimaryDirectionalLight.Type_:=TpvScene3D.TLightData.TType.PrimaryDirectional;
 fPrimaryDirectionalLight.Color:=TpvVector3.InlineableCreate(1.7,1.15,0.70);
 fPrimaryDirectionalLight.Matrix:=TpvMatrix4x4.CreateConstructZ(-TSkyCubeMap.LightDirection.xyz);
 fPrimaryDirectionalLight.Intensity:=1.0;
 fPrimaryDirectionalLight.Range:=0.0;
 fPrimaryDirectionalLight.CastShadows:=true;
 fPrimaryDirectionalLight.Data.Visible:=true;
 fPrimaryDirectionalLight.Visible:=true;
 fPrimaryDirectionalLight.Update;

 fGroup:=TpvScene3D.TGroup.Create(pvApplication.ResourceManager,fScene3D);
 try
  fGroup.Culling:=false; // true for GLTFs with large scenes like landscapes, cities, etc.
  GLTF:=TPasGLTF.TDocument.Create;
  try
   if FileExists(GLTFFileName) then begin
    GLTF.RootPath:=ExtractFilePath(ExpandFileName(GLTFFileName));
    AssetStream:=TFileStream.Create(GLTFFileName,fmOpenRead or fmShareDenyWrite);
   end else begin
    AssetStream:=pvApplication.Assets.GetAssetStream(GLTFFileName);
   end;
   if assigned(AssetStream) then begin
    try
     GLTF.LoadFromStream(AssetStream);
    finally
     FreeAndNil(AssetStream);
    end;
   end;
   fGroup.AssignFromGLTF(GLTF);
  finally
   FreeAndNil(GLTF);
  end;
 finally
 end;

 fGroupInstance:=fGroup.CreateInstance;

 fFrameGraph:=TpvFrameGraph.Create(pvApplication.VulkanDevice);

 fFrameGraph.SurfaceIsSwapchain:=true;

 fFrameGraph.DefaultResourceInstanceType:=TpvFrameGraph.TResourceInstanceType.InstancePerSwapChainImage;

 fCountSurfaceViews:=UnitApplication.Application.VirtualReality.CountImages;

 fSurfaceMultiviewMask:=UnitApplication.Application.VirtualReality.MultiviewMask;

 SampleCounts:=pvApplication.VulkanDevice.PhysicalDevice.Properties.limits.framebufferColorSampleCounts and
               pvApplication.VulkanDevice.PhysicalDevice.Properties.limits.framebufferDepthSampleCounts and
               pvApplication.VulkanDevice.PhysicalDevice.Properties.limits.framebufferStencilSampleCounts;

 if pvApplication.VulkanDevice.PhysicalDevice.Properties.deviceType=VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU then begin

 {if (SampleCounts and TVkSampleCountFlags(VK_SAMPLE_COUNT_64_BIT))<>0 then begin
   fVulkanSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_64_BIT);
   fVulkanShadowMapSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_64_BIT);
   fCountSurfaceMSAASamples:=64;
   fCountCascadedShadowMapMSAASamples:=64;
  end else if (SampleCounts and TVkSampleCountFlags(VK_SAMPLE_COUNT_32_BIT))<>0 then begin
   fVulkanSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_32_BIT);
   fVulkanShadowMapSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_32_BIT);
   fCountSurfaceMSAASamples:=32;
   fCountCascadedShadowMapMSAASamples:=32;
  end else if (SampleCounts and TVkSampleCountFlags(VK_SAMPLE_COUNT_16_BIT))<>0 then begin
   fVulkanSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_16_BIT);
   fVulkanShadowMapSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_16_BIT);
   fCountSurfaceMSAASamples:=16;
   fCountCascadedShadowMapMSAASamples:=16;
  end else}if (SampleCounts and TVkSampleCountFlags(VK_SAMPLE_COUNT_8_BIT))<>0 then begin
   fVulkanSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_8_BIT);
   fVulkanShadowMapSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_8_BIT);
   fCountSurfaceMSAASamples:=8;
   fCountCascadedShadowMapMSAASamples:=8;
  end else if (SampleCounts and TVkSampleCountFlags(VK_SAMPLE_COUNT_4_BIT))<>0 then begin
   fVulkanSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_4_BIT);
   fVulkanShadowMapSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_4_BIT);
   fCountSurfaceMSAASamples:=4;
   fCountCascadedShadowMapMSAASamples:=4;
  end else if (SampleCounts and TVkSampleCountFlags(VK_SAMPLE_COUNT_2_BIT))<>0 then begin
   fVulkanSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_2_BIT);
   fVulkanShadowMapSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_2_BIT);
   fCountSurfaceMSAASamples:=2;
   fCountCascadedShadowMapMSAASamples:=2;
  end else begin
   fVulkanSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT);
   fVulkanShadowMapSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT);
   fCountSurfaceMSAASamples:=1;
   fCountCascadedShadowMapMSAASamples:=1;
  end;

 end else begin

  fVulkanSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT);
  fVulkanShadowMapSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT);
  fCountSurfaceMSAASamples:=1;
  fCountCascadedShadowMapMSAASamples:=1;

 end;

{fVulkanSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT);
 fVulkanShadowMapSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT);
 fCountSurfaceMSAASamples:=1;
 fCountCascadedShadowMapMSAASamples:=1;}

 //fVulkanShadowMapSampleCountFlagBits:=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT);

{fFrameGraph.AddImageResourceType('resourcetype_surface',
                                  true,
                                  TVkFormat(VK_FORMAT_UNDEFINED),
                                  TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT),
                                  TpvFrameGraph.TImageType.Surface,
                                  TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.SurfaceDependent,1.0,1.0),
                                  TVkImageUsageFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT),
                                  1
                                 );}

 fExternalOutputImageData:=TpvFrameGraph.TExternalImageData.Create(fFrameGraph);

 fFrameGraph.AddImageResourceType('resourcetype_output_color',
                                  true,
                                  UnitApplication.Application.VirtualReality.ImageFormat,
                                  TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT),
                                  TpvFrameGraph.TImageType.Color,
                                  TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.SurfaceDependent,1.0,1.0,1.0,fCountSurfaceViews),
                                  TVkImageUsageFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT),
                                  1
                                 );

 fFrameGraph.AddImageResourceType('resourcetype_msaa_color',
                                  false,
                                  VK_FORMAT_R16G16B16A16_SFLOAT,
                                  fVulkanSampleCountFlagBits,
                                  TpvFrameGraph.TImageType.Color,
                                  TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.SurfaceDependent,1.0,1.0,1.0,fCountSurfaceViews),
                                  TVkImageUsageFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_SAMPLED_BIT),
                                  1
                                 );

 fFrameGraph.AddImageResourceType('resourcetype_msaa_depth',
                                  false,
                                  VK_FORMAT_D32_SFLOAT{pvApplication.VulkanDepthImageFormat},
                                  fVulkanSampleCountFlagBits,
                                  TpvFrameGraph.TImageType.From(VK_FORMAT_D32_SFLOAT{pvApplication.VulkanDepthImageFormat}),
                                  TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.SurfaceDependent,1.0,1.0,1.0,fCountSurfaceViews),
                                  TVkImageUsageFlags(VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_SAMPLED_BIT),
                                  1
                                 );

 fFrameGraph.AddImageResourceType('resourcetype_orderindependenttransparency_abuffer',
                                  false,
                                  VK_FORMAT_R32G32B32A32_UINT,
                                  fVulkanSampleCountFlagBits,
                                  TpvFrameGraph.TImageType.Color,
                                  TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.SurfaceDependent,1.0,1.0,1.0,fCountSurfaceViews),
                                  TVkImageUsageFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_SAMPLED_BIT),
                                  1
                                 );

 fFrameGraph.AddImageResourceType('resourcetype_orderindependenttransparency_aux',
                                  false,
                                  VK_FORMAT_R32_UINT,
                                  fVulkanSampleCountFlagBits,
                                  TpvFrameGraph.TImageType.Color,
                                  TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.SurfaceDependent,1.0,1.0,1.0,fCountSurfaceViews),
                                  TVkImageUsageFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_SAMPLED_BIT),
                                  1
                                 );

 fFrameGraph.AddImageResourceType('resourcetype_orderindependenttransparency_spinlock',
                                  false,
                                  VK_FORMAT_R32_UINT,
                                  fVulkanSampleCountFlagBits,
                                  TpvFrameGraph.TImageType.Color,
                                  TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.SurfaceDependent,1.0,1.0,1.0,fCountSurfaceViews),
                                  TVkImageUsageFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_SAMPLED_BIT),
                                  1
                                 );

 fFrameGraph.AddImageResourceType('resourcetype_color',
                                  true,
                                  VK_FORMAT_R16G16B16A16_SFLOAT,
                                  TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT),
                                  TpvFrameGraph.TImageType.Color,
                                  TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.SurfaceDependent,1.0,1.0,1.0,fCountSurfaceViews),
                                  TVkImageUsageFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_SAMPLED_BIT),
                                  1
                                 );

 fFrameGraph.AddImageResourceType('resourcetype_srgb_color',
                                  true,
                                  VK_FORMAT_R8G8B8A8_SRGB,
                                  TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT),
                                  TpvFrameGraph.TImageType.Color,
                                  TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.SurfaceDependent,1.0,1.0,1.0,fCountSurfaceViews),
                                  TVkImageUsageFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_SAMPLED_BIT),
                                  1
                                 );

 fFrameGraph.AddImageResourceType('resourcetype_depth',
                                  true,
                                  VK_FORMAT_D32_SFLOAT{pvApplication.VulkanDepthImageFormat},
                                  TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT),
                                  TpvFrameGraph.TImageType.From(VK_FORMAT_D32_SFLOAT{pvApplication.VulkanDepthImageFormat}),
                                  TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.SurfaceDependent,1.0,1.0,1.0,fCountSurfaceViews),
                                  TVkImageUsageFlags(VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_SAMPLED_BIT),
                                  1
                                 );

 fFrameGraph.AddImageResourceType('resourcetype_cascadedshadowmap_msaa_data',
                                  false,
                                  VK_FORMAT_R16G16B16A16_UNORM,
//                                VK_FORMAT_R32G32B32A32_SFLOAT,
                                  fVulkanShadowMapSampleCountFlagBits,
                                  TpvFrameGraph.TImageType.Color,
                                  TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.Absolute,CascadedShadowMapWidth,CascadedShadowMapHeight,1.0,CountCascadedShadowMapCascades),
                                  TVkImageUsageFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_SAMPLED_BIT),
                                  1
                                 );

 fFrameGraph.AddImageResourceType('resourcetype_cascadedshadowmap_msaa_depth',
                                  false,
                                  VK_FORMAT_D32_SFLOAT,
                                  fVulkanShadowMapSampleCountFlagBits,
                                  TpvFrameGraph.TImageType.From(VK_FORMAT_D32_SFLOAT),
                                  TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.Absolute,CascadedShadowMapWidth,CascadedShadowMapHeight,1.0,CountCascadedShadowMapCascades),
                                  TVkImageUsageFlags(VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_SAMPLED_BIT),
                                  1
                                 );

 fFrameGraph.AddImageResourceType('resourcetype_cascadedshadowmap_data',
                                  false,
                                  VK_FORMAT_R16G16B16A16_UNORM,
//                                VK_FORMAT_R32G32B32A32_SFLOAT,
                                  TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT),
                                  TpvFrameGraph.TImageType.Color,
                                  TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.Absolute,CascadedShadowMapWidth,CascadedShadowMapHeight,1.0,CountCascadedShadowMapCascades),
                                  TVkImageUsageFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_SAMPLED_BIT),
                                  1
                                 );

 fFrameGraph.AddImageResourceType('resourcetype_cascadedshadowmap_depth',
                                  false,
                                  VK_FORMAT_D32_SFLOAT,
                                  TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT),
                                  TpvFrameGraph.TImageType.From(VK_FORMAT_D32_SFLOAT),
                                  TpvFrameGraph.TImageSize.Create(TpvFrameGraph.TImageSize.TKind.Absolute,CascadedShadowMapWidth,CascadedShadowMapHeight,1.0,CountCascadedShadowMapCascades),
                                  TVkImageUsageFlags(VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_SAMPLED_BIT),
                                  1
                                 );

 fCascadedShadowMapRenderPass:=TCascadedShadowMapRenderPass.Create(fFrameGraph,self);

 fCascadedShadowMapResolveRenderPass:=TCascadedShadowMapResolveRenderPass.Create(fFrameGraph,self);

 fCascadedShadowMapBlurRenderPasses[0]:=TCascadedShadowMapBlurRenderPass.Create(fFrameGraph,self,true);

 fCascadedShadowMapBlurRenderPasses[1]:=TCascadedShadowMapBlurRenderPass.Create(fFrameGraph,self,false);

 fForwardRenderPass:=TForwardRenderPass.Create(fFrameGraph,self);

 fOrderIndependentTransparencyClearCustomPass:=TOrderIndependentTransparencyClearCustomPass.Create(fFrameGraph,self);

 fOrderIndependentTransparencyRenderPass:=TOrderIndependentTransparencyRenderPass.Create(fFrameGraph,self);
 fOrderIndependentTransparencyRenderPass.AddExplicitPassDependency(fOrderIndependentTransparencyClearCustomPass);

 fOrderIndependentTransparencyResolveRenderPass:=TOrderIndependentTransparencyResolveRenderPass.Create(fFrameGraph,self);
//fOrderIndependentTransparencyResolveRenderPass.AddExplicitPassDependency(fOrderIndependentTransparencyRenderPass);

 fTonemappingRenderPass:=TTonemappingRenderPass.Create(fFrameGraph,self);

 fAntialiasingRenderPass:=TAntialiasingRenderPass.Create(fFrameGraph,self);

 fFrameGraph.RootPass:=fAntialiasingRenderPass;

 fFrameGraph.DoWaitOnSemaphore:=true;

 fFrameGraph.DoSignalSemaphore:=true;

 fFrameGraph.Compile;

// fFrameGraph.Dump;

end;

destructor TScreenMain.Destroy;
var Index:TpvSizeInt;
begin
 for Index:=0 to length(fCascadedShadowMapVulkanUniformBuffers)-1 do begin
  FreeAndNil(fCascadedShadowMapVulkanUniformBuffers[Index]);
 end;
 FreeAndNil(fFrameGraph);
 FreeAndNil(fGroupInstance);
 FreeAndNil(fGroup);
 FreeAndNil(fPrimaryDirectionalLight);
 FreeAndNil(fScene3D);
 FreeAndNil(fUpdateLock);
 inherited Destroy;
end;

procedure TScreenMain.Show;
var Index:TpvSizeInt;
    Stream:TStream;
begin

 inherited Show;

 fSkyCubeMap:=TSkyCubeMap.Create;

 fGGXBRDF:=TGGXBRDF.Create;

 fGGXEnvMapCubeMap:=TGGXEnvMapCubeMap.Create(fSkyCubeMap.DescriptorImageInfo);

 fCharlieBRDF:=TCharlieBRDF.Create;

 fCharlieEnvMapCubeMap:=TCharlieEnvMapCubeMap.Create(fSkyCubeMap.DescriptorImageInfo);

 fLambertianEnvMapCubeMap:=TLambertianEnvMapCubeMap.Create(fSkyCubeMap.DescriptorImageInfo);

 fTime:=0.0;

 fCameraRotationX:=0.0;//frac(fTime*0.03125);

 fCameraRotationY:=0.0;

 fZoom:=1.0;

 fVulkanGraphicsCommandPool:=TpvVulkanCommandPool.Create(pvApplication.VulkanDevice,
                                                         pvApplication.VulkanDevice.GraphicsQueueFamilyIndex,
                                                         TVkCommandPoolCreateFlags(VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT));

 fVulkanGraphicsCommandBuffer:=TpvVulkanCommandBuffer.Create(fVulkanGraphicsCommandPool,VK_COMMAND_BUFFER_LEVEL_PRIMARY);

 fVulkanGraphicsCommandBufferFence:=TpvVulkanFence.Create(pvApplication.VulkanDevice);

 fVulkanTransferCommandPool:=TpvVulkanCommandPool.Create(pvApplication.VulkanDevice,
                                                         pvApplication.VulkanDevice.TransferQueueFamilyIndex,
                                                         TVkCommandPoolCreateFlags(VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT));

 fVulkanTransferCommandBuffer:=TpvVulkanCommandBuffer.Create(fVulkanTransferCommandPool,VK_COMMAND_BUFFER_LEVEL_PRIMARY);

 fVulkanTransferCommandBufferFence:=TpvVulkanFence.Create(pvApplication.VulkanDevice);

 fScene3D.Upload;

 Stream:=pvApplication.Assets.GetAssetStream('textures/sheenelut.png');
 try
  fSheenELUT:=TpvVulkanTexture.CreateFromImage(pvApplication.VulkanDevice,
                                                pvApplication.VulkanDevice.GraphicsQueue,
                                                fVulkanGraphicsCommandBuffer,
                                                fVulkanGraphicsCommandBufferFence,
                                                pvApplication.VulkanDevice.TransferQueue,
                                                fVulkanTransferCommandBuffer,
                                                fVulkanTransferCommandBufferFence,
                                                Stream,
                                                false,
                                                false);
  fSheenELUT.UpdateSampler;
 finally
  FreeAndNil(Stream);
 end;

 FillChar(fSwapChainImageStates,SizeOf(TSwapChainImageStates),#0);

 for Index:=0 to MaxSwapChainImages-1 do begin
  fVulkanRenderSemaphores[Index]:=TpvVulkanSemaphore.Create(pvApplication.VulkanDevice);
 end;

 for Index:=0 to length(fCascadedShadowMapVulkanUniformBuffers)-1 do begin
  fCascadedShadowMapVulkanUniformBuffers[Index]:=TpvVulkanBuffer.Create(pvApplication.VulkanDevice,
                                                                        SizeOf(TCascadedShadowMapUniformBuffer),
                                                                        TVkBufferUsageFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT) or TVkBufferUsageFlags(VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT),
                                                                        TVkSharingMode(VK_SHARING_MODE_EXCLUSIVE),
                                                                        [],
                                                                        TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT),
                                                                        TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT) or TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT),
                                                                        0,
                                                                        0,
                                                                        0,
                                                                        0,
                                                                        []);
 end;

 fOrderIndependentTransparentUniformVulkanBuffer:=TpvVulkanBuffer.Create(pvApplication.VulkanDevice,
                                                                         SizeOf(TOrderIndependentTransparentUniformBuffer),
                                                                         TVkBufferUsageFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT) or TVkBufferUsageFlags(VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT),
                                                                         TVkSharingMode(VK_SHARING_MODE_EXCLUSIVE),
                                                                         [],
                                                                         0,
                                                                         TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT),
                                                                         0,
                                                                         0,
                                                                         0,
                                                                         0,
                                                                         []);

 fFrameGraph.Show;

 pvApplication.SkipNextDrawFrame:=true;

end;

procedure TScreenMain.Hide;
var Index:TpvSizeInt;
begin

 fFrameGraph.Hide;

 for Index:=0 to MaxSwapChainImages-1 do begin
  FreeAndNil(fVulkanRenderSemaphores[Index]);
 end;

 for Index:=0 to length(fCascadedShadowMapVulkanUniformBuffers)-1 do begin
  FreeAndNil(fCascadedShadowMapVulkanUniformBuffers[Index]);
 end;

 fScene3D.Unload;

 FreeAndNil(fOrderIndependentTransparentUniformVulkanBuffer);

 FreeAndNil(fVulkanTransferCommandBufferFence);
 FreeAndNil(fVulkanTransferCommandBuffer);
 FreeAndNil(fVulkanTransferCommandPool);
 FreeAndNil(fVulkanGraphicsCommandBufferFence);
 FreeAndNil(fVulkanGraphicsCommandBuffer);
 FreeAndNil(fVulkanGraphicsCommandPool);

 FreeAndNil(fSheenELUT);

 FreeAndNil(fCharlieEnvMapCubeMap);

 FreeAndNil(fCharlieBRDF);

 FreeAndNil(fGGXEnvMapCubeMap);

 FreeAndNil(fGGXBRDF);

 FreeAndNil(fLambertianEnvMapCubeMap);

 FreeAndNil(fSkyCubeMap);

 inherited Hide;
end;

procedure TScreenMain.Resume;
begin
 inherited Resume;
 pvApplication.SkipNextDrawFrame:=true;
end;

procedure TScreenMain.Pause;
begin
 inherited Pause;
end;

procedure TScreenMain.Resize(const aWidth,aHeight:TpvInt32);
begin
 inherited Resize(aWidth,aHeight);
 pvApplication.SkipNextDrawFrame:=true;
end;

procedure TScreenMain.AfterCreateSwapChain;
var Index:TpvSizeInt;
begin
 inherited AfterCreateSwapChain;

 fWidth:=UnitApplication.Application.VirtualReality.Width;

 fHeight:=UnitApplication.Application.VirtualReality.Height;

 FillChar(fSwapChainImageStates,SizeOf(TSwapChainImageStates),#0);

 fFrameGraph.SetSwapChain(pvApplication.VulkanSwapChain,
                          pvApplication.VulkanDepthImageFormat);

 fFrameGraph.SurfaceWidth:=fWidth;
 fFrameGraph.SurfaceHeight:=fHeight;

 fExternalOutputImageData.VulkanImages.Clear;
 for Index:=0 to UnitApplication.Application.VirtualReality.VulkanImages.Count-1 do begin
  fExternalOutputImageData.VulkanImages.Add(UnitApplication.Application.VirtualReality.VulkanImages[Index]);
 end;

 (fFrameGraph.ResourceTypeByName['resourcetype_output_color'] as TpvFrameGraph.TImageResourceType).Format:=UnitApplication.Application.VirtualReality.ImageFormat;

 fCountOrderIndependentTransparencyLayers:=CountOrderIndependentTransparencyLayers;

 fOrderIndependentTransparentUniformBuffer.ViewPort.x:=fWidth;
 fOrderIndependentTransparentUniformBuffer.ViewPort.y:=fHeight;
 fOrderIndependentTransparentUniformBuffer.ViewPort.z:=fOrderIndependentTransparentUniformBuffer.ViewPort.x*fOrderIndependentTransparentUniformBuffer.ViewPort.y;
 fOrderIndependentTransparentUniformBuffer.ViewPort.w:=(fCountOrderIndependentTransparencyLayers and $ffff) or ((fCountSurfaceMSAASamples and $ffff) shl 16);

 fOrderIndependentTransparentUniformVulkanBuffer.UploadData(pvApplication.VulkanDevice.TransferQueue,
                                                            fVulkanTransferCommandBuffer,
                                                            fVulkanTransferCommandBufferFence,
                                                            fOrderIndependentTransparentUniformBuffer,
                                                            0,
                                                            SizeOf(TOrderIndependentTransparentUniformBuffer));

 for Index:=0 to fFrameGraph.CountSwapChainImages-1 do begin

  fOrderIndependentTransparencyABufferBuffers[Index]:=TOrderIndependentTransparencyBuffer.Create(fWidth*fHeight*fCountOrderIndependentTransparencyLayers*fCountSurfaceViews*(SizeOf(UInt32)*4),
                                                                                                 VK_FORMAT_R32G32B32A32_UINT,
                                                                                                 TVkBufferUsageFlags(VK_BUFFER_USAGE_STORAGE_TEXEL_BUFFER_BIT));

  fOrderIndependentTransparencyAuxImages[Index]:=TOrderIndependentTransparencyImage.Create(fWidth,
                                                                                           fHeight,
                                                                                           fCountSurfaceViews,
                                                                                           VK_FORMAT_R32_UINT,
                                                                                           VK_SAMPLE_COUNT_1_BIT);

  fOrderIndependentTransparencySpinLockImages[Index]:=TOrderIndependentTransparencyImage.Create(fWidth,
                                                                                                fHeight,
                                                                                                fCountSurfaceViews,
                                                                                                VK_FORMAT_R32_UINT,
                                                                                                VK_SAMPLE_COUNT_1_BIT);

 end;

 fFrameGraph.AfterCreateSwapChain;

 pvApplication.SkipNextDrawFrame:=true;

end;

procedure TScreenMain.BeforeDestroySwapChain;
var Index:TpvSizeInt;
begin
 fFrameGraph.BeforeDestroySwapChain;
 fExternalOutputImageData.VulkanImages.Clear;
 for Index:=0 to MaxSwapChainImages-1 do begin
  FreeAndNil(fOrderIndependentTransparencyABufferBuffers[Index]);
  FreeAndNil(fOrderIndependentTransparencyAuxImages[Index]);
  FreeAndNil(fOrderIndependentTransparencySpinLockImages[Index]);
 end;
 inherited BeforeDestroySwapChain;
end;

function TScreenMain.CanBeParallelProcessed:boolean;
begin
 result:=false;
end;

procedure TScreenMain.CalculateCascadedShadowMaps(const aSwapChainImageIndex:Int32;const aViewLeft,aViewRight:TpvScene3D.TView);
{$undef UseSphereBasedCascadedShadowMaps}
const CascadedShadowMapSplitConstant=0.975;
      FrustumCorners:array[0..7] of TpvVector3=
       (
        (x:-1.0;y:-1.0;z:0.0),
        (x:1.0;y:-1.0;z:0.0),
        (x:-1.0;y:1.0;z:0.0),
        (x:1.0;y:1.0;z:0.0),
        (x:-1.0;y:-1.0;z:1.0),
        (x:1.0;y:-1.0;z:1.0),
        (x:-1.0;y:1.0;z:1.0),
        (x:1.0;y:1.0;z:1.0)
       );
var CascadedShadowMapIndex,Index:TpvSizeInt;
    CascadedShadowMaps:TScreenMain.PCascadedShadowMaps;
    CascadedShadowMap:TScreenMain.PCascadedShadowMap;
    SceneWorldSpaceBoundingBox,
    SceneLightSpaceBoundingBox,
    LightSpaceAABB:TpvAABB;
    LightForwardVector,LightSideVector,
    LightUpVector,LightSpaceCorner:TpvVector3;
{$ifdef UseSphereBasedCascadedShadowMaps}
    {SplitCenter,SplitBounds,}SplitOffset,SplitScale:TpvVector3;
    Offset,Step:TpvVector2;
    LightSpaceSphere:TpvSphere;
{$else}
    ShadowOrigin,RoundedOrigin,RoundOffset:TpvVector2;
{$endif}
    ProjectionMatrix,
    LightViewMatrix,
    LightProjectionMatrix,
    LightViewProjectionMatrix,
    FromViewSpaceToLightSpaceMatrixLeft,
    FromViewSpaceToLightSpaceMatrixRight,
    InverseProjectionMatrixLeft,
    InverseProjectionMatrixRight:TpvMatrix4x4;
    MinZ,MaxZ,MinZExtents,MaxZExtents,ZMargin,
    Ratio,FadeStartValue,LastValue,Value,
{$ifdef UseSphereBasedCascadedShadowMaps}
    Border,RoundedUpLightSpaceSphereRadius,
{$endif}
    zNear,zFar:TpvScalar;
    DoNeedRefitNearFarPlanes:boolean;
    ViewSpaceFrustumCornersLeft,
    ViewSpaceFrustumCornersRight:array[0..7] of TpvVector3;
    SwapChainImageState:PSwapChainImageState;
begin

 if IsInfinite(UnitApplication.Application.VirtualReality.ZFar) then begin
  zNear:=0.1;
  zFar:=4096.0;
  DoNeedRefitNearFarPlanes:=true;
 end else begin
  zNear:=abs(UnitApplication.Application.VirtualReality.ZNear);
  zFar:=abs(UnitApplication.Application.VirtualReality.ZFar);
  DoNeedRefitNearFarPlanes:=UnitApplication.Application.VirtualReality.ZFar<0.0;
 end;

 ProjectionMatrix:=aViewLeft.ProjectionMatrix;
 if DoNeedRefitNearFarPlanes then begin
  ProjectionMatrix[2,2]:=zFar/(zNear-zFar);
  ProjectionMatrix[3,2]:=(-(zNear*zFar))/(zFar-zNear);
 end;
 InverseProjectionMatrixLeft:=ProjectionMatrix.Inverse;

 ProjectionMatrix:=aViewRight.ProjectionMatrix;
 if DoNeedRefitNearFarPlanes then begin
  ProjectionMatrix[2,2]:=zFar/(zNear-zFar);
  ProjectionMatrix[3,2]:=(-(zNear*zFar))/(zFar-zNear);
 end;
 InverseProjectionMatrixRight:=ProjectionMatrix.Inverse;

 SceneWorldSpaceBoundingBox:=fScene3D.BoundingBox;

 LightForwardVector:=-TSkyCubeMap.LightDirection.xyz.Normalize;
 LightSideVector:=TpvVector3.InlineableCreate(-aViewLeft.ViewMatrix.RawComponents[0,2],
                                              -aViewLeft.ViewMatrix.RawComponents[1,2],
                                              -aViewLeft.ViewMatrix.RawComponents[2,2]).Normalize;
 if abs(LightForwardVector.Dot(LightSideVector))>0.5 then begin
  if abs(LightForwardVector.Dot(TpvVector3.YAxis))<0.9 then begin
   LightSideVector:=TpvVector3.YAxis;
  end else begin
   LightSideVector:=TpvVector3.ZAxis;
  end;
 end;
 LightUpVector:=(LightForwardVector.Cross(LightSideVector)).Normalize;
 LightSideVector:=(LightUpVector.Cross(LightForwardVector)).Normalize;
 LightViewMatrix.RawComponents[0,0]:=LightSideVector.x;
 LightViewMatrix.RawComponents[0,1]:=LightUpVector.x;
 LightViewMatrix.RawComponents[0,2]:=LightForwardVector.x;
 LightViewMatrix.RawComponents[0,3]:=0.0;
 LightViewMatrix.RawComponents[1,0]:=LightSideVector.y;
 LightViewMatrix.RawComponents[1,1]:=LightUpVector.y;
 LightViewMatrix.RawComponents[1,2]:=LightForwardVector.y;
 LightViewMatrix.RawComponents[1,3]:=0.0;
 LightViewMatrix.RawComponents[2,0]:=LightSideVector.z;
 LightViewMatrix.RawComponents[2,1]:=LightUpVector.z;
 LightViewMatrix.RawComponents[2,2]:=LightForwardVector.z;
 LightViewMatrix.RawComponents[2,3]:=0.0;
 LightViewMatrix.RawComponents[3,0]:=0.0;
 LightViewMatrix.RawComponents[3,1]:=0.0;
 LightViewMatrix.RawComponents[3,2]:=0.0;
 LightViewMatrix.RawComponents[3,3]:=1.0;

 FromViewSpaceToLightSpaceMatrixLeft:=aViewLeft.ViewMatrix.Inverse*LightViewMatrix;

 FromViewSpaceToLightSpaceMatrixRight:=aViewRight.ViewMatrix.Inverse*LightViewMatrix;

 SceneLightSpaceBoundingBox:=SceneWorldSpaceBoundingBox.Transform(LightViewMatrix);

 MinZExtents:=SceneLightSpaceBoundingBox.Min.z-16;
 MaxZExtents:=SceneLightSpaceBoundingBox.Max.z+16;
 ZMargin:=(MaxZExtents-MinZExtents)*0.25;
 MinZExtents:=MinZExtents-ZMargin;
 MaxZExtents:=MaxZExtents+ZMargin;

 for Index:=0 to 7 do begin
  ViewSpaceFrustumCornersLeft[Index]:=InverseProjectionMatrixLeft.MulHomogen(TpvVector4.InlineableCreate(FrustumCorners[Index],1.0)).xyz;
  ViewSpaceFrustumCornersRight[Index]:=InverseProjectionMatrixRight.MulHomogen(TpvVector4.InlineableCreate(FrustumCorners[Index],1.0)).xyz;
 end;

 CascadedShadowMaps:=@fSwapChainImageCascadedShadowMaps[aSwapChainImageIndex];

 CascadedShadowMaps^[0].SplitDepths.x:=zNear;
 Ratio:=zFar/zNear;
 LastValue:=0.0;
 for CascadedShadowMapIndex:=1 to CountCascadedShadowMapCascades-1 do begin
  Value:=(CascadedShadowMapSplitConstant*zNear*power(Ratio,CascadedShadowMapIndex/CountCascadedShadowMapCascades))+
         ((1.0-CascadedShadowMapSplitConstant)*(zNear+((CascadedShadowMapIndex/CountCascadedShadowMapCascades)*(zFar-zNear))));
  FadeStartValue:=Min(Max(((Value-LastValue)*0.95)+LastValue,zNear),zFar);
  LastValue:=Value;
  CascadedShadowMaps^[CascadedShadowMapIndex].SplitDepths.x:=Min(Max(FadeStartValue,zNear),zFar);
  CascadedShadowMaps^[CascadedShadowMapIndex-1].SplitDepths.y:=Min(Max(Value,zNear),zFar);
 end;
 CascadedShadowMaps^[CountCascadedShadowMapCascades-1].SplitDepths.y:=zFar;

 for CascadedShadowMapIndex:=0 to CountCascadedShadowMapCascades-1 do begin

  CascadedShadowMap:=@CascadedShadowMaps^[CascadedShadowMapIndex];

  MinZ:=CascadedShadowMap^.SplitDepths.x;
  MaxZ:=CascadedShadowMap^.SplitDepths.y;

  for Index:=0 to 7 do begin
   case Index of
    0..3:begin
     LightSpaceCorner:=ViewSpaceFrustumCornersLeft[Index].Lerp(ViewSpaceFrustumCornersLeft[Index+4],(MinZ-zNear)/(zFar-zNear));
    end;
    else {4..7:}begin
     LightSpaceCorner:=ViewSpaceFrustumCornersLeft[Index-4].Lerp(ViewSpaceFrustumCornersLeft[Index],(MaxZ-zNear)/(zFar-zNear));
    end;
   end;
   LightSpaceCorner:=FromViewSpaceToLightSpaceMatrixLeft*LightSpaceCorner;
   if Index=0 then begin
    LightSpaceAABB.Min:=LightSpaceCorner;
    LightSpaceAABB.Max:=LightSpaceCorner;
   end else begin
    LightSpaceAABB:=LightSpaceAABB.CombineVector3(LightSpaceCorner);
   end;
  end;
  for Index:=0 to 7 do begin
   case Index of
    0..3:begin
     LightSpaceCorner:=ViewSpaceFrustumCornersRight[Index].Lerp(ViewSpaceFrustumCornersRight[Index+4],(MinZ-zNear)/(zFar-zNear));
    end;
    else {4..7:}begin
     LightSpaceCorner:=ViewSpaceFrustumCornersRight[Index-4].Lerp(ViewSpaceFrustumCornersRight[Index],(MaxZ-zNear)/(zFar-zNear));
    end;
   end;
   LightSpaceAABB:=LightSpaceAABB.CombineVector3(FromViewSpaceToLightSpaceMatrixRight*LightSpaceCorner);
  end;

  if LightSpaceAABB.Intersect(SceneLightSpaceBoundingBox) then begin
   LightSpaceAABB:=LightSpaceAABB.GetIntersection(SceneLightSpaceBoundingBox);
  end;

  //LightSpaceAABB:=SceneLightSpaceBoundingBox;

{$ifdef UseSphereBasedCascadedShadowMaps}
  LightSpaceSphere:=TpvSphere.CreateFromAABB(LightSpaceAABB);

  Border:=4;

  RoundedUpLightSpaceSphereRadius:=ceil(LightSpaceSphere.Radius);

  Step.x:=(2.0*RoundedUpLightSpaceSphereRadius)/(CascadedShadowMapWidth-(2.0*Border));
  Step.y:=(2.0*RoundedUpLightSpaceSphereRadius)/(CascadedShadowMapHeight-(2.0*Border));

  Offset.x:=floor((LightSpaceSphere.Center.x-RoundedUpLightSpaceSphereRadius)/Step.x);
  Offset.y:=floor((LightSpaceSphere.Center.y-RoundedUpLightSpaceSphereRadius)/Step.y);

{ SplitCenter.x:=(Offset.x*Step.x)+RoundedUpLightSpaceSphereRadius;
  SplitCenter.y:=(Offset.y*Step.y)+RoundedUpLightSpaceSphereRadius;
  SplitCenter.z:=-0.5*(MinZExtents+MaxZExtents);

  SplitBounds.x:=RoundedUpLightSpaceSphereRadius;
  SplitBounds.y:=RoundedUpLightSpaceSphereRadius;
  SplitBounds.z:=0.5*(MaxZExtents-MinZExtents);}

  SplitScale.x:=1.0/Step.x;
  SplitScale.y:=1.0/Step.y;
  SplitScale.z:=(-1.0)/(MaxZExtents-MinZExtents);

  SplitOffset.x:=Border-Offset.x;
  SplitOffset.y:=Border-Offset.y;
  SplitOffset.z:=(-MinZExtents)/(MaxZExtents-MinZExtents);

  LightProjectionMatrix[0,0]:=2.0*(SplitScale.x/CascadedShadowMapWidth);
  LightProjectionMatrix[0,1]:=0.0;
  LightProjectionMatrix[0,2]:=0.0;
  LightProjectionMatrix[0,3]:=0.0;
  LightProjectionMatrix[1,0]:=0.0;
  LightProjectionMatrix[1,1]:=2.0*(SplitScale.y/CascadedShadowMapHeight);
  LightProjectionMatrix[1,2]:=0.0;
  LightProjectionMatrix[1,3]:=0.0;
  LightProjectionMatrix[2,0]:=0.0;
  LightProjectionMatrix[2,1]:=0.0;
  LightProjectionMatrix[2,2]:=SplitScale.z;//2.0*SplitScale.z;
  LightProjectionMatrix[2,3]:=0.0;
  LightProjectionMatrix[3,0]:=(2.0*(SplitOffset.x/CascadedShadowMapWidth))-1.0;
  LightProjectionMatrix[3,1]:=(2.0*(SplitOffset.y/CascadedShadowMapHeight))-1.0;
  LightProjectionMatrix[3,2]:=SplitOffset.z;//(2.0*SplitOffset.z)-1.0;
  LightProjectionMatrix[3,3]:=1.0;

{$else}

  LightProjectionMatrix:=TpvMatrix4x4.CreateOrthoRightHandedZeroToOne(LightSpaceAABB.Min.x,
                                                                      LightSpaceAABB.Max.x,
                                                                      LightSpaceAABB.Min.y,
                                                                      LightSpaceAABB.Max.y,
                                                                      MinZExtents,
                                                                      MaxZExtents);

  LightViewProjectionMatrix:=LightViewMatrix*LightProjectionMatrix;

  ShadowOrigin:=(LightViewProjectionMatrix.MulHomogen(TpvVector3.Origin)).xy*TpvVector2.InlineableCreate(CascadedShadowMapWidth*0.5,CascadedShadowMapHeight*0.5);
  RoundedOrigin.x:=round(ShadowOrigin.x);
  RoundedOrigin.y:=round(ShadowOrigin.y);
  RoundOffset:=(RoundedOrigin-ShadowOrigin)*TpvVector2.InlineableCreate(2.0/CascadedShadowMapWidth,2.0/CascadedShadowMapHeight);
  LightProjectionMatrix[3,0]:=LightProjectionMatrix[3,0]+RoundOffset.x;
  LightProjectionMatrix[3,1]:=LightProjectionMatrix[3,1]+RoundOffset.y;

{$endif}

  LightViewProjectionMatrix:=LightViewMatrix*LightProjectionMatrix;

  CascadedShadowMap.View.ViewMatrix:=LightViewMatrix;
  CascadedShadowMap.View.ProjectionMatrix:=LightProjectionMatrix;
  CascadedShadowMap.CombinedMatrix:=LightViewProjectionMatrix;

  fCascadedShadowMapUniformBuffers[aSwapChainImageIndex].Matrices[CascadedShadowMapIndex]:=LightViewProjectionMatrix;
  fCascadedShadowMapUniformBuffers[aSwapChainImageIndex].SplitDepths[CascadedShadowMapIndex]:=TpvVector4.Create(CascadedShadowMap^.SplitDepths,0.0);

 end;

 SwapChainImageState:=@fSwapChainImageStates[aSwapChainImageIndex];

 SwapChainImageState^.CascadedShadowMapViewIndex:=fScene3D.AddView(CascadedShadowMaps^[0].View);
 for CascadedShadowMapIndex:=1 to CountCascadedShadowMapCascades-1 do begin
  fScene3D.AddView(CascadedShadowMaps^[CascadedShadowMapIndex].View);
 end;

 SwapChainImageState^.CountCascadedShadowMapViews:=CountCascadedShadowMapCascades;

end;

procedure TScreenMain.Update(const aDeltaTime:TpvDouble);
begin
 inherited Update(aDeltaTime);
 fFrameGraph.Update(pvApplication.UpdateSwapChainImageIndex,pvApplication.UpdateFrameCounter);
end;

function TScreenMain.IsReadyForDrawOfSwapChainImageIndex(const aSwapChainImageIndex:TpvInt32):boolean;
begin
 result:=TPasMPInterlocked.Read(fSwapChainImageStates[aSwapChainImageIndex].Ready);
end;

procedure TScreenMain.DrawUpdate(const aSwapChainImageIndex:TpvInt32;const aDeltaTime:TpvDouble);
var Index:TpvSizeInt;
    ModelMatrix,ViewMatrix:TpvMatrix4x4;
    Center,Bounds:TpvVector3;
    t0,t1:Double;
    ViewLeft,ViewRight:TpvScene3D.TView;
    SwapChainImageState:PSwapChainImageState;
    BlendFactor,Factor:single;
begin
 inherited Update(aDeltaTime);

 SwapChainImageState:=@fSwapChainImageStates[aSwapChainImageIndex];

 begin

  fUpdateLock.Acquire;
  try

   ModelMatrix:=TpvMatrix4x4.Identity; // TpvMatrix4x4.CreateRotate(State^.AnglePhases[0]*TwoPI,TpvVector3.Create(0.0,0.0,1.0))*TpvMatrix4x4.CreateRotate(State^.AnglePhases[1]*TwoPI,TpvVector3.Create(0.0,1.0,0.0));

   fGroupInstance.ModelMatrix:=ModelMatrix;

   begin
    BlendFactor:=1.0-exp(-(pvApplication.DeltaTime*4.0));
    for Index:=-1 to fGroupInstance.Group.Animations.Count-1 do begin
     Factor:=fGroupInstance.Automations[Index].Factor;
     if Index=fAnimationIndex then begin
      if Factor<0.0 then begin
       Factor:=0.0;
       fGroupInstance.Automations[Index].ShadowTime:=0.0;
      end;
      Factor:=(Factor*(1.0-BlendFactor))+(1.0*BlendFactor);
     end else if Factor>0.0 then begin
      Factor:=Factor*(1.0-BlendFactor);
      if Factor<1e-5 then begin
       Factor:=-1.0;
      end;
     end;
     if Factor>0.0 then begin
      if Index>=0 then begin
       t0:=fGroupInstance.Group.Animations[Index].GetAnimationBeginTime;
       t1:=fGroupInstance.Group.Animations[Index].GetAnimationEndTime;
       fGroupInstance.Automations[Index].Time:=fGroupInstance.Automations[Index].ShadowTime+t0;
       fGroupInstance.Automations[Index].ShadowTime:=ModuloPos(fGroupInstance.Automations[Index].ShadowTime+pvApplication.DeltaTime,t1-t0);
       fGroupInstance.Automations[Index].Complete:=true;
      end else begin
       fGroupInstance.Automations[Index].Time:=0.0;
       fGroupInstance.Automations[Index].Complete:=false;
      end;
     end else begin
      fGroupInstance.Automations[Index].Time:=0.0;
     end;
     fGroupInstance.Automations[Index].Factor:=Factor;
    end;
   end;

   fScene3D.Update(aSwapChainImageIndex);

   fScene3D.ClearViews;

   Center:=(fScene3D.BoundingBox.Min+fScene3D.BoundingBox.Max)*0.5;
   Bounds:=(fScene3D.BoundingBox.Max-fScene3D.BoundingBox.Min)*0.5;
   ViewMatrix:=TpvMatrix4x4.CreateLookAt(Center+(TpvVector3.Create(sin(fCameraRotationX*PI*2.0)*cos(-fCameraRotationY*PI*2.0),
                                                                   sin(-fCameraRotationY*PI*2.0),
                                                                   cos(fCameraRotationX*PI*2.0)*cos(-fCameraRotationY*PI*2.0)).Normalize*
                                                         (Max(Max(Bounds[0],Bounds[1]),Bounds[2])*2.0*fZoom)),
                                         Center,
                                         TpvVector3.Create(0.0,1.0,0.0));//*TpvMatrix4x4.FlipYClipSpace;

   ViewLeft.ViewMatrix:=ViewMatrix*UnitApplication.Application.VirtualReality.GetPositionMatrix(0);
   ViewLeft.ProjectionMatrix:=UnitApplication.Application.VirtualReality.GetProjectionMatrix(0);

   ViewRight.ViewMatrix:=ViewMatrix*UnitApplication.Application.VirtualReality.GetPositionMatrix(1);
   ViewRight.ProjectionMatrix:=UnitApplication.Application.VirtualReality.GetProjectionMatrix(1);

   SwapChainImageState^.FinalViewIndex:=fScene3D.AddViews([ViewLeft,ViewRight]);

   SwapChainImageState^.CountViews:=2;

   CalculateCascadedShadowMaps(aSwapChainImageIndex,
                               ViewLeft,
                               ViewRight);

   fCascadedShadowMapVulkanUniformBuffers[aSwapChainImageIndex].UpdateData(fCascadedShadowMapUniformBuffers[aSwapChainImageIndex],
                                                                           0,
                                                                           SizeOf(TCascadedShadowMapUniformBuffer));

   fScene3D.UpdateViews(aSwapChainImageIndex);

   TPasMPInterlocked.Write(SwapChainImageState^.Ready,true);

   fTime:=fTime+pvApplication.DeltaTime;

  finally
   fUpdateLock.Release;
  end;

 end;

end;

procedure TScreenMain.Draw(const aSwapChainImageIndex:TpvInt32;var aWaitSemaphore:TpvVulkanSemaphore;const aWaitFence:TpvVulkanFence=nil);
var SwapChainImageState:TScreenMain.PSwapChainImageState;
begin
 inherited Draw(aSwapChainImageIndex,aWaitSemaphore,nil);
//writeln('D: ',SwapChainImageIndex,' ',aSwapChainImageIndex);

 SwapChainImageState:=@fSwapChainImageStates[aSwapChainImageIndex];

 DrawUpdate(aSwapChainImageIndex,pvApplication.DeltaTime);

 // Main viewport(s)
 fScene3D.Prepare(aSwapChainImageIndex,
                  0,
                  SwapChainImageState^.FinalViewIndex,
                  SwapChainImageState^.CountViews,
                  fWidth,
                  fHeight,
                  true,
                  true);

 // Cascaded shadow map viewport(s)
 fScene3D.Prepare(aSwapChainImageIndex,
                  1,
                  SwapChainImageState^.CascadedShadowMapViewIndex,
                  SwapChainImageState^.CountCascadedShadowMapViews,
                  CascadedShadowMapWidth,
                  CascadedShadowMapHeight,
                  false,
                  true);

 fFrameGraph.Draw(aSwapChainImageIndex,
                  pvApplication.DrawFrameCounter,
                  aWaitSemaphore,
                  fVulkanRenderSemaphores[aSwapChainImageIndex],
                  aWaitFence);

 TPasMPInterlocked.Write(SwapChainImageState^.Ready,false);

 aWaitSemaphore:=fVulkanRenderSemaphores[aSwapChainImageIndex];

end;

function TScreenMain.KeyEvent(const aKeyEvent:TpvApplicationInputKeyEvent):boolean;
begin
 result:=inherited KeyEvent(aKeyEvent);
 if aKeyEvent.KeyEventType=TpvApplicationInputKeyEventType.Down then begin
  case aKeyEvent.KeyCode of
   KEYCODE_ESCAPE:begin
    pvApplication.Terminate;
   end;
   KEYCODE_V,KEYCODE_B:begin
    if fAnimationIndex<0 then begin
     fAnimationIndex:=fGroupInstance.Group.Animations.Count-1;
    end else begin
     dec(fAnimationIndex);
    end;
   end;
   KEYCODE_N,KEYCODE_M:begin
    inc(fAnimationIndex);
    if fAnimationIndex>=fGroupInstance.Group.Animations.Count then begin
     fAnimationIndex:=-1;
    end;
   end;
   KEYCODE_0..KEYCODE_9:begin
    if ((aKeyEvent.KeyCode-(KEYCODE_0+1))>=-1) and ((aKeyEvent.KeyCode-(KEYCODE_0+1))<fGroupInstance.Group.Animations.Count) then begin
     fAnimationIndex:=aKeyEvent.KeyCode-(KEYCODE_0+1);
    end;
   end;
  end;
 end;
end;

function TScreenMain.PointerEvent(const aPointerEvent:TpvApplicationInputPointerEvent):boolean;
begin
 result:=inherited PointerEvent(aPointerEvent);
 if not result then begin
  if (aPointerEvent.PointerEventType=TpvApplicationInputPointerEventType.Motion) and
     (TpvApplicationInputPointerButton.Left in aPointerEvent.Buttons) then begin
   fUpdateLock.Acquire;
   try
    fCameraRotationX:=frac(fCameraRotationX+(1.0-(aPointerEvent.RelativePosition.x*(1.0/pvApplication.VulkanSwapChain.Width))));
    fCameraRotationY:=frac(fCameraRotationY+(1.0-(aPointerEvent.RelativePosition.y*(1.0/pvApplication.VulkanSwapChain.Height))));
   finally
    fUpdateLock.Release;
   end;
   result:=true;
  end;
 end;
end;

function TScreenMain.Scrolled(const aRelativeAmount:TpvVector2):boolean;
begin
 result:=inherited Scrolled(aRelativeAmount);
 if not result then begin
  fUpdateLock.Acquire;
  try
   fZoom:=Max(1e-4,fZoom+((aRelativeAmount.x+aRelativeAmount.y)*0.1));
  finally
   fUpdateLock.Release;
  end;
  result:=true;
 end;
end;

end.
