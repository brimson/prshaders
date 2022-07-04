
#include "shaders/SkinnedMesh_Shared.fx"

#if !defined(SKINNEDMESH_SHARED_FX)
	#include "SkinnedMesh_Shared.fx"
#endif

struct APP2VS_fullMRT
{
	float4 Pos : POSITION;
	float3 Normal : NORMAL;
	float BlendWeights : BLENDWEIGHT;
	float4 BlendIndices : BLENDINDICES;
	float2 TexCoord0 : TEXCOORD0;
};

struct VS2PS_Z_Diffuse
{
	float4 Pos : POSITION;
	float2 Tex0 : TEXCOORD0;
};

struct VS2PS_Full_MRT
{
	float4 Pos : POSITION;
	float2 Tex0 : TEXCOORD0;
	float4 wPos : TEXCOORD1;
	float4 Mat1 : TEXCOORD2;
	float3 Mat2 : TEXCOORD3;
	float3 Mat3 : TEXCOORD4;
	float4 Mat1_ : TEXCOORD5;
	float3 Mat2_ : TEXCOORD6;
	float3 Mat3_ : TEXCOORD7;
	float3 GroundUVAndLerp : COLOR0;
};

struct PS2FB_Full_MRT
{
    float4 Col0 : COLOR0;
    float4 Col1 : COLOR1;
    float4 Col2 : COLOR2;
};




VS2PS_Z_Diffuse Z_Diffuse_VS(APP2VS_fullMRT Input, uniform int NumBones)
{
	VS2PS_Z_Diffuse Output;

	float LastWeight = 0.0;
	float3 Pos = 0.0;

	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(Input.BlendIndices);

	// Cast the vectors to arrays for use in the for loop below
	float BlendWeightsArray[1] = (float[1])Input.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;

	// Calculate the pos/Normal using the "Normal" weights
	// and accumulate the weights to calculate the last weight
	for (int iBone = 0; iBone < NumBones-1; iBone++)
	{
		LastWeight += BlendWeightsArray[iBone];
		Pos += mul(Input.Pos, _BoneArray[IndexArray[iBone]]) * BlendWeightsArray[iBone];
	}
	LastWeight = 1.0 - LastWeight;

	// Now that we have the calculated weight, add in the final influence
	Pos += mul(Input.Pos, _BoneArray[IndexArray[NumBones-1]]) * LastWeight;

	float4 pos4 = float4(Pos.xyz, 1.0);

	// Transform position into view and then projection space
	Output.Pos = mul(pos4, _WorldViewProj);

	Output.Tex0 = Input.TexCoord0;

	return Output;
}

float4 Z_Diffuse_PS(VS2PS_Z_Diffuse  Input) : COLOR
{
	return tex2D(Sampler_0, Input.Tex0);
}

VS2PS_Full_MRT Full_MRT_VS(APP2VS_fullMRT Input, uniform int NumBones)
{
	VS2PS_Full_MRT Output;

	float LastWeight = 0.0;
	float3 Pos = 0.0;
	float3 Normal = 0.0;
	float3 SkinnedLightVec = 0.0;

	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(Input.BlendIndices);

	// Cast the vectors to arrays for use in the for loop below
	float BlendWeightsArray[1] = (float[1])Input.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;

	// Calculate the pos/Normal using the "Normal" weights
	// and accumulate the weights to calculate the last weight
	for (int iBone = 0; iBone < NumBones-1; iBone++)
	{
		LastWeight += BlendWeightsArray[iBone];
		Pos += mul(Input.Pos, _BoneArray[IndexArray[iBone]]) * BlendWeightsArray[iBone];
		Normal += mul(Input.Normal, _BoneArray[IndexArray[iBone]]) * BlendWeightsArray[iBone];
	}
	LastWeight = 1.0 - LastWeight;

	// Now that we have the calculated weight, add in the final influence
	Pos += mul(Input.Pos, _BoneArray[IndexArray[NumBones-1]]) * LastWeight;
	Normal += mul(Input.Normal, _BoneArray[IndexArray[NumBones-1]]) * LastWeight;

	// Normalize normals
	Normal = normalize(Normal);

	float4 pos4 = float4(Pos.xyz, 1.0);

	float3x3 Bone1 = transpose((float3x3)_BoneArray[IndexArray[0]]);
	float3x3 Bone2 = transpose((float3x3)_BoneArray[IndexArray[1]]);
	Output.Mat1.xyz = Bone1[0];
	Output.Mat1.w = BlendWeightsArray[0];
	Output.Mat2 = Bone1[1];
	Output.Mat3 = Bone1[2];
	Output.Mat1_.xyz = Bone2[0];
	Output.Mat1_.w = 1.0 - BlendWeightsArray[0];
	Output.Mat2_ = Bone2[1];
	Output.Mat3_ = Bone2[2];

	// Transform position into view and then projection space
	Output.Pos = mul(pos4, _WorldViewProj);

 	// Hemi lookup values
	float4 wPos = mul(pos4, _World);
	Output.GroundUVAndLerp = saturate(SkinnedMesh_Calc_HemiLookup(wPos, _HemiMapInfo, Normal));

	Output.wPos = mul(pos4, _WorldView);

	Output.Tex0 = Input.TexCoord0;

	return Output;
}

