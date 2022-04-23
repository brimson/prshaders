
/*
	Shader that handles BF2's UI elements
*/

#line 2 "PortedMenuShader.fx"

// Render-states from app settings
bool _AlphaBlend : ALPHABLEND = false;
dword _SrcBlend : SRCBLEND = D3DBLEND_INVSRCALPHA;
dword _DestBlend : DESTBLEND = D3DBLEND_SRCALPHA;
bool _AlphaTest : ALPHATEST = false;
dword _AlphaFunc : ALPHAFUNC = D3DCMP_GREATER;
dword _AlphaRef : ALPHAREF = 0;
dword _ZEnable : ZMODE = D3DZB_TRUE;
dword _ZFunc : ZFUNC = D3DCMP_LESSEQUAL;
bool _ZWriteEnable : ZWRITEENABLE = true;

#define APP_ALPHA_DEPTH_SETTINGS \
	AlphaBlendEnable = (_AlphaBlend); \
	SrcBlend = (_SrcBlend); \
	DestBlend = (_DestBlend); \
	AlphaTestEnable = (_AlphaTest); \
	AlphaFunc = (_AlphaFunc); \
	AlphaRef = (_AlphaRef); \
	ZEnable = (_ZEnable); \
	ZFunc = (_ZFunc); \
	ZWriteEnable = (_ZWriteEnable); \

float4x4 _WorldMatrix : matWORLD;
float4x4 _ViewMatrix : matVIEW;
float4x4 _ProjMatrix : matPROJ;

texture Texture_0: TEXLAYER0;
texture Texture_1: TEXLAYER1;

sampler Sampler_0_Clamp = sampler_state
{
	Texture = (Texture_0);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
};

sampler Sampler_1_Clamp = sampler_state
{
	Texture = (Texture_1);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
};

struct APP2VS
{
	float4 Pos : POSITION;
	float4 Col : COLOR;
	float2 Tex : TEXCOORD0;
	float2 Tex2 : TEXCOORD1;
};

struct VS2PS
{
	float4 Pos : POSITION;
	float4 Col : COLOR;
	float2 Tex : TEXCOORD0;
	float2 Tex2 : TEXCOORD1;
};

VS2PS Basic_VS(APP2VS Input)
{
	VS2PS Output;

	float4x4 WorldViewProj = _WorldMatrix * _ViewMatrix * _ProjMatrix;
	Output.Pos = mul(Input.Pos, WorldViewProj);
	Output.Col = Input.Col;
 	Output.Tex = Input.Tex;
 	Output.Tex2 = Input.Tex2;
	return Output;
}

technique Menu
{
	pass { }
}

technique Menu_States <bool Restore = true;>
{
	pass BeginStates { }
	pass EndStates { }
}

float4 Quad_WTex_NoTex_PS(VS2PS Input) : COLOR
{
	return Input.Col;
}

float4 Quad_WTex_Tex_PS(VS2PS Input) : COLOR
{
	return Input.Col * tex2D(Sampler_0_Clamp, Input.Tex);
}

float4 Quad_WTex_Tex_Masked_PS(VS2PS Input) : COLOR
{
	float4 Color = Input.Col * tex2D(Sampler_0_Clamp, Input.Tex);
	// Color *= tex2D(Sampler_1_Clamp, Input.Tex2);
	Color.a *= tex2D(Sampler_1_Clamp, Input.Tex2).a;
	return Color;
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
		APP_ALPHA_DEPTH_SETTINGS
		VertexShader = compile vs_3_0 Basic_VS();
		PixelShader = compile ps_3_0 Quad_WTex_NoTex_PS();
	}

	pass tex
	{
		// App alpha/depth settings
		APP_ALPHA_DEPTH_SETTINGS
		VertexShader = compile vs_3_0 Basic_VS();
		PixelShader = compile ps_3_0 Quad_WTex_Tex_PS();
	}

	pass masked
	{
		// App alpha/depth settings
		APP_ALPHA_DEPTH_SETTINGS
		VertexShader = compile vs_3_0 Basic_VS();
		PixelShader = compile ps_3_0 Quad_WTex_Tex_Masked_PS();
	}
}

float4 Quad_Cache_PS(VS2PS Input) : COLOR
{
	float4 InputTexture = tex2D(Sampler_0_Clamp, Input.Tex);
	return (InputTexture + 1.0) * Input.Col;
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

		VertexShader = compile vs_3_0 Basic_VS();
		PixelShader = compile ps_3_0 Quad_Cache_PS();
	}
}
