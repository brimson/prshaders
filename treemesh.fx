#line 2 "TreeMesh.fx"

/*
	[Uniform data from app]
*/

uniform float4x4 _WorldViewProj : WorldViewProjection; // : register(vs_3_0, c0);
uniform float4x4 _WorldInverseMat : WorldI; // : register(vs_3_0, c4);
uniform float4x4 _ViewInverseMat : ViewI; //: register(vs_3_0, c8);
// uniform float4x3 _OneBoneSkinning[26]: matONEBONESKINNING; //: register(vs_3_0, c15);

// Sprite parameters
uniform float4x4 _WorldViewMat : WorldView;
uniform float4x4 _ProjMat : Projection;
uniform float4 _SpriteScale :  SpriteScale;
uniform float4 _ShadowSpherePoint : ShadowSpherePoint;
uniform float4 _BoundingboxScaledInvGradientMag : BoundingboxScaledInvGradientMag;
uniform float4 _InvBoundingBoxScale : InvBoundingBoxScale;
uniform float4 _ShadowColor : ShadowColor;

uniform float4 _AmbColor : Ambient = { 0.0f, 0.0f, 0.0f, 1.0f };
uniform float4 _DiffColor : Diffuse = { 1.0f, 1.0f, 1.0f, 1.0f };
uniform float4 _SpecColor : Specular = { 0.0f, 0.0f, 0.0f, 1.0f };

// uniform texture LUT_Color: LUTMap;
float4 _EyePos : EyePosition = {0.0f, 0.0f, 1.0f, 0.0f};

float4 _LightPos : LightPosition
<
	string Object = "PointLight";
	string Space = "World";
> = {0.0f, 0.0f, 1.0f, 1.f};

float4 _LightDir : LightDirection;
float _HeightmapSize : HeightmapSize;
float _NormalOffsetScale : NormalOffsetScale;
float _HemiLerpBias : HemiLerpBias;
float4 _SkyColor : SkyColor;
float4 _AmbientColor : AmbientColor;
float4 _SunColor : SunColor;

float _AttenuationSqrInv : AttenuationSqrInv;
float4 _LightColor : LightColor;
float _ConeAngle : ConeAngle;

uniform texture Texture_0: TEXLAYER0; // Normal or Diffuse map
uniform texture Texture_1: TEXLAYER1; // Ground Color
uniform texture Texture_2: TEXLAYER2; // Intensity
uniform texture Texture_3: TEXLAYER3; // Diffuse

sampler Sampler_0 = sampler_state
{
	Texture = (Texture_0);
};

sampler Sampler_1 = sampler_state
{
	Texture = (Texture_1);
};

sampler Sampler_2 = sampler_state
{
	Texture = (Texture_2);
	AddressU = CLAMP;
	AddressV = CLAMP;
};

sampler Sampler_3 = sampler_state
{
	Texture = (Texture_3);
};

sampler Diffuse_Sampler = sampler_state
{
	Texture = <Texture_0>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	// MipMapLodBias = 0;
	AddressU = WRAP;
	AddressV = WRAP;
};

struct APP2VS
{
	float4 Pos : POSITION;
	float3 Normal : NORMAL;
	float2 TexCoord : TEXCOORD0;
	float2 TexCoord1 : TEXCOORD1;
	float4 Tan : TANGENT;
};

struct APP2VS_2
{
	float4 Pos : POSITION;
	float3 Normal : NORMAL;
	float2 TexCoord : TEXCOORD0;
	float2 Width_height : TEXCOORD1;
	float4 Tan : TANGENT;
};

struct VS2PS
{
	float4 HPos : POSITION;
	float2 TexCoord : TEXCOORD0;
	float2 TexCoord2 : TEXCOORD1;
	float4 LightVec : TEXCOORD2;
	float4 HalfVec : TEXCOORD3;
	float4 Diffuse : COLOR0;
};

struct VS2PS_2
{
	float4 HPos : POSITION;
	float2 TexCoord : TEXCOORD0;
	float4 Diffuse : COLOR0;
};

