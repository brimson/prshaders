#line 2 "BundledMesh.fx"

/*
	[Attributes from app]
*/

uniform float4x4 _ViewProjMatrix : WorldViewProjection; // : register(vs_1_1, c0);
uniform float4x4 _ViewInverseMatrix : ViewI; //: register(vs_1_1, c8);
uniform float4x3 _MatOneBoneSkinning[26]: matONEBONESKINNING;// : register(c15) < bool sparseArray = true; int arrayStart = 15; >;
uniform float4x4 _ViewMatrix : ViewMatrix;
uniform float4x4 _ViewITMatrix : ViewITMatrix;

uniform float4 _AmbientColor : Ambient = { 0.0f, 0.0f, 0.0f, 1.0f };
uniform float4 _DiffuseColor : Diffuse = { 1.0f, 1.0f, 1.0f, 1.0f };
uniform float4 _SpecularColor : Specular = { 0.0f, 0.0f, 0.0f, 1.0f };

uniform float4x4 _ViewProjLightMatrix : vpLightMat;
uniform float4x4 _ViewProjTrapezMatrix : vpLightTrapezMat;
uniform float4 _PosUnpack : POSUNPACK;

uniform float2 _TexProjOffset : TEXPROJOFFSET;

uniform float2 _ZLimitsInv : ZLIMITSINV;

uniform float _ShadowAlphaThreshold : SHADOWALPHATHRESHOLD;
uniform float4x4 _LightViewProj : LIGHTVIEWPROJ;
uniform float4 _ViewportMap : VIEWPORTMAP;

uniform dword _DwordStencilRef : STENCILREF = 0;
uniform float4 _EyePos : EYEPOS = { 0.0f, 0.0f, 1.0f, 0.25f };
uniform float _AltitudeFactor : ALTITUDEFACTOR = 0.7f;

uniform float4 _Attenuation : Attenuation;

uniform float4x4 _ViewPortMatrix: _ViewPortMatrix;
uniform float4 _ViewportMap2: ViewportMap;
uniform bool _AlphaBlendEnable: AlphaBlendEnable;

uniform float4 _LightPosition : LightPosition;

// float4 _EyePos;

uniform float4 _LightDirection : LightDirection;

// offset x/y HeightmapSize z / HemiLerpBias w
uniform float4 _HemiMapInfo : HemiMapInfo;

// float _HeightmapSize : HeightmapSize;
// float _HemiLerpBias : HemiLerpBias;
uniform float _NormalOffsetScale : NormalOffsetScale;

uniform float4 _SkyColor : SkyColor;
uniform float4 _AmbientColor2 : AmbientColor;
uniform float4 _SunColor : SunColor;

uniform float _AttenuationSqrInv : AttenuationSqrInv;
uniform float4 _LightColor : LightColor;
uniform float _ConeAngle : ConeAngle;

uniform float4 _ParaboloidValues : ParaboloidValues;
uniform float4 _ParaboloidZValues : ParaboloidZValues;

uniform float4x3 _UVMatrix[8]: UVMatrix;

/*
	[Textures and Samplers]
*/

uniform texture Texture_0: TEXLAYER0;
uniform texture Texture_1: TEXLAYER1;
uniform texture Texture_2: TEXLAYER2;
uniform texture Texture_3: TEXLAYER3;
uniform texture Texture_4: TEXLAYER4;

/*
	SHADOW BUFFER DATA

	texture Shadow_Map: ShadowMapTex;

	sampler Shadow_Map_Sampler = sampler_state
	{
		Texture = (Shadow_Map);
		AddressU = CLAMP;
		AddressV = CLAMP;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = NONE;
	};

	texture Shadow_Map_Occluder: ShadowMapOccluderTex;

	sampler Shadow_Map_Occluder_Sampler = sampler_state
	{
		Texture = (Shadow_Map_Occluder);
		AddressU = CLAMP;
		AddressV = CLAMP;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = NONE;
	};
*/

