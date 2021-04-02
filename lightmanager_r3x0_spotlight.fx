
VS2PS_D3DXMesh vsDx9_SpotLight(APP2VS_D3DXMesh indata)
{
    VS2PS_D3DXMesh outdata;

    float4 scaledPos = indata.Pos * float4(1.5, 1.5, 1.0, 1.0) + float4(0.0, 0.0, 0.5, 0.0);
    outdata.Pos = mul(scaledPos, mWVP);

    outdata.TexCoord0.xy = outdata.Pos.xy/outdata.Pos.w;
    outdata.TexCoord0.xy = (outdata.TexCoord0.xy * 0.5) + 0.5;
    outdata.TexCoord0.y = 1.0 - outdata.TexCoord0.y;
    outdata.TexCoord0.x += 0.000625;
    outdata.TexCoord0.y += 0.000833;
    outdata.TexCoord0.xy = outdata.TexCoord0.xy * outdata.Pos.w;
    outdata.TexCoord0.zw = outdata.Pos.zw;

    return outdata;
}

PS2FB_DiffSpec psDx9_SpotLightNV40(VS2PS_D3DXMesh indata)
{
    PS2FB_DiffSpec outdata;

    float4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
    float4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

    float3 lightVec = LightPos.xyz - viewPos;
    float lightDist = length(lightVec);
    lightDist *= LightAttenuationRangeInv;
    float4 radialAtt = tex1D(sampler4bilin, lightDist);

    float3 lightVecN = normalize(lightVec);
    float fallOff = dot(-lightVecN, LightDir);
    float4 conicalAtt = tex1D(sampler5bilin, 1.0 - (fallOff * fallOff));

    float diff = saturate(dot(viewNormal.xyz, lightVecN)) * radialAtt * conicalAtt;
    float3 halfVec = normalize(-LightDir.xyz + normalize(viewPos.xyz-EyePos.xyz));
    float spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

    outdata.Col0 = diff * LightCol;
    outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol;

    return outdata;
}

PS2FB_DiffSpec psDx9_SpotLight(VS2PS_D3DXMesh indata)
{
    PS2FB_DiffSpec outdata;

    float4 currDiff = tex2Dproj(sampler0, indata.TexCoord0);
    float4 currSpec = tex2Dproj(sampler1, indata.TexCoord0);

    float4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
    float4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

    float3 lightVec = LightPos.xyz - viewPos;
    float lightDist = length(lightVec);
    lightDist *= LightAttenuationRangeInv;
    float4 radialAtt = tex1D(sampler4bilin, lightDist);

    float3 lightVecN = normalize(lightVec);
    float fallOff = dot(-lightVecN, LightDir);
    float4 conicalAtt = tex1D(sampler5bilin, 1.0 - (fallOff * fallOff));

    float diff = saturate(dot(viewNormal.xyz, lightVecN)) * radialAtt * conicalAtt;
    float3 halfVec = normalize(-LightDir.xyz + normalize(viewPos.xyz-EyePos.xyz));
    float spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

    outdata.Col0 = max(diff * LightCol, currDiff);
    outdata.Col1 = max(pow(spec, 36) * viewNormal.a * LightCol, currSpec);

    return outdata;
}

PS2FB_DiffSpec psDx9_SpotLightShadowNV(VS2PS_D3DXMesh indata)
{
    PS2FB_DiffSpec outdata;

    float4 currDiff = tex2Dproj(sampler0, indata.TexCoord0);
    float4 currSpec = tex2Dproj(sampler1, indata.TexCoord0);

    float4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
    float4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

    float4 lightUV = mul(viewPos, mLightVP);
    lightUV.xyz /= lightUV.w;
    lightUV.xy = lightUV.xy * float2(0.5, -0.5) + 0.5;

    float4 samples = tex2D(sampler6bilin, lightUV);

    float3 lightVec = LightPos.xyz - viewPos;
    float lightDist = length(lightVec);
    lightDist *= LightAttenuationRangeInv;
    float4 radialAtt = tex1D(sampler4bilin, lightDist);

    float3 lightVecN = normalize(lightVec);
    float fallOff = dot(-lightVecN, LightDir);
    float4 conicalAtt = tex1D(sampler5bilin, 1.0 - (fallOff * fallOff));

    float diff = saturate(dot(viewNormal.xyz, lightVecN)) * radialAtt * conicalAtt;
    float3 halfVec = normalize(-LightDir.xyz + normalize(viewPos.xyz-EyePos.xyz));
    float spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

    outdata.Col0 = max(diff * LightCol, currDiff);
    outdata.Col1 = max(pow(spec, 36) * viewNormal.a * LightCol, currSpec);

    return outdata;
}

