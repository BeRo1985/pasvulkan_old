#version 450 core

#pragma shader_stage(tesscontrol)

#extension GL_EXT_multiview : enable
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable
#extension GL_EXT_nonuniform_qualifier : enable
#extension GL_EXT_control_flow_attributes : enable
#extension GL_GOOGLE_include_directive : enable

#include "bufferreference_definitions.glsl"

#ifdef TRIANGLES
layout(vertices = 3) out;
#else
layout(vertices = 4) out;
#endif

layout(location = 0) in InBlock {
  vec3 position;
  vec3 normal;
  vec3 planetCenterToCamera;
  uint flags;
} inBlocks[];

layout(location = 0) out OutBlock {
  vec3 position;
  vec3 normal;
  uint flags;
} outBlocks[];

// Global descriptor set

#define PLANETS
#include "globaldescriptorset.glsl"
#undef PLANETS

#define PLANET_WATER
#include "planet_renderpass.glsl"
  
vec2 resolution = vec2(float(uint(pushConstants.resolutionXY & 0xffffu)), float(uint(pushConstants.resolutionXY >> 16u)));

struct View {
  mat4 viewMatrix;
  mat4 projectionMatrix;
  mat4 inverseViewMatrix;
  mat4 inverseProjectionMatrix;
};

layout(set = 1, binding = 0, std140) uniform uboViews {
  View views[256];
} uView;
 
uint viewIndex = pushConstants.viewBaseIndex + uint(gl_ViewIndex);
mat4 viewMatrix = uView.views[viewIndex].viewMatrix;
mat4 projectionMatrix = uView.views[viewIndex].projectionMatrix;
mat4 inverseViewMatrix = uView.views[viewIndex].inverseViewMatrix;
// mat4 inverseProjectionMatrix = uView.views[viewIndex].inverseProjectionMatrix;

float remap(const in float value,
            const in float oldMin,
            const in float oldMax,
            const in float newMin,
            const in float newMax){
  return (((value - oldMin) / (oldMax - oldMin)) * (newMax - newMin)) + newMin; 
}

float AdaptiveTessellation(vec3 p0, vec3 p1){
  vec4 vc = viewMatrix * vec4(mix(p0, p1, 0.5), 1.0),
       vr = vec2(distance(p0, p1) * 0.5, 0.0).xxyy,
       v0 = projectionMatrix * (vc - vr),
       v1 = projectionMatrix * (vc + vr),
       v = fma(vec4(v0.xy / v0.w, v1.xy / v1.w), vec4(0.5), vec4(0.5)) * resolution.xyxy;
 	return clamp(distance(v.xy, v.zw) * pushConstants.tessellationFactor, 1.0, 64.0);
}
void main(){	 
  const uint anyFlags = inBlocks[0].flags | 
                        inBlocks[1].flags | 
                        inBlocks[2].flags |
#ifndef TRIANGLES
                        inBlocks[3].flags |             
#endif
                        0u;
  const uint maskedFlags = inBlocks[0].flags & 
                           inBlocks[1].flags & 
                           inBlocks[2].flags &
#ifndef TRIANGLES
                           inBlocks[3].flags &
#endif
                           0xffffffffu; 
  const bool underWater = (maskedFlags & (1u << 0u)) != 0u;
  const bool isVisible = (anyFlags & (1u << 1u)) != 0u;
  const bool isWaterVisible = (anyFlags & (1u << 2u)) != 0u;
  const bool aboveGround = (anyFlags & (1u << 3u)) != 0u;
  bool visible = isVisible && isWaterVisible && aboveGround && !underWater;
  if(visible){
#ifdef TRIANGLES
    vec3 faceNormal = normalize(inBlocks[0].normal + inBlocks[1].normal + inBlocks[2].normal);
#else
    vec3 faceNormal = normalize(inBlocks[0].normal + inBlocks[1].normal + inBlocks[2].normal + inBlocks[3].normal);
#endif
    vec3 planetCenterToCamera = (inBlocks[0].planetCenterToCamera + 
                                 inBlocks[1].planetCenterToCamera + 
                                 inBlocks[2].planetCenterToCamera + 
                                 inBlocks[3].planetCenterToCamera) * 0.25;
    vec3 planetCenterToCameraDirection = normalize(planetCenterToCamera);
    if(dot(faceNormal, planetCenterToCameraDirection) < 0.0){
      // Because the planet is a sphere, the face is visible if the angle between the face normal and the vector from the planet center to the 
      // camera is less than 90 degrees, and invisible otherwise.
      visible = false;
    }    
  }
  if(visible){
#ifdef TRIANGLES
    gl_TessLevelOuter[0] = AdaptiveTessellation(inBlocks[1].position, inBlocks[2].position);
    gl_TessLevelOuter[1] = AdaptiveTessellation(inBlocks[2].position, inBlocks[0].position);
    gl_TessLevelOuter[2] = AdaptiveTessellation(inBlocks[0].position, inBlocks[1].position);
    gl_TessLevelInner[0] = mix(gl_TessLevelOuter[0], gl_TessLevelOuter[2], 0.5);
#else
  	gl_TessLevelOuter[0] = AdaptiveTessellation(inBlocks[3].position, inBlocks[0].position);
	  gl_TessLevelOuter[1] = AdaptiveTessellation(inBlocks[0].position, inBlocks[1].position);
	  gl_TessLevelOuter[2] = AdaptiveTessellation(inBlocks[1].position, inBlocks[2].position);
	  gl_TessLevelOuter[3] = AdaptiveTessellation(inBlocks[2].position, inBlocks[3].position);
	  gl_TessLevelInner[0] = mix(gl_TessLevelOuter[0], gl_TessLevelOuter[3], 0.5);
    gl_TessLevelInner[1] = mix(gl_TessLevelOuter[2], gl_TessLevelOuter[1], 0.5);
/*  gl_TessLevelOuter[0] = AdaptiveTessellation(inBlocks[2].position, inBlocks[0].position);
	  gl_TessLevelOuter[1] = AdaptiveTessellation(inBlocks[0].position, inBlocks[1].position);
	  gl_TessLevelOuter[2] = AdaptiveTessellation(inBlocks[1].position, inBlocks[3].position);
	  gl_TessLevelOuter[3] = AdaptiveTessellation(inBlocks[3].position, inBlocks[2].position);
	  gl_TessLevelInner[0] = mix(gl_TessLevelOuter[0], gl_TessLevelOuter[3], 0.5);
    gl_TessLevelInner[1] = mix(gl_TessLevelOuter[2], gl_TessLevelOuter[1], 0.5);*/
#endif
  }else{
#ifdef TRIANGLES
    gl_TessLevelOuter[0] = -1.0;
    gl_TessLevelOuter[1] = -1.0;   
    gl_TessLevelOuter[2] = -1.0;
    gl_TessLevelInner[0] = -1.0;  
#else
	  gl_TessLevelOuter[0] = -1.0;
	  gl_TessLevelOuter[1] = -1.0;   
	  gl_TessLevelOuter[2] = -1.0;
	  gl_TessLevelOuter[3] = -1.0;
	  gl_TessLevelInner[0] = -1.0;
    gl_TessLevelInner[1] = -1.0;
#endif
  }
  outBlocks[gl_InvocationID].position = inBlocks[gl_InvocationID].position;
	outBlocks[gl_InvocationID].normal = inBlocks[gl_InvocationID].normal;
	outBlocks[gl_InvocationID].flags = inBlocks[gl_InvocationID].flags;
}  