#define CREATE_SAMPLER(NAME, TEXTURE, ADDRESS, FILTER) \
	sampler NAME = sampler_state \
	{ \
		Texture = (TEXTURE); \
		AddressU = ADDRESS; \
		AddressV = ADDRESS; \
		MinFilter = FILTER; \
		MagFilter = FILTER; \
		MipFilter = FILTER; \
	};

CREATE_SAMPLER(BundledMesh_Sampler_0, Texture_0, CLAMP, LINEAR)
CREATE_SAMPLER(BundledMesh_Sampler_1, Texture_1, CLAMP, LINEAR)
CREATE_SAMPLER(BundledMesh_Sampler_2, Texture_2, CLAMP, LINEAR)
CREATE_SAMPLER(BundledMesh_Sampler_3, Texture_3, CLAMP, LINEAR)
CREATE_SAMPLER(BundledMesh_Sampler_Cube_3, Texture_3, WRAP, LINEAR)

CREATE_SAMPLER(Diffuse_Sampler, Texture_0, WRAP, LINEAR)
CREATE_SAMPLER(Normal_Sampler, Texture_1, WRAP, LINEAR)

sampler Dummy_Sampler = sampler_state
{
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU = CLAMP;
	AddressV = CLAMP;
};

CREATE_SAMPLER(Color_LUT_Sampler, Texture_2, CLAMP, LINEAR)

struct APP2VS
{
	float4 Pos : POSITION;
	float3 Normal : NORMAL;
	float4 BlendIndices : BLENDINDICES;
	float2 TexCoord : TEXCOORD0;
	float3 Tan : TANGENT;
	float3 Binorm : BINORMAL;
};

struct VS2PS_1
{
	float4 HPos : POSITION;
	float4 NormalDiffuseMap : TEXCOORD0;
	float3 LightVec : TEXCOORD1;
	float3 HalfVec : TEXCOORD2;
	float Fog : FOG;
};

struct VS2PS_20
{
	float4 HPos : POSITION;
	float2 Tex0 : TEXCOORD0;
	float3 LightVec : TEXCOORD1;
	float3 HalfVec : TEXCOORD2;
	float Fog : FOG;
};

struct VS2PS_2
{
	float4 HPos : POSITION;
	float2 TexCoord : TEXCOORD0;
	float4 Diffuse : COLOR;
	float Fog : FOG;
};

technique Full_States <bool Restore = true;>
{
	pass BeginStates
	{
		AlphaTestEnable = TRUE;
		AlphaRef = 0;
		AlphaFunc = GREATER;

		Sampler[1] = <Dummy_Sampler>;
		Sampler[2] = <Color_LUT_Sampler>;
	}

	pass EndStates { }
}




/*
	Blinn-specular-bumpmap shaders
*/

void Specular_VS(APP2VS Input, out float4 HPos, out float3 LightVec, out float3 HalfVec)
{
	float4 Constants = float4(0.5, 0.5, 0.5, 1.0);

	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(Input.BlendIndices);
	int IndexArray[4] = (int[4])IndexVector;

	float3 Pos = mul(Input.Pos, _MatOneBoneSkinning[IndexArray[0]]);
	HPos = mul(float4(Pos.xyz, 1.0f), _ViewProjMatrix);

	// Cross product to create BiNormal
	float3 BiNormal = normalize(cross(Input.Tan, Input.Normal));

	// Need to calculate the WorldI based on each matBone skinning world matrix
	float3x3 TanBasis = float3x3(Input.Tan, BiNormal, Input.Normal);
	// Calculate WorldTangent directly... inverse is the transpose for affine rotations
	float3x3 WorldI = transpose(mul(TanBasis, _MatOneBoneSkinning[IndexArray[0]]));

	// Transform Light pos to Object space
	// float4 MatsLightDir = float4(0.2, 0.8, -0.2, 1.);
	// float3 MatsLightDir = float3(0.0, 1.0, 0.0);
	float3 MatsLightDir = float3(0.5, 0.5, 0.0);
	float3 NormalizedTanLightVec = normalize(mul(MatsLightDir, WorldI));

	LightVec = NormalizedTanLightVec;

	// Transform eye pos to tangent space
	float3 WorldEyeVec = _ViewInverseMatrix[3].xyz - Pos;
	float3 TanEyeVec = mul(WorldEyeVec, WorldI);

	HalfVec = normalize(NormalizedTanLightVec + normalize(TanEyeVec));
}

