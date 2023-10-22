#version 450 core

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable
#extension GL_GOOGLE_include_directive : enable
#extension GL_EXT_nonuniform_qualifier : enable

layout(triangles, invocations = COUNT_CLIPMAPS) in; // COUNT_CLIPMAPS is defined by the compiling call in the build script 
layout(triangle_strip, max_vertices = 3) out;

layout(location = 0) in vec3 inWorldSpacePosition[];
layout(location = 1) in vec3 inViewSpacePosition[];
layout(location = 2) in vec3 inCameraRelativePosition[];
layout(location = 3) in vec3 inTangent[];
layout(location = 4) in vec3 inBitangent[];
layout(location = 5) in vec3 inNormal[];
layout(location = 6) in vec2 inTexCoord0[];
layout(location = 7) in vec2 inTexCoord1[];
layout(location = 8) in vec4 inColor0[];
layout(location = 9) in vec3 intModelScale[];
layout(location = 10) flat in uint inMaterialID[];

layout(location = 0) out vec3 outWorldSpacePosition;
layout(location = 1) out vec3 outViewSpacePosition;
layout(location = 2) out vec3 outCameraRelativePosition;
layout(location = 3) out vec3 outTangent;
layout(location = 4) out vec3 outBitangent;
layout(location = 5) out vec3 outNormal;
layout(location = 6) out vec2 outTexCoord0;
layout(location = 7) out vec2 outTexCoord1;
layout(location = 8) out vec4 outColor0;
layout(location = 9) out vec3 outModelScale;
layout(location = 10) flat out uint outMaterialID;
layout(location = 11) flat out vec3 outAABBMin;
layout(location = 12) flat out vec3 outAABBMax;
layout(location = 13) flat out uint outClipMapIndex;
layout(location = 14) out vec3 outVoxelPosition;

/*layout(location = 11) flat out vec3 outVertex0;
layout(location = 12) flat out vec3 outVertex1;
layout(location = 13) flat out vec3 outVertex2;*/

#define VOXELIZATION
#include "voxelization_globals.glsl"

