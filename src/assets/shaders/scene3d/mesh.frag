#version 450 core

#define MESH_FRAGMENT_SHADER

#define NUM_SHADOW_CASCADES 4

#ifdef USE_MATERIAL_BUFFER_REFERENCE
  #undef NOBUFFERREFERENCE
#elif defined(USE_MATERIAL_SSBO)
  #define NOBUFFERREFERENCE
#endif

#extension GL_EXT_multiview : enable
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable
#extension GL_GOOGLE_include_directive : enable
#if defined(USEDEMOTE)
  #extension GL_EXT_demote_to_helper_invocation : enable
#endif
#extension GL_EXT_nonuniform_qualifier : enable
#if defined(USESHADERBUFFERFLOAT32ATOMICADD)
  #extension GL_EXT_shader_atomic_float : enable
#endif

#extension GL_EXT_control_flow_attributes : enable

#ifndef NOBUFFERREFERENCE
  #define sizeof(Type) (uint64_t(Type(uint64_t(0))+1))
  #extension GL_EXT_shader_explicit_arithmetic_types_int64 : enable 
  #extension GL_EXT_buffer_reference2 : enable 
  #ifndef USEINT64
    #extension GL_EXT_buffer_reference_uvec2 : enable 
  #endif
#endif

#if defined(LOCKOIT) || defined(DFAOIT)
  #extension GL_ARB_post_depth_coverage : enable
  #ifdef INTERLOCK
    #extension GL_ARB_fragment_shader_interlock : enable
    #define beginInvocationInterlock beginInvocationInterlockARB
    #define endInvocationInterlock endInvocationInterlockARB
    #ifdef MSAA
      layout(early_fragment_tests, post_depth_coverage, sample_interlock_ordered) in;
    #else
      layout(early_fragment_tests, post_depth_coverage, pixel_interlock_ordered) in;
    #endif
  #else
    #if defined(ALPHATEST)
      layout(post_depth_coverage) in;
    #else
      layout(early_fragment_tests, post_depth_coverage) in;
    #endif
  #endif
#elif !defined(ALPHATEST)
  layout(early_fragment_tests) in;
#endif

#ifdef VOXELIZATION
layout(location = 0) in vec3 inWorldSpacePosition;
layout(location = 1) in vec3 inViewSpacePosition;
layout(location = 2) in vec3 inCameraRelativePosition;
layout(location = 3) in vec3 inTangent;
layout(location = 4) in vec3 inBitangent;
layout(location = 5) in vec3 inNormal;
layout(location = 6) in vec2 inTexCoord0;
layout(location = 7) in vec2 inTexCoord1;
layout(location = 8) in vec4 inColor0;
layout(location = 9) in vec3 inModelScale;
layout(location = 10) flat in uint inMaterialID;
layout(location = 11) flat in vec3 inAABBMin;
layout(location = 12) flat in vec3 inAABBMax;
layout(location = 13) flat in uint inClipMapIndex; 
/*layout(location = 11) flat in vec3 inVertex0;
layout(location = 12) flat in vec3 inVertex1;
layout(location = 13) flat in vec3 inVertex2;*/
#else
layout(location = 0) in vec3 inWorldSpacePosition;
layout(location = 1) in vec3 inViewSpacePosition;
layout(location = 2) in vec3 inCameraRelativePosition;
layout(location = 3) in vec3 inTangent;
layout(location = 4) in vec3 inBitangent;
layout(location = 5) in vec3 inNormal;
layout(location = 6) in vec2 inTexCoord0;
layout(location = 7) in vec2 inTexCoord1;
layout(location = 8) in vec4 inColor0;
layout(location = 9) in vec3 inModelScale;
layout(location = 10) flat in uint inMaterialID;
layout(location = 11) flat in int inViewIndex;
layout(location = 12) flat in uint inFrameIndex;
#ifdef VELOCITY
layout(location = 13) in vec4 inPreviousClipSpace;
layout(location = 14) in vec4 inCurrentClipSpace;
layout(location = 15) flat in vec4 inJitter;
#else
layout(location = 13) flat in vec2 inJitter;
#endif
#endif

#ifdef VOXELIZATION
  // Nothing in this case, since the fragment shader writes to the voxel grid directly.
#elif defined(DEPTHONLY)
  #if defined(VELOCITY) && !(defined(MBOIT) && defined(MBOITPASS1))
    layout(location = 0) out vec2 outFragVelocity;
    layout(location = 1) out vec4 outFragNormal;
  #endif
#else
  #if defined(EXTRAEMISSIONOUTPUT) && !(defined(WBOIT) || defined(MBOIT))
    layout(location = 1) out vec4 outFragEmission;
  #elif defined(REFLECTIVESHADOWMAPOUTPUT)
    layout(location = 1) out vec4 outFragNormalUsed; // xyz = normal, w = 1.0 if normal was used, 0.0 otherwise (by clearing the normal buffer to vec4(0.0))
    //layout(location = 2) out vec3 outFragPosition; // Can be reconstructed from depth and inversed model view projection matrix 
  #endif
#endif

// Specialization constants are sadly unusable due to dead slow shader stage compilation times with several minutes "per" pipeline, 
// when the validation layers and a debugger (GDB, LLDB, etc.) are active at the same time!
#undef USE_SPECIALIZATION_CONSTANTS
#ifdef USE_SPECIALIZATION_CONSTANTS
layout (constant_id = 0) const bool UseReversedZ = true;
#endif

const int TEXTURE_BRDF_GGX = 0;
const int TEXTURE_BRDF_CHARLIE = 1;
const int TEXTURE_BRDF_SHEEN_E = 2;
const int TEXTURE_ENVMAP_GGX = 3;
const int TEXTURE_ENVMAP_CHARLIE = 4;
const int TEXTURE_ENVMAP_LAMBERTIAN = 5;

const int TEXTURE_BASE_INDEX = 10;

// Global descriptor set

struct View {
  mat4 viewMatrix;
  mat4 projectionMatrix;
  mat4 inverseViewMatrix;
  mat4 inverseProjectionMatrix;
};

#ifdef NOBUFFERREFERENCE
struct Material {
  vec4 baseColorFactor;
  vec4 specularFactor;
  vec4 emissiveFactor;
  vec4 metallicRoughnessNormalScaleOcclusionStrengthFactor;
  vec4 sheenColorFactorSheenRoughnessFactor;
  vec4 clearcoatFactorClearcoatRoughnessFactor;
  vec4 iorIridescenceFactorIridescenceIorIridescenceThicknessMinimum;
  vec4 iridescenceThicknessMaximumTransmissionFactorVolumeThicknessFactorVolumeAttenuationDistance;
  uvec4 volumeAttenuationColorAnisotropyStrengthAnisotropyRotation;
  uvec4 alphaCutOffFlagsTex0Tex1;
  int textures[20];
  mat3x2 textureTransforms[20];
};
#endif

layout(set = 0, binding = 0, std140) uniform uboViews {
  View views[256];
} uView;

#ifdef LIGHTS
struct Light {
  uvec4 metaData;
  vec4 colorIntensity;
  vec4 positionRange;
  vec4 directionZFar;
  mat4 shadowMapMatrix;
};

layout(set = 0, binding = 1, std430) readonly buffer LightItemData {
//uvec4 lightMetaData;
  Light lights[];
};

struct LightTreeNode {
  uvec4 aabbMinSkipCount;
  uvec4 aabbMaxUserData;
};

layout(set = 0, binding = 2, std430) readonly buffer LightTreeNodeData {
  LightTreeNode lightTreeNodes[];
};

#endif

#ifdef NOBUFFERREFERENCE

layout(set = 0, binding = 3, std430) readonly buffer Materials {
  Material materials[];
};

#else

layout(buffer_reference, std430, buffer_reference_align = 16) readonly buffer Material {
  vec4 baseColorFactor;
  vec4 specularFactor;
  vec4 emissiveFactor;
  vec4 metallicRoughnessNormalScaleOcclusionStrengthFactor;
  vec4 sheenColorFactorSheenRoughnessFactor;
  vec4 clearcoatFactorClearcoatRoughnessFactor;
  vec4 iorIridescenceFactorIridescenceIorIridescenceThicknessMinimum;
  vec4 iridescenceThicknessMaximumTransmissionFactorVolumeThicknessFactorVolumeAttenuationDistance;
  uvec4 volumeAttenuationColorAnisotropyStrengthAnisotropyRotation;
  uvec4 alphaCutOffFlagsTex0Tex1;
  int textures[20];
  mat3x2 textureTransforms[20];
};

layout(set = 0, binding = 3, std140) uniform Materials {
  Material materials;
} uMaterials;

#endif

layout(set = 0, binding = 4) uniform sampler2D u2DTextures[];

layout(set = 0, binding = 4) uniform samplerCube uCubeTextures[];

// Pass descriptor set

#ifdef DEPTHONLY
#else
layout(set = 1, binding = 0) uniform sampler2D uImageBasedLightingBRDFTextures[];  // 0 = GGX, 1 = Charlie, 2 = Sheen E

layout(set = 1, binding = 1) uniform samplerCube uImageBasedLightingEnvMaps[];  // 0 = GGX, 1 = Charlie, 2 = Lambertian

#ifdef SHADOWS
const uint SHADOWMAP_MODE_NONE = 1;
const uint SHADOWMAP_MODE_PCF = 2;
const uint SHADOWMAP_MODE_DPCF = 3;
const uint SHADOWMAP_MODE_PCSS = 4;
const uint SHADOWMAP_MODE_MSM = 5;

layout(set = 1, binding = 2, std140) uniform uboCascadedShadowMaps {
  mat4 shadowMapMatrices[NUM_SHADOW_CASCADES];
  vec4 shadowMapSplitDepthsScales[NUM_SHADOW_CASCADES];
  vec4 constantBiasNormalBiasSlopeBiasClamp[NUM_SHADOW_CASCADES];
  uvec4 metaData; // x = type
} uCascadedShadowMaps;

layout(set = 1, binding = 3) uniform sampler2DArray uCascadedShadowMapTexture;

#ifdef PCFPCSS

// Yay! Binding Aliasing! :-)
layout(set = 1, binding = 3) uniform sampler2DArrayShadow uCascadedShadowMapTextureShadow;

#endif

#endif

layout(set = 1, binding = 4) uniform sampler2DArray uPassTextures[]; // 0 = SSAO, 1 = Opaque frame buffer

#endif

#ifdef FRUSTUMCLUSTERGRID
layout (set = 1, binding = 5, std140) readonly uniform FrustumClusterGridGlobals {
  uvec4 tileSizeZNearZFar; 
  vec4 viewRect;
  uvec4 countLightsViewIndexSizeOffsetedViewIndex;
  uvec4 clusterSize;
  vec4 scaleBiasMax;
} uFrustumClusterGridGlobals;

layout (set = 1, binding = 6, std430) readonly buffer FrustumClusterGridIndexList {
   uint frustumClusterGridIndexList[];
};

layout (set = 1, binding = 7, std430) readonly buffer FrustumClusterGridData {
  uvec4 frustumClusterGridData[]; // x = start light index, y = count lights, z = start decal index, w = count decals
};

#endif

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

layout (set = 1, binding = 6, std140) readonly uniform VoxelGridData {
  vec4 clipMaps[4]; // xyz = center in world-space, w = extent of a voxel 
  uint countClipMaps; // maximum 4 clipmaps
  uint hardwareConservativeRasterization; // 0 = false, 1 = true
} voxelGridData;

layout (set = 1, binding = 7, std430) coherent buffer VoxelGridColors {
#if defined(USESHADERBUFFERFLOAT32ATOMICADD)
  float data[]; // 32-bit floating point
#else
  uint data[]; // 22.12 bit fixed point
#endif
} voxelGridColors;

layout (set = 1, binding = 8, std430) coherent buffer VoxelGridCounters {
  uint data[]; // 32-bit unsigned integer
} voxelGridCounters;

#endif

// Extra global illumination descriptor set (optional, if global illumination is enabled) for more easily sharing the same 
// global illumination data between multiple passes (e.g. opaque and transparent passes).

#ifdef GLOBAL_ILLUMINATION_CASCADED_RADIANCE_HINTS
  #define GLOBAL_ILLUMINATION_VOLUME_UNIFORM_SET 2
  #define GLOBAL_ILLUMINATION_VOLUME_UNIFORM_BINDING 0
  layout(set = GLOBAL_ILLUMINATION_VOLUME_UNIFORM_SET, binding = 1) uniform sampler3D uTexGlobalIlluminationCascadedRadianceHintsSHVolumes[];
  #define GLOBAL_ILLUMINATION_VOLUME_MESH_FRAGMENT
  #include "global_illumination_cascaded_radiance_hints.glsl"
#endif

#define TRANSPARENCY_DECLARATION
#include "transparency.glsl"
#undef TRANSPARENCY_DECLARATION

/* clang-format on */

vec3 workTangent, workBitangent, workNormal;

float sq(float t){
  return t * t; //
}

vec2 sq(vec2 t){
  return t * t; //
}

vec3 sq(vec3 t){
  return t * t; //
}

vec4 sq(vec4 t){
  return t * t; //
}

float pow2(float t){
  return t * t; //
}

vec2 pow2(vec2 t){
  return t * t; //
}

vec3 pow2(vec3 t){
  return t * t; //
}

vec4 pow2(vec4 t){
  return t * t; //
}

float pow4(float t){
  return t * t * t * t;  
}

vec2 pow4(vec2 t){
  return t * t * t * t;  
}

vec3 pow4(vec3 t){
  return t * t * t * t;  
}

vec4 pow4(vec4 t){
  return t * t * t * t;  
}

#if 0
vec3 convertLinearRGBToSRGB(vec3 c) {
  return mix((pow(c, vec3(1.0 / 2.4)) * vec3(1.055)) - vec3(5.5e-2), c * vec3(12.92), lessThan(c, vec3(3.1308e-3)));  //
}

vec4 convertLinearRGBToSRGB(vec4 c) {
  return vec4(convertLinearRGBToSRGB(c.xyz), c.w);  //
}

vec3 convertSRGBToLinearRGB(vec3 c) {
  return mix(pow((c + vec3(5.5e-2)) / vec3(1.055), vec3(2.4)), c / vec3(12.92), lessThan(c, vec3(4.045e-2)));  //
}

vec4 convertSRGBToLinearRGB(vec4 c) {
  return vec4(convertSRGBToLinearRGB(c.xyz), c.w);  //
}
#endif

#define TRANSPARENCY_GLOBALS
#include "transparency.glsl"
#undef TRANSPARENCY_GLOBALS

#ifdef VOXELIZATION
vec3 cartesianToBarycentric(vec3 p, vec3 a, vec3 b, vec3 c) {
  vec3 v0 = b - a, v1 = c - a, v2 = p - a;
  float d00 = dot(v0, v0), d01 = dot(v0, v1), d11 = dot(v1, v1), d20 = dot(v2, v0), d21 = dot(v2, v1);
  vec2 vw = vec2((d11 * d20) - (d01 * d21), (d00 * d21) - (d01 * d20)) / vec2((d00 * d11) - (d01 * d01));
  return vec3((1.0 - vw.x) - vw.y, vw.xy);
}
#endif

#ifdef DEPTHONLY
#else
#include "roughness.glsl"

float envMapMaxLevelGGX, envMapMaxLevelCharlie;

const float PI = 3.14159265358979323846,     //
    PI2 = 6.283185307179586476925286766559,  //
    OneOverPI = 1.0 / PI;

float cavity, ambientOcclusion, specularOcclusion;
uint flags, shadingModel;

