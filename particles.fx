#line 2 "Particles.fx"
#include "shaders/FXCommon.fx"

/*
	[Textures and samplers]
*/

sampler Particles_Diffuse_Sampler = sampler_state
{
	Texture = <Texture_0>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = FILTER_PARTICLE_MIP;
	AddressU = CLAMP;
	AddressV = CLAMP;
};

sampler Particles_Diffuse_Sampler_2 = sampler_state 
{
	Texture = <Texture_0>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = FILTER_PARTICLE_MIP;
	AddressU = CLAMP;
	AddressV = CLAMP;
};

sampler Particles_LUT_Sampler = sampler_state 
{ 
	Texture = <Texture_1>; 
	AddressU = CLAMP; 
	AddressV = CLAMP; 
	MinFilter = LINEAR; 
	MagFilter = LINEAR; 
	MipFilter = FILTER_PARTICLE_MIP; 
};

// UNIFORM INPUTS
// Constant array

struct TemplateParameters
{
	float4 m_uvRangeLMapIntensiyAndParticleMaxSize;
	float4 m_lightColorAndRandomIntensity;
	float4 m_color1AndLightFactor;
	float4 m_color2;
	float4 m_colorBlendGraph;
	float4 m_transparencyGraph;
	float4 m_sizeGraph;
};

// TODO: change the value 10 to the approprite max value for the current hardware, need to make this a variable
TemplateParameters _Temps[10] : TemplateParameters;

struct APP2VS
{
	float3 Pos : POSITION;
	float2 AgeFactorAndGraphIndex : TEXCOORD0;
	float3 RandomSizeAlphaAndIntensityBlendFactor : TEXCOORD1;
	float2 DisplaceCoords : TEXCOORD2;
	float2 IntensityAndRandomIntensity : TEXCOORD3;
	float2 Rotation : TEXCOORD4;
	float4 UVOffsets : TEXCOORD5;
	float2 TexCoords : TEXCOORD6;
};

struct VS2PS_Particle
{
	float4 HPos : POSITION;
	float4 Color : TEXCOORD0;
	float4 DiffuseCoords : TEXCOORD1; // .xy = Diffuse1; .zw = Diffuse2
	float2 HemiLUTCoord : TEXCOORD2;
	float4 LightFactorAndAlphaBlend	: COLOR0;
	float4 AnimBFactorAndLMapIntOffset : COLOR1;
	float Fog : FOG;
};

VS2PS_Particle Particle_VS(APP2VS Input)
{
	float4 Pos = mul(float4(Input.Pos.xyz, 1.0), _ViewMat);
	VS2PS_Particle Output = (VS2PS_Particle)0;

	// Compute Cubic polynomial factors.
	float4 PC = float4(pow(Input.AgeFactorAndGraphIndex[0], float3(3.0, 2.0, 1.0)), 1.0);

	float ColorBlendFactor = min(dot(_Temps[Input.AgeFactorAndGraphIndex.y].m_colorBlendGraph, PC), 1.0);
	float3 Color = ColorBlendFactor * _Temps[Input.AgeFactorAndGraphIndex.y].m_color2.rgb;
	Color += (1.0 - ColorBlendFactor) * _Temps[Input.AgeFactorAndGraphIndex.y].m_color1AndLightFactor.rgb;
	Output.Color.rgb = ((Color * Input.IntensityAndRandomIntensity[0]) + Input.IntensityAndRandomIntensity[1]) / 2.0;

	float AlphaBlendFactor = min(dot(_Temps[Input.AgeFactorAndGraphIndex.y].m_transparencyGraph, PC), 1);
	Output.LightFactorAndAlphaBlend.a = _Temps[Input.AgeFactorAndGraphIndex.y].m_color1AndLightFactor.a;
	Output.LightFactorAndAlphaBlend.b = AlphaBlendFactor * Input.RandomSizeAlphaAndIntensityBlendFactor[1];
	Output.LightFactorAndAlphaBlend = saturate(Output.LightFactorAndAlphaBlend);

	Output.AnimBFactorAndLMapIntOffset.a = Input.RandomSizeAlphaAndIntensityBlendFactor[2];
	Output.AnimBFactorAndLMapIntOffset.b = saturate(saturate((Input.Pos.y - _HemiShadowAltitude) / 10.0f) + _Temps[Input.AgeFactorAndGraphIndex.y].m_uvRangeLMapIntensiyAndParticleMaxSize.z);
	Output.AnimBFactorAndLMapIntOffset = saturate(Output.AnimBFactorAndLMapIntOffset);

	// Compute size of particle using the constants of the _Temps[Input.AgeFactorAndGraphIndex.y]ate (mSizeGraph)
	float Size = min(dot(_Temps[Input.AgeFactorAndGraphIndex.y].m_sizeGraph, PC), 1.0) * _Temps[Input.AgeFactorAndGraphIndex.y].m_uvRangeLMapIntensiyAndParticleMaxSize.w;
	Size += Input.RandomSizeAlphaAndIntensityBlendFactor.x;

	// Displace vertex
	float2 Rotation = Input.Rotation * _OneOverShort;
	Pos.xy = (Input.DisplaceCoords.xy * Size) + Pos.xy;
	Output.HPos = mul(Pos, _ProjMat);

	// Compute texcoords
	// Rotate and scale to correct u,v space and zoom in.
	float2 TexCoords = Input.TexCoords.xy * _OneOverShort;
	float2 RotatedTexCoords = float2(TexCoords.x * Rotation.y - TexCoords.y * Rotation.x, TexCoords.x * Rotation.x + TexCoords.y * Rotation.y);
	RotatedTexCoords *= _Temps[Input.AgeFactorAndGraphIndex.y].m_uvRangeLMapIntensiyAndParticleMaxSize.xy * _UVScale;

	// Bias texcoords
	RotatedTexCoords.x += _Temps[Input.AgeFactorAndGraphIndex.y].m_uvRangeLMapIntensiyAndParticleMaxSize.x;
	RotatedTexCoords.y = _Temps[Input.AgeFactorAndGraphIndex.y].m_uvRangeLMapIntensiyAndParticleMaxSize.y - RotatedTexCoords.y;
	RotatedTexCoords *= 0.5f;

	// Offset texcoords
	float4 UVOffsets = Input.UVOffsets * _OneOverShort;
	Output.DiffuseCoords = RotatedTexCoords.xyxy + UVOffsets.xyzw;

	// Hemi lookup coords
	Output.HemiLUTCoord.xy = ((Input.Pos + (_HemiMapInfo.z / 2.0)).xz - _HemiMapInfo.xy) / _HemiMapInfo.z;
	Output.HemiLUTCoord.y = 1.0 - Output.HemiLUTCoord.y;

	Output.Fog = saturate(calcFog(Output.HPos.w));

	return Output;
}

