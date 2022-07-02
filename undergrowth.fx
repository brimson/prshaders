
uniform float4x4 _WorldViewProj : WorldViewProjection;
uniform float4x4 _WorldView : WorldView;
uniform float4 _PosOffsetAndScale : PosOffsetAndScale;
uniform float2 _SinCos : SinCos;
uniform float4 _TerrainTexCoordScaleAndOffset : TerrainTexCoordScaleAndOffset;
uniform float3 _CameraPos : CameraPos;
uniform float4 _FadeAndHeightScaleOffset : FadeAndHeightScaleOffset;
uniform float4 _SwayOffsets[16] : SwayOffset;
uniform float4 _ShadowTexCoordScaleAndOffset : ShadowTexCoordScaleAndOffset;
uniform float4 _SunColor : SunColor;
uniform float4 _GIColor : GIColor;
uniform float4 _PointLightPosAtten[4] : PointLightPosAtten;
uniform float4 _PointLightColor[4] : PointLightColor;
uniform int _AlphaRefValue : AlphaRef;
uniform float _LightingScale : LightingScale;

uniform float4 _Transparency_x8 : TRANSPARENCY_X8;

#if NVIDIA
	#define _CUSTOMSHADOWSAMPLER_ s3
	#define _CUSTOMSHADOWSAMPLERINDEX_ 3
#endif

#define FH2_ALPHAREF 127

string Category = "Effects\\Lighting";
#include "shaders\racommon.fx"

uniform texture Texture_0 : TEXLAYER0;
uniform texture Texture_1 : TEXLAYER1;
uniform texture Texture_2 : TEXLAYER2;

sampler2D Sampler_0 = sampler_state
{
	Texture = <Texture_0>;
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU = CLAMP;
	AddressV = CLAMP;
};

sampler2D Sampler_1 = sampler_state
{
	Texture = <Texture_1>;
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU = CLAMP;
	AddressV = CLAMP;
};

sampler2D Sampler_2 = sampler_state
{
	Texture = <Texture_2>;
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU = CLAMP;
	AddressV = CLAMP;
};

struct APP2VS
{
	float4 Pos : POSITION;
	float2 TexCoord : TEXCOORD0;
	float4 Packed : COLOR;
};

struct APP2VS_Simple
{
	float4 Pos : POSITION;
	float2 TexCoord : TEXCOORD0;
	float4 Packed : COLOR;
	float4 TerrainColormap : COLOR1;
	float4 TerrainLightmap : COLOR2;
};

struct VS2PS
{
	float4 Pos : POSITION;
	float2 Tex0 : TEXCOORD0;
	float2 Tex1 : TEXCOORD1;
	float2 Tex2 : TEXCOORD2;
	float4 TexShadow : TEXCOORD3;
	float4 LightAndScale : COLOR0;
	float Fog : FOG;
};

float4 CalcPos(APP2VS Input)
{
	float4 Pos = float4((Input.Pos.xyz / 32767.0 * _PosOffsetAndScale.w), 1.0);
	Pos.xz += _SwayOffsets[Input.Packed.z * 255].xy * Input.Packed.y * 3.0f;
	Pos.xyz += _PosOffsetAndScale.xyz;

	float Dist = length(Pos.xyz - _CameraPos);
	float ViewDistance = _FadeAndHeightScaleOffset.x;
	float FadeFactor = _FadeAndHeightScaleOffset.y;
	float HeightScale = saturate((ViewDistance - Dist) * FadeFactor);
	Pos.y = (Input.Pos.y / 32767.0 * _PosOffsetAndScale.w) * HeightScale + _PosOffsetAndScale.y + (Input.Pos.w / 32767.0 * _PosOffsetAndScale.w);
	return Pos;
}

