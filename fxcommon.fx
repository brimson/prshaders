#line 2 "FXCommon.fx"
#include "shaders/RaCommon.fx"

// Particle Texture
uniform texture Texture_0: Texture0;

// Groundhemi Texture
uniform texture Texture_1: Texture1;

// commonparams
uniform float4x4 _ViewMat : ViewMat;
uniform float4x4 _ProjMat : ProjMat;

uniform float _UVScale = rsqrt(2.0f);
uniform float4 _HemiMapInfo : HemiMapInfo;
uniform float _HemiShadowAltitude : HemiShadowAltitude;
uniform float _AlphaPixelTestRef : AlphaPixelTestRef = 0;

const float _OneOverShort = 1.0 / 32767.0;

sampler Diffuse_Sampler = sampler_state
{
	Texture = <Texture_0>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = FILTER_PARTICLE_MIP;
	AddressU = Clamp;
	AddressV = Clamp;
};

sampler Diffuse_Sampler_2 = sampler_state 
{
	Texture = <Texture_0>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = FILTER_PARTICLE_MIP;
	AddressU = Clamp;
	AddressV = Clamp;
};

sampler LUT_Sampler = sampler_state 
{ 
	Texture = <Texture_1>; 
	AddressU = CLAMP; 
	AddressV = CLAMP; 
	MinFilter = LINEAR; 
	MagFilter = LINEAR; 
	MipFilter = FILTER_PARTICLE_MIP; 
};

uniform float3 _EffectSunColor : EffectSunColor;
uniform float3 _EffectShadowColor : EffectShadowColor;

float3 Calc_Particle_Lighting(float LM, float LMOffset, float LightFactor)
{
	float LUT = saturate(LM + LMOffset);
	float3 Diffuse = lerp(_EffectShadowColor, _EffectSunColor, LUT);
	return lerp(1.0, Diffuse, LightFactor);
}
