(******************************************************************************
 *                                 PasVulkan                                  *
 ******************************************************************************
 *                       Version see PasVulkan.Framework.pas                  *
 ******************************************************************************
 *                                zlib license                                *
 *============================================================================*
 *                                                                            *
 * Copyright (C) 2016-2024, Benjamin Rosseaux (benjamin@rosseaux.de)          *
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
unit PasVulkan.Raytracing;
{$i PasVulkan.inc}
{$ifndef fpc}
 {$ifdef conditionalexpressions}
  {$if CompilerVersion>=24.0}
   {$legacyifend on}
  {$ifend}
 {$endif}
{$endif}

interface

uses SysUtils,
     Classes,
     Math,
     Vulkan,
     PasVulkan.Types,
     PasVulkan.Math,
     PasVulkan.Collections,
     PasVulkan.Framework;

type EpvRaytracing=class(Exception);

     TpvRaytracingAccelerationStructure=class;

     TpvRaytracingAccelerationStructureList=TpvObjectGenericList<TpvRaytracingAccelerationStructure>;

     { TpvRaytracingAccelerationStructure }
     TpvRaytracingAccelerationStructure=class
      private
       fDevice:TpvVulkanDevice;
       fAccelerationStructure:TVkAccelerationStructureKHR;
       fAccelerationStructureType:TVkAccelerationStructureTypeKHR;
       fBuildGeometryInfo:TVkAccelerationStructureBuildGeometryInfoKHR;
       fBuildSizesInfo:TVkAccelerationStructureBuildSizesInfoKHR;
      public
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aAccelerationStructureType:TVkAccelerationStructureTypeKHR=TVkAccelerationStructureTypeKHR(VK_ACCELERATION_STRUCTURE_TYPE_GENERIC_KHR)); reintroduce; 
       destructor Destroy; override;
       class function Reduce(const aStructures:TpvRaytracingAccelerationStructureList):TVkAccelerationStructureBuildSizesInfoKHR; static;
       function GetMemorySizes(var aCount:TVkUInt32):TVkAccelerationStructureBuildSizesInfoKHR;
       procedure Initialize(const aBuffer:TpvVulkanBuffer;const aResultOfset:TVkDeviceSize);
       procedure Clone(const aCommandBuffer:TpvVulkanCommandBuffer;const aSourceAccelerationStructure:TpvRaytracingAccelerationStructure);
       procedure MemoryBarrier(const aCommandBuffer:TpvVulkanCommandBuffer);
      published
       property Device:TpvVulkanDevice read fDevice;
       property AccelerationStructure:TVkAccelerationStructureKHR read fAccelerationStructure;
       property AccelerationStructureType:TVkAccelerationStructureTypeKHR read fAccelerationStructureType;
      public
       property BuildGeometryInfo:TVkAccelerationStructureBuildGeometryInfoKHR read fBuildGeometryInfo;
       property BuildSizesInfo:TVkAccelerationStructureBuildSizesInfoKHR read fBuildSizesInfo;
     end;

     { TpvRaytracingBottomLevelAccelerationStructureGeometry }
     TpvRaytracingBottomLevelAccelerationStructureGeometry=class
      public
       type TTriangles=TpvDynamicArrayList<TVkAccelerationStructureGeometryKHR>;
            TBuildOffsets=TpvDynamicArrayList<TVkAccelerationStructureBuildRangeInfoKHR>;
      private
       fDevice:TpvVulkanDevice;
       fTriangles:TTriangles;
       fBuildOffsets:TBuildOffsets;
      public
       constructor Create(const aDevice:TpvVulkanDevice); reintroduce;
       destructor Destroy; override;       
       procedure AddTriangles(const aVertexBuffer:TpvVulkanBuffer;
                              const aVertexOffset:TVkUInt32;
                              const aVertexCount:TVkUInt32;
                              const aVertexStride:TVkDeviceSize;
                              const aIndexBuffer:TpvVulkanBuffer;
                              const aIndexOffset:TVkUInt32;
                              const aIndexCount:TVkUInt32;
                              const aOpaque:Boolean);
     end;
     