VS2PS Undergrowth_VS(APP2VS Input, uniform int LightCount, uniform bool ShadowMapEnable)
{
	VS2PS Output = (VS2PS)0;

	float4 Pos = CalcPos(Input);

	Output.LightAndScale.w = Input.Packed.w * 0.5;

	Output.Pos = mul(Pos, _WorldViewProj);
	Output.Tex0 = Input.TexCoord / 32767.0;
	Output.Tex1.xy = Pos.xz*_TerrainTexCoordScaleAndOffset.xy + _TerrainTexCoordScaleAndOffset.zw;
	Output.Tex2 = Output.Tex1;

	Output.TexShadow = (ShadowMapEnable) ? calcShadowProjection(Pos) : 0.0;

	Output.LightAndScale.rgb = 0.0;

	for (int i = 0; i < LightCount; i++)
	{
		float3 LightVec = Pos.xyz - _PointLightPosAtten[i].xyz;
		Output.LightAndScale.rgb += saturate(1.0 - pow(length(LightVec), 2.0) *_PointLightPosAtten[i].w) * _PointLightColor[i];
	}

	Output.LightAndScale = saturate(Output.LightAndScale);
	Output.Fog = saturate(calcFog(Output.Pos.w));

	return Output;
}

float4 Undergrowth_PS
(
	VS2PS Input,
	uniform bool PointLightEnable,
	uniform bool ShadowMapEnable,
	uniform sampler2D ColorMap,
	uniform sampler2D TerrainColormap,
	uniform sampler2D TerrainLightmap
) : COLOR
{
	float4 Base = tex2D(ColorMap, Input.Tex0);

	float4 TerrainColor = (FogColor.r < 0.01) ? 0.333 : tex2D(TerrainColormap, Input.Tex1);
	TerrainColor.rgb = lerp(TerrainColor.rgb, 1.0, Input.LightAndScale.w);

	float3 TerrainLightMap = tex2D(TerrainLightmap, Input.Tex2);
	float4 TerrainShadow = (ShadowMapEnable) ? getShadowFactor(ShadowMapSampler, Input.TexShadow, 1) : 1.0;

	float3 PointColor = (PointLightEnable) ? Input.LightAndScale.rgb * 0.125 : 0.0;
	float3 TerrainLight = (TerrainLightMap.y * _SunColor.rgb * TerrainShadow.rgb + PointColor) * 2.0 + (TerrainLightMap.z * _GIColor.rgb);

	TerrainColor.rgb = Base.rgb * TerrainColor.rgb * TerrainLight.rgb * 2.0;
	TerrainColor.a = Base.a * _Transparency_x8.a * 4.0;
	TerrainColor.a = TerrainColor.a + TerrainColor.a;

	// Fog
	TerrainColor.rgb = lerp(FogColor.rgb, TerrainColor.rgb, Input.Fog);

	return TerrainColor;
}

// { StreamNo, DataType, Usage, UsageIdx }
// DECLARATION_END => End macro
#define VERTEX_DECLARATION_UNDERGROWTH \
	int Declaration[] = \
	{ \
		{ 0, D3DDECLTYPE_SHORT4, D3DDECLUSAGE_POSITION, 0 }, \
		{ 0, D3DDECLTYPE_SHORT2, D3DDECLUSAGE_TEXCOORD, 0 }, \
		{ 0, D3DDECLTYPE_D3DCOLOR, D3DDECLUSAGE_COLOR, 0 }, \
		DECLARATION_END \
	}; \

#define RENDERSTATES_UNDERGROWTH \
	CullMode = CW; \
	AlphaTestEnable = TRUE; \
	AlphaRef = FH2_ALPHAREF; \
	AlphaFunc = GREATER; \
	ZFunc = LESS; \

technique t0_l0
<
	VERTEX_DECLARATION_UNDERGROWTH
>
{
	pass Normal
	{
		RENDERSTATES_UNDERGROWTH
		VertexShader = compile vs_3_0 Undergrowth_VS(0, false);
		PixelShader = compile ps_3_0 Undergrowth_PS(false, false, Sampler_0, Sampler_1, Sampler_2);
	}
}

technique t0_l1
<
	VERTEX_DECLARATION_UNDERGROWTH
