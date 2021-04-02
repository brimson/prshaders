
VS2PS_Quad vsDx9_SunLightDynamicObjects(APP2VS_Quad indata)
{
    VS2PS_Quad outdata;
    outdata.Pos = float4(indata.Pos.x, indata.Pos.y, 0.0, 1.0);
    outdata.TexCoord0 = indata.TexCoord0;
    return outdata;
}

VS2PS_Quad vsDx9_SunLightStaticObjects(APP2VS_Quad indata)
{
    VS2PS_Quad outdata;
    outdata.Pos = float4(indata.Pos.x, indata.Pos.y, 0.0, 1.0);
    outdata.TexCoord0 = indata.TexCoord0;
    return outdata;
}

PS2FB_DiffSpec psDx9_SunLightDynamicObjects(VS2PS_Quad indata)
{
    PS2FB_DiffSpec outdata;

    float4 viewNormal = tex2D(sampler0, indata.TexCoord0);
    float3 viewPos = tex2D(sampler1, indata.TexCoord0);
    float4 lightMap = tex2D(sampler2, indata.TexCoord0);

    float diff = saturate(dot(viewNormal.xyz, -LightDir.xyz));
    float3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));

    float spec = saturate(dot(viewNormal.xyz, halfVec));
    float shadowIntensity = saturate(lightMap.a+ShadowIntensityBias);
    outdata.Col0 = diff * LightCol * shadowIntensity;
    outdata.Col1 = pow(spec, 36.0) * viewNormal.a * LightCol * shadowIntensity * shadowIntensity;
    return outdata;
}

PS2FB_DiffSpec psDx9_SunLightDynamicSkinObjects(VS2PS_Quad indata)
{
    PS2FB_DiffSpec outdata;

    float4 viewNormal = tex2D(sampler0, indata.TexCoord0);
    float3 viewPos = tex2D(sampler1, indata.TexCoord0);
    float4 lightMap = tex2D(sampler2, indata.TexCoord0);

    float3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
    float specTmp = dot(viewNormal.xyz, halfVec) + 0.5;
    float spec = saturate(specTmp / 1.5);

    float shadowIntensity = saturate(lightMap.a+ShadowIntensityBias);
    outdata.Col0 = 0.0;
    outdata.Col1 = pow(spec, 16.0) * viewNormal.a * LightCol * shadowIntensity * shadowIntensity;

    return outdata;
}

PS2FB_DiffSpec psDx9_SunLightStaticObjects(VS2PS_Quad indata)
{
    PS2FB_DiffSpec outdata;

    float4 viewNormal = tex2D(sampler0, indata.TexCoord0);
    float3 viewPos = tex2D(sampler1, indata.TexCoord0);
    float4 lightMap = tex2D(sampler2, indata.TexCoord0);

    float diff = saturate(dot(viewNormal.xyz, -LightDir.xyz));
    float3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
    float spec = saturate(dot(viewNormal.xyz, halfVec));

    float shadowIntensity = saturate(lightMap.a+ShadowIntensityBias);
    outdata.Col0 = diff * LightCol * shadowIntensity;
    outdata.Col1 = pow(spec, 36.0) * viewNormal.a * LightCol * shadowIntensity * shadowIntensity;

    return outdata;
}

PS2FB_DiffSpec psDx9_SunLightTransparent(VS2PS_Quad indata)
{
    PS2FB_DiffSpec outdata;

    float4 viewNormal = tex2D(sampler0, indata.TexCoord0);
    float4 wPos = tex2D(sampler1, indata.TexCoord0);
    float4 diffTex = tex2D(sampler5, indata.TexCoord0);
    float diff = saturate(dot(viewNormal.xyz, -LightDir.xyz));

    outdata.Col0 = diff * LightCol * diffTex.a;
    outdata.Col1 = 0.0; //TL don't need specular decals; //pow(spec, 36) * viewNormal.a * LightCol * diffTex.a;
    return outdata;
}

VS2PS_D3DXMesh vsDx9_SunLightShadowDynamicObjects(APP2VS_D3DXMesh indata)
{
    VS2PS_D3DXMesh outdata;

    float4 scaledPos = indata.Pos + float4(0, 0, 0.5, 0);
    scaledPos = mul(scaledPos, mObjW);
    scaledPos = mul(scaledPos, mCamV);
    scaledPos = mul(scaledPos, mCamP);
    outdata.Pos = scaledPos;

    outdata.TexCoord0.xy = outdata.Pos.xy/outdata.Pos.w;
    outdata.TexCoord0.xy = (outdata.TexCoord0.xy * 0.5) + 0.5;
    outdata.TexCoord0.y = 1.0 - outdata.TexCoord0.y;
    outdata.TexCoord0.x += 0.5 / 800.0;
    outdata.TexCoord0.y += 0.5 / 600.0;
    outdata.TexCoord0.xy = outdata.TexCoord0.xy * outdata.Pos.w;
    outdata.TexCoord0.zw = outdata.Pos.zw;

    return outdata;
}

