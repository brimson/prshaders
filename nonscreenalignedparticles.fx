#line 2 "NonScreenAlignedParticles.fx"
#include "shaders/FXCommon.fx"

/*
	[Textures and samplers]
*/

sampler NonScreenAlignedParticles_Diffuse_Sampler = sampler_state
{
	Texture = <Texture_0>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = FILTER_PARTICLE_MIP;
	AddressU = CLAMP;
	AddressV = CLAMP;
};

sampler NonScreenAlignedParticles_Diffuse_Sampler_2 = sampler_state 
{
	Texture = <Texture_0>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = FILTER_PARTICLE_MIP;
	AddressU = CLAMP;
	AddressV = CLAMP;
};

sampler NonScreenAlignedParticles_LUT_Sampler = sampler_state 
{ 
	Texture = <Texture_1>; 
	AddressU = CLAMP; 
	AddressV = CLAMP; 
	MinFilter = LINEAR; 
	MagFilter = LINEAR; 
	MipFilter = FILTER_PARTICLE_MIP; 
};

// constant array
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
	float3 DisplaceCoords : TEXCOORD2;
	float2 IntensityAndRandomIntensity : TEXCOORD3;
	float4 RotationAndWaterSurfaceOffset : TEXCOORD4;
	float4 UVOffsets : TEXCOORD5;
	float2 TexCoords : TEXCOORD6;
};

struct VS2PS
{
	float4 HPos : POSITION;
	float4 Color : TEXCOORD0;
	float4 DiffuseCoords : TEXCOORD1; // .xy = Diffuse1; .zw = Diffuse2
	float2 HemiLUTCoord : TEXCOORD2; // Hemi look-up table coordinates
	float4 AnimBFactor : COLOR0;
	float4 LMapIntOffsetAndLFactor : COLOR1;
	float Fog : FOG;
};

