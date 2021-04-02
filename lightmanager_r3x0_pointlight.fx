
VS2PS_D3DXMesh vsDx9_PointLight(APP2VS_D3DXMesh indata)
{
    VS2PS_D3DXMesh outdata;

    float3 wPos = indata.Pos * LightAttenuationRange + LightWorldPos.xyz;
    outdata.Pos = mul(float4(wPos, 1.0), mVP);

    outdata.TexCoord0.xy  = (outdata.Pos.xy / outdata.Pos.ww) * 0.5 + 0.5;
    outdata.TexCoord0.y   = 1.0 - outdata.TexCoord0.y;
    outdata.TexCoord0.xy += float2(0.000625, 0.000833);
    outdata.TexCoord0.xy  = outdata.TexCoord0.xy * outdata.Pos.w;
    outdata.TexCoord0.zw  = outdata.Pos.zw;
    return outdata;
}

PS2FB_DiffSpec psDx9_PointLight(VS2PS_D3DXMesh indata)
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

    float diff = saturate(dot(viewNormal.xyz, normalize(lightVec))) * radialAtt;
    float3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
    float spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

    outdata.Col0 = max(diff * LightCol, currDiff);
    outdata.Col1 = max(pow(spec, 36.0) * viewNormal.a * LightCol, currSpec);

    return outdata;
}

PS2FB_DiffSpec psDx9_PointLightNV40(VS2PS_D3DXMesh indata)
{
    PS2FB_DiffSpec outdata;

    float4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
    float4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

    float3 lightVec = LightPos.xyz - viewPos;
    float lightDist = length(lightVec);
    lightDist *= LightAttenuationRangeInv;

    float4 radialAtt = tex1D(sampler4bilin, lightDist);

    float diff = saturate(dot(viewNormal.xyz, normalize(lightVec))) * radialAtt;
    float3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
    float spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

    outdata.Col0 = diff * LightCol;
    outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol;

    return outdata;
}

PS2FB_DiffSpec psDx9_PointLight2(VS2PS_D3DXMesh indata)
{
    PS2FB_DiffSpec outdata;

    float4 currDiff = tex2Dproj(sampler0, indata.TexCoord0);
    float4 currSpec = tex2Dproj(sampler1, indata.TexCoord0);

    float4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
    float4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);
    float4 lightmap = tex2Dproj(sampler5, indata.TexCoord0);

    float3 lightVec = LightPos.xyz - viewPos;
    float lightDist = length(lightVec);
    lightDist *= LightAttenuationRangeInv;

    float4 radialAtt = tex1D(sampler4bilin, lightDist);

    float diff = saturate(dot(viewNormal.xyz, normalize(lightVec))) * radialAtt;
    float3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
    float spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

    outdata.Col0 = max(diff * LightCol, currDiff);
    outdata.Col1 = max(pow(spec, 36.0) * viewNormal.a * LightCol, currSpec);

    return outdata;
}

PS2FB_DiffSpec psDx9_PointLightShadowNV(VS2PS_D3DXMesh indata)
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

    float3 paraPos1 = -lightVec;
    paraPos1 = normalize(paraPos1);
    paraPos1 = mul(paraPos1, mCamVI);
    float hemiSel = paraPos1.z;
    float3 paraPos2 = paraPos1 - float3(0.0, 0.0, 1.0);
    paraPos1 += float3(0.0, 0.0, 1.0);

    paraPos1.xy /= paraPos1.z;
    paraPos2.xy /= paraPos2.z;

    float paraPosZ = lightDist*paraboloidZValues.x + paraboloidZValues.y;

    paraPos1.xy = saturate(paraPos1.xy * float2(0.5, -0.5) + 0.5);
    paraPos1.xy = paraPos1.xy * vViewportMap.wz + vViewportMap.xy;
    paraPos2.xy = saturate(paraPos2.xy * float2(-0.5, 0.5) + 0.5);
    paraPos2.xy = paraPos2.xy * vViewportMap.wz + vViewportMap.xy;

    float2 avgPara;
    avgPara.x = tex2Dproj(sampler5bilin, float4(paraPos1.xy, paraPosZ, 1));
    avgPara.y = tex2Dproj(sampler6bilin, float4(paraPos2.xy, paraPosZ, 1));

    float diff = saturate(dot(viewNormal.xyz, normalize(lightVec))) * radialAtt;
    float3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
    float spec = 0.0;

    float shad = hemiSel >= 0 ? avgPara.x : avgPara.y;
    outdata.Col0 = max(diff * LightCol * shad, currDiff);
    outdata.Col1 = max(pow(spec, 36) * viewNormal.a * LightCol, currSpec);

    return outdata;
}

float4 ps_dummy() : COLOR
{
    return 0.0;
}