PS2FB_DiffSpec psDx9_SunLightShadowDynamicObjectsNV(VS2PS_D3DXMesh indata)
{
    PS2FB_DiffSpec outdata;

    float4 viewNormal = (tex2Dproj(sampler0, indata.TexCoord0));
    float4 viewPos = tex2Dproj(sampler1, indata.TexCoord0);

    float4 lightUV = mul(viewPos, mLightVP);
    lightUV.xy = clamp(lightUV.xy, vViewportMap.xy, vViewportMap.zw);

    float avgShadowValue = tex2Dproj(sampler3bilin, lightUV); // HW percentage closer filtering.

    float texel = 1.0 / 1024.0;
    float4 staticSamples;
    staticSamples.x = tex2D(sampler4bilin, lightUV + float2(-texel*1, -texel*2)).r;
    staticSamples.y = tex2D(sampler4bilin, lightUV + float2( texel*1, -texel*2)).r;
    staticSamples.z = tex2D(sampler4bilin, lightUV + float2(-texel*1,  texel*2)).r;
    staticSamples.w = tex2D(sampler4bilin, lightUV + float2( texel*1,  texel*2)).r;
    staticSamples.x = dot(staticSamples, 0.25);

    float diff = saturate(dot(viewNormal.xyz, -LightDir.xyz));

    float3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
    float spec = saturate(dot(viewNormal.xyz, halfVec));

    outdata.Col0 = diff * LightCol * avgShadowValue * staticSamples.x;
    outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol * avgShadowValue * staticSamples.x;

    return outdata;
}

PS2FB_DiffSpec psDx9_SunLightShadowDynamicObjects(VS2PS_D3DXMesh indata)
{
    PS2FB_DiffSpec outdata;

    float4 viewNormal = (tex2Dproj(sampler0, indata.TexCoord0));
    float4 viewPos = tex2Dproj(sampler1, indata.TexCoord0);

    float4 lightUV = mul(viewPos, mLightVP);
    lightUV.xy = clamp(lightUV.xy, vViewportMap.xy, vViewportMap.zw);

    float4 lightUV2 = mul(viewPos, mLightOccluderVP);

    float texel = 1.0 / 1024.0;
    float4 samples;
    samples.x = tex2D(sampler3, lightUV);
    samples.y = tex2D(sampler3, lightUV + float2(texel, 0));
    samples.z = tex2D(sampler3, lightUV + float2(0, texel));
    samples.w = tex2D(sampler3, lightUV + float2(texel, texel));

    float4 staticSamples;
    staticSamples.x = tex2D(sampler4bilin, lightUV + float2(-texel*1, -texel*2)).r;
    staticSamples.y = tex2D(sampler4bilin, lightUV + float2( texel*1, -texel*2)).r;
    staticSamples.z = tex2D(sampler4bilin, lightUV + float2(-texel*1,  texel*2)).r;
    staticSamples.w = tex2D(sampler4bilin, lightUV + float2( texel*1,  texel*2)).r;

    staticSamples.x = dot(staticSamples, 0.25);

    const float epsilon = 0.05;
    float4 cmpbits = (samples.xyzw + epsilon) >= saturate(lightUV.zzzz);
    float avgShadowValue = dot(cmpbits, float4(0.25, 0.25, 0.25, 0.25));

    float diff = saturate(dot(viewNormal.xyz, -LightDir.xyz));

    float3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
    float spec = saturate(dot(viewNormal.xyz, halfVec));

    outdata.Col0 = diff * LightCol * avgShadowValue * staticSamples.x;
    outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol * avgShadowValue * staticSamples.x;

    return outdata;
}

PS2FB_DiffSpec psDx9_SunLightShadowDynamic1pObjectsNV(VS2PS_D3DXMesh indata)
{
    PS2FB_DiffSpec outdata;

    float4 viewNormal = (tex2Dproj(sampler0, indata.TexCoord0));
    float4 viewPos = tex2Dproj(sampler1, indata.TexCoord0);

    float4 lightUV = mul(viewPos, mLightVP);
    lightUV.xy = clamp(lightUV.xy, vViewportMap.xy, vViewportMap.zw);

    float avgShadowValue = tex2D(sampler3bilin, lightUV); // HW percentage closer filtering.

    float texel = 1.0 / 1024.0;
    float4 staticSamples;
    staticSamples.x = tex2D(sampler4bilin, lightUV + float2(-texel*1, -texel*2)).r;
    staticSamples.y = tex2D(sampler4bilin, lightUV + float2( texel*1, -texel*2)).r;
    staticSamples.z = tex2D(sampler4bilin, lightUV + float2(-texel*1,  texel*2)).r;
    staticSamples.w = tex2D(sampler4bilin, lightUV + float2( texel*1,  texel*2)).r;
    staticSamples.x = dot(staticSamples, 0.25);

    float diff = saturate(dot(viewNormal.xyz, -LightDir.xyz));

    float3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
    float spec = saturate(dot(viewNormal.xyz, halfVec));

    float totShadow = staticSamples.x;

    outdata.Col0 =  diff * LightCol * totShadow;
    outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol * totShadow;

    return outdata;
}