>
{
	pass Normal
	{
		RENDERSTATES_UNDERGROWTH
		VertexShader = compile vs_3_0 Undergrowth_VS(1, false);
		PixelShader = compile ps_3_0 Undergrowth_PS(true, false, Sampler_0, Sampler_1, Sampler_2);
	}
}

technique t0_l2
<
	VERTEX_DECLARATION_UNDERGROWTH
>
{
	pass Normal
	{
		RENDERSTATES_UNDERGROWTH
		VertexShader = compile vs_3_0 Undergrowth_VS(2, false);
		PixelShader = compile ps_3_0 Undergrowth_PS(true, false, Sampler_0, Sampler_1, Sampler_2);
	}
}

technique t0_l3
<
	VERTEX_DECLARATION_UNDERGROWTH
>
{
	pass Normal
	{
		RENDERSTATES_UNDERGROWTH
		VertexShader = compile vs_3_0 Undergrowth_VS(3, false);
		PixelShader = compile ps_3_0 Undergrowth_PS(true, false, Sampler_0, Sampler_1, Sampler_2);
	}
}

technique t0_l4
<
	VERTEX_DECLARATION_UNDERGROWTH
>
{
	pass Normal
	{
		RENDERSTATES_UNDERGROWTH
		VertexShader = compile vs_3_0 Undergrowth_VS(4, false);
		PixelShader = compile ps_3_0 Undergrowth_PS(true, false, Sampler_0, Sampler_1, Sampler_2);
	}
}

technique t0_l0_ds
<
	VERTEX_DECLARATION_UNDERGROWTH
>
{
	pass Normal
	{
		RENDERSTATES_UNDERGROWTH
		VertexShader = compile vs_3_0 Undergrowth_VS(0, true);
		PixelShader = compile ps_3_0 Undergrowth_PS(false, true, Sampler_0, Sampler_1, Sampler_2);
	}
}

technique t0_l1_ds
<
	VERTEX_DECLARATION_UNDERGROWTH
>
{
	pass Normal
	{
		RENDERSTATES_UNDERGROWTH
		VertexShader = compile vs_3_0 Undergrowth_VS(1, true);
		PixelShader = compile ps_3_0 Undergrowth_PS(false, true, Sampler_0, Sampler_1, Sampler_2);
	}
}

technique t0_l2_ds
<
	VERTEX_DECLARATION_UNDERGROWTH
>
{
	pass Normal
	{
		RENDERSTATES_UNDERGROWTH
		VertexShader = compile vs_3_0 Undergrowth_VS(2, true);
		PixelShader = compile ps_3_0 Undergrowth_PS(false, true, Sampler_0, Sampler_1, Sampler_2);
	}
}

technique t0_l3_ds
<
	VERTEX_DECLARATION_UNDERGROWTH
>
{
	pass Normal
	{
		RENDERSTATES_UNDERGROWTH
		VertexShader = compile vs_3_0 Undergrowth_VS(3, true);
		PixelShader = compile ps_3_0 Undergrowth_PS(false, true, Sampler_0, Sampler_1, Sampler_2);
	}
}

technique t0_l4_ds
<
	VERTEX_DECLARATION_UNDERGROWTH
>
{
	pass Normal
	{
		RENDERSTATES_UNDERGROWTH
		VertexShader = compile vs_3_0 Undergrowth_VS(4, true);
		PixelShader = compile ps_3_0 Undergrowth_PS(false, true, Sampler_0, Sampler_1, Sampler_2);
	}
}




/*
	Undergrowth simple shaders
*/

struct VS2PS_Simple
{
	float4 Pos : POSITION;
	float2 Tex0 : TEXCOORD0;
	float4 TexShadow : TEXCOORD1;
	float3 SunLight : TEXCOORD2;
	float4 LightAndScale : COLOR0;
	float3 TerrainColor : COLOR1;
	float Fog : FOG;
};

