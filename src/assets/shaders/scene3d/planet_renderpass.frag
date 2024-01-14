#version 450 core

#pragma shader_stage(fragment)

#extension GL_EXT_multiview : enable
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable
#extension GL_GOOGLE_include_directive : enable
#extension GL_EXT_nonuniform_qualifier : enable
#ifdef WIREFRAME
  #extension GL_EXT_fragment_shader_barycentric : enable
#endif

layout(location = 0) in InBlock {
  vec3 position;
  vec3 sphereNormal;
  vec3 normal;
  vec3 worldSpacePosition;
  vec3 viewSpacePosition;
  vec3 cameraRelativePosition;
  vec2 jitter;
#ifdef VELOCITY
  vec4 previousClipSpace;
  vec4 currentClipSpace;
#endif  
} inBlock;

layout(location = 0) out vec4 outFragColor;
#ifdef VELOCITY
layout(location = 1) out vec2 outVelocity;
#endif

// Global descriptor set

#define PLANETS
#include "globaldescriptorset.glsl"
#undef PLANETS

// Pass descriptor set

layout(set = 1, binding = 1) uniform sampler2D uImageBasedLightingBRDFTextures[];  // 0 = GGX, 1 = Charlie, 2 = Sheen E

layout(set = 1, binding = 2) uniform samplerCube uImageBasedLightingEnvMaps[];  // 0 = GGX, 1 = Charlie, 2 = Lambertian

layout(set = 1, binding = 3, std430) readonly buffer ImageBasedSphericalHarmonicsMetaData {
  vec4 dominantLightDirection;
  vec4 dominantLightColor;
  vec4 ambientLightColor;
} imageBasedSphericalHarmonicsMetaData;

// Per planet descriptor set

layout(set = 2, binding = 0) uniform sampler2D uTextures[]; // 0 = height map, 1 = normal map, 2 = tangent bitangent map

#include "planet_renderpass.glsl"

#define FRAGMENT_SHADER

#include "octahedral.glsl"
#include "octahedralmap.glsl"
#include "tangentspacebasis.glsl" 

float envMapMaxLevelGGX;

#include "roughness.glsl"

vec3 imageLightBasedLightDirection = imageBasedSphericalHarmonicsMetaData.dominantLightDirection.xyz;

float ambientOcclusion = 1.0;
vec3 iridescenceF0 = vec3(0.04);
vec3 iridescenceFresnel = vec3(0.0);
float iridescenceFactor = 0.0;

#ifdef WIREFRAME
float edgeFactor(){
  const float sqrt0d5Mul0d5 = 0.3535533905932738; // sqrt(0.5) * 0.5 - Half of the length of the diagonal of a square with a side length of 1.0
  const vec3 edge = gl_BaryCoordEXT, 
             edgeDX = dFdxFine(edge), 
             edgeDY = dFdyFine(edge), 
             edgeDXY = sqrt((edgeDX * edgeDX) + (edgeDY * edgeDY)),
             edgeRemapped = smoothstep(vec3(0.0), edgeDXY * sqrt0d5Mul0d5, fma(edgeDXY, vec3(-sqrt0d5Mul0d5), edge));
  return 1.0 - min(min(edgeRemapped.x, edgeRemapped.y), edgeRemapped.z);
}   
#endif

float getSpecularOcclusion(const in float NdotV, const in float ao, const in float roughness){
  return clamp((pow(NdotV + ao, /*roughness * roughness*/exp2((-16.0 * roughness) - 1.0)) - 1.0) + ao, 0.0, 1.0); 
} 

