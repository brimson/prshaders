
/*
	Description: 1,2 bone skinning
 	Author: Mats Dal
*/

/*
	[Uniform data from app]
*/

// Note: Object space light vectors
uniform float4 _SunLightDir : SunLightDirection;
uniform float4 _LightDir : LightDirection;
// uniform float _HemiMapInfo.z : hemiMapInfo.z;
uniform float _NormalOffsetScale : NormalOffsetScale;
// uniform float _HemiMapInfo.w : hemiMapInfo.w;

// Offset x/y _HemiMapInfo.z z / _HemiMapInfo.w w
uniform float4 _HemiMapInfo : HemiMapInfo;

uniform float4 _SkyColor : SkyColor;
uniform float4 _AmbientColor : AmbientColor;
uniform float4 _SunColor : SunColor;

uniform float4 _LightPos : LightPosition;
uniform float _AttenuationSqrInv : AttenuationSqrInv;
uniform float4 _LightColor : LightColor;

uniform float _ShadowAlphaThreshold : SHADOWALPHATHRESHOLD;

uniform float _ConeAngle : ConeAngle;
uniform float4 _WorldEyePos : WorldEyePos;
uniform float4 _ObjectEyePos : ObjectEyePos;

uniform float4x4 _LightViewProj : LIGHTVIEWPROJ;
uniform float4x4 _LightViewProj2 : LIGHTVIEWPROJ2;
uniform float4x4 _LightViewProj3 : LIGHTVIEWPROJ3;
uniform float4 _ViewportMap : VIEWPORTMAP;

uniform dword _StencilRef : STENCILREF = 0;

uniform float4x4 _World : World;
uniform float4x4 _WorldT : WorldT;
uniform float4x4 _WorldView : WorldView;
uniform float4x4 _WorldViewI : WorldViewI; // (WorldViewIT)T = WorldViewI
uniform float4x4 _WorldViewProj : WorldViewProjection;
uniform float4x3 _BoneArray[26] : BoneArray; // : register(c15) < bool sparseArray = true; int arrayStart = 15; >;

uniform float4x4 _LightMat : vpLightMat;
uniform float4x4 _LightTrapezMat : vpLightTrapezMat;

uniform float4 _ParaboloidValues : ParaboloidValues;
uniform float4 _ParaboloidZValues : ParaboloidZValues;

/*
	[Textures and samplers]
*/

uniform texture Texture_0: TEXLAYER0;
uniform texture Texture_1: TEXLAYER1;
uniform texture Texture_2: TEXLAYER2;
uniform texture Texture_3: TEXLAYER3;
uniform texture Texture_4: TEXLAYER4;

#define CREATE_SAMPLER(NAME, TEXTURE) \
	sampler NAME = sampler_state \
	{ \
		Texture = TEXTURE; \
		MipFilter = LINEAR; \
		MinFilter = LINEAR; \
		MagFilter = LINEAR; \
	}; \

CREATE_SAMPLER(Sampler_0, Texture_0)
CREATE_SAMPLER(Sampler_1, Texture_1)
CREATE_SAMPLER(Sampler_2, Texture_2)
CREATE_SAMPLER(Sampler_3, Texture_3)
CREATE_SAMPLER(Sampler_4, Texture_4)

struct APP2VS
{
	float4 Pos : POSITION;
	float3 Normal : NORMAL;
	float BlendWeights : BLENDWEIGHT;
	float4 BlendIndices : BLENDINDICES;
	float2 TexCoord0 : TEXCOORD0;
};

struct APP2VStangent
{
	float4 Pos : POSITION;
	float3 Normal : NORMAL;
	float BlendWeights : BLENDWEIGHT;
	float4 BlendIndices : BLENDINDICES;
	float2 TexCoord0 : TEXCOORD0;
	float3 Tan : TANGENT;
};




#include "shaders/SkinnedMesh_Shared.fx"
#include "shaders/SkinnedMesh_Lighting_PP.fx"
#include "shaders/SkinnedMesh_Lighting_PV.fx"
#include "shaders/SkinnedMesh_HumanSkin.fx"
#include "shaders/SkinnedMesh_ShadowMap.fx"




/*
	Max 2 bones skinning supported!
*/

VertexShader Array_Hemi_Sun_PP_VS[2] =
{
	compile vs_3_0 Hemi_Sun_PP_VS(1),
	compile vs_3_0 Hemi_Sun_PP_VS(2)
};

VertexShader Array_Hemi_Sun_Shadow_PP_VS[2] =
{
	compile vs_3_0 Hemi_Sun_Shadow_PP_VS(1),
	compile vs_3_0 Hemi_Sun_Shadow_PP_VS(2)
};

