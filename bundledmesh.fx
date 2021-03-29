#line 2 "BundledMesh.fx"

// UNIFORM INPUTS
float4x4 viewProjMatrix : WorldViewProjection;// : register(vs_1_1, c0);
float4x4 viewInverseMatrix : ViewI; // : register(vs_1_1, c8);
float4x3 mOneBoneSkinning[26]: matONEBONESKINNING;// : register(c15) < bool sparseArray = true; int arrayStart = 15; >;
float4x4 viewMatrix : ViewMatrix;
float4x4 viewITMatrix : ViewITMatrix;

float4 ambColor  : Ambient  = { 0.0f, 0.0f, 0.0f, 1.0f };
float4 diffColor : Diffuse  = { 1.0f, 1.0f, 1.0f, 1.0f };
float4 specColor : Specular = { 0.0f, 0.0f, 0.0f, 1.0f };

float4x4 vpLightMat : vpLightMat;
float4x4 vpLightTrapezMat : vpLightTrapezMat;
float4 PosUnpack : POSUNPACK;

float2 vTexProjOffset : TEXPROJOFFSET;

float2 zLimitsInv : ZLIMITSINV;

float shadowAlphaThreshold : SHADOWALPHATHRESHOLD;
float4x4 mLightVP : LIGHTVIEWPROJ;
float4 vViewportMap : VIEWPORTMAP;

dword dwStencilRef : STENCILREF = 0;
float4 eyePos : EYEPOS = {0.0f, 0.0f, 1.0f, .25f};
float altitudeFactor : ALTITUDEFACTOR = 0.7f;

texture texture0: TEXLAYER0;
texture texture1: TEXLAYER1;
texture texture2: TEXLAYER2;
texture texture3: TEXLAYER3;
texture texture4: TEXLAYER4;

// SHADOWS
float4 Attenuation : Attenuation;

float4x4 ViewPortMatrix : ViewPortMatrix;
float4   ViewportMap    : ViewportMap;

bool alphaBlendEnable:	AlphaBlendEnable;

float4 lightPos : LightPosition;
float4 lightDir : LightDirection;
float4 hemiMapInfo : HemiMapInfo;

float normalOffsetScale : NormalOffsetScale;

float4 skyColor : SkyColor;
float4 ambientColor : AmbientColor;
float4 sunColor : SunColor;

float attenuationSqrInv : AttenuationSqrInv;
float4 lightColor : LightColor;
float coneAngle : ConeAngle;

float4 paraboloidValues : ParaboloidValues;
float4 paraboloidZValues : ParaboloidZValues;

float4x3 uvMatrix[8]: UVMatrix;

sampler sampler0 = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler1 = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler2 = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler3 = sampler_state { Texture = (texture3); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };

sampler sampler1point = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler2point = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };

sampler samplerNormal2   = sampler_state { Texture = (texture2); AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
samplerCUBE samplerCube2 = sampler_state { Texture = (texture2); AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
samplerCUBE samplerCube3 = sampler_state { Texture = (texture3); AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
samplerCUBE samplerCube4 = sampler_state { Texture = (texture4); AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };

sampler sampler2Aniso   = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = Anisotropic; MagFilter = LINEAR; MipFilter = LINEAR; MaxAnisotropy = 8; };
sampler diffuseSampler  = sampler_state { Texture = <texture0>; MinFilter = Linear; MagFilter = Linear; MipFilter = Linear; AddressU = Wrap; AddressV = Wrap; };
sampler normalSampler   = sampler_state { Texture = <texture1>; MinFilter = Linear; MagFilter = Linear; MipFilter = Linear; AddressU = Wrap; AddressV = Wrap; };
sampler colorLUTSampler = sampler_state { Texture = <texture2>; MinFilter = Linear; MagFilter = Linear; AddressU = Clamp; AddressV = Clamp; };
sampler dummySampler    = sampler_state { MinFilter = Linear; MagFilter = Linear;AddressU = Clamp; AddressV = Clamp; };

struct appdata
{
    float4 Pos          : POSITION;
    float3 Normal       : NORMAL;
    float4 BlendIndices : BLENDINDICES;
    float2 TexCoord     : TEXCOORD0;
    float3 Tan          : TANGENT;
    float3 Binorm       : BINORMAL;
};

struct VS_OUTPUT
{
    float4 HPos      : POSITION;
    float2 NormalMap : TEXCOORD0;
    float3 LightVec  : TEXCOORD1;
    float3 HalfVec   : TEXCOORD2;
    float2 DiffMap   : TEXCOORD3;
    float  Fog       : FOG;
};

struct VS_OUTPUT20
{
    float4 HPos     : POSITION;
    float2 Tex0     : TEXCOORD0;
    float3 LightVec : TEXCOORD1;
    float3 HalfVec  : TEXCOORD2;
    float  Fog      : FOG;
};

struct VS_OUTPUT2
{
    float4 HPos     : POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Diffuse  : COLOR;
    float Fog       : FOG;
};

struct VS_OUTPUT_AlphaScope
{
    float4 HPos         : POSITION;
    float3 Tex0AndTrans	: TEXCOORD0;
    float2 Tex1         : TEXCOORD1;
    float  Fog          : FOG;
};

struct VS_OUTPUT_Alpha
{
    float4 HPos       : POSITION;
    float2 DiffuseMap : TEXCOORD0;
    float4 Tex1       : TEXCOORD1;
    float Fog         : FOG;
};

struct VS_OUTPUT_AlphaEnvMap
{
    float4 HPos                : POSITION;
    float2 DiffuseMap          : TEXCOORD0;
    float4 TexPos              : TEXCOORD1;
    float2 NormalMap           : TEXCOORD2;
    float3 TanToCubeSpace[3]   : TEXCOORD5;
    float4 EyeVecAndReflection : TEXCOORD4;
    float Fog                  : FOG;
};

struct VS2PS_ShadowMap
{
    float4 HPos  : POSITION;
    float2 PosZW : TEXCOORD0;
};

struct VS2PS_ShadowMapAlpha
{
    float4 HPos        : POSITION;
    float4 Tex0PosZW   : TEXCOORD0;
    // SHADOWS
    float4 Attenuation : COLOR0;
};

/*
    Blinn lighting and diffuse shaders
*/

#include "shaders/bundledmesh_blinndiffuse.fx"

technique Full_States <bool Restore = true;>
{
    pass BeginStates
    {
        AlphaTestEnable = TRUE;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        Sampler[1] = <dummySampler>;
        Sampler[2] = <colorLUTSampler>;
    }

    pass EndStates { }
}

technique Full
{
    pass p0
    {
        VertexShader = compile vs_2_a bumpSpecularVertexShaderBlinn1(viewProjMatrix, viewInverseMatrix, lightPos);
        PixelShader = compile ps_2_a bumpSpecularPixelShaderBlinn1();
    }
}

technique Full20
{
    pass p0
    {
        ZEnable = true;
        ZWriteEnable = true;
        AlphaBlendEnable = false;
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        VertexShader = compile vs_2_a bumpSpecularVertexShaderBlinn20(viewProjMatrix, viewInverseMatrix, lightPos);
        PixelShader = compile ps_2_a PShade2();
    }
}

technique t1
{
    pass p0
    {

        ZEnable = true;
        ZWriteEnable = true;
        AlphaBlendEnable = false;
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        VertexShader = compile vs_2_a diffuseVertexShader(viewProjMatrix, viewInverseMatrix, lightPos, eyePos);
        PixelShader = compile ps_2_a diffusePixelShader();
    }
}

/*
    Alpha and alpha scope shaders
*/

#include "shaders/bundledmesh_alpha.fx"

technique alpha
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

        VertexShader = compile vs_2_a vsAlpha(viewProjMatrix);
        PixelShader = compile ps_2_a psAlpha();
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

        VertexShader = compile vs_2_a vsAlphaEnvMap(viewProjMatrix);
        PixelShader = compile ps_2_a psAlphaEnvMap();
    }
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

        VertexShader = compile vs_2_a vsAlphaScope(viewProjMatrix);
        PixelShader = compile ps_2_a psAlphaScope();
    }
}