PS2FB_Full_MRT Full_MRT_PS(VS2PS_Full_MRT Input)
{
	PS2FB_Full_MRT Output;

	float4 GroundColor = tex2D(Sampler_0, Input.GroundUVAndLerp.xy);
	float4 HemiColor = lerp(GroundColor, _SkyColor, Input.GroundUVAndLerp.z);
	float4 ExpNormal = tex2D(Sampler_1, Input.Tex0);
	ExpNormal.rgb = (ExpNormal * 2.0) - 1.0;

	Output.Col0 = _AmbientColor * HemiColor;
	Output.Col1 = Input.wPos;

	float3 Normal;
	Normal.x = dot(ExpNormal.xyz, Input.Mat1.xyz) * Input.Mat1.w;
	Normal.y = dot(ExpNormal.xyz, Input.Mat2.xyz) * Input.Mat1.w;
	Normal.z = dot(ExpNormal.xyz, Input.Mat3.xyz) * Input.Mat1.w;
	Normal.x += dot(ExpNormal.xyz, Input.Mat1_.xyz) * Input.Mat1_.w;
	Normal.y += dot(ExpNormal.xyz, Input.Mat2_.xyz) * Input.Mat1_.w;
	Normal.z += dot(ExpNormal.xyz, Input.Mat3_.xyz) * Input.Mat1_.w;
	Output.Col2.x = dot(Normal, _WorldViewI[0].xyz);
	Output.Col2.y = dot(Normal, _WorldViewI[1].xyz);
	Output.Col2.z = dot(Normal, _WorldViewI[2].xyz);
	Output.Col2.w = ExpNormal.a;

	return Output;
}

// Max 2 bones skinning supported!
VertexShader Array_Full_MRT_VS[2] =
{
	compile vs_3_0 Full_MRT_VS(1),
	compile vs_3_0 Full_MRT_VS(2)
};

technique fullMRT
{
	pass zdiffuse
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;

		StencilEnable = TRUE;
		StencilRef = (_StencilRef);
		StencilFunc = ALWAYS;
		StencilZFail = KEEP;
		StencilPass = REPLACE;

		VertexShader = compile vs_3_0 Z_Diffuse_VS(2);
		PixelShader = compile ps_3_0 Z_Diffuse_PS();
	}

	pass mrt
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = EQUAL;

		StencilEnable = FALSE;

		VertexShader = (Array_Full_MRT_VS[1]);
		PixelShader = compile ps_3_0 Full_MRT_PS();
	}
}




// PP tangent based lighting

struct APP2VS_Full_MRT_Tangent
{
	float4 Pos : POSITION;
	float3 Normal : NORMAL;
	float BlendWeights : BLENDWEIGHT;
	float4 BlendIndices : BLENDINDICES;
	float2 TexCoord0 : TEXCOORD0;
    float3 Tan : TANGENT;
};

