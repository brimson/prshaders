#line 2 "MeshParticleMesh.fx"
#include "shaders/FXCommon.fx"

// UNIFORM INPUTS
float4x4 _ViewProjMatrix : WorldViewProjection;
float4 _GlobalScale : GlobalScale;

struct APP2VS
{
   	float4 Pos : POSITION;
   	float3 Normal : NORMAL;
   	float4 BlendIndices : BLENDINDICES;
   	float2 TexCoord : TEXCOORD0;
   	float3 Tan : TANGENT;
   	float3 Binorm : BINORMAL;
};

// Once per system instance
// TemplateParameters
float4 m_color1AndLightFactor : COLOR1;
float4 m_color2 : COLOR2;
float4 m_colorBlendGraph : COLORBLENDGRAPH;
float4 m_transparencyGraph : TRANSPARENCYGRAPH;

float4 _AgeAndAlphaArray[26] : AgeAndAlphaArray;
float _LightmapIntensityOffset : LightmapIntensityOffset;
float4x3 _MatOneBoneSkinning[26]: matONEBONESKINNING; /* : register(c50) < bool sparseArray = true; int arrayStart = 50; >; */

struct VS2PS_Diffuse
{
	float4 HPos : POSITION;
	float2 DiffuseMap : TEXCOORD0;
	float2 GroundUV : TEXCOORD1;
	float3 LerpAndLMapIntOffset: TEXCOORD2;
	float4 Color : COLOR0;
	float4 LightFactor : COLOR1;
	float Fog : FOG;
};

VS2PS_Diffuse Diffuse_VS(APP2VS Input, uniform float4x4 ViewProj)
{
	VS2PS_Diffuse Output = (VS2PS_Diffuse)0;

   	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(Input.BlendIndices);
	int IndexArray[4] = (int[4])IndexVector;

	float3 Pos = mul(Input.Pos * _GlobalScale, _MatOneBoneSkinning[IndexArray[0]]);
 	Output.HPos = mul(float4(Pos.xyz, 1.0f), ViewProj);

	// Compute Cubic polynomial factors.
	float Age = _AgeAndAlphaArray[IndexArray[0]][0];
	float4 PC = float4(pow(Age, float3(3.0, 2.0, 1.0)), 1.0);

	float ColorBlendFactor = min(dot(m_colorBlendGraph, PC), 1.0);
	float3 Color = ColorBlendFactor * m_color2.rgb;
	Color += (1.0 - ColorBlendFactor) * m_color1AndLightFactor.rgb;

	Output.LightFactor = m_color1AndLightFactor.a;
 	Output.Color.rgb = Color;
 	Output.Color.a = _AgeAndAlphaArray[IndexArray[0]][1];

	// Pass-through texcoords
	Output.DiffuseMap = Input.TexCoord;

	// hemi lookup coords
 	Output.GroundUV.xy = ((Pos.xyz + (_HemiMapInfo.z / 2.0)).xz - _HemiMapInfo.xy)/ _HemiMapInfo.z;
 	Output.LerpAndLMapIntOffset = saturate(saturate((Pos.y - _HemiShadowAltitude) / 10.0f) + _LightmapIntensityOffset);

	Output.Fog = Calc_Fog(Output.HPos.w);

	return Output;
}

float4 Diffuse_PS(VS2PS_Diffuse Input) : COLOR
{
	float4 OutColor = tex2D(Diffuse_Sampler, Input.DiffuseMap) * Input.Color;
	float4 TLUT = tex2D(LUT_Sampler, Input.GroundUV);
	OutColor.rgb *= Calc_Particle_Lighting(TLUT.a, Input.LerpAndLMapIntOffset, Input.LightFactor.a);
	return OutColor;
}

technique Diffuse
{
	pass p0
	{
		AlphaTestEnable = TRUE;
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		AlphaRef = 0;
		AlphaFunc = GREATER;
		CullMode = CCW;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		FogEnable = TRUE;

 		VertexShader = compile vs_3_0 Diffuse_VS(_ViewProjMatrix);
		PixelShader = compile ps_3_0 Diffuse_PS();
	}
}

float4 Additive_PS(VS2PS_Diffuse Input) : COLOR
{
	float4 OutColor = tex2D(Diffuse_Sampler, Input.DiffuseMap) * Input.Color;
	OutColor.rgb = (_EffectSunColor.b < -0.1) ? float3(1.0, 0.0, 0.0) : OutColor.rgb;
	OutColor.rgb *= OutColor.a; // Mask with alpha since were doing an add
	return OutColor;
}

technique Additive
{
	pass p0
	{
		AlphaTestEnable = TRUE;
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		AlphaRef = 0;
		AlphaFunc = GREATER;
		CullMode = NONE;
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;
		FogEnable = FALSE;

 		VertexShader = compile vs_3_0 Diffuse_VS(_ViewProjMatrix);
		PixelShader = compile ps_3_0 Additive_PS();
	}
}

technique DiffuseWithZWrite
{
	pass p0
	{
		AlphaTestEnable = TRUE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		AlphaRef = 0;
		AlphaFunc = GREATER;
		CullMode = CCW;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		FogEnable = TRUE;


 		VertexShader = compile vs_3_0 Diffuse_VS(_ViewProjMatrix);
		PixelShader = compile ps_3_0 Diffuse_PS();
	}
}
