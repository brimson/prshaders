#line 2 "RoadCompiled.fx"
#include "shaders/raCommon.fx"

float4x4	mWorldViewProj : WorldViewProjection;
float		fTexBlendFactor : TexBlendFactor;
float2		vFadeoutValues : FadeOut;
float4		vLocalEyePos : LocalEye;
float4		vCameraPos : CAMERAPOS;
float		vScaleY : SCALEY;
float4		vSunColor : SUNCOLOR;
float4 		vGIColor : GICOLOR;

float4		vTexProjOffset : TEXPROJOFFSET;
float4		vTexProjScale : TEXPROJSCALE;

texture detail0 : TEXLAYER3;
texture detail1 : TEXLAYER4;
texture lighting : TEXLAYER2;

sampler sampler0 = sampler_state
{
	Texture 		= (detail0);
	AddressU 		= CLAMP;
	AddressV 		= WRAP;
	MipFilter 		= FILTER_ROAD_MIP;
	MinFilter 		= FILTER_ROAD_DIFF_MIN;
	MagFilter 		= FILTER_ROAD_DIFF_MAG;
#ifdef FILTER_ROAD_DIFF_MAX_ANISOTROPY
	MaxAnisotropy 	= FILTER_ROAD_DIFF_MAX_ANISOTROPY;
#endif
};
sampler sampler1 = sampler_state
{
	Texture 		= (detail1);
	AddressU 		= WRAP;
	AddressV 		= WRAP;
	MipFilter 		= FILTER_ROAD_MIP;
	MinFilter 		= FILTER_ROAD_DIFF_MIN;
	MagFilter 		= FILTER_ROAD_DIFF_MAG;
#ifdef FILTER_ROAD_DIFF_MAX_ANISOTROPY
	MaxAnisotropy 	= FILTER_ROAD_DIFF_MAX_ANISOTROPY;
#endif
};
sampler sampler2 = sampler_state
{
	Texture = (lighting);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
};
struct APP2VS
{
	float4 Pos	: POSITION;
	float2 Tex0	: TEXCOORD0;
	float2 Tex1	: TEXCOORD1;
//	float4 MorphDelta: POSITION1;
	float  Alpha    : TEXCOORD2;
};

struct VS2PS
{
    float4	Pos : POSITION;
    float2	Tex0 : TEXCOORD0;
    float2	Tex1 : TEXCOORD1;
    float4	PosTex : TEXCOORD2;
    float  ZFade : COLOR;
    float  Fog  : FOG;
};

float4 projToLighting(float4 hPos)
{
	float4 tex;

	//tl: This has been rearranged optimally (I believe) into 1 MUL and 1 MAD,
	//    don't change this without thinking twice. 
	//    ProjOffset now includes screen->texture bias as well as half-texel offset
	//    ProjScale is screen->texture scale/invert operation
	// tex = (hpos.x * 0.5 + 0.5 + htexel, hpos.y * -0.5 + 0.5 + htexel, hpos.z, hpos.w)
 	tex = hPos * vTexProjScale + (vTexProjOffset * hPos.w);

	return tex;
}

VS2PS RoadCompiledVS(APP2VS input)
{
	VS2PS outdata;

	float4 wPos = input.Pos;
	
	float cameraDist = length(vLocalEyePos.xyz - input.Pos.xyz);
	float interpVal = saturate(cameraDist * vFadeoutValues.x - vFadeoutValues.y);
//	wPos.y += 0.01 * (1-interpVal);
	wPos.y += .01;
	
	outdata.Pos = mul(wPos, mWorldViewProj);

	
//	outdata.PosTex.xy = outdata.Pos.xy/outdata.Pos.w;
// 	outdata.PosTex.xy = (outdata.PosTex.xy + 1) / 2;
// 	outdata.PosTex.y = 1-outdata.PosTex.y;
// 	outdata.PosTex.xy = outdata.PosTex.xy * outdata.Pos.w;
//	outdata.PosTex.zw = outdata.Pos.zw;
	
	outdata.PosTex = projToLighting(outdata.Pos);
	
	outdata.Tex0.xy = input.Tex0;
	outdata.Tex1 = input.Tex1;
	
	outdata.ZFade = 1 - saturate((cameraDist * vFadeoutValues.x) - vFadeoutValues.y);
	outdata.ZFade *= input.Alpha;
	
	outdata.Fog = calcFog(cameraDist);
	
	return outdata;
}