VS2PS_1 BlinnSpecularBump_1_VS(APP2VS Input)
{
	VS2PS_1 Output = (VS2PS_1)0;
	Specular_VS(Input, Output.HPos, Output.LightVec, Output.HalfVec);

	// Pass-through texcoords
	Output.NormalDiffuseMap.xy = Input.TexCoord; // Normal
	Output.NormalDiffuseMap.zw = Input.TexCoord; // Diffuse
	Output.Fog = 0.0; // Calc_Fog(Output.HPos.w);
	return Output;
}

float4 BlinnSpecularBump_1_PS(VS2PS_1 Input) : COLOR
{
	float4 Ambient = float4(0.4, 0.4, 0.4, 1.0);
	float4 Diffuse = 1.0;
	float4 Specular = 1.0;

	float4 NormalMap = tex2D(Normal_Sampler, Input.NormalDiffuseMap.xy);
	float U = dot(Input.LightVec.xy, Input.NormalDiffuseMap.xy * 2.0 - 1.0);
	float V = dot(Input.HalfVec.xy, Input.NormalDiffuseMap.xy * 2.0 - 1.0);
	float4 Gloss = tex2D(Diffuse_Sampler, float2(U,V));
	float4 DiffuseMap = tex2D(Diffuse_Sampler, Input.NormalDiffuseMap.zw);

	float4 OutColor = saturate((Gloss * Diffuse) + Ambient);
	OutColor *= DiffuseMap;

	float Spec = NormalMap.a * Gloss.a;
	OutColor = saturate((Spec * Specular) + OutColor);
	return OutColor;
}

technique Full
{
	pass p0
	{
		VertexShader = compile vs_3_0 BlinnSpecularBump_1_VS();
		PixelShader = compile ps_3_0 BlinnSpecularBump_1_PS();
	}
}

VS2PS_20 BlinnSpecularBump_20_VS(APP2VS Input)
{
	VS2PS_20 Output = (VS2PS_20)0;
	Specular_VS(Input, Output.HPos, Output.LightVec, Output.HalfVec);

	// Pass-through texcoords
	Output.Tex0 = Input.TexCoord;
	Output.Fog = 0.0; // Calc_Fog(Output.HPos.w);
	return Output;
}

float4 BlinnSpecularBump_20_PS(VS2PS_20 Input) : COLOR
{
	float4 Cosang, TDiffuse, TNormal, Color, TShadow;
	float3 TLight;

	// Sample Diffuse texture and Normal map
	TDiffuse = tex2D(Diffuse_Sampler, Input.Tex0);

	TNormal = tex2D(Normal_Sampler, Input.Tex0) * 2.0 - 1.0;
	TLight = Input.LightVec * 2.0 - 1.0;

	// DP Lighting in tangent space (where normal map is based)
	// Modulate with Diffuse texture
	Color = dot(TNormal.xyz, TLight) * TDiffuse;

	// N.H for Specular term
	Cosang = dot(TNormal.xyz, Input.HalfVec);

	// Raise to a power for falloff
	Cosang = pow(Cosang, 32.0) * TNormal.w; // try changing the power to 255!

	// Sample shadow texture
	TShadow = tex2D(BundledMesh_Sampler_3, Input.Tex0);

	// Add to Diffuse lit texture value
	float4 Res = (Color + Cosang) * TShadow;

	// float4 Res = Color * TShadow;
	return float4(Res.xyz, TDiffuse.w);
}