float4 CalcPos_Simple(APP2VS_Simple Input)
{
	float4 Pos = float4((Input.Pos.xyz / 32767.0 * _PosOffsetAndScale.w) + _PosOffsetAndScale.xyz, 1.0);
	Pos.xz += _SwayOffsets[Input.Packed.z * 255].xy * Input.Packed.y * 3.0f;

	float Dist = length(Pos.xyz - _CameraPos);
	float ViewDistance = _FadeAndHeightScaleOffset.x;
	float FadeFactor = _FadeAndHeightScaleOffset.y;

	float HeightScale = saturate((ViewDistance - Dist) * FadeFactor);
	Pos.y = (Input.Pos.y / 32767.0 * _PosOffsetAndScale.w) * HeightScale + _PosOffsetAndScale.y + (Input.Pos.w / 32767.0 * _PosOffsetAndScale.w);
	return Pos;
}

VS2PS_Simple Undergrowth_Simple_VS(APP2VS_Simple Input, uniform int LightCount, uniform bool ShadowMapEnable)
{
	VS2PS_Simple Output = (VS2PS_Simple)0;

	float4 Pos = CalcPos_Simple(Input);

	Output.Pos = mul(Pos, _WorldViewProj);
	Output.Tex0 = Input.TexCoord / 32767.0;

	if (ShadowMapEnable)
	{
		Output.TexShadow = calcShadowProjection(Pos);
	}

	float3 Light = 0.0;
	Light += Input.TerrainLightmap.z * _GIColor;

	for (int i = 0; i<LightCount; i++)
	{
		float3 LightVec = Pos.xyz - _PointLightPosAtten[i].xyz;
		Light += saturate(1.0 - pow(length(LightVec), 2.0) * _PointLightPosAtten[i].w) * _PointLightColor[i];
	}

	if (ShadowMapEnable)
	{
		Output.LightAndScale.rgb = Light;
		Output.LightAndScale.w = Input.Packed.w;
		Output.SunLight = Input.TerrainLightmap.y * _SunColor * 2.0;
		Output.TerrainColor = lerp(Input.TerrainColormap, 1.0, Input.Packed.w);
	}
	else
	{
		Light += Input.TerrainLightmap.y * _SunColor * 2.0;
		Output.TerrainColor = lerp(Input.TerrainColormap, 1.0, Input.Packed.w);
		Output.TerrainColor *= Light;
	}

	Output.LightAndScale = saturate(Output.LightAndScale);
	Output.TerrainColor = saturate(Output.TerrainColor);
	Output.Fog = saturate(calcFog(Output.Pos.w));

	return Output;
}

float4 Undergrowth_Simple_PS
(
	VS2PS_Simple Input,
	uniform bool PointLightEnable,
	uniform bool ShadowMapEnable,
	uniform sampler2D ColorMap
) : COLOR
{
	float4 Base = tex2D(ColorMap, Input.Tex0);
	float3 LightColor;

	if (ShadowMapEnable)
	{
		float4 TerrainShadow = getShadowFactor(ShadowMapSampler, Input.TexShadow, 1);
		float3 Light = Input.SunLight * TerrainShadow.xyz;
		Light += Input.LightAndScale.rgb;
		LightColor = Base.rgb * Input.TerrainColor * Light * 2.0;
	}
	else
	{
		LightColor = Base.rgb * Input.TerrainColor * 2.0;
	}

	float4 OutColor = 0.0;
	OutColor.rgb = (FogColor.r < 0.01) ? float3(lerp(0.43, 0.17, LightColor.b), 1.0, 0.0) : LightColor;
	OutColor.a = Base.a * _Transparency_x8.a * 4.0;
	OutColor.a = OutColor.a + OutColor.a;

	// Fog
	OutColor.rgb = lerp(FogColor.rgb, OutColor.rgb, Input.Fog);

	return OutColor;
}