void main(){

  uint clipMapIndex = uint(gl_InvocationID);

  if(clipMapIndex < voxelGridData.countClipMaps){ // Just for to be sure alongside the invocations count above
    
    vec3 clipMapSpacePositions[3] = vec3[3](
#if 0      
      fma(vec3(voxelGridData.worldToNormalizedClipMaps[clipMapIndex] * vec4(inWorldSpacePosition[0].xyz, 1.0)).xyz, vec3(2.0), vec3(-1.0)),
      fma(vec3(voxelGridData.worldToNormalizedClipMaps[clipMapIndex] * vec4(inWorldSpacePosition[1].xyz, 1.0)).xyz, vec3(2.0), vec3(-1.0)),
      fma(vec3(voxelGridData.worldToNormalizedClipMaps[clipMapIndex] * vec4(inWorldSpacePosition[2].xyz, 1.0)).xyz, vec3(2.0), vec3(-1.0))
#else
      vec3((inWorldSpacePosition[0] - voxelGridData.clipMaps[clipMapIndex].xyz) / voxelGridData.clipMaps[clipMapIndex].w),
      vec3((inWorldSpacePosition[1] - voxelGridData.clipMaps[clipMapIndex].xyz) / voxelGridData.clipMaps[clipMapIndex].w),
      vec3((inWorldSpacePosition[2] - voxelGridData.clipMaps[clipMapIndex].xyz) / voxelGridData.clipMaps[clipMapIndex].w)
#endif
    );   

    vec3 faceNormal = cross(inWorldSpacePosition[1] - inWorldSpacePosition[0], inWorldSpacePosition[2] - inWorldSpacePosition[0]);

    ivec3 vertexIndexOrder = (faceNormal.z > 0.0) ? ivec3(0, 1, 2) : ivec3(0, 2, 1);

    faceNormal = abs(faceNormal);

    int dominantAxisIndex = (faceNormal.y > faceNormal.x) ? ((faceNormal.y > faceNormal.z) ? 1 : 2) : ((faceNormal.x > faceNormal.z) ? 0 : 2);

    const ivec3 dominantAxisComponentOrders[3] = ivec3[3](
      ivec3(2, 1, 0), // zyx
      ivec3(0, 2, 1), // xzy
      ivec3(0, 1, 2)  // xyz
    );
    
    ivec3 dominantAxisComponentOrder = dominantAxisComponentOrders[dominantAxisIndex];

    vec4 projectionVertices[3] = vec4[3](
      vec4(
        clipMapSpacePositions[0][dominantAxisComponentOrder.x],
        clipMapSpacePositions[0][dominantAxisComponentOrder.y], 
        clipMapSpacePositions[0][dominantAxisComponentOrder.z], 
        1.0
      ),
      vec4(
        clipMapSpacePositions[1][dominantAxisComponentOrder.x], 
        clipMapSpacePositions[1][dominantAxisComponentOrder.y], 
        clipMapSpacePositions[1][dominantAxisComponentOrder.z], 
        1.0
      ),
      vec4(
        clipMapSpacePositions[2][dominantAxisComponentOrder.x], 
        clipMapSpacePositions[2][dominantAxisComponentOrder.y], 
        clipMapSpacePositions[2][dominantAxisComponentOrder.z], 
        1.0
      )
    );
    
    // When using no hardware conservative rasterization, we need to expand the triangle by one texel in each direction manually to avoid holes in the voxelization.
    if(voxelGridData.hardwareConservativeRasterization == 0u){
      vec2 sides[3] = vec2[3](
        vec2(normalize(projectionVertices[vertexIndexOrder[1]].xy - projectionVertices[vertexIndexOrder[0]].xy)),
        vec2(normalize(projectionVertices[vertexIndexOrder[2]].xy - projectionVertices[vertexIndexOrder[1]].xy)),
        vec2(normalize(projectionVertices[vertexIndexOrder[0]].xy - projectionVertices[vertexIndexOrder[2]].xy))
      );
      float texelSize = 1.41421356237 / voxelGridData.clipMaps[clipMapIndex].w;
      projectionVertices[vertexIndexOrder[0]].xy += normalize(sides[2] - sides[0]) * texelSize;
      projectionVertices[vertexIndexOrder[1]].xy += normalize(sides[0] - sides[1]) * texelSize;
      projectionVertices[vertexIndexOrder[2]].xy += normalize(sides[1] - sides[2]) * texelSize;
    }

    vec3 aabbMin = min(min(inWorldSpacePosition[0], inWorldSpacePosition[1]), inWorldSpacePosition[2]);
    vec3 aabbMax = max(max(inWorldSpacePosition[0], inWorldSpacePosition[1]), inWorldSpacePosition[2]);
    
    for(int vertexIndex = 0; vertexIndex < 3; vertexIndex++){

      int currentVertexIndex = vertexIndexOrder[vertexIndex];

      outWorldSpacePosition = inWorldSpacePosition[currentVertexIndex];

      outViewSpacePosition = inViewSpacePosition[currentVertexIndex];

      outCameraRelativePosition = inCameraRelativePosition[currentVertexIndex];
          
      outTangent = inTangent[currentVertexIndex];
      outBitangent = inBitangent[currentVertexIndex];
      outNormal = inNormal[currentVertexIndex];

      outTexCoord0 = inTexCoord0[currentVertexIndex];
      outTexCoord1 = inTexCoord1[currentVertexIndex];

      outColor0 = inColor0[currentVertexIndex];

      outModelScale = intModelScale[currentVertexIndex];

      outMaterialID = inMaterialID[currentVertexIndex];

      outAABBMin = aabbMin;

      outAABBMax = aabbMax;    

      outClipMapIndex = clipMapIndex;

      outVoxelPosition = fma(clipMapSpacePositions[currentVertexIndex].xyz, vec3(0.5), vec3(0.5));

    /*outVertex0 = inWorldSpacePosition[vertexIndexOrder[0]];
      outVertex1 = inWorldSpacePosition[vertexIndexOrder[1]];
      outVertex2 = inWorldSpacePosition[vertexIndexOrder[2]];*/

      gl_Position = vec4(projectionVertices[currentVertexIndex].xyw, 0.0).xywz; // We need to swap the z and w components here because we are using a 2D projection matrix

      //gl_ViewportIndex = clipMapIndex;

      EmitVertex();

    }

    EndPrimitive();

  }

}