PS2FB_DiffSpec psDx9_SunLightShadowDynamic1pObjects(VS2PS_D3DXMesh indata)
{
    PS2FB_DiffSpec outdata;

    float4 viewNormal = (tex2Dproj(sampler0, indata.TexCoord0));
    float4 viewPos = tex2Dproj(sampler1, indata.TexCoord0);

    float4 lightUV = mul(viewPos, mLightVP);
    lightUV.xy = clamp(lightUV.xy, vViewportMap.xy, vViewportMap.zw);

    float texel = 1.0 / 1024.0;

    float4 staticSamples;
    staticSamples.x = tex2D(sampler4bilin, lightUV + float2(-texel*1, -texel*2)).r;
    staticSamples.y = tex2D(sampler4bilin, lightUV + float2( texel*1, -texel*2)).r;
    staticSamples.z = tex2D(sampler4bilin, lightUV + float2(-texel*1,  texel*2)).r;
    staticSamples.w = tex2D(sampler4bilin, lightUV + float2( texel*1,  texel*2)).r;
    staticSamples.x = dot(staticSamples, 0.25);

    float diff = saturate(dot(viewNormal.xyz, -LightDir.xyz));

    float3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
    float spec = saturate(dot(viewNormal.xyz, halfVec));

    float totShadow = staticSamples.x;

    outdata.Col0 =  diff * LightCol * totShadow;
    outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol * totShadow;

    return outdata;
}

VS2PS_D3DXMesh vsDx9_SunLightShadowStaticObjects(APP2VS_D3DXMesh indata)
{
    VS2PS_D3DXMesh outdata;

    float4 scaledPos = indata.Pos + float4(0, 0, 0.5, 0);
    scaledPos = mul(scaledPos, mObjW);
    scaledPos = mul(scaledPos, mCamV);
    scaledPos = mul(scaledPos, mCamP);
    outdata.Pos = scaledPos;

    outdata.TexCoord0.xy = outdata.Pos.xy/outdata.Pos.w;
    outdata.TexCoord0.xy = (outdata.TexCoord0.xy * 0.5) + 0.5;
    outdata.TexCoord0.y = 1.0 - outdata.TexCoord0.y;
    outdata.TexCoord0.x += 0.000625;
    outdata.TexCoord0.y += 0.000833;
    outdata.TexCoord0.xy = outdata.TexCoord0.xy * outdata.Pos.w;
    outdata.TexCoord0.zw = outdata.Pos.zw;

    return outdata;
}

PS2FB_DiffSpec psDx9_SunLightShadowStaticObjectsNV(VS2PS_D3DXMesh indata)
{
    PS2FB_DiffSpec outdata;

    float4 viewNormal = tex2Dproj(sampler0, indata.TexCoord0);
    float4 viewPos = tex2Dproj(sampler1, indata.TexCoord0);

    float4 lightMap = tex2Dproj(sampler2, indata.TexCoord0);

    float4 lightUV = mul(viewPos, mLightVP);

    lightUV.xy = clamp(lightUV.xy, vViewportMap.xy, vViewportMap.zw);

    lightUV.z = saturate(lightUV.z) - 0.001;
    float avgShadowValue = tex2Dproj(sampler3bilin, lightUV); // HW percentage closer filtering.

    float diff = saturate(dot(viewNormal.xyz, -LightDir.xyz));
    float3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
    float spec = saturate(dot(viewNormal.xyz, halfVec));

    outdata.Col0 = diff * LightCol * saturate((lightMap.a * avgShadowValue) + ShadowIntensityBias);
    outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol * saturate(lightMap.a*avgShadowValue+ShadowIntensityBias);

    return outdata;
}

PS2FB_DiffSpec psDx9_SunLightShadowStaticObjects(VS2PS_D3DXMesh indata)
{
    PS2FB_DiffSpec outdata;

    float4 viewNormal = tex2Dproj(sampler0, indata.TexCoord0);
    float4 viewPos = tex2Dproj(sampler1, indata.TexCoord0);

    float4 lightMap = tex2Dproj(sampler2, indata.TexCoord0);

    float4 lightUV = mul(viewPos, mLightVP);

    lightUV.xy = clamp(lightUV.xy, vViewportMap.xy, vViewportMap.zw);

    float texel = 1.0 / 1024.0;
    float4 samples;
    samples.x = tex2D(sampler3, lightUV);
    samples.y = tex2D(sampler3, lightUV + float2(texel, 0));
    samples.z = tex2D(sampler3, lightUV + float2(0, texel));
    samples.w = tex2D(sampler3, lightUV + float2(texel, texel));

    const float epsilon = 0.0075;
    float4 cmpbits = (samples.xyzw + epsilon) >= saturate(lightUV.zzzz);
    float avgShadowValue = dot(cmpbits, float4(0.25, 0.25, 0.25, 0.25));

    float diff = saturate(dot(viewNormal.xyz, -LightDir.xyz));
    float3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
    float spec = saturate(dot(viewNormal.xyz, halfVec));

    outdata.Col0 = diff * LightCol * saturate((lightMap.a*avgShadowValue)+ShadowIntensityBias);
    outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol * saturate(lightMap.a*avgShadowValue+ShadowIntensityBias);

    return outdata;
}
