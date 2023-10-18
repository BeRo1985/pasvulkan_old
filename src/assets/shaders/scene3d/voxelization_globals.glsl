#ifndef VOXELIZATION_GLOBALS_GLSL
#define VOXELIZATION_GLOBALS_GLSL

#ifdef VOXELIZATION

// Here i'm using 20.12 bit fixed point, since some current GPUs doesn't still support 32 bit floating point atomic add operations, and a RGBA8 
// atomic-compare-and-exchange-loop running average is not enough for a good quality voxelization with HDR-ranged colors for my taste, since 
// RGBA8 has only 8 bits per channel, which is only suitable for LDR colors. In addition to it, i'm using a 32-bit counter per voxel for the 
// post averaging step.

// The RGBA8 running average approach would also need separate volumes for non-emissive and emissive voxels, because of possible range 
// overflows, but where this approach doesn't need it, because it uses 32-bit fixed point, which is enough for HDR colors including emissive 
// colors on top of it. It's just HDR. :-)   

// So:

// 32*(4+1) = 160 bits per voxel, comparing to 32*2=64 bits per voxel (1x non-emission, 1x emission) with the RGBA8 running average approach, but 
// which supports only LDR colors. Indeed, it needs more memory bandwidth, but it's worth it, because it supports HDR colors, and it doesn't need  
// separate volumes for non-emissive and emissive voxels.

// 6 sides, 6 volumes, for multi directional anisotropic voxels, because a cube of voxel has 6 sides

#if defined(META_VOXELIZATION)

layout (set = 1, binding = 0, std140) readonly uniform VoxelGridData {
  vec4 clipMaps[4]; // xyz = center in world-space, w = half-extent of a voxel 
  vec4 cellSizes; // size of a voxel in world-space
  uint gridSize; // number of voxels in a clipmap in a single dimension
  uint countClipMaps; // maximum 4 clipmaps
  uint hardwareConservativeRasterization; // 0 = false, 1 = true
  uint maxGlobalFragmentCount; // maximum number of fragments per voxel globally
  uint maxLocalFragmentCount; // maximum number of fragments per voxel locally
} voxelGridData;

layout (set = 1, binding = 1, std430) coherent buffer VoxelGridContentData {
  uvec4 data[];
} voxelGridContentData;

layout (set = 1, binding = 2, std430) coherent buffer VoxelGridContentMetaData {
  uint data[];
} voxelGridContentMetaData;

#elif defined(OCCLUSION_VOXELIZATION)

layout (set = 1, binding = 0, std140) readonly uniform VoxelGridData {
  vec4 clipMaps[4]; // xyz = center in world-space, w = half-extent of a voxel 
  vec4 cellSizes; // size of a voxel in world-space
  uint gridSize; // number of voxels in a clipmap in a single dimension
  uint countClipMaps; // maximum 4 clipmaps
  uint hardwareConservativeRasterization; // 0 = false, 1 = true
  uint maxGlobalFragmentCount; // maximum number of fragments per voxel globally
  uint maxLocalFragmentCount; // maximum number of fragments per voxel locally
} voxelGridData;

layout (set = 1, binding = 1, std430) coherent buffer VoxelGridColors {
#if defined(USESHADERBUFFERFLOAT32ATOMICADD)
  float data[]; // 32-bit floating point
#else
  uint data[]; // 22.12 bit fixed point
#endif
} voxelGridColors;

layout (set = 1, binding = 2, std430) coherent buffer VoxelGridCounters {
  uint data[]; // 32-bit unsigned integer
} voxelGridCounters;

#else

layout (set = 1, binding = 5, std140) readonly uniform VoxelGridData {
  vec4 clipMaps[4]; // xyz = center in world-space, w = extent of a voxel 
  vec4 cellSizes; // size of a voxel in world-space
  uint gridSize; // number of voxels in a clipmap in a single dimension
  uint countClipMaps; // maximum 4 clipmaps
  uint hardwareConservativeRasterization; // 0 = false, 1 = true
  uint maxGlobalFragmentCount; // maximum number of fragments per voxel globally
  uint maxLocalFragmentCount; // maximum number of fragments per voxel locally
} voxelGridData;

layout (set = 1, binding = 6, std430) coherent buffer VoxelGridColors {
#if defined(USESHADERBUFFERFLOAT32ATOMICADD)
  float data[]; // 32-bit floating point
#else
  uint data[]; // 22.12 bit fixed point
#endif
} voxelGridColors;

layout (set = 1, binding = 7, std430) coherent buffer VoxelGridCounters {
  uint data[]; // 32-bit unsigned integer
} voxelGridCounters;

#endif

#endif

#endif