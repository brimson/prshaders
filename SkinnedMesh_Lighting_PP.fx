
#include "shaders/SkinnedMesh_Shared.fx"

#if !defined(SKINNEDMESH_SHARED_FX)
	#include "SkinnedMesh_Shared.fx"
#endif

struct VS2PS_PP
{
	float4 Pos : POSITION;
	float2 Tex0 : TEXCOORD0;
	float3 GroundUVAndLerp : TEXCOORD1;
	float3 SkinnedLightVec : TEXCOORD2;
	float3 HalfVec : TEXCOORD3;
};

// PP object based lighting

VS2PS_PP Hemi_Sun_PP_VS(APP2VS Input, uniform int NumBones)
{
	VS2PS_PP Output;
	float3 Pos, Normal, SkinnedLightVec;
	SkinSoldier_PP(NumBones, Input, -_SunLightDir.xyz, Pos, Normal, SkinnedLightVec);

	// Transform position into view and then projection space
	Output.Pos = mul(float4(Pos.xyz, 1.0), _WorldViewProj);

	// Hemi lookup values
	float4 WPos = mul(float4(Pos.xyz, 1.0), _World);
	Output.GroundUVAndLerp = SkinnedMesh_Calc_HemiLookup(WPos, _HemiMapInfo, Normal);

	// [TS:040201] Please note that "normalize(_WorldEyePos-WPos)" is in worldspace while "SkinnedLightVec" is in SkinnedSpace/ObjectSpace can this be correct??
	// Output.HalfVec = normalize(normalize(_WorldEyePos-WPos) + SkinnedLightVec);
	Output.HalfVec = normalize(normalize(_ObjectEyePos.xyz - Pos) + SkinnedLightVec);
	Output.SkinnedLightVec = normalize(SkinnedLightVec);

	Output.Tex0 = Input.TexCoord0;

	return Output;
}

// PP tangent based lighting

VS2PS_PP Hemi_Sun_PP_Tangent_VS(APP2VStangent Input, uniform int NumBones)
{
	VS2PS_PP Output;
	float3 Pos, Normal, SkinnedLightVec;
	float4 WPos;

	SkinSoldier_PP_Tangent(NumBones, Input, -_SunLightDir.xyz, Pos, Normal, SkinnedLightVec, WPos, Output.HalfVec);

	// Transform position into view and then projection space
	Output.Pos = mul(float4(Pos.xyz, 1.0), _WorldViewProj);

	Output.GroundUVAndLerp = SkinnedMesh_Calc_HemiLookup(WPos, _HemiMapInfo, Normal);

	Output.SkinnedLightVec = normalize(SkinnedLightVec);

	Output.Tex0 = Input.TexCoord0;

	return Output;
}

float4 Hemi_PP(VS2PS_PP Input, bool UseColor)
{
	float4 GroundColor = tex2D(Sampler_0, Input.GroundUVAndLerp.xy);
	float4 HemiColor = lerp(GroundColor, _SkyColor, Input.GroundUVAndLerp.z);
	float4 Normal = tex2D(Sampler_1, Input.Tex0);
	float3 ExpNormal = normalize(Normal * 2.0 - 1.0);
	float3 SunColor = saturate(dot(ExpNormal.rgb, Input.SkinnedLightVec)) * _SunColor;
	float Specular = pow(dot(ExpNormal.rgb, Input.HalfVec), 36.0) * Normal.a;

	// Do something with spec-alpha later on
	float4 TotalColor = 0.0;
	if(UseColor)
	{
		TotalColor = saturate(float4(SunColor * GroundColor.a * GroundColor.a + _AmbientColor.rgb * HemiColor.rgb, Specular));
		float4 Color = tex2D(Sampler_2, Input.Tex0);
		TotalColor.rgb *= Color.rgb;
		TotalColor.rgb += Specular;
		TotalColor.a = Color.a;
	}
	else
	{
		TotalColor = float4(SunColor, Specular);
		TotalColor *= GroundColor.a * GroundColor.a;
		TotalColor.rgb += _AmbientColor * HemiColor;
	}

	return TotalColor;
}

float4 Hemi_Sun_PP_PS(VS2PS_PP Input) : COLOR
{
	return Hemi_PP(Input, false);
}

float4 Hemi_Sun_Color_PP_PS(VS2PS_PP Input) : COLOR
{
	return Hemi_PP(Input, true);
}




struct VS2PS_PP_Shadow
{
	float4 Pos : POSITION;
	float2 Tex0 : TEXCOORD0;
	float3 GroundUVAndLerp : TEXCOORD1;
	float3 SkinnedLightVec : TEXCOORD2;
	float3 HalfVec : TEXCOORD3;
	float4 ShadowTex : TEXCOORD4;
};