VS2PS_Full_MRT Full_MRT_Tangent_VS(APP2VS_Full_MRT_Tangent Input, uniform int NumBones)
{
	VS2PS_Full_MRT Output;

	float LastWeight = 0.0;
	float3 Pos = 0.0;
	float3 Normal = 0.0;
	float3 SkinnedLightVec = 0.0;

	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(Input.BlendIndices);

	// Cast the vectors to arrays for use in the for loop below
	float BlendWeightsArray[1] = (float[1])Input.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;

	float3 binormal = normalize(cross(Input.Tan, Input.Normal));
	float3x3 TanBasis = float3x3(Input.Tan, binormal, Input.Normal);
	float3x3 worldI;
	float3x3 mat;

	// Calculate the pos/Normal using the "Normal" weights
	// and accumulate the weights to calculate the last weight
	for (int iBone = 0; iBone < NumBones-1; iBone++)
	{
		LastWeight += BlendWeightsArray[iBone];
		Pos += mul(Input.Pos, _BoneArray[IndexArray[iBone]]) * BlendWeightsArray[iBone];
		Normal += mul(Input.Normal, _BoneArray[IndexArray[iBone]]) * BlendWeightsArray[iBone];
	}
	LastWeight = 1.0 - LastWeight;

	// Now that we have the calculated weight, add in the final influence
	Pos += mul(Input.Pos, _BoneArray[IndexArray[NumBones-1]]) * LastWeight;
	Normal += mul(Input.Normal, _BoneArray[IndexArray[NumBones-1]]) * LastWeight;

	// Normalize normals
	Normal = normalize(Normal);

	float4 pos4 = float4(Pos.xyz, 1.0);

	// Calculate WorldTangent directly... inverse is the transpose for affine rotations
	float3x3 Bone1 = transpose(mul(TanBasis, _BoneArray[IndexArray[0]]));
	float3x3 Bone2 = transpose(mul(TanBasis, _BoneArray[IndexArray[1]]));
	Output.Mat1.xyz = Bone1[0];
	Output.Mat1.w = BlendWeightsArray[0];
	Output.Mat2 = Bone1[1];
	Output.Mat3 = Bone1[2];
	Output.Mat1_.xyz = Bone2[0];
	Output.Mat1_.w = 1.0 - BlendWeightsArray[0];
	Output.Mat2_ = Bone2[1];
	Output.Mat3_ = Bone2[2];

	// Transform position into view and then projection space
	Output.Pos = mul(pos4, _WorldViewProj);

 	// Hemi lookup values
	float4 wPos = mul(pos4, _World);
	Output.GroundUVAndLerp = saturate(SkinnedMesh_Calc_HemiLookup(wPos, _HemiMapInfo, Normal));

	Output.wPos = mul(pos4, _WorldView);

	Output.Tex0 = Input.TexCoord0;

	return Output;
}

// Max 2 bones skinning supported!
VertexShader Array_Full_MRT_Tangent_VS[2] =
{
	compile vs_3_0 Full_MRT_Tangent_VS(1),
	compile vs_3_0 Full_MRT_Tangent_VS(2)
};

technique fullMRTtangent
{
	pass zdiffuse
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;

		StencilEnable = TRUE;
		StencilRef = (_StencilRef);
		StencilFunc = ALWAYS;
		StencilZFail = KEEP;
		StencilPass = REPLACE;

		VertexShader = compile vs_3_0 Z_Diffuse_VS(2);
		PixelShader = compile ps_3_0 Z_Diffuse_PS();
	}
	pass mrt
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = EQUAL;

		StencilEnable = FALSE;

		VertexShader = (Array_Full_MRT_Tangent_VS[1]);
		PixelShader = compile ps_3_0 Full_MRT_PS();
	}
}




struct VS2PS_fullMRTskinpre
{
	float4 Pos : POSITION;
	float2 Tex0 : TEXCOORD0;
	float4 Mat1 : TEXCOORD1;
	float3 Mat2 : TEXCOORD2;
	float3 Mat3 : TEXCOORD3;
	float4 Mat1_ : TEXCOORD4;
	float3 Mat2_ : TEXCOORD5;
	float3 Mat3_ : TEXCOORD6;
	float3 ObjEyeVec : TEXCOORD7;
};

