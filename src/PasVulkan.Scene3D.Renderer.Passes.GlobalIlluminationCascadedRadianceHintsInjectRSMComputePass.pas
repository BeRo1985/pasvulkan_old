(******************************************************************************
 *                                 PasVulkan                                  *
 ******************************************************************************
 *                       Version see PasVulkan.Framework.pas                  *
 ******************************************************************************
 *                                zlib license                                *
 *============================================================================*
 *                                                                            *
 * Copyright (C) 2016-2020, Benjamin Rosseaux (benjamin@rosseaux.de)          *
 *                                                                            *
 * This software is provided 'as-is', without any express or implied          *
 * warranty. In no event will the authors be held liable for any damages      *
 * arising from the use of this software.                                     *
 *                                                                            *
 * Permission is granted to anyone to use this software for any purpose,      *
 * including commercial applications, and to alter it and redistribute it     *
 * freely, subject to the following restrictions:                             *
 *                                                                            *
 * 1. The origin of this software must not be misrepresented; you must not    *
 *    claim that you wrote the original software. If you use this software    *
 *    in a product, an acknowledgement in the product documentation would be  *
 *    appreciated but is not required.                                        *
 * 2. Altered source versions must be plainly marked as such, and must not be *
 *    misrepresented as being the original software.                          *
 * 3. This notice may not be removed or altered from any source distribution. *
 *                                                                            *
 ******************************************************************************
 *                  General guidelines for code contributors                  *
 *============================================================================*
 *                                                                            *
 * 1. Make sure you are legally allowed to make a contribution under the zlib *
 *    license.                                                                *
 * 2. The zlib license header goes at the top of each source file, with       *
 *    appropriate copyright notice.                                           *
 * 3. This PasVulkan wrapper may be used only with the PasVulkan-own Vulkan   *
 *    Pascal header.                                                          *
 * 4. After a pull request, check the status of your pull request on          *
      http://github.com/BeRo1985/pasvulkan                                    *
 * 5. Write code which's compatible with Delphi >= 2009 and FreePascal >=     *
 *    3.1.1                                                                   *
 * 6. Don't use Delphi-only, FreePascal-only or Lazarus-only libraries/units, *
 *    but if needed, make it out-ifdef-able.                                  *
 * 7. No use of third-party libraries/units as possible, but if needed, make  *
 *    it out-ifdef-able.                                                      *
 * 8. Try to use const when possible.                                         *
 * 9. Make sure to comment out writeln, used while debugging.                 *
 * 10. Make sure the code compiles on 32-bit and 64-bit platforms (x86-32,    *
 *     x86-64, ARM, ARM64, etc.).                                             *
 * 11. Make sure the code runs on all platforms with Vulkan support           *
 *                                                                            *
 ******************************************************************************)
unit PasVulkan.Scene3D.Renderer.Passes.GlobalIlluminationCascadedRadianceHintsInjectRSMComputePass;
{$i PasVulkan.inc}
{$ifndef fpc}
 {$ifdef conditionalexpressions}
  {$if CompilerVersion>=24.0}
   {$legacyifend on}
  {$ifend}
 {$endif}
{$endif}
{$m+}

interface

uses SysUtils,
     Classes,
     Math,
     Vulkan,
     PasVulkan.Types,
     PasVulkan.Math,
     PasVulkan.Framework,
     PasVulkan.Application,
     PasVulkan.FrameGraph,
     PasVulkan.Scene3D,
     PasVulkan.Scene3D.Renderer.Globals,
     PasVulkan.Scene3D.Renderer,
     PasVulkan.Scene3D.Renderer.Instance;