#define LOW
// #define MED
// #define HIGH

float4 Particle_PS(VS2PS_Particle Input) : COLOR
{
	float4 TDiffuse = tex2D(Particles_Diffuse_Sampler, Input.DiffuseCoords.xy);

	#ifndef LOW
		float4 TDiffuse2 = tex2D(Particles_Diffuse_Sampler_2, Input.DiffuseCoords.zw);
	#endif

	#ifdef HIGH
		float4 TLUT = tex2D(Particles_LUT_Sampler, Input.HemiLUTCoord.xy);
	#else
		float4 TLUT = 1.0;
	#endif

	#ifndef LOW
		float4 Color = lerp(TDiffuse, TDiffuse2, Input.AnimBFactorAndLMapIntOffset.a);
		Color.rgb *=  Calc_Particle_Lighting(TLUT.a, Input.AnimBFactorAndLMapIntOffset.b, Input.LightFactorAndAlphaBlend.a);
	#else
		float4 Color = TDiffuse;
	#endif

	Color.rgb *= 2.0 * Input.Color.rgb;
	Color.a *= Input.LightFactorAndAlphaBlend.b;

	// Use me if we decide to sort by blendMode
	// Color.rgb *= Color.a;

	return Color;
}

/*
	Ordinary techniques
*/

float4 Particle_Low_PS(VS2PS_Particle Input) : COLOR
{
	float4 Color = tex2D(Particles_Diffuse_Sampler, Input.DiffuseCoords.xy);
	Color.rgb *= 2.0 * Input.Color.rgb * _EffectSunColor; // M
	Color.a *= Input.LightFactorAndAlphaBlend.b;

	// Fog
	Color.rgb = lerp(FogColor.rgb, Color.rgb, Input.Fog);
	return Color;
}

float4 Particle_Medium_PS(VS2PS_Particle Input) : COLOR
{
	float4 TDiffuse = tex2D(Particles_Diffuse_Sampler, Input.DiffuseCoords.xy);
	float4 TDiffuse2 = tex2D(Particles_Diffuse_Sampler_2, Input.DiffuseCoords.zw);
	float4 Color = lerp(TDiffuse, TDiffuse2, Input.AnimBFactorAndLMapIntOffset.a);
	Color.rgb *= Calc_Particle_Lighting(1.0, Input.AnimBFactorAndLMapIntOffset.b, Input.LightFactorAndAlphaBlend.a);
	Color.rgb *= 2.0 * Input.Color.rgb;
	Color.a *= Input.LightFactorAndAlphaBlend.b;

	// Fog
	Color.rgb = lerp(FogColor.rgb, Color.rgb, Input.Fog);
	return Color;
}