VS2PS_fullMRTskinpre Full_MRT_Skin_Pre_VS(APP2VS_fullMRT Input, uniform int NumBones)
{
	VS2PS_fullMRTskinpre Output;

	int4 IndexVector = D3DCOLORtoUBYTE4(Input.BlendIndices);
	float BlendWeightsArray[1] = (float[1])Input.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;

	float3 Pos = mul(Input.Pos, _BoneArray[IndexArray[0]]) * BlendWeightsArray[0];
	Pos += mul(Input.Pos, _BoneArray[IndexArray[1]]) * (1-BlendWeightsArray[0]);
	Output.ObjEyeVec = normalize(_ObjectEyePos - Pos);

	float3x3 Bone1 = transpose((float3x3)_BoneArray[IndexArray[0]]);
	float3x3 Bone2 = transpose((float3x3)_BoneArray[IndexArray[1]]);
	Output.Mat1.xyz = Bone1[0];
	Output.Mat1.w = BlendWeightsArray[0];
	Output.Mat2 = Bone1[1];
	Output.Mat3 = Bone1[2];
	Output.Mat1_.xyz = Bone2[0];
	Output.Mat1_.w = 1.0 - BlendWeightsArray[0];
	Output.Mat2_ = Bone2[1];
	Output.Mat3_ = Bone2[2];

	Output.Pos.xy = Input.TexCoord0 * float2(2.0, -2.0) - float2(1.0, -1.0);
	Output.Pos.zw = float2(0.0, 1.0);
	Output.Tex0 = Input.TexCoord0;

	return Output;
}

float4 Full_MRT_Skin_Pre_PS(VS2PS_fullMRTskinpre Input) : COLOR
{
	float4 ExpNormal = tex2D(Sampler_0, Input.Tex0);
	ExpNormal.rgb = (ExpNormal * 2.0) - 1.0;

	float3 Normal;
	Normal.x = dot(ExpNormal.xyz, Input.Mat1.xyz) * Input.Mat1.w;
	Normal.y = dot(ExpNormal.xyz, Input.Mat2.xyz) * Input.Mat1.w;
	Normal.z = dot(ExpNormal.xyz, Input.Mat3.xyz) * Input.Mat1.w;
	Normal.x += dot(ExpNormal.xyz, Input.Mat1_.xyz) * Input.Mat1_.w;
	Normal.y += dot(ExpNormal.xyz, Input.Mat2_.xyz) * Input.Mat1_.w;
	Normal.z += dot(ExpNormal.xyz, Input.Mat3_.xyz) * Input.Mat1_.w;

	float WrapDiff = dot(Normal, -_SunLightDir) + 0.5;
	WrapDiff = saturate(WrapDiff / 1.5);

	float RimDiff = 1.0 - dot(Normal, Input.ObjEyeVec);
	RimDiff = pow(RimDiff, 3.0);
	RimDiff *= saturate(0.75 - saturate(dot(Input.ObjEyeVec, -_SunLightDir)));

	return float4(WrapDiff.rrr + RimDiff, ExpNormal.a);
}

struct VS2PS_fullMRTskinpreshadowed
{
	float4 Pos : POSITION;
	float4 Tex0AndHZW : TEXCOORD0;
	float4 Mat1 : TEXCOORD1;
	float3 Mat2 : TEXCOORD2;
	float3 Mat3 : TEXCOORD3;
	float4 Mat1_ : TEXCOORD4;
	float3 Mat2_ : TEXCOORD5;
	float3 Mat3_ : TEXCOORD6;
	float4 ShadowTex : TEXCOORD7;
	float3 ObjEyeVec : COLOR0;
};

