
#include "shaders/SkinnedMesh_Shared.fx"

#if !defined(SKINNEDMESH_SHARED_FX)
	#include "SkinnedMesh_Shared.fx"
#endif

float4 Calc_DiffSpec(float3 Normal, float3 Pos)
{
	float4 DiffAndSpec = 0.0;
	float Diff = dot(Normal, -_SunLightDir.xyz);
	float3 ObjectEyeVec = normalize(_ObjectEyePos.xyz - Pos.xyz);
	float3 HalfVec = (-_SunLightDir.xyz + ObjectEyeVec) * 0.5;
	float Spec = dot(Normal, HalfVec);
	float4 Light = lit(Diff, Spec, 32.0);
	DiffAndSpec.rgb = Light.y * _SunColor;
	DiffAndSpec.a = Light.z;
	return DiffAndSpec;
}

struct VS2PS_PV
{
	float4 Pos : POSITION;
	float2 Tex0 : TEXCOORD0;
	float3 GroundUVAndLerp : TEXCOORD1;
	float4 DiffAndSpec : COLOR0;
};

VS2PS_PV Hemi_Sun_PV_VS(APP2VS Input, uniform int NumBones)
{
	VS2PS_PV Output;
	float3 Pos, Normal;

	SkinSoldier_PV(NumBones, Input, Pos, Normal);

	// Transform position into view and then projection space
	Output.Pos = mul(float4(Pos.xyz, 1.0), _WorldViewProj);

 	// Hemi lookup values
	float4 WPos = mul(float4(Pos.xyz, 1.0), _World);
	Output.GroundUVAndLerp = SkinnedMesh_Calc_HemiLookup(WPos, _HemiMapInfo, Normal);
	Output.GroundUVAndLerp.z = saturate(Output.GroundUVAndLerp.z);

	Output.Tex0 = Input.TexCoord0;

	Output.DiffAndSpec = saturate(Calc_DiffSpec(Normal, Output.Pos.xyz));

	return Output;
}

float4 Hemi_Sun_PV_PS(VS2PS_PV Input) : COLOR
{
	float4 GroundColor = tex2D(Sampler_0, Input.GroundUVAndLerp.xy);
	float4 HemiColor = lerp(GroundColor, _SkyColor, Input.GroundUVAndLerp.z);
	float4 TotalColor = float4(Input.DiffAndSpec.rgb * GroundColor.a * GroundColor.a + _AmbientColor.rgb * HemiColor.rgb, Input.DiffAndSpec.a);
	return saturate(TotalColor);
}

float4 Hemi_Sun_Color_PV_PS(VS2PS_PV Input) : COLOR
{
	float4 GroundColor = tex2D(Sampler_0, Input.GroundUVAndLerp.xy);
	float4 HemiColor = lerp(GroundColor, _SkyColor, Input.GroundUVAndLerp.z);

	// Do something with Spec-alpha later on
	float4 TotalColor = saturate(float4(Input.DiffAndSpec.rgb * GroundColor.a * GroundColor.a + _AmbientColor.rgb * HemiColor.rgb, Input.DiffAndSpec.a));
	float4 Color = tex2D(Sampler_1, Input.Tex0);
	TotalColor.rgb *= Color.rgb;
	TotalColor.rgb += Input.DiffAndSpec.a;
	TotalColor.a = Color.a;
	return TotalColor;
}




struct VS2PS_PVCOLOR_SHADOW
{
	float4 Pos : POSITION;
	float2 Tex0 : TEXCOORD0;
	float3 GroundUVAndLerp : TEXCOORD1;
	float4 ShadowTex : TEXCOORD2;
	float4 DiffAndSpec : COLOR0;
};