technique Full20
{
	pass p0
	{
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		AlphaBlendEnable = FALSE;
		AlphaTestEnable = TRUE;
		AlphaRef = 0;
		AlphaFunc = GREATER;

		VertexShader = compile vs_3_0 BlinnSpecularBump_20_VS();
		PixelShader = compile ps_3_0 BlinnSpecularBump_20_PS();
	}
}




/*
	Diffuse map shaders
*/

VS2PS_2 Diffuse_VS(APP2VS Input)
{
	VS2PS_2 Output = (VS2PS_2)0;

	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(Input.BlendIndices);
	int IndexArray[4] = (int[4])IndexVector;

	// float3 Pos = Input.Pos;
	float3 Pos = mul(Input.Pos, _MatOneBoneSkinning[IndexArray[0]]);
	Output.HPos = mul(float4(Pos.xyz, 1.0), _ViewProjMatrix);
	// Output.HPos = mul(Input.Pos, WorldViewProj);

	float3 Normal = Input.Normal;
	// float3 Normal = mul(Input.Normal, _MatOneBoneSkinning[IndexArray[0]]);
	Normal = normalize(Normal);

	// Pass-through texcoords
	Output.TexCoord = Input.TexCoord;

	// Need to calculate the WorldI based on each matBone skinning world matrix
	// There must be a more efficient way to do this...
	// Inverse is simplified to M-1 = Rt * T,
	// where Rt is the transpose of the rotaional part and T is the translation
	float4x4 WorldI;
	float3x3 R;
	R[0] = float3(_MatOneBoneSkinning[IndexArray[0]][0].xyz);
	R[1] = float3(_MatOneBoneSkinning[IndexArray[0]][1].xyz);
	R[2] = float3(_MatOneBoneSkinning[IndexArray[0]][2].xyz);
	float3x3 Rtranspose = transpose(R);
	float3 T = mul(_MatOneBoneSkinning[IndexArray[0]][3],Rtranspose);
	WorldI[0] = float4(Rtranspose[0].xyz,T.x);
	WorldI[1] = float4(Rtranspose[1].xyz,T.y);
	WorldI[2] = float4(Rtranspose[2].xyz,T.z);
	WorldI[3] = float4(0.0, 0.0, 0.0, 1.0);

	// Transform Light pos to Object space
	float3 MatsLightDir = float3(0.2, 0.8, -0.2);
	float3 LightDirObjSpace = mul(-MatsLightDir, WorldI);
	float3 NormalizedLightVec = normalize(LightDirObjSpace);

	float Color = 0.8 + max(0.0, dot(Normal, NormalizedLightVec));
	Output.Diffuse = saturate(float4(Color, Color, Color, 1.0));
	Output.Fog = 0.0; // Calc_Fog(Output.HPos.w);
	return Output;
}

float4 Diffuse_PS(VS2PS_2 Input) : COLOR
{
	float4 OutColor = tex2D(Diffuse_Sampler, Input.TexCoord);
	OutColor *= Input.Diffuse;
	return OutColor;
}

technique t1
{
	pass p0
	{
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		// CullMode = NONE;
		AlphaBlendEnable = FALSE;
		AlphaTestEnable = TRUE;
		AlphaRef = 0;
		AlphaFunc = GREATER;
		// FillMode = WIREFRAME;

		VertexShader = compile vs_3_0 Diffuse_VS();
		PixelShader = compile ps_3_0 Diffuse_PS();
	}
}




/*
	Alpha enivroment map shaders
*/

struct VS2PS_Alpha
{
	float4 HPos : POSITION;
	float2 DiffuseMap : TEXCOORD0;
	float4 Tex1 : TEXCOORD1;
	float Fog : FOG;
};