// { StreamNo, DataType, Usage, UsageIdx }
// DECLARATION_END => End macro
#define VERTEX_DECLARATION_UNDERGROWTH_SIMPLE \
	int Declaration[] = \
	{ \
		{ 0, D3DDECLTYPE_SHORT4, D3DDECLUSAGE_POSITION, 0 }, \
		{ 0, D3DDECLTYPE_SHORT2, D3DDECLUSAGE_TEXCOORD, 0 }, \
		{ 0, D3DDECLTYPE_D3DCOLOR, D3DDECLUSAGE_COLOR, 0 }, \
		{ 0, D3DDECLTYPE_D3DCOLOR, D3DDECLUSAGE_COLOR, 1 }, \
		{ 0, D3DDECLTYPE_D3DCOLOR, D3DDECLUSAGE_COLOR, 2 }, \
		DECLARATION_END \
	}; \

#define RENDERSTATES_UNDERGROWTH_SIMPLE \
	CullMode = CW; \
	AlphaTestEnable = TRUE; \
	AlphaRef = FH2_ALPHAREF; \
	AlphaFunc = GREATER; \
	ZFunc = LESS; \

technique t0_l0_simple
<
	VERTEX_DECLARATION_UNDERGROWTH_SIMPLE
>
{
	pass Normal
	{
		RENDERSTATES_UNDERGROWTH_SIMPLE
		VertexShader = compile vs_3_0 Undergrowth_Simple_VS(0, false);
		PixelShader = compile ps_3_0 Undergrowth_Simple_PS(false, false, Sampler_0);
	}
}

technique t0_l1_simple
<
	VERTEX_DECLARATION_UNDERGROWTH_SIMPLE
>
{
	pass Normal
	{
		RENDERSTATES_UNDERGROWTH_SIMPLE
		VertexShader = compile vs_3_0 Undergrowth_Simple_VS(1, false);
		PixelShader = compile ps_3_0 Undergrowth_Simple_PS(true, false, Sampler_0);
	}
}

technique t0_l2_simple
<
	VERTEX_DECLARATION_UNDERGROWTH_SIMPLE
>
{
	pass Normal
	{
		RENDERSTATES_UNDERGROWTH_SIMPLE
		VertexShader = compile vs_3_0 Undergrowth_Simple_VS(2, false);
		PixelShader = compile ps_3_0 Undergrowth_Simple_PS(true, false, Sampler_0);
	}
}

technique t0_l3_simple
<
	VERTEX_DECLARATION_UNDERGROWTH_SIMPLE
>
{
	pass Normal
	{
		RENDERSTATES_UNDERGROWTH_SIMPLE
		VertexShader = compile vs_3_0 Undergrowth_Simple_VS(3, false);
		PixelShader = compile ps_3_0 Undergrowth_Simple_PS(true, false, Sampler_0);
	}
}

technique t0_l4_simple
<
	VERTEX_DECLARATION_UNDERGROWTH_SIMPLE
>
{
	pass Normal
	{
		RENDERSTATES_UNDERGROWTH_SIMPLE
		VertexShader = compile vs_3_0 Undergrowth_Simple_VS(4, false);
		PixelShader = compile ps_3_0 Undergrowth_Simple_PS(true, false, Sampler_0);
	}
}

technique t0_l0_ds_simple
<
	VERTEX_DECLARATION_UNDERGROWTH_SIMPLE
>
{
	pass Normal
	{
		RENDERSTATES_UNDERGROWTH_SIMPLE
		VertexShader = compile vs_3_0 Undergrowth_Simple_VS(0, true);
		PixelShader = compile ps_3_0 Undergrowth_Simple_PS(false, true, Sampler_0);
	}
}

technique t0_l1_ds_simple
<
	VERTEX_DECLARATION_UNDERGROWTH_SIMPLE
>
{
	pass Normal
	{
		RENDERSTATES_UNDERGROWTH_SIMPLE
		VertexShader = compile vs_3_0 Undergrowth_Simple_VS(1, true);
		PixelShader = compile ps_3_0 Undergrowth_Simple_PS(true, true, Sampler_0);
	}
}

technique t0_l2_ds_simple
<
	VERTEX_DECLARATION_UNDERGROWTH_SIMPLE
>
{
	pass Normal
	{
		RENDERSTATES_UNDERGROWTH_SIMPLE
		VertexShader = compile vs_3_0 Undergrowth_Simple_VS(2, true);
		PixelShader = compile ps_3_0 Undergrowth_Simple_PS(true, true, Sampler_0);
	}
}