VS2PS BumpSpecular_Blinn_1_VS(APP2VS Input)
{
	VS2PS Output = (VS2PS)0;

 	Output.HPos = mul(Input.Pos, _WorldViewProj);

	// Cross product to create BiNormal
	float3 BiNormal = cross(Input.Tan.xyz, Input.Normal);
	BiNormal = normalize(BiNormal);

	// Pass-through texcoords
	Output.TexCoord = Input.TexCoord;
	Output.TexCoord2 = Input.TexCoord;

	// Transform Light Pos to Object space
	float3 MatsLightDir = float3(0.2f, 0.8f, -0.2f);
	float3 LightDirObjSpace = mul(-MatsLightDir, _WorldInverseMat);
	float3 NormalizedLightVec = normalize(LightDirObjSpace);

	// TANGENT SPACE LIGHT
	// This way of geting the tangent space data changes the coordinate system
	float3 TanLightVec = float3(dot(-NormalizedLightVec, Input.Tan.xyz),
								dot(-NormalizedLightVec, BiNormal),
								dot(-NormalizedLightVec, Input.Normal));

	// Compress L' in tex2... don't compress, autoclamp >0
	float3 NormalizedTanLightVec = normalize(TanLightVec);
	Output.LightVec = float4((0.5f + NormalizedTanLightVec * 0.5f).xyz, 0.0f);

	// Transform eye Pos to tangent space
	float4 MatsEyePos = float4(0.0f, 0.0f, 1.0f, 0.0f);
	float4 WorldPos = mul(MatsEyePos, _ViewInverseMat);
	// float4 WorldPos = mul(_EyePos, _ViewInverseMat);

	float3 ObjPos = mul(float4(WorldPos.xyz, 1.0f), _WorldInverseMat);
	float3 TanPos = float3(dot(ObjPos, Input.Tan.xyz),
						   dot(ObjPos, BiNormal),
						   dot(ObjPos, Input.Normal));

	float3 HalfVec = normalize(NormalizedTanLightVec + TanPos);
	// Compress H' in tex3... don't compress, autoclamp >0
	Output.HalfVec = float4((0.5f + -HalfVec * 0.5f).xyz, 1.0f);
	float Color = 0.8f + max(0.0f, dot(Input.Normal, NormalizedLightVec));
	Output.Diffuse = saturate(float4(Color, Color, Color, 1.0f));

	return Output;
}

float4 BumpSpecular_Blinn_1_PS(VS2PS Input) : COLOR
{
	float4 DiffuseMap = tex2D(Diffuse_Sampler, Input.TexCoord);
	return DiffuseMap * Input.Diffuse;
}




VS2PS_2 Sprite_VS(APP2VS_2 Input)
{
	VS2PS_2 Output = (VS2PS_2)0;
	float4 Pos =  mul(Input.Pos, _WorldViewMat);
	float4 ScaledPos = float4(float2(Input.Width_height.xy * _SpriteScale.xy), 0.0, 0.0) + Pos;
 	Output.HPos = mul(ScaledPos, _ProjMat);
	Output.TexCoord = Input.TexCoord;

	// Lighting calc
	float4 EyeSpaceSherePoint = mul(_ShadowSpherePoint, _WorldViewMat);
	float4 ShadowSpherePos = ScaledPos * _InvBoundingBoxScale;
	float4 EyeShadowSperePos = EyeSpaceSherePoint * _InvBoundingBoxScale;
	float4 VectorMagnitude = normalize(ShadowSpherePos - EyeShadowSperePos);
	float ShadowFactor = VectorMagnitude * _BoundingboxScaledInvGradientMag;
	ShadowFactor = min(ShadowFactor, 1.0);
	float3 ShadowColorInt = _ShadowColor * (1.0 - ShadowFactor);
	float3 Color = _LightColor.rgb * ShadowFactor + ShadowColorInt;
	Output.Diffuse = saturate(float4(Color, 1.0f));
	return Output;
}