VertexShader Array_Hemi_Sun_PP_Tangent_VS[2] =
{
	compile vs_3_0 Hemi_Sun_PP_Tangent_VS(1),
	compile vs_3_0 Hemi_Sun_PP_Tangent_VS(2)
};

VertexShader Array_Hemi_Sun_Shadow_PP_Tangent_VS[2] =
{
	compile vs_3_0 Hemi_Sun_Shadow_PP_Tangent_VS(1),
	compile vs_3_0 Hemi_Sun_Shadow_PP_Tangent_VS(2)
};

#define RENDER_HEMI_PP(VERTEXSHADER, PIXELSHADER) \
	CullMode = CCW; \
	AlphaBlendEnable = FALSE; \
	AlphaTestEnable = FALSE; \
	ZEnable = TRUE; \
	ZWriteEnable = TRUE; \
	ZFunc = LESSEQUAL; \
	VertexShader = VERTEXSHADER; \
	PixelShader = compile ps_3_0 PIXELSHADER; \

technique t0_HemiAndSunPP
{
	pass p0
	{
		RENDER_HEMI_PP((Array_Hemi_Sun_PP_VS[1]), Hemi_Sun_PP_PS())
	}

	pass p0
	{
		RENDER_HEMI_PP((Array_Hemi_Sun_Shadow_PP_VS[1]), Hemi_Sun_PP_PS())
	}
}

technique t0_HemiAndSunAndColorPP
{
	pass p0
	{
		RENDER_HEMI_PP((Array_Hemi_Sun_PP_VS[1]), Hemi_Sun_Color_PP_PS())
	}

	pass p1
	{
		RENDER_HEMI_PP((Array_Hemi_Sun_Shadow_PP_VS[1]), Hemi_Sun_Shadow_Color_PP_PS())
	}
}

technique t0_HemiAndSunPPtangent
{
	pass p0
	{
		RENDER_HEMI_PP((Array_Hemi_Sun_PP_Tangent_VS[1]), Hemi_Sun_PP_PS())
	}

	pass p1
	{
		RENDER_HEMI_PP((Array_Hemi_Sun_Shadow_PP_Tangent_VS[1]), Hemi_Sun_PP_PS())
	}
}

technique t0_HemiAndSunAndColorPPtangent
{
	pass p0
	{
		RENDER_HEMI_PP((Array_Hemi_Sun_PP_Tangent_VS[1]), Hemi_Sun_PP_PS())
	}

	pass p1
	{
		RENDER_HEMI_PP((Array_Hemi_Sun_Shadow_PP_Tangent_VS[1]), Hemi_Sun_PP_PS())
	}
}





// Max 2 bones skinning supported!
VertexShader Array_Hemi_Sun_PV_VS[2] =
{
	compile vs_3_0 Hemi_Sun_PV_VS(1),
	compile vs_3_0 Hemi_Sun_PV_VS(2)
};

VertexShader Array_Hemi_Sun_Shadow_Color_PV_VS[2] =
{
	compile vs_3_0 Hemi_Sun_Shadow_Color_PV_VS(1),
	compile vs_3_0 Hemi_Sun_Shadow_Color_PV_VS(2)
};

#define COMMON_RENDERSTATES_HEMI_PV \
	CullMode = CCW; \
	AlphaBlendEnable = FALSE; \
	ZWriteEnable = TRUE; \
	ZFunc = LESSEQUAL; \

technique t0_HemiAndSunPV
{
	pass p0
	{
		COMMON_RENDERSTATES_HEMI_PV
		VertexShader = (Array_Hemi_Sun_PV_VS[1]);
		PixelShader = compile ps_3_0 Hemi_Sun_PV_PS();
	}

	pass p1
	{
		COMMON_RENDERSTATES_HEMI_PV
		ZEnable = TRUE;
		AlphaTestEnable = FALSE;
		VertexShader = (Array_Hemi_Sun_PV_VS[1]);
		PixelShader = compile ps_3_0 Hemi_Sun_PV_PS();
	}
}

technique t0_HemiAndSunAndColorPV
{
	pass p0
	{
		COMMON_RENDERSTATES_HEMI_PV
		VertexShader = (Array_Hemi_Sun_PV_VS[1]);
		PixelShader = compile ps_3_0 Hemi_Sun_PV_PS();
	}
	pass p1
	{
		COMMON_RENDERSTATES_HEMI_PV
		VertexShader = (Array_Hemi_Sun_Shadow_Color_PV_VS[1]);
		PixelShader = compile ps_3_0 Hemi_Sun_PV_PS();
	}
}




