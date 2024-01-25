#if defined(LIGHTING_GLOBALS)


#elif defined(LIGHTING_IMPLEMENTATION)

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
#endif // !defined(REFLECTIVESHADOWMAPOUTPUT)
            float lightAttenuationEx = lightAttenuation;
#endif // SHADOWS
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
#endif // !defined(REFLECTIVESHADOWMAPOUTPUT)
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
            if((lightAttenuation > 0.0) 
#ifdef CAN_HAVE_EXTENDED_PBR_MATERIAL
               || ((flags & ((1u << 7u) | (1u << 8u))) != 0u)
#endif
               ){
#if defined(REFLECTIVESHADOWMAPOUTPUT)
              diffuseOutput += lightAttenuation * light.colorIntensity.xyz * light.colorIntensity.w * diffuseColorAlpha.xyz * max(0.0, dot(normal, lightDirection));
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
#endif // TRANSMISSION
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