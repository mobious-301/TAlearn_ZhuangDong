void MainLight_float(float3 WorldPos, out float3 Direction, out float3 Color, out float DistanceAtten, out float ShadowAtten)
{
#if SHADERGRAPH_PREVIEW
    Direction = float3(0.5, 0.5, 0);
    Color = 1;
    DistanceAtten = 1;
    ShadowAtten = 1;
#else

#if SHADOWS_SCREEN
    float4 clipPos = TransformWorldToHClip(WorldPos);
    float4 shadowCoord = ComputeScreenPos(clipPos);
    ShadowAtten = SampleScreenSpaceShadowmap(shadowCoord);
#else
    float4 shadowCoord = TransformWorldToShadowCoord(WorldPos);
    ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
    float4 shadowParams = GetMainLightShadowParams();
    ShadowAtten = SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowCoord, shadowSamplingData, shadowParams, false);

#endif
    Direction = _MainLightPosition.xyz;
    Color = _MainLightColor.rgb;
    DistanceAtten = _MainLightPosition.z;
#endif
}