#line 2 "SwiffMenu.fx"

/*
	Shaders for main menu
*/

#include "shaders/RaCommon.fx"

uniform float4x4 WorldView : TRANSFORM;
uniform float4 DiffuseColor : DIFFUSE;
uniform float4 TexGenS : TEXGENS;
uniform float4 TexGenT : TEXGENT;
uniform texture TexMap : TEXTURE;
uniform float Time : TIME;

sampler SwiffMenu_TexMap_Sampler_Clamp = sampler_state
{
	Texture = <TexMap>;
	AddressU = CLAMP;
	AddressV = CLAMP;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
};

sampler SwiffMenu_TexMap_Sampler_Wrap = sampler_state
{
	Texture = <TexMap>;
	AddressU = WRAP;
	AddressV = WRAP;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
};

struct VS2PS_Shape
{
	float4 Position : POSITION;
	float4 Diffuse : COLOR0;
};

struct VS2PS_TS0
{
	float4 Position : POSITION;
	float2 TexCoord : TEXCOORD0;
};

struct VS2PS_TS3
{
	float4 Position : POSITION;
	float2 TexCoord : TEXCOORD0;
	float4 Diffuse : COLOR0;
};

struct VS2PS_Shape_Texture
{
	float4 Position : POSITION;
	float4 Diffuse : COLOR0;
	float4 Selector : COLOR1;
	float2 TexCoord : TEXCOORD0;
};

VS2PS_Shape Shape_VS(float3 Position : POSITION, float4 VertexColor : COLOR0)
{
	VS2PS_Shape Output = (VS2PS_Shape)0;
	// Output.Position = mul(float4(Position.xy, 0.0f, 1.0), WorldView);
	Output.Position = float4(Position.xy, 0.0f, 1.0);
	// Output.Diffuse = saturate(DiffuseColor);
	Output.Diffuse = saturate(VertexColor);
	return Output;
}

VS2PS_Shape Line_VS(float3 Position : POSITION)
{
	VS2PS_Shape Output = (VS2PS_Shape)0;
	// Output.Position = mul(float4(Position.xy, 0.0f, 1.0), WorldView);
	// Output.Position = float4(Position.xy, 0.0f, 1.0);
	Output.Position = float4(Position.xy, 0.0f, 1.0);
	Output.Diffuse = saturate(DiffuseColor);
	return Output;
}

VS2PS_Shape_Texture Shape_Texture_VS(float3 Position : POSITION)
{
	VS2PS_Shape_Texture Output = (VS2PS_Shape_Texture)0;

	Output.Position = mul( float4(Position.xy, 0.0f, 1.0), WorldView);
	Output.Diffuse = saturate(DiffuseColor);
	Output.Selector = saturate(Position.zzzz);

	float4 TexPos = float4(Position.xy, 0.0, 1.0);
	Output.TexCoord.x = mul(TexPos, TexGenS);
	Output.TexCoord.y = mul(TexPos, TexGenT);

	return Output;
}

float4 Regular_Wrap_PS(VS2PS_Shape_Texture Input) : COLOR
{
	float4 Color = 0.0;
	float4 Tex = tex2D(SwiffMenu_TexMap_Sampler_Wrap, Input.TexCoord);
	// return Tex.aaaa;
	Color.rgb = Tex * Input.Diffuse * Input.Selector + Input.Diffuse * (1.0 - Input.Selector);
	Color.a = Tex.a * Input.Diffuse.a;
	return Color;
}

float4 PSRegularClamp(VS2PS_Shape_Texture Input) : COLOR
{
	float4 Color = 0.0;
	float4 Tex = tex2D(SwiffMenu_TexMap_Sampler_Clamp, Input.TexCoord);
	// return Tex.aaaa + 1.0;
	Color.rgb = Tex * Input.Diffuse * Input.Selector + Input.Diffuse * (1.0 - Input.Selector);
	Color.a = Tex.a * Input.Diffuse.a;
	return Color;
}

float4 Diffuse_PS(VS2PS_Shape Input) : COLOR
{
	return Input.Diffuse;
}

VS2PS_TS0 TS0_0_VS(float3 Position : POSITION)
{
	VS2PS_TS0 Output = (VS2PS_TS0)0;

	Output.Position = mul( float4(Position.xy, 0.0f, 1.0), WorldView);

	float4 TexPos = float4(Position.xy + sin(Time) * 240.5, 0.0, 1.0);
	float2 SinCosTime = Time * float2(0.10, 0.12) + float2(0.0, 0.2);
	SinCosTime = float2(sin(SinCosTime.x), cos(SinCosTime.y));
	Output.TexCoord.x = mul(TexPos, TexGenS);
	Output.TexCoord.y = mul(TexPos, TexGenT);
	Output.TexCoord.xy = Output.TexCoord.xy + (SinCosTime.xy * 0.1);
	Output.TexCoord.xy = Output.TexCoord.xy * 0.8 + 0.1;

	return Output;
}

VS2PS_Shape TS0_1_VS(float3 Position : POSITION)
{
	VS2PS_Shape Output = (VS2PS_Shape)0;

	Output.Position = mul(float4(Position.xy, 0.0f, 1.0), WorldView);

	float2 SinCosTime = Time * float2(1.0, 0.31);
	SinCosTime = float2(sin(SinCosTime.x), cos(SinCosTime.y));
	Output.Diffuse = saturate(dot(SinCosTime * float2(0.2, 0.1) + (0.2, 0.1), 1.0));
	// Output.Diffuse = saturate(float4(0.0, 0.6, 1.0, 0.7));

	return Output;
}