float4 Particle_High_PS(VS2PS_Particle Input) : COLOR
{
	float4 TDiffuse = tex2D(Particles_Diffuse_Sampler, Input.DiffuseCoords.xy);
	float4 TDiffuse2 = tex2D(Particles_Diffuse_Sampler_2, Input.DiffuseCoords.zw);
	float4 TLUT = tex2D(Particles_LUT_Sampler, Input.HemiLUTCoord.xy);
	float4 Color = lerp(TDiffuse, TDiffuse2, Input.AnimBFactorAndLMapIntOffset.a);
	Color.rgb *= Calc_Particle_Lighting(TLUT.a, Input.AnimBFactorAndLMapIntOffset.b, Input.LightFactorAndAlphaBlend.a);
	Color.rgb *= 2.0 * Input.Color.rgb;
	Color.a *= Input.LightFactorAndAlphaBlend.b;

	// Fog
	Color.rgb = lerp(FogColor.rgb, Color.rgb, Input.Fog);
	return Color;
}

#define COMMON_RENDERSTATES_PARTICLE \
	CullMode = NONE; \
	ZEnable = TRUE; \
	ZFunc = LESSEQUAL; \
	ZWriteEnable = FALSE; \
	StencilEnable = FALSE; \
	StencilFunc = ALWAYS; \
	StencilPass = ZERO; \
	AlphaTestEnable = TRUE; \
	AlphaRef = <_AlphaPixelTestRef>; \
	AlphaBlendEnable = TRUE; \
	SrcBlend = SRCALPHA; \
	DestBlend = INVSRCALPHA; \

technique ParticleLow
<
>
{
	pass p0
	{
		COMMON_RENDERSTATES_PARTICLE
		VertexShader = compile vs_3_0 Particle_VS();
		PixelShader = compile ps_3_0 Particle_Low_PS();
	}
}

technique ParticleMedium
<
>
{
	pass p0
	{
		COMMON_RENDERSTATES_PARTICLE
		VertexShader = compile vs_3_0 Particle_VS();
		PixelShader = compile ps_3_0 Particle_Medium_PS();
	}
}

technique ParticleHigh
<
>
{
	pass p0
	{
		COMMON_RENDERSTATES_PARTICLE
		VertexShader = compile vs_3_0 Particle_VS();
		PixelShader = compile ps_3_0 Particle_High_PS();
	}
}




float4 Particle_Show_Fill_PS(VS2PS_Particle Input) : COLOR
{
	float4 OutColor = _EffectSunColor.rrrr;

	// Fog
	OutColor.rgb = lerp(FogColor.rgb, OutColor.rgb, Input.Fog);
	return OutColor;
}

float4 Particle_Additive_Low_PS(VS2PS_Particle Input) : COLOR
{
	float4 Color = tex2D(Particles_Diffuse_Sampler, Input.DiffuseCoords.xy);
	Color.rgb *= 2.0 * Input.Color.rgb;

	// Mask with alpha since were doing an add
	Color.rgb *= Color.a * Input.LightFactorAndAlphaBlend.b;
	return Color;
}

float4 Particle_Additive_High_PS(VS2PS_Particle Input) : COLOR
{
	float4 TDiffuse = tex2D(Particles_Diffuse_Sampler, Input.DiffuseCoords.xy);
	float4 TDiffuse2 = tex2D(Particles_Diffuse_Sampler_2, Input.DiffuseCoords.zw);

	float4 Color = lerp(TDiffuse, TDiffuse2, Input.AnimBFactorAndLMapIntOffset.a);
	Color.rgb *= 2.0 * Input.Color.rgb;
	// Mask with alpha since were doing an add
	Color.rgb *= Color.a * Input.LightFactorAndAlphaBlend.b;
	return Color;
}

#define COMMON_RENDERSTATES_PARTICLE_ADDITIVE \
	CullMode = NONE; \
	ZEnable = TRUE; \
	ZFunc = LESSEQUAL; \
	ZWriteEnable = FALSE; \
	StencilEnable = FALSE; \
	StencilFunc = ALWAYS; \
	StencilPass = ZERO; \
	AlphaTestEnable = TRUE; \
	AlphaRef = <_AlphaPixelTestRef>; \
	AlphaBlendEnable = TRUE; \
	SrcBlend = ONE; \
	DestBlend = ONE; \

technique ParticleShowFill
<
	>
{
	pass p0
	{
		COMMON_RENDERSTATES_PARTICLE_ADDITIVE
		VertexShader = compile vs_3_0 Particle_VS();
		PixelShader = compile ps_3_0 Particle_Show_Fill_PS();
	}
}

technique AdditiveLow
<
>
{
	pass p0
	{
		COMMON_RENDERSTATES_PARTICLE_ADDITIVE
		VertexShader = compile vs_3_0 Particle_VS();
		PixelShader = compile ps_3_0 Particle_Additive_Low_PS();
	}
}

technique AdditiveHigh
<
>
{
	pass p0
	{
		COMMON_RENDERSTATES_PARTICLE_ADDITIVE
		VertexShader = compile vs_3_0 Particle_VS();
		PixelShader = compile ps_3_0 Particle_Additive_High_PS();
	}
}
