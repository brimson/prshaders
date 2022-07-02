
/*
	Human skin
*/

#include "shaders/SkinnedMesh_Shared.fx"

#if !defined(SKINNEDMESH_SHARED_FX)
	#include "SkinnedMesh_Shared.fx"
#endif

struct VS2PS_Skin_Pre
{
	float4 Pos : POSITION;
	float2 Tex0 : TEXCOORD0;
	float3 SkinnedLightVec : TEXCOORD1;
	float3 ObjEyeVec : TEXCOORD2;
	float3 GroundUVAndLerp : TEXCOORD3;
};

VS2PS_Skin_Pre Skin_Pre_VS(APP2VS Input, uniform int NumBones)
{
	VS2PS_Skin_Pre Output;
	float3 Pos, Normal;

	SkinSoldier_PP(NumBones, Input, -_SunLightDir.xyz, Pos, Normal, Output.SkinnedLightVec);

	Output.ObjEyeVec = normalize(_ObjectEyePos.xyz - Pos);

	Output.Pos.xy = Input.TexCoord0 * float2(2.0, -2.0) - float2(1.0, -1.0);
	Output.Pos.zw = float2(0.0, 1.0);

 	// Hemi lookup values
	float4 WPos = mul(Pos, _World);
	Output.GroundUVAndLerp = SkinnedMesh_Calc_HemiLookup(WPos, _HemiMapInfo, Normal);

	Output.Tex0 = Input.TexCoord0;
	Output.SkinnedLightVec = normalize(Output.SkinnedLightVec);

	return Output;
}

float4 Skin_Pre_PS(VS2PS_Skin_Pre Input) : COLOR
{
	// return float4(Input.ObjEyeVec, 0.0);
	float4 ExpNormal = tex2D(Sampler_0, Input.Tex0);
	float4 GroundColor = tex2D(Sampler_1, Input.GroundUVAndLerp.xy);

	ExpNormal.rgb = (ExpNormal * 2.0) - 1.0;
	float WrapDiff = dot(ExpNormal.xyz, Input.SkinnedLightVec) + 0.5;
	WrapDiff = saturate(WrapDiff / 1.5);

	float RimDiff = 1.0 - dot(ExpNormal.xyz, Input.ObjEyeVec);
	RimDiff = pow(RimDiff, 3.0);

	RimDiff *= saturate(0.75 - saturate(dot(Input.ObjEyeVec, Input.SkinnedLightVec)));
	// RimDiff *= saturate(0.1 - saturate(dot(Input.ObjEyeVec, normalize(Input.SkinnedLightVec))));

	return float4((WrapDiff.rrr + RimDiff) * GroundColor.a * GroundColor.a, ExpNormal.a);
}




struct VS2PS_Skin_Pre_Shadowed
{
	float4 Pos : POSITION;
	float4 Tex0AndHZW : TEXCOORD0;
	float3 SkinnedLightVec : TEXCOORD1;
	float4 ShadowTex : TEXCOORD2;
	float3 ObjEyeVec : TEXCOORD3;
};

VS2PS_Skin_Pre_Shadowed Skin_Pre_Shadowed_VS(APP2VS Input, uniform int NumBones)
{
	VS2PS_Skin_Pre_Shadowed Output;
	float3 Pos, Normal;

	// don't need as much code for this case.. will rewrite later
	SkinSoldier_PP(NumBones, Input, -_SunLightDir.xyz, Pos, Normal, Output.SkinnedLightVec);

	Output.ObjEyeVec = normalize(_ObjectEyePos.xyz - Pos);

	Output.ShadowTex = mul(float4(Pos, 1.0), _LightViewProj);
	Output.ShadowTex.z -= 0.007;

	Output.Pos.xy = Input.TexCoord0 * float2(2.0, -2.0) - float2(1.0, -1.0);
	Output.Pos.zw = float2(0.0, 1.0);
	Output.Tex0AndHZW /* .xy */ = Input.TexCoord0.xyyy;

	return Output;
}