struct VS2PS_Alpha_Env_Map
{
	float4 HPos : POSITION;
	float4 DiffuseNormalMap : TEXCOORD0;
	float4 TexPos : TEXCOORD1;
	float4 TanToCubeSpace1 : TEXCOORD2;
	float4 TanToCubeSpace2 : TEXCOORD3;
	float4 TanToCubeSpace3 : TEXCOORD4;
	float4 EyeVecAndReflection: TEXCOORD5;
	float Fog : FOG;
};

void Alpha_Map_VS
(
	APP2VS Input,
	in int IndexArray[4],
	in float4x4 ViewProj,
	out float3 Pos,
	out float4 HPos,
	out float4 Tex
)
{
	Pos = mul(Input.Pos, _MatOneBoneSkinning[IndexArray[0]]);
	HPos = mul(float4(Pos.xyz, 1.0), ViewProj);

	// Hacked to only support 800/600
	Tex.xy = HPos.xy / HPos.w;
	Tex.xy = Tex.xy * 0.5 + 0.5;
	Tex.y = 1.0 - Tex.y;
	Tex.xy += _TexProjOffset;
	// Tex.x += 0.000625;
	// Tex.y += 0.000833;
	Tex.xy = Tex.xy * HPos.w;
	Tex.zw = HPos.zw;
}

VS2PS_Alpha Alpha_VS(APP2VS Input, uniform float4x4 ViewProj)
{
	VS2PS_Alpha Output;

	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(Input.BlendIndices);
	int IndexArray[4] = (int[4])IndexVector;

	float3 Pos = 0.0;
	Alpha_Map_VS(Input, IndexArray, ViewProj, Pos, Output.HPos, Output.Tex1);

	// Pass-through texcoords
	Output.DiffuseMap = Input.TexCoord.xy;

	Output.Fog = 0.0; // Calc_Fog(Output.HPos.w);
	return Output;
}

float4 Alpha_PS(VS2PS_Alpha Input) : COLOR
{
	float4 ProjLight = tex2Dproj(BundledMesh_Sampler_1, Input.Tex1);
	float4 OutColor;
	OutColor = tex2D(BundledMesh_Sampler_0, Input.DiffuseMap);
	OutColor.rgb *= ProjLight.rgb;
	OutColor.rgb += ProjLight.a;
	return OutColor;
}

VS2PS_Alpha_Env_Map Alpha_Env_Map_VS(APP2VS Input, uniform float4x4 ViewProj)
{
	VS2PS_Alpha_Env_Map Output = (VS2PS_Alpha_Env_Map)0;

	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(Input.BlendIndices);
	int IndexArray[4] = (int[4])IndexVector;

	float3 Pos = 0.0;
	Alpha_Map_VS(Input, IndexArray, ViewProj, Pos, Output.HPos, Output.TexPos);

	// Pass-through texcoords
	Output.DiffuseNormalMap.xy = Input.TexCoord; // Diffuse
	Output.DiffuseNormalMap.zw = Input.TexCoord; // Normal

	// Cross product to create BiNormal
	float3 BiNormal = normalize(cross(Input.Tan, Input.Normal));

	// Need to calculate the TanToCubeState based on each matBone skinning world matrix

	float3x3 TanToObjectBasis;
	TanToObjectBasis[0] = float3(Input.Tan[0], BiNormal[0], Input.Normal[0]);
	TanToObjectBasis[1] = float3(Input.Tan[1], BiNormal[1], Input.Normal[1]);
	TanToObjectBasis[2] = float3(Input.Tan[2], BiNormal[2], Input.Normal[2]);

	[unroll] for(int i = 0; i < 3; i++)
	{
		Output.TanToCubeSpace1[i] = dot(_MatOneBoneSkinning[IndexArray[0]][i].xyz, TanToObjectBasis[0]);
		Output.TanToCubeSpace2[i] = dot(_MatOneBoneSkinning[IndexArray[0]][i].xyz, TanToObjectBasis[1]);
		Output.TanToCubeSpace3[i] = dot(_MatOneBoneSkinning[IndexArray[0]][i].xyz, TanToObjectBasis[2]);
	}

	// Transform eye pos to tangent space
	Output.EyeVecAndReflection.xyz = Pos.xyz - _EyePos.xyz;
	Output.EyeVecAndReflection.w = _EyePos.w;
	Output.Fog = 0.0; // Calc_Fog(Output.HPos.w);
	return Output;
}