implementation

{ TpvRaytracingAccelerationStructure }

constructor TpvRaytracingAccelerationStructure.Create(const aDevice:TpvVulkanDevice;const aAccelerationStructureType:TVkAccelerationStructureTypeKHR=TVkAccelerationStructureTypeKHR(VK_ACCELERATION_STRUCTURE_TYPE_GENERIC_KHR));
begin

 inherited Create;

 fDevice:=aDevice;

 fAccelerationStructure:=VK_NULL_HANDLE;

 fAccelerationStructureType:=aAccelerationStructureType;

 FillChar(fBuildGeometryInfo,SizeOf(TVkAccelerationStructureBuildGeometryInfoKHR),#0);
 fBuildGeometryInfo.sType:=VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_BUILD_GEOMETRY_INFO_KHR;
 fBuildGeometryInfo.pNext:=nil;
 fBuildGeometryInfo.type_:=fAccelerationStructureType;
 fBuildGeometryInfo.flags:=0;
 fBuildGeometryInfo.mode:=TVkBuildAccelerationStructureModeKHR(VK_BUILD_ACCELERATION_STRUCTURE_MODE_BUILD_KHR);
 fBuildGeometryInfo.srcAccelerationStructure:=VK_NULL_HANDLE;
 fBuildGeometryInfo.dstAccelerationStructure:=VK_NULL_HANDLE;
 fBuildGeometryInfo.geometryCount:=0;
 fBuildGeometryInfo.pGeometries:=nil;
 fBuildGeometryInfo.ppGeometries:=nil;
 fBuildGeometryInfo.scratchData.deviceAddress:=0;
 fBuildGeometryInfo.scratchData.hostAddress:=nil;

 FillChar(fBuildSizesInfo,SizeOf(TVkAccelerationStructureBuildSizesInfoKHR),#0);
 fBuildSizesInfo.sType:=VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_BUILD_SIZES_INFO_KHR;
 fBuildSizesInfo.pNext:=nil;
 fBuildSizesInfo.accelerationStructureSize:=0;
 fBuildSizesInfo.updateScratchSize:=0;
 fBuildSizesInfo.buildScratchSize:=0;

end;

destructor TpvRaytracingAccelerationStructure.Destroy;
begin
 if fAccelerationStructure<>VK_NULL_HANDLE then begin
  try
   fDevice.Commands.Commands.DestroyAccelerationStructureKHR(fDevice.Handle,fAccelerationStructure,nil);
  finally
   fAccelerationStructure:=VK_NULL_HANDLE;
  end;
 end;
 inherited Destroy;
end;

class function TpvRaytracingAccelerationStructure.Reduce(const aStructures:TpvRaytracingAccelerationStructureList):TVkAccelerationStructureBuildSizesInfoKHR;
var Index:TpvSizeInt;
    Current:TpvRaytracingAccelerationStructure;
begin
 
 result.sType:=VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_BUILD_SIZES_INFO_KHR;
 result.pNext:=nil;
 result.accelerationStructureSize:=0;
 result.updateScratchSize:=0;
 result.buildScratchSize:=0;

 for Index:=0 to aStructures.Count-1 do begin
  Current:=aStructures[Index];
  if assigned(Current) then begin
   result.accelerationStructureSize:=result.accelerationStructureSize+Current.fBuildSizesInfo.accelerationStructureSize;
   result.updateScratchSize:=result.updateScratchSize+Current.fBuildSizesInfo.updateScratchSize;
   result.buildScratchSize:=result.buildScratchSize+Current.fBuildSizesInfo.buildScratchSize;
  end;
 end;

end;

function TpvRaytracingAccelerationStructure.GetMemorySizes(var aCount:TVkUInt32):TVkAccelerationStructureBuildSizesInfoKHR;
begin

 result.sType:=VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_BUILD_SIZES_INFO_KHR;
 result.pNext:=nil;
 result.accelerationStructureSize:=0;
 result.updateScratchSize:=0;
 result.buildScratchSize:=0;

 fDevice.Commands.Commands.GetAccelerationStructureBuildSizesKHR(fDevice.Handle,
                                                                 VK_ACCELERATION_STRUCTURE_BUILD_TYPE_DEVICE_KHR,
                                                                 @fBuildGeometryInfo,
                                                                 @aCount,
                                                                 @result);

 result.accelerationStructureSize:=RoundUp64(result.accelerationStructureSize,256);                                                                
 result.buildScratchSize:=RoundUp64(result.buildScratchSize,TVkDeviceSize(fDevice.PhysicalDevice.AccelerationStructurePropertiesKHR.minAccelerationStructureScratchOffsetAlignment));

end;

procedure TpvRaytracingAccelerationStructure.Initialize(const aBuffer:TpvVulkanBuffer;const aResultOfset:TVkDeviceSize);
var CreateInfo:TVkAccelerationStructureCreateInfoKHR;
begin
 
 FillChar(CreateInfo,SizeOf(TVkAccelerationStructureCreateInfoKHR),#0);
 CreateInfo.sType:=VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_CREATE_INFO_KHR;
 CreateInfo.pNext:=nil;
 CreateInfo.type_:=fBuildGeometryInfo.type_;
 CreateInfo.size:=fBuildSizesInfo.accelerationStructureSize;
 CreateInfo.buffer:=aBuffer.Handle;
 CreateInfo.offset:=aResultOfset;
  
 VulkanCheckResult(fDevice.Commands.Commands.CreateAccelerationStructureKHR(fDevice.Handle,@CreateInfo,nil,@fAccelerationStructure));
  
end;

procedure TpvRaytracingAccelerationStructure.Clone(const aCommandBuffer:TpvVulkanCommandBuffer;const aSourceAccelerationStructure:TpvRaytracingAccelerationStructure);
var CopyAccelerationStructureInfo:TVkCopyAccelerationStructureInfoKHR;
begin

 Assert(aCommandBuffer<>nil);
 Assert(aSourceAccelerationStructure<>nil);
 Assert(aSourceAccelerationStructure.fDevice=aCommandBuffer.Device);
 Assert(fDevice=aCommandBuffer.Device);
 Assert(aSourceAccelerationStructure.fAccelerationStructure<>VK_NULL_HANDLE);
 Assert(fAccelerationStructure<>VK_NULL_HANDLE);

 FillChar(CopyAccelerationStructureInfo,SizeOf(TVkCopyAccelerationStructureInfoKHR),#0);
 CopyAccelerationStructureInfo.sType:=VK_STRUCTURE_TYPE_COPY_ACCELERATION_STRUCTURE_INFO_KHR;
 CopyAccelerationStructureInfo.pNext:=nil;
 CopyAccelerationStructureInfo.src:=aSourceAccelerationStructure.AccelerationStructure;
 CopyAccelerationStructureInfo.dst:=fAccelerationStructure;
 CopyAccelerationStructureInfo.mode:=VK_COPY_ACCELERATION_STRUCTURE_MODE_CLONE_KHR;

 fDevice.Commands.Commands.CmdCopyAccelerationStructureKHR(aCommandBuffer.Handle,@CopyAccelerationStructureInfo);

end;

procedure TpvRaytracingAccelerationStructure.MemoryBarrier(const aCommandBuffer:TpvVulkanCommandBuffer);
var MemoryBarrier:TVkMemoryBarrier;
begin
 
 FillChar(MemoryBarrier,SizeOf(TVkMemoryBarrier),#0);
 MemoryBarrier.sType:=VK_STRUCTURE_TYPE_MEMORY_BARRIER;
 MemoryBarrier.pNext:=nil;
 MemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_ACCELERATION_STRUCTURE_READ_BIT_KHR) or TVkAccessFlags(VK_ACCESS_ACCELERATION_STRUCTURE_WRITE_BIT_KHR);
 MemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_ACCELERATION_STRUCTURE_READ_BIT_KHR) or TVkAccessFlags(VK_ACCESS_ACCELERATION_STRUCTURE_WRITE_BIT_KHR);
 
 aCommandBuffer.CmdPipelineBarrier(TVkPipelineStageFlags(VK_PIPELINE_STAGE_ACCELERATION_STRUCTURE_BUILD_BIT_KHR),
                                   TVkPipelineStageFlags(VK_PIPELINE_STAGE_ACCELERATION_STRUCTURE_BUILD_BIT_KHR),
                                   0,
                                   1,@MemoryBarrier,
                                   0,nil,
                                   0,nil);

end;

{ TpvRaytracingBottomLevelAccelerationStructureGeometry }

constructor TpvRaytracingBottomLevelAccelerationStructureGeometry.Create(const aDevice:TpvVulkanDevice);
begin
 inherited Create;
 fDevice:=aDevice;
 fTriangles:=TTriangles.Create;
 fBuildOffsets:=TBuildOffsets.Create;
end;

destructor TpvRaytracingBottomLevelAccelerationStructureGeometry.Destroy;
begin
 FreeAndNil(fTriangles);
 FreeAndNil(fBuildOffsets);
 inherited Destroy;
end;

procedure TpvRaytracingBottomLevelAccelerationStructureGeometry.AddTriangles(const aVertexBuffer:TpvVulkanBuffer;
                                                                             const aVertexOffset:TVkUInt32;
                                                                             const aVertexCount:TVkUInt32;
                                                                             const aVertexStride:TVkDeviceSize;
                                                                             const aIndexBuffer:TpvVulkanBuffer;
                                                                             const aIndexOffset:TVkUInt32;
                                                                             const aIndexCount:TVkUInt32;
                                                                             const aOpaque:Boolean);
var Geometry:TVkAccelerationStructureGeometryKHR;
    BuildOffsetInfo:TVkAccelerationStructureBuildRangeInfoKHR;
begin

 FillChar(Geometry,SizeOf(TVkAccelerationStructureGeometryKHR),#0);
 Geometry.sType:=VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_GEOMETRY_KHR;
 Geometry.pNext:=nil;
 Geometry.geometryType:=TVkGeometryTypeKHR(VK_GEOMETRY_TYPE_TRIANGLES_KHR);
 Geometry.geometry.triangles.sType:=VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_GEOMETRY_TRIANGLES_DATA_KHR;
 Geometry.geometry.triangles.pNext:=nil;
 Geometry.geometry.triangles.vertexData.deviceAddress:=aVertexBuffer.DeviceAddress;
 Geometry.geometry.triangles.vertexStride:=aVertexStride;
 Geometry.geometry.triangles.maxVertex:=aVertexCount;
 Geometry.geometry.triangles.vertexFormat:=VK_FORMAT_R32G32B32_SFLOAT;
 Geometry.geometry.triangles.indexData.deviceAddress:=aIndexBuffer.DeviceAddress;
 Geometry.geometry.triangles.indexType:=TVkIndexType(VK_INDEX_TYPE_UINT32);
 Geometry.geometry.triangles.transformData.deviceAddress:=0;
 Geometry.geometry.triangles.transformData.hostAddress:=nil;
 Geometry.flags:=TVkGeometryFlagsKHR(0);
 if aOpaque then begin
  Geometry.flags:=Geometry.flags or TVkGeometryFlagsKHR(VK_GEOMETRY_OPAQUE_BIT_KHR);
 end;

 FillChar(BuildOffsetInfo,SizeOf(TVkAccelerationStructureBuildRangeInfoKHR),#0);
 BuildOffsetInfo.firstVertex:=aVertexOffset div aVertexStride;
 BuildOffsetInfo.primitiveOffset:=aIndexOffset;
 BuildOffsetInfo.primitiveCount:=aIndexCount div 3;
 BuildOffsetInfo.transformOffset:=0;

 fTriangles.Add(Geometry);
 fBuildOffsets.Add(BuildOffsetInfo);

end;



end.
