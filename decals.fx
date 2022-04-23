#line 2 "Decals.fx"

#include "shaders/RaCommon.fx"

#define SAMPLER(NAME, TEXTURE, ADDRESS, FILTER) \
	sampler NAME = sampler_state \
	{ \
		Texture = TEXTURE; \
		AddressU = ADDRESS; \
		AddressV = ADDRESS; \
		MinFilter = FILTER; \
		MagFilter = FILTER; \
		MipFilter = FILTER; \
	};

// UNIFORM INPUTS
float4x4 _WorldViewProjection : WorldViewProjection;
float4x3 _InstanceTransformations[10]: InstanceTransformations;
float4x4 _ShadowTransformations[10] : ShadowTransformations;
float4 _ShadowViewPortMaps[10] : ShadowViewPortMaps;

// offset x/y heightmapsize z / hemilerpbias w
// float4 _HemiMapInfo : HemiMapInfo;
// float4 _SkyColor : SkyColor;

float4 _AmbientColor : AmbientColor;
float4 _SunColor : SunColor;
float4 _SunDirection : SunDirection;
float2 _DecalFadeDistanceAndInterval : DecalFadeDistanceAndInterval = float2(100.0f, 30.0f);

texture Texture_0: TEXLAYER0;
texture Texture_1: HemiMapTexture;
texture Shadow_Map_Tex: ShadowMapTex;
// texture Shadow_Map_Occluder_Tex: ShadowMapOccluderTex;

SAMPLER(Sampler_0, Texture_0, CLAMP, LINEAR)
// SAMPLER(Shadow_Map_Sampler, Shadow_Map_Tex, CLAMP, LINEAR)
// SAMPLER(Shadow_Map_Occluder_Sampler, Shadow_Map_Occluder_Tex, CLAMP, LINEAR)

struct APP2VS
{
   	float4 Pos : POSITION;
   	float4 Normal : NORMAL;
   	float4 Color : COLOR;
   	float4 TexCoordsInstanceIndexAndAlpha : TEXCOORD0;
};

struct VS2PS_Decal
{
	float4 HPos : POSITION;
	float2 Texture0 : TEXCOORD0;
	float3 Color : TEXCOORD1;
	float3 Diffuse : TEXCOORD2;
	float4 Alpha : COLOR0;
	float Fog : FOG;
};

void Output_Decal
(
	APP2VS Input,
	out int Index,
	out float3 Pos,
	out float4 HPos,
	out float3 Diffuse,
	out float4 Alpha,
	out float3 Color
)
{
	Index = Input.TexCoordsInstanceIndexAndAlpha.z;

	Pos = mul(Input.Pos, _InstanceTransformations[Index]);
	HPos = mul(float4(Pos.xyz, 1.0f), _WorldViewProjection);

	float3 WorldNormal = mul(Input.Normal.xyz, (float3x3)_InstanceTransformations[Index]);
	Diffuse = saturate(dot(WorldNormal, -_SunDirection.xyz)) * _SunColor;

	Alpha = 1.0f - saturate((HPos.z - _DecalFadeDistanceAndInterval.x) / _DecalFadeDistanceAndInterval.y);
	Alpha *= Input.TexCoordsInstanceIndexAndAlpha.w;
	Alpha = Alpha;
	Color = Input.Color;
}

VS2PS_Decal Decal_VS(APP2VS Input)
{
	VS2PS_Decal Output;

	int Index;
	float3 Pos;
	Output_Decal(Input, Index, Pos, Output.HPos, Output.Diffuse, Output.Alpha, Output.Color);

	Output.Texture0 = Input.TexCoordsInstanceIndexAndAlpha.xy;
	Output.Fog = Calc_Fog(Output.HPos.w);
	return Output;
}

float4 Decal_PS(VS2PS_Decal Input) : COLOR
{
	float3 Lighting = _AmbientColor.rgb + Input.Diffuse;
	float4 OutColor = tex2D(Sampler_0, Input.Texture0); // * Input.Color;

	OutColor.rgb *= Input.Color * Lighting;
	OutColor.a *= Input.Alpha;
	return OutColor;
}

struct VS2PS_Decal_Shadowed
{
	float4 HPos : POSITION;
	float2 Texture0 : TEXCOORD0;
	float4 TexShadow : TEXCOORD1;
	float4 ViewPortMap : TEXCOORD2;
	float3 Color : TEXCOORD3;
	float3 Diffuse : TEXCOORD4;
	float4 Alpha : COLOR0;
	float Fog : FOG;
};

VS2PS_Decal_Shadowed Decal_Shadowed_VS(APP2VS Input)
{
	VS2PS_Decal_Shadowed Output;

	int Index;
	float3 Pos;
	Output_Decal(Input, Index, Pos, Output.HPos, Output.Diffuse, Output.Alpha, Output.Color);

	Output.ViewPortMap = _ShadowViewPortMaps[Index];
	Output.TexShadow = mul(float4(Pos, 1.0), _ShadowTransformations[Index]);
	Output.TexShadow.z -= 0.007;

	Output.Texture0 = Input.TexCoordsInstanceIndexAndAlpha.xy;
	Output.Fog = Calc_Fog(Output.HPos.w);
	return Output;
}

float4 Decal_Shadowed_PS(VS2PS_Decal_Shadowed Input) : COLOR
{
	float2 Texel = float2(1.0 / 1024.0, 1.0 / 1024.0);
	float4 Samples;

	/*
		Input.TexShadow.xy = clamp(Input.TexShadow.xy,  Input.ViewPortMap.xy, Input.ViewPortMap.zw);
		Samples.x = tex2D(Shadow_Map_Sampler, Input.TexShadow);
		Samples.y = tex2D(Shadow_Map_Sampler, Input.TexShadow + float2(Texel.x, 0));
		Samples.z = tex2D(Shadow_Map_Sampler, Input.TexShadow + float2(0, Texel.y));
		Samples.w = tex2D(Shadow_Map_Sampler, Input.TexShadow + Texel);

		float4 Cmpbits = Samples >= saturate(Input.TexShadow.z);
		float DirShadow = dot(Cmpbits, float4(0.25, 0.25, 0.25, 0.25));
	*/

	float DirShadow = 1.0;

	float4 OutColor = tex2D(Sampler_0, Input.Texture0);
	OutColor.rgb *=  Input.Color;
	OutColor.a *= Input.Alpha;

	float3 Lighting = _AmbientColor.rgb + Input.Diffuse * DirShadow;
	OutColor.rgb *= Lighting;
	return OutColor;
}

technique Decal
<
	int Declaration[] =
	{
		// StreamNo, DataType, Usage, UsageIdx
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
		{ 0, D3DDECLTYPE_D3DCOLOR, D3DDECLUSAGE_COLOR, 0 },
		{ 0, D3DDECLTYPE_FLOAT4, D3DDECLUSAGE_TEXCOORD, 0 },
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		// FillMode = WireFrame;
		AlphaTestEnable = TRUE;
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		AlphaRef = 0;
		AlphaFunc = GREATER;
		CullMode = CW;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		FogEnable = TRUE;

 		VertexShader = compile vs_3_0 Decal_VS();
		PixelShader = compile ps_3_0 Decal_PS();
	}

	pass p1
	{
		// FillMode = WireFrame;
		AlphaTestEnable = TRUE;
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		AlphaRef = 0;
		AlphaFunc = GREATER;
		CullMode = CW;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		FogEnable = TRUE;

 		VertexShader = compile vs_3_0 Decal_VS();
		PixelShader = compile ps_3_0 Decal_PS();
	}
}
