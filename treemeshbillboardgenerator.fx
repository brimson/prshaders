#line 2 "TreeMeshBillboardGenerator.fx"

/*
	[Uniform data from app]
*/

uniform float4x4 _WorldViewProj : WorldViewProjection; // : register(vs_3_0, c0);
uniform float4x4 _WorldInverseMat : WorldI; // : register(vs_3_0, c4);
uniform float4x4 _ViewInverseMat : ViewI; // : register(vs_3_0, c8);
// uniform float4x3 _OneBoneSkinning[26] : matONEBONESKINNING; // : register(vs_3_0, c15);

// Sprite parameters
uniform float4x4 _WorldViewMat : WorldView;
uniform float4x4 _ProjMat : Projection;
uniform float4 _SpriteScale :  SpriteScale;
uniform float4 _ShadowSpherePoint : ShadowSpherePoint;
uniform float4 _BoundingboxScaledInvGradientMag : BoundingboxScaledInvGradientMag;
uniform float4 _InvBoundingBoxScale : InvBoundingBoxScale;
uniform float4 _ShadowColor : ShadowColor;
uniform float4 _LightColor : LightColor;

uniform float4 _AmbColor : Ambient = { 0.0f, 0.0f, 0.0f, 1.0f };
uniform float4 _DiffColor : Diffuse = { 1.0f, 1.0f, 1.0f, 1.0f };
uniform float4 _SpecColor : Specular = { 0.0f, 0.0f, 0.0f, 1.0f };

uniform dword _ColorWriteEnable : ColorWriteEnable;

uniform float4 _EyePos : EyePosition = { 0.0f, 0.0f, 1.0f, 0.0f };

uniform float4 _LightPos : LightPosition
<
	string Object = "PointLight";
	string Space = "World";
> = {0.0f, 0.0f, 1.0f, 1.f};

/*
	[Textures and samplers]
*/

uniform texture Diffuse_Texture: TEXLAYER0
<
	string File = "default_color.dds";
	string TextureType = "2D";
>;

uniform texture Normal_Texture: TEXLAYER1
<
	string File = "bumpy_flipped.dds";
	string TextureType = "2D";
>;

uniform texture Color_LUT: TEXLAYER2
<
	string File = "default_sdgbmfbf_color_lut.dds";
	string TextureType = "2D";
>;

// uniform texture Normal_Texture: NormalMap;
// uniform texture Color_LUT: LUTMap;

sampler Diffuse_Sampler = sampler_state
{
	Texture = <Diffuse_Texture>;
	// Target = Texture2D;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
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




struct VS2PS_BumpSpecular_Blinn_1
{
	float4 HPos : POSITION;
	float2 TexCoord : TEXCOORD0;
	float2 TexCoord2 : TEXCOORD1;
	float4 LightVec : TEXCOORD2;
	float4 HalfVec : TEXCOORD3;
	float4 Diffuse : COLOR0;
};

VS2PS_BumpSpecular_Blinn_1 BumpSpecular_Blinn_1_VS(APP2VS Input)
{
	VS2PS_BumpSpecular_Blinn_1 Output = (VS2PS_BumpSpecular_Blinn_1)0;

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
	Output.Diffuse = saturate(float4(float3(Color), 1.0f));

	return Output;
}

float4 BumpSpecular_Blinn_1_PS(VS2PS_BumpSpecular_Blinn_1 Input) : COLOR
{
	float4 DiffuseMap = tex2D(Diffuse_Sampler, Input.TexCoord);
	return DiffuseMap * Input.Diffuse;
}

float4 BumpSpecular_Blinn_1_Alpha_PS(VS2PS_BumpSpecular_Blinn_1 Input) : COLOR
{
	float4 DiffuseMap = tex2D(Diffuse_Sampler, Input.TexCoord);
	return 1.0 - DiffuseMap.a;
}

technique trunk
{
	pass p0
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE; // TRUE
		ColorWriteEnable = (_ColorWriteEnable);
		AlphaBlendEnable = FALSE;
		AlphaTestEnable = TRUE;
		AlphaRef = 0;
		AlphaFunc = GREATER;

 		VertexShader = compile vs_3_0 BumpSpecular_Blinn_1_VS();
		PixelShader = compile ps_3_0 BumpSpecular_Blinn_1_PS();
	}
}

