
// Include guard for "SkinnedMesh_Shared.fx" main functions

#if !defined(SKINNEDMESH_SHARED_FX)
#define SKINNEDMESH_SHARED_FX

// object based lighting

void SkinSoldier_PP
(
	uniform int NumBones,
	in APP2VS Input,
	in float3 LightVec,
	out float3 Pos,
	out float3 Normal,
	out float3 SkinnedLightVec
)
{
	float LastWeight = 0.0;
	Pos = 0.0;
	Normal = 0.0;
	SkinnedLightVec = 0.0;

	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(Input.BlendIndices);

	// Cast the vectors to arrays for use in the for loop below
	float BlendWeightsArray[1] = (float[1])Input.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;

	// Calculate the pos/normal using the "normal" weights
	// and accumulate the weights to calculate the last weight
	for (int BoneIndex = 0; BoneIndex < NumBones-1; BoneIndex++)
	{
		LastWeight += BlendWeightsArray[BoneIndex];
		Pos += mul(Input.Pos, _BoneArray[IndexArray[BoneIndex]]) * BlendWeightsArray[BoneIndex];
		Normal += mul(Input.Normal, _BoneArray[IndexArray[BoneIndex]]) * BlendWeightsArray[BoneIndex];
		float3x3 Mat = transpose((float3x3)_BoneArray[IndexArray[BoneIndex]]);
		SkinnedLightVec += mul(LightVec, Mat) * BlendWeightsArray[BoneIndex];
	}

	LastWeight = 1.0 - LastWeight;

	// Now that we have the calculated weight, add in the final influence
	Pos += mul(Input.Pos, _BoneArray[IndexArray[NumBones-1]]) * LastWeight;
	Normal += mul(Input.Normal, _BoneArray[IndexArray[NumBones-1]]) * LastWeight;
	float3x3 Mat = transpose((float3x3)_BoneArray[IndexArray[NumBones-1]]);
	SkinnedLightVec += mul(LightVec, Mat) * LastWeight;

	// Normalize normals
	Normal = normalize(Normal);
	// SkinnedLightVec = normalize(SkinnedLightVec); // Don't normalize
}

void SkinSoldier_Point_PP
(
	uniform int NumBones,
	in APP2VS Input,
	in float3 LightVec,
	out float3 Pos,
	out float3 Normal,
	out float3 SkinnedLightVec
)
{
	float LastWeight = 0.0;
	Pos = 0.0;
	Normal = 0.0;
	SkinnedLightVec = 0.0;

	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(Input.BlendIndices);

	// Cast the vectors to arrays for use in the for loop below
	float BlendWeightsArray[1] = (float[1])Input.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;

	// Calculate the pos/normal using the "normal" weights
	// and accumulate the weights to calculate the last weight
	for (int BoneIndex = 0; BoneIndex < NumBones-1; BoneIndex++)
	{
		LastWeight += BlendWeightsArray[BoneIndex];

		float3 SkinPos = mul(Input.Pos, _BoneArray[IndexArray[BoneIndex]]);
		Pos += SkinPos * BlendWeightsArray[BoneIndex];

		Normal += mul(Input.Normal, _BoneArray[IndexArray[BoneIndex]]) * BlendWeightsArray[BoneIndex];
		float3x3 Mat = transpose((float3x3)_BoneArray[IndexArray[BoneIndex]]);
		float3 LocalLightVec = LightVec - SkinPos;
		SkinnedLightVec += mul(LocalLightVec, Mat) * BlendWeightsArray[BoneIndex];
	}

	LastWeight = 1.0 - LastWeight;

	// Now that we have the calculated weight, add in the final influence
	float3 SkinPos = mul(Input.Pos, _BoneArray[IndexArray[NumBones-1]]);
	Pos += SkinPos * LastWeight;
	Normal += mul(Input.Normal, _BoneArray[IndexArray[NumBones-1]]) * LastWeight;
	float3x3 Mat = transpose((float3x3)_BoneArray[IndexArray[NumBones-1]]);
	float3 LocalLightVec = LightVec - SkinPos;
	SkinnedLightVec += mul(LocalLightVec, Mat) * LastWeight;

	// Normalize normals
	Normal = normalize(Normal);
	// SkinnedLightVec = normalize(SkinnedLightVec); // Don't normalize
}