float4 Sprite_PS(VS2PS_2 Input) : COLOR
{
	float4 DiffuseMap = tex2D(Diffuse_Sampler, Input.TexCoord);
	return DiffuseMap * Input.Diffuse;
}




struct VS2PS_BumpSpecular_HemiSun_PV
{
	float4 HPos : POSITION;
	float2 NormalMap : TEXCOORD0;
	float3 LightVec : TEXCOORD1;
	float3 HalfVec : TEXCOORD2;
	float3 GroundUVAndLerp : TEXCOORD3;
	float2 DiffuseAlpha : TEXCOORD4;
};

VS2PS_BumpSpecular_HemiSun_PV Bump_Specular_HemiSun_PV_VS(APP2VS Input)
{
	VS2PS_BumpSpecular_HemiSun_PV Output = (VS2PS_BumpSpecular_HemiSun_PV)0;

 	// float3 Pos = mul(Input.Pos, _OneBoneSkinning[IndexArray[0]]);
 	Output.HPos = mul(float4(Input.Pos.xyz, 1.0f), _WorldViewProj);

 	// Hemi lookup values
 	float3 AlmostNormal = Input.Normal.xyz;
 	Output.GroundUVAndLerp.xy = (Input.Pos.xyz +(_HeightmapSize * 0.5) + AlmostNormal).xz / _HeightmapSize;
 	Output.GroundUVAndLerp.z = AlmostNormal.y * 0.5 + 0.5;

	// Cross product to create BiNormal
	float3 BiNormal = normalize(cross(Input.Tan.xyz, Input.Normal));

	// Need to calculate the WorldI based on each matBone skinning world matrix
	float3x3 TanBasis = float3x3(Input.Tan.xyz, BiNormal, Input.Normal.xyz);

	// Calculate WorldTangent directly... inverse is the transpose for affine rotations
	// float3x3 worldI = transpose(mul(TanBasis, _OneBoneSkinning[IndexArray[0]]));

	// Pass-through texcoords
	Output.NormalMap = Input.TexCoord;
	// Output.DiffMap = Input.TexCoord;

	// Transform Light dir to Object space, lightdir is already in object space.
	float3 NormalizedTanLightVec = normalize(mul(-_LightDir.xyz, TanBasis));

	Output.LightVec = NormalizedTanLightVec;

	// Transform eye Pos to tangent space
	float3 WorldEyeVec = _ViewInverseMat[3].xyz - Input.Pos.xyz;
	float3 TanEyeVec = mul(WorldEyeVec, TanBasis);

	Output.HalfVec = normalize(NormalizedTanLightVec + normalize(TanEyeVec));

	return Output;
}

float4 Bump_Specular_HemiSun_PV_PS(VS2PS_BumpSpecular_HemiSun_PV Input) : COLOR
{
	float4 NormalMap = tex2D(Sampler_0, Input.NormalMap);
	float3 ExpNormal = NormalMap.xyz * 2.0 - 1.0;
	float4 Diffuse = tex2D(Sampler_3, Input.NormalMap);
	float2 IntensityUV = float2(dot(Input.LightVec, ExpNormal), dot(Input.HalfVec, ExpNormal));

	float4 Intensity = tex2D(Sampler_2, IntensityUV);
	float RealIntensity = Intensity.b + Intensity.a * NormalMap.a;
	RealIntensity *= _SunColor;

	float4 GroundColor = tex2D(Sampler_1, Input.GroundUVAndLerp.xy);
	float4 HemiColor = lerp(GroundColor, _SkyColor, Input.GroundUVAndLerp.z - _HemiLerpBias);
	float4 Result = _AmbientColor * HemiColor + (RealIntensity * GroundColor.a * GroundColor.a);
	Result.a = Diffuse.a;
	return Result;
}

