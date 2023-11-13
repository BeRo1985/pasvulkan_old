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
unit PasVulkan.Scene3D.Renderer.Passes.CullDepthPyramidComputePass;
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

type { TpvScene3DRendererPassesCullDepthPyramidComputePass }
     TpvScene3DRendererPassesCullDepthPyramidComputePass=class(TpvFrameGraph.TComputePass)
      private
       fInstance:TpvScene3DRendererInstance;
       fResourceInput:TpvFrameGraph.TPass.TUsedImageResource;
       fDownsampleLevel0ComputeShaderModule:TpvVulkanShaderModule;
       fDownsampleLevel1ComputeShaderModule:TpvVulkanShaderModule;
       fVulkanImageViews:array[0..MaxInFlightFrames-1] of TpvVulkanImageView;
       fVulkanPipelineShaderStageDownsampleLevel0Compute:TpvVulkanPipelineShaderStage;
       fVulkanPipelineShaderStageDownsampleLevel1Compute:TpvVulkanPipelineShaderStage;
       fVulkanDescriptorSetLayout:TpvVulkanDescriptorSetLayout;
       fVulkanDescriptorPool:TpvVulkanDescriptorPool;
       fVulkanDescriptorSets:array[0..MaxInFlightFrames-1,0..15] of TpvVulkanDescriptorSet;
       fPipelineLayout:TpvVulkanPipelineLayout;
       fPipelineLevel0:TpvVulkanComputePipeline;
       fPipelineLevel1:TpvVulkanComputePipeline;
      public
       constructor Create(const aFrameGraph:TpvFrameGraph;const aInstance:TpvScene3DRendererInstance); reintroduce;
       destructor Destroy; override;
       procedure AcquirePersistentResources; override;
       procedure ReleasePersistentResources; override;
       procedure AcquireVolatileResources; override;
       procedure ReleaseVolatileResources; override;
       procedure Update(const aUpdateInFlightFrameIndex,aUpdateFrameIndex:TpvSizeInt); override;
       procedure Execute(const aCommandBuffer:TpvVulkanCommandBuffer;const aInFlightFrameIndex,aFrameIndex:TpvSizeInt); override;
     end;

implementation

{ TpvScene3DRendererPassesCullDepthPyramidComputePass  }