VS2PS_PP_Shadow Hemi_Sun_Shadow_PP_VS(APP2VS Input, uniform int NumBones)
{
	VS2PS_PP_Shadow Output;
	float3 Pos, Normal, SkinnedLightVec;

	SkinSoldier_PP(NumBones, Input, -_SunLightDir.xyz, Pos, Normal, SkinnedLightVec);

	// Transform position into view and then projection space
	Output.Pos = mul(float4(Pos.xyz, 1.0), _WorldViewProj);

	// Shadow
	Output.ShadowTex = mul(float4(Pos, 1.0), _LightTrapezMat);
	float2 TexShadow2 = mul(float4(Pos, 1.0), _LightMat).zw;
	TexShadow2.x -= 0.007;
	Output.ShadowTex.z = (TexShadow2.x*Output.ShadowTex.w)/TexShadow2.y; // (zL*wT)/wL == zL/wL post homo

	// Hemi lookup values
	float4 WPos = mul(float4(Pos.xyz, 1.0), _World);
	Output.GroundUVAndLerp = SkinnedMesh_Calc_HemiLookup(WPos, _HemiMapInfo, Normal);

	// [TS:040201] Please note that "normalize(_WorldEyePos-WPos") is in worldspace while "SkinnedLightVec" is in SkinnedSpace/ObjectSpace can this be correct??
	// Output.HalfVec = normalize(normalize(_WorldEyePos-WPos) + SkinnedLightVec);
	Output.HalfVec = normalize(normalize(_ObjectEyePos.xyz - Pos) + SkinnedLightVec);
	Output.SkinnedLightVec = normalize(SkinnedLightVec);

	Output.Tex0 = Input.TexCoord0;

	return Output;
}

VS2PS_PP_Shadow Hemi_Sun_Shadow_PP_Tangent_VS(APP2VStangent Input, uniform int NumBones)
{
	VS2PS_PP_Shadow Output;
	float3 Pos, Normal, SkinnedLightVec;
	float4 WPos;

	SkinSoldier_PP_Tangent(NumBones, Input, -_SunLightDir.xyz, Pos, Normal, SkinnedLightVec, WPos, Output.HalfVec);

	// Transform position into view and then projection space
	Output.Pos = mul(float4(Pos.xyz, 1.0), _WorldViewProj);

 	// Hemi lookup values
	Output.GroundUVAndLerp = SkinnedMesh_Calc_HemiLookup(WPos, _HemiMapInfo, Normal);

	// Shadow
	Output.ShadowTex =  mul(float4(Pos, 1.0), _LightTrapezMat);
	float2 TexShadow2 = mul(float4(Pos, 1.0), _LightMat).zw;
	TexShadow2.x -= 0.007;
	Output.ShadowTex.z = (TexShadow2.x * Output.ShadowTex.w) / TexShadow2.y; // (zL*wT)/wL == zL/wL post homo

	Output.SkinnedLightVec = normalize(SkinnedLightVec);

	Output.Tex0 = Input.TexCoord0;

	return Output;
}

float4 Hemi_Sun_Shadow_Color_PP_PS(VS2PS_PP_Shadow Input) : COLOR
{
	float4 GroundColor = tex2D(Sampler_0, Input.GroundUVAndLerp.xy);
	float4 HemiColor = lerp(GroundColor, _SkyColor, Input.GroundUVAndLerp.z);
	float4 Normal = tex2D(Sampler_1, Input.Tex0);
	float3 ExpNormal = normalize(Normal * 2.0 - 1.0);
	float3 SunColor = saturate(dot(ExpNormal.rgb, Input.SkinnedLightVec)) * _SunColor;
	float Specular = pow(dot(ExpNormal.rgb, Input.HalfVec), 36.0) * Normal.a;

	// Input.ShadowTex.xy = clamp(Input.ShadowTex.xy, _ViewportMap.xy, _ViewportMap.zw);
	float4 Samples = SkinnedMesh_Samples(Sampler_4, Input.ShadowTex, float2(0.5 / 1024.0, 0.5 / 1024.0));
	float4 StaticSamples = SkinnedMesh_StaticSamples(Sampler_3, Input.ShadowTex.xy, float2(0.5 / 1024.0, 0.5 / 1024.0));
	StaticSamples.x = dot(StaticSamples.xyzw, 0.25);

	float4 CMPBits = Samples > saturate(Input.ShadowTex.z / Input.ShadowTex.w);
	float AvgShadowValue = dot(CMPBits, 0.25);

	float TotalShadow = AvgShadowValue.x * StaticSamples.x;
	// return AvgShadowValue;
	float4 Color = tex2D(Sampler_2, Input.Tex0);
	float4 TotalColor = saturate(float4(SunColor * TotalShadow + _AmbientColor.rgb * HemiColor.rgb, Specular)); // Do something with spec-alpha later on
	TotalColor.rgb *= Color.rgb;
	TotalColor.rgb += Specular * TotalShadow* TotalShadow;
	TotalColor.a = Color.a;

	return TotalColor;
}