VS2PS_fullMRTskinpreshadowed Full_MRT_Skin_Pre_Shadowed_VS(APP2VS_fullMRT Input, uniform int NumBones)
{
	VS2PS_fullMRTskinpreshadowed Output;

	int4 IndexVector = D3DCOLORtoUBYTE4(Input.BlendIndices);
	float BlendWeightsArray[1] = (float[1])Input.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;

	float3 Pos = mul(Input.Pos, _BoneArray[IndexArray[0]]) * BlendWeightsArray[0];
	Pos += mul(Input.Pos, _BoneArray[IndexArray[1]]) * (1-BlendWeightsArray[0]);
	Output.ObjEyeVec = saturate(normalize(_ObjectEyePos - Pos));

	Output.ShadowTex = mul(float4(Pos, 1), _LightViewProj);
	Output.ShadowTex.xy = clamp(Output.ShadowTex.xy, _ViewportMap.xy, _ViewportMap.zw);
	Output.ShadowTex.z -= 0.007;
	Output.ShadowTex.xy = clamp(Output.ShadowTex.xy, _ViewportMap.xy, _ViewportMap.zw);

	float3x3 Bone1 = transpose((float3x3)_BoneArray[IndexArray[0]]);
	float3x3 Bone2 = transpose((float3x3)_BoneArray[IndexArray[1]]);
	Output.Mat1.xyz = Bone1[0];
	Output.Mat1.w = BlendWeightsArray[0];
	Output.Mat2 = Bone1[1];
	Output.Mat3 = Bone1[2];
	Output.Mat1_.xyz = Bone2[0];
	Output.Mat1_.w = 1.0 - BlendWeightsArray[0];
	Output.Mat2_ = Bone2[1];
	Output.Mat3_ = Bone2[2];

	Output.Pos.xy = Input.TexCoord0 * float2(2.0, -2.0) - float2(1.0, -1.0);
	Output.Pos.zw = float2(0.0, 1.0);
	Output.Tex0AndHZW /* .xy */ = Input.TexCoord0.xyyy;

	return Output;
}

float4 FullMRTskinpreshadowed(VS2PS_fullMRTskinpreshadowed Input, bool IsNvidia)
{
	float4 ExpNormal = tex2D(Sampler_0, Input.Tex0AndHZW);
	ExpNormal.rgb = (ExpNormal * 2.0) - 1.0;

	float3 Normal;
	Normal.x = dot(ExpNormal.xyz, Input.Mat1.xyz) * Input.Mat1.w;
	Normal.y = dot(ExpNormal.xyz, Input.Mat2.xyz) * Input.Mat1.w;
	Normal.z = dot(ExpNormal.xyz, Input.Mat3.xyz) * Input.Mat1.w;
	Normal.x += dot(ExpNormal.xyz, Input.Mat1_.xyz) * Input.Mat1_.w;
	Normal.y += dot(ExpNormal.xyz, Input.Mat2_.xyz) * Input.Mat1_.w;
	Normal.z += dot(ExpNormal.xyz, Input.Mat3_.xyz) * Input.Mat1_.w;

	float WrapDiff = dot(Normal, -_SunLightDir) + 0.5;
	WrapDiff = saturate(WrapDiff / 1.5);

	float RimDiff = 1-dot(Normal, Input.ObjEyeVec);
	RimDiff = pow(RimDiff, 3);
	RimDiff *= saturate(0.75 - saturate(dot(Input.ObjEyeVec, -_SunLightDir)));

	float2 Texel = float2(1.0 / 1024.0, 1.0 / 1024.0);
	float AvgShadowValue = 0.0;

	if(IsNvidia)
	{
		AvgShadowValue = tex2Dproj(Sampler_2, Input.ShadowTex); // HW percentage closer filtering.
	}
	else
	{
		float4 Samples;
		Samples.x = tex2D(Sampler_2, Input.ShadowTex);
		Samples.y = tex2D(Sampler_2, Input.ShadowTex.xy + float2(Texel.x, 0));
		Samples.z = tex2D(Sampler_2, Input.ShadowTex.xy + float2(0, Texel.y));
		Samples.w = tex2D(Sampler_2, Input.ShadowTex.xy + Texel);
		float4 CMPBits = Samples > saturate(Input.ShadowTex.z);
		AvgShadowValue = dot(CMPBits, 0.25);
	}

	float4 StaticSamples = SkinnedMesh_StaticSamples(Sampler_1, Input.ShadowTex.xy, Texel);
	StaticSamples.x = dot(StaticSamples.xyzw, 0.25);

	float TotalShadow = AvgShadowValue.x * StaticSamples.x;
	float TotalDiff = WrapDiff + RimDiff;
	return float4(TotalDiff, TotalShadow, saturate(TotalShadow + 0.35), ExpNormal.a);
}

float4 Full_MRT_Skin_Pre_Shadowed_PS(VS2PS_fullMRTskinpreshadowed Input) : COLOR
{
	return FullMRTskinpreshadowed(Input, false);
}

float4 Full_MRT_Skin_Pre_Shadowed_NV_PS(VS2PS_fullMRTskinpreshadowed Input) : COLOR
{
	return FullMRTskinpreshadowed(Input, true);
}

