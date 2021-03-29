#line 2 "StaticMesh.fx"
#include "shaders/commonVertexLight.fx"

// UNIFORM INPUTS
float4x4 viewProjMatrix : WorldViewProjection;
float4x4 worldViewMatrix : WorldView;
float4x4 worldViewITMatrix : WorldViewIT;
float4x4 viewInverseMatrix : ViewI;
float4x4 worldMatrix : World;

float4 ambColor : Ambient = {0.0, 0.0, 0.0, 1.0};
float4 diffColor : Diffuse = {1.0, 1.0, 1.0, 1.0};
float4 specColor : Specular = {0.0, 0.0, 0.0, 1.0};
float4 fuzzyLightScaleValue : FuzzyLightScaleValue = {1.75,1.75,1.75,1};
float4 lightmapOffset : LightmapOffset;
float dropShadowClipheight : DROPSHADOWCLIPHEIGHT;
float4 parallaxScaleBias : PARALLAXSCALEBIAS;

float4x4 vpLightMat : vpLightMat;
float4x4 vpLightTrapezMat : vpLightTrapezMat;
float4	PosUnpack : POSUNPACK;
float	TexUnpack : TEXUNPACK;

bool alphaTest : AlphaTest = false;

float4 paraboloidValues : ParaboloidValues;
float4 paraboloidZValues : ParaboloidZValues;

//SHADOW
float4 Attenuation : Attenuation;
//\SHADOW

texture texture0: TEXLAYER0;
texture texture1: TEXLAYER1;
texture texture2: TEXLAYER2;
texture texture3: TEXLAYER3;
texture texture4: TEXLAYER4;
texture texture5: TEXLAYER5;
texture texture6: TEXLAYER6;
texture texture7: TEXLAYER7;