// PP object based lighting

struct VS2PS_PointLight_PP
{
	float4 Pos : POSITION;
	float2 Tex0 : TEXCOORD0;
	float4 SkinnedLightVec : TEXCOORD1;
	float3 HalfVec : TEXCOORD2;
};

VS2PS_PointLight_PP PointLight_PP_VS(APP2VS Input, uniform int NumBones)
{
	VS2PS_PointLight_PP Output;
	float3 Pos, Normal, SkinnedLightVec;

	SkinSoldier_Point_PP(NumBones, Input, _LightPos.xyz, Pos, Normal, SkinnedLightVec);

	// Transform position into view and then projection space
	Output.Pos = mul(float4(Pos.xyz, 1.0), _WorldViewProj);
	float4 WPos = mul(float4(Pos.xyz, 1.0), _World);

	// [TS:040201] Please note that "normalize(_WorldEyePos-WPos") is in worldspace while "SkinnedLightVec" is in SkinnedSpace/ObjectSpace can this be correct??
	// Output.HalfVec = normalize(normalize(_WorldEyePos-WPos) + SkinnedLightVec);
	Output.HalfVec = normalize(normalize(_ObjectEyePos.xyz - Pos) + SkinnedLightVec);
	float3 NormalizedSkinnedVec = normalize(SkinnedLightVec);
	Output.SkinnedLightVec.xyz = NormalizedSkinnedVec;

	// Skinnedmeshes are highly tesselated, so..
	float RadialAtt = 1.0 - saturate(dot(SkinnedLightVec, SkinnedLightVec)*_AttenuationSqrInv);
	Output.SkinnedLightVec.w = RadialAtt;

	Output.Tex0 = Input.TexCoord0;

	return Output;
}

// PP tangent based lighting

VS2PS_PointLight_PP PointLight_PP_Tangent_VS(APP2VStangent Input, uniform int NumBones)
{
	VS2PS_PointLight_PP Output;
	float3 Pos, Normal, SkinnedLightVec;

	SkinSoldier_Point_PP_Tangent(NumBones, Input, _LightPos.xyz, Pos, Normal, SkinnedLightVec, Output.HalfVec);

	// Transform position into view and then projection space
	Output.Pos = mul(float4(Pos.xyz, 1.0), _WorldViewProj);

	float3 NormalizedSkinnedVec = normalize(SkinnedLightVec);
	Output.SkinnedLightVec.xyz = NormalizedSkinnedVec;

	// Skinnedmeshes are highly tesselated, so..
	float RadialAtt = 1.0 - saturate(dot(SkinnedLightVec, SkinnedLightVec) * _AttenuationSqrInv);
	Output.SkinnedLightVec.w = RadialAtt;

	Output.Tex0 = Input.TexCoord0;

	return Output;
}

float4 PointLight_PP_PS(VS2PS_PointLight_PP Input) : COLOR
{
	// float3 NormalizedLightVec = normalize(Input.SkinnedLightVec);
	// float RadialAtt = 1.0 - saturate(dot(Input.SkinnedLightVec, Input.SkinnedLightVec) * _AttenuationSqrInv);

	float4 ExpandedNormal = tex2D(Sampler_1, Input.Tex0);
	ExpandedNormal.xyz = (ExpandedNormal.xyz * 2.0 - 1.0);
	float2 IntensityUV = float2(dot(Input.SkinnedLightVec.xyz,ExpandedNormal.xyz), dot(Input.HalfVec, ExpandedNormal.xyz));
	float4 RealIntensity = float4(IntensityUV.rrr, pow(IntensityUV.g, 36.0) * ExpandedNormal.a);
	RealIntensity *= _LightColor * Input.SkinnedLightVec.w; // RadialAtt;
	return RealIntensity;
}




struct VS2PS_SpotLight_PP
{
	float4 Pos : POSITION;
	float2 Tex0 : TEXCOORD0;
	float4 SkinnedLightVec : TEXCOORD1;
	// float3 SkinnedLightDir : TEXCOORD2;
	float3 HalfVec : TEXCOORD3;
};