float4 RoadCompiledPS(VS2PS indata) : COLOR0
{	
	float4 t0 = tex2D(sampler0, indata.Tex0);
	float4 t1 = tex2D(sampler1, indata.Tex1*0.1);
	float4 color;
	color.rgb = lerp(t1, t0, fTexBlendFactor);
	color.a = t0.a * indata.ZFade;
    
    float4 accumlights = tex2Dproj(sampler2, indata.PosTex);
    float4 light;
    if (FogColor.r < 0.01)
    {
        // On thermals no shadows
        light = (vSunColor * 2 + accumlights) * 2;
        color.rgb *= light.xyz;
        color.g = clamp(color.g, 0, 0.5);
    }
    else
    {
        light = ((accumlights.w * vSunColor * 2) + accumlights) * 2;
        color.rgb *= light.xyz;
    }
	
	

	return color;
}

struct VS2PSDx9
{
    float4	Pos : POSITION;
    float2	Tex0 : TEXCOORD0;
    float2	Tex1 : TEXCOORD1;
    float    ZFade : COLOR;
    float Fog : FOG;
};

VS2PSDx9 RoadCompiledVSDx9(APP2VS input)
{
	VS2PSDx9 outdata;
	outdata.Pos = mul(input.Pos, mWorldViewProj);
		
	outdata.Tex0.xy = input.Tex0;
	outdata.Tex1 = input.Tex1;
	
	float3 dist = (vLocalEyePos.xyz - input.Pos.xyz);
	outdata.ZFade = dot(dist, dist);
	outdata.ZFade = (outdata.ZFade - vFadeoutValues.x) * vFadeoutValues.y;
	outdata.ZFade = 1 - saturate(outdata.ZFade);
	
	outdata.Fog = calcFog(length(dist));
	
	return outdata;
}

float4 RoadCompiledPSDx9(VS2PSDx9 indata) : COLOR0
{
	float4 t0 = tex2D(sampler0, indata.Tex0);
	float4 t1 = tex2D(sampler1, indata.Tex1);

	float4 final;
	final.rgb = lerp(t1, t0, fTexBlendFactor);
	final.a = t0.a * indata.ZFade;
	return final;
}

technique roadcompiledFull
<
	int DetailLevel = DLHigh+DLNormal+DLLow+DLAbysmal;
	int Compatibility = CMPR300+CMPNV2X;
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
		{ 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0 },
		{ 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 1 },
//		{ 0, D3DDECLTYPE_FLOAT4, D3DDECLUSAGE_POSITION, 1 },
		{ 0, D3DDECLTYPE_FLOAT1, D3DDECLUSAGE_TEXCOORD, 2 },
		DECLARATION_END	// End macro
	};
	int TechniqueStates = D3DXFX_DONOTSAVESHADERSTATE;
>
{
	pass NV3x
	{
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
//		DepthBias = -0.0001f;
//		SlopeScaleDepthBias = -0.00001f;
//		FillMode = WIREFRAME;
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		FogEnable = true;
		VertexShader = compile vs_2_a RoadCompiledVS();
		PixelShader = compile ps_2_a RoadCompiledPS();
	}

	pass DirectX9
	{
		AlphaBlendEnable = FALSE;
		//AlphaBlendEnable = TRUE;
		//SrcBlend = SRCALPHA;
		//DestBlend = INVSRCALPHA;
		DepthBias = -0.0001f;
		SlopeScaleDepthBias = -0.00001f;
		ZEnable = FALSE;
//		FillMode = WIREFRAME;
		VertexShader = compile vs_2_a RoadCompiledVSDx9();
		PixelShader = compile ps_2_a RoadCompiledPSDx9();
	}
}

float4 RoadCompiledPS_LightingOnly(VS2PS indata) : COLOR0
{
//	float4 t0 = tex2D(sampler0, indata.Tex0AndZFade);
//	float4 t2 = tex2D(sampler2, indata.PosTex);

//	float4 final;
//	final.rgb = t2;
//	final.a = t0.a * indata.Tex0AndZFade.z;
//	return final;
return 0;
}

technique roadcompiledLightingOnly
<
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
		{ 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0 },
		{ 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 1 },
		{ 0, D3DDECLTYPE_FLOAT4, D3DDECLUSAGE_POSITION, 1 },
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		DepthBias = -0.000025;
		//SlopeScaleDepthBias = -0.5;
		ZEnable = FALSE;
//CullMode = NONE;
//FillMode = WIREFRAME;	
		VertexShader = compile vs_2_a RoadCompiledVS();
		PixelShader = compile ps_2_a RoadCompiledPS_LightingOnly();
	}
}
