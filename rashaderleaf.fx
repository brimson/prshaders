
// Speed to always add to wind, decrease for less movement
#define WIND_ADD 5

#define LEAF_MOVEMENT 1024

#ifndef _HASSHADOW_
#define _HASSHADOW_ 0
#endif

#include "shaders/RaCommon.fx"
 
//float3	TreeSkyColor;
float4 	OverGrowthAmbient;
Light	Lights[1];
float4	PosUnpack;
float2	NormalUnpack;
float	TexUnpack;
float	ObjRadius = 2;

struct VS_OUTPUT
{
	float4 Pos	: POSITION0;
	float2 Tex0	: TEXCOORD0;
#if _HASSHADOW_
	float4 TexShadow	: TEXCOORD1;
#endif
	float4 Color  : COLOR0;
	float Fog	: FOG;
};

texture	DiffuseMap;
sampler DiffuseMapSampler = sampler_state
{
	Texture = (DiffuseMap);
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
	MipMapLodBias = 0;
};

// INPUTS TO THE VERTEX SHADER FROM THE APP
string reqVertexElement[] = 
{
#ifdef OVERGROWTH	//tl: TODO - Compress overgrowth patches as well.
 	"Position",
 	"Normal",
	"TBase2D"
#else
 	"PositionPacked",
 	"NormalPacked8",
	"TBasePacked2D"
#endif
};

VS_OUTPUT basicVertexShader
(
	float4 inPos: POSITION0,
	float3 normal: NORMAL,
	float2 tex0	: TEXCOORD0
)
{
	VS_OUTPUT Out = (VS_OUTPUT)0;

#ifndef OVERGROWTH
	inPos *= PosUnpack;
	WindSpeed += WIND_ADD;
	inPos.xyz +=  sin((GlobalTime / (ObjRadius + inPos.y)) * WindSpeed) * (ObjRadius + inPos.y) * (ObjRadius + inPos.y) / LEAF_MOVEMENT;// *  WindSpeed / 16384;//clamp(abs(inPos.z * inPos.x), 0, WindSpeed);
#endif
	Out.Pos		= mul(float4(inPos.xyz, 1), WorldViewProjection);

	Out.Fog		= Calc_Fog(Out.Pos.w);
	Out.Tex0	= tex0;

#ifdef OVERGROWTH
	Out.Tex0 /= 32767.0f;
 	normal = normal * 2.0f - 1.0f;
#else
  	normal = normal * NormalUnpack.x + NormalUnpack.y;
	Out.Tex0 *= TexUnpack;
#endif	
	
#ifdef _POINTLIGHT_
	float3 lightVec = float3(Lights[0].pos.xyz - inPos);
	float LdotN	= 0.125;//saturate( (dot(normal, -normalize(lightVec))));
#else
	float LdotN	= saturate( (dot(normal, -Lights[0].dir ) + 0.6 ) / 1.4 );
#endif

#ifdef OVERGROWTH
	Out.Color.rgb = Lights[0].color * (inPos.w / 32767) * LdotN* (inPos.w / 32767) ;
	OverGrowthAmbient *= (inPos.w / 32767);
#else	
	Out.Color.rgb = Lights[0].color * LdotN;
#endif

#if _HASSHADOW_
	Out.TexShadow = Calc_Shadow_Projection(float4(inPos.xyz, 1));
#elif !defined(_POINTLIGHT_)
	Out.Color.rgb += OverGrowthAmbient;
#endif

#ifdef _POINTLIGHT_
	Out.Color.rgb *= 1 - saturate(dot(lightVec, lightVec) * Lights[0].attenuation * 0.1);
	Out.Color.rgb *= Calc_Fog(Out.Pos.w);
#endif
	Out.Color.a = Transparency;
	Out.Color = Out.Color * 0.5;

	return Out;
}

float4 basicPixelShader(VS_OUTPUT VsOut) : COLOR
{
	float4 vertexColor = float4(VsOut.Color.rgb, VsOut.Color.a*2);
	float4 diffuseMap = tex2D(DiffuseMapSampler, VsOut.Tex0);

#if _HASSHADOW_
	vertexColor.rgb *= saturate(Get_Shadow_Factor(ShadowMapSampler, VsOut.TexShadow, 1)+0.6667);
	vertexColor.rgb += OverGrowthAmbient/2;
#endif

float4 outCol;
#ifdef _POINTLIGHT_
    outCol = diffuseMap * vertexColor;
    outCol.a *= 2;
#else
	//tl: use compressed color register to avoid this being compiled as a 2.0 shader.
    outCol = (diffuseMap * vertexColor) * 2;
#endif
	
#if defined(OVERGROWTH) && HASALPHA2MASK
	outCol.a *= 2 * diffuseMap.a;
#endif

	return outCol;
};

float4 basicPixelShaderNoShadow(VS_OUTPUT VsOut) : COLOR
{
    float4 vertexColor = float4(VsOut.Color.rgb, VsOut.Color.a*2);
    float4 diffuseMap = tex2D(DiffuseMapSampler, VsOut.Tex0);
    float4 outCol;
#ifdef _POINTLIGHT_
    outCol = diffuseMap * vertexColor;
    outCol.a *= 2;
#else
    outCol = (diffuseMap * vertexColor) * 2;
#endif

#if defined(OVERGROWTH) && HASALPHA2MASK
    outCol.a *= 2 * diffuseMap.a;
#endif
    return outCol;
}

string GlobalParameters[] =
{
#if _HASSHADOW_
	"ShadowMap",
#endif
	"GlobalTime",
	"FogRange",
#ifndef _POINTLIGHT_
	"FogColor"
#endif
};

string InstanceParameters[] =
{
#if _HASSHADOW_
	"ShadowProjMat",
	"ShadowTrapMat",
#endif
	"WorldViewProjection",
	"Transparency",
	"WindSpeed",
	"Lights",
#ifndef _POINTLIGHT_
	"OverGrowthAmbient"
#endif
};

string TemplateParameters[] = 
{
	"DiffuseMap",
	"PosUnpack",
	"NormalUnpack",
	"TexUnpack"
};

technique defaultTechnique
{
	pass P0
	{
		vertexShader		= compile vs_2_a basicVertexShader();
#if _HASSHADOW_
		pixelShader			= compile ps_2_a basicPixelShader();
#else
        pixelShader			= compile ps_2_a basicPixelShaderNoShadow();
#endif
#ifdef ENABLE_WIREFRAME
		FillMode			= WireFrame;
#endif

#if HASALPHA2MASK
		Alpha2Mask = 1;
#endif

		AlphaTestEnable		= true;

		AlphaRef			= 127;
		SrcBlend			= < _SrcBlend >;
		DestBlend			= < _DestBlend >;

#ifdef _POINTLIGHT_
		FogEnable			= false;
		AlphaBlendEnable	= true;
	SrcBlend			= one;
	DestBlend			= one;
#else
		AlphaBlendEnable	= false;
		FogEnable			= true;
#endif
		CullMode			= NONE;
	}
}