void SkinSoldier_Spot_PP
(
	uniform int NumBones,
	in APP2VS Input,
	in float3 LightVec,
	in float3 LightDir,
	out float3 Pos,
	out float3 Normal,
	out float3 SkinnedLightVec,
	out float3 SkinnedLightDir
)
{
	float LastWeight = 0.0;
	Pos = 0.0;
	Normal = 0.0;
	SkinnedLightVec = 0.0;
	SkinnedLightDir = 0.0;

	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(Input.BlendIndices);

	// Cast the vectors to arrays for use in the for loop below
	float BlendWeightsArray[1] = (float[1])Input.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;

	// Calculate the pos/normal using the "normal" weights
	// and accumulate the weights to calculate the last weight
	for (int BoneIndex = 0; BoneIndex < NumBones-1; BoneIndex++)
	{
		LastWeight += BlendWeightsArray[BoneIndex];

		float3 SkinPos = mul(Input.Pos, _BoneArray[IndexArray[BoneIndex]]);
		Pos += SkinPos * BlendWeightsArray[BoneIndex];

		Normal += mul(Input.Normal, _BoneArray[IndexArray[BoneIndex]]) * BlendWeightsArray[BoneIndex];
		float3x3 Mat = transpose((float3x3)_BoneArray[IndexArray[BoneIndex]]);
		float3 LocalLightVec = LightVec - SkinPos;
		SkinnedLightVec += mul(LocalLightVec, Mat) * BlendWeightsArray[BoneIndex];
		SkinnedLightDir += mul(LightDir, Mat) * BlendWeightsArray[BoneIndex];
	}

	LastWeight = 1.0f - LastWeight;

	// Now that we have the calculated weight, add in the final influence
	float3 SkinPos = mul(Input.Pos, _BoneArray[IndexArray[NumBones-1]]);
	Pos += SkinPos * LastWeight;
	Normal += mul(Input.Normal, _BoneArray[IndexArray[NumBones-1]]) * LastWeight;
	float3x3 Mat = transpose((float3x3)_BoneArray[IndexArray[NumBones-1]]);
	float3 LocalLightVec = LightVec - SkinPos;
	SkinnedLightVec += mul(LocalLightVec, Mat) * LastWeight;
	SkinnedLightDir += mul(LightDir, Mat) * LastWeight;

	// Normalize normals
	Normal = normalize(Normal);
	SkinnedLightVec = SkinnedLightVec;//normalize(SkinnedLightVec);
	SkinnedLightDir = normalize(SkinnedLightDir);
}




// Tangent-based lighting

void SkinSoldier_PP_Tangent
(
	uniform int NumBones,
	in APP2VStangent Input,
	in float3 LightVec,
	out float3 Pos,
	out float3 Normal,
	out float3 SkinnedLightVec,
	out float4 WPos,
	out float3 HalfVec
)
{
	float LastWeight = 0.0;
	Pos = 0.0;
	Normal = 0.0;
	SkinnedLightVec = 0.0;

	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(Input.BlendIndices);

	// Cast the vectors to arrays for use in the for loop below
	float BlendWeightsArray[1] = (float[1])Input.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;

	float3 BiNormal = normalize(cross(Input.Tan, Input.Normal));
	float3x3 TanBasis = float3x3(Input.Tan, BiNormal, Input.Normal);
	float3x3 WorldI;
	float3x3 Mat;

	// Calculate the pos/normal using the "normal" weights
	// and accumulate the weights to calculate the last weight
	for (int BoneIndex = 0; BoneIndex < NumBones-1; BoneIndex++)
	{
		LastWeight += BlendWeightsArray[BoneIndex];
		Pos += mul(Input.Pos, _BoneArray[IndexArray[BoneIndex]]) * BlendWeightsArray[BoneIndex];

		// Calculate WorldTangent directly... inverse is the transpose for affine rotations
		WorldI = mul(TanBasis, _BoneArray[IndexArray[BoneIndex]]);
		Normal += WorldI[2] * BlendWeightsArray[BoneIndex];
		Mat = transpose(WorldI);

		SkinnedLightVec += mul(LightVec, Mat) * BlendWeightsArray[BoneIndex];
	}

	LastWeight = 1.0 - LastWeight;

	// Now that we have the calculated weight, add in the final influence
	Pos += mul(Input.Pos, _BoneArray[IndexArray[NumBones-1]]) * LastWeight;

	// Calculate WorldTangent directly... inverse is the transpose for affine rotations
	WorldI = mul(TanBasis, _BoneArray[IndexArray[NumBones-1]]);
	Normal += WorldI[2]  * LastWeight;

	Mat = transpose(WorldI);
	SkinnedLightVec += mul(LightVec, Mat) * LastWeight;

	// Calculate HalfVector
	WPos = mul(float4(Pos.xyz, 1.0), _World);
	float3 TanEyeVec = mul(_WorldEyePos.xyz - WPos.xyz, Mat);
	HalfVec = normalize(normalize(TanEyeVec) + SkinnedLightVec);

	// Normalize normals
	Normal = normalize(Normal);
	//SkinnedLightVec = normalize(SkinnedLightVec); // Don't normalize
}

