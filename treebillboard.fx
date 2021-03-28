#line 2 "TreeBillboard.fx"

float4x4 mViewProj : matVIEWPROJ;


bool bAlphaBlend : ALPHABLEND		= true;
dword dwSrcBlend : SRCBLEND		= D3DBLEND_SRCALPHA;
dword dwDestBlend : DESTBLEND		= D3DBLEND_INVSRCALPHA;

bool bAlphaTest : ALPHATEST		= true;
dword dwAlphaFunc : ALPHAFUNC		= D3DCMP_GREATER;
dword dwAlphaRef : ALPHAREF		= 0;

dword dwZEnable : ZMODE			= D3DZB_TRUE;
bool bZWriteEnable : ZWRITEENABLE	= false;

dword dwTexFactor : TEXFACTOR		= 0;

texture texture0: TEXLAYER0;
sampler sampler0 = sampler_state {
    Texture			= (texture0);
    AddressU		= WRAP;
    AddressV		= CLAMP;
    MipFilter		= LINEAR;
    MinFilter 		= LINEAR;
    MagFilter 		= LINEAR;
};

texture texture1: TEXLAYER1;
sampler sampler1 = sampler_state {
    Texture			= (texture0);
    AddressU		= WRAP;
    AddressV		= CLAMP;
    MipFilter		= LINEAR;
    MinFilter 		= LINEAR;
    MagFilter 		= LINEAR;
};


struct APP2VS
{
    float4	Pos : POSITION;
    float4	Col : COLOR;
    float4	Col2 : COLOR;
    float2	Tex : TEXCOORD0;
    float2	Tex2 : TEXCOORD1;
};

struct VS2PS
{
    float4	Pos : POSITION;
    float4	Col : COLOR0;
    float4	Col2 : COLOR1;
    float2	Tex : TEXCOORD0;
    float2	Tex2 : TEXCOORD1;
};


float4 psFFP(VS2PS indata) : COLOR
{
    float4 col0 = tex2D(sampler0, indata.Tex);
    float4 col1 = tex2D(sampler1, indata.Tex2);

    return lerp(col1, col0, indata.Col2.a);
}

VS2PS vsFFP(APP2VS indata)
{
    VS2PS outdata;

    outdata.Pos = mul(indata.Pos, mViewProj);
    outdata.Col = indata.Col;
    outdata.Col2 = indata.Col2;
     outdata.Tex = indata.Tex;
     outdata.Tex2 = indata.Tex2;

    return outdata;
}


technique QuadWithTexture
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        0, D3DDECLTYPE_D3DCOLOR, D3DDECLUSAGE_COLOR, 0,
        0, D3DDECLTYPE_D3DCOLOR, D3DDECLUSAGE_COLOR, 1,
        0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0,
        0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 1,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        // App alpha/depth settings
        AlphaBlendEnable = (bAlphaBlend);
        SrcBlend = (dwSrcBlend);
        DestBlend = (dwDestBlend);
        AlphaTestEnable = true;//(bAlphaTest);
        AlphaFunc = (dwAlphaFunc);
        AlphaRef = (dwAlphaRef);
        ZWriteEnable = (bZWriteEnable);
        //TextureFactor = (dwTexFactor);
        CullMode = NONE;

        VertexShader = compile vs_2_a vsFFP();
        PixelShader = compile ps_2_a psFFP();
    }
}

