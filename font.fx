#line 2 "Font.fx"

#include "shaders/RaCommon.fx"

float4x4 _WorldView : TRANSFORM;
float4 _DiffuseColor : DIFFUSE;

texture Tex_Map : TEXTURE;

sampler Tex_Map_Sampler_Clamp = sampler_state
{
	Texture   = <Tex_Map>;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
};

sampler Tex_Map_Sampler_Clamp_Bilinear = sampler_state
{
	Texture   = <Tex_Map>;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
};

struct APP2VS
{
	float4 Position : POSITION;
	float4 Color : COLOR;
	float2 TexCoord : TEXCOORD0;
};

struct VS2PS_REGULAR
{
	float4 Position : POSITION;
	float4 Diffuse : COLOR0;
	float2 TexCoord : TEXCOORD0;
};

VS2PS_REGULAR Regular_VS(APP2VS Input)
{
	VS2PS_REGULAR Out = (VS2PS_REGULAR)0;
	// Out.Position = mul( float4(Position.xy, 0.5f, 1.0f), _WorldView);
	Out.Position = float4(Input.Position.xy, 0.5f, 1.0f);
	Out.Diffuse = Input.Color;
	Out.TexCoord = Input.TexCoord;
	return Out;
}

float4 Regular_PS(VS2PS_REGULAR Input) : COLOR
{
	return tex2D(Tex_Map_Sampler_Clamp, Input.TexCoord) * Input.Diffuse;
}

float4 Regular_Scaled_PS(VS2PS_REGULAR Input) : COLOR
{
	return tex2D(Tex_Map_Sampler_Clamp_Bilinear, Input.TexCoord) * Input.Diffuse;
}

struct VS_SELECTIONQUAD
{
	float4 Position : POSITION;
	float4 Diffuse : COLOR0;
};

VS_SELECTIONQUAD Quad_Selection_VS(float3 Position : POSITION)
{
	VS_SELECTIONQUAD Out = (VS_SELECTIONQUAD)0;
	Out.Position = mul(float4(Position.xy, 0.0f, 1.0), _WorldView);
	Out.Diffuse = _DiffuseColor;
	return Out;
}

float4 Quad_Selection_PS(VS_SELECTIONQUAD Input) : COLOR
{
	return Input.Diffuse;
}

technique Regular
{
	pass P0
	{
		VertexShader = compile vs_3_0 Regular_VS();
		PixelShader = compile ps_3_0 Regular_PS();
		AlphaTestEnable = FALSE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
	}
}

technique RegularScaled
{
	pass P0
	{
		VertexShader = compile vs_3_0 Regular_VS();
		PixelShader = compile ps_3_0 Regular_Scaled_PS();
		AlphaTestEnable = FALSE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
	}
}

technique SelectionQuad
{
	pass P0
	{
		VertexShader = compile vs_3_0 Quad_Selection_VS();
		PixelShader = compile ps_3_0 Quad_Selection_PS();
		AlphaTestEnable = FALSE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
	}
}
