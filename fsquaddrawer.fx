texture texture0 : TEXLAYER0;
texture texture1 : TEXLAYER1;

sampler sampler0point = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler1point = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };

sampler sampler0bilin = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler0aniso = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = ANISOTROPIC; MagFilter = ANISOTROPIC; MaxAnisotropy = 8; };

dword dwStencilRef : STENCILREF = 0;
dword dwStencilPass : STENCILPASS = 1; // KEEP

float4x4 convertPosTo8BitMat : CONVERTPOSTO8BITMAT;
float4x4 customMtx : CUSTOMMTX;

float4 scaleDown2x2SampleOffsets[4]                 : SCALEDOWN2X2SAMPLEOFFSETS;
float4 scaleDown4x4SampleOffsets[16]                : SCALEDOWN4X4SAMPLEOFFSETS;
float4 scaleDown4x4LinearSampleOffsets[4]           : SCALEDOWN4X4LINEARSAMPLEOFFSETS;
float4 gaussianBlur5x5CheapSampleOffsets[13]        : GAUSSIANBLUR5X5CHEAPSAMPLEOFFSETS;
float  gaussianBlur5x5CheapSampleWeights[13]        : GAUSSIANBLUR5X5CHEAPSAMPLEWEIGHTS;
float4 gaussianBlur15x15HorizontalSampleOffsets[15] : GAUSSIANBLUR15X15HORIZONTALSAMPLEOFFSETS;
float  gaussianBlur15x15HorizontalSampleWeights[15] : GAUSSIANBLUR15X15HORIZONTALSAMPLEWEIGHTS;
float4 gaussianBlur15x15VerticalSampleOffsets[15]   : GAUSSIANBLUR15X15VERTICALSAMPLEOFFSETS;
float  gaussianBlur15x15VerticalSampleWeights[15]   : GAUSSIANBLUR15X15VERTICALSAMPLEWEIGHTS;
float4 growablePoisson13SampleOffsets[12]           : GROWABLEPOISSON13SAMPLEOFFSETS;

float glowHorizOffsets[5] : GLOWHORIZOFFSETS;
float glowHorizWeights[5] : GLOWHORIZWEIGHTS;
float glowVertOffsets[5]  : GLOWVERTOFFSETS;
float glowVertWeights[5]  : GLOWVERTWEIGHTS;

float bloomHorizOffsets[5] : BLOOMHORIZOFFSETS;
float bloomVertOffsets[5]  : BLOOMVERTOFFSETS;

float highPassGate : HIGHPASSGATE; // 3d optics blur; xxxx.yyyy; x - aspect ratio(H/V), y - blur amount(0=no blur, 0.9=full blur)
float blurStrength : BLURSTRENGTH; // 3d optics blur; xxxx.yyyy; x - inner radius, y - outer radius

float2 texelSize : TEXELSIZE;

struct APP2VS_blit {
    float2 Pos       : POSITION0;
    float2 TexCoord0 : TEXCOORD0;
};

struct VS2PS_blit_ {
    float4 Pos       : POSITION;
    float2 TexCoord0 : TEXCOORD0;
};

struct VS2PS_blit {
    float4 Pos       : POSITION;
    float2 TexCoord0 : TEXCOORD0;
};

struct VS2PS_tr_blit {
    float4 Pos       : POSITION;
    float2 TexCoord0 : TEXCOORD0;
};

VS2PS_blit vsDx9_blit(APP2VS_blit indata) {
    VS2PS_blit outdata;
    outdata.Pos = float4(indata.Pos.x, indata.Pos.y, 0, 1);
    outdata.TexCoord0 = indata.TexCoord0;
    return outdata;
}

VS2PS_blit vsDx9_blitCustom(APP2VS_blit indata) {
    VS2PS_blit outdata;
    outdata.Pos = mul(float4(indata.Pos.x, indata.Pos.y, 0, 1), customMtx);
    outdata.TexCoord0 = indata.TexCoord0;
    return outdata;
}

// TODO: implement support for old shader versions. TODO: try to use fakeHDRWeights as variables
VS2PS_tr_blit vsDx9_tr_blit(APP2VS_blit indata) {
    VS2PS_tr_blit outdata;
    outdata.Pos = float4(indata.Pos.x, indata.Pos.y, 0.0, 1.0);
    outdata.TexCoord0 = indata.TexCoord0;
    return outdata;
}