vec3 parallaxCorrectedReflection(vec3 reflectionDirection){
    
#define PARALLAX_CORRECTION_METHOD 0 // 0 = None, 1 = Offset, 2 = Vector, 3 = Halfway (all without proxy geometry, at the moment) 

#if PARALLAX_CORRECTION_METHOD != 0
//vec3 fragmentWorldPosition = inWorldSpacePosition;
//vec3 cameraWorldPosition = uView.views[inViewIndex].inverseViewMatrix[3].xyz;
#endif

#if PARALLAX_CORRECTION_METHOD == 1

  // The most straightforward way to do parallax correction is to adjust the reflection vector based on the relative positions of the 
  // fragment and the camera. This adjustment will be based on how the view direction intersects with the virtual "bounding box" of the cubemap.
  // Given that a cubemap is, conceptually, a bounding box surrounding the scene, we can think of the parallax correction as finding the intersection 
  // of the view direction with this bounding box and using that point to adjust the reflection vector. Here's an approach to do this:

  // Calculate the normalized view direction, which is the direction from the camera to the fragment.
  vec3 viewDirection = normalize(-inCameraRelativePosition); //normalize(fragmentWorldPosition - cameraWorldPosition);
  
  // Compute the offset between the view direction and the original reflection direction.
  // This offset represents how much the reflection direction should be adjusted to account for the viewer's position.
  vec3 offset = viewDirection - reflectionDirection;
  
  // Apply the offset to the original reflection direction to get the parallax-corrected reflection direction.
  vec3 parallaxCorrectedReflectionDirection = reflectionDirection + offset;

  return normalize(parallaxCorrectedReflectionDirection);

#elif PARALLAX_CORRECTION_METHOD == 2

  // Another approach to parallax correction is to compute the reflection direction as usual and then adjust it based on the relative positions of the
  // fragment and the camera. This adjustment will be based on how the reflection direction intersects with the virtual "bounding box" of the cubemap.
  // Given just the fragment position, camera position, and reflection direction, we can only apply a general parallax correction, assuming a virtual 
  // "bounding box" around the scene. Here's an approach to do this:

  // Normalize the input reflection direction
  vec3 normalizedReflectionDirection = normalize(reflectionDirection);

  // Compute the view direction, which is the direction from the camera to the fragment
  vec3 viewDirection = -inCameraRelativePosition; //fragmentWorldPosition - cameraWorldPosition;
  
  // Create a vector perpendicular to the reflection direction and the view direction.
  vec3 perpendicularVector = cross(normalizedReflectionDirection, viewDirection);
  
  // Create another vector perpendicular to the reflection direction and the first perpendicular vector.
  vec3 correctionVector = cross(perpendicularVector, normalizedReflectionDirection);
  
  // Use the magnitude of the view direction to apply the parallax correction.
  float parallaxMagnitude = length(viewDirection) * 0.5;  // The scale factor (0.5) can be adjusted.
  
  // Apply the parallax correction to the reflection direction.
  // The reflection direction is shifted by a fraction of the parallax-reflected direction.
  vec3 parallaxCorrectedReflectionDirection = normalizedReflectionDirection + (correctionVector * parallaxMagnitude);

  return normalize(parallaxCorrectedReflectionDirection);

#elif PARALLAX_CORRECTION_METHOD == 3

  vec3 localSurfaceNormal = inNormal;

  // Normalize the input reflection direction
  vec3 normalizedReflectionDirection = normalize(reflectionDirection);
  
  // Compute the view direction, which is the direction from the camera to the fragment
  vec3 viewDirection = -inCameraRelativePosition; //fragmentWorldPosition - cameraWorldPosition;
  
  // Calculate the halfway vector between the view direction and the reflection direction.
  // This is often used in shading models, especially for specular reflections.
  vec3 halfwayVector = normalize(viewDirection + normalizedReflectionDirection);
  
  // Compute the reflection of the view direction about the local surface normal.
  // This would be the reflection vector if the surface was a perfect mirror.
  vec3 parallaxReflectedDirection = reflect(viewDirection, localSurfaceNormal);
  
  // Compute a scale factor based on the angle between the halfway vector and the local surface normal.
  // The dot product here effectively measures the cosine of the angle between the two vectors.
  // This factor will be used to adjust the reflection direction based on the viewer's position.
  float parallaxScaleFactor = 0.5 * dot(halfwayVector, localSurfaceNormal);
  
  // Apply the parallax correction to the reflection direction.
  // The reflection direction is shifted by a fraction of the parallax-reflected direction.
  vec3 parallaxCorrectedReflectionDirection = normalizedReflectionDirection + (parallaxReflectedDirection * parallaxScaleFactor);
  
  // Return the normalized parallax-corrected reflection direction.
  return normalize(parallaxCorrectedReflectionDirection);

#else

  return reflectionDirection;

#endif

}

vec3 iridescenceFresnel = vec3(0.0);
vec3 iridescenceF0 = vec3(0.0);
float iridescenceFactor = 0.0;
float iridescenceIor = 1.3;
float iridescenceThickness = 400.0;

#define ENABLE_ANISOTROPIC
#ifdef ENABLE_ANISOTROPIC
bool anisotropyActive;
vec3 anisotropyDirection;
vec3 anisotropyT;
vec3 anisotropyB;
float anisotropyStrength;
float alphaRoughnessAnisotropyT;
float alphaRoughnessAnisotropyB;
float anisotropyTdotV;
float anisotropyBdotV;
float anisotropyTdotL;
float anisotropyBdotL;
float anisotropyTdotH;
float anisotropyBdotH;
#endif

#if defined(BLEND) || defined(LOOPOIT) || defined(LOCKOIT) || defined(MBOIT) || defined(WBOIT) || defined(DFAOIT)
  #define TRANSMISSION
#endif

#if defined(TRANSMISSION)
float transmissionFactor = 0.0;

float volumeThickness = 0.0;
vec3 volumeAttenuationColor = vec3(1.0); 
float volumeAttenuationDistance = 1.0 / 0.0; // +INF
#endif

float applyIorToRoughness(float roughness, float ior) {
  // Scale roughness with IOR so that an IOR of 1.0 results in no microfacet refraction and an IOR of 1.5 results in the default amount of microfacet refraction.
  return roughness * clamp(fma(ior, 2.0, -2.0), 0.0, 1.0);
}

vec3 approximateAnalyticBRDF(vec3 specularColor, float NoV, float roughness) {
  const vec4 c0 = vec4(-1.0, -0.0275, -0.572, 0.022);
  const vec4 c1 = vec4(1.0, 0.0425, 1.04, -0.04);
  vec4 r = fma(c0, vec4(roughness), c1);
  vec2 AB = fma(vec2(-1.04, 1.04), vec2((min(r.x * r.x, exp2(-9.28 * NoV)) * r.x) + r.y), r.zw);
  return fma(specularColor, AB.xxx, AB.yyy);
}

vec3 F_Schlick(vec3 f0, vec3 f90, float VdotH) {
  return mix(f0, f90, pow(clamp(1.0 - VdotH, 0.0, 1.0), 5.0));  //
}

float F_Schlick(float f0, float f90, float VdotH) {
  float x = clamp(1.0 - VdotH, 0.0, 1.0);
  float x2 = x * x;
  return mix(f0, f90, x * x2 * x2);  
}

float F_Schlick(float f0, float VdotH) {
  return F_Schlick(f0, 1.0, VdotH);
}

vec3 F_Schlick(vec3 f0, float VdotH) {
  return F_Schlick(f0, vec3(1.0), VdotH);
}

vec3 Schlick_to_F0(vec3 f, vec3 f90, float VdotH) {
  float x = clamp(1.0 - VdotH, 0.0, 1.0);
  float x2 = x * x;
  float x5 = clamp(x * x2 * x2, 0.0, 0.9999);

  return (f - f90 * x5) / (1.0 - x5);
}

float Schlick_to_F0(float f, float f90, float VdotH) {
  float x = clamp(1.0 - VdotH, 0.0, 1.0);
  float x2 = x * x;
  float x5 = clamp(x * x2 * x2, 0.0, 0.9999);

  return (f - f90 * x5) / (1.0 - x5);
}

vec3 Schlick_to_F0(vec3 f, float VdotH) { return Schlick_to_F0(f, vec3(1.0), VdotH); }

float Schlick_to_F0(float f, float VdotH) { return Schlick_to_F0(f, 1.0, VdotH); }

float V_GGX(float NdotL, float NdotV, float alphaRoughness) {
#ifdef ENABLE_ANISOTROPIC
  float GGX;
  if (anisotropyActive) {
    GGX = (NdotL * length(vec3(alphaRoughnessAnisotropyT * anisotropyTdotV, alphaRoughnessAnisotropyB * anisotropyBdotV, NdotV))) + //
          (NdotV * length(vec3(alphaRoughnessAnisotropyT * anisotropyTdotL, alphaRoughnessAnisotropyB * anisotropyBdotL, NdotL)));
  }else{
    float alphaRoughnessSq = alphaRoughness * alphaRoughness;
    GGX = (NdotL * sqrt(((NdotV * NdotV) * (1.0 - alphaRoughnessSq)) + alphaRoughnessSq)) +  //
          (NdotV * sqrt(((NdotL * NdotL) * (1.0 - alphaRoughnessSq)) + alphaRoughnessSq));
  }
  return (GGX > 0.0) ? clamp(0.5 / GGX, 0.0, 1.0) : 0.0;
#else
  float alphaRoughnessSq = alphaRoughness * alphaRoughness;
  float GGX = (NdotL * sqrt(((NdotV * NdotV) * (1.0 - alphaRoughnessSq)) + alphaRoughnessSq)) +  //
              (NdotV * sqrt(((NdotL * NdotL) * (1.0 - alphaRoughnessSq)) + alphaRoughnessSq));
  return (GGX > 0.0) ? (0.5 / GGX) : 0.0;
#endif  
}

float D_GGX(float NdotH, float alphaRoughness) {
#ifdef ENABLE_ANISOTROPIC
  if (anisotropyActive) {
    float a2 = alphaRoughnessAnisotropyT * alphaRoughnessAnisotropyB;
    vec3 f = vec3(alphaRoughnessAnisotropyB * anisotropyTdotH, alphaRoughnessAnisotropyT * anisotropyBdotH, a2 * NdotH);
    return (a2 * pow2(a2 / dot(f, f))) / PI;  
  }else{
    float alphaRoughnessSq = alphaRoughness * alphaRoughness;
    float f = ((NdotH * NdotH) * (alphaRoughnessSq - 1.0)) + 1.0;
    return alphaRoughnessSq / (PI * (f * f));
  }
#else
  float alphaRoughnessSq = alphaRoughness * alphaRoughness;
  float f = ((NdotH * NdotH) * (alphaRoughnessSq - 1.0)) + 1.0;
  return alphaRoughnessSq / (PI * (f * f));
#endif
}

float lambdaSheenNumericHelper(float x, float alphaG) {
  float oneMinusAlphaSq = (1.0 - alphaG) * (1.0 - alphaG);
  return ((mix(21.5473, 25.3245, oneMinusAlphaSq) /          //
           (1.0 + (mix(3.82987, 3.32435, oneMinusAlphaSq) *  //
                   pow(x, mix(0.19823, 0.16801, oneMinusAlphaSq))))) +
          (mix(-1.97760, -1.27393, oneMinusAlphaSq) * x)) +  //
         mix(-4.32054, -4.85967, oneMinusAlphaSq);
}

float lambdaSheen(float cosTheta, float alphaG) {
  return (abs(cosTheta) < 0.5) ?  //
             exp(lambdaSheenNumericHelper(cosTheta, alphaG))
                               :  //
             exp((2.0 * lambdaSheenNumericHelper(0.5, alphaG)) - lambdaSheenNumericHelper(1.0 - cosTheta, alphaG));
}

float V_Sheen(float NdotL, float NdotV, float sheenRoughness) {
  sheenRoughness = max(sheenRoughness, 0.000001);
  float alphaG = sheenRoughness * sheenRoughness;
  return clamp(1.0 / (((1.0 + lambdaSheen(NdotV, alphaG)) + lambdaSheen(NdotL, alphaG)) * (4.0 * NdotV * NdotL)), 0.0, 1.0);
}

float D_Charlie(float sheenRoughness, float NdotH) {
  sheenRoughness = max(sheenRoughness, 0.000001);
  float invR = 1.0 / (sheenRoughness * sheenRoughness);
  return ((2.0 + invR) * pow(1.0 - (NdotH * NdotH), invR * 0.5)) / (2.0 * PI);
}

vec3 BRDF_lambertian(vec3 f0, vec3 f90, vec3 diffuseColor, float specularWeight, float VdotH) {
  return (1.0 - (specularWeight * mix(F_Schlick(f0, f90, VdotH), vec3(max(max(iridescenceF0.x, iridescenceF0.y), iridescenceF0.z)), iridescenceFactor))) * (diffuseColor * OneOverPI);  //
}

vec3 BRDF_specularGGX(vec3 f0, vec3 f90, float alphaRoughness, float specularWeight, float VdotH, float NdotL, float NdotV, float NdotH) {
  return specularWeight * mix(F_Schlick(f0, f90, VdotH), iridescenceFresnel, iridescenceFactor) * V_GGX(NdotL, NdotV, alphaRoughness) * D_GGX(NdotH, alphaRoughness);  //
}

vec3 BRDF_specularSheen(vec3 sheenColor, float sheenRoughness, float NdotL, float NdotV, float NdotH) {
  return sheenColor * D_Charlie(sheenRoughness, NdotH) * V_Sheen(NdotL, NdotV, sheenRoughness);  //
}

/////////////////////////////

vec3 getPunctualRadianceTransmission(vec3 normal, vec3 view, vec3 pointToLight, float alphaRoughness, vec3 f0, vec3 f90, vec3 baseColor, float ior) {
  float transmissionRougness = applyIorToRoughness(alphaRoughness, ior);

  vec3 n = normalize(normal);  // Outward direction of surface point
  vec3 v = normalize(view);    // Direction from surface point to view
  vec3 l = normalize(pointToLight);
  vec3 l_mirror = normalize(l + (2.0 * n * dot(-l, n)));  // Mirror light reflection vector on surface
  vec3 h = normalize(l_mirror + v);                       // Halfway vector between transmission light vector and v

  float D = D_GGX(clamp(dot(n, h), 0.0, 1.0), transmissionRougness);
  vec3 F = F_Schlick(f0, f90, clamp(dot(v, h), 0.0, 1.0));
  float Vis = V_GGX(clamp(dot(n, l_mirror), 0.0, 1.0), clamp(dot(n, v), 0.0, 1.0), transmissionRougness);

  // Transmission BTDF
  return (1.0 - F) * baseColor * D * Vis;
}

/////////////////////////////

// Compute attenuated light as it travels through a volume.
vec3 applyVolumeAttenuation(vec3 radiance, float transmissionDistance, vec3 attenuationColor, float attenuationDistance) {
  if (isinf(attenuationDistance) || (attenuationDistance == 0.0)) {
    // Attenuation distance is +∞ (which we indicate by zero), i.e. the transmitted color is not attenuated at all.
    return radiance;
  } else {
    // Compute light attenuation using Beer's law.
    vec3 attenuationCoefficient = -log(attenuationColor) / attenuationDistance;
    vec3 transmittance = exp(-attenuationCoefficient * transmissionDistance);  // Beer's law
    return transmittance * radiance;
  }
}

vec3 getVolumeTransmissionRay(vec3 n, vec3 v, float thickness, float ior) {
  return normalize(refract(-v, normalize(n), 1.0 / ior)) * thickness * inModelScale;
}

/////////////////////////////

// XYZ to sRGB color space
const mat3 XYZ_TO_REC709 = mat3(3.2404542, -0.9692660, 0.0556434, -1.5371385, 1.8760108, -0.2040259, -0.4985314, 0.0415560, 1.0572252);

// Assume air interface for top
// Note: We don't handle the case fresnel0 == 1
vec3 Fresnel0ToIor(vec3 fresnel0) {
  vec3 sqrtF0 = sqrt(fresnel0);
  return (vec3(1.0) + sqrtF0) / (vec3(1.0) - sqrtF0);
}

// Conversion FO/IOR
vec3 IorToFresnel0(vec3 transmittedIor, float incidentIor) { return sq((transmittedIor - vec3(incidentIor)) / (transmittedIor + vec3(incidentIor))); }

// ior is a value between 1.0 and 3.0. 1.0 is air interface
float IorToFresnel0(float transmittedIor, float incidentIor) { return sq((transmittedIor - incidentIor) / (transmittedIor + incidentIor)); }

// Fresnel equations for dielectric/dielectric interfaces.
// Ref: https://belcour.github.io/blog/research/2017/05/01/brdf-thin-film.html
// Evaluation XYZ sensitivity curves in Fourier space
vec3 evalSensitivity(float OPD, vec3 shift) {
  float phase = 2.0 * PI * OPD * 1.0e-9;
  vec3 val = vec3(5.4856e-13, 4.4201e-13, 5.2481e-13);
  vec3 pos = vec3(1.6810e+06, 1.7953e+06, 2.2084e+06);
  vec3 var = vec3(4.3278e+09, 9.3046e+09, 6.6121e+09);

  vec3 xyz = val * sqrt(2.0 * PI * var) * cos(pos * phase + shift) * exp(-sq(phase) * var);
  xyz.x += 9.7470e-14 * sqrt(2.0 * PI * 4.5282e+09) * cos(2.2399e+06 * phase + shift[0]) * exp(-4.5282e+09 * sq(phase));
  xyz /= 1.0685e-7;

  vec3 srgb = XYZ_TO_REC709 * xyz;
  return srgb;
}