type { TpvScene3DRendererPassesGlobalIlluminationCascadedRadianceHintsInjectRSMComputePass }
     TpvScene3DRendererPassesGlobalIlluminationCascadedRadianceHintsInjectRSMComputePass=class(TpvFrameGraph.TComputePass)
      public
       type TUniformBufferData=record
             WorldToReflectiveShadowMapMatrix:TpvMatrix4x4;
             ReflectiveShadowMapToWorldMatrix:TpvMatrix4x4;
             ModelViewProjectionMatrix:TpvMatrix4x4;
             LightDirection:TpvVector4;
             LightPosition:TpvVector4;
             LightColor:TpvVector4;
             MaximumSamplingDistance:TpvFloat;
             Spread:TpvFloat;
            end;
            PUniformBufferData=^TUniformBufferData;
      private
       fInstance:TpvScene3DRendererInstance;
       fResourceRSMColor:TpvFrameGraph.TPass.TUsedImageResource;
       fResourceRSMNormalUsed:TpvFrameGraph.TPass.TUsedImageResource;
       fResourceRSMDepth:TpvFrameGraph.TPass.TUsedImageResource;
       fComputeShaderModule:TpvVulkanShaderModule;
       fVulkanPipelineShaderStageCompute:TpvVulkanPipelineShaderStage;
       fVulkanDescriptorSetLayout:TpvVulkanDescriptorSetLayout;
       fVulkanDescriptorPool:TpvVulkanDescriptorPool;
       fVulkanDescriptorSets:array[0..MaxInFlightFrames-1] of TpvVulkanDescriptorSet;
       fPipelineLayout:TpvVulkanPipelineLayout;
       fPipeline:TpvVulkanComputePipeline;
       fVulkanSampler:TpvVulkanSampler;
       fVulkanImageViews:array[0..MaxInFlightFrames-1] of TpvVulkanImageView;
       fVulkanUniformBuffers:array[0..MaxInFlightFrames-1] of TpvVulkanBuffer;
       //fFirst:Boolean;
      public
       constructor Create(const aFrameGraph:TpvFrameGraph;const aInstance:TpvScene3DRendererInstance); reintroduce;
       destructor Destroy; override;
       procedure AcquirePersistentResources; override;
       procedure ReleasePersistentResources; override;
       procedure AcquireVolatileResources; override;
       procedure ReleaseVolatileResources; override;
       procedure Update(const aUpdateInFlightFrameIndex,aUpdateFrameIndex:TpvSizeInt); override;
       procedure Execute(const aCommandBuffer:TpvVulkanCommandBuffer;const aInFlightFrameIndex,aFrameIndex:TpvSizeInt); override;
      published
     end;

implementation

{ TpvScene3DRendererPassesGlobalIlluminationCascadedRadianceHintsInjectRSMComputePass }

constructor TpvScene3DRendererPassesGlobalIlluminationCascadedRadianceHintsInjectRSMComputePass.Create(const aFrameGraph:TpvFrameGraph;const aInstance:TpvScene3DRendererInstance);
begin
 inherited Create(aFrameGraph);

 fInstance:=aInstance;

 Name:='GlobalIlluminationCascadedRadianceHintsInjectRSMComputePass';

 //fFirst:=true;

 fResourceRSMColor:=AddImageInput('resourcetype_reflectiveshadowmap_color',
                                  'resource_reflectiveshadowmap_color',
                                  VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                                  []
                                 );

 fResourceRSMNormalUsed:=AddImageInput('resourcetype_reflectiveshadowmap_normalused',
                                       'resource_reflectiveshadowmap_normalused',
                                       VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                                       []
                                      );

 fResourceRSMDepth:=AddImageInput('resourcetype_reflectiveshadowmap_depth',
                                  'resource_reflectiveshadowmap_depth',
                                  VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                                  []
                                 );

end;

destructor TpvScene3DRendererPassesGlobalIlluminationCascadedRadianceHintsInjectRSMComputePass.Destroy;
begin
 inherited Destroy;
end;

procedure TpvScene3DRendererPassesGlobalIlluminationCascadedRadianceHintsInjectRSMComputePass.AcquirePersistentResources;
var Stream:TStream;
    Format:string;
begin

 inherited AcquirePersistentResources;

 Stream:=pvScene3DShaderVirtualFileSystem.GetFile('gi_cascaded_radiance_hints_inject_rsm_comp.spv');
 try
  fComputeShaderModule:=TpvVulkanShaderModule.Create(fInstance.Renderer.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 fVulkanPipelineShaderStageCompute:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_COMPUTE_BIT,fComputeShaderModule,'main');

end;

procedure TpvScene3DRendererPassesGlobalIlluminationCascadedRadianceHintsInjectRSMComputePass.ReleasePersistentResources;
begin
 FreeAndNil(fVulkanPipelineShaderStageCompute);
 FreeAndNil(fComputeShaderModule);
 inherited ReleasePersistentResources;
end;

procedure TpvScene3DRendererPassesGlobalIlluminationCascadedRadianceHintsInjectRSMComputePass.AcquireVolatileResources;
var InFlightFrameIndex,PreviousInFlightFrameIndex,Index,CascadeIndex,SHTextureIndex:TpvInt32;
    ImageSHDescriptorImageInfoArray:TVkDescriptorImageInfoArray;
    ImageMetaInfoDescriptorImageInfoArray:TVkDescriptorImageInfoArray;
