#include "shaders/RaCommon.fx"

#define LIGHT_MUL float3(0.8, 0.8, 0.4)
#define LIGHT_ADD float3(0.4, 0.4, 0.4)

float3	TerrainSunColor;
float2	RoadFadeOut;
float4	WorldSpaceCamPos;

float4	PosUnpack;
float	TexUnpack;

vector textureFactor = float4(1.0f, 1.0f, 1.0f, 1.0f);

// VS --- PS

struct VS_OUTPUT
{
    float4 Pos          : POSITION0;
    float3 Tex0AndZFade	: TEXCOORD0;
    float4 lightTex     : TEXCOORD2;
    float  Fog          : Fog;
};

texture	LightMap;
sampler LightMapSampler = sampler_state
{
    Texture = (LightMap);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
};

texture	DiffuseMap;
sampler DiffuseMapSampler = sampler_state
{
    Texture = (DiffuseMap);
    MipFilter = LINEAR;
    MinFilter = FILTER_STM_DIFF_MIN;
    MagFilter = FILTER_STM_DIFF_MAG;
    #ifdef FILTER_STM_DIFF_MAX_ANISOTROPY
        MaxAnisotropy = FILTER_STM_DIFF_MAX_ANISOTROPY;
    #endif
    AddressU = WRAP;
    AddressV = WRAP;
};


// INPUTS TO THE VERTEX SHADER FROM THE APP
string reqVertexElement[] =
{
    "PositionPacked",
    "TBasePacked2D",
};

VS_OUTPUT basicVertexShader
(
float4 inPos: POSITION0,
float2 tex0	: TEXCOORD0
)
{
    VS_OUTPUT Out = (VS_OUTPUT)0;

    float4 wPos = mul(inPos * PosUnpack, World);
    wPos.y += .01;

    Out.Pos	= mul(wPos, ViewProjection);
    Out.Tex0AndZFade.xy = tex0 * TexUnpack;

    Out.lightTex.xy = Out.Pos.xy/Out.Pos.w;
    Out.lightTex.xy = (Out.lightTex.xy + 1) / 2;
    Out.lightTex.y = 1-Out.lightTex.y;
    Out.lightTex.xy = Out.lightTex.xy * Out.Pos.w;
    Out.lightTex.zw = Out.Pos.zw;

    float cameraDist = length(WorldSpaceCamPos - wPos);
    Out.Tex0AndZFade.z = 1 - saturate((cameraDist * RoadFadeOut.x) - RoadFadeOut.y);

    Out.Fog = calcFog(Out.Pos.w);

    return Out;
}

string GlobalParameters[] =
{
    "FogRange",
    "ViewProjection",
    "TerrainSunColor",
    "RoadFadeOut",
    "WorldSpaceCamPos",
};

string TemplateParameters[] = {
    "DiffuseMap",
};

string InstanceParameters[] = {
    "World",
    "Transparency",
    "LightMap",
    "PosUnpack",
    "TexUnpack",
};

float4 basicPixelShader(VS_OUTPUT VsOut) : COLOR
{
    float4 color = tex2D(DiffuseMapSampler, VsOut.Tex0AndZFade.xy);
    color.a *= VsOut.Tex0AndZFade.z;
    return color;
};

technique defaultTechnique
{
    pass P0
    {
        vertexShader = compile vs_2_a basicVertexShader();
        pixelShader	 = compile ps_2_a basicPixelShader();

        #ifdef ENABLE_WIREFRAME
            FillMode = WireFrame;
        #endif

        CullMode = CCW;
        AlphaBlendEnable = true;
        AlphaTestEnable = false;

        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;

        ZEnable	= true;
        ZWriteEnable = false;

        fogenable = true;
    }
}