VS2PS_TS3 TS1_0_VS(float3 Position : POSITION)
{
	VS2PS_TS3 Output = (VS2PS_TS3)0;

	Output.Position = mul(float4(Position.xy, 0.0f, 1.0), WorldView);

	float4 TexPos = float4(Position.xy, 0.0, 1.0);
	Output.TexCoord.x = mul(TexPos, TexGenS);
	Output.TexCoord.y = mul(TexPos, TexGenT) + Time * 0.005;

	Output.Diffuse = saturate(1.0);

	return Output;
}


VS2PS_TS3 TS2_0_VS(float3 Position : POSITION)
{
	VS2PS_TS3 Output = (VS2PS_TS3)0;

	Output.Position = mul(float4(Position.xy, 0.0f, 1.0), WorldView);

	float4 TexPos = float4(Position.xy, 0.0, 1.0);
	Output.TexCoord.x = mul(TexPos, TexGenS);
	Output.TexCoord.y = mul(TexPos, TexGenT);

	float2 SinCosA = Time * float2(1.0, 0.31);
	SinCosA = SinCosA * float2(1.0, 33.0) + float2(1.0, 0.0);
	SinCosA = float2(sin(SinCosA.x), cos(SinCosA.y));
	float Alpha = dot(SinCosA * float2(0.15, 0.03) + float2(0.4, 0.03), 1.0);
	Output.Diffuse = saturate(float4(1.0, 1.0, 1.0, Alpha));

	return Output;
}

VS2PS_TS3 TS3_0_VS(float3 Position : POSITION)
{
	VS2PS_TS3 Output = (VS2PS_TS3)0;

	Output.Position = mul(float4(Position.xy, 0.0f, 1.0), WorldView);

	float4 TexPos = float4(Position.xy + sin(Time + 0.2) * 240.5, 0.0, 1.0);
	float2 SinCosTime = Time * float2(0.10, 0.12) + float2(0.0, 0.2);
	SinCosTime = float2(sin(SinCosTime.x), cos(SinCosTime.y));
	Output.TexCoord.x = mul(TexPos, TexGenS);
	Output.TexCoord.y = mul(TexPos, TexGenT);
	Output.TexCoord.xy = Output.TexCoord.xy + (SinCosTime.xy * 0.1);
	Output.TexCoord.xy = Output.TexCoord.xy * 0.8 + 0.1;

	float2 SinCosA = Time * float2(1.0, 33.0);
	SinCosA = float2(sin(SinCosA.x), cos(SinCosA.y));
	float Alpha = dot(SinCosA * float2(0.15, 0.03) + float2(0.4, 0.03), 1.0);
	Output.Diffuse = saturate(float4(1.0, 1.0, 1.0, Alpha));

	return Output;
}

float4 TS0_0_PS(VS2PS_TS0 Input) : COLOR
{
	return tex2D(SwiffMenu_TexMap_Sampler_Wrap, Input.TexCoord);
	/*
		float4 Color = tex2D(SwiffMenu_TexMap_Sampler_Wrap, Input.TexCoord);
		Color.a *= Input.Diffuse.a;
		return Color;
	*/
}

float4 Regular_TSX_PS(VS2PS_TS3 Input) : COLOR
{
	return tex2D(SwiffMenu_TexMap_Sampler_Wrap, Input.TexCoord) * Input.Diffuse;
}

float4 Line_PS(VS2PS_Shape Input) : COLOR
{
	return Input.Diffuse;
}

technique Shape
{
	pass P0
	{
		VertexShader = compile vs_3_0 Shape_VS();
		PixelShader = compile ps_3_0 Diffuse_PS();
	}
}

technique ShapeTextureWrap
{
	pass P0
	{
		VertexShader = compile vs_3_0 Shape_Texture_VS();
		PixelShader = compile ps_3_0 Regular_Wrap_PS();
		AlphaTestEnable = FALSE;
		// AlphaRef = 128;
		// AlphaFunc = GREATER;
	}
}

technique ShapeTextureClamp
{
	pass P0
	{
		VertexShader = compile vs_3_0 Shape_Texture_VS();
		PixelShader  = compile ps_3_0 PSRegularClamp();
		// AlphaTestEnable = TRUE;
		// AlphaRef = 77;
		// AlphaFunc = GREATER;
	}
}

technique Line
{
	pass P0
	{
		VertexShader = compile vs_3_0 Line_VS();
		PixelShader = compile ps_3_0 Line_PS();
		AlphaTestEnable = FALSE;
	}
}

technique TS0
{
	pass P0
	{
		VertexShader = compile vs_3_0 TS0_0_VS();
		PixelShader = compile ps_3_0 TS0_0_PS();
		AlphaTestEnable = FALSE;
	}

	pass P1
	{
		VertexShader = compile vs_3_0 TS0_1_VS();
		PixelShader = compile ps_3_0 Diffuse_PS();
		AlphaTestEnable = FALSE;
	}
}

technique TS1
{
	pass P0
	{
		VertexShader = compile vs_3_0 TS1_0_VS();
		PixelShader = compile ps_3_0 Regular_TSX_PS();
		AlphaTestEnable = FALSE;
	}
}

technique TS2
{
	pass P0
	{
		VertexShader = compile vs_3_0 TS2_0_VS();
		PixelShader = compile ps_3_0 Regular_TSX_PS();
		AlphaTestEnable = FALSE;
	}
}

technique TS3
{
	pass P0
	{
		VertexShader = compile vs_3_0 TS3_0_VS();
		PixelShader = compile ps_3_0 Regular_TSX_PS();
		AlphaTestEnable = FALSE;
	}
}