vec3 evalIridescence(float outsideIOR, float eta2, float cosTheta1, float thinFilmThickness, vec3 baseF0) {
  vec3 I;

  // Force iridescenceIor -> outsideIOR when thinFilmThickness -> 0.0
  float iridescenceIor = mix(outsideIOR, eta2, smoothstep(0.0, 0.03, thinFilmThickness));
  // Evaluate the cosTheta on the base layer (Snell law)
  float sinTheta2Sq = sq(outsideIOR / iridescenceIor) * (1.0 - sq(cosTheta1));

  // Handle TIR:
  float cosTheta2Sq = 1.0 - sinTheta2Sq;
  if (cosTheta2Sq < 0.0) {
    return vec3(1.0);
  }

  float cosTheta2 = sqrt(cosTheta2Sq);

  // First interface
  float R0 = IorToFresnel0(iridescenceIor, outsideIOR);
  float R12 = F_Schlick(R0, cosTheta1);
  float R21 = R12;
  float T121 = 1.0 - R12;
  float phi12 = 0.0;
  if (iridescenceIor < outsideIOR) phi12 = PI;
  float phi21 = PI - phi12;

  // Second interface
  vec3 baseIOR = Fresnel0ToIor(clamp(baseF0, 0.0, 0.9999));  // guard against 1.0
  vec3 R1 = IorToFresnel0(baseIOR, iridescenceIor);
  vec3 R23 = F_Schlick(R1, cosTheta2);
  vec3 phi23 = vec3(0.0);
  if (baseIOR[0] < iridescenceIor) phi23[0] = PI;
  if (baseIOR[1] < iridescenceIor) phi23[1] = PI;
  if (baseIOR[2] < iridescenceIor) phi23[2] = PI;

  // Phase shift
  float OPD = 2.0 * iridescenceIor * thinFilmThickness * cosTheta2;
  vec3 phi = vec3(phi21) + phi23;

  // Compound terms
  vec3 R123 = clamp(R12 * R23, 1e-5, 0.9999);
  vec3 r123 = sqrt(R123);
  vec3 Rs = sq(T121) * R23 / (vec3(1.0) - R123);

  // Reflectance term for m = 0 (DC term amplitude)
  vec3 C0 = R12 + Rs;
  I = C0;

  // Reflectance term for m > 0 (pairs of diracs)
  vec3 Cm = Rs - T121;
  for (int m = 1; m <= 2; ++m) {
    Cm *= r123;
    vec3 Sm = 2.0 * evalSensitivity(float(m) * OPD, float(m) * phi);
    I += Cm * Sm;
  }

  // Since out of gamut colors might be produced, negative color values are clamped to 0.
  return max(I, vec3(0.0));
}

////////////////////////////

vec3 diffuseOutput = vec3(0.0);
vec3 specularOutput = vec3(0.0);
vec3 sheenOutput = vec3(0.0);
vec3 clearcoatOutput = vec3(0.0);
vec3 clearcoatFresnel = vec3(0.0);
#if defined(TRANSMISSION)
vec3 transmissionOutput = vec3(0.0);
#endif

float albedoSheenScaling = 1.0;

float albedoSheenScalingLUT(const in float NdotV, const in float sheenRoughnessFactor) {
  return textureLod(uImageBasedLightingBRDFTextures[2], vec2(NdotV, sheenRoughnessFactor), 0.0).x;  //
}

float getSpecularOcclusion(const in float NdotV, const in float ao, const in float roughness){
  return clamp((pow(NdotV + ao, /*roughness * roughness*/exp2((-16.0 * roughness) - 1.0)) - 1.0) + ao, 0.0, 1.0); 
} 

void doSingleLight(const in vec3 lightColor, const in vec3 lightLit, const in vec3 lightDirection, const in vec3 normal, const in vec3 diffuseColor, const in vec3 F0, const in vec3 F90, const in vec3 viewDirection, const in float refractiveAngle, const in float materialTransparency, const in float alphaRoughness, const in float materialCavity, const in vec3 sheenColor, const in float sheenRoughness, const in vec3 clearcoatNormal, const in vec3 clearcoatF0, const float clearcoatRoughness, const in float specularWeight) {
  float nDotL = clamp(dot(normal, lightDirection), 0.0, 1.0);
  float nDotV = clamp(dot(normal, viewDirection), 0.0, 1.0);
  if((nDotL > 0.0) || (nDotV > 0.0)){
    vec3 halfVector = normalize(viewDirection + lightDirection);
    float nDotH = clamp(dot(normal, halfVector), 0.0, 1.0);
    float vDotH = clamp(dot(viewDirection, halfVector), 0.0, 1.0);
    vec3 lit = vec3((materialCavity * nDotL * lightColor) * lightLit);
#ifdef ENABLE_ANISOTROPIC
    anisotropyTdotL = dot(anisotropyT, lightDirection);
    anisotropyBdotL = dot(anisotropyB, lightDirection);
    anisotropyTdotH = dot(anisotropyT, halfVector);
    anisotropyBdotH = dot(anisotropyB, halfVector);
#endif
    diffuseOutput += BRDF_lambertian(F0, F90, diffuseColor, specularWeight, vDotH) * lit;
    specularOutput += BRDF_specularGGX(F0, F90, alphaRoughness, specularWeight, vDotH, nDotL, nDotV, nDotH) * specularOcclusion * lit;
    if ((flags & (1u << 7u)) != 0u) {
      float sheenColorMax = max(max(sheenColor.x, sheenColor.y), sheenColor.z);
      albedoSheenScaling = min(1.0 - (sheenColorMax * albedoSheenScalingLUT(nDotV, sheenRoughness)), //
                               1.0 - (sheenColorMax * albedoSheenScalingLUT(nDotL, sheenRoughness)));
      sheenOutput += BRDF_specularSheen(sheenColor, sheenRoughness, nDotL, nDotV, nDotH) * lit;
    }
    if ((flags & (1u << 8u)) != 0u) {
      float nDotL = clamp(dot(clearcoatNormal, lightDirection), 1e-5, 1.0);
      float nDotV = clamp(abs(dot(clearcoatNormal, viewDirection)) + 1e-5, 0.0, 1.0);
      float nDotH = clamp(dot(clearcoatNormal, halfVector), 0.0, 1.0);
      vec3 lit = vec3((materialCavity * nDotL * lightColor) * lightLit);
      clearcoatOutput += F_Schlick(clearcoatF0, vec3(1.0), vDotH) *  //
                        D_GGX(nDotH, clearcoatRoughness) *          //
                        V_GGX(nDotV, nDotL, clearcoatRoughness) * specularWeight * specularOcclusion * lit;
    }
  }
}

vec4 getEnvMap(sampler2D texEnvMap, vec3 rayDirection, float texLOD) {
  rayDirection = normalize(rayDirection);
  return textureLod(texEnvMap, (vec2((atan(rayDirection.z, rayDirection.x) / PI2) + 0.5, acos(rayDirection.y) / 3.1415926535897932384626433832795)), texLOD);
}

vec3 getIBLRadianceLambertian(const in vec3 normal, const in vec3 viewDirection, const in float roughness, const in vec3 diffuseColor, const in vec3 F0, const in float specularWeight) {
  float ao = cavity * ambientOcclusion;
  float NdotV = clamp(dot(normal, viewDirection), 0.0, 1.0);
  vec2 brdfSamplePoint = clamp(vec2(NdotV, roughness), vec2(0.0), vec2(1.0));
  vec2 f_ab = textureLod(uImageBasedLightingBRDFTextures[0], brdfSamplePoint, 0.0).xy;
  vec3 irradiance = textureLod(uImageBasedLightingEnvMaps[2], normal.xyz, 0.0).xyz;
  vec3 mixedF0 = mix(F0, vec3(max(max(iridescenceF0.x, iridescenceF0.y), iridescenceF0.z)), iridescenceFactor);
  vec3 Fr = max(vec3(1.0 - roughness), mixedF0) - mixedF0;
  vec3 k_S = mixedF0 + (Fr * pow(1.0 - NdotV, 5.0));
  vec3 FssEss = (specularWeight * k_S * f_ab.x) + f_ab.y;
  float Ems = 1.0 - (f_ab.x + f_ab.y);
  vec3 F_avg = specularWeight * (mixedF0 + ((1.0 - mixedF0) / 21.0));
  vec3 FmsEms = (Ems * FssEss * F_avg) / (vec3(1.0) - (F_avg * Ems));
  vec3 k_D = (diffuseColor * ((1.0 - FssEss) + FmsEms) * ao);
  return (FmsEms + k_D) * irradiance;
}

vec3 getIBLRadianceGGX(in vec3 normal, const in float roughness, const in vec3 F0, const in float specularWeight, const in vec3 viewDirection, const in float litIntensity, const in vec3 imageLightBasedLightDirection) {
  float NdotV = clamp(dot(normal, viewDirection), 0.0, 1.0);
#ifdef ENABLE_ANISOTROPIC
  if(anisotropyActive){
  //float tangentRoughness = mix(roughness, 1.0, anisotropyStrength * anisotropyStrength);  
    normal = normalize(mix(cross(cross(anisotropyDirection, viewDirection), anisotropyDirection), normal, pow4(1.0 - (anisotropyStrength * (1.0 - roughness)))));
  }
#endif
  vec3 reflectionVector = normalize(reflect(-viewDirection, normal));
  float ao = cavity * ambientOcclusion,                                                                                                   //
      lit = mix(1.0, litIntensity, max(0.0, dot(reflectionVector, -imageLightBasedLightDirection) * (1.0 - (roughness * roughness)))),  //
      specularOcclusion = getSpecularOcclusion(NdotV, ao * lit, roughness);
  vec2 brdf = textureLod(uImageBasedLightingBRDFTextures[0], clamp(vec2(NdotV, roughness), vec2(0.0), vec2(1.0)), 0.0).xy;
  return (texture(uImageBasedLightingEnvMaps[0],  //
                  reflectionVector,               //
                  roughnessToMipMapLevel(roughness, envMapMaxLevelGGX))
              .xyz *                                                                     //
          fma(mix(F0 + ((max(vec3(1.0 - roughness), F0) - F0) * pow(1.0 - NdotV, 5.0)),  //
                  iridescenceFresnel,                                                    //
                  iridescenceFactor),                                                    //
              brdf.xxx,                                                                  //
              brdf.yyy * clamp(max(max(F0.x, F0.y), F0.z) * 50.0, 0.0, 1.0)) *           //
          specularWeight *                                                               //
          specularOcclusion *                                                            //
          1.0);
}

vec3 getIBLRadianceCharlie(vec3 normal, vec3 viewDirection, float sheenRoughness, vec3 sheenColor) {
  float ao = cavity * ambientOcclusion;
  float NdotV = clamp(dot(normal.xyz, viewDirection), 0.0, 1.0);
  vec3 reflectionVector = normalize(reflect(-viewDirection, normal));
  return texture(uImageBasedLightingEnvMaps[1],  //
                 reflectionVector,               //
                 roughnessToMipMapLevel(sheenRoughness, envMapMaxLevelCharlie))
             .xyz *    //
         sheenColor *  //
         textureLod(uImageBasedLightingBRDFTextures[1], clamp(vec2(NdotV, sheenRoughness), vec2(0.0), vec2(1.0)), 0.0).x *
         ao;
}

#ifdef TRANSMISSION
vec4 cubic(float v) {
  vec4 n = vec4(1.0, 2.0, 3.0, 4.0) - v;
  n *= n * n;
  vec3 t = vec3(n.x, fma(n.xy, vec2(-4.0), n.yz)) + vec2(0.0, 6.0 * n.x).xxy;
  return vec4(t, ((6.0 - t.x) - t.y) - t.z) * (1.0 / 6.0);
}

vec4 textureBicubicEx(const in sampler2DArray tex, vec3 uvw, int lod) {
  vec2 textureResolution = textureSize(tex, lod).xy,  //
      uv = fma(uvw.xy, textureResolution, vec2(-0.5)),            //
      fuv = fract(uv);
  uv -= fuv;
  vec4 xcubic = cubic(fuv.x),                                                             //
      ycubic = cubic(fuv.y),                                                              //
      c = uv.xxyy + vec2(-0.5, 1.5).xyxy,                                                 //
      s = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw),                             //
      o = (c + (vec4(xcubic.yw, ycubic.yw) / s)) * (vec2(1.0) / textureResolution).xxyy;  //
  s.xy = s.xz / (s.xz + s.yw);
  return mix(mix(textureLod(tex, vec3(o.yw, uvw.z), float(lod)), textureLod(tex, vec3(o.xw, uvw.t), float(lod)), s.x),  //
             mix(textureLod(tex, vec3(o.yz, uvw.z), float(lod)), textureLod(tex, vec3(o.xz, uvw.z), float(lod)), s.x), s.y);
}

vec4 textureBicubic(const in sampler2DArray tex, vec3 uvw, float lod, int maxLod) {
  int ilod = int(floor(lod));
  lod -= float(ilod); 
  return (lod < float(maxLod)) ? mix(textureBicubicEx(tex, uvw, ilod), textureBicubicEx(tex, uvw, ilod + 1), lod) : textureBicubicEx(tex, uvw, maxLod);
}

vec4 betterTextureEx(const in sampler2DArray tex, vec3 uvw, int lod) {
  vec2 textureResolution = textureSize(uPassTextures[1], lod).xy;
  vec2 uv = fma(uvw.xy, textureResolution, vec2(0.5));
  vec2 fuv = fract(uv);
  return textureLod(tex, vec3((floor(uv) + ((fuv * fuv) * fma(fuv, vec2(-2.0), vec2(3.0))) - vec2(0.5)) / textureResolution, uvw.z), float(lod));
}

vec4 betterTexture(const in sampler2DArray tex, vec3 uvw, float lod, int maxLod) {
  int ilod = int(floor(lod));
  lod -= float(ilod); 
  return (lod < float(maxLod)) ? mix(betterTextureEx(tex, uvw, ilod), betterTextureEx(tex, uvw, ilod + 1), lod) : betterTextureEx(tex, uvw, maxLod);
}

vec3 getTransmissionSample(vec2 fragCoord, float roughness, float ior) {
  int maxLod = int(textureQueryLevels(uPassTextures[1]));
  float framebufferLod = float(maxLod) * applyIorToRoughness(roughness, ior);
#if 1
  vec3 transmittedLight = (framebufferLod < 1e-4) ? //
                           betterTexture(uPassTextures[1], vec3(fragCoord.xy, inViewIndex), framebufferLod, maxLod).xyz :  //                           
                           textureBicubic(uPassTextures[1], vec3(fragCoord.xy, inViewIndex), framebufferLod, maxLod).xyz; //
#else
  vec3 transmittedLight = texture(uPassTextures[1], vec3(fragCoord.xy, inViewIndex), framebufferLod).xyz;
#endif
  return transmittedLight;
}

vec3 getIBLVolumeRefraction(vec3 n, vec3 v, float perceptualRoughness, vec3 baseColor, vec3 f0, vec3 f90, vec3 position, float ior, float thickness, vec3 attenuationColor, float attenuationDistance) {
  vec3 transmissionRay = getVolumeTransmissionRay(n, v, thickness, ior);
  vec3 refractedRayExit = position + transmissionRay;

  // Project refracted vector on the framebuffer, while mapping to normalized device coordinates.
  vec4 ndcPos = uView.views[inViewIndex].projectionMatrix * uView.views[inViewIndex].viewMatrix * vec4(refractedRayExit, 1.0);
  vec2 refractionCoords = fma(ndcPos.xy / ndcPos.w, vec2(0.5), vec2(0.5));
  
  // Sample framebuffer to get pixel the refracted ray hits.
  vec3 transmittedLight = getTransmissionSample(refractionCoords, perceptualRoughness, ior);

  vec3 attenuatedColor = applyVolumeAttenuation(transmittedLight, length(transmissionRay), attenuationColor, attenuationDistance);

  // Sample GGX LUT to get the specular component.
  float NdotV = clamp(dot(n, v), 0.0, 1.0);
  vec2 brdfSamplePoint = clamp(vec2(NdotV, perceptualRoughness), vec2(0.0, 0.0), vec2(1.0, 1.0));
  vec2 brdf = textureLod(uImageBasedLightingBRDFTextures[0], brdfSamplePoint, 0.0).xy;
  vec3 specularColor = (f0 * brdf.x) + (f90 * brdf.y);

  return (1.0 - specularColor) * attenuatedColor * baseColor;
}
#endif