constructor TpvScene3DRendererPassesCullDepthPyramidComputePass.Create(const aFrameGraph:TpvFrameGraph;const aInstance:TpvScene3DRendererInstance);
begin
 inherited Create(aFrameGraph);

 fInstance:=aInstance;

 Name:='CullDepthPyramidComputePass';

 if fInstance.Renderer.SurfaceSampleCountFlagBits=TVkSampleCountFlagBits(VK_SAMPLE_COUNT_1_BIT) then begin

  fResourceInput:=AddImageInput('resourcetype_depth',
                                'resource_cull_depth_data',
                                VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                                [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                               );

 end else begin

  fResourceInput:=nil;
                 {AddImageInput('resourcetype_msaa_depth',
                                'resource_msaa_cull_depth_data',
                                VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                                [TpvFrameGraph.TResourceTransition.TFlag.Attachment]
                               );}

 end;

end;

destructor TpvScene3DRendererPassesCullDepthPyramidComputePass.Destroy;
begin
 inherited Destroy;
end;

procedure TpvScene3DRendererPassesCullDepthPyramidComputePass.AcquirePersistentResources;
var Stream:TStream;
begin

 inherited AcquirePersistentResources;

 if fInstance.ZFar<0.0 then begin
  if fInstance.CountSurfaceViews>1 then begin
   Stream:=pvScene3DShaderVirtualFileSystem.GetFile('downsample_culldepthpyramid_multiview_reversedz_level0_comp.spv');
  end else begin
   Stream:=pvScene3DShaderVirtualFileSystem.GetFile('downsample_culldepthpyramid_reversedz_level0_comp.spv');
  end;
 end else begin
  if fInstance.CountSurfaceViews>1 then begin
   Stream:=pvScene3DShaderVirtualFileSystem.GetFile('downsample_culldepthpyramid_multiview_level0_comp.spv');
  end else begin
   Stream:=pvScene3DShaderVirtualFileSystem.GetFile('downsample_culldepthpyramid_level0_comp.spv');
  end;
 end;
 try
  fDownsampleLevel0ComputeShaderModule:=TpvVulkanShaderModule.Create(fInstance.Renderer.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 if fInstance.ZFar<0.0 then begin
  if fInstance.CountSurfaceViews>1 then begin
   Stream:=pvScene3DShaderVirtualFileSystem.GetFile('downsample_culldepthpyramid_multiview_reversedz_level1_comp.spv');
  end else begin
   Stream:=pvScene3DShaderVirtualFileSystem.GetFile('downsample_culldepthpyramid_reversedz_level1_comp.spv');
  end;
 end else begin
  if fInstance.CountSurfaceViews>1 then begin
   Stream:=pvScene3DShaderVirtualFileSystem.GetFile('downsample_multiview_level1_comp.spv');
  end else begin
   Stream:=pvScene3DShaderVirtualFileSystem.GetFile('downsample_level1_comp.spv');
  end;
 end;
 try
  fDownsampleLevel1ComputeShaderModule:=TpvVulkanShaderModule.Create(fInstance.Renderer.VulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 fVulkanPipelineShaderStageDownsampleLevel0Compute:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_COMPUTE_BIT,fDownsampleLevel0ComputeShaderModule,'main');

 fVulkanPipelineShaderStageDownsampleLevel1Compute:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_COMPUTE_BIT,fDownsampleLevel1ComputeShaderModule,'main');

end;

procedure TpvScene3DRendererPassesCullDepthPyramidComputePass.ReleasePersistentResources;
begin
 FreeAndNil(fVulkanPipelineShaderStageDownsampleLevel1Compute);
 FreeAndNil(fVulkanPipelineShaderStageDownsampleLevel0Compute);
 FreeAndNil(fDownsampleLevel1ComputeShaderModule);
 FreeAndNil(fDownsampleLevel0ComputeShaderModule);
 inherited ReleasePersistentResources;
end;

procedure TpvScene3DRendererPassesCullDepthPyramidComputePass.AcquireVolatileResources;
var InFlightFrameIndex,MipMapLevelIndex:TpvInt32;
    ImageViewType:TVkImageViewType;
begin

 inherited AcquireVolatileResources;

 fVulkanDescriptorPool:=TpvVulkanDescriptorPool.Create(fInstance.Renderer.VulkanDevice,
                                                       TVkDescriptorPoolCreateFlags(VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT),
                                                       fInstance.Renderer.CountInFlightFrames*fInstance.CullDepthPyramidMipMappedArray2DImages[0].MipMapLevels);
 fVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,fInstance.Renderer.CountInFlightFrames*fInstance.CullDepthPyramidMipMappedArray2DImages[0].MipMapLevels);
 fVulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,fInstance.Renderer.CountInFlightFrames*fInstance.CullDepthPyramidMipMappedArray2DImages[0].MipMapLevels);
 fVulkanDescriptorPool.Initialize;

 fVulkanDescriptorSetLayout:=TpvVulkanDescriptorSetLayout.Create(fInstance.Renderer.VulkanDevice);
 fVulkanDescriptorSetLayout.AddBinding(0,
                                       VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                                       1,
                                       TVkShaderStageFlags(VK_SHADER_STAGE_COMPUTE_BIT),
                                       []);
 fVulkanDescriptorSetLayout.AddBinding(1,
                                       VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
                                       1,
                                       TVkShaderStageFlags(VK_SHADER_STAGE_COMPUTE_BIT),
                                       []);
 fVulkanDescriptorSetLayout.Initialize;

 fPipelineLayout:=TpvVulkanPipelineLayout.Create(fInstance.Renderer.VulkanDevice);
 fPipelineLayout.AddDescriptorSetLayout(fVulkanDescriptorSetLayout);
 fPipelineLayout.Initialize;

 fPipelineLevel0:=TpvVulkanComputePipeline.Create(fInstance.Renderer.VulkanDevice,
                                                  fInstance.Renderer.VulkanPipelineCache,
                                                  0,
                                                  fVulkanPipelineShaderStageDownsampleLevel0Compute,
                                                  fPipelineLayout,
                                                  nil,
                                                  0);

 fPipelineLevel1:=TpvVulkanComputePipeline.Create(fInstance.Renderer.VulkanDevice,
                                                  fInstance.Renderer.VulkanPipelineCache,
                                                  0,
                                                  fVulkanPipelineShaderStageDownsampleLevel1Compute,
                                                  fPipelineLayout,
                                                  nil,
                                                  0);

 if fInstance.CountSurfaceViews>1 then begin
  ImageViewType:=TVkImageViewType(VK_IMAGE_VIEW_TYPE_2D_ARRAY);
 end else begin
  ImageViewType:=TVkImageViewType(VK_IMAGE_VIEW_TYPE_2D);
 end;

 for InFlightFrameIndex:=0 to FrameGraph.CountInFlightFrames-1 do begin
  if assigned(fResourceInput) then begin
   fVulkanImageViews[InFlightFrameIndex]:=TpvVulkanImageView.Create(fInstance.Renderer.VulkanDevice,
                                                                    fResourceInput.VulkanImages[InFlightFrameIndex],
                                                                    ImageViewType,
                                                                    TpvFrameGraph.TImageResourceType(fResourceInput.ResourceType).Format,
                                                                    VK_COMPONENT_SWIZZLE_IDENTITY,
                                                                    VK_COMPONENT_SWIZZLE_IDENTITY,
                                                                    VK_COMPONENT_SWIZZLE_IDENTITY,
                                                                    VK_COMPONENT_SWIZZLE_IDENTITY,
                                                                    TVkImageAspectFlags(VK_IMAGE_ASPECT_DEPTH_BIT),
                                                                    0,
                                                                    1,
                                                                    0,
                                                                    fInstance.CountSurfaceViews
                                                                   );
  end else begin
   fVulkanImageViews[InFlightFrameIndex]:=TpvVulkanImageView.Create(fInstance.Renderer.VulkanDevice,
                                                                    fInstance.CullDepthArray2DImages[InFlightFrameIndex].VulkanImage,
                                                                    ImageViewType,
                                                                    fInstance.CullDepthArray2DImages[InFlightFrameIndex].Format,
                                                                    VK_COMPONENT_SWIZZLE_IDENTITY,
                                                                    VK_COMPONENT_SWIZZLE_IDENTITY,
                                                                    VK_COMPONENT_SWIZZLE_IDENTITY,
                                                                    VK_COMPONENT_SWIZZLE_IDENTITY,
                                                                    TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT),
                                                                    0,
                                                                    1,
                                                                    0,
                                                                    fInstance.CountSurfaceViews
                                                                   );
  end;
  for MipMapLevelIndex:=0 to fInstance.CullDepthPyramidMipMappedArray2DImages[InFlightFrameIndex].MipMapLevels-1 do begin
   fVulkanDescriptorSets[InFlightFrameIndex,MipMapLevelIndex]:=TpvVulkanDescriptorSet.Create(fVulkanDescriptorPool,
                                                                                             fVulkanDescriptorSetLayout);
   if MipMapLevelIndex=0 then begin
    if assigned(fResourceInput) then begin
     fVulkanDescriptorSets[InFlightFrameIndex,MipMapLevelIndex].WriteToDescriptorSet(0,
                                                                                     0,
                                                                                     1,
                                                                                     TVkDescriptorType(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER),
                                                                                     [TVkDescriptorImageInfo.Create(fInstance.Renderer.ClampedNearestSampler.Handle,
                                                                                                                    fVulkanImageViews[InFlightFrameIndex].Handle,
                                                                                                                    fResourceInput.ResourceTransition.Layout)],
                                                                                     [],
                                                                                     [],
                                                                                     false
                                                                                    );
    end else begin
     fVulkanDescriptorSets[InFlightFrameIndex,MipMapLevelIndex].WriteToDescriptorSet(0,
                                                                                     0,
                                                                                     1,
                                                                                     TVkDescriptorType(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER),
                                                                                     [TVkDescriptorImageInfo.Create(fInstance.Renderer.ClampedNearestSampler.Handle,
                                                                                                                    fVulkanImageViews[InFlightFrameIndex].Handle,
                                                                                                                    VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL)],
                                                                                     [],
                                                                                     [],
                                                                                     false
                                                                                    );
    end;
   end else begin
    fVulkanDescriptorSets[InFlightFrameIndex,MipMapLevelIndex].WriteToDescriptorSet(0,
                                                                                    0,
                                                                                    1,
                                                                                    TVkDescriptorType(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER),
                                                                                    [TVkDescriptorImageInfo.Create(fInstance.Renderer.ClampedNearestSampler.Handle,
                                                                                                                   fInstance.CullDepthPyramidMipMappedArray2DImages[InFlightFrameIndex].VulkanImageViews[MipMapLevelIndex-1].Handle,
                                                                                                                   VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL)],
                                                                                    [],
                                                                                    [],
                                                                                    false
                                                                                   );
   end;
   fVulkanDescriptorSets[InFlightFrameIndex,MipMapLevelIndex].WriteToDescriptorSet(1,
                                                                                   0,
                                                                                   1,
                                                                                   TVkDescriptorType(VK_DESCRIPTOR_TYPE_STORAGE_IMAGE),
                                                                                   [TVkDescriptorImageInfo.Create(fInstance.Renderer.ClampedNearestSampler.Handle,
                                                                                                                  fInstance.CullDepthPyramidMipMappedArray2DImages[InFlightFrameIndex].VulkanImageViews[MipMapLevelIndex].Handle,
                                                                                                                  VK_IMAGE_LAYOUT_GENERAL)],
                                                                                   [],
                                                                                   [],
                                                                                   false
                                                                                  );
   fVulkanDescriptorSets[InFlightFrameIndex,MipMapLevelIndex].Flush;
  end;
 end;