float4 Alpha_Env_Map_PS(VS2PS_Alpha_Env_Map Input) : COLOR
{
	float4 AccumLight = tex2Dproj(BundledMesh_Sampler_1, Input.TexPos);

	float4 OutColor;
	OutColor = tex2D(BundledMesh_Sampler_0, Input.DiffuseNormalMap.xy);
	OutColor.rgb *= AccumLight.rgb;

	float4 NormalMap = tex2D(BundledMesh_Sampler_2, Input.DiffuseNormalMap.zw);
	float3 ExpandedNormal = (NormalMap.xyz * 2.0) - 1.0;
	float3 WorldNormal;
	WorldNormal.x = dot(Input.TanToCubeSpace1.xyz, ExpandedNormal);
	WorldNormal.y = dot(Input.TanToCubeSpace2.xyz, ExpandedNormal);
	WorldNormal.z = dot(Input.TanToCubeSpace3.xyz, ExpandedNormal);

	float3 Lookup = reflect(normalize(Input.EyeVecAndReflection.xyz), normalize(WorldNormal));
	float3 EnvMapColor = texCUBE(BundledMesh_Sampler_Cube_3, Lookup) * NormalMap.a * Input.EyeVecAndReflection.w;

	OutColor.rgb += AccumLight.a + EnvMapColor;
	return OutColor;
}

technique Alpha
{
	pass p0
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		CullMode = NONE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		AlphaTestEnable = TRUE;
		AlphaRef = 0;
		AlphaFunc = GREATER;
		// TextureTransformFlags[1] = PROJECTED; // This doesn't work very well....

		VertexShader = compile vs_3_0 Alpha_VS(_ViewProjMatrix);
		PixelShader = compile ps_3_0 Alpha_PS();
	}

	pass p1EnvMap
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		CullMode = NONE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		AlphaTestEnable = TRUE;
		AlphaRef = 0;
		AlphaFunc = GREATER;
		// TextureTransformFlags[1] = PROJECTED; // This doesn't work very well....

		VertexShader = compile vs_3_0 Alpha_Env_Map_VS(_ViewProjMatrix);
		PixelShader = compile ps_3_0 Alpha_Env_Map_PS();
	}
}




/*
	Alpha scope shaders
*/

struct VS2PS_Alpha_Scope
{
	float4 HPos : POSITION;
	float3 Tex0AndTrans	: TEXCOORD0;
	float2 Tex1 : TEXCOORD1;
	float Fog : FOG;
};

float4 Alpha_Scope_PS(VS2PS_Alpha_Scope Input) : COLOR
{
	float4 AccumLight = tex2D(BundledMesh_Sampler_1, Input.Tex1);
	float4 Diffuse = tex2D(BundledMesh_Sampler_0, Input.Tex0AndTrans.xy);

	Diffuse.rgb = Diffuse * AccumLight;
	Diffuse.a *= (1.0 - Input.Tex0AndTrans.b);
	return Diffuse;
}