#ifdef SHADOWS

#ifdef PCFPCSS

#ifndef UseReceiverPlaneDepthBias
#define UseReceiverPlaneDepthBias
#endif

#undef UseReceiverPlaneDepthBias // because it seems to crash Intel iGPUs   

#ifdef UseReceiverPlaneDepthBias
vec4 cascadedShadowMapPositions[NUM_SHADOW_CASCADES];
#endif

vec2 shadowMapSize;

vec3 shadowMapTexelSize;

const int SHADOW_TAP_COUNT = 16;

const vec2 PoissonDiskSamples[16] = vec2[](
  vec2(-0.94201624, -0.39906216), 
  vec2(0.94558609, -0.76890725), 
  vec2(-0.094184101, -0.92938870), 
  vec2(0.34495938, 0.29387760), 
  vec2(-0.91588581, 0.45771432), 
  vec2(-0.81544232, -0.87912464), 
  vec2(-0.38277543, 0.27676845), 
  vec2(0.97484398, 0.75648379), 
  vec2(0.44323325, -0.97511554), 
  vec2(0.53742981, -0.47373420), 
  vec2(-0.26496911, -0.41893023), 
  vec2(0.79197514, 0.19090188), 
  vec2(-0.24188840, 0.99706507), 
  vec2(-0.81409955, 0.91437590), 
  vec2(0.19984126, 0.78641367), 
  vec2(0.14383161, -0.14100790)
);

#ifdef UseReceiverPlaneDepthBias

vec2 shadowPositionReceiverPlaneDepthBias;

vec2 computeReceiverPlaneDepthBias(const vec3 position) {
  // see: GDC '06: Shadow Mapping: GPU-based Tips and Techniques
  // Chain rule to compute dz/du and dz/dv
  // |dz/du|   |du/dx du/dy|^-T   |dz/dx|
  // |dz/dv| = |dv/dx dv/dy|    * |dz/dy|
  vec3 duvz_dx = dFdx(position);
  vec3 duvz_dy = dFdy(position);
  vec2 dz_duv = inverse(transpose(mat2(duvz_dx.xy, duvz_dy.xy))) * vec2(duvz_dx.z, duvz_dy.z);
  return (any(isnan(dz_duv.xy)) || any(isinf(dz_duv.xy))) ? vec2(0.0) : dz_duv;
}

#endif

vec3 getOffsetedBiasedWorldPositionForShadowMapping(const in vec4 values, const in vec3 lightDirection){
  vec3 worldSpacePosition = inWorldSpacePosition;
  {
    vec3 worldSpaceNormal = workNormal;
    float cos_alpha = clamp(dot(worldSpaceNormal, lightDirection), 0.0, 1.0);
    float offset_scale_N = sqrt(1.0 - (cos_alpha * cos_alpha));   // sin(acos(L·N))
    float offset_scale_L = offset_scale_N / max(5e-4, cos_alpha); // tan(acos(L·N))
    vec2 offsets = fma(vec2(offset_scale_N, min(2.0, offset_scale_L)), vec2(values.yz), vec2(0.0, values.x));
    if(values.w > 1e-6){
      offsets.xy = clamp(offsets.xy, vec2(-values.w), vec2(values.w));
    }
    worldSpacePosition += (worldSpaceNormal * offsets.x) + (lightDirection * offsets.y);
  } 
  return worldSpacePosition;  
}

float CalculatePenumbraRatio(const in float zReceiver, const in float zBlocker, const in float nearOverFarMinusNear) {
#if 1
  return (zBlocker - zReceiver) / (1.0 - zBlocker);
#else
  return ((nearOverFarMinusNear + z_blocker) / (nearOverFarMinusNear + z_receiver)) - 1.0;
#endif
}

float doPCFSample(const in sampler2DArrayShadow shadowMapArray, const in vec3 pBaseUVS, const in float pU, const in float pV, const in float pZ, const in vec2 pShadowMapSizeInv){
#ifdef UseReceiverPlaneDepthBias  
  vec2 offset = vec2(pU, pV) * pShadowMapSizeInv;
  return texture(shadowMapArray, vec4(pBaseUVS + vec3(offset, 0.0), pZ + dot(offset, shadowPositionReceiverPlaneDepthBias)));
#else
  return texture(shadowMapArray, vec4(pBaseUVS + vec3(vec2(vec2(pU, pV) * pShadowMapSizeInv), 0.0), pZ));
#endif
}

float DoPCF(const in sampler2DArrayShadow shadowMapArray,
            const in int cascadedShadowMapIndex,
            const in vec4 shadowMapPosition){
#define OptimizedPCFFilterSize 7
#if OptimizedPCFFilterSize != 2
  
  vec2 shadowMapUV = shadowMapPosition.xy * shadowMapSize;

  vec3 shadowMapBaseUVS = vec3(floor(shadowMapUV + vec2(0.5)), floor(cascadedShadowMapIndex + 0.5));

  float shadowMapS = (shadowMapUV.x + 0.5) - shadowMapBaseUVS.x;
  float shadowMapT = (shadowMapUV.y + 0.5) - shadowMapBaseUVS.y;

  shadowMapBaseUVS.xy = (shadowMapBaseUVS.xy - vec2(0.5)) * shadowMapTexelSize.xy;
#endif
  float shadowMapSum = 0.0;
#if OptimizedPCFFilterSize == 2
  shadowMapSum = doPCFSample(shadowMapArray, vec3(shadowMapPosition.xy, float(pShadowMapSlice)), 0.0, 0.0, shadowMapPosition.z, vec2(0.0));
#elif OptimizedPCFFilterSize == 3

  float shadowMapBaseUW0 = 3.0 - (2.0 * shadowMapS);
  float shadowMapBaseUW1 = 1.0 + (2.0 * shadowMapS);

  float shadowMapBaseU0 = ((2.0 - shadowMapS) / shadowMapBaseUW0) - 1.0;
  float shadowMapBaseU1 = (shadowMapS / shadowMapBaseUW1) + 1.0;

  float shadowMapBaseVW0 = 3.0 - (2.0 * shadowMapT);
  float shadowMapBaseVW1 = 1.0 + (2.0 * shadowMapT);

  float shadowMapBaseV0 = ((2.0 - shadowMapT) / shadowMapBaseVW0) - 1.0;
  float shadowMapBaseV1 = (shadowMapT / shadowMapBaseVW1) + 1.0;

  shadowMapSum += (shadowMapBaseUW0 * shadowMapBaseVW0) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU0, shadowMapBaseV0, shadowMapPosition.z, shadowMapTexelSize.xy);
  shadowMapSum += (shadowMapBaseUW1 * shadowMapBaseVW0) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU1, shadowMapBaseV0, shadowMapPosition.z, shadowMapTexelSize.xy);
  shadowMapSum += (shadowMapBaseUW0 * shadowMapBaseVW1) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU0, shadowMapBaseV1, shadowMapPosition.z, shadowMapTexelSize.xy);
  shadowMapSum += (shadowMapBaseUW1 * shadowMapBaseVW1) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU1, shadowMapBaseV1, shadowMapPosition.z, shadowMapTexelSize.xy);

  shadowMapSum *= 1.0 / 16.0;
#elif OptimizedPCFFilterSize == 5

  float shadowMapBaseUW0 = 4.0 - (3.0 * shadowMapS);
  float shadowMapBaseUW1 = 7.0;
  float shadowMapBaseUW2 = 1.0 + (3.0 * shadowMapS);

  float shadowMapBaseU0 = ((3.0 - (2.0 * shadowMapS)) / shadowMapBaseUW0) - 2.0;
  float shadowMapBaseU1 = (3.0 + shadowMapS) / shadowMapBaseUW1;
  float shadowMapBaseU2 = (shadowMapS / shadowMapBaseUW2) + 2.0;

  float shadowMapBaseVW0 = 4.0 - (3.0 * shadowMapT);
  float shadowMapBaseVW1 = 7.0;
  float shadowMapBaseVW2 = 1.0 + (3.0 * shadowMapT);

  float shadowMapBaseV0 = ((3.0 - (2.0 * shadowMapT)) / shadowMapBaseVW0) - 2.0;
  float shadowMapBaseV1 = (3.0 + shadowMapT) / shadowMapBaseVW1;
  float shadowMapBaseV2 = (shadowMapT / shadowMapBaseVW2) + 2.0;

  shadowMapSum += (shadowMapBaseUW0 * shadowMapBaseVW0) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU0, shadowMapBaseV0, shadowMapPosition.z, shadowMapTexelSize.xy);
  shadowMapSum += (shadowMapBaseUW1 * shadowMapBaseVW0) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU1, shadowMapBaseV0, shadowMapPosition.z, shadowMapTexelSize.xy);
  shadowMapSum += (shadowMapBaseUW2 * shadowMapBaseVW0) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU2, shadowMapBaseV0, shadowMapPosition.z, shadowMapTexelSize.xy);

  shadowMapSum += (shadowMapBaseUW0 * shadowMapBaseVW1) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU0, shadowMapBaseV1, shadowMapPosition.z, shadowMapTexelSize.xy);
  shadowMapSum += (shadowMapBaseUW1 * shadowMapBaseVW1) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU1, shadowMapBaseV1, shadowMapPosition.z, shadowMapTexelSize.xy);
  shadowMapSum += (shadowMapBaseUW2 * shadowMapBaseVW1) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU2, shadowMapBaseV1, shadowMapPosition.z, shadowMapTexelSize.xy);

  shadowMapSum += (shadowMapBaseUW0 * shadowMapBaseVW2) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU0, shadowMapBaseV2, shadowMapPosition.z, shadowMapTexelSize.xy);
  shadowMapSum += (shadowMapBaseUW1 * shadowMapBaseVW2) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU1, shadowMapBaseV2, shadowMapPosition.z, shadowMapTexelSize.xy);
  shadowMapSum += (shadowMapBaseUW2 * shadowMapBaseVW2) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU2, shadowMapBaseV2, shadowMapPosition.z, shadowMapTexelSize.xy);

  shadowMapSum *= 1.0 / 144.0;

#elif OptimizedPCFFilterSize == 7

  float shadowMapBaseUW0 = (5.0 * shadowMapS) - 6;
  float shadowMapBaseUW1 = (11.0 * shadowMapS) - 28.0;
  float shadowMapBaseUW2 = -((11.0 * shadowMapS) + 17.0);
  float shadowMapBaseUW3 = -((5.0 * shadowMapS) + 1.0);

  float shadowMapBaseU0 = ((4.0 * shadowMapS) - 5.0) / shadowMapBaseUW0 - 3.0;
  float shadowMapBaseU1 = ((4.0 * shadowMapS) - 16.0) / shadowMapBaseUW1 - 1.0;
  float shadowMapBaseU2 = (-(((7.0 * shadowMapS) + 5.0)) / shadowMapBaseUW2) + 1.0;
  float shadowMapBaseU3 = (-(shadowMapS / shadowMapBaseUW3)) + 3.0;

  float shadowMapBaseVW0 = ((5.0 * shadowMapT) - 6.0);
  float shadowMapBaseVW1 = ((11.0 * shadowMapT) - 28.0);
  float shadowMapBaseVW2 = -((11.0 * shadowMapT) + 17.0);
  float shadowMapBaseVW3 = -((5.0 * shadowMapT) + 1.0);

  float shadowMapBaseV0 = (((4.0 * shadowMapT) - 5.0) / shadowMapBaseVW0) - 3.0;
  float shadowMapBaseV1 = (((4.0 * shadowMapT) - 16.0) / shadowMapBaseVW1) - 1.0;
  float shadowMapBaseV2 = ((-((7.0 * shadowMapT) + 5)) / shadowMapBaseVW2) + 1.0;
  float shadowMapBaseV3 = (-(shadowMapT / shadowMapBaseVW3)) + 3.0;

  shadowMapSum += (shadowMapBaseUW0 * shadowMapBaseVW0) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU0, shadowMapBaseV0, shadowMapPosition.z, shadowMapTexelSize.xy);
  shadowMapSum += (shadowMapBaseUW1 * shadowMapBaseVW0) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU1, shadowMapBaseV0, shadowMapPosition.z, shadowMapTexelSize.xy);
  shadowMapSum += (shadowMapBaseUW2 * shadowMapBaseVW0) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU2, shadowMapBaseV0, shadowMapPosition.z, shadowMapTexelSize.xy);
  shadowMapSum += (shadowMapBaseUW3 * shadowMapBaseVW0) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU3, shadowMapBaseV0, shadowMapPosition.z, shadowMapTexelSize.xy);

  shadowMapSum += (shadowMapBaseUW0 * shadowMapBaseVW1) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU0, shadowMapBaseV1, shadowMapPosition.z, shadowMapTexelSize.xy);
  shadowMapSum += (shadowMapBaseUW1 * shadowMapBaseVW1) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU1, shadowMapBaseV1, shadowMapPosition.z, shadowMapTexelSize.xy);
  shadowMapSum += (shadowMapBaseUW2 * shadowMapBaseVW1) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU2, shadowMapBaseV1, shadowMapPosition.z, shadowMapTexelSize.xy);
  shadowMapSum += (shadowMapBaseUW3 * shadowMapBaseVW1) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU3, shadowMapBaseV1, shadowMapPosition.z, shadowMapTexelSize.xy);

  shadowMapSum += (shadowMapBaseUW0 * shadowMapBaseVW2) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU0, shadowMapBaseV2, shadowMapPosition.z, shadowMapTexelSize.xy);
  shadowMapSum += (shadowMapBaseUW1 * shadowMapBaseVW2) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU1, shadowMapBaseV2, shadowMapPosition.z, shadowMapTexelSize.xy);
  shadowMapSum += (shadowMapBaseUW2 * shadowMapBaseVW2) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU2, shadowMapBaseV2, shadowMapPosition.z, shadowMapTexelSize.xy);
  shadowMapSum += (shadowMapBaseUW3 * shadowMapBaseVW2) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU3, shadowMapBaseV2, shadowMapPosition.z, shadowMapTexelSize.xy);

  shadowMapSum += (shadowMapBaseUW0 * shadowMapBaseVW3) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU0, shadowMapBaseV3, shadowMapPosition.z, shadowMapTexelSize.xy);
  shadowMapSum += (shadowMapBaseUW1 * shadowMapBaseVW3) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU1, shadowMapBaseV3, shadowMapPosition.z, shadowMapTexelSize.xy);
  shadowMapSum += (shadowMapBaseUW2 * shadowMapBaseVW3) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU2, shadowMapBaseV3, shadowMapPosition.z, shadowMapTexelSize.xy);
  shadowMapSum += (shadowMapBaseUW3 * shadowMapBaseVW3) * doPCFSample(shadowMapArray, shadowMapBaseUVS, shadowMapBaseU3, shadowMapBaseV3, shadowMapPosition.z, shadowMapTexelSize.xy);

  shadowMapSum *= 1.0 / 2704.0;

#endif

  return 1.0 - clamp(shadowMapSum, 0.0, 1.0);
}
                                
float ContactHardenPCFKernel(const float occluders,
                             const float occluderDistSum,
                             const float lightDistanceNormalized,
                             const float mul){

  if(occluderDistSum == 0.0){
    return 1.0;
  }else{

    float occluderAvgDist = occluderDistSum / occluders;

    float w = 1.0 / (mul * SHADOW_TAP_COUNT);

    float pcfWeight = clamp(occluderAvgDist / max(1e-6, lightDistanceNormalized), 0.0, 1.0);

    float percentageOccluded = clamp(occluders * w, 0.0, 1.0);

    percentageOccluded = fma(percentageOccluded, 2.0, -1.0);
    float occludedSign = sign(percentageOccluded);
    percentageOccluded = fma(percentageOccluded, -occludedSign, 1.0);

    return 1.0 - fma((1.0 - mix(percentageOccluded * percentageOccluded * percentageOccluded, percentageOccluded, pcfWeight)) * occludedSign, 0.5, 0.5);

  }  
}

