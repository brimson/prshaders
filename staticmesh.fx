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

//sampler diffuseSampler = sampler_state
sampler samplerWrap0 = sampler_state
{
    Texture = <texture0>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
};

//sampler normalSampler = sampler_state
sampler samplerWrap1 = sampler_state
{
    Texture = <texture1>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler samplerWrap2 = sampler_state
{
    Texture = <texture2>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler samplerWrap3 = sampler_state
{
    Texture = <texture3>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler samplerWrap4 = sampler_state
{
    Texture = <texture4>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler samplerWrap5 = sampler_state
{
    Texture = <texture5>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler samplerWrap6 = sampler_state
{
    Texture = <texture6>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler samplerWrap7 = sampler_state
{
    Texture = <texture7>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler samplerWrapAniso0 = sampler_state
{
    Texture = <texture0>;
    MinFilter = Anisotropic;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
    MaxAnisotropy = 8;
};


sampler samplerWrapAniso1 = sampler_state
{
    Texture = <texture1>;
    MinFilter = Anisotropic;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
    MaxAnisotropy = 8;
};

sampler samplerWrapAniso2 = sampler_state
{
    Texture = <texture2>;
    MinFilter = Anisotropic;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler samplerWrapAniso3 = sampler_state
{
    Texture = <texture3>;
    MinFilter = Anisotropic;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
    MaxAnisotropy = 8;
};

sampler samplerWrapAniso4 = sampler_state
{
    Texture = <texture4>;
    MinFilter = Anisotropic;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
    MaxAnisotropy = 8;
};

sampler samplerWrapAniso5 = sampler_state
{
    Texture = <texture5>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
    MaxAnisotropy = 8;
};

sampler samplerWrapAniso6 = sampler_state
{
    Texture = <texture6>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
    MaxAnisotropy = 8;
};

sampler samplerWrapAniso7 = sampler_state
{
    Texture = <texture7>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Wrap;
    AddressV = Wrap;
    MaxAnisotropy = 8;
};


sampler samplerClamp0 = sampler_state
{
    Texture = <texture0>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Clamp;
    AddressV = Clamp;
};

//sampler normalSampler = sampler_state
sampler samplerClamp1 = sampler_state
{
    Texture = <texture1>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler samplerClamp2 = sampler_state
{
    Texture = <texture2>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler samplerClamp3 = sampler_state
{
    Texture = <texture3>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler samplerClamp4 = sampler_state
{
    Texture = <texture4>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler samplerClamp5 = sampler_state
{
    Texture = <texture5>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler samplerClamp6 = sampler_state
{
    Texture = <texture6>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler samplerClamp7 = sampler_state
{
    Texture = <texture7>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    MipMapLodBias = 0;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler sampler0clamppoint = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler1clamppoint = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler2clamppoint = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler3clamppoint = sampler_state { Texture = (texture3); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler4clamppoint = sampler_state { Texture = (texture4); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler5clamppoint = sampler_state { Texture = (texture5); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler6clamppoint = sampler_state { Texture = (texture6); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };

sampler sampler0wrappoint = sampler_state { Texture = (texture0); AddressU = WRAP; AddressV = WRAP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler1wrappoint = sampler_state { Texture = (texture1); AddressU = WRAP; AddressV = WRAP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler2wrappoint = sampler_state { Texture = (texture2); AddressU = WRAP; AddressV = WRAP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler3wrappoint = sampler_state { Texture = (texture3); AddressU = WRAP; AddressV = WRAP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler4wrappoint = sampler_state { Texture = (texture4); AddressU = WRAP; AddressV = WRAP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler5wrappoint = sampler_state { Texture = (texture5); AddressU = WRAP; AddressV = WRAP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
sampler sampler6wrappoint = sampler_state { Texture = (texture6); AddressU = WRAP; AddressV = WRAP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };


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
    MinFilter = Linear;
    MagFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
};

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


VS_OUTPUT3 VSimpleShader(appdata input,
    uniform float4x4 wvp)
{
    VS_OUTPUT3 outdata;

    outdata.HPos = mul(float4(input.Pos.xyz, 1.0), wvp);
    outdata.TexCoord = input.TexCoord;

    return outdata;
}

float4 PSSimpleShader(VS_OUTPUT3 input) : COLOR
{
    float4 ambient = float4(1, 1, 1, 0.8);
    float4 normalMap = tex2D(samplerWrap0, input.TexCoord);
    float4 outCol = normalMap * ambient;
    return outCol;
}

technique alpha_one
{
    pass p0
    {
        ZEnable = true;
        ZWriteEnable = false;
        CullMode = NONE;
        AlphaBlendEnable = true;

        //SrcBlend = ONE;
        SrcBlend = SRCALPHA;
        DestBlend = ONE;

        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = GREATER;
        //FillMode = WIREFRAME;

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
    float4 Pos  : POSITION;
    float2 osZW : TEXCOORD0;
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

//SHADOW
// TBD: mul matrices on CPU
//	matrix m = mul( vpLightMat, vpLightTrapezMat );
//	Out.Pos = mul( float4(unpackPos.xyz, 1.0), vpLightMat );
//\SHADOW

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
/*
VS2PS_ShadowMap vsShadowMapPoint(APPDATA_ShadowMap input)
{
    VS2PS_ShadowMap Out;

       // Compensate for lack of UBYTE4 on Geforce3
    //int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    //int IndexArray[4] = (int[4])IndexVector;

      float4 oPos = input.Pos;//float4(mul(input.Pos, mOneBoneSkinning[IndexArray[0]]), 1);
     //float4 vPos = mul(oPos, viewProjMatrix);
     Out.Pos = mul(oPos, viewProjMatrix);

    Out.Pos.z *= paraboloidValues.x;
    Out.PosZW = Out.Pos.zwww/10.0 + 0.5;

     float d = length(Out.Pos.xyz);
     Out.Pos.xyz /= d;
    Out.Pos.z += 1;
     Out.Pos.x /= Out.Pos.z;
     Out.Pos.y /= Out.Pos.z;
    Out.Pos.z = (d*paraboloidZValues.x) + paraboloidZValues.y;
    Out.Pos.w = 1;

//SHADOW
// TBD: mul matrices on CPU
     float4 unpackPos = input.Pos * PosUnpack;
//	matrix m = mul( vpLightMat, vpLightTrapezMat );
    Out.Pos = mul( float4(unpackPos.xyz, 1.0), vpLightMat );
    Out.PosZW.xy = Out.Pos.zw;
//\SHADOW

    return Out;
}

float4 psShadowMapPoint(VS2PS_ShadowMap indata) : COLOR
{
#if NVIDIA
    return 0;
#else
//SHADOW
;;	return indata.PosZW.x/indata.PosZW.y;
//\SHADOW
#endif

    clip(indata.PosZW.x-0.5);
    return indata.PosZW.x - 0.5;
}*/

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
//#endif

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

/*
#include "shaders/StaticMesh_nv3x.fx"
#include "shaders/StaticMesh_nv3xpp.fx"
#include "shaders/StaticMesh_r3x0.fx"
#include "shaders/StaticMesh_editor.fx"
#include "shaders/StaticMesh_debug.fx"
#include "shaders/StaticMesh_lightmapgen.fx"
*/
