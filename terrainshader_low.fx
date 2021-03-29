#line 2 "TerrainShader_nv3x.fx"

// -- Low Terrain

float4 Low_PS_DirectionalLightShadows(Shared_VS2PS_DirectionalLightShadows indata) : COLOR
{
    float4 lightmap = tex2D(sampler0Clamp, indata.Tex0);
    float avgShadowValue = tex2Dproj(sampler2PointClamp, indata.ShadowTex);
    avgShadowValue = avgShadowValue == 1.0f;

    float4 light = saturate(lightmap.z * vGIColor * 2.0) * 0.5;
    if (avgShadowValue < lightmap.y)
        light.w = 1.0 - saturate(4.0 - indata.Z.x) + avgShadowValue.x;
    else
        light.w = lightmap.y;

    return light;
}

technique Low_Terrain
{
    pass ZFillLightmap // p0
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = FALSE;
        FogEnable = false;

        VertexShader = compile vs_2_a Shared_VS_ZFillLightmap();
        PixelShader = compile ps_2_a Shared_PS_ZFillLightmap();

    }

    pass pointlight // p1
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        VertexShader = compile vs_2_a Shared_VS_PointLight();
        PixelShader = compile ps_2_a Shared_PS_PointLight();
    }

    pass LowDetail // p3
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        FogEnable = true;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_2_a Shared_VS_LowDetail();
        PixelShader = compile ps_2_a Shared_PS_LowDetail();
    }

    pass DirectionalLightShadows // p7
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_2_a Shared_VS_DirectionalLightShadows();
        PixelShader = compile ps_2_a Low_PS_DirectionalLightShadows();
    }

    pass DynamicShadowmap // p9
    {
        CullMode = CW;
        ZEnable = FALSE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = TRUE;
        SrcBlend = DESTCOLOR;
        DestBlend = ZERO;
        VertexShader = compile vs_2_a Shared_VS_DynamicShadowmap();
        PixelShader = compile ps_2_a Shared_PS_DynamicShadowmap();
    }

    pass underWater // p14
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        FogEnable = false;
        VertexShader = compile vs_2_a Shared_VS_UnderWater();
        PixelShader = compile ps_2_a Shared_PS_UnderWater();
    }
}

technique Low_SurroundingTerrain
{
    pass p0 // Normal
    {
        CullMode = CW;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        AlphaBlendEnable = FALSE;
        FogEnable = true;
        VertexShader = compile vs_2_a Shared_VS_STNormal();
        PixelShader = compile ps_2_a Shared_PS_STNormal();
    }
}