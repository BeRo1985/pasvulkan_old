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
unit PasVulkan.Scene3D.Renderer.Charlie.EnvMapCubeMap;
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
     PasVulkan.Scene3D.Renderer.Globals;

type { TpvScene3DRendererCharlieEnvMapCubeMap }
     TpvScene3DRendererCharlieEnvMapCubeMap=class
      public
       const Width=512;
             Height=512;
             Samples=1024;
      private
       fComputeShaderModule:TpvVulkanShaderModule;
       fVulkanPipelineShaderStageCompute:TpvVulkanPipelineShaderStage;
       fVulkanImage:TpvVulkanImage;
       fVulkanSampler:TpvVulkanSampler;
       fVulkanImageView:TpvVulkanImageView;
       fMemoryBlock:TpvVulkanDeviceMemoryBlock;
       fDescriptorImageInfo:TVkDescriptorImageInfo;
      public

       constructor Create(const aVulkanDevice:TpvVulkanDevice;const aVulkanPipelineCache:TpvVulkanPipelineCache;const aDescriptorImageInfo:TVkDescriptorImageInfo;const aImageFormat:TVkFormat=TVkFormat(VK_FORMAT_R16G16B16A16_SFLOAT));

       destructor Destroy; override;

      published

       property VulkanImage:TpvVulkanImage read fVulkanImage;

       property VulkanSampler:TpvVulkanSampler read fVulkanSampler;

       property VulkanImageView:TpvVulkanImageView read fVulkanImageView;

      public

       property DescriptorImageInfo:TVkDescriptorImageInfo read fDescriptorImageInfo;

     end;

implementation

{ TpvScene3DRendererCharlieEnvMapCubeMap }

constructor TpvScene3DRendererCharlieEnvMapCubeMap.Create(const aVulkanDevice:TpvVulkanDevice;const aVulkanPipelineCache:TpvVulkanPipelineCache;const aDescriptorImageInfo:TVkDescriptorImageInfo;const aImageFormat:TVkFormat);
type TPushConstants=record
      MipMapLevel:TpvInt32;
      MaxMipMapLevel:TpvInt32;
      NumSamples:TpvInt32;
      Dummy:TpvInt32;
     end;
var Index,MipMaps:TpvSizeInt;
    Stream:TStream;
    MemoryRequirements:TVkMemoryRequirements;
    RequiresDedicatedAllocation,
    PrefersDedicatedAllocation:boolean;
    MemoryBlockFlags:TpvVulkanDeviceMemoryBlockFlags;
    ImageSubresourceRange:TVkImageSubresourceRange;
    GraphicsQueue:TpvVulkanQueue;
    GraphicsCommandPool:TpvVulkanCommandPool;
    GraphicsCommandBuffer:TpvVulkanCommandBuffer;
    GraphicsFence:TpvVulkanFence;
    ComputeQueue:TpvVulkanQueue;
    ComputeCommandPool:TpvVulkanCommandPool;
    ComputeCommandBuffer:TpvVulkanCommandBuffer;
    ComputeFence:TpvVulkanFence;
    ImageViews:array of TpvVulkanImageView;
    VulkanDescriptorSetLayout:TpvVulkanDescriptorSetLayout;
    VulkanDescriptorPool:TpvVulkanDescriptorPool;
    VulkanDescriptorSets:array of TpvVulkanDescriptorSet;
    DescriptorImageInfos:array of TVkDescriptorImageInfo;
    PipelineLayout:TpvVulkanPipelineLayout;
    Pipeline:TpvVulkanComputePipeline;
    PushConstants:TPushConstants;
    ImageMemoryBarrier:TVkImageMemoryBarrier;
