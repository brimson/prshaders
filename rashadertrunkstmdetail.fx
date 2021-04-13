#include "shaders/RaCommon.fx"

#ifndef _HASSHADOW_
#define _HASSHADOW_ 0
#endif

float4 	OverGrowthAmbient;
Light	Lights[1];
float4	PosUnpack;
float2	NormalUnpack;
float	TexUnpack;

texture	DetailMap;
sampler DetailMapSampler = sampler_state
{
    Texture = (DetailMap);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU  = WRAP;
    AddressV  = WRAP;
    MipMapLodBias = 0;
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
    "PositionPacked",
    "NormalPacked8",
    "TBasePacked2D"
    #ifndef BASEDIFFUSEONLY
        ,"TDetailPacked2D"
    #endif
};

struct VS_OUTPUT
{
    float4 Pos  : POSITION0;
    float2 Tex0 : TEXCOORD0;
    float2 Tex1 : TEXCOORD1;
    #if _HASSHADOW_
        float4 TexShadow : TEXCOORD2;
    #endif
    float4 Color : COLOR0;
    float  Fog   : FOG;
};

VS_OUTPUT basicVertexShader
(
    float4 inPos  : POSITION0,
    float3 normal : NORMAL,
    float2 tex0   : TEXCOORD0
    #ifndef BASEDIFFUSEONLY
        , float2 tex1 : TEXCOORD1
    #endif
)
{
    VS_OUTPUT Out = (VS_OUTPUT)0;

    inPos *= PosUnpack;
    Out.Pos = mul(float4(inPos.xyz, 1.0), WorldViewProjection);
    Out.Fog  = calcFog(Out.Pos.xyz);
    Out.Tex0 = tex0 * TexUnpack;

    #ifndef BASEDIFFUSEONLY
        Out.Tex1 = tex1 * TexUnpack;
    #endif

    normal = normal * NormalUnpack.x + NormalUnpack.y;

    float LdotN	= saturate( dot(normal, -Lights[0].dir ));
    Out.Color.rgb = Lights[0].color * LdotN;
    Out.Color.a = Transparency;

    #if _HASSHADOW_
        Out.TexShadow = calcShadowProjection(float4(inPos.xyz, 1.0));
    #else
        Out.Color.rgb += OverGrowthAmbient;
    #endif

    Out.Color = Out.Color * 0.5;

    return Out;
}

string GlobalParameters[] =
{
    #if _HASSHADOW_
        "ShadowMap",
    #endif
    "FogRange",
    "FogColor"
};

string TemplateParameters[] =
{
    "PosUnpack",
    "NormalUnpack",
    "TexUnpack",
    "DiffuseMap"
    #ifndef BASEDIFFUSEONLY
        , "DetailMap"
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
    "Lights",
    "OverGrowthAmbient"
};

float4 basicPixelShader(VS_OUTPUT VsOut) : COLOR
{
    float3 vertexColor = VsOut.Color;

    #ifdef BASEDIFFUSEONLY
        float4 diffuseMap = tex2D(DiffuseMapSampler, VsOut.Tex0);
    #else
        float4 diffuseMap = tex2D(DiffuseMapSampler, VsOut.Tex0) * tex2D(DetailMapSampler, VsOut.Tex1);
    #endif

    #if _HASSHADOW_
        vertexColor.rgb *= getShadowFactor(ShadowMapSampler, VsOut.TexShadow, 1);
        vertexColor.rgb += OverGrowthAmbient/2;
    #endif

    //tl: use compressed color register to avoid this being compiled as a 2.0 shader.
    return float4(vertexColor.rgb * diffuseMap.rgb * 4.0, VsOut.Color.a * 2.0);
};

technique defaultTechnique
{
    pass P0
    {
        // TextureTransFormFlags[2] = PROJECTED;
        vertexShader = compile vs_2_a basicVertexShader();
        pixelShader = compile ps_2_a basicPixelShader();

        #ifdef ENABLE_WIREFRAME
            FillMode = WireFrame;
        #endif
        AlphaTestEnable = < AlphaTest >;
        AlphaRef        = 127; // temporary hack by johan because "m_shaderSettings.m_alphaTestRef = 127" somehow doesn't work
        FogEnable       = true;
    }
}