begin

 inherited AcquireVolatileResources;

 fVulkanSampler:=TpvVulkanSampler.Create(fInstance.Renderer.VulkanDevice,
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

 fVulkanDescriptorPool:=TpvVulkanDescriptorPool.Create(fInstance.Renderer.VulkanDevice,
                                                       TVkDescriptorPoolCreateFlags(VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT),
                                                       fInstance.Renderer.CountInFlightFrames);
 fVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,fInstance.Renderer.CountInFlightFrames*2);
 fVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,fInstance.Renderer.CountInFlightFrames*TpvScene3DRendererInstance.CountGlobalIlluminationRadiantHintCascades*TpvScene3DRendererInstance.CountGlobalIlluminationRadiantHintVolumeImages);
 fVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,fInstance.Renderer.CountInFlightFrames*4);
 fVulkanDescriptorPool.Initialize;

 fVulkanDescriptorSetLayout:=TpvVulkanDescriptorSetLayout.Create(fInstance.Renderer.VulkanDevice);
 fVulkanDescriptorSetLayout.AddBinding(0,
                                       VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                                       1,
                                       TVkShaderStageFlags(VK_SHADER_STAGE_COMPUTE_BIT),
                                       []);
 fVulkanDescriptorSetLayout.AddBinding(1,
                                       VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                                       4,
                                       TVkShaderStageFlags(VK_SHADER_STAGE_COMPUTE_BIT),
                                       []);
 fVulkanDescriptorSetLayout.AddBinding(2,
                                       VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
                                       TpvScene3DRendererInstance.CountGlobalIlluminationRadiantHintCascades*TpvScene3DRendererInstance.CountGlobalIlluminationRadiantHintSHImages,
                                       TVkShaderStageFlags(VK_SHADER_STAGE_COMPUTE_BIT),
                                       []);
 fVulkanDescriptorSetLayout.AddBinding(3,
                                       VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
                                       TpvScene3DRendererInstance.CountGlobalIlluminationRadiantHintCascades,
                                       TVkShaderStageFlags(VK_SHADER_STAGE_COMPUTE_BIT),
                                       []);
 fVulkanDescriptorSetLayout.AddBinding(4,
                                       VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
                                       1,
                                       TVkShaderStageFlags(VK_SHADER_STAGE_COMPUTE_BIT),
                                       []);
 fVulkanDescriptorSetLayout.Initialize;

 fPipelineLayout:=TpvVulkanPipelineLayout.Create(fInstance.Renderer.VulkanDevice);
{fPipelineLayout.AddPushConstantRange(TVkShaderStageFlags(VK_SHADER_STAGE_COMPUTE_BIT),
                                      0,
                                      SizeOf(TpvScene3DRendererPassesGlobalIlluminationCascadedRadianceHintsInjectRSMComputePass.TPushConstants));//}
 fPipelineLayout.AddDescriptorSetLayout(fVulkanDescriptorSetLayout);
 fPipelineLayout.Initialize;

 fPipeline:=TpvVulkanComputePipeline.Create(fInstance.Renderer.VulkanDevice,
                                            fInstance.Renderer.VulkanPipelineCache,
                                            0,
                                            fVulkanPipelineShaderStageCompute,
                                            fPipelineLayout,
                                            nil,
                                            0);

 ImageSHDescriptorImageInfoArray:=nil;
 ImageMetaInfoDescriptorImageInfoArray:=nil;

 try

  for InFlightFrameIndex:=0 to FrameGraph.CountInFlightFrames-1 do begin

   if InFlightFrameIndex=0 then begin
    PreviousInFlightFrameIndex:=FrameGraph.CountInFlightFrames-1;
   end else begin
    PreviousInFlightFrameIndex:=InFlightFrameIndex-1;
   end;

   fVulkanImageViews[InFlightFrameIndex]:=TpvVulkanImageView.Create(fInstance.Renderer.VulkanDevice,
                                                                    fInstance.DepthMipmappedArray2DImages[InFlightFrameIndex].VulkanImage,
                                                                    TVkImageViewType(VK_IMAGE_VIEW_TYPE_2D),
                                                                    fInstance.DepthMipmappedArray2DImages[InFlightFrameIndex].Format,
                                                                    VK_COMPONENT_SWIZZLE_IDENTITY,
                                                                    VK_COMPONENT_SWIZZLE_IDENTITY,
                                                                    VK_COMPONENT_SWIZZLE_IDENTITY,
                                                                    VK_COMPONENT_SWIZZLE_IDENTITY,
                                                                    TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT),
                                                                    0,
                                                                    1,
                                                                    0,
                                                                    1
                                                                   );

   fVulkanUniformBuffers[InFlightFrameIndex]:=TpvVulkanBuffer.Create(fInstance.Renderer.VulkanDevice,
                                                                     SizeOf(TpvScene3DRendererPassesGlobalIlluminationCascadedRadianceHintsInjectRSMComputePass.TUniformBufferData),
                                                                     TVkBufferUsageFlags(VK_BUFFER_USAGE_TRANSFER_DST_BIT) or TVkBufferUsageFlags(VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT),
                                                                     TVkSharingMode(VK_SHARING_MODE_EXCLUSIVE),
                                                                     [],
                                                                     TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT),
                                                                     TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT) or TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT),
                                                                     0,
                                                                     0,
                                                                     0,
                                                                     0,
                                                                     0,
                                                                     0,
                                                                     [TpvVulkanBufferFlag.PersistentMapped]);

   SetLength(ImageSHDescriptorImageInfoArray,TpvScene3DRendererInstance.CountGlobalIlluminationRadiantHintCascades*TpvScene3DRendererInstance.CountGlobalIlluminationRadiantHintSHImages);
   SetLength(ImageMetaInfoDescriptorImageInfoArray,TpvScene3DRendererInstance.CountGlobalIlluminationRadiantHintCascades);

   Index:=0;
   for CascadeIndex:=0 to TpvScene3DRendererInstance.CountGlobalIlluminationRadiantHintCascades-1 do begin
    for SHTextureIndex:=0 to TpvScene3DRendererInstance.CountGlobalIlluminationRadiantHintSHImages-1 do begin
     ImageSHDescriptorImageInfoArray[Index]:=TVkDescriptorImageInfo.Create(VK_NULL_HANDLE,
                                                                           fInstance.InFlightFrameCascadedRadianceHintVolumeImages[InFlightFrameIndex,CascadeIndex,SHTextureIndex].DescriptorImageInfo.imageView,
                                                                           VK_IMAGE_LAYOUT_GENERAL);
     inc(Index);
    end;
    ImageMetaInfoDescriptorImageInfoArray[CascadeIndex]:=TVkDescriptorImageInfo.Create(VK_NULL_HANDLE,
                                                                                       fInstance.InFlightFrameCascadedRadianceHintVolumeImages[InFlightFrameIndex,CascadeIndex,TpvScene3DRendererInstance.CountGlobalIlluminationRadiantHintSHImages].DescriptorImageInfo.imageView,
                                                                                       VK_IMAGE_LAYOUT_GENERAL);
   end;

   fVulkanDescriptorSets[InFlightFrameIndex]:=TpvVulkanDescriptorSet.Create(fVulkanDescriptorPool,
                                                                            fVulkanDescriptorSetLayout);
   fVulkanDescriptorSets[InFlightFrameIndex].WriteToDescriptorSet(0,
                                                                  0,
                                                                  1,
                                                                  TVkDescriptorType(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER),
                                                                  [],
                                                                  [fInstance.GlobalIlluminationRadianceHintsUniformBuffers[InFlightFrameIndex].DescriptorBufferInfo],
                                                                  [],
                                                                  false
                                                                 );
   fVulkanDescriptorSets[InFlightFrameIndex].WriteToDescriptorSet(1,
                                                                  0,
                                                                  4,
                                                                  TVkDescriptorType(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER),
                                                                  [TVkDescriptorImageInfo.Create(fVulkanSampler.Handle,
                                                                                                 fResourceRSMColor.VulkanImageViews[InFlightFrameIndex].Handle,
                                                                                                 fResourceRSMColor.ResourceTransition.Layout),
                                                                   TVkDescriptorImageInfo.Create(fVulkanSampler.Handle,
                                                                                                 fResourceRSMNormalUsed.VulkanImageViews[InFlightFrameIndex].Handle,
                                                                                                 fResourceRSMNormalUsed.ResourceTransition.Layout),
                                                                   TVkDescriptorImageInfo.Create(fVulkanSampler.Handle,
                                                                                                 fResourceRSMDepth.VulkanImageViews[InFlightFrameIndex].Handle,
                                                                                                 fResourceRSMDepth.ResourceTransition.Layout),
                                                                   TVkDescriptorImageInfo.Create(fVulkanSampler.Handle,
                                                                                                 fVulkanImageViews[InFlightFrameIndex].Handle,
                                                                                                 VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL)],
                                                                  [],
                                                                  [],
                                                                  false
                                                                 );
   fVulkanDescriptorSets[InFlightFrameIndex].WriteToDescriptorSet(2,
                                                                  0,
                                                                  length(ImageSHDescriptorImageInfoArray),
                                                                  TVkDescriptorType(VK_DESCRIPTOR_TYPE_STORAGE_IMAGE),
                                                                  ImageSHDescriptorImageInfoArray,
                                                                  [],
                                                                  [],
                                                                  false
                                                                 );
   fVulkanDescriptorSets[InFlightFrameIndex].WriteToDescriptorSet(3,
                                                                  0,
                                                                  length(ImageMetaInfoDescriptorImageInfoArray),
                                                                  TVkDescriptorType(VK_DESCRIPTOR_TYPE_STORAGE_IMAGE),
                                                                  ImageMetaInfoDescriptorImageInfoArray,
                                                                  [],
                                                                  [],
                                                                  false
                                                                 );
   fVulkanDescriptorSets[InFlightFrameIndex].WriteToDescriptorSet(4,
                                                                  0,
                                                                  1,
                                                                  TVkDescriptorType(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER),
                                                                  [],
                                                                  [fVulkanUniformBuffers[InFlightFrameIndex].DescriptorBufferInfo],
                                                                  [],
                                                                  false
                                                                 );
   fVulkanDescriptorSets[InFlightFrameIndex].Flush;

   ImageSHDescriptorImageInfoArray:=nil;
