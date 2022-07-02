
#include "shaders/SkinnedMesh_Shared.fx"

#if !defined(SKINNEDMESH_SHARED_FX)
	#include "SkinnedMesh_Shared.fx"
#endif

float4 CalcPos(APP2VS Input, bool IsAlpha)
{
	float4 OutputPos = 0.0;

	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(Input.BlendIndices);

	// Cast the vectors to arrays for use in the for loop below
	float BlendWeightsArray[1] = (float[1])Input.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;

	float3 LocalPos = mul(Input.Pos, _BoneArray[IndexArray[0]]) * BlendWeightsArray[0];
	LocalPos += mul(Input.Pos, _BoneArray[IndexArray[1]]) * (1.0 - BlendWeightsArray[0]);

 	OutputPos = mul(float4(LocalPos.xyz, 1.0), _LightTrapezMat);
 	float2 LightZW = mul(float4(LocalPos.xyz, 1.0), _LightMat).zw;
	OutputPos.z = (LightZW.x * OutputPos.w) / LightZW.y; // (zL*wT)/wL == zL/wL post homo

	OutputPos = (IsAlpha) ? OutputPos : mul(float4(LocalPos.xyz, 1.0), _LightMat);
	return OutputPos;
}

struct VS2PS_ShadowMap
{
	float4 Pos : POSITION;
	float2 PosZW : TEXCOORD0;
};

VS2PS_ShadowMap ShadowMap_VS(APP2VS Input)
{
	VS2PS_ShadowMap Output;
	Output.Pos = CalcPos(Input, false);
 	Output.PosZW = Output.Pos.zw;
	return Output;
}

float4 ShadowMap_PS(VS2PS_ShadowMap Input) : COLOR
{
	#if NVIDIA
		return 0;
	#else
		return Input.PosZW.x / Input.PosZW.y;
	#endif
}


struct VS2PS_ShadowMap_Alpha
{
	float4 Pos : POSITION;
	float4 Tex0PosZW : TEXCOORD0;
};

VS2PS_ShadowMap_Alpha ShadowMap_Alpha_VS(APP2VS Input)
{
	VS2PS_ShadowMap_Alpha Output;
	Output.Pos = CalcPos(Input, true);
 	Output.Tex0PosZW.xy = Input.TexCoord0;
 	Output.Tex0PosZW.zw = Output.Pos.zw;
	return Output;
}

float4 ShadowMap_Alpha_PS(VS2PS_ShadowMap_Alpha Input) : COLOR
{
	float Alpha = tex2D(Sampler_0, Input.Tex0PosZW.xy).a - _ShadowAlphaThreshold;

	#if NVIDIA
		return Alpha;
	#else
		clip(Alpha);
		return Input.Tex0PosZW.z / Input.Tex0PosZW.w;
	#endif
}