float DoDPCF_PCSS(const in sampler2DArray shadowMapArray, 
                  const in int cascadedShadowMapIndex,
                  const in vec4 shadowPosition,
                  const in bool DPCF){

  float rotationAngle; 
  {
    const uint k = 1103515245u;
    uvec3 v = uvec3(floatBitsToUint(inTexCoord0.xy), uint(inFrameIndex)) ^ uvec3(0u, uvec2(gl_FragCoord.xy)); 
    v = ((v >> 8u) ^ v.yzx) * k;
    v = ((v >> 8u) ^ v.yzx) * k;
    v = ((v >> 8u) ^ v.yzx) * k;
    rotationAngle = ((uintBitsToFloat(uint(uint(((v.x >> 9u) & uint(0x007fffffu)) | uint(0x3f800000u))))) - 1.0) * 6.28318530718;    
  }
  vec2 rotation = vec2(sin(rotationAngle + vec2(0.0, 1.57079632679)));
  mat2 rotationMatrix = mat2(rotation.y, rotation.x, -rotation.x, rotation.y);
  
  float occluders = 0.0;  
  float occluderDistSum = 0.0;
  
  vec2 penumbraSize = uCascadedShadowMaps.shadowMapSplitDepthsScales[cascadedShadowMapIndex].w * shadowMapTexelSize.xy;

#if 0
  const float countFactor = 1.0;
  for(int tapIndex = 0; tapIndex < SHADOW_TAP_COUNT; tapIndex++){
    vec2 offset = PoissonDiskSamples[tapIndex] * rotationMatrix * penumbraSize;
    vec2 uv = shadowPosition.xy + offset;
    float sampleDepth = textureLod(shadowMapArray, vec3(uv, float(cascadedShadowMapIndex)), 0.0).x;
    float sampleDistance = sampleDepth - shadowPosition.z;
#ifdef UseReceiverPlaneDepthBias
    float sampleOccluder = step(dot(offset, shadowPositionReceiverPlaneDepthBias), sampleDistance);
#else
    float sampleOccluder = step(0.0, sampleDistance);
#endif
    occluders += sampleOccluder;
    occluderDistSum += sampleDistance * sampleOccluder;
  }
#else  
  const float countFactor = 4.0;
  for(int tapIndex = 0; tapIndex < SHADOW_TAP_COUNT; tapIndex++){
    vec2 offset = PoissonDiskSamples[tapIndex] * rotationMatrix * penumbraSize;
    vec4 samples = textureGather(shadowMapArray, vec3(shadowPosition.xy + offset, float(cascadedShadowMapIndex)), 0); // 01, 11, 10, 00  
    vec4 sampleDistances = samples - vec4(shadowPosition.z);
#ifdef UseReceiverPlaneDepthBias
    vec4 sampleOccluders = step(vec4(dot(offset + shadowMapTexelSize.zy, shadowPositionReceiverPlaneDepthBias),      // 01
                                     dot(offset + shadowMapTexelSize.xy, shadowPositionReceiverPlaneDepthBias),      // 11
                                     dot(offset + shadowMapTexelSize.xz, shadowPositionReceiverPlaneDepthBias),      // 10
                                     dot(offset, shadowPositionReceiverPlaneDepthBias)), sampleDistances);  // 00
#else
    vec4 sampleOccluders = step(0.0, sampleDistances);
#endif
    occluders += dot(sampleOccluders, vec4(1.0));
    occluderDistSum += dot(sampleDistances * sampleOccluders, vec4(1.0));
  }
#endif

  if(occluderDistSum == 0.0){
    return 0.0;
  }else{

    float penumbraRatio = CalculatePenumbraRatio(shadowPosition.z, occluderDistSum / occluders, 0.0);
    
    if(DPCF){

      // DPCF
      
      penumbraRatio = clamp(penumbraRatio, 0.0, 1.0);

      float percentageOccluded = occluders * (1.0 / (SHADOW_TAP_COUNT * countFactor));

      percentageOccluded = fma(percentageOccluded, 2.0, -1.0);
      float occludedSign = sign(percentageOccluded);
      percentageOccluded = fma(percentageOccluded, -occludedSign, 1.0);

      return fma((1.0 - mix(percentageOccluded * percentageOccluded * percentageOccluded, percentageOccluded, penumbraRatio)) * occludedSign, 0.5, 0.5);

    //return 1.0 - ContactHardenPCFKernel(occluders, occluderDistSum, shadowPosition.z, countFactor);

    }else{

      // PCSS

      penumbraSize *= CalculatePenumbraRatio(shadowPosition.z, occluderDistSum / occluders, 0.0);

      float occludedCount = 0.0;

      for(int tapIndex = 0; tapIndex < SHADOW_TAP_COUNT; tapIndex++){
        vec2 offset = PoissonDiskSamples[tapIndex] * rotationMatrix * penumbraSize;
        vec2 position = shadowPosition.xy + offset;
        vec2 gradient = fract((position * shadowMapSize) - 0.5);
        vec4 samples = textureGather(shadowMapArray, vec3(position, float(cascadedShadowMapIndex)), 0); // 01, 11, 10, 00  
        vec4 sampleDistances = samples - vec4(shadowPosition.z);
#ifdef UseReceiverPlaneDepthBias
        vec4 sampleOccluders = step(vec4(dot(offset + shadowMapTexelSize.zy, shadowPositionReceiverPlaneDepthBias),      // 01
                                         dot(offset + shadowMapTexelSize.xy, shadowPositionReceiverPlaneDepthBias),      // 11
                                         dot(offset + shadowMapTexelSize.xz, shadowPositionReceiverPlaneDepthBias),      // 10
                                         dot(offset, shadowPositionReceiverPlaneDepthBias)), sampleDistances);  // 00
#else
        vec4 sampleOccluders = step(vec4(0.0), sampleDistances);
#endif
        occludedCount += mix(mix(sampleOccluders.w, sampleOccluders.z, gradient.x), mix(sampleOccluders.x, sampleOccluders.y, gradient.x), gradient.y);
      }

      return occludedCount * (1.0 / float(SHADOW_TAP_COUNT));

    }  

  }

}  

float doCascadedShadowMapShadow(const in int cascadedShadowMapIndex, const in vec3 lightDirection) {
  float value = 1.0;
  shadowMapSize = (uCascadedShadowMaps.metaData.x == SHADOWMAP_MODE_PCF) ? vec2(textureSize(uCascadedShadowMapTextureShadow, 0).xy) :  vec2(textureSize(uCascadedShadowMapTexture, 0).xy);
  shadowMapTexelSize = vec3(vec2(1.0) / shadowMapSize, 0.0);
#ifdef UseReceiverPlaneDepthBias
  vec4 shadowPosition = cascadedShadowMapPositions[cascadedShadowMapIndex];
  shadowPositionReceiverPlaneDepthBias = computeReceiverPlaneDepthBias(shadowPosition.xyz); 
  shadowPosition.z -= min(2.0 * dot(shadowMapTexelSize.xy, abs(shadowPositionReceiverPlaneDepthBias)), 1e-2);
#else
  vec3 worldSpacePosition = getOffsetedBiasedWorldPositionForShadowMapping(uCascadedShadowMaps.constantBiasNormalBiasSlopeBiasClamp[cascadedShadowMapIndex], lightDirection);
  vec4 shadowPosition = uCascadedShadowMaps.shadowMapMatrices[cascadedShadowMapIndex] * vec4(worldSpacePosition, 1.0);
  shadowPosition = fma(shadowPosition / shadowPosition.w, vec2(0.5, 1.0).xxyy, vec2(0.5, 0.0).xxyy);
#endif
  if(all(greaterThanEqual(shadowPosition, vec4(0.0))) && all(lessThanEqual(shadowPosition, vec4(1.0)))){
    switch(uCascadedShadowMaps.metaData.x){
      case SHADOWMAP_MODE_PCF:{
        value = DoPCF(uCascadedShadowMapTextureShadow, cascadedShadowMapIndex, shadowPosition);
        break;
      }
      case SHADOWMAP_MODE_DPCF:{
        value = DoDPCF_PCSS(uCascadedShadowMapTexture, cascadedShadowMapIndex, shadowPosition, true);
        break;
      }
      case SHADOWMAP_MODE_PCSS:{
        value = DoDPCF_PCSS(uCascadedShadowMapTexture, cascadedShadowMapIndex, shadowPosition, false);
        break;
      }
      default:{
        break;
      }
    }
  }
  return value;
}

#else

float computeMSM(in vec4 moments, in float fragmentDepth, in float depthBias, in float momentBias) {
  vec4 b = mix(moments, vec4(0.5), momentBias);
  vec3 z;
  z[0] = fragmentDepth - depthBias;
  float L32D22 = fma(-b[0], b[1], b[2]);
  float D22 = fma(-b[0], b[0], b[1]);
  float squaredDepthVariance = fma(-b[1], b[1], b[3]);
  float D33D22 = dot(vec2(squaredDepthVariance, -L32D22), vec2(D22, L32D22));
  float InvD22 = 1.0 / D22;
  float L32 = L32D22 * InvD22;
  vec3 c = vec3(1.0, z[0], z[0] * z[0]);
  c[1] -= b.x;
  c[2] -= b.y + (L32 * c[1]);
  c[1] *= InvD22;
  c[2] *= D22 / D33D22;
  c[1] -= L32 * c[2];
  c[0] -= dot(c.yz, b.xy);
  float InvC2 = 1.0 / c[2];
  float p = c[1] * InvC2;
  float q = c[0] * InvC2;
  float D = (p * p * 0.25) - q;
  float r = sqrt(D);
  z[1] = (p * -0.5) - r;
  z[2] = (p * -0.5) + r;
  vec4 switchVal = (z[2] < z[0]) ? vec4(z[1], z[0], 1.0, 1.0) : ((z[1] < z[0]) ? vec4(z[0], z[1], 0.0, 1.0) : vec4(0.0));
  float quotient = (switchVal[0] * z[2] - b[0] * (switchVal[0] + z[2]) + b[1]) / ((z[2] - switchVal[1]) * (z[0] - z[1]));
  return 1.0 - clamp((switchVal[2] + (switchVal[3] * quotient)), 0.0, 1.0);
}

float linearStep(float a, float b, float v) {
  return clamp((v - a) / (b - a), 0.0, 1.0);  //
}

float reduceLightBleeding(float pMax, float amount) {
  return linearStep(amount, 1.0, pMax);  //
}

float getMSMShadowIntensity(vec4 moments, float depth, float depthBias, float momentBias) {
  vec4 b = mix(moments, vec4(0.5), momentBias);
  float                                                  //
      d = depth - depthBias,                             //
      l32d22 = fma(-b.x, b.y, b.z),                      //
      d22 = fma(-b.x, b.x, b.y),                         //
      squaredDepthVariance = fma(-b.y, b.y, b.w),        //
      d33d22 = dot(vec2(squaredDepthVariance, -l32d22),  //
                   vec2(d22, l32d22)),                   //
      invD22 = 1.0 / d22,                                //
      l32 = l32d22 * invD22;
  vec3 c = vec3(1.0, d - b.x, d * d);
  c.z -= b.y + (l32 * c.y);
  c.yz *= vec2(invD22, d22 / d33d22);
  c.y -= l32 * c.z;
  c.x -= dot(c.yz, b.xy);
  vec2 pq = c.yx / c.z;
  vec3 z = vec3(d, vec2(-(pq.x * 0.5)) + (vec2(-1.0, 1.0) * sqrt(((pq.x * pq.x) * 0.25) - pq.y)));
  vec4 s = (z.z < z.x) ? vec3(z.y, z.x, 1.0).xyzz : ((z.y < z.x) ? vec4(z.x, z.y, 0.0, 1.0) : vec4(0.0));
  return 1.0 - clamp((s.z + (s.w * ((((s.x * z.z) - (b.x * (s.x + z.z))) + b.y) / ((z.z - s.y) * (z.x - z.y))))), 0.0, 1.0); // * 1.03
}

float fastTanArcCos(const in float x){
  return sqrt(-fma(x, x, -1.0)) / x; // tan(acos(x)); sqrt(1.0 - (x * x)) / x 
}

float doCascadedShadowMapShadow(const in int cascadedShadowMapIndex, const in vec3 lightDirection) {
  mat4 shadowMapMatrix = uCascadedShadowMaps.shadowMapMatrices[cascadedShadowMapIndex];
  vec4 shadowNDC = shadowMapMatrix * vec4(inWorldSpacePosition, 1.0);
  shadowNDC /= shadowNDC.w;
  shadowNDC.xy = fma(shadowNDC.xy, vec2(0.5), vec2(0.5));
  if (all(greaterThanEqual(shadowNDC, vec4(0.0))) && all(lessThanEqual(shadowNDC, vec4(1.0)))) {
    vec4 moments = (textureLod(uCascadedShadowMapTexture, vec3(shadowNDC.xy, float(int(cascadedShadowMapIndex))), 0.0) +  //
                    vec2(-0.035955884801, 0.0).xyyy) *                                                                    //
                   mat4(0.2227744146, 0.0771972861, 0.7926986636, 0.0319417555,                                           //
                        0.1549679261, 0.1394629426, 0.7963415838, -0.172282317,                                           //
                        0.1451988946, 0.2120202157, 0.7258694464, -0.2758014811,                                          //
                        0.163127443, 0.2591432266, 0.6539092497, -0.3376131734);
    float depthBias = clamp(0.005 * fastTanArcCos(clamp(dot(workNormal, -lightDirection), -1.0, 1.0)), 0.0, 0.1) * 0.15;
    return clamp(reduceLightBleeding(getMSMShadowIntensity(moments, shadowNDC.z, depthBias, 3e-4), 0.25), 0.0, 1.0);
  } else {
    return 1.0;
  }
}

#endif
#endif
#endif

#ifdef NOBUFFERREFERENCE
#define material materials[inMaterialID]
//Material material = materials[inMaterialID];
#else
  #ifdef USEINT64
    Material material = uMaterials.materials[inMaterialID];
  #else
    Material material;
  #endif
#endif

const uint smPBRMetallicRoughness = 0u,  //
    smPBRSpecularGlossiness = 1u,        //
    smUnlit = 2u;                        //

#if defined(ALPHATEST) || defined(LOOPOIT) || defined(LOCKOIT) || defined(WBOIT) || defined(MBOIT) || defined(DFAOIT) || !defined(DEPTHONLY)

uvec2 textureFlags;
vec2 texCoords[2];
vec2 texCoords_dFdx[2];
vec2 texCoords_dFdy[2];

int getTexCoordID(const in int textureIndex){
  return material.textures[textureIndex]; 
}

vec2 textureUV(const in int textureIndex) {
  int textureID = getTexCoordID(textureIndex); 
  return (textureID >= 0) ? (material.textureTransforms[textureIndex] * vec3(texCoords[(textureID >> 16) & 0xf], 1.0)).xy : inTexCoord0;
}

ivec2 texture2DSize(const in int textureIndex) {
  int textureID = getTexCoordID(textureIndex); 
  return (textureID >= 0) ? ivec2(textureSize(u2DTextures[nonuniformEXT(textureID & 0x3fff)], 0).xy) : ivec2(0);
}

vec4 textureFetch(const in int textureIndex, const in vec4 defaultValue, const bool sRGB) {
  int textureID = getTexCoordID(textureIndex);
  if(textureID >= 0){
    int texCoordIndex = int((textureID >> 16) & 0xf); 
    mat3x2 m = material.textureTransforms[textureIndex];
    return textureGrad(u2DTextures[nonuniformEXT(((textureID & 0x3fff) << 1) | (int(sRGB) & 1))], //
                        (m * vec3(texCoords[texCoordIndex], 1.0)).xy,   //
                        (m * vec3(texCoords_dFdx[texCoordIndex], 0.0)).xy,  //
                        (m * vec3(texCoords_dFdy[texCoordIndex], 0.0)).xy);
 }else{
   return defaultValue;
 } 
}

#endif