void SkinSoldier_Point_PP_Tangent
(
	uniform int NumBones,
	in APP2VStangent Input,
	in float3 LightVec,
	out float3 Pos,
	out float3 Normal,
	out float3 SkinnedLightVec,
	out float3 HalfVec
)
{
	float LastWeight = 0.0;
	Pos = 0.0;
	Normal = 0.0;
	SkinnedLightVec = 0.0;

	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(Input.BlendIndices);

	// Cast the vectors to arrays for use in the for loop below
	float BlendWeightsArray[1] = (float[1])Input.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;

	float3 BiNormal = normalize(cross(Input.Tan, Input.Normal));
	float3x3 TanBasis = float3x3(Input.Tan, BiNormal, Input.Normal);
	float3x3 WorldI;
	float3x3 Mat;

	// Calculate the pos/normal using the "normal" weights
	// and accumulate the weights to calculate the last weight
	for (int BoneIndex = 0; BoneIndex < NumBones-1; BoneIndex++)
	{
		LastWeight += BlendWeightsArray[BoneIndex];

		float3 SkinPos = mul(Input.Pos, _BoneArray[IndexArray[BoneIndex]]);
		Pos += SkinPos * BlendWeightsArray[BoneIndex];

		// Calculate WorldTangent directly... inverse is the transpose for affine rotations
		WorldI = mul(TanBasis, _BoneArray[IndexArray[BoneIndex]]);
		Normal += WorldI[2] * BlendWeightsArray[BoneIndex];
		Mat = transpose(WorldI);

		float3 LocalLightVec = LightVec - SkinPos;

		SkinnedLightVec += mul(LocalLightVec, Mat) * BlendWeightsArray[BoneIndex];
	}

	LastWeight = 1.0 - LastWeight;

	// Now that we have the calculated weight, add in the final influence
	float3 SkinPos = mul(Input.Pos, _BoneArray[IndexArray[NumBones-1]]);
	Pos += SkinPos * LastWeight;

	WorldI = mul(TanBasis, _BoneArray[IndexArray[NumBones-1]]);
	Normal += WorldI[2]  * LastWeight;
	Mat = transpose(WorldI);
	float3 LocalLightVec = LightVec - SkinPos;
	SkinnedLightVec += mul(LocalLightVec, Mat) * LastWeight;

	// Calculate HalfVector
	float4 WPos = mul(float4(Pos.xyz, 1.0), _World);
	float3 TanEyeVec = mul(_WorldEyePos.xyz - WPos.xyz, Mat);
	HalfVec = normalize(normalize(TanEyeVec) + SkinnedLightVec);

	// Normalize normals
	Normal = normalize(Normal);
	//SkinnedLightVec = normalize(SkinnedLightVec); // Don't normalize
}

void SkinSoldier_Spot_PP_Tangent
(
	uniform int NumBones,
	in APP2VStangent Input,
	in float3 LightVec,
	in float3 LightDir,
	out float3 Pos,
	out float3 Normal,
	out float3 SkinnedLightVec,
	out float3 SkinnedLightDir,
	out float3 HalfVec
)
{
	float LastWeight = 0.0;
	Pos = 0.0;
	Normal = 0.0;
	SkinnedLightVec = 0.0;
	SkinnedLightDir = 0.0;

	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(Input.BlendIndices);

	// Cast the vectors to arrays for use in the for loop below
	float BlendWeightsArray[1] = (float[1])Input.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;

	float3 BiNormal = normalize(cross(Input.Tan, Input.Normal));
	float3x3 TanBasis = float3x3(Input.Tan, BiNormal, Input.Normal);
	float3x3 WorldI;
	float3x3 Mat;

	// Calculate the pos/normal using the "normal" weights
	// and accumulate the weights to calculate the last weight
	for (int BoneIndex = 0; BoneIndex < NumBones-1; BoneIndex++)
	{
		LastWeight += BlendWeightsArray[BoneIndex];

		float3 SkinPos = mul(Input.Pos, _BoneArray[IndexArray[BoneIndex]]);
		Pos += SkinPos * BlendWeightsArray[BoneIndex];

		// Calculate WorldTangent directly... inverse is the transpose for affine rotations
		WorldI = mul(TanBasis, _BoneArray[IndexArray[BoneIndex]]);
		Normal += WorldI[2] * BlendWeightsArray[BoneIndex];
		Mat = transpose(WorldI);

		float3 LocalLightVec = LightVec - SkinPos;

		SkinnedLightVec += mul(LocalLightVec, Mat) * BlendWeightsArray[BoneIndex];
		SkinnedLightDir += mul(LightDir, Mat) * BlendWeightsArray[BoneIndex];
	}

	LastWeight = 1.0 - LastWeight;

	// Now that we have the calculated weight, add in the final influence
	float3 SkinPos = mul(Input.Pos, _BoneArray[IndexArray[NumBones-1]]);
	Pos += SkinPos * LastWeight;
	// Calculate WorldTangent directly... inverse is the transpose for affine rotations
	WorldI = mul(TanBasis, _BoneArray[IndexArray[NumBones-1]]);
	Normal += WorldI[2] * LastWeight;
	Mat = transpose(WorldI);

	float3 LocalLightVec = LightVec - SkinPos;
	SkinnedLightVec += mul(LocalLightVec, Mat) * LastWeight;
	SkinnedLightDir += mul(LightDir, Mat) * LastWeight;

	// Calculate HalfVector
	float4 WPos = mul(float4(Pos.xyz, 1.0), _World);
	float3 TanEyeVec = mul(_WorldEyePos.xyz - WPos.xyz, Mat);
	HalfVec = normalize(normalize(TanEyeVec) + SkinnedLightVec);

	// Normalize normals
	Normal = normalize(Normal);
	// SkinnedLightVec = SkinnedLightVec;//normalize(SkinnedLightVec);
	SkinnedLightDir = normalize(SkinnedLightDir);
}