VS2PS_SpotLight_PP SpotLight_PP_VS(APP2VS Input, uniform int NumBones)
{
	VS2PS_SpotLight_PP Output;
	float3 Pos, Normal, SkinnedLightVec, SkinnedLightDir;

	SkinSoldier_Spot_PP(NumBones, Input, _LightPos.xyz, _LightDir.xyz, Pos, Normal, SkinnedLightVec, SkinnedLightDir);

	// Transform position into view and then projection space
	Output.Pos = mul(float4(Pos.xyz, 1.0), _WorldViewProj);
	float4 WPos = mul(float4(Pos.xyz, 1.0), _World);

	// [TS:040201] Please note that "normalize(_WorldEyePos - WPos)" is in worldspace while "SkinnedLightVec" is in SkinnedSpace/ObjectSpace can this be correct??
	// Output.HalfVec = normalize(normalize(_WorldEyePos - WPos) + SkinnedLightVec);
	Output.HalfVec = normalize(normalize(_ObjectEyePos.xyz - Pos) + SkinnedLightVec);
	float3 NormalizedSkinnedVec = normalize(SkinnedLightVec);
	Output.SkinnedLightVec.xyz = NormalizedSkinnedVec;
	// Output.SkinnedLightDir = SkinnedLightDir;

	// Skinnedmeshes are highly tesselated, so..
	float RadialAtt = 1.0 - saturate(dot(SkinnedLightVec, SkinnedLightVec)*_AttenuationSqrInv);
	float OffCenter = dot(NormalizedSkinnedVec, SkinnedLightDir);
	float ConicalAtt = saturate(OffCenter - (1.0 - _ConeAngle)) / _ConeAngle;
	Output.SkinnedLightVec.w = RadialAtt * ConicalAtt;

	Output.Tex0 = Input.TexCoord0;

	return Output;
}

// PP tangent based lighting

VS2PS_SpotLight_PP SpotLight_PP_Tangent_VS(APP2VStangent Input, uniform int NumBones)
{
	VS2PS_SpotLight_PP Output;
	float3 Pos, Normal, SkinnedLightVec, SkinnedLightDir;

	SkinSoldier_Spot_PP_Tangent(NumBones, Input, _LightPos.xyz, _LightDir.xyz, Pos, Normal, SkinnedLightVec, SkinnedLightDir, Output.HalfVec);

	// Transform position into view and then projection space
	Output.Pos = mul(float4(Pos.xyz, 1.0), _WorldViewProj);
	float4 WPos = mul(float4(Pos.xyz, 1.0), _World);

	// [TS:040201] Please note that "normalize(_WorldEyePos-WPos)" is in worldspace while "SkinnedLightVec" is in SkinnedSpace/ObjectSpace can this be correct??
	// Output.HalfVec = normalize(normalize(_WorldEyePos-WPos) + SkinnedLightVec);
	Output.HalfVec = normalize(normalize(_ObjectEyePos.xyz - Pos) + SkinnedLightVec);
	float3 NormalizedSkinnedVec = normalize(SkinnedLightVec);
	Output.SkinnedLightVec.xyz = NormalizedSkinnedVec;
	// Output.SkinnedLightDir = SkinnedLightDir;

	// Skinnedmeshes are highly tesselated, so..
	float RadialAtt = 1.0 - saturate(dot(SkinnedLightVec, SkinnedLightVec)*_AttenuationSqrInv);
	float OffCenter = dot(NormalizedSkinnedVec, SkinnedLightDir);
	float ConicalAtt = saturate(OffCenter - (1.0 - _ConeAngle)) / _ConeAngle;
	Output.SkinnedLightVec.w = RadialAtt * ConicalAtt;

	Output.Tex0 = Input.TexCoord0;

	return Output;
}

float4 SpotLight_PP_PS(VS2PS_SpotLight_PP Input) : COLOR
{
	// float3 NormalizedLightVec = normalize(Input.SkinnedLightVec);
	// float RadialAtt = 1.0 - saturate(dot(Input.SkinnedLightVec,Input.SkinnedLightVec) * _AttenuationSqrInv);
	// float OffCenter = dot(NormalizedLightVec, normalize(Input.SkinnedLightDir));
	// float ConicalAtt = saturate(OffCenter - (1.0 - _ConeAngle)) / _ConeAngle;

	float4 ExpandedNormal = tex2D(Sampler_1, Input.Tex0);
	ExpandedNormal.xyz = ExpandedNormal.xyz * 2.0 - 1.0;
	float2 IntensityUV = float2(dot(Input.SkinnedLightVec, ExpandedNormal), dot(Input.HalfVec, ExpandedNormal.xyz));
	float4 RealIntensity = float4(IntensityUV.rrr, pow(IntensityUV.g, 36.0) * ExpandedNormal.a);
	RealIntensity.rgb *= _LightColor;
	return RealIntensity * Input.SkinnedLightVec.w; // * ConicalAtt * RadialAtt;
}
