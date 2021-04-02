
VS2PS_D3DXMesh vsDx9_BlitBackLightContribPoint(APP2VS_D3DXMesh indata)
{
    VS2PS_D3DXMesh outdata;

    float3 wPos = indata.Pos * LightAttenuationRange + LightWorldPos.xyz;
    outdata.Pos = mul(float4(wPos, 1.0), mVP);

    outdata.TexCoord0.xy  = (outdata.Pos.xy / outdata.Pos.ww) * 0.5 + 0.5;
    outdata.TexCoord0.y   = 1.0 - outdata.TexCoord0.y;
    outdata.TexCoord0.xy += float2(0.000625, 0.000833);
    outdata.TexCoord0.xy  = outdata.TexCoord0.xy * outdata.Pos.ww;
    outdata.TexCoord0.zw  = outdata.Pos.zw;
    return outdata;
}

VS2PS_D3DXMesh vsDx9_BlitBackLightContribSpot(APP2VS_D3DXMesh indata)
{
    VS2PS_D3DXMesh outdata;

    float4 scaledPos = indata.Pos * float4(1.5, 1.5, 1.0, 1.0) + float4(0.0, 0.0, 0.5, 0.0);
    outdata.Pos = mul(scaledPos, mWVP);

    outdata.TexCoord0.xy  = (outdata.Pos.xy / outdata.Pos.ww) * 0.5 + 0.5;
    outdata.TexCoord0.y   = 1.0 - outdata.TexCoord0.y;
    outdata.TexCoord0.xy += float2(0.000625, 0.000833);
    outdata.TexCoord0.xy  = outdata.TexCoord0.xy * outdata.Pos.w;
    outdata.TexCoord0.zw  = outdata.Pos.zw;
    return outdata;
}

VS2PS_D3DXMesh vsDx9_BlitBackLightContribSpotProjector(APP2VS_D3DXMesh indata)
{
    VS2PS_D3DXMesh outdata;

    float4 properPos = indata.Pos + float4(0.0, 0.0, 0.5, 0.0);
    outdata.Pos = mul(properPos, mWVP);

    outdata.TexCoord0.xy  = (outdata.Pos.xy / outdata.Pos.ww) * 0.5 + 0.5;
    outdata.TexCoord0.y   = 1.0 - outdata.TexCoord0.y;
    outdata.TexCoord0.xy += float2(0.000625, 0.000833);
    outdata.TexCoord0.xy  = outdata.TexCoord0.xy * outdata.Pos.w;
    outdata.TexCoord0.zw  = outdata.Pos.zw;

    return outdata;
}

PS2FB_DiffSpec psDx9_BlitBackLightContrib(VS2PS_D3DXMesh indata)
{
    PS2FB_DiffSpec outdata;
    outdata.Col0 = tex2Dproj(sampler0, indata.TexCoord0);
    outdata.Col1 = tex2Dproj(sampler1, indata.TexCoord0);
    return outdata;
}

VS2PS_Quad vsDx9_Combine(APP2VS_Quad indata)
{
    VS2PS_Quad outdata;
    outdata.Pos = float4(indata.Pos.x, indata.Pos.y, 0.0, 1.0);
    outdata.TexCoord0 = indata.TexCoord0;
    return outdata;
}

PS2FB_Combine psDx9_Combine(VS2PS_Quad indata)
{
    PS2FB_Combine outdata;

    float4 lightmap = tex2D(sampler0, indata.TexCoord0);
    float4 diffTex = tex2D(sampler1, indata.TexCoord0);
    float4 diff1 = tex2D(sampler2, indata.TexCoord0);
    float4 spec1 = tex2D(sampler3, indata.TexCoord0);

    float4 diffTot = lightmap + LightmapIntensityBias + diff1;
    float4 specTot = spec1;

    outdata.Col0 = diffTot * diffTex + specTot;

    return outdata;
}

PS2FB_Combine psDx9_CombineTransparent(VS2PS_Quad indata)
{
    PS2FB_Combine outdata;

    float4 lightmap = tex2D(sampler0, indata.TexCoord0);
    float4 diffTex = tex2D(sampler1, indata.TexCoord0);
    float4 diff1 = tex2D(sampler2, indata.TexCoord0);
    float4 spec1 = tex2D(sampler3, indata.TexCoord0);

    float4 diffTot = lightmap + diff1;
    float4 specTot = spec1;

    outdata.Col0 = diffTot * diffTex + specTot;
    outdata.Col0.a = diffTex.a;

    return outdata;
}