/*
    ShadowMap shaders
*/

#include "shaders/bundledmesh_shadowmap.fx"

#if NVIDIA
    PixelShader psShadowMap_Compiled = compile ps_2_a psShadowMap();
    PixelShader psShadowMapAlpha_Compiled = compile ps_2_a psShadowMapAlpha();
#else
    PixelShader psShadowMap_Compiled = compile ps_2_a psShadowMap();
    PixelShader psShadowMapAlpha_Compiled = compile ps_2_a psShadowMapAlpha();
#endif

technique DrawShadowMap
{
    pass directionalspot
    {
        #if NVIDIA
            ColorWriteEnable = 0;
        #endif

        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        AlphaBlendEnable = FALSE;
        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_a vsShadowMap();
        PixelShader = (psShadowMap_Compiled);

        CullMode = CCW;
    }

    pass directionalspotalpha
    {
        #if NVIDIA
            ColorWriteEnable = 0;
        #endif

        #if NVIDIA
            AlphaTestEnable = TRUE;
            AlphaRef = 0;
        #endif

        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        AlphaBlendEnable = FALSE;
        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_a vsShadowMapAlpha();
        PixelShader = (psShadowMapAlpha_Compiled);

        CullMode = CCW;
    }

    pass point_
    {
        #if NVIDIA
            ColorWriteEnable = 0;
        #endif

        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        AlphaBlendEnable = FALSE;
        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_a vsShadowMap();
        PixelShader = (psShadowMap_Compiled);

        CullMode = CCW;
    }

    pass pointalpha
    {
        #if NVIDIA
            ColorWriteEnable = 0;
        #endif

        #if NVIDIA
            AlphaTestEnable = TRUE;
            AlphaRef = 0;
        #endif

        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        AlphaBlendEnable = FALSE;
        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_a vsShadowMapAlpha();
        PixelShader = (psShadowMapAlpha_Compiled);

        CullMode = CCW;
    }
}

// We actually don't need to have 2 techniques here
// but it is kept for back-compatibility with original BF2
technique DrawShadowMapNV
{
    pass directionalspot
    {
        #if NVIDIA
            ColorWriteEnable = 0;
        #endif

        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        AlphaBlendEnable = FALSE;
        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_a vsShadowMap();
        PixelShader = (psShadowMap_Compiled);

        CullMode = CCW;
    }

    pass directionalspotalpha
    {
        #if NVIDIA
            ColorWriteEnable = 0;
        #endif

        #if NVIDIA
            AlphaTestEnable = TRUE;
            AlphaRef = 0;
        #endif

        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        AlphaBlendEnable = FALSE;
        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_a vsShadowMapAlpha();
        PixelShader = (psShadowMapAlpha_Compiled);

        CullMode = None;
    }

    pass point_
    {
        #if NVIDIA
            ColorWriteEnable = 0;
        #endif

        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        AlphaBlendEnable = FALSE;
        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_a vsShadowMap();
        PixelShader = (psShadowMap_Compiled);

        CullMode = None;
    }

    pass pointalpha
    {
        #if NVIDIA
            ColorWriteEnable = 0;
        #endif

        #if NVIDIA
            AlphaTestEnable = TRUE;
            AlphaRef = 0;
        #endif

        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        AlphaBlendEnable = FALSE;
        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_a vsShadowMapAlpha();
        PixelShader = (psShadowMapAlpha_Compiled);

        CullMode = None;
    }
}
