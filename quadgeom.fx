#line 2 "QuadGeom.fx"

texture texture0: TEXLAYER0;
sampler sampler0 = sampler_state
{
    Texture = (texture0);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MipFilter = POINT;
    MinFilter = POINT;
    MagFilter = POINT;
};

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

// Note about D3DTA_DIFFUSE from https://docs.microsoft.com/en-us/windows/win32/direct3d9/d3dta
// If the vertex does not contain a diffuse color, the default color is 0xffffffff (White)
float4 psFFP(VS2PS input) : COLOR
{
    return tex2D(sampler0, input.Tex);
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

        VertexShader = compile vs_2_a vsFFP();
        PixelShader = compile ps_2_a psFFP();
    }
}