VS2PS Particle_VS(APP2VS Input)
{
	VS2PS Output = (VS2PS)0;

	// Compute Cubic polynomial factors.
	float4 PC = float4(pow(Input.AgeFactorAndGraphIndex[0], float3(3.0, 2.0, 1.0)), 1.0);

	float ColorBlendFactor = min(dot(_Temps[Input.AgeFactorAndGraphIndex.y].m_colorBlendGraph, PC), 1.0);
	float3 Color = ColorBlendFactor * _Temps[Input.AgeFactorAndGraphIndex.y].m_color2.rgb;
	Color += (1.0 - ColorBlendFactor) * _Temps[Input.AgeFactorAndGraphIndex.y].m_color1AndLightFactor.rgb;

	Output.Color.rgb = ((Color * Input.IntensityAndRandomIntensity[0]) + Input.IntensityAndRandomIntensity[1]) / 2.0;

	float AlphaBlendFactor = min(dot(_Temps[Input.AgeFactorAndGraphIndex.y].m_transparencyGraph, PC), 1.0);
	// Output.Color.a = AlphaBlendFactor * Input.RandomSizeAlphaAndIntensityBlendFactor[1];

	Output.AnimBFactor.a = AlphaBlendFactor * Input.RandomSizeAlphaAndIntensityBlendFactor[1];
	Output.AnimBFactor.b = Input.RandomSizeAlphaAndIntensityBlendFactor[2];
	Output.AnimBFactor = saturate(Output.AnimBFactor);

	Output.LMapIntOffsetAndLFactor.a = saturate(saturate((Input.Pos.y - _HemiShadowAltitude) / 10.0f) + _Temps[Input.AgeFactorAndGraphIndex.y].m_uvRangeLMapIntensiyAndParticleMaxSize.z);
	Output.LMapIntOffsetAndLFactor.b = _Temps[Input.AgeFactorAndGraphIndex.y].m_color1AndLightFactor.a;
	Output.LMapIntOffsetAndLFactor = saturate(Output.LMapIntOffsetAndLFactor);

	// Compute size of particle using the constants of the _Temps[Input.AgeFactorAndGraphIndex.y]ate (mSizeGraph)
	float Size = min(dot(_Temps[Input.AgeFactorAndGraphIndex.y].m_sizeGraph, PC), 1.0) * _Temps[Input.AgeFactorAndGraphIndex.y].m_uvRangeLMapIntensiyAndParticleMaxSize.w;
	Size += Input.RandomSizeAlphaAndIntensityBlendFactor.x;

	// Unpack verts
	float4 Rotation = Input.RotationAndWaterSurfaceOffset * _OneOverShort;
	float2 TexCoords = Input.TexCoords*_OneOverShort;

	// Displace vertex
	float3 ScaledPos = Input.DisplaceCoords * Size + Input.Pos.xyz;
	ScaledPos.y += Rotation.w;

	float4 Pos = mul(float4(ScaledPos, 1.0), _ViewMat);
	Output.HPos = mul(Pos, _ProjMat);

	// Compute texcoords
	// Rotate and scale to correct uv space and zoom in.
	float2 RotatedTexCoords = float2(TexCoords.x * Rotation.y - TexCoords.y * Rotation.x, TexCoords.x * Rotation.x + TexCoords.y * Rotation.y);
	RotatedTexCoords *= _Temps[Input.AgeFactorAndGraphIndex.y].m_uvRangeLMapIntensiyAndParticleMaxSize.xy * _UVScale;

	// Bias texcoords
	RotatedTexCoords.x += _Temps[Input.AgeFactorAndGraphIndex.y].m_uvRangeLMapIntensiyAndParticleMaxSize.x;
	RotatedTexCoords.y = _Temps[Input.AgeFactorAndGraphIndex.y].m_uvRangeLMapIntensiyAndParticleMaxSize.y - RotatedTexCoords.y;
	RotatedTexCoords *= 0.5f;

	// Offset texcoords for particle diffuse
	float4 UVOffsets = Input.UVOffsets * _OneOverShort;
	Output.DiffuseCoords = RotatedTexCoords.xyxy + UVOffsets.xyzw;

	// Hemi lookup table coords
 	Output.HemiLUTCoord.xy = ((Input.Pos + (_HemiMapInfo.z/2)).xz - _HemiMapInfo.xy) / _HemiMapInfo.z;
 	Output.HemiLUTCoord.y = 1.0 - Output.HemiLUTCoord.y;

	Output.Fog = saturate(calcFog(Output.HPos.w));

	return Output;
}

// Ordinary technique

/*	int Declaration[] =
	{
		// StreamNo, DataType, Usage, UsageIdx
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_posITION, 0 },
		{ 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0 },
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_TEXCOORD, 1 },
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_TEXCOORD, 2 },
		{ 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 3 },
		{ 0, D3DDECLTYPE_SHORT4, D3DDECLUSAGE_TEXCOORD, 4 },
		{ 0, D3DDECLTYPE_SHORT4, D3DDECLUSAGE_TEXCOORD, 5 },
		{ 0, D3DDECLTYPE_SHORT2, D3DDECLUSAGE_TEXCOORD, 6 },
		DECLARATION_END	// End macro
	};
*/

float4 Particle_Show_Fill_PS(VS2PS Input) : COLOR
{
	float4 OutColor = _EffectSunColor.rrrr;
	// Fog
	OutColor.rgb = lerp(FogColor.rgb, OutColor.rgb, Input.Fog);
	return OutColor;
}

technique NSAParticleShowFill
<
>
{
	pass p0
	{
		CullMode = NONE;
		ZEnable = TRUE;
		ZFunc = LESSEQUAL;
		ZWriteEnable = FALSE;
		StencilEnable = FALSE;
		StencilFunc = ALWAYS;
		StencilPass = ZERO;
		AlphaTestEnable = TRUE;
		AlphaRef = <_AlphaPixelTestRef>;
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;

 		VertexShader = compile vs_3_0 Particle_VS();
		PixelShader = compile ps_3_0 Particle_Show_Fill_PS();
	}
}