VS2PS_Alpha_Scope Alpha_Scope_VS(APP2VS Input, uniform float4x4 ViewProj)
{
	VS2PS_Alpha_Scope Output;

	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(Input.BlendIndices);
	int IndexArray[4] = (int[4])IndexVector;

	float3 Pos = mul(Input.Pos, _MatOneBoneSkinning[IndexArray[0]]);
	Output.HPos = mul(float4(Pos.xyz, 1.0), ViewProj);

	float3 WorldNormal = mul(Input.Normal, _MatOneBoneSkinning[IndexArray[0]]);
	float3 WorldEyeVec = normalize(_ViewInverseMatrix[3].xyz - Pos);

	float F = dot(WorldNormal, WorldEyeVec);

	Output.Tex0AndTrans.xy = Input.TexCoord;
	Output.Tex0AndTrans.z = smoothstep(0.965, 1.0, F);	// step(0.99, F) * F;

	Output.Tex1.xy = Output.HPos.xy / Output.HPos.w;
	Output.Tex1.xy = (Output.Tex1.xy * 0.5) + 0.5;
	Output.Tex1.y = 1.0 - Output.Tex1.y;
	Output.Fog = 0.0; // Calc_Fog(Output.HPos.w);

	return Output;
}

technique alphascope
{
	pass p0
	{
		ZEnable = FALSE;
		ZWriteEnable = FALSE;
		CullMode = NONE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		AlphaTestEnable = FALSE;
		AlphaRef = 0;
		AlphaFunc = GREATER;

		VertexShader = compile vs_3_0 Alpha_Scope_VS(_ViewProjMatrix);
		PixelShader = compile ps_3_0 Alpha_Scope_PS();
	}
}




/*
	Shadow map shaders
*/

float4 Calc_Shadow_Proj_Coords(float4 Pos, float4x4 matTrap, float4x4 matLight)
{
	float4 ShadowCoords = mul(Pos, matTrap);
	float2 LightZW = mul(Pos, matLight).zw;
	ShadowCoords.z = (LightZW.x * ShadowCoords.w) / LightZW.y; // (zL*wT)/wL == zL/wL post homo
	return ShadowCoords;
}

struct VS2PS_Shadow_Map
{
	float4 HPos : POSITION;
	float2 PosZW : TEXCOORD0;
};

struct VS2PS_Shadow_Map_Alpha
{
	float4 HPos : POSITION;
	float4 Tex0PosZW : TEXCOORD0;
	// SHADOWS
	float4 Attenuation	: COLOR0;
};

VS2PS_Shadow_Map Shadow_Map_VS(APP2VS Input)
{
	VS2PS_Shadow_Map Output = (VS2PS_Shadow_Map)0;

	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(Input.BlendIndices);
	int IndexArray[4] = (int[4])IndexVector;

	float4 UnpackPos = float4(Input.Pos.xyz * _PosUnpack.xyz, 1.0);
	float3 Pos = mul(UnpackPos, _MatOneBoneSkinning[IndexArray[0]]);
	Output.HPos = Calc_Shadow_Proj_Coords(float4(Pos.xyz, 1.0), _ViewProjTrapezMatrix, _ViewProjLightMatrix);

	Output.PosZW = Output.HPos.zw;
	return Output;
}

float4 Shadow_Map_PS(VS2PS_Shadow_Map Input) : COLOR
{
	#if NVIDIA
		return 0.0;
	#else
		return Input.PosZW.x / Input.PosZW.y;
	#endif
}

VS2PS_Shadow_Map_Alpha Shadow_Map_Alpha_VS(APP2VS Input)
{
	VS2PS_Shadow_Map_Alpha Output;

	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(Input.BlendIndices);
	int IndexArray[4] = (int[4])IndexVector;

	float4 UnpackPos = Input.Pos * _PosUnpack;
	float3 Pos = mul(UnpackPos, _MatOneBoneSkinning[IndexArray[0]]);
	Output.HPos = Calc_Shadow_Proj_Coords(float4(Pos.xyz, 1.0), _ViewProjTrapezMatrix, _ViewProjLightMatrix);

	float4 WorldPos = float4(Pos.xyz, 1.0);

	// SHADOW
	// matrix m = mul(_ViewProjLightMatrix, _ViewProjTrapezMatrix);
	// Output.HPos = mul(WorldPos, _ViewProjLightMatrix);

	Output.Tex0PosZW.xy = Input.TexCoord;
	Output.Tex0PosZW.zw = Output.HPos.zw;
	Output.Attenuation = 0.0;

	return Output;
}