technique HemiAndSun_States <bool Restore = true;>
{
	pass BeginStates
	{
		AlphaTestEnable = TRUE;
		AlphaRef = 0;
		AlphaFunc = GREATER;

		// Normal
		AddressU[0] = WRAP;
		AddressV[0] = WRAP;
		MipFilter[0] = LINEAR;
		MinFilter[0] = LINEAR;
		MagFilter[0] = LINEAR;

		// GroundHemi
		AddressU[1] = CLAMP;
		AddressV[1] = CLAMP;
		MipFilter[1] = LINEAR;
		MinFilter[1] = LINEAR;
		MagFilter[1] = LINEAR;

		// LUT
		AddressU[2] = CLAMP;
		AddressV[2] = CLAMP;
		MipFilter[2] = LINEAR;
		MinFilter[2] = LINEAR;
		MagFilter[2] = LINEAR;

		// Diffuse
		AddressU[3] = WRAP;
		AddressV[3] = WRAP;
		MipFilter[3] = LINEAR;
		MinFilter[3] = LINEAR;
		MagFilter[3] = LINEAR;
	}

	pass EndStates {}
}

technique HemiAndSun
{
	pass p0
	{
		AlphaBlendEnable = FALSE;
		ZFunc = LESSEQUAL;
		ZWriteEnable = TRUE;

 		VertexShader = compile vs_3_0 Bump_Specular_HemiSun_PV_VS();
		PixelShader = compile ps_3_0 Bump_Specular_HemiSun_PV_PS();
	}
}




struct VS2PS_BumpSpecular_PointLight
{
	float4 HPos : POSITION;
	float2 NormalMap : TEXCOORD0;
	float3 LightVec : TEXCOORD1;
	float3 HalfVec : TEXCOORD2;
	float3 ObjectLightVec : TEXCOORD3;
};

VS2PS_BumpSpecular_PointLight BumpSpecular_PointLight_VS(APP2VS Input)
{
	VS2PS_BumpSpecular_PointLight Output = (VS2PS_BumpSpecular_PointLight)0;

 	Output.HPos = mul(float4(Input.Pos.xyz, 1.0f), _WorldViewProj);

	// Cross product to create BiNormal
	float3 BiNormal = normalize(cross(Input.Tan.xyz, Input.Normal));

	// Need to calculate the WorldI based on each matBone skinning world matrix
	float3x3 TanBasis = float3x3(Input.Tan.xyz, BiNormal, Input.Normal.xyz);

	// Calculate WorldTangent directly... inverse is the transpose for affine rotations
	// float3x3 worldI = transpose(mul(TanBasis, _OneBoneSkinning[IndexArray[0]]));

	// Pass-through texcoords
	Output.NormalMap = Input.TexCoord;

	// Transform Light vec to Tangentspace space
	float3 LightVec = _LightPos - Input.Pos;
	Output.ObjectLightVec = LightVec;
	float3 TanLightVec = mul(LightVec, TanBasis);

	Output.LightVec = TanLightVec;

	// Transform eye Pos to tangent space
	float3 ObjEyeVec = _ViewInverseMat[3].xyz - Input.Pos.xyz;
	float3 TanEyeVec = mul(ObjEyeVec, TanBasis);

	Output.HalfVec = normalize(normalize(TanLightVec) + normalize(TanEyeVec));
	// Output.HalfVec = (normalize(TanLightVec) + normalize(TanEyeVec)) * 0.5;

	return Output;
}

float4 BumpSpecular_PointLight_PS(VS2PS_BumpSpecular_PointLight Input) : COLOR
{
	float4 NormalMap = tex2D(Sampler_0, Input.NormalMap);
	float3 ExpNormal = NormalMap.xyz * 2.0 - 1.0;
	float4 Diffuse = tex2D(Sampler_3, Input.NormalMap);

	float3 NormalizedLightVec = normalize(Input.LightVec);
	float2 IntensityUV = float2(dot(NormalizedLightVec,ExpNormal), dot(Input.HalfVec,ExpNormal));
	// float4 Intensity = tex2D(Sampler_2, IntensityUV);
	float4 RealIntensity = IntensityUV.r + pow(IntensityUV.g, 36.0) * NormalMap.a;
	RealIntensity *= _LightColor;

	float Attenuation = saturate(1.0 - dot(Input.ObjectLightVec, Input.ObjectLightVec) * _AttenuationSqrInv);
	float4 Result = Attenuation * RealIntensity;
	Result.a = Diffuse.a;
	return Result;
}