float4 Particle_Low_PS(VS2PS Input) : COLOR
{
	float4 Color = tex2D(NonScreenAlignedParticles_Diffuse_Sampler, Input.DiffuseCoords.xy);
	Color.rgb *= 2.0 * Input.Color.rgb;
	Color.a *= Input.AnimBFactor.a;
	// Fog
	Color.rgb = lerp(FogColor.rgb, Color.rgb, Input.Fog);
	return Color;
}

technique NSAParticleLow
<
>
{
	pass p0
	{
		CullMode = NONE;
		ZEnable = TRUE;
		ZFunc = LESSEQUAL;
		ZWriteEnable = FALSE;
		StencilEnable = FALSE;
		StencilFunc = ALWAYS;
		StencilPass = ZERO;
		AlphaTestEnable = TRUE;
		AlphaRef = <_AlphaPixelTestRef>;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

 		VertexShader = compile vs_3_0 Particle_VS();
		PixelShader = compile ps_3_0 Particle_Low_PS();
	}
}

float4 Particle_Medium_PS(VS2PS Input) : COLOR
{
	float4 TDiffuse = tex2D(NonScreenAlignedParticles_Diffuse_Sampler, Input.DiffuseCoords.xy);
	float4 TDiffuse2 = tex2D(NonScreenAlignedParticles_Diffuse_Sampler_2, Input.DiffuseCoords.zw);
	float4 Color = lerp(TDiffuse, TDiffuse2, Input.AnimBFactor.b);
	Color.rgb *= 2.0 * Input.Color.rgb;
	Color.rgb *= Calc_Particle_Lighting(1.0, Input.LMapIntOffsetAndLFactor.a, Input.LMapIntOffsetAndLFactor.b);
	Color.a *= Input.AnimBFactor.a;
	// Fog
	Color.rgb = lerp(FogColor.rgb, Color.rgb, Input.Fog);
	return Color;
}

technique NSAParticleMedium
<
>
{
	pass p0
	{
		CullMode = NONE;
		ZEnable = TRUE;
		ZFunc = LESSEQUAL;
		ZWriteEnable = FALSE;
		StencilEnable = FALSE;
		StencilFunc = ALWAYS;
		StencilPass = ZERO;
		AlphaTestEnable = TRUE;
		AlphaRef = <_AlphaPixelTestRef>;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

 		VertexShader = compile vs_3_0 Particle_VS();
		PixelShader = compile ps_3_0 Particle_Medium_PS();
	}
}

float4 Particle_High_PS(VS2PS Input) : COLOR
{
	float4 TDiffuse = tex2D(NonScreenAlignedParticles_Diffuse_Sampler, Input.DiffuseCoords.xy);
	float4 TDiffuse2 = tex2D(NonScreenAlignedParticles_Diffuse_Sampler_2, Input.DiffuseCoords.zw);
	float4 TLut = tex2D(NonScreenAlignedParticles_LUT_Sampler, Input.HemiLUTCoord.xy);

	float4 Color = lerp(TDiffuse, TDiffuse2, Input.AnimBFactor.b);
	Color.rgb *= 2.0 * Input.Color.rgb;
	Color.rgb *= Calc_Particle_Lighting(TLut.a, Input.LMapIntOffsetAndLFactor.a, Input.LMapIntOffsetAndLFactor.b);
	Color.a *= Input.AnimBFactor.a;
	// Fog
	Color.rgb = lerp(FogColor.rgb, Color.rgb, Input.Fog);
	return Color;
}

technique NSAParticleHigh
<
>
{
	pass p0
	{
		CullMode = NONE;
		ZEnable = TRUE;
		ZFunc = LESSEQUAL;
		ZWriteEnable = FALSE;
		StencilEnable = FALSE;
		StencilFunc = ALWAYS;
		StencilPass = ZERO;
		AlphaTestEnable = TRUE;
		AlphaRef = <_AlphaPixelTestRef>;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

 		VertexShader = compile vs_3_0 Particle_VS();
		PixelShader = compile ps_3_0 Particle_High_PS();
	}
}