sampler samplerShadowAlpha = sampler_state
{
    Texture = <texture0>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler colorLUTSampler = sampler_state
{
    Texture = <texture2>;
    MinFilter = Linear;
    MagFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler dummySampler = sampler_state
{
    MinFilter = Linear; MagFilter = Linear;
    AddressU = Clamp; AddressV = Clamp;
};

#define dWrap MinFilter = Linear; MagFilter = Linear; MipFilter = Linear; AddressU = Wrap; AddressV = Wrap
sampler samplerWrap0 = sampler_state { Texture = <texture0>; dWrap; MipMapLodBias = 0; };
sampler samplerWrap1 = sampler_state { Texture = <texture1>; dWrap; MipMapLodBias = 0; };
sampler samplerWrap2 = sampler_state { Texture = <texture2>; dWrap; MipMapLodBias = 0; };
sampler samplerWrap3 = sampler_state { Texture = <texture3>; dWrap; MipMapLodBias = 0; };
sampler samplerWrap4 = sampler_state { Texture = <texture4>; dWrap; MipMapLodBias = 0; };
sampler samplerWrap5 = sampler_state { Texture = <texture5>; dWrap; MipMapLodBias = 0; };
sampler samplerWrap6 = sampler_state { Texture = <texture6>; dWrap; MipMapLodBias = 0; };
sampler samplerWrap7 = sampler_state { Texture = <texture7>; dWrap; MipMapLodBias = 0; };

#define dWrapAniso MinFilter = Anisotropic; MagFilter = Linear; MipFilter = Linear; AddressU = Wrap; AddressV = Wrap
sampler samplerWrapAniso0 = sampler_state { Texture = <texture0>; dWrapAniso; MipMapLodBias = 0; MaxAnisotropy = 8; };
sampler samplerWrapAniso1 = sampler_state { Texture = <texture1>; dWrapAniso; MipMapLodBias = 0; MaxAnisotropy = 8; };
sampler samplerWrapAniso2 = sampler_state { Texture = <texture2>; dWrapAniso; MipMapLodBias = 0; };
sampler samplerWrapAniso3 = sampler_state { Texture = <texture3>; dWrapAniso; MipMapLodBias = 0; MaxAnisotropy = 8; };
sampler samplerWrapAniso4 = sampler_state { Texture = <texture4>; dWrapAniso; MipMapLodBias = 0; MaxAnisotropy = 8; };

#define dWrapAnisoAlt MinFilter = Linear; MagFilter = Linear; MipFilter = Linear; AddressU = Wrap; AddressV = Wrap
sampler samplerWrapAniso5 = sampler_state { Texture = <texture5>; dWrapAnisoAlt; MipMapLodBias = 0; MaxAnisotropy = 8; };
sampler samplerWrapAniso6 = sampler_state { Texture = <texture6>; dWrapAnisoAlt; MipMapLodBias = 0; MaxAnisotropy = 8; };
sampler samplerWrapAniso7 = sampler_state { Texture = <texture7>; dWrapAnisoAlt; MipMapLodBias = 0; MaxAnisotropy = 8; };

#define dClamp MinFilter = Linear; MagFilter = Linear; MipFilter = Linear; AddressU = Clamp; AddressV = Clamp
sampler samplerClamp0 = sampler_state { Texture = <texture0>; dClamp; MipMapLodBias = 0; };
sampler samplerClamp1 = sampler_state { Texture = <texture1>; dClamp; MipMapLodBias = 0; };
sampler samplerClamp2 = sampler_state { Texture = <texture2>; dClamp; MipMapLodBias = 0; };
sampler samplerClamp3 = sampler_state { Texture = <texture3>; dClamp; MipMapLodBias = 0; };
sampler samplerClamp4 = sampler_state { Texture = <texture4>; dClamp; MipMapLodBias = 0; };
sampler samplerClamp5 = sampler_state { Texture = <texture5>; dClamp; MipMapLodBias = 0; };
sampler samplerClamp6 = sampler_state { Texture = <texture6>; dClamp; MipMapLodBias = 0; };
sampler samplerClamp7 = sampler_state { Texture = <texture7>; dClamp; MipMapLodBias = 0; };

#define dClampPoint AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE
sampler sampler0clamppoint = sampler_state { Texture = (texture0); dClampPoint; };
sampler sampler1clamppoint = sampler_state { Texture = (texture1); dClampPoint; };
sampler sampler2clamppoint = sampler_state { Texture = (texture2); dClampPoint; };
sampler sampler3clamppoint = sampler_state { Texture = (texture3); dClampPoint; };
sampler sampler4clamppoint = sampler_state { Texture = (texture4); dClampPoint; };
sampler sampler5clamppoint = sampler_state { Texture = (texture5); dClampPoint; };
sampler sampler6clamppoint = sampler_state { Texture = (texture6); dClampPoint; };

#define dWrapPoint AddressU = WRAP; AddressV = WRAP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE
sampler sampler0wrappoint = sampler_state { Texture = (texture0); dWrapPoint; };
sampler sampler1wrappoint = sampler_state { Texture = (texture1); dWrapPoint; };
sampler sampler2wrappoint = sampler_state { Texture = (texture2); dWrapPoint; };
sampler sampler3wrappoint = sampler_state { Texture = (texture3); dWrapPoint; };
sampler sampler4wrappoint = sampler_state { Texture = (texture4); dWrapPoint; };
sampler sampler5wrappoint = sampler_state { Texture = (texture5); dWrapPoint; };
sampler sampler6wrappoint = sampler_state { Texture = (texture6); dWrapPoint; };

float4 lightPos : LightPosition  : register(vs_1_1, c12)
<
    string Object = "PointLight";
    string Space = "World";
> = {0.0, 0.0, 1.0, 1.0};

float4 lightDir : LightDirection;
float4 sunColor : SunColor;
float4 eyePos : EyePos;
float4 eyePosObjectSpace : EyePosObjectSpace;

struct appdata
{
    float4 Pos      : POSITION;
    float3 Normal   : NORMAL;
    float2 TexCoord : TEXCOORD0;
    float3 Tan      : TANGENT;
    float3 Binorm   : BINORMAL;
};

struct VS_OUTPUT
{
    float4 HPos      : POSITION;
    float2 NormalMap : TEXCOORD0;
    float3 LightVec  : TEXCOORD1;
    float3 HalfVec   : TEXCOORD2;
    float2 DiffMap   : TEXCOORD3;
};

struct VS_OUTPUTSS
{
    float4 HPos      : POSITION;
    float4 TanNormal : COLOR0;
    float4 TanLight  : COLOR1;
    float2 NormalMap : TEXCOORD0;
    float3 LightVec  : TEXCOORD1;
    float3 HalfVec   : TEXCOORD2;
    float2 DiffMap   : TEXCOORD3;
};

struct VS_OUTPUT2
{
    float4 HPos     : POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Diffuse  : COLOR;
};

struct VS_OUTPUT3
{
    float4 HPos     : POSITION;
    float2 TexCoord : TEXCOORD0;
};


VS_OUTPUT3 VSimpleShader(appdata input, uniform float4x4 wvp)
{
    VS_OUTPUT3 outdata;
    outdata.HPos = mul(float4(input.Pos.xyz, 1.0), wvp);
    outdata.TexCoord = input.TexCoord;
    return outdata;
}

float4 PSSimpleShader(VS_OUTPUT3 input) : COLOR
{
    const float4 ambient = float4(1.0, 1.0, 1.0, 0.8);
    float4 normalMap = tex2D(samplerWrap0, input.TexCoord);
    return normalMap * ambient;
}

technique alpha_one
{
    pass p0
    {
        ZEnable = true;
        ZWriteEnable = false;
        CullMode = NONE;
        AlphaBlendEnable = true;

        SrcBlend = SRCALPHA;
        DestBlend = ONE;

        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        VertexShader = compile vs_2_a VSimpleShader(viewProjMatrix);
        PixelShader = compile ps_2_a PSSimpleShader();
    }
}

struct APPDATA_ShadowMap
{
    float4 Pos : POSITION;
    float2 Tex : TEXCOORD0;
};

struct VS2PS_ShadowMap
{
    float4 Pos   : POSITION;
    float2 PosZW : TEXCOORD0;
};

struct VS2PS_ShadowMapAlpha
{
    float4 Pos   : POSITION;
    float2 Tex   : TEXCOORD0;
    float2 PosZW : TEXCOORD1;
};

float4 calcShadowProjCoords(float4 Pos, float4x4 matTrap, float4x4 matLight)
{
     float4 shadowcoords = mul(Pos, matTrap);
     float2 lightZW = mul(Pos, matLight).zw;
    shadowcoords.z = (lightZW.x*shadowcoords.w) / lightZW.y;			// (zL*wT)/wL == zL/wL post homo
    return shadowcoords;
}

VS2PS_ShadowMap vsShadowMap(APPDATA_ShadowMap input)
{
    VS2PS_ShadowMap Out;
    float4 unpackPos = float4(input.Pos.xyz * PosUnpack, 1);
    float4 wPos = mul(unpackPos, worldMatrix);
    Out.Pos = calcShadowProjCoords(float4(wPos.xyz,1.0), vpLightTrapezMat, vpLightMat);
    Out.PosZW.xy = Out.Pos.zw;
    return Out;
}

VS2PS_ShadowMapAlpha vsShadowMapAlpha(APPDATA_ShadowMap input)
{
    VS2PS_ShadowMapAlpha Out;
    float4 unpackPos = float4(input.Pos.xyz * PosUnpack, 1);
    float4 wPos = mul(unpackPos, worldMatrix);
    Out.Pos = calcShadowProjCoords(wPos, vpLightTrapezMat, vpLightMat);
    Out.PosZW.xy = Out.Pos.zw;
    Out.Tex = input.Tex * TexUnpack;
    return Out;
}
float4 psShadowMap(VS2PS_ShadowMap indata) : COLOR
{
    #if NVIDIA
        return 0;
    #else
        return indata.PosZW.x/indata.PosZW.y;
    #endif
}

float4 psShadowMapAlpha(VS2PS_ShadowMapAlpha indata) : COLOR
{
    const float alphaRef = 96.f/255.f;
    float4 alpha = tex2D(samplerShadowAlpha, indata.Tex);

    #if NVIDIA
        return alpha;
    #else
        clip(alpha.a - alphaRef);
        return indata.PosZW.x/indata.PosZW.y;
    #endif
}

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
            ColorWriteEnable = 0; // 0x0000000F;
        #endif

        AlphaBlendEnable = FALSE;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_a vsShadowMap();
        PixelShader = (psShadowMap_Compiled);
    }

    pass directionalspotalpha
    {
        #if NVIDIA
                ColorWriteEnable = 0; // 0x0000000F;

                AlphaTestEnable = TRUE;
                AlphaRef = 96;
                AlphaFunc = GREATER;
        #endif

        CullMode = CW;

        AlphaBlendEnable = FALSE;

        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;

        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_a vsShadowMapAlpha();
        PixelShader = (psShadowMapAlpha_Compiled);
    }

    pass point_
    {
        #if NVIDIA
            ColorWriteEnable = 0;//0x0000000F;
        #endif

        AlphaBlendEnable = FALSE;

        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_a vsShadowMap();
        PixelShader = (psShadowMap_Compiled);
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

        AlphaBlendEnable = FALSE;
        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;
        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_a vsShadowMap();
        PixelShader = (psShadowMap_Compiled);
    }

    pass directionalspotalpha
    {
        #if NVIDIA
            ColorWriteEnable = 0;//0x0000000F;

            AlphaTestEnable = TRUE;
            AlphaRef = 96;
            AlphaFunc = GREATER;
        #endif

        CullMode = CW;

        AlphaBlendEnable = FALSE;

        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ZFunc = LESSEQUAL;

        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_a vsShadowMapAlpha();
        PixelShader = (psShadowMapAlpha_Compiled);
    }

    pass point_
    {
        #if NVIDIA
            ColorWriteEnable = 0;//0x0000000F;
        #endif

        AlphaBlendEnable = FALSE;

        ZEnable = TRUE;
        ZWriteEnable = TRUE;
        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_a vsShadowMap();
        PixelShader = (psShadowMap_Compiled);
    }
}