technique PointLight_States <bool Restore = true;>
{
	pass BeginStates
	{
		AlphaBlendEnable = TRUE;
		SrcBlend = DESTALPHA;
		DestBlend = ONE;

		// Normal
		AddressU[0] = WRAP;
		AddressV[0] = WRAP;
		MipFilter[0] = LINEAR;
		MinFilter[0] = LINEAR;
		MagFilter[0] = LINEAR;
	}

	pass EndStates { }
}

technique PointLight
{
	pass p0
	{
		AlphaBlendEnable = TRUE;
		SrcBlend = DESTALPHA;
		DestBlend = ONE;

		// Normal
		AddressU[0] = WRAP;
		AddressV[0] = WRAP;
		MipFilter[0] = LINEAR;
		MinFilter[0] = LINEAR;
		MagFilter[0] = LINEAR;

 		VertexShader = compile vs_3_0 BumpSpecular_PointLight_VS();
		PixelShader = compile ps_3_0 BumpSpecular_PointLight_PS();
	}
}




struct VS2PS_BumpSpecular_SpotLight
{
	float4 HPos : POSITION;
	float2 NormalMap : TEXCOORD0;
	float3 LightVec : TEXCOORD1;
	float3 HalfVec : TEXCOORD2;
	float3 LightDir : TEXCOORD3;
};

VS2PS_BumpSpecular_SpotLight BumpSpecularSpotLight_VS(APP2VS Input)
{
	VS2PS_BumpSpecular_SpotLight Output = (VS2PS_BumpSpecular_SpotLight)0;

   	// Compensate for lack of UBYTE4 on Geforce3
	Output.HPos = mul(float4(Input.Pos.xyz, 1.0f), _WorldViewProj);

	// Cross product to create BiNormal
	float3 BiNormal = normalize(cross(Input.Tan.xyz, Input.Normal));

	// Need to calculate the WorldI based on each matBone skinning world matrix
	float3x3 TanBasis = float3x3( Input.Tan.xyz, BiNormal, Input.Normal.xyz);
	// Calculate WorldTangent directly... inverse is the transpose for affine rotations
	// float3x3 worldI = transpose(mul(TanBasis, _OneBoneSkinning[IndexArray[0]]));

	// Pass-through texcoords
	Output.NormalMap = Input.TexCoord;

	// Transform Light vec to Object space
	float3 LightVec = _LightPos.xyz - Input.Pos.xyz;
	float3 TanLightVec = mul(LightVec, TanBasis);
	Output.LightVec = TanLightVec;

	// Transform eye Pos to tangent space
	// Gottcha ViewInv[3].xyz is in worldspace... must rewrite..
	float3 ObjEyeVec = _ViewInverseMat[3].xyz - Input.Pos.xyz;
	float3 TanEyeVec = mul(ObjEyeVec, TanBasis);

	Output.HalfVec = normalize(normalize(TanLightVec) + normalize(TanEyeVec));
	// Output.HalfVec = (normalize(TanLightVec) + normalize(TanEyeVec)) * 0.5;

	// Light direction in tangent space
	Output.LightDir = mul(-_LightDir.xyz, TanBasis);

	return Output;
}

float4 BumpSpecularSpotLight_PS(VS2PS_BumpSpecular_SpotLight Input) : COLOR
{
	float OffCenter = dot(normalize(Input.LightVec), Input.LightDir);
	float ConicalAtt = saturate(OffCenter - (1.0 - _ConeAngle)) / _ConeAngle;
	float4 NormalMap = tex2D(Sampler_0, Input.NormalMap);
	float3 ExpNormal = NormalMap.xyz * 2.0 - 1.0;

	float3 NormalizedLightVec = normalize(Input.LightVec);
	float2 IntensityUV = float2(dot(NormalizedLightVec,ExpNormal), dot(Input.HalfVec,ExpNormal));
	float4 RealIntensity = IntensityUV.r + pow(IntensityUV.g, 36.0) * NormalMap.a;
	RealIntensity *= _LightColor;
	float RadialAtt = 1.0 - saturate(dot(Input.LightVec, Input.LightVec) * _AttenuationSqrInv);
	return RealIntensity * ConicalAtt * RadialAtt;
}

