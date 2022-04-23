#include "shaders/raCommon.fx"

/*

#define USE_FRESNEL
#define USE_SPECULAR
#define USE_SHADOWS
#define PIXEL_CAMSPACE
#define USE_3DTEXTURE

*/

// Affects how transparency is claculated depending on camera height.
// Try increasing/decreasing ADD_ALPHA slighty for different results
#define MAX_HEIGHT 20
#define ADD_ALPHA 0.75


// Darkness of water shadows - Lower means darker
#define SHADOW_FACTOR 0.75

// Higher value means less transparent water
#define BASE_TRANSPARENCY 1.5F

// Like specular - higher values gives smaller, more distinct area of transparency
#define POW_TRANSPARENCY 30.F

// How much of the texture color to use (vs envmap color)
#define COLOR_ENVMAP_RATIO 0.4F

// Modifies heightalpha (for tweaking transparancy depending on depth)
#define APOW 1.3

//Wether to use normalmap for transparency calculation or not
//#define FRESNEL_NORMALMAP


//////////////////////////////////////////////////////////////////////////////////

/*float uvLevelAddX;
float uvLevelMulX;
float uvLevelAddY;
float uvLevelMulY;*/

float4 LightMapOffset;


float WaterHeight;

Light Lights[1];

float4	WorldSpaceCamPos;
float4	WaterScroll;

float	WaterCycleTime;

float4	SpecularColor;
float	SpecularPower;
float4	WaterColor;
float4	PointColor;

#ifdef DEBUG
#define _WaterColor float4(1,0,0,1)
#else
#define _WaterColor WaterColor
#endif

texture	CubeMap;
sampler CubeMapSampler = sampler_state
{
	Texture = (CubeMap);
	MipFilter = LINEAR; //Rasterizing speedup
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
	AddressW  = WRAP;
	MipMapLodBias = 0;
};

#ifdef USE_3DTEXTURE

texture	WaterMap;
sampler WaterMapSampler = sampler_state
{
	Texture = (WaterMap);
	MipFilter = LINEAR; //Rasterizing speedup
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
	AddressW  = WRAP;
	MipMapLodBias = 0;
};

#else

texture	WaterMapFrame0;
sampler WaterMapSampler0 = sampler_state
{
	Texture = (WaterMapFrame0);
	MipFilter = LINEAR; //Rasterizing speedup
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
	MipMapLodBias = 0;
};

texture	WaterMapFrame1;
sampler WaterMapSampler1 = sampler_state
{
	Texture = (WaterMapFrame1);
	MipFilter = LINEAR; //Rasterizing speedup
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
	MipMapLodBias = 0;
};

#endif

texture LightMap;
sampler LightMapSampler = sampler_state
{
	Texture = (LightMap);
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
	MipMapLodBias = 0;
};

struct VS_OUTPUT_WATER
{
	float4 Pos		: POSITION;
//	float4 Color		: COLOR;
	float  Fog		: FOG;
#ifdef USE_3DTEXTURE
	float3 Tex		: TEXCOORD0;
#else
	float2 Tex		: TEXCOORD0;
#endif
#ifndef NO_LIGHTMAP
	float2 lmtex		: TEXCOORD1;
#endif
	float3 Position	: TEXCOORD2;
#ifdef USE_SHADOWS
	float4 TexShadow	: TEXCOORD3;
#endif

};

string reqVertexElement[] = 
{
	"Position",
	"TLightMap2D"
};


string GlobalParameters[] =
{
 	"WorldSpaceCamPos",
	"FogRange", 
	"FogColor", 
	"WaterCycleTime",	
	"WaterScroll",		
#ifdef USE_3DTEXTURE
 	"WaterMap",
#else
	"WaterMapFrame0",
	"WaterMapFrame1",
#endif
	"WaterHeight",
 	"WaterColor",
//	"ShadowMap"

};

string InstanceParameters[] =
{
 	"ViewProjection",
	"CubeMap",
 	"LightMap",
 	"LightMapOffset",
#ifdef USE_SPECULAR
 	"SpecularColor",
 	"SpecularPower",
#endif

#ifdef USE_SHADOWS
	"ShadowProjMat",
	"ShadowTrapMat",
	"ShadowMap",
#endif
	"PointColor",
	"Lights",
	"World"
};


