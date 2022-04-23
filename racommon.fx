#include "shaders/RaDefines.fx"

#ifdef DISABLE_DIFFUSEMAP
	#ifdef DISABLE_BUMPMAP
		#ifndef DISABLE_SPECULAR
			#define DRAW_ONLY_SPEC
		#endif
	#endif
#endif

#ifdef DRAW_ONLY_SPEC
	#define DEFAULT_DIFFUSE_MAP_COLOR float4(0.0, 0.0, 0.0, 1.0)
#else
	#define DEFAULT_DIFFUSE_MAP_COLOR float4(1.0, 1.0, 1.0, 1.0)
#endif	

// VARIABLES
struct Light
{
	float3 Pos;
	float3 dir;
	float4 color;
	float4 specularColor;
	float attenuation;
};

int _SrcBlend = 5;
int _DestBlend = 6;
bool _AlphaBlendEnable = true;

int _AlphaRef = 20;
int CullMode = 3; // D3DCULL_CCW
#define FH2_HARDCODED_PARALLAX_BIAS 0.0025

// Global parameter string attributes
float GlobalTime;
float4 HemiMapConstants;

//tl: This is a float replicated to a float4 to make 1.3 shaders more efficient (they can't access .rg directly)
float4 Transparency = 1.0f;

// Instance/template parameter string attributes
float WindSpeed = 0;
float4x4 World;
float4x4 ViewProjection;
float4x4 WorldViewProjection; 
bool AlphaTest = false;

float4 FogRange : fogRange;
float4 FogColor : fogColor;

float Calc_Fog(float W)
{
	float2 FogValues = W * FogRange.xy + FogRange.zw;
	float Close = max(FogValues.y, FogColor.w);
	float Far = pow(FogValues.x, 3.0);
	return Close - Far;
}

// Might need this for radefines.fx

#define NO_VAL float3(1.0, 1.0, 0.0)

float4 Show_Channel(
	float3 Diffuse = NO_VAL, 
	float3 Normal = NO_VAL, 
	float Specular = 0, 
	float Alpha = 0,
	float3 Shadow = 0,
	float3 Environment = NO_VAL)
{
	float4 ReturnVal = float4(0.0, 1.0, 1.0, 0.0);

	#ifdef DIFFUSE_CHANNEL
		ReturnVal = float4(Diffuse, 1.0);
	#endif

	#ifdef NORMAL_CHANNEL
		ReturnVal = float4(Normal, 1.0);
	#endif
		
	#ifdef SPECULAR_CHANNEL
		ReturnVal = float4(Specular, Specular, Specular, 1.0);
	#endif
		
	#ifdef ALPHA_CHANNEL
		ReturnVal = float4(Alpha, Alpha, Alpha, 1.0);
	#endif
		
	#ifdef ENVIRONMENT_CHANNEL
		ReturnVal = float4(Environment, 1.0);
	#endif
		
	#ifdef SHADOW_CHANNEL
		ReturnVal = float4(Shadow, 1.0);
	#endif
	
	return ReturnVal;
}

// Common dynamic Shadow instance parameters
float4x4 ShadowProjMat : ShadowProjMatrix;
float4x4 ShadowOccProjMat : ShadowOccProjMatrix;
float4x4 ShadowTrapMat : ShadowTrapMatrix;

texture ShadowMap : SHADOWMAP;

sampler ShadowMapSampler 
#ifdef _CUSTOMSHADOWSAMPLER_
: register(_CUSTOMSHADOWSAMPLER_)
#endif
= sampler_state
{
	Texture = (ShadowMap);
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = CLAMP;
	AddressV = CLAMP;
	AddressW = CLAMP;
};

texture ShadowOccluderMap : SHADOWOCCLUDERMAP;

sampler ShadowOccluderMapSampler = sampler_state
{
	Texture = (ShadowOccluderMap);
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = CLAMP;
	AddressV = CLAMP;
	AddressW = CLAMP;
};

// tl: Make _sure_ Pos and matrices are in same space!
float4 Calc_Shadow_Projection(float4 Pos, uniform float BIAS = -0.001, uniform bool ISOCCLUDER = false)
{
	float4 TexShadow1 = mul(Pos, ShadowTrapMat);
	float2 TexShadow2 = (ISOCCLUDER) ? mul(Pos, ShadowOccProjMat).zw : mul(Pos, ShadowProjMat).zw;
    TexShadow1.z = (TexShadow2.x*TexShadow1.w) / TexShadow2.y + BIAS; // (zL*wT)/wL == zL/wL post homo
	return TexShadow1;
}

// tl: Make _sure_ Pos and matrices are in same space!
float4 Calc_Shadow_Projection_Exact(float4 Pos, uniform float BIAS = -0.001)
{
	float4 TexShadow1 = mul(Pos, ShadowTrapMat);
	float2 TexShadow2 = mul(Pos, ShadowProjMat).zw;
	TexShadow1.z = (TexShadow2.x*TexShadow1.w) / TexShadow2.y + BIAS; // (zL*wT)/wL == zL/wL post homo
	return TexShadow1;
}

// Currently fixed to 3 or 4.
float4 Get_Shadow_Factor(sampler ShadowSampler, float4 ShadowCoords, uniform int NSAMPLES = 4)
{
    if (NSAMPLES == 1)
    {
        float Samples = tex2Dproj(ShadowSampler, ShadowCoords);
        return Samples >= saturate(ShadowCoords.z);
    }
    else
    {
        float4 Texel = float4(0.5 / 1024.0, 0.5 / 1024.0, 0, 0);
        float4 Samples = 0;
        Samples.x = tex2Dproj(ShadowSampler, ShadowCoords);
        Samples.y = tex2Dproj(ShadowSampler, ShadowCoords + float4(Texel.x, 0.0, 0.0, 0.0));
        Samples.z = tex2Dproj(ShadowSampler, ShadowCoords + float4(0.0, Texel.y, 0.0, 0.0));
        Samples.w = tex2Dproj(ShadowSampler, ShadowCoords + Texel);
        float4 cmpbits = Samples >= saturate(ShadowCoords.z);
        return dot(cmpbits, 0.25);
    }
}

texture SpecLUT64SpecularColor;

sampler SpecLUT64Sampler = sampler_state
{
	Texture = (SpecLUT64SpecularColor);
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};

/*
	Normalize cubemap approximates normalize() because sqrt() was not a cheap instruction

	https://developer.download.nvidia.com/CgTutorial/cg_tutorial_chapter08.html

	Implementation requires putting "NormalizationCube" as global parameter.

	texture NormalizationCube;

	sampler NormalizationCubeSampler = sampler_state
	{
		Texture = (NormalizationCube);
		MipFilter = LINEAR;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		AddressU  = WRAP;
		AddressV  = WRAP;
		AddressW  = WRAP;
	};
*/