// ImageMetaInfoDescriptorImageInfoArray:=nil;

  end;

 finally
  ImageSHDescriptorImageInfoArray:=nil;
//ImageMetaInfoDescriptorImageInfoArray:=nil;
 end;

end;

procedure TpvScene3DRendererPassesGlobalIlluminationCascadedRadianceHintsInjectRSMComputePass.ReleaseVolatileResources;
var InFlightFrameIndex:TpvInt32;
begin
 FreeAndNil(fPipeline);
 FreeAndNil(fPipelineLayout);
 for InFlightFrameIndex:=0 to FrameGraph.CountInFlightFrames-1 do begin
  FreeAndNil(fVulkanDescriptorSets[InFlightFrameIndex]);
  FreeAndNil(fVulkanImageViews[InFlightFrameIndex]);
  FreeAndNil(fVulkanUniformBuffers[InFlightFrameIndex]);
 end;
 FreeAndNil(fVulkanDescriptorSetLayout);
 FreeAndNil(fVulkanDescriptorPool);
 FreeAndNil(fVulkanSampler);
 inherited ReleaseVolatileResources;
end;

procedure TpvScene3DRendererPassesGlobalIlluminationCascadedRadianceHintsInjectRSMComputePass.Update(const aUpdateInFlightFrameIndex,aUpdateFrameIndex:TpvSizeInt);
begin
 inherited Update(aUpdateInFlightFrameIndex,aUpdateFrameIndex);