technique branch
{
	pass p0
	{

		ZEnable = TRUE;
		ZWriteEnable = FALSE; // TRUE
		ColorWriteEnable = (_ColorWriteEnable);
		CullMode = NONE;
		AlphaBlendEnable = TRUE;
		SrcBlend = D3DBLEND_SRCALPHA;
		DestBlend = D3DBLEND_INVSRCALPHA;

		AlphaTestEnable = FALSE;
		AlphaRef = 0;
		AlphaFunc = GREATER;

 		VertexShader = compile vs_3_0 BumpSpecular_Blinn_1_VS();
		PixelShader = compile ps_3_0 BumpSpecular_Blinn_1_PS();
	}
}

technique alpha
{
	pass p0
	{
		ColorWriteEnable = (_ColorWriteEnable);
		AlphaBlendEnable = TRUE;
		CullMode = NONE;
		ZWriteEnable = FALSE;
		SrcBlend = D3DBLEND_DESTCOLOR;
		DestBlend = D3DBLEND_ZERO;
		AlphaTestEnable = FALSE;

 		VertexShader = compile vs_3_0 BumpSpecular_Blinn_1_VS();
		PixelShader = compile ps_3_0 BumpSpecular_Blinn_1_Alpha_PS();
	}
}




struct VS2PS_Sprite
{
	float4 HPos : POSITION;
	float2 TexCoord : TEXCOORD0;
	float4 Diffuse : COLOR0;
};

VS2PS_Sprite Sprite_VS(APP2VS Input)
{
	VS2PS_Sprite Output = (VS2PS_Sprite)0;
	float2 Width_Height = Input.TexCoord1;
	float4 Pos =  mul(Input.Pos, _WorldViewMat);
	float4 scaledPos = float4(float2(Width_Height * _SpriteScale.xy), 0.0, 0.0) + Pos;
 	Output.HPos = mul(scaledPos, _ProjMat);
	Output.TexCoord = Input.TexCoord;

	// Lighting calc
	float4 EyeSpaceSherePoint = mul(_ShadowSpherePoint, _WorldViewMat);
	float4 ShadowSpherePos = scaledPos * _InvBoundingBoxScale;
	float4 EyeShadowSpherePos = EyeSpaceSherePoint * _InvBoundingBoxScale;
	float4 VectorMagnitude = normalize(ShadowSpherePos - EyeShadowSpherePos);
	float ShadowFactor = VectorMagnitude * _BoundingboxScaledInvGradientMag;
	ShadowFactor = min(ShadowFactor, 1.0);
	float3 ShadowColorInt = _ShadowColor * (1.0 - ShadowFactor);
	float3 Color = _LightColor.rgb * ShadowFactor + ShadowColorInt;
	Output.Diffuse = saturate(float4(Color, 1.0f));

	return Output;
}

float4 Sprite_PS(VS2PS_Sprite Input) : COLOR
{
	float4 DiffuseMap = tex2D(Diffuse_Sampler, Input.TexCoord);
	return DiffuseMap * Input.Diffuse;
}

float4 Sprite_Alpha_PS(VS2PS_Sprite Input) : COLOR
{
	float4 DiffuseMap = tex2D(Diffuse_Sampler, Input.TexCoord);
	return 1.0 - DiffuseMap.a;
}

technique sprite
{
	pass p0
	{

		ZEnable = TRUE; // FALSE
		ZWriteEnable = FALSE;
		CullMode = NONE;
		AlphaBlendEnable = TRUE;
		SrcBlend = D3DBLEND_SRCALPHA;
		DestBlend = D3DBLEND_INVSRCALPHA;
		AlphaTestEnable = FALSE;
		AlphaRef = 0;
		AlphaFunc = GREATER;

 		VertexShader = compile vs_3_0 Sprite_VS();
		PixelShader = compile ps_3_0 Sprite_PS();
	}
}

technique alphaSprite
{
	pass p0
	{
		ColorWriteEnable = (_ColorWriteEnable);
		AlphaBlendEnable = TRUE;
		CullMode = NONE;
		ZWriteEnable = FALSE;
		SrcBlend = D3DBLEND_DESTCOLOR;
		DestBlend = D3DBLEND_ZERO;
		AlphaTestEnable = FALSE;

 		VertexShader = compile vs_3_0 Sprite_VS();
		PixelShader = compile ps_3_0 Sprite_Alpha_PS();
	}
}