technique t0_l3_ds_simple
<
	VERTEX_DECLARATION_UNDERGROWTH_SIMPLE
>
{
	pass Normal
	{
		RENDERSTATES_UNDERGROWTH_SIMPLE
		VertexShader = compile vs_3_0 Undergrowth_Simple_VS(3, true);
		PixelShader = compile ps_3_0 Undergrowth_Simple_PS(true, true, Sampler_0);
	}
}

technique t0_l4_ds_simple
<
	VERTEX_DECLARATION_UNDERGROWTH_SIMPLE
>
{
	pass Normal
	{
		RENDERSTATES_UNDERGROWTH_SIMPLE
		VertexShader = compile vs_3_0 Undergrowth_Simple_VS(4, true);
		PixelShader = compile ps_3_0 Undergrowth_Simple_PS(true, true, Sampler_0);
	}
}




/*
	Undergrowth ZOnly shaders
*/

struct VS2PS_ZOnly
{
	float4 Pos : POSITION;
	float2 Tex0 : TEXCOORD0;
};

VS2PS_ZOnly Undergrowth_ZOnly_Simple_VS(APP2VS_Simple Input)
{
	VS2PS_ZOnly Output = (VS2PS_ZOnly)0;
	float4 Pos = CalcPos_Simple(Input);
	Output.Pos = mul(Pos, _WorldViewProj);
 	Output.Tex0 = Input.TexCoord / 32767.0;
	return Output;
}

VS2PS_ZOnly Undergrowth_ZOnly_VS(APP2VS Input)
{
	VS2PS_ZOnly Output = (VS2PS_ZOnly)0;
	float4 Pos = CalcPos(Input);
	Output.Pos = mul(Pos, _WorldViewProj);
	Output.Tex0 = Input.TexCoord / 32767.0;
	return Output;
}

float4 Undergrowth_ZOnly_PS(VS2PS Input, uniform sampler2D ColorMap) : COLOR
{
	float4 Base = tex2D(ColorMap, Input.Tex0);
	Base.a *= _Transparency_x8.a * 4.0;
	Base.a += Base.a;
	return Base;
}

// { StreamNo, DataType, Usage, UsageIdx }
// DECLARATION_END => End macro
#define VERTEX_DECLARATION_UNDERGROWTH_ZONLY \
	int Declaration[] = \
	{ \
		{ 0, D3DDECLTYPE_SHORT4, D3DDECLUSAGE_POSITION, 0 }, \
		{ 0, D3DDECLTYPE_SHORT2, D3DDECLUSAGE_TEXCOORD, 0 }, \
		{ 0, D3DDECLTYPE_D3DCOLOR, D3DDECLUSAGE_COLOR, 0 }, \
		DECLARATION_END \
	}; \

#define RENDERSTATES_UNDERGROWTH_ZONLY \
	CullMode = CW; \
	AlphaTestEnable = TRUE; \
	AlphaRef = FH2_ALPHAREF; \
	AlphaFunc = GREATER; \
	ColorWriteEnable = 0; \
	ZFunc = LESS; \

technique ZOnly
<
	VERTEX_DECLARATION_UNDERGROWTH_ZONLY
>
{
	pass Normal
	{
		RENDERSTATES_UNDERGROWTH_ZONLY
		VertexShader = compile vs_3_0 Undergrowth_ZOnly_VS();
		PixelShader = compile ps_3_0 Undergrowth_ZOnly_PS(Sampler_0);
	}
}

technique ZOnly_Simple
<
	VERTEX_DECLARATION_UNDERGROWTH_ZONLY
>
{
	pass Normal
	{
		RENDERSTATES_UNDERGROWTH_ZONLY
		VertexShader = compile vs_3_0 Undergrowth_ZOnly_Simple_VS();
		PixelShader = compile ps_3_0 Undergrowth_ZOnly_PS(Sampler_0);
	}
}