float4 Shadow_Map_Alpha_PS(VS2PS_Shadow_Map_Alpha Input) : COLOR
{
	float Alpha = tex2D(BundledMesh_Sampler_0, Input.Tex0PosZW.xy).a-_ShadowAlphaThreshold;
	#if NVIDIA
		return Alpha;
	#else
		clip(Alpha);
		return Input.Tex0PosZW.z / Input.Tex0PosZW.w;
	#endif
}

#define SHADOW_RENDER_STATES(VERTEX_SHADER, PIXEL_SHADER, CULL_MODE) \
	ZEnable = TRUE; \
	ZFunc = LESSEQUAL; \
	ZWriteEnable = TRUE; \
	AlphaBlendEnable = FALSE; \
	ScissorTestEnable = TRUE; \
	CullMode = CULL_MODE; \
	VertexShader = compile vs_3_0 VERTEX_SHADER; \
	PixelShader = compile ps_3_0 PIXEL_SHADER; \

technique DrawShadowMap
{
	pass directionalspot
	{
		#if NVIDIA
			ColorWriteEnable = 0; // 0x0000000F;
		#endif

		SHADOW_RENDER_STATES(Shadow_Map_VS(), Shadow_Map_PS(), CCW)
	}

	pass directionalspotalpha
	{
		#if NVIDIA
			AlphaTestEnable = TRUE;
			AlphaRef = 0;
			ColorWriteEnable = 0; // 0x0000000F;
		#endif

		SHADOW_RENDER_STATES(Shadow_Map_Alpha_VS(), Shadow_Map_Alpha_PS(), CCW)
	}

	pass point_
	{
		#if NVIDIA
			ColorWriteEnable = 0; // 0x0000000F;
		#endif

		SHADOW_RENDER_STATES(Shadow_Map_VS(), Shadow_Map_PS(), CCW)
	}

	pass pointalpha
	{
		#if NVIDIA
			ColorWriteEnable = 0; // 0x0000000F;
			AlphaTestEnable = TRUE;
			AlphaRef = 0;
		#endif

		SHADOW_RENDER_STATES(Shadow_Map_Alpha_VS(), Shadow_Map_Alpha_PS(), CCW)
	}
}

// We actually don't need to have 2 techniques here
// but it is kept for back-compatibility with original BF2
technique DrawShadowMapNV
{
	pass directionalspot
	{
		#if NVIDIA
			ColorWriteEnable = 0;//0x0000000F;
		#endif

		SHADOW_RENDER_STATES(Shadow_Map_VS(), Shadow_Map_PS(), CCW)
	}

	pass directionalspotalpha
	{
		#if NVIDIA
			ColorWriteEnable = 0;//0x0000000F;
			AlphaTestEnable = TRUE;
			AlphaRef = 0;
		#endif

		SHADOW_RENDER_STATES(Shadow_Map_Alpha_VS(), Shadow_Map_Alpha_PS(), NONE) // CW
	}

	pass point_
	{
		#if NVIDIA
			ColorWriteEnable = 0; // 0x0000000F;
		#endif

		SHADOW_RENDER_STATES(Shadow_Map_VS(), Shadow_Map_PS(), NONE) // CW
	}

	pass pointalpha
	{
		#if NVIDIA
			ColorWriteEnable = 0; // 0x0000000F;
			AlphaTestEnable = TRUE;
			AlphaRef = 0;
		#endif

		SHADOW_RENDER_STATES(Shadow_Map_Alpha_VS(), Shadow_Map_Alpha_PS(), NONE) // CW
	}
}
