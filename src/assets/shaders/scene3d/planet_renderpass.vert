#version 450 core

#pragma shader_stage(vertex)

#extension GL_EXT_multiview : enable
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable
#extension GL_GOOGLE_include_directive : enable
#extension GL_EXT_control_flow_attributes : enable

#ifdef EXTERNAL_VERTICES
  layout(location = 0) in vec3 inVector;
#endif

#ifdef DIRECT

// Without tessellation

layout(location = 0) out OutBlock {
  vec3 position;
  vec3 tangent;
  vec3 bitangent;
  vec3 normal;
  vec3 edge; 
  vec3 worldSpacePosition;
  vec3 viewSpacePosition;
  vec3 cameraRelativePosition;
  vec2 jitter;
#ifdef VELOCITY
  vec4 previousClipSpace;
  vec4 currentClipSpace;
#endif  
} outBlock;

#else

// With tessellation

layout(location = 0) out OutBlock {
  vec3 position;
  vec3 normal;
  vec3 planetCenterToCamera;
} outBlock;

#endif

layout(push_constant) uniform PushConstants {
  
  mat4 modelMatrix;
  
  uint viewBaseIndex;
  uint countViews;
  uint countQuadPointsInOneDirection; 
  uint countAllViews;
  
  float bottomRadius;
  float topRadius;
  float resolutionX;  
  float resolutionY;  
  
  float heightMapScale;
  float tessellationFactor;
  vec2 jitter;

} pushConstants;

struct View {
  mat4 viewMatrix;
  mat4 projectionMatrix;
  mat4 inverseViewMatrix;
  mat4 inverseProjectionMatrix;
};

layout(set = 0, binding = 0, std140) uniform uboViews {
  View views[256];
} uView;

#ifdef DIRECT
layout(set = 1, binding = 0) uniform sampler2D uTextures[]; // 0 = height map, 1 = normal map, 2 = tangent bitangent map

#include "octahedral.glsl"
#include "octahedralmap.glsl"
#include "tangentspacebasis.glsl" 

uint viewIndex = pushConstants.viewBaseIndex + uint(gl_ViewIndex);
mat4 viewMatrix = uView.views[viewIndex].viewMatrix;
mat4 projectionMatrix = uView.views[viewIndex].projectionMatrix;
mat4 inverseViewMatrix = uView.views[viewIndex].inverseViewMatrix;
#else
uint viewIndex = pushConstants.viewBaseIndex + uint(gl_ViewIndex);
mat4 inverseViewMatrix = uView.views[viewIndex].inverseViewMatrix; 
#endif

#ifndef EXTERNAL_VERTICES

  #if defined(OCTAHEDRAL)

    uint countQuadPointsInOneDirection = pushConstants.countQuadPointsInOneDirection;
    uint countQuads = countQuadPointsInOneDirection * countQuadPointsInOneDirection;
    #ifdef TRIANGLES
      uint countTotalVertices = countQuads * 6u; // 2 triangles per quad, 3 vertices per triangle
    #else
      uint countTotalVertices = countQuads * 4u; // 4 vertices per quad
    #endif

  #else

    uint countQuadPointsInOneDirection = pushConstants.countQuadPointsInOneDirection;
    uint countSideQuads = countQuadPointsInOneDirection * countQuadPointsInOneDirection;
    #ifdef TRIANGLES
      uint countTotalVertices = countSideQuads * (6u * 6u); // 2 triangles per quad, 3 vertices per triangle, 6 sides
    #else
      uint countTotalVertices = countSideQuads * (6u * 4u); // 4 vertices per quad, 6 sides
    #endif

  #endif

#endif

