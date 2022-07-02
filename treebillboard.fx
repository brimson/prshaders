#line 2 "TreeBillboard.fx"

uniform float4x4 _ViewProj : matVIEWPROJ;

// Uniform render state settings from app
uniform bool _AlphaBlend : ALPHABLEND = true;
uniform dword _SrcBlend : SRCBLEND = D3DBLEND_SRCALPHA;
uniform dword _DestBlend : DESTBLEND = D3DBLEND_INVSRCALPHA;
uniform bool _AlphaTest : ALPHATEST = true;
uniform dword _AlphaFunc : ALPHAFUNC = D3DCMP_GREATER;
uniform dword _AlphaRef : ALPHAREF = 0;
uniform dword _ZEnable : ZMODE = D3DZB_TRUE;
uniform bool _ZWriteEnable : ZWRITEENABLE = false;
uniform dword _TexFactor : TEXFACTOR = 0;

uniform texture Texture_0: TEXLAYER0;
sampler Sampler_0 = sampler_state
{
	Texture = (Texture_0);
	AddressU = WRAP;
	AddressV = CLAMP;
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
};

texture Texture_1: TEXLAYER1;
sampler Sampler_1 = sampler_state
{
	Texture = (Texture_1);
	AddressU = WRAP;
	AddressV = CLAMP;
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
};

struct APP2VS
{
	float4 Pos : POSITION;
	float4 Color1 : COLOR;
	float4 Color2 : COLOR;
	float2 TexCoord1 : TEXCOORD0;
	float2 TexCoord2 : TEXCOORD1;
};

struct VS2PS
{
	float4 Pos : POSITION;
	float4 Color1 : COLOR0;
	float4 Color2 : COLOR1;
	float2 TexCoord1 : TEXCOORD0;
	float2 TexCoord2 : TEXCOORD1;
};

float4 TreeBillboard_PS(VS2PS Input) : COLOR
{
	float4 col0 = tex2D(Sampler_0, Input.TexCoord1);
	float4 col1 = tex2D(Sampler_1, Input.TexCoord2);
	return lerp(col1, col0, Input.Color2.a);
}

VS2PS TreeBillboard_VS(APP2VS Input)
{
	VS2PS Output;
	Output.Pos = mul(Input.Pos, _ViewProj);
	Output.Color1 = saturate(Input.Color1);
	Output.Color2 = saturate(Input.Color2);
	Output.TexCoord1 = Input.TexCoord1;
	Output.TexCoord2 = Input.TexCoord2;
	return Output;
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
		AlphaBlendEnable = (_AlphaBlend);
		SrcBlend = (_SrcBlend);
		DestBlend = (_DestBlend);
		AlphaTestEnable = TRUE; // (_AlphaTest);
		AlphaFunc = (_AlphaFunc);
		AlphaRef = (_AlphaRef);
		ZWriteEnable = (_ZWriteEnable);
		// TextureFactor = (_TexFactor);
		CullMode = NONE;

		VertexShader = compile vs_3_0 TreeBillboard_VS();
		PixelShader = compile ps_3_0 TreeBillboard_PS();
	}
}