/*
	Max 2 bones skinning supported!
*/

VertexShader Array_PointLight_PV_VS[2] =
{
	compile vs_3_0 PointLight_PV_VS(1),
	compile vs_3_0 PointLight_PV_VS(2)
};

VertexShader Array_PointLight_PP_VS[2] =
{
	compile vs_3_0 PointLight_PP_VS(1),
	compile vs_3_0 PointLight_PP_VS(2)
};

VertexShader Array_PointLight_PP_Tangent_VS[2] =
{
	compile vs_3_0 PointLight_PP_Tangent_VS(1),
	compile vs_3_0 PointLight_PP_Tangent_VS(2)
};

#define COMMON_RENDERSTATES_POINTLIGHT \
	AlphaBlendEnable = TRUE; \
	SrcBlend = ONE; \
	DestBlend = ONE; \
	ZWriteEnable = FALSE; \
	ZFunc = EQUAL; \

technique t0_PointLightPV
{
	pass p0
	{
		COMMON_RENDERSTATES_POINTLIGHT
		VertexShader = (Array_PointLight_PV_VS[1]);
		PixelShader = compile ps_3_0 PointLight_PV_PS();
	}
}

technique t0_PointLightPP
{
	pass p0
	{
		COMMON_RENDERSTATES_POINTLIGHT
		VertexShader = (Array_PointLight_PP_VS[1]);
		PixelShader = compile ps_3_0 PointLight_PP_PS();
	}
}

technique t0_PointLightPPtangent
{
	pass p0
	{
		COMMON_RENDERSTATES_POINTLIGHT
		VertexShader = (Array_PointLight_PP_Tangent_VS[1]);
		PixelShader = compile ps_3_0 PointLight_PP_PS();
	}
}




/*
	Spotlight skinnedmesh shaders
*/

VertexShader Array_SpotLight_PV_VS[2] =
{
	compile vs_3_0 SpotLight_PV_VS(1),
	compile vs_3_0 SpotLight_PV_VS(2)
};

VertexShader Array_SpotLight_PP_VS[2] =
{
	compile vs_3_0 SpotLight_PP_VS(1),
	compile vs_3_0 SpotLight_PP_VS(2)
};

VertexShader Array_SpotLight_PP_Tangent_VS[2] =
{
	compile vs_3_0 SpotLight_PP_Tangent_VS(1),
	compile vs_3_0 SpotLight_PP_Tangent_VS(2)
};

#define COMMON_RENDERSTATES_SPOTLIGHT \
	AlphaBlendEnable = TRUE; \
	SrcBlend = ONE; \
	DestBlend = ONE; \
	ZWriteEnable = FALSE; \
	ZFunc = EQUAL; \

technique t0_SpotLightPV
{
	pass p0
	{
		COMMON_RENDERSTATES_SPOTLIGHT
		VertexShader = (Array_SpotLight_PV_VS[1]);
		PixelShader = compile ps_3_0 SpotLight_PV_PS();
	}
}

technique t0_SpotLightPP
{
	pass p0
	{
		COMMON_RENDERSTATES_SPOTLIGHT
		VertexShader = (Array_SpotLight_PP_VS[1]);
		PixelShader = compile ps_3_0 SpotLight_PP_PS();
	}
}

technique t0_SpotLightPPtangent
{
	pass p0
	{
		COMMON_RENDERSTATES_SPOTLIGHT
		VertexShader = (Array_SpotLight_PP_Tangent_VS[1]);
		PixelShader = compile ps_3_0 SpotLight_PP_PS();
	}
}




/*
	Max 2 bones skinning supported!
*/

VertexShader Array_MulDiffuse_VS[2] =
{
	compile vs_3_0 MulDiffuse_VS(1),
	compile vs_3_0 MulDiffuse_VS(2)
};

technique t0_MulDiffuse
{
	pass p0
	{
		AlphaBlendEnable = TRUE;
		SrcBlend = DESTCOLOR;
		DestBlend = ZERO;
		// DestBlend = ONE;

		ZWriteEnable = FALSE;
		ZFunc = EQUAL;

		VertexShader = (Array_MulDiffuse_VS[1]);
		PixelShader = compile ps_3_0 MulDiffuse_PS();
	}
}




/*
	Max 2 bones skinning supported!
*/

#define COMMON_RENDERSTATES_HUMANSKIN \
	CullMode = NONE; \
	AlphaBlendEnable = FALSE; \
	ZEnable = FALSE; \
	ZWriteEnable = FALSE; \
	ZFunc = LESSEQUAL; \
	StencilEnable = FALSE; \