PS2FB_Full_MRT Full_MRT_Skin_Apply_PS(VS2PS_Full_MRT Input)
{
	PS2FB_Full_MRT Output;

	float4 GroundColor = tex2D(Sampler_0, Input.GroundUVAndLerp.xy);
	float4 HemiColor = lerp(GroundColor, _SkyColor, Input.GroundUVAndLerp.z);
	float4 ExpNormal = tex2D(Sampler_1, Input.Tex0);
	ExpNormal.rgb = (ExpNormal * 2.0) - 1.0;
	float4 Diffuse = tex2D(Sampler_2, Input.Tex0);
	float4 DiffuseLight = tex2D(Sampler_3, Input.Tex0);

	float3 Normal;
	Normal.x = dot(ExpNormal.xyz, Input.Mat1.xyz) * Input.Mat1.w;
	Normal.y = dot(ExpNormal.xyz, Input.Mat2.xyz) * Input.Mat1.w;
	Normal.z = dot(ExpNormal.xyz, Input.Mat3.xyz) * Input.Mat1.w;
	Normal.x += dot(ExpNormal.xyz, Input.Mat1_.xyz) * Input.Mat1_.w;
	Normal.y += dot(ExpNormal.xyz, Input.Mat2_.xyz) * Input.Mat1_.w;
	Normal.z += dot(ExpNormal.xyz, Input.Mat3_.xyz) * Input.Mat1_.w;

	Output.Col0.rgb = _AmbientColor * HemiColor + DiffuseLight.r * DiffuseLight.b * _SunColor;
	Output.Col0.a = DiffuseLight.g;

	Output.Col1 = Input.wPos;
	Output.Col2.x = dot(Normal, _WorldViewI[0].xyz);
	Output.Col2.y = dot(Normal, _WorldViewI[1].xyz);
	Output.Col2.z = dot(Normal, _WorldViewI[2].xyz);
	Output.Col2.w = Diffuse.w;

	return Output;
}

technique fullMRThumanskinNV
{
	pass pre
	{
		CullMode = NONE;
		AlphaBlendEnable = FALSE;
		ZEnable = FALSE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;

		StencilEnable = FALSE;

		VertexShader = compile vs_3_0 Full_MRT_Skin_Pre_VS(2);
		PixelShader = compile ps_3_0 Full_MRT_Skin_Pre_PS();
	}

	pass preshadowed
	{
		CullMode = NONE;
		AlphaBlendEnable = FALSE;
		ZEnable = FALSE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;

		StencilEnable = FALSE;

		VertexShader = compile vs_3_0 Full_MRT_Skin_Pre_Shadowed_VS(2);
		PixelShader = compile ps_3_0 Full_MRT_Skin_Pre_Shadowed_NV_PS();
	}

	pass apply
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;

		StencilEnable = TRUE;
		StencilRef = (_StencilRef);
		StencilFunc = ALWAYS;
		StencilZFail = KEEP;
		StencilPass = REPLACE;

		VertexShader = compile vs_3_0 Full_MRT_VS(2);
		PixelShader = compile ps_3_0 Full_MRT_Skin_Apply_PS();
	}
}

technique fullMRThumanskin
{
	pass pre
	{
		CullMode = NONE;
		AlphaBlendEnable = FALSE;
		ZEnable = FALSE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;

		StencilEnable = FALSE;

		VertexShader = compile vs_3_0 Full_MRT_Skin_Pre_VS(2);
		PixelShader = compile ps_3_0 Full_MRT_Skin_Pre_PS();
	}

	pass preshadowed
	{
		CullMode = NONE;
		AlphaBlendEnable = FALSE;
		ZEnable = FALSE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;

		StencilEnable = FALSE;

		VertexShader = compile vs_3_0 Full_MRT_Skin_Pre_Shadowed_VS(2);
		PixelShader = compile ps_3_0 Full_MRT_Skin_Pre_Shadowed_PS();
	}

	pass apply
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;

		StencilEnable = TRUE;
		StencilRef = (_StencilRef);
		StencilFunc = ALWAYS;
		StencilZFail = KEEP;
		StencilPass = REPLACE;

		VertexShader = compile vs_3_0 Full_MRT_VS(2);
		PixelShader = compile ps_3_0 Full_MRT_Skin_Apply_PS();
	}
}