technique SpotLight_States <bool Restore = true;>
{
	pass BeginStates
	{
		AlphaBlendEnable = TRUE;
		SrcBlend = DESTALPHA;
		DestBlend = ONE;

		// Normal
		AddressU[0] = WRAP;
		AddressV[0] = WRAP;
		MipFilter[0] = LINEAR;
		MinFilter[0] = LINEAR;
		MagFilter[0] = LINEAR;
	}

	pass EndStates { }
}

technique SpotLight
{
	pass p0
	{
		AlphaBlendEnable = TRUE;
		SrcBlend = DESTALPHA;
		DestBlend = ONE;

		// Normal
		AddressU[0] = WRAP;
		AddressV[0] = WRAP;
		MipFilter[0] = LINEAR;
		MinFilter[0] = LINEAR;
		MagFilter[0] = LINEAR;

 		VertexShader = compile vs_3_0 BumpSpecularSpotLight_VS();
		PixelShader = compile ps_3_0 BumpSpecularSpotLight_PS();
	}
}




struct VS2PS_BumpSpecular_MulDiffuse
{
	float4 HPos : POSITION;
	float2 DiffuseMap : TEXCOORD0;
};

VS2PS_BumpSpecular_MulDiffuse BumpSpecular_MulDiffuse_VS(APP2VS Input)
{
	VS2PS_BumpSpecular_MulDiffuse Output = (VS2PS_BumpSpecular_MulDiffuse)0;

   	// Compensate for lack of UBYTE4 on Geforce3
 	Output.HPos = mul(float4(Input.Pos.xyz, 1.0f), _WorldViewProj);

	// Pass-through texcoords
	Output.DiffuseMap = Input.TexCoord;

	return Output;
}

float4 BumpSpecular_MulDiffuse_PS(VS2PS_BumpSpecular_MulDiffuse Input) : COLOR
{
	return tex2D(Sampler_0, Input.DiffuseMap);
}

technique MulDiffuse
{
	pass p0
	{
		ZFunc = EQUAL;
		ZWriteEnable = FALSE;
		AlphaBlendEnable = TRUE;
		SrcBlend = DESTCOLOR;
		DestBlend = INVSRCALPHA;

		// Diffuse
		AddressU[0] = WRAP;
		AddressV[0] = WRAP;
		MipFilter[0] = LINEAR;
		MinFilter[0] = LINEAR;
		MagFilter[0] = LINEAR;

 		VertexShader = compile vs_3_0 BumpSpecular_MulDiffuse_VS();
		PixelShader = compile ps_3_0 BumpSpecular_MulDiffuse_PS();
	}
}

technique trunk
{
	pass p0
	{
		ZEnable = TRUE;
		ZWriteEnable = TRUE; // FALSE
		AlphaBlendEnable = FALSE;
		AlphaTestEnable = TRUE;
		AlphaRef = 0;
		AlphaFunc = GREATER;

 		VertexShader = compile vs_3_0 BumpSpecular_Blinn_1_VS();
		PixelShader = compile ps_3_0 BumpSpecular_Blinn_1_PS();
	}
}

technique sprite
{
	pass p0
	{
		ZEnable = TRUE; // FALSE
		ZWriteEnable = TRUE; // FALSE
		CullMode = NONE;
		AlphaBlendEnable = FALSE;
		AlphaTestEnable = TRUE;
		AlphaRef = 0;
		AlphaFunc = GREATER;

 		VertexShader = compile vs_3_0 Sprite_VS();
		PixelShader = compile ps_3_0 Sprite_PS();
	}
}