void main() {
#ifdef VOXELIZATION
  if(any(lessThan(inWorldSpacePosition.xyz, inAABBMin.xyz)) || any(greaterThan(inWorldSpacePosition.xyz, vec3(inAABBMax.xyz))) || (uint(inClipMapIndex) >= uint(voxelGridData.countClipMaps))){
    return;
  }
#endif
  {
    float frontFacingSign = gl_FrontFacing ? 1.0 : -1.0;   
    workTangent = inTangent * frontFacingSign;
    workBitangent = inBitangent * frontFacingSign;
    workNormal = inNormal * frontFacingSign;
  }
#if !(defined(NOBUFFERREFERENCE) || defined(USEINT64))
  material = uMaterials.materials;
  {
    uvec2 materialPointer = uvec2(material);  
    uint carry;
    materialPointer.x = uaddCarry(materialPointer.x, uint(inMaterialID * uint(sizeof(Material))), carry);
    materialPointer.y += carry;
    material = Material(materialPointer);
  }
#endif
#if defined(ALPHATEST) || defined(LOOPOIT) || defined(LOCKOIT) || defined(WBOIT) || defined(MBOIT) || defined(DFAOIT) || !defined(DEPTHONLY)
  textureFlags = material.alphaCutOffFlagsTex0Tex1.zw;
  texCoords[0] = inTexCoord0;
  texCoords[1] = inTexCoord1;
  texCoords_dFdx[0] = dFdxFine(inTexCoord0);
  texCoords_dFdx[1] = dFdxFine(inTexCoord1);
  texCoords_dFdy[0] = dFdyFine(inTexCoord0);
  texCoords_dFdy[1] = dFdyFine(inTexCoord1);
#if !defined(VOXELIZATION)  
  /*if(!any(notEqual(inJitter.xy, vec2(0.0))))*/{
    texCoords[0] -= (texCoords_dFdx[0] * inJitter.x) + (texCoords_dFdy[0] * inJitter.y);
    texCoords[1] -= (texCoords_dFdx[1] * inJitter.x) + (texCoords_dFdy[1] * inJitter.y);
  }  
#endif
#endif
#ifndef DEPTHONLY
  envMapMaxLevelGGX = max(0.0, textureQueryLevels(uImageBasedLightingEnvMaps[0]) - 1.0);
  envMapMaxLevelCharlie = max(0.0, textureQueryLevels(uImageBasedLightingEnvMaps[1]) - 1.0);
  flags = material.alphaCutOffFlagsTex0Tex1.y;
  shadingModel = (flags >> 0u) & 0xfu;
#endif
#ifdef DEPTHONLY
#if defined(ALPHATEST) || defined(LOOPOIT) || defined(LOCKOIT) || defined(WBOIT) || defined(MBOIT) || defined(DFAOIT)
  float alpha = textureFetch(0, vec4(1.0), true).w * material.baseColorFactor.w * inColor0.w;
#endif
#else
  vec4 color = vec4(0.0);
#ifdef EXTRAEMISSIONOUTPUT
  vec4 emissionColor = vec4(0.0);
#endif
  float litIntensity = 1.0;
  switch (shadingModel) {
    case smPBRMetallicRoughness:
    case smPBRSpecularGlossiness: {
      vec4 diffuseColorAlpha = vec4(1.0);
      vec4 baseColor = vec4(1.0);
      float ior = material.iorIridescenceFactorIridescenceIorIridescenceThicknessMinimum.x;
      vec3 F0 = vec3((abs(ior - 1.5) < 1e-6) ? 0.04 : pow((ior - 1.0) / (ior + 1.0), 2.0));
      vec3 F90 = vec3(1.0);
      float perceptualRoughness = 1.0;
      float specularWeight = 1.0;
      switch (shadingModel) {
        case smPBRMetallicRoughness: {
          vec3 specularColorFactor = material.specularFactor.xyz;
          specularWeight = material.specularFactor.w;
          if ((flags & (1u << 9u)) != 0u) {
            specularWeight *= textureFetch(10, vec4(1.0), false).w;
            specularColorFactor *= textureFetch(11, vec4(1.0), true).xyz;
          }
          vec3 dielectricSpecularF0 = clamp(F0 * specularColorFactor, vec3(0.0), vec3(1.0));
          baseColor = textureFetch(0, vec4(1.0), true) * material.baseColorFactor;
          vec2 metallicRoughness = clamp(textureFetch(1, vec4(1.0), false).zy * material.metallicRoughnessNormalScaleOcclusionStrengthFactor.xy, vec2(0.0, 1e-3), vec2(1.0));
          diffuseColorAlpha = vec4(max(vec3(0.0), baseColor.xyz * (1.0 - metallicRoughness.x)), baseColor.w);
          F0 = mix(dielectricSpecularF0, baseColor.xyz, metallicRoughness.x);
          perceptualRoughness = metallicRoughness.y;
          break;
        }
        case smPBRSpecularGlossiness: {
          vec4 specularGlossiness = textureFetch(1, vec4(1.0), true) * vec4(material.specularFactor.xyz, material.metallicRoughnessNormalScaleOcclusionStrengthFactor.y);
          baseColor = textureFetch(0, vec4(1.0), true) * material.baseColorFactor;
          F0 = specularGlossiness.xyz;
          diffuseColorAlpha = vec4(baseColor.xyz * max(0.0, 1.0 - max(max(F0.x, F0.y), F0.z)), baseColor.w);
          perceptualRoughness = clamp(1.0 - specularGlossiness.w, 1e-3, 1.0);
          break;
        }
      }

#undef UseGeometryRoughness
#ifdef UseGeometryRoughness
      const float minimumRoughness = 0.0525;
      float geometryRoughness;
      {
        vec3 dxy = max(abs(dFdx(workNormal)), abs(dFdy(workNormal)));
        geometryRoughness = max(max(dxy.x, dxy.y), dxy.z);
      }

      perceptualRoughness = min(max(perceptualRoughness, minimumRoughness) + geometryRoughness, 1.0);
#else        
      // Vlachos 2015, "Advanced VR Rendering"
      // Kaplanyan 2016, "Stable specular highlights"
      // Tokuyoshi 2017, "Error Reduction and Simplification for Shading Anti-Aliasing"
      // Tokuyoshi and Kaplanyan 2019, "Improved Geometric Specular Antialiasing"
      // Tokuyoshi and Kaplanyan 2021, "Stable Geometric Specular Antialiasing with Projected-Space NDF Filtering"
      // ===========================================================================================================
      // In the original paper, this implementation is intended for deferred rendering, but here it is also used 
      // for forward rendering (as described in Tokuyoshi and Kaplanyan 2019 and 2021). This is mainly because 
      // the forward version requires an expensive transformation of the half-vector by the tangent frame for each
      // light. Thus, this is an approximation based on world-space normals, but it works well enough for what is 
      // needed and is an clearly improvement over the implementation based on Vlachos 2015.
      float kernelRoughness;
      {
        const float SIGMA2 = 0.15915494, KAPPA = 0.18;        
        vec3 dx = dFdx(workNormal), dy = dFdy(workNormal);
        kernelRoughness = min(KAPPA, (2.0 * SIGMA2) * (dot(dx, dx) + dot(dy, dy)));
        perceptualRoughness = sqrt(clamp((perceptualRoughness * perceptualRoughness) + kernelRoughness, 0.0, 1.0));
      }
#endif

      float alphaRoughness = perceptualRoughness * perceptualRoughness;

      vec3 normal;
      if ((textureFlags.x & (1 << 2)) != 0) {
        vec4 normalTexture = textureFetch(2, vec2(0.0, 1.0).xxyx, false);
        normal = normalize(                                                                                                                      //
            mat3(normalize(workTangent), normalize(workBitangent), normalize(workNormal)) *                                                            //
            normalize((normalTexture.xyz - vec3(0.5)) * (vec2(material.metallicRoughnessNormalScaleOcclusionStrengthFactor.z, 1.0).xxy * 2.0))  //
        );
      } else {
        normal = normalize(workNormal);
      }
      normal *= (((flags & (1u << 6u)) != 0u) && !gl_FrontFacing) ? -1.0 : 1.0;

      vec4 occlusionTexture = textureFetch(3, vec4(1.0), false);

      cavity = clamp(mix(1.0, occlusionTexture.x, material.metallicRoughnessNormalScaleOcclusionStrengthFactor.w), 0.0, 1.0);

      vec4 emissiveTexture = textureFetch(4, vec4(1.0), true);

      float transparency = 0.0;
      float refractiveAngle = 0.0;
      float shadow = 1.0;
      float screenSpaceAmbientOcclusion = 1.0;
  #if defined(ALPHATEST) || defined(LOOPOIT) || defined(LOCKOIT) || defined(WBOIT) || defined(MBOIT) || defined(DFAOIT) || defined(BLEND) || defined(ENVMAP)
      ambientOcclusion = 1.0;
  #else      
  #ifdef GLOBAL_ILLUMINATION_CASCADED_RADIANCE_HINTS
      screenSpaceAmbientOcclusion = texelFetch(uPassTextures[0], ivec3(gl_FragCoord.xy, int(gl_ViewIndex)), 0).x;
      ambientOcclusion = screenSpaceAmbientOcclusion;
      //ambientOcclusion = ((textureFlags.x & (1 << 3)) != 0) ? 1.0 : screenSpaceAmbientOcclusion;
  #else
      ambientOcclusion = ((textureFlags.x & (1 << 3)) != 0) ? 1.0 : texelFetch(uPassTextures[0], ivec3(gl_FragCoord.xy, int(gl_ViewIndex)), 0).x;
      screenSpaceAmbientOcclusion = ambientOcclusion;
  #endif
  #endif

      vec3 viewDirection = normalize(-inCameraRelativePosition);

      if ((flags & (1u << 10u)) != 0u) {
        iridescenceFresnel = F0;
        iridescenceF0 = F0;
        iridescenceFactor = material.iorIridescenceFactorIridescenceIorIridescenceThicknessMinimum.y * (((textureFlags.x & (1 << 12)) != 0) ? textureFetch(12, vec4(1.0), false).x : 1.0);
        iridescenceIor = material.iorIridescenceFactorIridescenceIorIridescenceThicknessMinimum.z;
        if ((textureFlags.x & (1 << 12)) != 0){
          iridescenceThickness = mix(material.iorIridescenceFactorIridescenceIorIridescenceThicknessMinimum.w, material.iridescenceThicknessMaximumTransmissionFactorVolumeThicknessFactorVolumeAttenuationDistance.x, textureFetch(13, vec4(1.0), false).y);  
        }else{
          iridescenceThickness = material.iridescenceThicknessMaximumTransmissionFactorVolumeThicknessFactorVolumeAttenuationDistance.x;  
        }
        if(iridescenceThickness == 0.0){
          iridescenceFactor = 0.0;
        }  
        if(iridescenceFactor > 0.0){
          float NdotV = clamp(dot(normal, viewDirection), 0.0, 1.0);
          iridescenceFresnel = evalIridescence(1.0, iridescenceIor, NdotV, iridescenceThickness, F0);
          iridescenceF0 = Schlick_to_F0(iridescenceFresnel, NdotV);          
        }
      }

#if defined(TRANSMISSION)
      if ((flags & (1u << 11u)) != 0u) {
        transmissionFactor = material.iridescenceThicknessMaximumTransmissionFactorVolumeThicknessFactorVolumeAttenuationDistance.y * (((textureFlags.x & (1 << 14)) != 0) ? textureFetch(14, vec4(1.0), false).x : 1.0);  
      }
      if ((flags & (1u << 12u)) != 0u) {
        volumeThickness = material.iridescenceThicknessMaximumTransmissionFactorVolumeThicknessFactorVolumeAttenuationDistance.z * (((textureFlags.x & (1 << 15)) != 0) ? textureFetch(15, vec4(1.0), false).y : 1.0);  
        volumeAttenuationDistance = material.iridescenceThicknessMaximumTransmissionFactorVolumeThicknessFactorVolumeAttenuationDistance.w;        
        volumeAttenuationColor = uintBitsToFloat(material.volumeAttenuationColorAnisotropyStrengthAnisotropyRotation.xyz);        
      }
#endif

      vec3 imageLightBasedLightDirection = vec3(0.0, 0.0, -1.0);

      vec3 sheenColor = vec3(0.0);
      float sheenRoughness = 0.0;
      if ((flags & (1u << 7u)) != 0u) {
        sheenColor = material.sheenColorFactorSheenRoughnessFactor.xyz;
        sheenRoughness = material.sheenColorFactorSheenRoughnessFactor.w;
        if ((textureFlags.x & (1 << 5)) != 0) {
          sheenColor *= textureFetch(5, vec4(1.0), true).xyz;
        }
        if ((textureFlags.x & (1 << 6)) != 0) {
          sheenRoughness *= textureFetch(6, vec4(1.0), true).x;
        }
#undef UseGeometryRoughness
#ifdef UseGeometryRoughness
        sheenRoughness = min(max(sheenRoughness, minimumRoughness) + geometryRoughness, 1.0);
#else        
        // Vlachos 2015, "Advanced VR Rendering"
        // Kaplanyan 2016, "Stable specular highlights"
        // Tokuyoshi 2017, "Error Reduction and Simplification for Shading Anti-Aliasing"
        // Tokuyoshi and Kaplanyan 2019, "Improved Geometric Specular Antialiasing"
        // Tokuyoshi and Kaplanyan 2021, "Stable Geometric Specular Antialiasing with Projected-Space NDF Filtering"
        // ===========================================================================================================
        // In the original paper, this implementation is intended for deferred rendering, but here it is also used 
        // for forward rendering (as described in Tokuyoshi and Kaplanyan 2019 and 2021). This is mainly because 
        // the forward version requires an expensive transformation of the half-vector by the tangent frame for each
        // light. Thus, this is an approximation based on world-space normals, but it works well enough for what is 
        // needed and is an clearly improvement over the implementation based on Vlachos 2015.
        float kernelRoughness;
        {
          const float SIGMA2 = 0.15915494, KAPPA = 0.18;        
          vec3 dx = dFdx(workNormal), dy = dFdy(workNormal);
          kernelRoughness = min(KAPPA, (2.0 * SIGMA2) * (dot(dx, dx) + dot(dy, dy)));
          sheenRoughness = sqrt(clamp((sheenRoughness * sheenRoughness) + kernelRoughness, 0.0, 1.0));
        }
#endif
        sheenRoughness = max(sheenRoughness, 1e-7);
      }

      vec3 clearcoatF0 = vec3(0.04);
      vec3 clearcoatF90 = vec3(0.0);
      vec3 clearcoatNormal = normal;
      float clearcoatFactor = 1.0;
      float clearcoatRoughness = 1.0;
      if ((flags & (1u << 8u)) != 0u) {
        clearcoatFactor = material.clearcoatFactorClearcoatRoughnessFactor.x;
        clearcoatRoughness = material.clearcoatFactorClearcoatRoughnessFactor.y;
        if ((textureFlags.x & (1 << 7)) != 0) {
          clearcoatFactor *= textureFetch(7, vec4(1.0), false).x;
        }
        if ((textureFlags.x & (1 << 8)) != 0) {
          clearcoatRoughness *= textureFetch(8, vec4(1.0), false).y;
        }
        if ((textureFlags.x & (1 << 9)) != 0) {
          vec4 normalTexture = textureFetch(9, vec2(0.0, 1.0).xxyx, false);
          clearcoatNormal = normalize(mat3(normalize(workTangent), normalize(workBitangent), normalize(workNormal)) * normalize((normalTexture.xyz - vec3(0.5)) * (vec2(material.metallicRoughnessNormalScaleOcclusionStrengthFactor.z, 1.0).xxy * 2.0)));
        } else {
          clearcoatNormal = normalize(workNormal);
        }
        clearcoatNormal *= (((flags & (1u << 6u)) != 0u) && !gl_FrontFacing) ? -1.0 : 1.0;
#ifdef UseGeometryRoughness        
        clearcoatRoughness = min(max(clearcoatRoughness, minimumRoughness) + geometryRoughness, 1.0);
#else
        {
          clearcoatRoughness = sqrt(clamp((clearcoatRoughness * clearcoatRoughness) + kernelRoughness, 0.0, 1.0));
        }
#endif
      }

      specularOcclusion = getSpecularOcclusion(clamp(dot(normal, viewDirection), 0.0, 1.0), cavity * ambientOcclusion, alphaRoughness);

#ifdef ENABLE_ANISOTROPIC
      if (anisotropyActive = ((flags & (1u << 13u)) != 0u)) {
        vec2 ansitropicStrengthAnsitropicRotation = unpackHalf2x16(material.volumeAttenuationColorAnisotropyStrengthAnisotropyRotation.w);        
        vec2 directionRotation = vec2(sin(vec2(ansitropicStrengthAnsitropicRotation.y) + vec2(1.5707963267948966, 0.0)));
        mat2 rotationMatrix = mat2(directionRotation.x, directionRotation.y, -directionRotation.y, directionRotation.x);
        vec3 anisotropySample = textureFetch(16, vec4(1.0, 0.5, 1.0, 1.0), false).xyz;
        vec2 direction = rotationMatrix * fma(anisotropySample.xy, vec2(2.0), vec2(-1.0));
        anisotropyT = mat3(workTangent, workBitangent, normal) * normalize(vec3(direction, 0.0));
        anisotropyB = cross(workNormal, anisotropyT);
        anisotropyStrength = clamp(ansitropicStrengthAnsitropicRotation.x * anisotropySample.z, 0.0, 1.0);
        alphaRoughnessAnisotropyT = mix(alphaRoughness, 1.0, anisotropyStrength * anisotropyStrength);
        alphaRoughnessAnisotropyB = clamp(alphaRoughness, 1e-3, 1.0);
        anisotropyTdotV = dot(anisotropyT, viewDirection);
        anisotropyBdotV = dot(anisotropyB, viewDirection);   
      }
#endif

#ifdef LIGHTS
#if defined(REFLECTIVESHADOWMAPOUTPUT)
      if(lights[0].metaData.x == 4u){ // Only the first light is supported for RSMs, and only when it is the primary directional light 
        for(int lightIndex = 0; lightIndex < 1; lightIndex++){
          {
            Light light = lights[lightIndex];
#elif defined(LIGHTCLUSTERS)
      // Light cluster grid
      uvec3 clusterXYZ = uvec3(uvec2(uvec2(gl_FragCoord.xy) / uFrustumClusterGridGlobals.tileSizeZNearZFar.xy), 
                               uint(clamp(fma(log2(-inViewSpacePosition.z), uFrustumClusterGridGlobals.scaleBiasMax.x, uFrustumClusterGridGlobals.scaleBiasMax.y), 0.0, uFrustumClusterGridGlobals.scaleBiasMax.z)));
      uint clusterIndex = clamp((((clusterXYZ.z * uFrustumClusterGridGlobals.clusterSize.y) + clusterXYZ.y) * uFrustumClusterGridGlobals.clusterSize.x) + clusterXYZ.x, 0u, uFrustumClusterGridGlobals.countLightsViewIndexSizeOffsetedViewIndex.z) +
                          (uint(gl_ViewIndex + uFrustumClusterGridGlobals.countLightsViewIndexSizeOffsetedViewIndex.w) * uFrustumClusterGridGlobals.countLightsViewIndexSizeOffsetedViewIndex.z);
      uvec2 clusterData = frustumClusterGridData[clusterIndex].xy; // x = index, y = count and ignore decal data for now  
      for(uint clusterLightIndex = clusterData.x, clusterCountLights = clusterData.y; clusterCountLights > 0u; clusterLightIndex++, clusterCountLights--){
        {
          {
            Light light = lights[frustumClusterGridIndexList[clusterLightIndex]];
#else
      // Light BVH
      uint lightTreeNodeIndex = 0;
      uint lightTreeNodeCount = lightTreeNodes[0].aabbMinSkipCount.w;
      while (lightTreeNodeIndex < lightTreeNodeCount) {
        LightTreeNode lightTreeNode = lightTreeNodes[lightTreeNodeIndex];
        vec3 aabbMin = vec3(uintBitsToFloat(uvec3(lightTreeNode.aabbMinSkipCount.xyz)));
        vec3 aabbMax = vec3(uintBitsToFloat(uvec3(lightTreeNode.aabbMaxUserData.xyz)));
        if (all(greaterThanEqual(inWorldSpacePosition.xyz, aabbMin)) && all(lessThanEqual(inWorldSpacePosition.xyz, aabbMax))) {
          if (lightTreeNode.aabbMaxUserData.w != 0xffffffffu) {
            Light light = lights[lightTreeNode.aabbMaxUserData.w];
#endif
            float lightAttenuation = 1.0;
            vec3 lightDirection;
            vec3 lightPosition = light.positionRange.xyz; 
            vec3 lightVector = lightPosition - inWorldSpacePosition.xyz;
            vec3 normalizedLightVector = normalize(lightVector);
#ifdef SHADOWS
#if !defined(REFLECTIVESHADOWMAPOUTPUT)
            if (/*(uShadows != 0) &&*/ ((light.metaData.y & 0x80000000u) == 0u) && (uCascadedShadowMaps.metaData.x != SHADOWMAP_MODE_NONE)) {
              switch (light.metaData.x) {
#if !defined(REFLECTIVESHADOWMAPOUTPUT)
#if 0
                case 1u: { // Directional 
                  // imageLightBasedLightDirection = light.directionZFar.xyz;
                  // fall-through
                }
                case 3u: {  // Spot
                  vec4 shadowNDC = light.shadowMapMatrix * vec4(inWorldSpacePosition, 1.0);                  
                  shadowNDC /= shadowNDC.w;
                  if (all(greaterThanEqual(shadowNDC, vec4(-1.0))) && all(lessThanEqual(shadowNDC, vec4(1.0)))) {
                    shadowNDC.xyz = fma(shadowNDC.xyz, vec3(0.5), vec3(0.5));
                    vec4 moments = (textureLod(uNormalShadowMapArrayTexture, vec3(shadowNDC.xy, float(int(light.metaData.y))), 0.0) + vec2(-0.035955884801, 0.0).xyyy) * mat4(0.2227744146, 0.0771972861, 0.7926986636, 0.0319417555, 0.1549679261, 0.1394629426, 0.7963415838, -0.172282317, 0.1451988946, 0.2120202157, 0.7258694464, -0.2758014811, 0.163127443, 0.2591432266, 0.6539092497, -0.3376131734);
                    lightAttenuation *= reduceLightBleeding(getMSMShadowIntensity(moments, shadowNDC.z, 5e-3, 1e-2), 0.0);
                  }
                  break;
                }
                case 2u: {  // Point
                  float znear = 1e-2, zfar = max(1.0, light.directionZFar.w);
                  vec3 vector = light.positionRange.xyz - inWorldSpacePosition;
                  vec4 moments = (textureLod(uCubeMapShadowMapArrayTexture, vec4(vec3(normalize(vector)), float(int(light.metaData.y))), 0.0) + vec2(-0.035955884801, 0.0).xyyy) * mat4(0.2227744146, 0.0771972861, 0.7926986636, 0.0319417555, 0.1549679261, 0.1394629426, 0.7963415838, -0.172282317, 0.1451988946, 0.2120202157, 0.7258694464, -0.2758014811, 0.163127443, 0.2591432266, 0.6539092497, -0.3376131734);
                  lightAttenuation *= reduceLightBleeding(getMSMShadowIntensity(moments, clamp((length(vector) - znear) / (zfar - znear), 0.0, 1.0), 5e-3, 1e-2), 0.0);
                  break;
                }
#endif
#endif
                case 4u: {  // Primary directional
                  imageLightBasedLightDirection = light.directionZFar.xyz;
                  litIntensity = lightAttenuation;
                  float viewSpaceDepth = -inViewSpacePosition.z;
#ifdef UseReceiverPlaneDepthBias
                  // Outside of doCascadedShadowMapShadow as an own loop, for the reason, that the partial derivative based
                  // computeReceiverPlaneDepthBias function can work correctly then, when all cascaded shadow map slice
                  // position are already known in advance, and always at any time and at any real current cascaded shadow 
                  // map slice. Because otherwise one can see dFdx/dFdy caused artefacts on cascaded shadow map border
                  // transitions.  
                  {
                    const vec3 lightDirection = -light.directionZFar.xyz;
                    for(int cascadedShadowMapIndex = 0; cascadedShadowMapIndex < NUM_SHADOW_CASCADES; cascadedShadowMapIndex++){
                      vec3 worldSpacePosition = getOffsetedBiasedWorldPositionForShadowMapping(uCascadedShadowMaps.constantBiasNormalBiasSlopeBiasClamp[cascadedShadowMapIndex], lightDirection);
                      vec4 shadowPosition = uCascadedShadowMaps.shadowMapMatrices[cascadedShadowMapIndex] * vec4(worldSpacePosition, 1.0);
                      shadowPosition = fma(shadowPosition / shadowPosition.w, vec2(0.5, 1.0).xxyy, vec2(0.5, 0.0).xxyy);
                      cascadedShadowMapPositions[cascadedShadowMapIndex] = shadowPosition;
                    }
                  }
#endif
                  for (int cascadedShadowMapIndex = 0; cascadedShadowMapIndex < NUM_SHADOW_CASCADES; cascadedShadowMapIndex++) {
                    vec2 shadowMapSplitDepth = uCascadedShadowMaps.shadowMapSplitDepthsScales[cascadedShadowMapIndex].xy;
                    if ((viewSpaceDepth >= shadowMapSplitDepth.x) && (viewSpaceDepth <= shadowMapSplitDepth.y)) {
                      float shadow = doCascadedShadowMapShadow(cascadedShadowMapIndex, -light.directionZFar.xyz);
                      int nextCascadedShadowMapIndex = cascadedShadowMapIndex + 1;
                      if (nextCascadedShadowMapIndex < NUM_SHADOW_CASCADES) {
                        vec2 nextShadowMapSplitDepth = uCascadedShadowMaps.shadowMapSplitDepthsScales[nextCascadedShadowMapIndex].xy;
                        if ((viewSpaceDepth >= nextShadowMapSplitDepth.x) && (viewSpaceDepth <= nextShadowMapSplitDepth.y)) {
                          float splitFade = smoothstep(nextShadowMapSplitDepth.x, shadowMapSplitDepth.y, viewSpaceDepth);
                          if (splitFade > 0.0) {
                            shadow = mix(shadow, doCascadedShadowMapShadow(nextCascadedShadowMapIndex, -light.directionZFar.xyz), splitFade);
                          }
                        }
                      }
                      lightAttenuation *= shadow;
                      break;
                    }
                  }
                  break;
                }
              }
#if 0              
              if (lightIndex == 0) {
                litIntensity = lightAttenuation;
              }
#endif
            }
#endif
            float lightAttenuationEx = lightAttenuation;
#endif
            switch (light.metaData.x) {
#if !defined(REFLECTIVESHADOWMAPOUTPUT)
              case 1u: {  // Directional
                lightDirection = -light.directionZFar.xyz;
                break;
              }
              case 2u: {  // Point
                lightDirection = normalizedLightVector;
                break;
              }
              case 3u: {  // Spot
#if 1
                float angularAttenuation = clamp(fma(dot(normalize(light.directionZFar.xyz), -normalizedLightVector), uintBitsToFloat(light.metaData.z), uintBitsToFloat(light.metaData.w)), 0.0, 1.0);
#else
                // Just for as reference
                float innerConeCosinus = uintBitsToFloat(light.metaData.z);
                float outerConeCosinus = uintBitsToFloat(light.metaData.w);
                float actualCosinus = dot(normalize(light.directionZFar.xyz), -normalizedLightVector);
                float angularAttenuation = mix(0.0, mix(smoothstep(outerConeCosinus, innerConeCosinus, actualCosinus), 1.0, step(innerConeCosinus, actualCosinus)), step(outerConeCosinus, actualCosinus));
#endif
                lightAttenuation *= angularAttenuation * angularAttenuation;
                lightDirection = normalizedLightVector;
                break;
              }
#endif
              case 4u: {  // Primary directional
                imageLightBasedLightDirection = lightDirection = -light.directionZFar.xyz;
                break;
              }
              default: {
                continue;
              }
            }
#if !defined(REFLECTIVESHADOWMAPOUTPUT)
            switch (light.metaData.x) {
              case 2u:    // Point
              case 3u: {  // Spot
                if (light.positionRange.w >= 0.0) {
                  float currentDistance = length(lightVector);
                  if (currentDistance > 0.0) {
                    lightAttenuation *= 1.0 / (currentDistance * currentDistance);
                    if (light.positionRange.w > 0.0) {
                      float distanceByRange = currentDistance / light.positionRange.w;
                      lightAttenuation *= clamp(1.0 - (distanceByRange * distanceByRange * distanceByRange * distanceByRange), 0.0, 1.0);
                    }
                  }
                }
                break;
              }
            }
#endif
            if((lightAttenuation > 0.0) || ((flags & ((1u << 7u) | (1u << 8u))) != 0u)){
#if defined(REFLECTIVESHADOWMAPOUTPUT)
              diffuseOutput += lightAttenuation * light.colorIntensity.xyz * light.colorIntensity.w * diffuseColorAlpha.xyz * max(0.0, dot(normal, lightDirection));
//#elif defined(VOXELIZATION)
//             diffuseOutput += lightAttenuation * light.colorIntensity.xyz * light.colorIntensity.w * diffuseColorAlpha.xyz * max(0.0, dot(normal, lightDirection));
#else
              doSingleLight(light.colorIntensity.xyz * light.colorIntensity.w,  //
                            vec3(lightAttenuation),                             //
                            lightDirection,                                     //
                            normal.xyz,                                         //
                            diffuseColorAlpha.xyz,                              //
                            F0,                                                 //
                            F90,                                                //
                            viewDirection,                                      //
                            refractiveAngle,                                    //
                            transparency,                                       //
                            alphaRoughness,                                     //
                            cavity,                                             //
                            sheenColor,                                         //
                            sheenRoughness,                                     //
                            clearcoatNormal,                                    //
                            clearcoatF0,                                        //
                            clearcoatRoughness,                                 //
                            specularWeight);                                    //
#endif
#ifdef TRANSMISSION
              if ((flags & (1u << 11u)) != 0u) {
                // If the light ray travels through the geometry, use the point it exits the geometry again.
                // That will change the angle to the light source, if the material refracts the light ray.
                vec3 transmissionRay = getVolumeTransmissionRay(normal.xyz, viewDirection, volumeThickness, ior);
                vec3 pointToLight = ((light.metaData.x == 0) ? lightDirection : lightVector) - transmissionRay;
                vec3 normalizedLightVector = normalize(pointToLight);
                float lightAttenuation = lightAttenuationEx;
                switch (light.metaData.x) {
                  case 3u: {  // Spot
    #if 1
                    float angularAttenuation = clamp(fma(dot(normalize(light.directionZFar.xyz), -normalizedLightVector), uintBitsToFloat(light.metaData.z), uintBitsToFloat(light.metaData.w)), 0.0, 1.0);
    #else
                    // Just for as reference
                    float innerConeCosinus = uintBitsToFloat(light.metaData.z);
                    float outerConeCosinus = uintBitsToFloat(light.metaData.w);
                    float actualCosinus = dot(normalize(light.directionZFar.xyz), -normalizedLightVector);
                    float angularAttenuation = mix(0.0, mix(smoothstep(outerConeCosinus, innerConeCosinus, actualCosinus), 1.0, step(innerConeCosinus, actualCosinus)), step(outerConeCosinus, actualCosinus));
    #endif
                    lightAttenuation *= angularAttenuation * angularAttenuation;
                    lightDirection = normalizedLightVector;
                    break;
                  }
                }
                switch (light.metaData.x) {
                  case 2u:    // Point
                  case 3u: {  // Spot
                    if (light.positionRange.w >= 0.0) {
                      float currentDistance = length(pointToLight);
                      if (currentDistance > 0.0) {
                        lightAttenuation *= 1.0 / (currentDistance * currentDistance);
                        if (light.positionRange.w > 0.0) {
                          float distanceByRange = currentDistance / light.positionRange.w;
                          lightAttenuation *= clamp(1.0 - (distanceByRange * distanceByRange * distanceByRange * distanceByRange), 0.0, 1.0);
                        }
                      }
                    }
                    break;
                  }
                }
                vec3 transmittedLight = lightAttenuation * getPunctualRadianceTransmission(normal.xyz, viewDirection, normalizedLightVector, alphaRoughness, F0, F90, diffuseColorAlpha.xyz, ior);
                if ((flags & (1u << 12u)) != 0u) {
                  transmittedLight = applyVolumeAttenuation(transmittedLight, length(transmissionRay), volumeAttenuationColor, volumeAttenuationDistance);
                }
                transmissionOutput += transmittedLight;
              }
#endif
            }
#if defined(REFLECTIVESHADOWMAPOUTPUT)
          }
        }
      }
#elif defined(LIGHTCLUSTERS)
          }
        }
      }
#else
          }
          lightTreeNodeIndex++;
        } else {
          lightTreeNodeIndex += max(1u, lightTreeNode.aabbMinSkipCount.w);
        }
      }
#endif
/*    if (lightTreeNodeIndex == 0u) {
        doSingleLight(vec3(1.7, 1.15, 0.70),              //
                      vec3(1.0),                          //
                      normalize(-vec3(0.5, -1.0, -1.0)),  //
                      normal.xyz,                         //
                      diffuseColorAlpha.xyz,              //
                      F0,                                 //
                      F90,                                //
                      viewDirection,                      //
                      refractiveAngle,                    //
                      transparency,                       //
                      alphaRoughness,                     //
                      cavity,                             //
                      sheenColor,                         //
                      sheenRoughness,                     //
                      clearcoatNormal,                    //
                      clearcoatF0,                        //
                      clearcoatRoughness,                 //
                      specularWeight);                    //
      }*/
#elif 1
#if !defined(VOXELIZATION)  
      doSingleLight(vec3(1.7, 1.15, 0.70),              //
                    vec3(1.0),                          //
                    normalize(-vec3(0.5, -1.0, -1.0)),  //
                    normal.xyz,                         //
                    diffuseColorAlpha.xyz,              //
                    F0,                                 //
                    F90,                                //
                    viewDirection,                      //
                    refractiveAngle,                    //
                    transparency,                       //
                    alphaRoughness,                     //
                    cavity,                             //
                    sheenColor,                         //
                    sheenRoughness,                     //
                    clearcoatNormal,                    //
                    clearcoatF0,                        //
                    clearcoatRoughness,                 //
                    specularWeight);                    //
#endif
#endif
#ifdef GLOBAL_ILLUMINATION_CASCADED_RADIANCE_HINTS
      {
        vec3 volumeSphericalHarmonics[9];
        globalIlluminationVolumeLookUp(volumeSphericalHarmonics, inWorldSpacePosition.xyz, vec3(0.0), normal.xyz);
        vec3 shAmbient = vec3(0.0), shDominantDirectionalLightColor = vec3(0.0), shDominantDirectionalLightDirection = vec3(0.0);
        globalIlluminationSphericalHarmonicsExtractAndSubtract(volumeSphericalHarmonics, shAmbient, shDominantDirectionalLightColor, shDominantDirectionalLightDirection);
        vec3 shResidualDiffuse = max(vec3(0.0), globalIlluminationDecodeColor(globalIlluminationCompressedSphericalHarmonicsDecodeWithCosineLobe(normal, volumeSphericalHarmonics)));
        diffuseOutput += shResidualDiffuse * baseColor.xyz * screenSpaceAmbientOcclusion * cavity;
        doSingleLight(shDominantDirectionalLightColor,                    //
                      vec3(screenSpaceAmbientOcclusion * cavity),         //
                      -shDominantDirectionalLightDirection,               //
                      normal.xyz,                                         //
                      diffuseColorAlpha.xyz,                              //
                      F0,                                                 //
                      F90,                                                //
                      viewDirection,                                      //
                      refractiveAngle,                                    //
                      transparency,                                       //
                      alphaRoughness,                                     //
                      cavity,                                             //
                      sheenColor,                                         //
                      sheenRoughness,                                     //
                      clearcoatNormal,                                    //
                      clearcoatF0,                                        //
                      clearcoatRoughness,                                 //
                      specularWeight);                                    //
      }
#endif
#if !defined(REFLECTIVESHADOWMAPOUTPUT) 
#if !defined(GLOBAL_ILLUMINATION_CASCADED_RADIANCE_HINTS)
      float iblWeight = 1.0; // for future sky occulsion 
      diffuseOutput += getIBLRadianceLambertian(normal, viewDirection, perceptualRoughness, diffuseColorAlpha.xyz, F0, specularWeight) * iblWeight;
      specularOutput += getIBLRadianceGGX(normal, perceptualRoughness, F0, specularWeight, viewDirection, litIntensity, imageLightBasedLightDirection) * iblWeight;
      if ((flags & (1u << 7u)) != 0u) {
        sheenOutput += getIBLRadianceCharlie(normal, viewDirection, sheenRoughness, sheenColor) * iblWeight;
      }
      if ((flags & (1u << 8u)) != 0u) {
        clearcoatOutput += getIBLRadianceGGX(clearcoatNormal, clearcoatRoughness, clearcoatF0.xyz, 1.0, viewDirection, litIntensity, imageLightBasedLightDirection) * iblWeight;
        clearcoatFresnel = F_Schlick(clearcoatF0, clearcoatF90, clamp(dot(clearcoatNormal, viewDirection), 0.0, 1.0)) * iblWeight;
      }
#endif
#if defined(TRANSMISSION)
      if ((flags & (1u << 11u)) != 0u) {
        transmissionOutput += getIBLVolumeRefraction(normal.xyz, viewDirection,
                                                     perceptualRoughness,
                                                     diffuseColorAlpha.xyz, F0, F90,
                                                     inWorldSpacePosition,
                                                     ior, 
                                                     volumeThickness, 
                                                     volumeAttenuationColor, 
                                                     volumeAttenuationDistance);        
      }
#endif
#endif
#if defined(REFLECTIVESHADOWMAPOUTPUT)
      vec3 emissiveOutput = vec3(0.0); // No emissive output for RSMs
#else
      vec3 emissiveOutput = emissiveTexture.xyz * material.emissiveFactor.xyz * material.emissiveFactor.w;
#endif
      color = vec2(0.0, diffuseColorAlpha.w).xxxy;
#ifndef EXTRAEMISSIONOUTPUT
      color.xyz += emissiveOutput;
#endif
#if defined(TRANSMISSION)
      color.xyz += mix(diffuseOutput, transmissionOutput, transmissionFactor);
#else
      color.xyz += diffuseOutput;
#endif
#if defined(GLOBAL_ILLUMINATION_CASCADED_RADIANCE_HINTS)
#if 0
      color.xyz += globalIlluminationCascadeVisualizationColor(inWorldSpacePosition).xyz;
#endif
#endif
      color.xyz += specularOutput;
      color.xyz = fma(color.xyz, vec3(albedoSheenScaling), sheenOutput);
      color.xyz = fma(color.xyz, vec3(1.0 - (clearcoatFactor * clearcoatFresnel)), clearcoatOutput);
#ifdef EXTRAEMISSIONOUTPUT
      emissionColor.xyz = emissiveOutput * (1.0 - (clearcoatFactor * clearcoatFresnel));
#endif
      break;
    }
    case smUnlit: {
      color = textureFetch(0, vec4(1.0), true) * material.baseColorFactor * vec2((litIntensity * 0.25) + 0.75, 1.0).xxxy;
      break;
    }
  }
  float alpha = color.w * inColor0.w, outputAlpha = ((flags & 32) != 0) ? (color.w * inColor0.w) : 1.0; // AMD GPUs under Linux doesn't like mix(1.0, color.w * inColor0.w, float(int(uint((flags >> 5u) & 1u)))); due to the unsigned int stuff
  vec4 finalColor = vec4(color.xyz * inColor0.xyz, outputAlpha);
#if !(defined(WBOIT) || defined(MBOIT) || defined(VOXELIZATION))
#ifndef BLEND 
  outFragColor = finalColor;
#endif
#ifdef EXTRAEMISSIONOUTPUT
  outFragEmission = vec4(emissionColor.xyz * inColor0.xyz, outputAlpha);
#endif
#endif
#endif

#if defined(ALPHATEST)
  #if defined(NODISCARD)  
    float fragDepth;
  #endif
  if (alpha < uintBitsToFloat(material.alphaCutOffFlagsTex0Tex1.x)) {
  #if defined(WBOIT) || defined(LOCKOIT) || defined(DFAOIT) || defined(LOCKOIT_PASS2)
    finalColor = vec4(alpha = 0.0);    
  #elif defined(LOCKOIT_PASS1)
    alpha = 0.0;    
  #elif defined(MBOIT)
    #if defined(MBOIT) && defined(MBOITPASS1)    
      alpha = 0.0;    
    #else
      finalColor = vec4(alpha = 0.0);    
    #endif
  #else 
    #if defined(NODISCARD)  
      // Workaround for Intel (i)GPUs, which've problems with discarding fragments in 2x2 fragment blocks at alpha-test usage
#ifdef USE_SPECIALIZATION_CONSTANTS
      fragDepth = UseReversedZ ? -0.1 : 1.1;      
#else
      #if defined(REVERSEDZ)
        fragDepth = -0.1;
      #else
        fragDepth = 1.1;
      #endif
#endif
    #else
      #if defined(USEDEMOTE)
        demote;
      #else
        discard;
      #endif
    #endif
  #endif
  }else{
  #if defined(NODISCARD)  
    fragDepth = gl_FragCoord.z;
  #endif
  #if defined(WBOIT) || defined(MBOIT) || defined(LOCKOIT) || defined(LOOPOIT) || defined(DFAOIT)
    #if defined(WBOIT) || defined(LOCKOIT) || defined(LOOPOIT_PASS2) || defined(DFAOIT)
      finalColor.w = alpha = 1.0;    
    #elif defined(LOOPOIT_PASS1)
      alpha = 1.0;    
    #elif defined(MBOIT) && defined(MBOITPASS1)    
      alpha = 1.0;    
    #else
      finalColor.w = alpha = 1.0;    
    #endif
  #endif
  }
  #if defined(NODISCARD)  
    gl_FragDepth = fragDepth;
  #endif
  #if !(defined(WBOIT) || defined(MBOIT) || defined(LOCKOIT) || defined(LOOPOIT) || defined(DFAOIT))
    #ifdef MSAA
      #if 0
        vec2 alphaTextureSize = vec2(texture2DSize(0));
        vec2 alphaTextureUV = textureUV(0) * alphaTextureSize;
        vec4 alphaDUV = vec4(vec2(dFdx(alphaTextureUV)), vec2(dFdy(alphaTextureUV)));
        alpha *= 1.0 + (max(0.0, max(dot(alphaDUV.xy, alphaDUV.xy), dot(alphaDUV.zw, alphaDUV.zw)) * 0.5) * 0.25);
      #endif
      #if 1
        alpha = clamp(((alpha - uintBitsToFloat(material.alphaCutOffFlagsTex0Tex1.x)) / max(fwidth(alpha), 1e-4)) + 0.5, 0.0, 1.0);
      #endif  
      if (alpha < 1e-2) {
        alpha = 0.0;
      }
      #ifndef DEPTHONLY  
        outFragColor.w = finalColor.w = alpha;
      #endif
    #endif
  #endif
#endif

#if !defined(VOXELIZATION)
  const bool additiveBlending = false; // Mesh does never use additive blending currently, so static compile time constant folding is possible here.
   
#define TRANSPARENCY_IMPLEMENTATION
#include "transparency.glsl"
#undef TRANSPARENCY_IMPLEMENTATION

#if defined(VELOCITY)
  outFragVelocity = (((inCurrentClipSpace.xy / inCurrentClipSpace.w) - inJitter.xy) - ((inPreviousClipSpace.xy / inPreviousClipSpace.w) - inJitter.zw)) * 0.5;

  vec3 normal = normalize(workNormal);
/*normal /= (abs(normal.x) + abs(normal.y) + abs(normal.z));
  outFragNormal = vec4(vec3(fma(normal.xx, vec2(0.5, -0.5), vec2(fma(normal.y, 0.5, 0.5))), clamp(normal.z * 3.402823e+38, 0.0, 1.0)), 1.0);*/
  outFragNormal = vec4(vec3(fma(normal.xyz, vec3(0.5), vec3(0.5))), 1.0);  

#elif defined(REFLECTIVESHADOWMAPOUTPUT)

  vec3 normal = normalize(workNormal);
/*normal /= (abs(normal.x) + abs(normal.y) + abs(normal.z));
  outFragNormalUsed = vec4(vec3(fma(normal.xx, vec2(0.5, -0.5), vec2(fma(normal.y, 0.5, 0.5))), clamp(normal.z * 3.402823e+38, 0.0, 1.0)), 1.0);*/  
  outFragNormalUsed = vec4(vec3(fma(normal.xyz, vec3(0.5), vec3(0.5))), 1.0);  

  //outFragPosition = inWorldSpacePosition.xyz;

#endif
#endif

#ifdef VOXELIZATION
  vec4 clipMap = voxelGridData.clipMaps[inClipMapIndex];

  uint voxelGridSize = uint(clipMap.w);
  
  uvec3 volumePosition = ivec3((inWorldSpacePosition - float(clipMap.xyz)) / float(clipMap.w)); 

  if(all(greaterThanEqual(volumePosition, ivec3(0))) && all(lessThan(volumePosition, ivec3(voxelGridSize)))){

    uint volumeBaseIndex = ((((((uint(inClipMapIndex) * voxelGridSize) + uint(volumePosition.z)) * voxelGridSize) + uint(volumePosition.y)) * voxelGridSize) + uint(volumePosition.x)) * 6;

    uint countAnisotropicAxisDirectionSides;

    uvec3 anisotropicAxisDirectionSideOffsets[2];

    if((flags & (1u << 6u)) != 0u){
      countAnisotropicAxisDirectionSides = 2u; // Double-sided
      anisotropicAxisDirectionSideOffsets[0] = uvec3(0u, 1u, 2u);
      anisotropicAxisDirectionSideOffsets[1] = uvec3(3u, 4u, 5u);
    }else{
      countAnisotropicAxisDirectionSides = 1u; // Single-sided
      anisotropicAxisDirectionSideOffsets[0] = uvec3(
        (workNormal.x > 0.0) ? 0u : 3u, 
        (workNormal.y > 0.0) ? 1u : 4u, 
        (workNormal.z > 0.0) ? 2u : 5u
      );
    } 

    vec3 anisotropicDirectionWeights = abs(workNormal);

    for(uint anisotropicAxisDirectionSideIndex = 0u; anisotropicAxisDirectionSideIndex < countAnisotropicAxisDirectionSides; anisotropicAxisDirectionSideIndex++){

      uvec3 anisotropicDirectionOffsets = anisotropicAxisDirectionSideOffsets[anisotropicAxisDirectionSideIndex];

      vec4 anisotropicPremultipliedColor = vec4(finalColor.xyz, 1.0) * finalColor.w;

      [[unroll]]            
      for(uint anisotropicAxisDirectionIndex = 0u; anisotropicAxisDirectionIndex < 3u; anisotropicAxisDirectionIndex++){

        float anisotropicAxisDirectionWeight = anisotropicDirectionWeights[anisotropicAxisDirectionIndex];

        if(anisotropicAxisDirectionWeight > 0.0){
          
          uint volumeIndex = volumeBaseIndex + anisotropicDirectionOffsets[anisotropicAxisDirectionIndex];

          uint volumeColorIndex = volumeIndex << 2u;

          vec4 anisotropicAxisDirectionColor = anisotropicPremultipliedColor * anisotropicAxisDirectionWeight;

  #if defined(USESHADERBUFFERFLOAT32ATOMICADD)
          // 32 bit floating point 
          atomicAdd(voxelGridColors.data[volumeColorIndex | 0u], anisotropicAxisDirectionColor.x);
          atomicAdd(voxelGridColors.data[volumeColorIndex | 1u], anisotropicAxisDirectionColor.y);
          atomicAdd(voxelGridColors.data[volumeColorIndex | 2u], anisotropicAxisDirectionColor.z);
          atomicAdd(voxelGridColors.data[volumeColorIndex | 3u], anisotropicAxisDirectionColor.w);    
  #else
          // 22.12 bit fixed point
          uvec4 anisotropicAxisDirectionColorFixedPoint = uvec4(anisotropicAxisDirectionColor * 4096.0); 
          atomicAdd(voxelGridColors.data[volumeColorIndex | 0u], anisotropicAxisDirectionColorFixedPoint.x);
          atomicAdd(voxelGridColors.data[volumeColorIndex | 1u], anisotropicAxisDirectionColorFixedPoint.y);
          atomicAdd(voxelGridColors.data[volumeColorIndex | 2u], anisotropicAxisDirectionColorFixedPoint.z);
          atomicAdd(voxelGridColors.data[volumeColorIndex | 3u], anisotropicAxisDirectionColorFixedPoint.w);
  #endif

          atomicAdd(voxelGridCounters.data[volumeIndex], 1u); 

        }

      }   

    }

  }  
 
#endif

}

/*oid main() {
  outFragColor = vec4(vec3(mix(0.25, 1.0, max(0.0, dot(workNormal, vec3(0.0, 0.0, 1.0))))), 1.0);
//outFragColor = vec4(texture(uTexture, inTexCoord)) * vec4(vec3(mix(0.25, 1.0, max(0.0, dot(workNormal, vec3(0.0, 0.0, 1.0))))), 1.0);
}*/