technique humanskinNV
{
	pass pre
	{
		COMMON_RENDERSTATES_HUMANSKIN
		VertexShader = compile vs_3_0 Skin_Pre_VS(2);
		PixelShader = compile ps_3_0 Skin_Pre_PS();
	}

	pass preshadowed
	{
		COMMON_RENDERSTATES_HUMANSKIN
		VertexShader = compile vs_3_0 Skin_Pre_Shadowed_VS(2);
		PixelShader = compile ps_3_0 Skin_Pre_Shadowed_NV_PS();
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

		VertexShader = compile vs_3_0 Skin_Apply_VS(2);
		PixelShader = compile ps_3_0 Skin_Apply_PS();
	}
}

technique humanskin
{
	pass pre
	{
		COMMON_RENDERSTATES_HUMANSKIN
		VertexShader = compile vs_3_0 Skin_Pre_VS(2);
		PixelShader = compile ps_3_0 Skin_Pre_PS();
	}

	pass preshadowed
	{
		COMMON_RENDERSTATES_HUMANSKIN
		VertexShader = compile vs_3_0 Skin_Pre_Shadowed_VS(2);
		PixelShader = compile ps_3_0 Skin_Pre_Shadowed_PS();
	}

	pass apply
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;

		// FillMode = WIREFRAME;

		VertexShader = compile vs_3_0 Skin_Apply_VS(2);
		PixelShader = compile ps_3_0 Skin_Apply_PS();
	}
}




#define RENDER_SKINNEDMESH_SHADOWMAP(CULLMODE, VERTEXSHADER, PIXELSHADER) \
	AlphaBlendEnable = FALSE; \
	ZEnable = TRUE; \
	ZWriteEnable = TRUE; \
	ZFunc = LESSEQUAL; \
	ScissorTestEnable = TRUE; \
	VertexShader = compile vs_3_0 VERTEXSHADER; \
	PixelShader = compile ps_3_0 PIXELSHADER; \

technique DrawShadowMap
{
	pass directionalspot
	{
		#if NVIDIA
			ColorWriteEnable = 0;//0x0000000F;
		#endif

		// RENDER_SKINNEDMESH_SHADOWMAP(CW, ShadowMap_VS(), ShadowMap_PS())
		RENDER_SKINNEDMESH_SHADOWMAP(NONE, ShadowMap_VS(), ShadowMap_PS())
	}

	pass directionalspotalpha
	{
		#if NVIDIA
			ColorWriteEnable = 0; // 0x0000000F;
			AlphaTestEnable = TRUE;
			AlphaRef = 0;
		#endif

		// RENDER_SKINNEDMESH_SHADOWMAP(CCW, ShadowMap_Alpha_VS(), ShadowMap_Alpha_PS())
		RENDER_SKINNEDMESH_SHADOWMAP(NONE, ShadowMap_Alpha_VS(), ShadowMap_Alpha_PS())
	}

	pass point_
	{
		#if NVIDIA
			ColorWriteEnable = 0; // 0x0000000F;
		#endif

		RENDER_SKINNEDMESH_SHADOWMAP(NONE, ShadowMap_VS(), ShadowMap_PS())
	}
}

// #endif

// We actually don't need to have 2 techniques here
// but it is kept for back-compatibility with original BF2
technique DrawShadowMapNV
{
	pass directionalspot
	{
		#if NVIDIA
			ColorWriteEnable = 0;//0x0000000F;
		#endif

		RENDER_SKINNEDMESH_SHADOWMAP(CW, ShadowMap_VS(), ShadowMap_PS())
		RENDER_SKINNEDMESH_SHADOWMAP(NONE, ShadowMap_VS(), ShadowMap_PS())
	}

	pass directionalspotalpha
	{
		#if NVIDIA
			ColorWriteEnable = 0; // 0x0000000F;
			AlphaTestEnable = TRUE;
			AlphaRef = 0;
		#endif

		// RENDER_SKINNEDMESH_SHADOWMAP(CCW, ShadowMap_Alpha_VS(), ShadowMap_Alpha_PS())
		RENDER_SKINNEDMESH_SHADOWMAP(NONE, ShadowMap_Alpha_VS(), ShadowMap_Alpha_PS())
	}

	pass point_
	{
		#if NVIDIA
			ColorWriteEnable = 0; // 0x0000000F;
		#endif

		RENDER_SKINNEDMESH_SHADOWMAP(NONE, ShadowMap_VS(), ShadowMap_PS())
	}
}
// #endif

#include "shaders/SkinnedMesh_r3x0.fx"