end;

procedure TpvScene3DRendererPassesGlobalIlluminationCascadedRadianceHintsInjectRSMComputePass.Execute(const aCommandBuffer:TpvVulkanCommandBuffer;const aInFlightFrameIndex,aFrameIndex:TpvSizeInt);
var InFlightFrameIndex,Index,CascadeIndex,VolumeIndex:TpvInt32;
    ImageMemoryBarriers:array[0..(TpvScene3DRendererInstance.CountGlobalIlluminationRadiantHintCascades*TpvScene3DRendererInstance.CountGlobalIlluminationRadiantHintSHImages)-1] of TVkImageMemoryBarrier;
//  PushConstants:TpvScene3DRendererPassesGlobalIlluminationCascadedRadianceHintsInjectRSMComputePass.TPushConstants;
    UniformBufferData:TpvScene3DRendererPassesGlobalIlluminationCascadedRadianceHintsInjectRSMComputePass.TUniformBufferData;
    InFlightFrameState:TpvScene3DRendererInstance.PInFlightFrameState;
begin

 inherited Execute(aCommandBuffer,aInFlightFrameIndex,aFrameIndex);

 InFlightFrameIndex:=aInFlightFrameIndex;

 InFlightFrameState:=@fInstance.InFlightFrameStates^[InFlightFrameIndex];

 UniformBufferData.ReflectiveShadowMapToWorldMatrix:=InFlightFrameState^.ReflectiveShadowMapMatrix.Inverse;
 UniformBufferData.WorldToReflectiveShadowMapMatrix:=InFlightFrameState^.ReflectiveShadowMapMatrix;
 UniformBufferData.ModelViewProjectionMatrix:=InFlightFrameState^.MainViewProjectionMatrix;
 UniformBufferData.LightDirection:=TpvVector4.InlineableCreate(InFlightFrameState^.ReflectiveShadowMapLightDirection,0.0);
 UniformBufferData.LightPosition:=(-UniformBufferData.LightDirection)*65536.0;
 UniformBufferData.LightColor:=TpvVector4.InlineableCreate(1.0,1.0,1.0,1.0);
 UniformBufferData.MaximumSamplingDistance:=512.0;
 UniformBufferData.Spread:=5.0;
 //fVulkanUniformBuffers[InFlightFrameIndex]

 aCommandBuffer.CmdUpdateBuffer(fVulkanUniformBuffers[InFlightFrameIndex].Handle,
                                0,
                                SizeOf(TpvScene3DRendererPassesGlobalIlluminationCascadedRadianceHintsInjectRSMComputePass.TUniformBufferData),
                                @UniformBufferData);

 aCommandBuffer.CmdBindPipeline(VK_PIPELINE_BIND_POINT_COMPUTE,fPipeline.Handle);

 aCommandBuffer.CmdBindDescriptorSets(VK_PIPELINE_BIND_POINT_COMPUTE,
                                      fPipelineLayout.Handle,
                                      0,
                                      1,
                                      @fVulkanDescriptorSets[InFlightFrameIndex].Handle,
                                      0,
                                      nil);