VS_OUTPUT_WATER waterVertexShader
(
float4 inPos	: POSITION0,
float2 lmtex	: TEXCOORD1
)
{
	VS_OUTPUT_WATER Out;// = (VS_OUTPUT_WATER)0;

	float4 wPos		= mul(inPos, World);
	
	//float h = (WorldSpaceCamPos.y - WaterHeight);
	//wPos.y += h/500;
	
	Out.Pos		= mul(wPos, ViewProjection);

#ifdef PIXEL_CAMSPACE
	Out.Position = wPos;
#else
	Out.Position = -(WorldSpaceCamPos - wPos) * 0.02;
#endif

#ifdef USE_3DTEXTURE
	float3 tex;
	tex.xy = (wPos.xz / float2(29.13, 31.81));//+ frameTime*1;	
	tex.xy += (WaterScroll.xy * WaterCycleTime);
	tex.z = WaterCycleTime*10 + (tex.x*0.7 + tex.y*1.13); //(inPos.x + inPos.y) / 100;
#else
	float2 tex;
	tex.xy = (wPos.xz / float2(99.13, 71.81));//+ frameTime*1;	
	//tex.xy += WaterCycleTime;
#endif

	Out.Tex = tex;

#ifndef NO_LIGHTMAP
	Out.lmtex.xy = lmtex.xy * LightMapOffset.xy + LightMapOffset.zw;
#endif
	Out.Fog		= Calc_Fog(Out.Pos.w);

#ifdef USE_SHADOWS
	Out.TexShadow = Calc_Shadow_Projection(wPos);
#endif

	return Out;
}

#define INV_LIGHTDIR float3(0.4,0.5,0.6)

float4 Water
(
in VS_OUTPUT_WATER VsData
) : COLOR
{
	float4 finalColor;
	
#ifdef NO_LIGHTMAP // F85BD0
	float4 lightmap = PointColor; //float4(1, StaticGloss, 0.8, 1);
#else
	float4 lightmap = tex2D(LightMapSampler, VsData.lmtex);
#endif

#ifdef USE_3DTEXTURE
	float3 TN = tex3D(WaterMapSampler, VsData.Tex);
#else
	float3 TN = lerp(tex2D(WaterMapSampler0, VsData.Tex), tex2D(WaterMapSampler1, VsData.Tex), WaterCycleTime);
#endif

#ifdef TANGENTSPACE_NORMALS
	TN.rbg = normalize((TN.rgb * 2) - 1);
#else
	TN.rgb = (TN.rgb * 2)-1;
#endif

#ifdef USE_FRESNEL
#ifdef FRESNEL_NORMALMAP
	float4 TN2 = float4(TN, 1);
#else
	float4 TN2 = float4(0,1,0,0);
#endif
#endif

#ifdef PIXEL_CAMSPACE
	float3 lookup = -(WorldSpaceCamPos - VsData.Position);
#else
	float3 lookup = VsData.Position;
#endif

	float3 reflection = reflect(lookup, TN);
	float3 envcol = texCUBE(CubeMapSampler, reflection);

#ifdef USE_SPECULAR
	float specular = saturate(dot(-Lights[0].dir, normalize(reflection)));
	specular = pow(specular, SpecularPower) * SpecularColor.a;
#endif

#ifdef USE_FRESNEL
	float fresnel = BASE_TRANSPARENCY - pow(dot(normalize(lookup), TN2), POW_TRANSPARENCY);
#endif

	float shadFac = lightmap.g;
#ifdef USE_SHADOWS
	shadFac *= Get_Shadow_Factor(ShadowMapSampler, VsData.TexShadow);
#endif
	float lerpMod = -(1 - saturate(shadFac+SHADOW_FACTOR));


#ifdef USE_SPECULAR
	finalColor.rgb = (specular * SpecularColor * shadFac) + lerp(_WaterColor, envcol, COLOR_ENVMAP_RATIO + lerpMod);
	//finalColor.rgb = (specular * SpecularColor * shadFac) + lerp(_WaterColor, envcol, saturate(lightmap.g * 0.5 + 0.1));
#else
	finalColor.rgb = lerp(_WaterColor.rgb, envcol, COLOR_ENVMAP_RATIO + lerpMod);
#endif

#ifdef USE_FRESNEL
	finalColor.a =  lightmap.r * fresnel + _WaterColor.w;// - 0.15;//pow(lightmap.r, 1.0);// * 0.5;
#else
	finalColor.a = lightmap.r + _WaterColor.w;// * 0.9; //fresnel * pow(lightmap.r, APOW);
#endif

    if (FogColor.r < 0.01){
        finalColor.rgb = float3(lerp(0.3,0.1,TN.r),1,0);
    }
    

	return finalColor;
}



technique defaultShader
{
	pass P0
	{
		vertexshader	= compile vs_2_a waterVertexShader();
		pixelshader		= compile ps_2_a Water();

		fogenable		= true;

#ifdef ENABLE_WIREFRAME
		FillMode		= WireFrame;
#endif
		CullMode		= NONE;
		AlphaBlendEnable= true;
		AlphaTestEnable = true;
		alpharef = 1;
		//depthfunct = always;

		SrcBlend		= SRCALPHA;
		DestBlend		= INVSRCALPHA;
	}
}