PS2FB_DiffSpec psDx9_SpotLightShadowNV40(VS2PS_D3DXMesh indata)
{
    PS2FB_DiffSpec outdata;

    float4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
    float4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

    float4 lightUV = mul(viewPos, mLightVP);
    lightUV.xyz /= lightUV.w;
    lightUV.xy = lightUV.xy * float2(0.5, -0.5) + 0.5;

    float4 samples = tex2D(sampler6, lightUV);

    float3 lightVec = LightPos.xyz - viewPos;
    float lightDist = length(lightVec);
    lightDist *= LightAttenuationRangeInv;
    float4 radialAtt = tex1D(sampler4bilin, lightDist);

    float3 lightVecN = normalize(lightVec);
    float fallOff = dot(-lightVecN, LightDir);
    float4 conicalAtt = tex1D(sampler5bilin, 1.0 - (fallOff * fallOff));

    float diff = saturate(dot(viewNormal.xyz, lightVecN)) * radialAtt * conicalAtt;
    float3 halfVec = normalize(-LightDir.xyz + normalize(viewPos.xyz-EyePos.xyz));
    float spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

    outdata.Col0 = diff * LightCol;
    outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol;

    return outdata;
}

PS2FB_DiffSpec psDx9_SpotLightShadow(VS2PS_D3DXMesh indata)
{
    PS2FB_DiffSpec outdata;

    float4 currDiff = tex2Dproj(sampler0, indata.TexCoord0);
    float4 currSpec = tex2Dproj(sampler1, indata.TexCoord0);

    float4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
    float4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

    float4 lightUV = mul(viewPos, mLightVP);
    lightUV.xyz /= lightUV.w;
    lightUV.xy = lightUV.xy * float2(0.5, -0.5) + 0.5;

    float4 samples = tex2D(sampler6, lightUV);

    float3 lightVec = LightPos.xyz - viewPos;
    float lightDist = length(lightVec);
    lightDist *= LightAttenuationRangeInv;
    float4 radialAtt = tex1D(sampler4bilin, lightDist);

    float3 lightVecN = normalize(lightVec);
    float fallOff = dot(-lightVecN, LightDir);
    float4 conicalAtt = tex1D(sampler5bilin, 1.0 - (fallOff * fallOff));

    float diff = saturate(dot(viewNormal.xyz, lightVecN)) * radialAtt * conicalAtt;
    float3 halfVec = normalize(-LightDir.xyz + normalize(viewPos.xyz-EyePos.xyz));
    float spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

    outdata.Col0 = max(diff * LightCol, currDiff);
    outdata.Col1 = max(pow(spec, 36) * viewNormal.a * LightCol, currSpec);

    return outdata;
}

VS2PS_D3DXMesh vsDx9_SpotProjector(APP2VS_D3DXMesh indata)
{
    VS2PS_D3DXMesh outdata;

    float near = 0.01;
    float far = 10;
    float vdist = far-near;

    float4 properPos = indata.Pos + float4(0, 0, 0.5, 0);
    outdata.Pos = mul(properPos, mWVP);

    outdata.TexCoord0.xy = outdata.Pos.xy/outdata.Pos.w;
    outdata.TexCoord0.xy = (outdata.TexCoord0.xy * 0.5) + 0.5;
    outdata.TexCoord0.y = 1.0 - outdata.TexCoord0.y;
    outdata.TexCoord0.x += 0.000625;
    outdata.TexCoord0.y += 0.000833;
    outdata.TexCoord0.xy = outdata.TexCoord0.xy * outdata.Pos.w;
    outdata.TexCoord0.zw = outdata.Pos.zw;

    return outdata;
}

