
float4 calcShadowProjCoords(float4 Pos, float4x4 matTrap, float4x4 matLight)
{
    float4 shadowcoords = mul(Pos, matTrap);
    float2 lightZW = mul(Pos, matLight).zw;
    shadowcoords.z = (lightZW.x * shadowcoords.w) / lightZW.y; // (zL*wT)/wL == zL/wL post homo
    return shadowcoords;
}

VS2PS_ShadowMap vsShadowMap(appdata input)
{
    VS2PS_ShadowMap Out;

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    float4 unpackPos = float4(input.Pos.xyz * PosUnpack, 1.0);
    float3 Pos = mul(unpackPos, mOneBoneSkinning[IndexArray[0]]);

    Out.HPos = calcShadowProjCoords(float4(Pos.xyz, 1.0), vpLightTrapezMat, vpLightMat);
    Out.PosZW = Out.HPos.zw;

    return Out;
}

float4 psShadowMap(VS2PS_ShadowMap indata) : COLOR
{
    #if NVIDIA
        return 0;
    #else
        return indata.PosZW.x / indata.PosZW.y;
    #endif
}

VS2PS_ShadowMapAlpha vsShadowMapAlpha(appdata input)
{
    VS2PS_ShadowMapAlpha Out;

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    float4 unpackPos = input.Pos * PosUnpack;
    float3 Pos = mul(unpackPos, mOneBoneSkinning[IndexArray[0]]);
    Out.HPos = calcShadowProjCoords(float4(Pos.xyz, 1.0), vpLightTrapezMat, vpLightMat);

    float4 wpos = float4(Pos.xyz, 1.0);

    Out.Tex0PosZW = float4(input.TexCoord, Out.HPos.zw);
    Out.Attenuation = 0;

    return Out;
}

float4 psShadowMapAlpha(VS2PS_ShadowMapAlpha indata) : COLOR
{
    float alpha = tex2D(sampler0, indata.Tex0PosZW.xy).a - shadowAlphaThreshold;

    #if NVIDIA
        return alpha;
    #else
        clip(alpha);
        return indata.Tex0PosZW.z / indata.Tex0PosZW.w;
    #endif
}

float4 psShadowMapAlphaNV(VS2PS_ShadowMapAlpha indata) : COLOR
{
    return indata.Tex0PosZW.z / indata.Tex0PosZW.w;
    return tex2D(sampler0, indata.Tex0PosZW.xy).a - shadowAlphaThreshold;
}

VS2PS_ShadowMap vsShadowMapPoint(appdata input)
{
    VS2PS_ShadowMap Out;

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    float3 wPos = mul(input.Pos*PosUnpack, mOneBoneSkinning[IndexArray[0]]);
    float3 hPos = wPos.xyz - lightPos;
    hPos.z *= paraboloidValues.x;

    float d = length(hPos.xyz);
    hPos.xyz /= d;
    hPos.z += 1.0;
    Out.HPos.xy = hPos.xy / hPos.zz;
    Out.HPos.z = (d * paraboloidZValues.x) + paraboloidZValues.y;
    Out.HPos.w = 1.0;

    Out.PosZW = Out.HPos.zw;

    return Out;
}

VS2PS_ShadowMapAlpha vsShadowMapPointAlpha(appdata input)
{
    VS2PS_ShadowMapAlpha Out;

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    float3 wPos = mul(input.Pos*PosUnpack, mOneBoneSkinning[IndexArray[0]]);
    float3 hPos = wPos.xyz - lightPos;
    hPos.z *= paraboloidValues.x;

    float d = length(hPos.xyz);
    hPos.xyz /= d;
    hPos.z += 1;
    Out.HPos.xy = hPos.xy / hPos.zz;
    Out.HPos.z = (d * paraboloidZValues.x) + paraboloidZValues.y;
    Out.HPos.w = 1.0;

    Out.Tex0PosZW = float4(input.TexCoord, Out.HPos.zw);

    // SHADOWS
    Out.Attenuation = 0.0;

    return Out;
}

float4 psShadowMapPointAlpha(VS2PS_ShadowMapAlpha indata) : COLOR
{
    clip(tex2D(sampler0, indata.Tex0PosZW.xy).a-shadowAlphaThreshold);
    clip(indata.Tex0PosZW.z);
    return indata.Tex0PosZW.z;
}

float4 psShadowMapNV(VS2PS_ShadowMap indata) : COLOR
{
    return indata.PosZW.x / indata.PosZW.y;
}