{PushConstants.TopDownRSMOcclusionMapViewProjectionMatrix:=fInstance.InFlightFrameStates^[InFlightFrameIndex].TopDownRSMOcclusionMapViewProjectionMatrix;

 aCommandBuffer.CmdPushConstants(fPipelineLayout.Handle,
                                 TVkShaderStageFlags(VK_SHADER_STAGE_COMPUTE_BIT),
                                 0,
                                 SizeOf(TpvScene3DRendererPassesGlobalIlluminationCascadedRadianceHintsInjectRSMComputePass.TPushConstants),
                                 @PushConstants);//}

 aCommandBuffer.CmdDispatch((TpvScene3DRendererInstance.GlobalIlluminationRadiantHintVolumeSize+7) shr 3,
                            (TpvScene3DRendererInstance.GlobalIlluminationRadiantHintVolumeSize+7) shr 3,
                            ((TpvScene3DRendererInstance.GlobalIlluminationRadiantHintVolumeSize*TpvScene3DRendererInstance.CountGlobalIlluminationRadiantHintCascades)+7) shr 3);

 Index:=0;
 for CascadeIndex:=0 to TpvScene3DRendererInstance.CountGlobalIlluminationRadiantHintCascades-1 do begin
  for VolumeIndex:=0 to TpvScene3DRendererInstance.CountGlobalIlluminationRadiantHintSHImages-1 do begin
   ImageMemoryBarriers[Index]:=TVkImageMemoryBarrier.Create(TVkAccessFlags(VK_ACCESS_SHADER_WRITE_BIT),
                                                            TVkAccessFlags(VK_ACCESS_SHADER_READ_BIT) or TVkAccessFlags(VK_ACCESS_SHADER_WRITE_BIT),
                                                            VK_IMAGE_LAYOUT_GENERAL,
                                                            VK_IMAGE_LAYOUT_GENERAL,
                                                            VK_QUEUE_FAMILY_IGNORED,
                                                            VK_QUEUE_FAMILY_IGNORED,
                                                            fInstance.InFlightFrameCascadedRadianceHintVolumeImages[InFlightFrameIndex,CascadeIndex,VolumeIndex].VulkanImage.Handle,
                                                            TVkImageSubresourceRange.Create(TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT),
                                                                                            0,
                                                                                            1,
                                                                                            0,
                                                                                            1));
   inc(Index);
  end;
 end;
 aCommandBuffer.CmdPipelineBarrier(TVkPipelineStageFlags(VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT),
                                   FrameGraph.VulkanDevice.PhysicalDevice.PipelineStageAllShaderBits,
                                   0,
                                   0,nil,
                                   0,nil,
                                   length(ImageMemoryBarriers),@ImageMemoryBarriers[0]);

end;

end.