PS2FB_DiffSpec psDx9_SpotProjectorNV40(VS2PS_D3DXMesh indata)
{
    PS2FB_DiffSpec outdata;

    float4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
    float4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

    float4 lightUV = mul(viewPos, mLightVP);
    lightUV.xy /= lightUV.w;
    lightUV.xy = lightUV.xy * 0.5 + 0.5;
    float4 headlight = tex2D(sampler5bilin, lightUV);

    float3 lightVec = LightPos.xyz - viewPos;
    float lightDist = length(lightVec);
    lightDist *= LightAttenuationRangeInv;
    float4 radialAtt = tex1D(sampler4bilin, lightDist);

    float3 lightVecN = normalize(lightVec);

    float diff = saturate(dot(viewNormal.xyz, lightVecN)) * radialAtt;
    float3 halfVec = normalize(-LightDir.xyz + normalize(viewPos.xyz-EyePos.xyz));
    float spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

    diff *= saturate(dot(headlight.rgb, vProjectorMask.rgb)) * saturate(dot(-LightDir.xyz, lightVec));
    outdata.Col0 = diff * LightCol;
    outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol;

    return outdata;
}

PS2FB_DiffSpec psDx9_SpotProjector(VS2PS_D3DXMesh indata)
{
    PS2FB_DiffSpec outdata;

    float4 currDiff = tex2Dproj(sampler0, indata.TexCoord0);
    float4 currSpec = tex2Dproj(sampler1, indata.TexCoord0);

    float4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
    float4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

    float4 lightUV = mul(viewPos, mLightVP);
    lightUV.xy /= lightUV.w;
    lightUV.xy = lightUV.xy * 0.5 + 0.5;
    float4 headlight = tex2D(sampler5bilin, lightUV);

    float3 lightVec = LightPos.xyz - viewPos;
    float lightDist = length(lightVec);
    lightDist *= LightAttenuationRangeInv;
    float4 radialAtt = tex1D(sampler4bilin, lightDist);

    float3 lightVecN = normalize(lightVec);

    float diff = saturate(dot(viewNormal.xyz, lightVecN)) * radialAtt;
    float3 halfVec = normalize(-LightDir.xyz + normalize(viewPos.xyz-EyePos.xyz));
    float spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

    diff *= saturate(dot(headlight.rgb, vProjectorMask.rgb)) * saturate(dot(-LightDir.xyz, lightVec));
    outdata.Col0 = max(diff * LightCol, currDiff);
    outdata.Col1 = max(pow(spec, 36) * viewNormal.a * LightCol, currSpec);

    return outdata;
}

PS2FB_DiffSpec psDx9_SpotProjectorShadowNV(VS2PS_D3DXMesh indata)
{
    PS2FB_DiffSpec outdata;

    float4 currDiff = tex2Dproj(sampler0, indata.TexCoord0);
    float4 currSpec = tex2Dproj(sampler1, indata.TexCoord0);

    float4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
    float4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

    float4 lightUV = mul(viewPos, mLightVP);
    lightUV.xyz /= lightUV.w;

    float2 headlightuv = lightUV.xy * float2(0.5, 0.5) + 0.5;
    float4 headlight = tex2D(sampler5bilin, headlightuv);

    float4 avgSamples = tex2D(sampler6bilin, lightUV);

    float3 lightVec = LightPos.xyz - viewPos;
    float lightDist = length(lightVec);
    lightDist *= LightAttenuationRangeInv;
    float4 radialAtt = tex1D(sampler4bilin, lightDist);

    float3 lightVecN = normalize(lightVec);

    float diff = saturate(dot(viewNormal.xyz, lightVecN)) * radialAtt;
    float3 halfVec = normalize(-LightDir.xyz + normalize(viewPos.xyz-EyePos.xyz));
    float spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

    diff *= (dot(headlight.rgb, vProjectorMask.rgb));
    diff *= avgSamples * saturate(dot(-LightDir.xyz, lightVec));
    outdata.Col0 = max(diff * LightCol, currDiff);
    outdata.Col1 = max(pow(spec, 36) * viewNormal.a * LightCol, currSpec);

    return outdata;
}