VS2PS_blit_ vsDx9_blitMagnified(APP2VS_blit indata) {
    VS2PS_blit_ outdata;
    outdata.Pos = float4(indata.Pos.x*1.1, indata.Pos.y*1.1, 0, 1);
    outdata.TexCoord0 = indata.TexCoord0;
    return outdata;
}

#include "shaders/fsquaddrawer_convert.fx"
#include "shaders/fsquaddrawer_blur.fx"
#include "shaders/fsquaddrawer_optics.fx"

//	Techniques

technique Blit
{
    pass FSBMPassThrough {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMPassThrough();
    }

    pass FSBMBlend {
        ZEnable = FALSE;
        AlphaBlendEnable = TRUE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;

        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMPassThrough();
    }

    pass FSBMConvertPosTo8Bit {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMConvertPosTo8Bit();
    }

    pass FSBMConvertNormalTo8Bit {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMConvertNormalTo8Bit();
    }

    pass FSBMConvertShadowMapFrontTo8Bit {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMConvertShadowMapFrontTo8Bit();
    }

    pass FSBMConvertShadowMapBackTo8Bit {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMConvertShadowMapBackTo8Bit();
    }

    pass FSBMScaleUp4x4LinearFilter {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMScaleUp4x4LinearFilter();
    }

    pass FSBMScaleDown2x2Filter {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMScaleDown2x2Filter();
    }

    pass FSBMScaleDown4x4Filter {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMScaleDown4x4Filter();
    }

    pass FSBMScaleDown4x4LinearFilter {  // pass 9, tinnitus
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_4TapFilter(scaleDown4x4LinearSampleOffsets);//vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMScaleDown4x4LinearFilter();
    }

    pass FSBMGaussianBlur5x5CheapFilter {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMGaussianBlur5x5CheapFilter();
    }

    pass FSBMGaussianBlur15x15HorizontalFilter {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMGaussianBlur15x15HorizontalFilter();//psDx9_FSBMGaussianBlur15x15HorizontalFilter2();
    }

    pass FSBMGaussianBlur15x15VerticalFilter {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMGaussianBlur15x15VerticalFilter();//psDx9_FSBMGaussianBlur15x15VerticalFilter2();
    }

    pass FSBMGrowablePoisson13Filter {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMGrowablePoisson13Filter();
    }

    pass FSBMGrowablePoisson13AndDilationFilter {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMGrowablePoisson13AndDilationFilter();
    }

    pass FSBMScaleUpBloomFilter {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMScaleUpBloomFilter();
    }

    pass FSBMPassThroughSaturateAlpha {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMPassThroughSaturateAlpha();
    }

    pass FSBMCopyOtherRGBToAlpha {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;
        ColorWriteEnable = ALPHA;

        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMCopyOtherRGBToAlpha();
    }

    // X-Pack additions
    pass FSBMPassThroughBilinear {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_tr_blit();
        PixelShader = compile ps_3_0 psDx9_tr_PassThrough_point();
    }

    pass FSBMPassThroughBilinearAdditive {
        ZEnable = FALSE;
        AlphaBlendEnable = TRUE;
        SrcBlend = ZERO;
        DestBlend = ONE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_tr_blit();
        PixelShader = compile ps_3_0 psDx9_tr_PassThrough_point();
    }

    pass FSMBlur {
        VertexShader = NULL;
        PixelShader = NULL;
    }

    pass FSBMScaleUp4x4LinearFilterAdditive {
        VertexShader = NULL;
        PixelShader = NULL;
    }

    pass FSBMGaussianBlur5x5CheapFilterBlend {
        VertexShader = NULL;
        PixelShader = NULL;
    }

    pass FSBMGaussianBlur5x5CheapFilterAdditive {
        VertexShader = NULL;
        PixelShader = NULL;
    }

    pass FSBMScaleUpBloomFilterAdditive {
        VertexShader = NULL;
        PixelShader = NULL;
    }

    pass FSBMGlowHorizontalFilter { // pass 25
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_tr_opticsBlurH();
        PixelShader = compile ps_3_0 psDx9_tr_opticsBlurH();
    }

    pass FSBMGlowVerticalFilter { // pass 26
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_tr_opticsBlurV();
        PixelShader = compile ps_3_0 psDx9_tr_opticsBlurV();
    }

    pass FSBMGlowVerticalFilterAdditive {
        VertexShader = NULL;
        PixelShader = NULL;
    }

    pass FSBMHighPassFilter {
        VertexShader = NULL;
        PixelShader = NULL;
    }

    pass FSBMHighPassFilterFade { // pass 29
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_tr_blit();
        PixelShader = compile ps_3_0 psDx9_tr_PassThrough_point();
    }

    pass FSBMExtractGlowFilter {
        VertexShader = NULL;
        PixelShader = NULL;
    }

    pass FSBMExtractHDRFilterFade {
        VertexShader = NULL;
        PixelShader = NULL;
    }

    pass FSBMClearAlpha {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;
        ColorWriteEnable = ALPHA;

        VertexShader = compile vs_3_0 vsDx9_blitMagnified(); // is this needed? -mosq
        PixelShader = compile ps_3_0 psDx9_FSBMClear();
    }

    pass FSBMAdditive {
        VertexShader = NULL;
        PixelShader = NULL;
    }

    pass FSBMAdditiveBilinear { // pass 34
        ZEnable = FALSE;
        AlphaBlendEnable = TRUE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        VertexShader = compile vs_3_0 vsDx9_tr_blit();
        PixelShader = compile ps_3_0 psDx9_tr_opticsNoBlurCircle();
    }

    pass FSBMBloomHorizFilter { // pass 35
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_tr_blit();
        PixelShader = compile ps_3_0 psDx9_tr_PassThrough_point();
    }

    pass FSBMBloomHorizFilterAdditive {
        VertexShader = NULL;
        PixelShader = NULL;
    }

    pass FSBMBloomVertFilter { // pass 37
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_tr_blit();
        PixelShader = compile ps_3_0 psDx9_tr_PassThrough_point();
    }

    pass FSBMBloomVertFilterAdditive {
        VertexShader = NULL;
        PixelShader = NULL;
    }

    pass FSBMBloomVertFilterBlur {
        VertexShader = NULL;
        PixelShader = NULL;
    }

    pass FSBMBloomVertFilterAdditiveBlur {
        VertexShader = NULL;
        PixelShader = NULL;
    }

    pass FSBMLuminancePlusBrightPassFilter {
        VertexShader = NULL;
        PixelShader = NULL;
    }

    pass FSBMScaleDown4x4LinearFilterHorizontal { // pass 42
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_tr_blit();
        PixelShader = compile ps_3_0 psDx9_tr_PassThrough_aniso();
    }

    pass FSBMScaleDown4x4LinearFilterVertical { // pass 43
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_tr_blit();
        PixelShader = compile ps_3_0 psDx9_tr_PassThrough_aniso();
    }

    pass FSBMClear {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMClear();
    }

    pass FSBMBlendCustom {
        ZEnable = FALSE;
        AlphaBlendEnable = TRUE;
        StencilEnable = FALSE;
        AlphaTestEnable = FALSE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;

        VertexShader = compile vs_3_0 vsDx9_blitCustom();
        PixelShader = compile ps_3_0 psDx9_FSBMPassThrough();
    }

}

