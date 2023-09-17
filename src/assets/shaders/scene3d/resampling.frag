#version 450 core

#extension GL_EXT_multiview : enable
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

layout(location = 0) in vec2 inTexCoord;

layout(location = 0) out vec4 outFragColor;

layout(set = 0, binding = 0) uniform sampler2DArray uTexture;

#define DYNAMIC_SIZED_LANCZOS 1
#define DYNAMIC_SIZED_LANCZOS_RADIUS 5

#if DYNAMIC_SIZED_LANCZOS
const float PI = 3.1415926535897932384626433;
const float PI_SQ = 9.8696044010893586188344910;

float lanczosWeight(float x, float r) {
    return (abs(x) < 1e-6) ? 1.0 : (r * sin(PI * x) * sin(PI * (x / r) )) / (PI_SQ * (x * x));
}

float lanczosWeight(vec2 x, float r) {
    return lanczosWeight(x.x, r) * lanczosWeight(x.y, r);
}

vec4 lanczos(sampler2DArray tex, vec2 texCoord, int r) {
  vec2 texSize = vec2(textureSize(tex, 0).xy);
  texCoord -= vec2(0.5) / texSize;
  vec2 center = floor(texCoord * texSize) / texSize;
  vec4 total = vec4(0);    
  for (int x = -r; x <= r; x++) {
    for (int y = -r; y <= r; y++) {
      vec2 uv = (vec2(x,y) / texSize) + center;
      total += texelFetch(tex, ivec3(uv * texSize, float(gl_ViewIndex)), 0) * 
                lanczosWeight(clamp((uv - texCoord) * texSize, vec2(-r), vec2(r)), float(r));
    }
  }
  return total;
}
#endif

void main(){
#if DYNAMIC_SIZED_LANCZOS
  outFragColor = lanczos(uTexture, inTexCoord, DYNAMIC_SIZED_LANCZOS_RADIUS); //textureLod(uTexture, vec3(inTexCoord, float(gl_ViewIndex)), 0.0);
#else  

  // Optimized lanczos shader with 4x4 kernel

  vec2 texSize = vec2(textureSize(uTexture, 0).xy);
  
  vec2 xy = inTexCoord;
  
  vec2 scaled = (xy * texSize) - vec2(0.5);
  
  xy = (floor(scaled) + vec2(0.5)) / texSize;
  
  vec2 uvratio = fract(scaled);
  
  vec4 coefsX = max(abs(3.141592653589 * vec4(1.0 + uvratio.x,uvratio.x, 1.0 - uvratio.x,2.0 - uvratio.x)), 1e-4);
  coefsX = 2.0*((sin(coefsX) * sin(coefsX * 0.5)) / (coefsX * coefsX));
  coefsX /= dot(coefsX, vec4(1.0));
  
  vec4 coefsY = max(abs(3.141592653589 * vec4(1.0 + uvratio.y, uvratio.y, 1.0 - uvratio.y, 2.0 - uvratio.y)), 1e-4);
  coefsY = 2.0 * ((sin(coefsY) * sin(coefsY*0.5)) / (coefsY * coefsY));
  coefsY /= dot(coefsY, vec4(1.0));

  vec4 texel0 = mat4(textureLod(uTexture, vec3(xy + (vec2(-1.0, -1.0) / texSize), float(gl_ViewIndex)), 0.0).xyzw,
                     textureLod(uTexture, vec3(xy + (vec2( 0.0, -1.0) / texSize), float(gl_ViewIndex)), 0.0).xyzw,
                     textureLod(uTexture, vec3(xy + (vec2( 1.0, -1.0) / texSize), float(gl_ViewIndex)), 0.0).xyzw,    
                     textureLod(uTexture, vec3(xy + (vec2( 2.0, -1.0) / texSize), float(gl_ViewIndex)), 0.0).xyzw) * coefsX;
  
  vec4 texel1 = mat4(textureLod(uTexture, vec3(xy + (vec2(-1.0,  0.0) / texSize), float(gl_ViewIndex)), 0.0).xyzw,
                     textureLod(uTexture, vec3(xy + (vec2( 0.0,  0.0) / texSize), float(gl_ViewIndex)), 0.0).xyzw,
                     textureLod(uTexture, vec3(xy + (vec2( 1.0,  0.0) / texSize), float(gl_ViewIndex)), 0.0).xyzw,
                     textureLod(uTexture, vec3(xy + (vec2( 2.0,  0.0) / texSize), float(gl_ViewIndex)), 0.0).xyzw) * coefsX;
  
  vec4 texel2 = mat4(textureLod(uTexture, vec3(xy + (vec2(-1.0,  1.0) / texSize), float(gl_ViewIndex)), 0.0).xyzw,
                     textureLod(uTexture, vec3(xy + (vec2( 0.0,  1.0) / texSize), float(gl_ViewIndex)), 0.0).xyzw,
                     textureLod(uTexture, vec3(xy + (vec2( 1.0,  1.0) / texSize), float(gl_ViewIndex)), 0.0).xyzw,
                     textureLod(uTexture, vec3(xy + (vec2( 2.0,  1.0) / texSize), float(gl_ViewIndex)), 0.0).xyzw) * coefsX;
  
  vec4 texel3 = mat4(textureLod(uTexture, vec3(xy + (vec2(-1.0,  2.0) / texSize), float(gl_ViewIndex)), 0.0).xyzw,
                     textureLod(uTexture, vec3(xy + (vec2( 0.0,  2.0) / texSize), float(gl_ViewIndex)), 0.0).xyzw,
                     textureLod(uTexture, vec3(xy + (vec2( 1.0,  2.0) / texSize), float(gl_ViewIndex)), 0.0).xyzw,
                     textureLod(uTexture, vec3(xy + (vec2( 2.0,  2.0) / texSize), float(gl_ViewIndex)), 0.0).xyzw) * coefsX;                                                           
  
  outFragColor = mat4(texel0, texel1, texel2, texel3)*coefsY;
#endif

}