PS2FB_DiffSpec psDx9_SpotProjectorShadowNV40(VS2PS_D3DXMesh indata)
{
    PS2FB_DiffSpec outdata;

    float4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
    float4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

    float4 lightUV = mul(viewPos, mLightVP);
    lightUV.xyz	 /= lightUV.w;


    float2 headlightuv = lightUV.xy * float2(0.5, 0.5) + 0.5;
    float4 headlight = tex2D(sampler5bilin, headlightuv);

    lightUV.xy = saturate(lightUV.xy * float2(0.5, -0.5) + 0.5);
    lightUV.xy = lightUV.xy * vViewportMap.zw + vViewportMap.xy;

    float texel = 1.0 / 1024.0;
    const float epsilon = 0.005;
    float4 samples;
    samples.x = tex2D(sampler6, lightUV);
    samples.y = tex2D(sampler6, lightUV + float2(texel, 0));
    samples.z = tex2D(sampler6, lightUV + float2(0, texel));
    samples.w = tex2D(sampler6, lightUV + float2(texel, texel));
    float4 avgSamples = (samples.xyzw+epsilon) > lightUV.zzzz;
    avgSamples = dot(avgSamples, 0.25);

    float3 lightVec = LightPos.xyz - viewPos;
    float lightDist = length(lightVec);
    lightDist *= LightAttenuationRangeInv;
    float4 radialAtt = tex1D(sampler4bilin, lightDist);

    float3 lightVecN = normalize(lightVec);

    float diff = saturate(dot(viewNormal.xyz, lightVecN)) * radialAtt;
    float3 halfVec = normalize(-LightDir.xyz + normalize(viewPos.xyz-EyePos.xyz));
    float spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

    diff *= (dot(headlight.rgb, vProjectorMask.rgb));
    diff *= avgSamples * saturate(dot(-LightDir.xyz, lightVec));
    outdata.Col0 = diff * LightCol;
    outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol;

    return outdata;
}

PS2FB_DiffSpec psDx9_SpotProjectorShadow(VS2PS_D3DXMesh indata)
{
    PS2FB_DiffSpec outdata;

    float4 currDiff = tex2Dproj(sampler0, indata.TexCoord0);
    float4 currSpec = tex2Dproj(sampler1, indata.TexCoord0);

    float4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
    float4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

    float4 lightUV = mul(viewPos, mLightVP);
    lightUV.xyz	 /= 1.1* lightUV.w;

    float2 headlightuv = lightUV.xy * float2(0.5, 0.5) + 0.5;
    float4 headlight = tex2D(sampler5bilin, headlightuv);

    lightUV.xy = lightUV.xy * float2(0.5, -0.5) + 0.5;
    lightUV.xy = saturate(lightUV.xy * vViewportMap.zw + vViewportMap.xy);

    float texel = 1.0 / 1024.0;
    const float epsilon = 0.005;
    float4 samples;
    samples.x = tex2D(sampler6, lightUV);
    samples.y = tex2D(sampler6, lightUV + float2(texel, 0.0));
    samples.z = tex2D(sampler6, lightUV + float2(0.0, texel));
    samples.w = tex2D(sampler6, lightUV + float2(texel, texel));
    float4 avgSamples = (samples.xyzw+epsilon) > lightUV.zzzz;
    avgSamples = dot(avgSamples, 0.25);

    float3 lightVec = LightPos.xyz - viewPos;
    float lightDist = length(lightVec);
    lightDist *= LightAttenuationRangeInv;
    float4 radialAtt = tex1D(sampler4bilin, lightDist);

    float3 lightVecN = normalize(lightVec);

    float diff = saturate(dot(viewNormal.xyz, lightVecN)) * radialAtt;
    float3 halfVec = normalize(-LightDir.xyz + normalize(viewPos.xyz-EyePos.xyz));
    float spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

    diff *= (dot(headlight.rgb, vProjectorMask.rgb));
    diff *= avgSamples * saturate(dot(-LightDir.xyz, lightVec));
    outdata.Col0 = max(diff * LightCol, currDiff);
    outdata.Col1 = max(pow(spec, 36) * viewNormal.a * LightCol, currSpec);

    return outdata;
}