void SkinSoldier_PV
(
	uniform int NumBones,
	in APP2VS Input,
	out float3 Pos,
	out float3 Normal
)
{
	float LastWeight = 0.0;
	Pos = 0.0;
	Normal = 0.0;

	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(Input.BlendIndices);

	// Cast the vectors to arrays for use in the for loop below
	float BlendWeightsArray[1] = (float[1])Input.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;

	// Calculate the pos/normal using the "normal" weights
	// and accumulate the weights to calculate the last weight
	for (int BoneIndex = 0; BoneIndex < NumBones-1; BoneIndex++)
	{
		LastWeight += BlendWeightsArray[BoneIndex];
		Pos += mul(Input.Pos, _BoneArray[IndexArray[BoneIndex]]) * BlendWeightsArray[BoneIndex];
		Normal += mul(Input.Normal, _BoneArray[IndexArray[BoneIndex]]) * BlendWeightsArray[BoneIndex];
	}

	LastWeight = 1.0 - LastWeight;

	// Now that we have the calculated weight, add in the final influence
	Pos += mul(Input.Pos, _BoneArray[IndexArray[NumBones-1]]) * LastWeight;
	Normal += mul(Input.Normal, _BoneArray[IndexArray[NumBones-1]]) * LastWeight;

	// Normalize normals
	Normal = normalize(Normal);
}

#endif




// Include guard for "SkinnedMesh_Shared.fx" other functions

#if !defined(SKINNEDMESH_SHARED_FUNC)
#define SKINNEDMESH_SHARED_FUNC

float3 SkinnedMesh_Calc_HemiLookup(float4 WPos, float4 HemiMapInfo, float3 Normal)
{
	float3 GroundUVAndLerp = 0.0;
	GroundUVAndLerp.xy = ((WPos.xyz + (HemiMapInfo.z * 0.5) + Normal).xz - HemiMapInfo.xy) / HemiMapInfo.z;
	GroundUVAndLerp.y = 1.0 - GroundUVAndLerp.y;
	GroundUVAndLerp.z = Normal.y * 0.5 + 0.5;
	GroundUVAndLerp.z -= HemiMapInfo.w;
	return GroundUVAndLerp;
}

float4 SkinnedMesh_Samples(sampler Source, float4 TexCoord, float2 Texel)
{
	float4 Samples;
	Samples.x = tex2Dproj(Source, TexCoord).x;
	Samples.y = tex2Dproj(Source, TexCoord + float4(Texel.x, 0.0, 0.0, 0.0)).x;
	Samples.z = tex2Dproj(Source, TexCoord + float4(0.0, Texel.y, 0.0, 0.0)).x;
	Samples.w = tex2Dproj(Source, TexCoord + float4(Texel.x, Texel.y, 0.0, 0.0)).x;
	return Samples;
}

float4 SkinnedMesh_StaticSamples(sampler Source, float2 TexCoord, float2 Texel)
{
	float4 StaticSamples;
	StaticSamples.x = tex2D(Source, TexCoord + float2(-Texel.x, -Texel.y * 2.0)).b;
	StaticSamples.y = tex2D(Source, TexCoord + float2( Texel.x, -Texel.y * 2.0)).b;
	StaticSamples.z = tex2D(Source, TexCoord + float2(-Texel.x,  Texel.y * 2.0)).b;
	StaticSamples.w = tex2D(Source, TexCoord + float2( Texel.x,  Texel.y * 2.0)).b;
	return StaticSamples;
}

#endif