float4 psDx9_StencilGather(VS2PS_blit indata) : COLOR {
    return dwStencilRef / 255.0;
}

float4 psDx9_StencilMap(VS2PS_blit indata) : COLOR {
    float4 stencil = tex2D(sampler0point, indata.TexCoord0);
    return tex1D(sampler1point, stencil.x / 255.0);
}

technique StencilPasses {
    pass StencilGather {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;

        StencilEnable = TRUE;
        StencilRef = (dwStencilRef);
        StencilFunc = EQUAL;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_StencilGather();
    }

    pass StencilMap {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
        StencilEnable = FALSE;

        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_StencilMap();
    }
}

technique ResetStencilCuller {
    pass NV4X {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = ALWAYS;

        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
        ColorWriteEnable = 0;
        ColorWriteEnable1 = 0;
        ColorWriteEnable2 = 0;
        ColorWriteEnable3 = 0;

        StencilEnable = TRUE;
        StencilRef = (dwStencilRef);
        StencilMask = 0xFF;
        StencilWriteMask = 0xFF;
        StencilFunc = EQUAL;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = (dwStencilPass);
        TwoSidedStencilMode = FALSE;

        VertexShader = compile vs_3_0 vsDx9_blit();
        PixelShader = compile ps_3_0 psDx9_FSBMClear();
    }
}