PS2FB_DiffSpec psDx9_PointLightShadow(VS2PS_D3DXMesh indata)
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

    float3 paraPos1 = -lightVec;
    paraPos1 = normalize(paraPos1);
    paraPos1 = mul(paraPos1, mCamVI);
    float hemiSel = paraPos1.z;
    float3 paraPos2 = paraPos1 - float3(0.0, 0.0, 1.0);
    paraPos1 += float3(0.0, 0.0, 1.0);

    paraPos1.xy /= paraPos1.z;
    paraPos2.xy /= paraPos2.z;
    float paraPosZ = lightDist*paraboloidZValues.x + paraboloidZValues.y;

    paraPos1.xy = saturate(paraPos1.xy * float2(0.5, -0.5) + 0.5);
    paraPos1.xy = paraPos1.xy * vViewportMap.wz + vViewportMap.xy;
    paraPos2.xy = saturate(paraPos2.xy * float2(-0.5, 0.5) + 0.5);
    paraPos2.xy = paraPos2.xy * vViewportMap.wz + vViewportMap.xy;

    float2 paraSamples;
    paraSamples.x = tex2D(sampler5, paraPos1);
    paraSamples.y = tex2D(sampler6, paraPos2);

    const float epsilon = 0.0075;
    float2 avgPara = (paraSamples.xy + epsilon) >= paraPosZ;

    float diff = saturate(dot(viewNormal.xyz, normalize(lightVec))) * radialAtt;
    float3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
    float spec = 0.0;

    float shad = hemiSel >= 0 ? avgPara.x : avgPara.y;
    outdata.Col0 = max(diff * LightCol * shad, currDiff);
    outdata.Col1 = max(pow(spec, 36.0) * viewNormal.a * LightCol, currSpec);

    return outdata;
}

PS2FB_DiffSpec psDx9_PointLightShadowNV40(VS2PS_D3DXMesh indata)
{
    PS2FB_DiffSpec outdata;

    float4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
    float4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

    float3 lightVec = LightPos.xyz - viewPos;
    float lightDist = length(lightVec);
    lightDist *= LightAttenuationRangeInv;
    float4 radialAtt = tex1D(sampler4bilin, lightDist);

    float3 paraPos1 = -lightVec;
    paraPos1 = normalize(paraPos1);
    paraPos1 = mul(paraPos1, mCamVI);
    float hemiSel = paraPos1.z;
    float3 paraPos2 = paraPos1 - float3(0.0, 0.0, 1.0);
    paraPos1 += float3(0.0, 0.0, 1.0);

    paraPos1.xy /= paraPos1.z;
    paraPos2.xy /= paraPos2.z;
    float paraPosZ = lightDist*paraboloidZValues.x + paraboloidZValues.y;
    paraPosZ += paraPosZ + 0.5;

    paraPos1.xy = saturate(paraPos1.xy * float2( 0.5, -0.5) + 0.5);
    paraPos1.xy = paraPos1.xy * vViewportMap.wz + vViewportMap.xy;
    paraPos2.xy = saturate(paraPos2.xy * float2(-0.5,  0.5) + 0.5);
    paraPos2.xy = paraPos2.xy * vViewportMap.wz + vViewportMap.xy;

    float2 paraSamples;
    paraSamples.x = tex2D(sampler5, paraPos1);
    paraSamples.y = tex2D(sampler6, paraPos2);

    const float epsilon = 0.0075;
    float2 avgPara = (paraSamples.xy + epsilon) >= paraPosZ;

    float diff = saturate(dot(viewNormal.xyz, normalize(lightVec))) * radialAtt;
    float3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
    float spec = 0.0;

    float shad = hemiSel >= 0 ? avgPara.x : avgPara.y;
    outdata.Col0 = diff * LightCol * shad;
    outdata.Col1 = pow(spec, 36.0) * viewNormal.a * LightCol;

    return outdata;
}

VS2PS_D3DXMesh2 vsDx9_PointLightGlow(APP2VS_D3DXMesh indata)
{
    VS2PS_D3DXMesh2 outdata;

    float scale = LightAttenuationRange;
    float3 wPos = (indata.Pos*scale) + LightWorldPos.xyz;
    outdata.Pos = mul(float4(wPos, 1.0), mVP);

    outdata.wPos = dot(normalize(EyePos-LightWorldPos.xyz),normalize(wPos-LightWorldPos.xyz));
    outdata.wPos = outdata.wPos*outdata.wPos*outdata.wPos*outdata.wPos;
    return outdata;
}

float4 psDx9_PointLightGlow(VS2PS_D3DXMesh2 indata) : COLOR
{
    return float4(LightCol * indata.wPos.rgb, 1.0);
}