end;

procedure TpvScene3DRendererPassesCullDepthPyramidComputePass.ReleaseVolatileResources;
var InFlightFrameIndex,MipMapLevelIndex:TpvInt32;
begin
 FreeAndNil(fPipelineLevel1);
 FreeAndNil(fPipelineLevel0);
 FreeAndNil(fPipelineLayout);
 for InFlightFrameIndex:=0 to fInstance.Renderer.CountInFlightFrames-1 do begin
  for MipMapLevelIndex:=0 to fInstance.CullDepthPyramidMipMappedArray2DImages[InFlightFrameIndex].MipMapLevels-1 do begin
   FreeAndNil(fVulkanDescriptorSets[InFlightFrameIndex,MipMapLevelIndex]);
  end;
  FreeAndNil(fVulkanImageViews[InFlightFrameIndex]);
 end;
 FreeAndNil(fVulkanDescriptorSetLayout);
 FreeAndNil(fVulkanDescriptorPool);
 inherited ReleaseVolatileResources;
end;

procedure TpvScene3DRendererPassesCullDepthPyramidComputePass.Update(const aUpdateInFlightFrameIndex,aUpdateFrameIndex:TpvSizeInt);
begin
 inherited Update(aUpdateInFlightFrameIndex,aUpdateFrameIndex);
