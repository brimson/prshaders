#line 2 "Decals.fx"

#include "shaders/RaCommon.fx"

/*
	[Attributes from app]
*/

uniform float4x4 _WorldViewProjection : WorldViewProjection;
uniform float4x3 _InstanceTransformations[10]: InstanceTransformations;
uniform float4x4 _ShadowTransformations[10] : ShadowTransformations;
uniform float4 _ShadowViewPortMaps[10] : ShadowViewPortMaps;

// offset x/y heightmapsize z / hemilerpbias w
// uniform float4 _HemiMapInfo : HemiMapInfo;
// uniform float4 _SkyColor : SkyColor;
uniform float4 _AmbientColor : AmbientColor;
uniform float4 _SunColor : SunColor;
uniform float4 _SunDirection : SunDirection;
uniform float2 _DecalFadeDistanceAndInterval : DecalFadeDistanceAndInterval = float2(100.0f, 30.0f);

/*
	[Textures and samplers]
*/

#define CREATE_SAMPLER(NAME, TEXTURE, ADDRESS, FILTER) \
	sampler NAME = sampler_state \
	{ \
		Texture = (TEXTURE); \
		AddressU = ADDRESS; \
		AddressV = ADDRESS; \
		MinFilter = FILTER; \
		MagFilter = FILTER; \
		MipFilter = FILTER; \
	};

uniform texture Texture_0: TEXLAYER0;
uniform texture Texture_1: HemiMapTexture;
uniform texture Shadow_Map_Tex: ShadowMapTex;
// uniform texture Shadow_Map_Occluder_Tex: ShadowMapOccluderTex;

CREATE_SAMPLER(Decals_Sampler_0, Texture_0, CLAMP, LINEAR)
// CREATE_SAMPLER(Decals_Shadow_Map_Sampler, Shadow_Map_Tex, CLAMP, LINEAR)
// CREATE_SAMPLER(Decals_Shadow_Map_Occluder_Sampler, Shadow_Map_Occluder_Tex, CLAMP, LINEAR)

struct APP2VS
{
   	float4 Pos : POSITION;
   	float4 Normal : NORMAL;
   	float4 Color : COLOR;
   	float4 TexCoordsInstanceIndexAndAlpha : TEXCOORD0;
};

struct VS2PS
{
	float4 HPos : POSITION;
	float2 Texture0 : TEXCOORD0;
	float3 Color : TEXCOORD1;
	float3 Diffuse : TEXCOORD2;
	float4 Alpha : COLOR0;
	float Fog : FOG;
};

struct Decals_Common_Data
{
	int Index;
	float3 Pos;
	float4 HPos;
	float3 Diffuse;
	float4 Alpha;
	float3 Color;
	float2 Texture0;
	float Fog;
};

Decals_Common_Data Decals_Common(APP2VS Input)
{
	Decals_Common_Data Output;
	Output.Index = Input.TexCoordsInstanceIndexAndAlpha.z;

	Output.Pos = mul(Input.Pos, _InstanceTransformations[Output.Index]);
	Output.HPos = mul(float4(Output.Pos.xyz, 1.0f), _WorldViewProjection);

	float3 WorldNormal = mul(Input.Normal.xyz, (float3x3)_InstanceTransformations[Output.Index]);
	Output.Diffuse = saturate(dot(WorldNormal, -_SunDirection.xyz)) * _SunColor;

	Output.Alpha = 1.0f - saturate((Output.HPos.z - _DecalFadeDistanceAndInterval.x) / _DecalFadeDistanceAndInterval.y);
	Output.Alpha *= Input.TexCoordsInstanceIndexAndAlpha.w;
	Output.Alpha = saturate(Output.Alpha);
	Output.Color = Input.Color;

	Output.Texture0 = Input.TexCoordsInstanceIndexAndAlpha.xy;
	Output.Fog = saturate(calcFog(Output.HPos.w));
	return Output;
}

VS2PS Decals_VS(APP2VS Input)
{
	VS2PS Output;
	Decals_Common_Data Data = Decals_Common(Input);
	Output.HPos = Data.HPos;
	Output.Texture0 = Data.Texture0;
	Output.Color = Data.Color;
	Output.Diffuse = Data.Diffuse;
	Output.Alpha = Data.Alpha;
	Output.Fog = Data.Fog;
	return Output;
}

float4 Decals_PS(VS2PS Input) : COLOR
{
	float3 Lighting = _AmbientColor.rgb + Input.Diffuse;
	float4 OutColor = tex2D(Decals_Sampler_0, Input.Texture0); // * Input.Color;

	OutColor.rgb *= Input.Color * Lighting;
	OutColor.a *= Input.Alpha;

	// Fog
	OutColor.rgb = lerp(FogColor.rgb, OutColor.rgb, Input.Fog);
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

VS2PS_Decal_Shadowed Decals_Shadowed_VS(APP2VS Input)
{
	VS2PS_Decal_Shadowed Output;
	Decals_Common_Data Data = Decals_Common(Input);

	Output.ViewPortMap = _ShadowViewPortMaps[Data.Index];
	Output.TexShadow = mul(float4(Data.Pos, 1.0), _ShadowTransformations[Data.Index]);
	Output.TexShadow.z -= 0.007;
	return Output;
}

float4 Decals_Shadowed_PS(VS2PS_Decal_Shadowed Input) : COLOR
{
	float2 Texel = float2(1.0 / 1024.0, 1.0 / 1024.0);
	float4 Samples;

	/*
		Input.TexShadow.xy = clamp(Input.TexShadow.xy,  Input.ViewPortMap.xy, Input.ViewPortMap.zw);
		Samples.x = tex2D(Decals_Shadow_Map_Sampler, Input.TexShadow);
		Samples.y = tex2D(Decals_Shadow_Map_Sampler, Input.TexShadow + float2(Texel.x, 0));
		Samples.z = tex2D(Decals_Shadow_Map_Sampler, Input.TexShadow + float2(0, Texel.y));
		Samples.w = tex2D(Decals_Shadow_Map_Sampler, Input.TexShadow + Texel);

		float4 Cmpbits = Samples >= saturate(Input.TexShadow.z);
		float DirShadow = dot(Cmpbits, float4(0.25, 0.25, 0.25, 0.25));
	*/

	float DirShadow = 1.0;

	float4 OutColor = tex2D(Decals_Sampler_0, Input.Texture0);
	OutColor.rgb *=  Input.Color;
	OutColor.a *= Input.Alpha;

	float3 Lighting = _AmbientColor.rgb + Input.Diffuse * DirShadow;
	OutColor.rgb *= Lighting;

	// Fog
	OutColor.rgb = lerp(FogColor.rgb, OutColor.rgb, Input.Fog);
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

 		VertexShader = compile vs_3_0 Decals_VS();
		PixelShader = compile ps_3_0 Decals_PS();
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

 		VertexShader = compile vs_3_0 Decals_VS();
		PixelShader = compile ps_3_0 Decals_PS();
	}
}
