#line 2 "QuadGeom.fx"

texture texture0: TEXLAYER0;

struct APP2VS
{
    float2 Pos : POSITION;
};

struct VS2PS
{
    float4 Pos : POSITION;
    float2 Tex : TEXCOORD0;
};

VS2PS vsFFP(APP2VS indata)
{
    VS2PS outdata;
    outdata.Pos. = float4(indata.Pos.xy, 0.0f, 1.0f);
    outdata.Tex.x = indata.Pos.x * 0.5 + 0.5;
    outdata.Tex.y = 1.0f - (indata.Pos.y * 0.5 + 0.5);
    return outdata;
}

technique TexturedQuad
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        // App alpha/depth settings
        CullMode = NONE;
        ZEnable = TRUE;
        ZFunc = ALWAYS;
        ZWriteEnable = TRUE;

        // SET UP STENCIL TO ONLY WRITE WHERE STENCIL IS SET TO ZERO
        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilPass = ZERO;
        StencilRef = 0;

        // App pixel settings
        ColorOp[0] = SELECTARG2;
        ColorArg1[0] = DIFFUSE;
        ColorArg2[0] = TEXTURE;
        AlphaOp[0] = MODULATE;
        AlphaArg1[0] = DIFFUSE;
        AlphaArg2[0] = TEXTURE;
        Texture[0] = (texture0);
        AddressU[0] = CLAMP;
        AddressV[0] = CLAMP;
        MipFilter[0] = POINT;
        MinFilter[0] = POINT;
        MagFilter[0] = POINT;

        VertexShader = compile vs_2_a vsFFP();
        PixelShader = NULL;
    }
}