float4 Skin_Pre_Shadow(VS2PS_Skin_Pre_Shadowed Input, bool IsNvidia)
{
	float4 ExpNormal = tex2D(Sampler_0, Input.Tex0AndHZW.xy);
	ExpNormal.rgb = (ExpNormal * 2.0) - 1.0;
	float WrapDiff = dot(ExpNormal.xyz, Input.SkinnedLightVec) + 0.5;
	WrapDiff = saturate(WrapDiff / 1.5);
	float RimDiff = 1.0 - dot(ExpNormal.xyz, Input.ObjEyeVec);
	RimDiff = pow(RimDiff, 3.0);
	RimDiff *= saturate(0.75 - saturate(dot(Input.ObjEyeVec, Input.SkinnedLightVec)));

	float2 Texel = float2(1.0 / 1024.0, 1.0 / 1024.0);
	// Input.ShadowTex.xy = clamp(Input.ShadowTex.xy, _ViewportMap.xy, _ViewportMap.zw);
	float AvgShadowValue = 0.0;

	if(IsNvidia)
	{
		AvgShadowValue = tex2Dproj(Sampler_2, Input.ShadowTex); // HW percentage closer filtering.
	}
	else
	{
		float4 samples;
		samples.x = tex2D(Sampler_2, Input.ShadowTex.xy);
		samples.y = tex2D(Sampler_2, Input.ShadowTex.xy + float2(Texel.x, 0));
		samples.z = tex2D(Sampler_2, Input.ShadowTex.xy + float2(0, Texel.y));
		samples.w = tex2D(Sampler_2, Input.ShadowTex.xy + Texel);
		float4 CMPBits = samples > saturate(Input.ShadowTex.z);
		AvgShadowValue = dot(CMPBits, 0.25);
	}

	float4 StaticSamples = SkinnedMesh_StaticSamples(Sampler_1, Input.ShadowTex.xy, Texel);
	StaticSamples.x = dot(StaticSamples.xyzw, 0.25);

	float TotalShadow = AvgShadowValue.x * StaticSamples.x;
	float TotalDiff = WrapDiff + RimDiff;
	return float4(TotalDiff, TotalShadow, saturate(TotalShadow + 0.35), ExpNormal.a);
}

float4 Skin_Pre_Shadowed_PS(VS2PS_Skin_Pre_Shadowed Input) : COLOR
{
	return Skin_Pre_Shadow(Input, false);
}

float4 Skin_Pre_Shadowed_NV_PS(VS2PS_Skin_Pre_Shadowed Input) : COLOR
{
	return Skin_Pre_Shadow(Input, true);
}




VS2PS_PP Skin_Apply_VS(APP2VS Input, uniform int NumBones)
{
	VS2PS_PP Output;

	float3 Pos, Normal;

	SkinSoldier_PP(NumBones, Input, -_SunLightDir.xyz, Pos, Normal, Output.SkinnedLightVec);

	// Transform position into view and then projection space
	Output.Pos = mul(float4(Pos.xyz, 1.0f), _WorldViewProj);

 	// Hemi lookup values
	float4 WPos = mul(Pos, _World);
	Output.GroundUVAndLerp = SkinnedMesh_Calc_HemiLookup(WPos, _HemiMapInfo, Normal);

	Output.Tex0 = Input.TexCoord0;
	Output.HalfVec = normalize(normalize(_ObjectEyePos.xyz - Pos) + Output.SkinnedLightVec);
	Output.SkinnedLightVec = normalize(Output.SkinnedLightVec);

	return Output;
}

float4 Skin_Apply_PS(VS2PS_PP Input) : COLOR
{
	float4 GroundColor = tex2D(Sampler_0, Input.GroundUVAndLerp.xy);
	float4 HemiColor = lerp(GroundColor, _SkyColor, Input.GroundUVAndLerp.z);
	float4 ExpNormal = tex2D(Sampler_1, Input.Tex0);
	ExpNormal.rgb = (ExpNormal * 2.0) - 1.0;
	float4 Diffuse = tex2D(Sampler_2, Input.Tex0);
	float4 DiffuseLight = tex2D(Sampler_3, Input.Tex0);

	// Glossmap is in the Diffuse alpha channel.
	float Specular = pow(dot(ExpNormal.rgb, Input.HalfVec), 16.0) * Diffuse.a;

	float4 TotalColor = saturate(_AmbientColor * HemiColor + DiffuseLight.r * DiffuseLight.b * _SunColor);
	TotalColor *= Diffuse; // + Specular;

	// What to do what the shadow???
	float ShadowIntensity = saturate(DiffuseLight.g /* + ShadowIntensityBias */);
	TotalColor.rgb += Specular * ShadowIntensity * ShadowIntensity;
	return TotalColor;
}
