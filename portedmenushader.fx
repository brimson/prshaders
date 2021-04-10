#line 2 "PortedMenuShader.fx"

float4x4 mWorld : matWORLD;
float4x4 mView  : matVIEW;
float4x4 mProj  : matPROJ;

bool bAlphaBlend  : ALPHABLEND = false;
dword dwSrcBlend  : SRCBLEND   = D3DBLEND_INVSRCALPHA;
dword dwDestBlend : DESTBLEND  = D3DBLEND_SRCALPHA;

bool bAlphaTest   : ALPHATEST = false;
dword dwAlphaFunc : ALPHAFUNC = D3DCMP_GREATER;
dword dwAlphaRef  : ALPHAREF  = 0;

dword dwZEnable    : ZMODE        = D3DZB_TRUE;
dword dwZFunc      : ZFUNC        = D3DCMP_LESSEQUAL;
bool bZWriteEnable : ZWRITEENABLE = true;

texture texture0: TEXLAYER0;
sampler sampler0Clamp = sampler_state
{
    Texture = (texture0);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
};

texture texture1: TEXLAYER1;
sampler sampler1Clamp = sampler_state
{
    Texture = (texture1);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
};

sampler sampler1Wrap = sampler_state
{
    Texture = (texture1);
    AddressU = WRAP;
    AddressV = WRAP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
};

struct APP2VS
{
    float4 Pos  : POSITION;
    float4 Col  : COLOR;
    float2 Tex  : TEXCOORD0;
    float2 Tex2 : TEXCOORD1;
};

struct VS2PS
{
    float4 Pos  : POSITION;
    float4 Col  : COLOR;
    float2 Tex  : TEXCOORD0;
    float2 Tex2 : TEXCOORD1;
};

VS2PS vsFFP(APP2VS indata)
{
    VS2PS outdata;
    float4x4 mWVP = mWorld * mView * mProj;
    outdata.Pos = mul(indata.Pos, mWVP);
    outdata.Col = indata.Col;
    outdata.Tex = indata.Tex;
    outdata.Tex2 = indata.Tex2;
    return outdata;
}

float4 psQuadWTexNoTex(VS2PS indata) : COLOR
{
    return indata.Col;
}

float4 psQuadWTexOneTex(VS2PS indata) : COLOR
{
    return indata.Col * tex2D(sampler0Clamp, indata.Tex);
}

float4 psQuadWTexOneTexMasked(VS2PS indata) : COLOR
{
    float4 outcol = indata.Col * tex2D(sampler0Clamp, indata.Tex);
    outcol.a *= tex2D(sampler1Clamp, indata.Tex2).a;
    return outcol;
}

// Note about D3DTA_DIFFUSE from https://docs.microsoft.com/en-us/windows/win32/direct3d9/d3dta
// If the vertex does not contain a diffuse color, the default color is 0xffffffff (White)
float4 psFFP(VS2PS input) : COLOR
{
    float4 tex = tex2D(sampler0Clamp, input.Tex);
    return (tex + 1.0) * input.Col;
}

technique Menu { pass{ } }

technique Menu_States <bool Restore = true;>
{
    pass BeginStates { }
    pass EndStates { }
}

technique QuadWithTexture
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        0, D3DDECLTYPE_FLOAT4, D3DDECLUSAGE_COLOR, 0,
        0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0,
        0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 1,
        DECLARATION_END	// End macro
    };
>
{
    pass notex
    {
        // App alpha/depth settings
        AlphaBlendEnable = (bAlphaBlend);
        SrcBlend = (dwSrcBlend);
        DestBlend = (dwDestBlend);
        AlphaTestEnable = (bAlphaTest);
        AlphaFunc = (dwAlphaFunc);
        AlphaRef = (dwAlphaRef);
        ZEnable = (dwZEnable);
        ZFunc = (dwZFunc);
        ZWriteEnable = (bZWriteEnable);

        VertexShader = compile vs_2_a vsFFP();
        PixelShader = compile ps_2_a psQuadWTexNoTex();
    }

    pass tex
    {
        // App alpha/depth settings
        AlphaBlendEnable = (bAlphaBlend);
        SrcBlend = (dwSrcBlend);
        DestBlend = (dwDestBlend);
        AlphaTestEnable = (bAlphaTest);
        AlphaFunc = (dwAlphaFunc);
        AlphaRef = (dwAlphaRef);
        ZEnable = (dwZEnable);
        ZFunc = (dwZFunc);
        ZWriteEnable = (bZWriteEnable);

        VertexShader = compile vs_2_a vsFFP();
        PixelShader = compile ps_2_a psQuadWTexOneTex();
    }

    pass masked
    {
        // App alpha/depth settings
        AlphaBlendEnable = (bAlphaBlend);
        SrcBlend = (dwSrcBlend);
        DestBlend = (dwDestBlend);
        AlphaTestEnable = (bAlphaTest);
        AlphaFunc = (dwAlphaFunc);
        AlphaRef = (dwAlphaRef);
        ZEnable = (dwZEnable);
        ZFunc = (dwZFunc);
        ZWriteEnable = (bZWriteEnable);

        VertexShader = compile vs_2_a vsFFP();
        PixelShader = compile ps_2_a psQuadWTexOneTexMasked();
    }
}

technique QuadCache
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT4, D3DDECLUSAGE_POSITION, 0,
        0, D3DDECLTYPE_FLOAT4, D3DDECLUSAGE_COLOR, 0,
        0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0,
        0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 1,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = TRUE;
        AlphaFunc = GREATER;
        AlphaRef = 0;
        ZEnable = TRUE;
        ZFunc = LESS;
        ZWriteEnable = TRUE;

        VertexShader = compile vs_2_a vsFFP();
        PixelShader = compile ps_2_a psFFP();
    }
}