vec3 getIBLRadianceLambertian(const in vec3 normal, const in vec3 viewDirection, const in float roughness, const in vec3 diffuseColor, const in vec3 F0, const in float specularWeight) {
  float ao = ambientOcclusion;
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
  float ao = ambientOcclusion,                                                                                                   //
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

float textureHash11(uint q){
	uvec2 n = q * uvec2(1597334673U, 3812015801U);
	q = (n.x ^ n.y) * 1597334673U;
  return ((uintBitsToFloat(uint(uint(((q >> 9u) & uint(0x007fffffu)) | uint(0x3f800000u))))) - 1.0);
}

float textureHash11(float p){
	uvec2 n = uint(int(p)) * uvec2(1597334673U, 3812015801U);
	uint q = (n.x ^ n.y) * 1597334673U;
  return ((uintBitsToFloat(uint(uint(((q >> 9u) & uint(0x007fffffu)) | uint(0x3f800000u))))) - 1.0);
}

float textureHash12(uvec2 q){
	q *= uvec2(1597334673U, 3812015801U);
	uint n = (q.x ^ q.y) * 1597334673U;
  return ((uintBitsToFloat(uint(uint(((n >> 9u) & uint(0x007fffffu)) | uint(0x3f800000u))))) - 1.0);
}

float textureHash12(vec2 p){
	uvec2 q = uvec2(ivec2(p)) * uvec2(1597334673U, 3812015801U);
	uint n = (q.x ^ q.y) * 1597334673U;
  return ((uintBitsToFloat(uint(uint(((n >> 9u) & uint(0x007fffffu)) | uint(0x3f800000u))))) - 1.0);
}

vec2 textureHash22(uvec2 q){
  q *= uvec2(1597334673U, 3812015801U);
  q = (q.x ^ q.y) * uvec2(1597334673U, 3812015801U);
  return vec2(vec2(uintBitsToFloat(uvec2(uvec2(((q >> 9u) & uvec2(0x007fffffu)) | uvec2(0x3f800000u))))) - vec2(1.0));
}

vec2 textureHash22(vec2 p){
  uvec2 q = uvec2(ivec2(p)) * uvec2(1597334673U, 3812015801U);
  q = (q.x ^ q.y) * uvec2(1597334673U, 3812015801U);
  return vec2(vec2(uintBitsToFloat(uvec2(uvec2(((q >> 9u) & uvec2(0x007fffffu)) | uvec2(0x3f800000u))))) - vec2(1.0));
}

float textureNoise11(float p){
  float f = fract(p);
  p -= f;
  f = (f * f) * (3.0 - (2.0 * f));
  return mix(textureHash11(p + 0.0), textureHash11(p + 1.0), f); 
}

float textureNoise12(vec2 p){
  vec2 f = fract(p);
  p -= f;
  f = (f * f) * (3.0 - (2.0 * f));
  vec2 n = vec2(0.0, 1.0);
  return mix(mix(textureHash12(p + n.xx), textureHash12(p + n.yx), f.x),
             mix(textureHash12(p + n.xy), textureHash12(p + n.yy), f.x), f.y);
}

vec2 textureNoise22(vec2 p){
  vec2 f = fract(p);
  p -= f;
  f = (f * f) * (3.0 - (2.0 * f));
  vec2 n = vec2(0.0, 1.0);
  return mix(mix(textureHash22(p + n.xx), textureHash22(p + n.yx), f.x),
             mix(textureHash22(p + n.xy), textureHash22(p + n.yy), f.x), f.y);
  
}

vec4 textureNoTile(const in sampler2D tex, in vec2 uv, const in vec2 duvdx, const in vec2 duvdy){
#if 0
  return textureGrad(tex, uv, duvdx, duvdy);
#else

  // sample variation pattern   
  float k = clamp(textureNoise12(uv), 0.0, 1.0); // low-frequency noise lookup per hash function
    
  // compute index for 8 variation patterns in total  
  float l = k * 8.0;
  float ia = floor(l);
  float f = l - ia;
  float ib = ia + 1.0;
    
  // offsets for the different virtual patterns      
#if 1
  vec2 offa = fma(textureNoise22(vec2(13.0, 17.0) * ia), vec2(2.0), vec2(-1.0));
  vec2 offb = fma(textureNoise22(vec2(13.0, 17.0) * ib), vec2(2.0), vec2(-1.0));
#else 
  vec2 offa = sin(vec2(3.0, 7.0) * ia); // can replace with any other hash
  vec2 offb = sin(vec2(3.0, 7.0) * ib); // can replace with any other hash 
#endif

  // sample the two closest virtual patterns   
  vec4 cola = textureGrad(tex, uv + offa, duvdx, duvdy);
  vec4 colb = textureGrad(tex, uv + offb, duvdx, duvdy);
    
  // interpolate between the two virtual patterns  
  return mix(cola, colb, smoothstep(0.2, 0.8, f - (0.1 * dot(cola - colb, vec4(1.0)))));
#endif
}

vec3 multiplanarP;
vec3 multiplanarDX;
vec3 multiplanarDY;

float multiplanarK;

#define TRIPLANAR
#ifdef TRIPLANAR

// Triplanar

vec3 multiplanarM;

vec4 multiplanarTexture(const in sampler2D tex, float scale){
  return (textureNoTile(tex, multiplanarP.yz * scale, multiplanarDX.yz * scale, multiplanarDY.yz * scale) * multiplanarM.x) +
         (textureNoTile(tex, multiplanarP.zx * scale, multiplanarDX.zx * scale, multiplanarDY.zx * scale) * multiplanarM.y) + 
         (textureNoTile(tex, multiplanarP.xy * scale, multiplanarDX.xy * scale, multiplanarDY.xy * scale) * multiplanarM.z);
}
#else

// Biplanar

ivec3 multiplanarMA;
ivec3 multiplanarMI;
ivec3 multiplanarME;
vec2 multiplanarM;

vec4 multiplanarTexture(const in sampler2D tex, float scale){
 return (textureNoTile(
            tex, 
            vec2(multiplanarP[multiplanarMA.y], multiplanarP[multiplanarMA.z]) * scale,
            vec2(multiplanarDX[multiplanarMA.y], multiplanarDX[multiplanarMA.z]) * scale,
            vec2(multiplanarDY[multiplanarMA.y], multiplanarDY[multiplanarMA.z]) * scale
          ) * multiplanarM.x
        ) +
        (textureNoTile(
           tex, 
           vec2(multiplanarP[multiplanarME.y], multiplanarP[multiplanarME.z]) * scale,
           vec2(multiplanarDX[multiplanarME.y], multiplanarDX[multiplanarME.z]) * scale,
           vec2(multiplanarDY[multiplanarME.y], multiplanarDY[multiplanarME.z]) * scale
          ) * multiplanarM.y
        );
}

#endif

void main(){

  envMapMaxLevelGGX = max(0.0, textureQueryLevels(uImageBasedLightingEnvMaps[0]) - 1.0);

  vec3 sphereNormal = normalize(inBlock.sphereNormal.xyz); // re-normalize, because of vertex interpolation

  vec3 normal = normalize((planetData.normalMatrix * vec4(texturePlanetOctahedralMap(uTextures[1], sphereNormal).xyz, 0.0)).xyz);
  vec3 tangent = normalize(cross((abs(normal.y) < 0.999999) ? vec3(0.0, 1.0, 0.0) : vec3(0.0, 0.0, 1.0), normal));
  vec3 bitangent = normalize(cross(normal, tangent));

  vec3 viewDirection = normalize(-inBlock.cameraRelativePosition);

  multiplanarP = inBlock.worldSpacePosition;

  multiplanarDX = dFdx(multiplanarP);
  multiplanarDY = dFdy(multiplanarP);

  multiplanarK = 6.0;

#ifdef TRIPLANAR

  multiplanarM = pow(abs(normal), vec3(multiplanarK));
  multiplanarM /= (multiplanarM.x + multiplanarM.y + multiplanarM.z);

#else

  vec3 absNormal = abs(normal);

  multiplanarMA = ((absNormal.x > absNormal.y) && (absNormal.x > absNormal.z)) ? ivec3(0, 1, 2) : ((absNormal.y > absNormal.z) ? ivec3(1, 2, 0) : ivec3(2, 0, 1));    
  multiplanarMI = ((absNormal.x < absNormal.y) && (absNormal.x < absNormal.z)) ? ivec3(0, 1, 2) : ((absNormal.y < absNormal.z) ? ivec3(1, 2, 0) : ivec3(2, 0, 1));
  multiplanarME = ivec3(3) - (multiplanarMI + multiplanarMA);
  multiplanarM = pow(clamp((vec2(absNormal[multiplanarMA.x], absNormal[multiplanarME.x]) - vec2(0.5773)) / vec2(1.0 - 0.5773), vec2(0.0), vec2(1.0)), vec2(multiplanarK * (1.0 / 8.0)));
  multiplanarM /= (multiplanarM.x + multiplanarM.y);

#endif

  const float specularWeight = 1.0;

  vec2 texUV = vec2(0.0); 

  Material material = planetData.materials[0];

  // Textures are stored in pairs, first as linear, then as sRGB.  

  float materialScale = GetMaterialScale(material);

  vec4 baseColor = multiplanarTexture(u2DTextures[(GetMaterialAlbedoTextureIndex(material) << 1) | 1], materialScale);

  vec4 normalHeight = multiplanarTexture(u2DTextures[(GetMaterialNormalHeightTextureIndex(material) << 1) | 0], materialScale);

  vec3 workNormal = normalize(mat3(tangent, bitangent, normal) * normalize(fma(normalHeight.xyz, vec3(2.0), vec3(-1.0))));

  vec4 occlusionRoughnessMetallic = multiplanarTexture(u2DTextures[(GetMaterialOcclusionRoughnessMetallicTextureIndex(material) << 1) | 0], materialScale);
 
  ambientOcclusion = clamp(occlusionRoughnessMetallic.x, 0.0, 1.0);

  vec2 metallicRoughness = clamp(occlusionRoughnessMetallic.zy, vec2(0.0, 1e-3), vec2(1.0));

  vec4 diffuseColorAlpha = vec4(max(vec3(0.0), baseColor.xyz * (1.0 - metallicRoughness.x)), baseColor.w);

  vec3 F0 = mix(vec3(0.04), baseColor.xyz, metallicRoughness.x);

  float perceptualRoughness = metallicRoughness.y;

  float kernelRoughness;
  {
    const float SIGMA2 = 0.15915494, KAPPA = 0.18;        
    vec3 dx = dFdx(workNormal), dy = dFdy(workNormal);
    kernelRoughness = min(KAPPA, (2.0 * SIGMA2) * (dot(dx, dx) + dot(dy, dy)));
    perceptualRoughness = sqrt(clamp((perceptualRoughness * perceptualRoughness) + kernelRoughness, 0.0, 1.0));
  }  

  float litIntensity = 1.0;

  vec3 diffuseOutput = vec3(0.0);
  vec3 specularOutput = vec3(0.0);

  float iblWeight = 1.0;

  diffuseOutput += getIBLRadianceLambertian(normal, viewDirection, perceptualRoughness, diffuseColorAlpha.xyz, F0, specularWeight) * iblWeight;
  specularOutput += getIBLRadianceGGX(normal, perceptualRoughness, F0, specularWeight, viewDirection, litIntensity, imageLightBasedLightDirection) * iblWeight;
       
  //vec3(0.015625) * edgeFactor() * fma(clamp(dot(normal, vec3(0.0, 1.0, 0.0)), 0.0, 1.0), 1.0, 0.0), 1.0);
  vec4 c = vec4( baseColor.xyz * (diffuseOutput + specularOutput), 1.0);
  
  if(planetData.selected.w > 1e-6){
    float d = length(sphereNormal - normalize(planetData.selected.xyz)) - planetData.selected.w;
    float t = fwidth(d) * 1.41421356237;
    c.xyz = mix(c.xyz, mix(vec3(1.0) - clamp(c.zxy, vec3(1.0), vec3(1.0)), vec3(1.0, 0.0, 0.0), 0.5), smoothstep(t, -t, d) * 0.5);
  }

#ifdef WIREFRAME
  if((planetData.flagsResolutions.x & 0x1u) != 0){
    c.xyz = mix(c.xyz, mix(vec3(1.0) - clamp(c.zxy, vec3(1.0), vec3(1.0)), vec3(0.0, 1.0, 1.0), 0.5), edgeFactor());
  }
#endif  

  outFragColor = c;

#ifdef VELOCITY
  outVelocity = (inBlock.currentClipSpace.xy / inBlock.currentClipSpace.w) - (inBlock.previousClipSpace.xy / inBlock.previousClipSpace.w);
#endif

}