end;

procedure TpvScene3DRendererPassesCullDepthPyramidComputePass.Execute(const aCommandBuffer:TpvVulkanCommandBuffer;const aInFlightFrameIndex,aFrameIndex:TpvSizeInt);
var InFlightFrameIndex,MipMapLevelIndex:TpvInt32;
    Pipeline:TpvVulkanComputePipeline;
    ImageMemoryBarrier:TVkImageMemoryBarrier;
begin

 inherited Execute(aCommandBuffer,aInFlightFrameIndex,aFrameIndex);

 InFlightFrameIndex:=aInFlightFrameIndex;

 FillChar(ImageMemoryBarrier,SizeOf(TVkImageMemoryBarrier),#0);
 ImageMemoryBarrier.sType:=VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
 ImageMemoryBarrier.pNext:=nil;
 ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_SHADER_READ_BIT);
 ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_SHADER_WRITE_BIT);
 ImageMemoryBarrier.oldLayout:=VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
 ImageMemoryBarrier.newLayout:=VK_IMAGE_LAYOUT_GENERAL;
 ImageMemoryBarrier.srcQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
 ImageMemoryBarrier.dstQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
 ImageMemoryBarrier.image:=fInstance.CullDepthPyramidMipMappedArray2DImages[InFlightFrameIndex].VulkanImage.Handle;
 ImageMemoryBarrier.subresourceRange.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
 ImageMemoryBarrier.subresourceRange.baseMipLevel:=0;
 ImageMemoryBarrier.subresourceRange.levelCount:=fInstance.CullDepthPyramidMipMappedArray2DImages[InFlightFrameIndex].MipMapLevels;
 ImageMemoryBarrier.subresourceRange.baseArrayLayer:=0;
 ImageMemoryBarrier.subresourceRange.layerCount:=fInstance.CountSurfaceViews;
 aCommandBuffer.CmdPipelineBarrier(FrameGraph.VulkanDevice.PhysicalDevice.PipelineStageAllShaderBits or  TVkPipelineStageFlags(VK_PIPELINE_STAGE_TRANSFER_BIT),
                                   TVkPipelineStageFlags(VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT),
                                   0,
                                   0,nil,
                                   0,nil,
                                   1,@ImageMemoryBarrier);

 for MipMapLevelIndex:=0 to fInstance.CullDepthPyramidMipMappedArray2DImages[InFlightFrameIndex].MipMapLevels-1 do begin

  case MipMapLevelIndex of
   0:begin
    Pipeline:=fPipelineLevel0;
   end;
   else begin
    Pipeline:=fPipelineLevel1;
   end;
  end;

  if MipMapLevelIndex<3 then begin
   aCommandBuffer.CmdBindPipeline(VK_PIPELINE_BIND_POINT_COMPUTE,Pipeline.Handle);
  end;

  aCommandBuffer.CmdBindDescriptorSets(VK_PIPELINE_BIND_POINT_COMPUTE,
                                       fPipelineLayout.Handle,
                                       0,
                                       1,
                                       @fVulkanDescriptorSets[InFlightFrameIndex,MipMapLevelIndex].Handle,
                                       0,
                                       nil);

  if assigned(fResourceInput) then begin
   aCommandBuffer.CmdDispatch(Max(1,(fResourceInput.Width+((1 shl (4+MipMapLevelIndex))-1)) shr (4+MipMapLevelIndex)),
                              Max(1,(fResourceInput.Height+((1 shl (4+MipMapLevelIndex))-1)) shr (4+MipMapLevelIndex)),
                              fInstance.CountSurfaceViews);
  end else begin
   aCommandBuffer.CmdDispatch(Max(1,(fInstance.CullDepthArray2DImages[InFlightFrameIndex].Width+((1 shl (4+MipMapLevelIndex))-1)) shr (4+MipMapLevelIndex)),
                              Max(1,(fInstance.CullDepthArray2DImages[InFlightFrameIndex].Height+((1 shl (4+MipMapLevelIndex))-1)) shr (4+MipMapLevelIndex)),
                              fInstance.CountSurfaceViews);
  end;

  FillChar(ImageMemoryBarrier,SizeOf(TVkImageMemoryBarrier),#0);
  ImageMemoryBarrier.sType:=VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
  ImageMemoryBarrier.pNext:=nil;
  ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_SHADER_WRITE_BIT);
  ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_SHADER_READ_BIT);
  ImageMemoryBarrier.oldLayout:=VK_IMAGE_LAYOUT_GENERAL;
  ImageMemoryBarrier.newLayout:=VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
  ImageMemoryBarrier.srcQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
  ImageMemoryBarrier.dstQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
  ImageMemoryBarrier.image:=fInstance.CullDepthPyramidMipmappedArray2DImages[InFlightFrameIndex].VulkanImage.Handle;
  ImageMemoryBarrier.subresourceRange.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
  ImageMemoryBarrier.subresourceRange.baseMipLevel:=MipMapLevelIndex;
  ImageMemoryBarrier.subresourceRange.levelCount:=1;
  ImageMemoryBarrier.subresourceRange.baseArrayLayer:=0;
  ImageMemoryBarrier.subresourceRange.layerCount:=fInstance.CountSurfaceViews;
  if (MipMapLevelIndex+1)<fInstance.CullDepthPyramidMipmappedArray2DImages[InFlightFrameIndex].MipMapLevels then begin
   aCommandBuffer.CmdPipelineBarrier(TVkPipelineStageFlags(VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT),
                                     TVkPipelineStageFlags(VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT),
                                     0,
                                     0,nil,
                                     0,nil,
                                     1,@ImageMemoryBarrier);
  end else begin

   aCommandBuffer.CmdPipelineBarrier(TVkPipelineStageFlags(VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT),
                                     FrameGraph.VulkanDevice.PhysicalDevice.PipelineStageAllShaderBits,
                                     0,
                                     0,nil,
                                     0,nil,
                                     1,@ImageMemoryBarrier);
  end;

 end;

end;

end.