void main(){          

  vec3 sphereNormal;

#ifdef EXTERNAL_VERTICES
  
  sphereNormal = normalize(inVector);

#else       
 
  uint vertexIndex = uint(gl_VertexIndex);
  
  if(vertexIndex < countTotalVertices){ 

    // A quad is made of two triangles, where the first triangle is the lower left triangle and the second
    // triangle is the upper right triangle. So the vertex indices and the triangles of a quad are:
    //
    // 0,0 v0--v1 1,0
    //     |\   |
    //     | \t0|
    //     |t1\ |
    //     |   \|
    // 1,0 v3--v2 1,1
    //
    // The indices are encoded as bitwise values here, so that the vertex indices can be calculated by bitshifting. 

#ifdef TRIANGLES

    // 0xe24 = 3,2,0,2,1,0 (two bit wise encoded triangle indices, reversed for bitshifting for 0,1,2, 0,2,3 output order)

    uint quadIndex = vertexIndex / 6u,   
         quadVertexIndex = (0xe24u >> ((vertexIndex - (quadIndex * 6u)) << 1u)) & 3u; 

#else

    uint quadIndex = vertexIndex >> 2u,
         quadVertexIndex = vertexIndex & 3u;

#endif

    // 0xb4 = 180 = 0b10110100 (bitwise encoded x y coordinates, where x is the first bit and y is the second bit in every two-bit pair)  
   
#ifndef DIRECT    
    // Reverse the order of the vertices for the tessellation shader, even tough the evaluation shader uses actually already counter clockwise winding order.
    // TODO: Find out the reason for this.
    quadVertexIndex = 3u - quadVertexIndex; 
#endif

    uint quadVertexUVIndex = (0xb4u >> (quadVertexIndex << 1u)) & 3u;     
    uvec2 quadVertexUV = uvec2(quadVertexUVIndex & 1u, quadVertexUVIndex >> 1u);

#if defined(OCTAHEDRAL)

    uvec2 quadXY;
    quadXY.y = quadIndex / countQuadPointsInOneDirection;
    quadXY.x = quadIndex - (quadXY.y * countQuadPointsInOneDirection); 

    vec2 uv = fma(vec2(quadXY + quadVertexUV) / vec2(countQuadPointsInOneDirection), vec2(2.0), vec2(-1.0));

    sphereNormal = vec3(uv.xy, 1.0 - (abs(uv.x) + abs(uv.y)));
    sphereNormal = normalize((sphereNormal.z < 0.0) ? vec3((1.0 - abs(sphereNormal.yx)) * vec2((sphereNormal.x >= 0.0) ? 1.0 : -1.0, (sphereNormal.y >= 0.0) ? 1.0 : -1.0), sphereNormal.z) : sphereNormal);

#else

    const mat3 sideMatrices[6] = mat3[6](
      mat3(vec3(0.0, 0.0, -1.0), vec3(0.0, -1.0, 0.0), vec3(-1.0, 0.0, 0.0)), // pos x
      mat3(vec3(0.0, 0.0, 1.0), vec3(0.0, -1.0, 0.0), vec3(1.0, 0.0, 0.0)),   // neg x
      mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, -1.0), vec3(0.0, 1.0, 0.0)),   // pos y
      mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), vec3(0.0, -1.0, 0.0)),   // neg y
      mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, -1.0, 0.0), vec3(0.0, 0.0, -1.0)),  // pos z
      mat3(vec3(-1.0, 0.0, 0.0), vec3(0.0, -1.0, 0.0), vec3(0.0, 0.0, 1.0))   // neg z
    );  

    uint sideIndex = quadIndex / countSideQuads,
        sideQuadIndex = quadIndex - (sideIndex * countSideQuads);

    float sideQuadY = sideQuadIndex / countQuadPointsInOneDirection,
          sideQuadX = sideQuadIndex - (sideQuadY * countQuadPointsInOneDirection); 

    vec2 uv = fma(vec2(uvec2(sideQuadX, sideQuadY) + quadVertexUV) / vec2(countQuadPointsInOneDirection), vec2(2.0), vec2(-1.0));

#define CUBE_TO_SPHERE_METHOD_NORMALIZATON 0
#define CUBE_TO_SPHERE_METHOD_PHIL_NOWELL 1
#define CUBE_TO_SPHERE_METHOD_HARRY_VAN_LANGEN 2
#define CUBE_TO_SPHERE_METHOD_MATT_ZUCKER_AND_YOSUKE_HIGASHI 3
#define CUBE_TO_SPHERE_METHOD_COBE 4
#define CUBE_TO_SPHERE_METHOD_ARVO 5

#define CUBE_TO_SPHERE_METHOD CUBE_TO_SPHERE_METHOD_COBE
#if CUBE_TO_SPHERE_METHOD == CUBE_TO_SPHERE_METHOD_MATT_ZUCKER_AND_YOSUKE_HIGASHI

    // http://www.jcgt.org/published/0007/02/01/ - Matt Zucker and Yosuke Higashi - Cube-to-sphere Projections for Procedural Texturing and Beyond
  
    {
      const float warpTheta = 0.868734829276; // radians
      const float tanWarpTheta = 1.1822866855467427; // tan(warpTheta);
      uv = tan(uv * warpTheta) / tanWarpTheta;
    }

#elif CUBE_TO_SPHERE_METHOD == CUBE_TO_SPHERE_METHOD_COBE

    // https://en.wikipedia.org/wiki/Quadrilateralized_spherical_cube - COBE quadrilateralized spherical cube

    {
      vec2 x = uv, y = x.yx, x2 = x * x, y2 = y * y,
           bsum = (((-0.0941180085824 + (0.0409125981187 * y2)) - (0.0623272690881 * x2))*x2) + ((0.0275922480902 + (0.0342217026979 * y2)) * y2);
      uv = ((0.723951234952 + (0.276048765048 * x2)) + ((1.0 - x2) * bsum)) * x;
    }
    
#elif CUBE_TO_SPHERE_METHOD == CUBE_TO_SPHERE_METHOD_ARVO

    // http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.88.3412&rep=rep1&type=pdf - Arvo's exact equal area method 

    {
      float tan_a_term = tan(uv.x * 0.523598775598), cos_a_term = cos(uv.x * 1.0471975512);
      uv = vec2((1.41421356237 * tan_a_term) / sqrt(1.0 - (tan_a_term * tan_a_term)), uv.y / sqrt(fma(1.0 - (uv.y * uv.y), cos_a_term, 1.0)));
    }