begin
 inherited Create;

 Stream:=pvScene3DShaderVirtualFileSystem.GetFile('cubemap_charlie_filter_comp.spv');
 try
  fComputeShaderModule:=TpvVulkanShaderModule.Create(aVulkanDevice,Stream);
 finally
  Stream.Free;
 end;

 MipMaps:=IntLog2(Max(Width,Height))+1;

 fVulkanPipelineShaderStageCompute:=TpvVulkanPipelineShaderStage.Create(VK_SHADER_STAGE_COMPUTE_BIT,fComputeShaderModule,'main');

 fVulkanImage:=TpvVulkanImage.Create(aVulkanDevice,
                                     TVkImageCreateFlags(VK_IMAGE_CREATE_CUBE_COMPATIBLE_BIT),
                                     VK_IMAGE_TYPE_2D,
                                     aImageFormat,
                                     Width,
                                     Height,
                                     1,
                                     MipMaps,
                                     6,
                                     VK_SAMPLE_COUNT_1_BIT,
                                     VK_IMAGE_TILING_OPTIMAL,
                                     TVkImageUsageFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT) or
                                     TVkImageUsageFlags(VK_IMAGE_USAGE_STORAGE_BIT) or
                                     TVkImageUsageFlags(VK_IMAGE_USAGE_SAMPLED_BIT),
                                     VK_SHARING_MODE_EXCLUSIVE,
                                     0,
                                     nil,
                                     VK_IMAGE_LAYOUT_UNDEFINED
                                    );

 MemoryRequirements:=aVulkanDevice.MemoryManager.GetImageMemoryRequirements(fVulkanImage.Handle,
                                                                                         RequiresDedicatedAllocation,
                                                                                         PrefersDedicatedAllocation);

 MemoryBlockFlags:=[];

 if RequiresDedicatedAllocation or PrefersDedicatedAllocation then begin
  Include(MemoryBlockFlags,TpvVulkanDeviceMemoryBlockFlag.DedicatedAllocation);
 end;

 fMemoryBlock:=aVulkanDevice.MemoryManager.AllocateMemoryBlock(MemoryBlockFlags,
                                                                            MemoryRequirements.size,
                                                                            MemoryRequirements.alignment,
                                                                            MemoryRequirements.memoryTypeBits,
                                                                            TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT),
                                                                            0,
                                                                            0,
                                                                            0,
                                                                            0,
                                                                            0,
                                                                            0,
                                                                            0,
                                                                            TpvVulkanDeviceMemoryAllocationType.ImageOptimal,
                                                                            @fVulkanImage.Handle);
 if not assigned(fMemoryBlock) then begin
  raise EpvVulkanMemoryAllocationException.Create('Memory for texture couldn''t be allocated!');
 end;

 fMemoryBlock.AssociatedObject:=self;

 VulkanCheckResult(aVulkanDevice.Commands.BindImageMemory(aVulkanDevice.Handle,
                                                                       fVulkanImage.Handle,
                                                                       fMemoryBlock.MemoryChunk.Handle,
                                                                       fMemoryBlock.Offset));

 GraphicsQueue:=aVulkanDevice.GraphicsQueue;

 ComputeQueue:=aVulkanDevice.ComputeQueue;

 GraphicsCommandPool:=TpvVulkanCommandPool.Create(aVulkanDevice,
                                                  aVulkanDevice.GraphicsQueueFamilyIndex,
                                                  TVkCommandPoolCreateFlags(VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT));
 try

  GraphicsCommandBuffer:=TpvVulkanCommandBuffer.Create(GraphicsCommandPool,VK_COMMAND_BUFFER_LEVEL_PRIMARY);
  try

   GraphicsFence:=TpvVulkanFence.Create(aVulkanDevice);
   try

    ComputeCommandPool:=TpvVulkanCommandPool.Create(aVulkanDevice,
                                                    aVulkanDevice.ComputeQueueFamilyIndex,
                                                    TVkCommandPoolCreateFlags(VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT));
    try

     ComputeCommandBuffer:=TpvVulkanCommandBuffer.Create(ComputeCommandPool,VK_COMMAND_BUFFER_LEVEL_PRIMARY);
     try

      ComputeFence:=TpvVulkanFence.Create(aVulkanDevice);
      try

       FillChar(ImageSubresourceRange,SizeOf(TVkImageSubresourceRange),#0);
       ImageSubresourceRange.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
       ImageSubresourceRange.baseMipLevel:=0;
       ImageSubresourceRange.levelCount:=MipMaps;
       ImageSubresourceRange.baseArrayLayer:=0;
       ImageSubresourceRange.layerCount:=6;

       fVulkanImage.SetLayout(TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT),
                              TVkImageLayout(VK_IMAGE_LAYOUT_UNDEFINED),
                              TVkImageLayout(VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL),
                              @ImageSubresourceRange,
                              GraphicsCommandBuffer,
                              GraphicsQueue,
                              GraphicsFence,
                              true);

       fVulkanSampler:=TpvVulkanSampler.Create(aVulkanDevice,
                                               TVkFilter(VK_FILTER_LINEAR),
                                               TVkFilter(VK_FILTER_LINEAR),
                                               TVkSamplerMipmapMode(VK_SAMPLER_MIPMAP_MODE_LINEAR),
                                               TVkSamplerAddressMode(VK_SAMPLER_ADDRESS_MODE_REPEAT),
                                               TVkSamplerAddressMode(VK_SAMPLER_ADDRESS_MODE_REPEAT),
                                               TVkSamplerAddressMode(VK_SAMPLER_ADDRESS_MODE_REPEAT),
                                               0.0,
                                               false,
                                               1.0,
                                               false,
                                               TVkCompareOp(VK_COMPARE_OP_NEVER),
                                               0.0,
                                               MipMaps,
                                               TVkBorderColor(VK_BORDER_COLOR_FLOAT_OPAQUE_BLACK),
                                               false);

       fVulkanImageView:=TpvVulkanImageView.Create(aVulkanDevice,
                                                   fVulkanImage,
                                                   TVkImageViewType(VK_IMAGE_VIEW_TYPE_CUBE),
                                                   aImageFormat,
                                                   TVkComponentSwizzle(VK_COMPONENT_SWIZZLE_IDENTITY),
                                                   TVkComponentSwizzle(VK_COMPONENT_SWIZZLE_IDENTITY),
                                                   TVkComponentSwizzle(VK_COMPONENT_SWIZZLE_IDENTITY),
                                                   TVkComponentSwizzle(VK_COMPONENT_SWIZZLE_IDENTITY),
                                                   TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT),
                                                   0,
                                                   MipMaps,
                                                   0,
                                                   6);

       fDescriptorImageInfo:=TVkDescriptorImageInfo.Create(fVulkanSampler.Handle,
                                                           fVulkanImageView.Handle,
                                                           VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);

       ImageViews:=nil;
       DescriptorImageInfos:=nil;
       try
        SetLength(ImageViews,MipMaps);
        SetLength(DescriptorImageInfos,MipMaps);
        for Index:=0 to MipMaps-1 do begin
         ImageViews[Index]:=TpvVulkanImageView.Create(aVulkanDevice,
                                                      fVulkanImage,
                                                      TVkImageViewType(VK_IMAGE_VIEW_TYPE_CUBE),
                                                      aImageFormat,
                                                      TVkComponentSwizzle(VK_COMPONENT_SWIZZLE_IDENTITY),
                                                      TVkComponentSwizzle(VK_COMPONENT_SWIZZLE_IDENTITY),
                                                      TVkComponentSwizzle(VK_COMPONENT_SWIZZLE_IDENTITY),
                                                      TVkComponentSwizzle(VK_COMPONENT_SWIZZLE_IDENTITY),
                                                      TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT),
                                                      Index,
                                                      1,
                                                      0,
                                                      6);

         DescriptorImageInfos[Index]:=TVkDescriptorImageInfo.Create(fVulkanSampler.Handle,
                                                                    ImageViews[Index].Handle,
                                                                    VK_IMAGE_LAYOUT_GENERAL);

        end;

        try

         VulkanDescriptorSetLayout:=TpvVulkanDescriptorSetLayout.Create(aVulkanDevice);
         try
          VulkanDescriptorSetLayout.AddBinding(0,
                                               VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                                               1,
                                               TVkShaderStageFlags(VK_SHADER_STAGE_COMPUTE_BIT),
                                               []);
          VulkanDescriptorSetLayout.AddBinding(1,
                                               VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
                                               1,
                                               TVkShaderStageFlags(VK_SHADER_STAGE_COMPUTE_BIT),
                                               []);
          VulkanDescriptorSetLayout.Initialize;

          VulkanDescriptorPool:=TpvVulkanDescriptorPool.Create(aVulkanDevice,
                                                               TVkDescriptorPoolCreateFlags(VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT),
                                                               MipMaps);
          try
           VulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,MipMaps);
           VulkanDescriptorPool.AddDescriptorPoolSize(VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,MipMaps);
           VulkanDescriptorPool.Initialize;

           VulkanDescriptorSets:=nil;
           try
            SetLength(VulkanDescriptorSets,MipMaps);
            for Index:=0 to MipMaps-1 do begin
             VulkanDescriptorSets[Index]:=TpvVulkanDescriptorSet.Create(VulkanDescriptorPool,
                                                                        VulkanDescriptorSetLayout);

             VulkanDescriptorSets[Index].WriteToDescriptorSet(0,
                                                              0,
                                                              1,
                                                              TVkDescriptorType(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER),
                                                              [aDescriptorImageInfo],
                                                              [],
                                                              [],
                                                              false);
             VulkanDescriptorSets[Index].WriteToDescriptorSet(1,
                                                              0,
                                                              1,
                                                              TVkDescriptorType(VK_DESCRIPTOR_TYPE_STORAGE_IMAGE),
                                                              [DescriptorImageInfos[Index]],
                                                              [],
                                                              [],
                                                              false);
             VulkanDescriptorSets[Index].Flush;
            end;
            try

             PipelineLayout:=TpvVulkanPipelineLayout.Create(aVulkanDevice);
             try
              PipelineLayout.AddPushConstantRange(TVkShaderStageFlags(VK_SHADER_STAGE_COMPUTE_BIT),0,SizeOf(TPushConstants));
              PipelineLayout.AddDescriptorSetLayout(VulkanDescriptorSetLayout);
              PipelineLayout.Initialize;

              Pipeline:=TpvVulkanComputePipeline.Create(aVulkanDevice,
                                                        aVulkanPipelineCache,
                                                        0,
                                                        fVulkanPipelineShaderStageCompute,
                                                        PipelineLayout,
                                                        nil,
                                                        0);
              try

               fVulkanImage.SetLayout(TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT),
                                      TVkImageLayout(VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL),
                                      TVkImageLayout(VK_IMAGE_LAYOUT_GENERAL),
                                      @ImageSubresourceRange,
                                      GraphicsCommandBuffer,
                                      GraphicsQueue,
                                      GraphicsFence,
                                      true);

               ComputeCommandBuffer.Reset(TVkCommandBufferResetFlags(VK_COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT));

               ComputeCommandBuffer.BeginRecording(TVkCommandBufferUsageFlags(VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT));

  {            FillChar(ImageMemoryBarrier,SizeOf(TVkImageMemoryBarrier),#0);
               ImageMemoryBarrier.sType:=VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
               ImageMemoryBarrier.pNext:=nil;
               ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_SHADER_READ_BIT);
               ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_SHADER_WRITE_BIT);
               ImageMemoryBarrier.oldLayout:=VK_IMAGE_LAYOUT_GENERAL;
               ImageMemoryBarrier.newLayout:=VK_IMAGE_LAYOUT_GENERAL;
               ImageMemoryBarrier.srcQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
               ImageMemoryBarrier.dstQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
               ImageMemoryBarrier.image:=fVulkanImage.Handle;
               ImageMemoryBarrier.subresourceRange.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
               ImageMemoryBarrier.subresourceRange.baseMipLevel:=0;
               ImageMemoryBarrier.subresourceRange.levelCount:=MipMaps;
               ImageMemoryBarrier.subresourceRange.baseArrayLayer:=0;
               ImageMemoryBarrier.subresourceRange.layerCount:=1;
               ComputeCommandBuffer.CmdPipelineBarrier(TVkPipelineStageFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT),
                                                       TVkPipelineStageFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT),
                                                       0,
                                                       0,nil,
                                                       0,nil,
                                                       1,@ImageMemoryBarrier);
  }
               ComputeCommandBuffer.CmdBindPipeline(VK_PIPELINE_BIND_POINT_COMPUTE,Pipeline.Handle);

               for Index:=0 to MipMaps-1 do begin

                ComputeCommandBuffer.CmdBindDescriptorSets(VK_PIPELINE_BIND_POINT_COMPUTE,
                                                           PipelineLayout.Handle,
                                                           0,
                                                           1,
                                                           @VulkanDescriptorSets[Index].Handle,
                                                           0,
                                                           nil);

                PushConstants.MipMapLevel:=Index;
                PushConstants.MaxMipMapLevel:=MipMaps-1;
                PushConstants.NumSamples:=Samples;

                ComputeCommandBuffer.CmdPushConstants(PipelineLayout.Handle,
                                                      TVkShaderStageFlags(TVkShaderStageFlagBits.VK_SHADER_STAGE_COMPUTE_BIT),
                                                      0,
                                                      SizeOf(TPushConstants),
                                                      @PushConstants);

                ComputeCommandBuffer.CmdDispatch(Max(1,(Width+((1 shl (4+Index))-1)) shr (4+Index)),
                                                 Max(1,(Height+((1 shl (4+Index))-1)) shr (4+Index)),
                                                 6);

               end;

  {            FillChar(ImageMemoryBarrier,SizeOf(TVkImageMemoryBarrier),#0);
               ImageMemoryBarrier.sType:=VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
               ImageMemoryBarrier.pNext:=nil;
               ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_SHADER_WRITE_BIT);
               ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_MEMORY_READ_BIT);
               ImageMemoryBarrier.oldLayout:=VK_IMAGE_LAYOUT_GENERAL;
               ImageMemoryBarrier.newLayout:=VK_IMAGE_LAYOUT_GENERAL;
               ImageMemoryBarrier.srcQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
               ImageMemoryBarrier.dstQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
               ImageMemoryBarrier.image:=fVulkanImage.Handle;
               ImageMemoryBarrier.subresourceRange.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
               ImageMemoryBarrier.subresourceRange.baseMipLevel:=0;
               ImageMemoryBarrier.subresourceRange.levelCount:=MipMaps;
               ImageMemoryBarrier.subresourceRange.baseArrayLayer:=0;
               ImageMemoryBarrier.subresourceRange.layerCount:=1;
               ComputeCommandBuffer.CmdPipelineBarrier(TVkPipelineStageFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT),
                                                       TVkPipelineStageFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT),
                                                       0,
                                                       0,nil,
                                                       0,nil,
                                                       1,@ImageMemoryBarrier); }

               ComputeCommandBuffer.EndRecording;

               ComputeCommandBuffer.Execute(ComputeQueue,TVkPipelineStageFlags(VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT),nil,nil,ComputeFence,true);

               fVulkanImage.SetLayout(TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT),
                                      TVkImageLayout(VK_IMAGE_LAYOUT_GENERAL),
                                      TVkImageLayout(VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL),
                                      @ImageSubresourceRange,
                                      GraphicsCommandBuffer,
                                      GraphicsQueue,
                                      GraphicsFence,
                                      true);

              finally
               FreeAndNil(Pipeline);
              end;

             finally
              FreeAndNil(PipelineLayout);
             end;

            finally
             for Index:=0 to MipMaps-1 do begin
              FreeAndNil(VulkanDescriptorSets[Index]);
             end;
            end;

           finally
            VulkanDescriptorSets:=nil;
           end;

          finally
           FreeAndNil(VulkanDescriptorPool);
          end;

         finally
          FreeAndNil(VulkanDescriptorSetLayout);
         end;

        finally
         for Index:=0 to MipMaps-1 do begin
          FreeAndNil(ImageViews[Index]);
         end;
        end;

       finally
        ImageViews:=nil;
        DescriptorImageInfos:=nil;
       end;

      finally
       FreeAndNil(ComputeFence);
      end;

     finally
      FreeAndNil(ComputeCommandBuffer);
     end;

    finally
     FreeAndNil(ComputeCommandPool);
    end;

   finally
    FreeAndNil(GraphicsFence);
   end;

  finally
   FreeAndNil(GraphicsCommandBuffer);
  end;

 finally
  FreeAndNil(GraphicsCommandPool);
 end;

end;

destructor TpvScene3DRendererCharlieEnvMapCubeMap.Destroy;
begin
 FreeAndNil(fMemoryBlock);
 FreeAndNil(fVulkanImageView);
 FreeAndNil(fVulkanSampler);
 FreeAndNil(fVulkanImage);
 FreeAndNil(fVulkanPipelineShaderStageCompute);
 FreeAndNil(fComputeShaderModule);
 inherited Destroy;
end;

end.