VS2PS_PVCOLOR_SHADOW Hemi_Sun_Shadow_Color_PV_VS(APP2VS Input, uniform int NumBones)
{
	VS2PS_PVCOLOR_SHADOW Output = (VS2PS_PVCOLOR_SHADOW)0;
	float3 Pos, Normal;

	SkinSoldier_PV(NumBones, Input, Pos, Normal);

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

	Output.Tex0 = Input.TexCoord0;

	Output.DiffAndSpec = saturate(Calc_DiffSpec(Normal, Output.Pos.xyz));
	// Output.DiffAndSpec.rgb = dot(Normal, -_SunLightDir) * _SunColor;
	// Output.DiffAndSpec.a = dot(Normal, normalize(normalize(_ObjectEyePos - Pos) - _SunLightDir));

	return Output;
}




struct VS2PS_PointLight_PV
{
	float4 Pos : POSITION;
	float3 Diffuse : COLOR0;
	float2 Tex0 : TEXCOORD0;
};

VS2PS_PointLight_PV PointLight_PV_VS(APP2VS Input, uniform int NumBones)
{
	VS2PS_PointLight_PV Output;
	float3 Pos, Normal;

	SkinSoldier_PV(NumBones, Input, Pos, Normal);

	// Transform position into view and then projection space
	Output.Pos = mul(float4(Pos.xyz, 1.0), _WorldViewProj);

	// Lighting. Shade (Ambient + etc.)
	// float4 WPos = mul(float4(Pos.xyz, 1.0), _World);
	float3 LightVec = _LightPos.xyz - Pos.xyz;
	float3 NormalizedLightVec = normalize(LightVec);

	float RadialAtt = 1.0 - saturate(dot(LightVec, LightVec) * _AttenuationSqrInv);

	Output.Diffuse = dot(NormalizedLightVec, Normal);
	Output.Diffuse *= _LightColor * RadialAtt;
	Output.Diffuse = saturate(Output.Diffuse);

	Output.Tex0 = Input.TexCoord0;

	return Output;
}

float4 PointLight_PV_PS(VS2PS_PointLight_PV Input) : COLOR
{
	return float4(Input.Diffuse, 0.0);
}




struct VS2PS_SpotLight_PV
{
	float4 Pos : POSITION;
	float3 Diffuse : COLOR0;
	float2 Tex0 : TEXCOORD0;
};

VS2PS_SpotLight_PV SpotLight_PV_VS(APP2VS Input, uniform int NumBones)
{
	VS2PS_SpotLight_PV Output;
	float3 Pos, Normal;

	SkinSoldier_PV(NumBones, Input, Pos, Normal);

	// Transform position into view and then projection space
	Output.Pos = mul(float4(Pos.xyz, 1.0f), _WorldViewProj);

	float3 LightVec = _LightPos.xyz - Pos.xyz;
	float3 NormalizedLightVec = normalize(LightVec);

	float RadialAtt = 1.0 - saturate(dot(LightVec,LightVec) * _AttenuationSqrInv);
	float OffCenter = dot(NormalizedLightVec, _LightDir.xyz);
	float ConicalAtt = saturate(OffCenter - (1.0 - _ConeAngle)) / _ConeAngle;

	Output.Diffuse = dot(NormalizedLightVec,Normal) * _LightColor;
	Output.Diffuse *= ConicalAtt * RadialAtt;
	Output.Diffuse = saturate(Output.Diffuse);

	Output.Tex0 = Input.TexCoord0;

	return Output;
}

float4 SpotLight_PV_PS(VS2PS_SpotLight_PV Input) : COLOR
{
	return float4(Input.Diffuse, 0.0);
}




struct VS2PS_MulDiffuse
{
	float4 Pos : POSITION;
	float2 Tex0 : TEXCOORD0;
};

VS2PS_MulDiffuse MulDiffuse_VS(APP2VS Input, uniform int NumBones)
{
	VS2PS_MulDiffuse Output;
	float3 Pos, Normal;
	SkinSoldier_PV(NumBones, Input, Pos, Normal);

	// Transform position into view and then projection space
	Output.Pos = mul(float4(Pos.xyz, 1.0f), _WorldViewProj);
	Output.Tex0 = Input.TexCoord0;
	return Output;
}

float4 MulDiffuse_PS(VS2PS_MulDiffuse Input) : COLOR
{
	return tex2D(Sampler_0, Input.Tex0);
}