#endif

    vec3 unitCube = sideMatrices[sideIndex % 6u] * vec3(uv, 1.0); 
                      
#if CUBE_TO_SPHERE_METHOD == CUBE_TO_SPHERE_METHOD_PHIL_NOWELL

    // https://mathproofs.blogspot.com/2005/07/mapping-cube-to-sphere.html?lr=1 - Phil Nowell - Mapping a Cube to a Sphere 
    // It has a more uniform distribution than just normalizing the unit cube

    vec3 unitCubeSquared = unitCube * unitCube, 
                           unitCubeSquaredDiv2 = unitCubeSquared * 0.5, 
                           unitCubeSquaredDiv3 = unitCubeSquared / 3.0;

    sphereNormal = normalize(unitCube * sqrt(((1.0 - unitCubeSquaredDiv2.yzx) - unitCubeSquaredDiv2.zxy) + (unitCubeSquared.yzx * unitCubeSquaredDiv3.zxy)));

#elif CUBE_TO_SPHERE_METHOD == CUBE_TO_SPHERE_METHOD_HARRY_VAN_LANGEN

    // https://hvlanalysis.blogspot.com/2023/05/mapping-cube-to-sphere.html - Harry van Langen - Mapping a Cube to a Sphere
    // It has a much more uniform distribution than the approach by Phil Nowell, but it is more expensive.

    sphereNormal = abs(unitCube);

    float p = float(countQuadPointsInOneDirection) * 10.0;

    const int countIterations = 2;

    [[unroll]]
    for(int iteration = 0; iteration < countIterations; iteration++){

      vec3 temp = sqrt(pow(sphereNormal, vec3(p)) + vec3(dot(sphereNormal.yz, sphereNormal.yz), dot(sphereNormal.xz, sphereNormal.xz), dot(sphereNormal.xy, sphereNormal.xy)));
      sphereNormal = temp * tan(sphereNormal * atan(vec3(1.0) / temp));

    } 

    sphereNormal = normalize(sphereNormal * sign(unitCube));

#else

    // Just normalize the unit cube for the other methods

    sphereNormal = normalize(unitCube);

#endif

#endif

  }else{

    sphereNormal = vec3(0.0);

  }  

#endif

#ifdef DIRECT
 
  // Without tessellation, so directly output the vertex data to the fragment shader

  mat4 viewProjectionMatrix = projectionMatrix * viewMatrix;

#if 1
  // The actual standard approach
  vec3 cameraPosition = inverseViewMatrix[3].xyz;
#else
  // This approach assumes that the view matrix has no scaling or skewing, but only rotation and translation.
  vec3 cameraPosition = (-viewMatrix[3].xyz) * mat3(viewMatrix);
#endif   

  vec3 position = (pushConstants.modelMatrix * vec4(sphereNormal * (pushConstants.bottomRadius + (textureCatmullRomOctahedralMap(uTextures[0], sphereNormal).x * pushConstants.heightMapScale)), 1.0)).xyz;

  vec3 outputNormal = textureCatmullRomOctahedralMap(uTextures[1], sphereNormal).xyz;
  vec3 outputTangent = normalize(cross((abs(outputNormal.y) < 0.999999) ? vec3(0.0, 1.0, 0.0) : vec3(0.0, 0.0, 1.0), outputNormal));
  vec3 outputBitangent = normalize(cross(outputNormal, outputTangent));

  vec3 worldSpacePosition = position;

  vec4 viewSpacePosition = viewMatrix * vec4(position, 1.0);
  viewSpacePosition.xyz /= viewSpacePosition.w;

  outBlock.position = position;         
  outBlock.tangent = outputTangent;
  outBlock.bitangent = outputBitangent;
  outBlock.normal = outputNormal;
  outBlock.edge = vec3(1.0);
  outBlock.worldSpacePosition = worldSpacePosition;
  outBlock.viewSpacePosition = viewSpacePosition.xyz;  
  outBlock.cameraRelativePosition = worldSpacePosition - cameraPosition;
  outBlock.jitter = pushConstants.jitter;
#ifdef VELOCITY
  outBlock.currentClipSpace = (projectionMatrix * viewMatrix) * vec4(position, 1.0);
  outBlock.previousClipSpace = (uView.views[viewIndex + pushConstants.countAllViews].projectionMatrix * uView.views[viewIndex + pushConstants.countAllViews].viewMatrix) * vec4(position, 1.0);
#endif

	gl_Position = viewProjectionMatrix * vec4(position, 1.0);


#else

  // With tessellation

  vec3 position = (pushConstants.modelMatrix * vec4(sphereNormal * pushConstants.bottomRadius, 1.0)).xyz;
  outBlock.position = position;    
  outBlock.normal = sphereNormal;
  outBlock.planetCenterToCamera = inverseViewMatrix[3].xyz - (pushConstants.modelMatrix * vec2(0.0, 1.0).xxxy).xyz; 

#endif

}