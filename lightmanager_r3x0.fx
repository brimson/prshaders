
float4x4 mVP : VIEWPROJ;
float4x4 mWVP : WORLDVIEWPROJ;

float4x4 mObjW : OBJWORLD;
float4x4 mCamV : CAMVIEW;
float4x4 mCamP : CAMPROJ;

float4x4 mLightVP : LIGHTVIEWPROJ;
float4x4 mLightOccluderVP : LIGHTOCCLUDERVIEWPROJ;
float4x4 mCamVI : CAMVIEWI;
float4x4 mCamPI : CAMPROJI;
float4 vViewportMap : VIEWPORTMAP;
float4 vViewportMap2 : VIEWPORTMAP2;

float4 EyePos : EYEPOS;
float4 EyeDof : EYEDOF;

float4 LightWorldPos : LIGHTWORLDPOS;
float4 LightDir : LIGHTDIR;
float4 LightPos : LIGHTPOS;
float4 LightCol : LIGHTCOL;
float LightAttenuationRange : LIGHTATTENUATIONRANGE;
float LightAttenuationRangeInv : LIGHTATTENUATIONRANGEINV;

float4 vProjectorMask : PROJECTORMASK;

float4 paraboloidZValues : PARABOLOIDZVALUES;

dword dwStencilFunc : STENCILFUNC = 3;
dword dwStencilRef : STENCILREF = 0;
dword dwStencilPass : STENCILPASS = 1;

float ShadowIntensityBias : SHADOWINTENSITYBIAS;
float LightmapIntensityBias : LIGHTMAPINTENSITYBIAS;

texture texture0 : TEXLAYER0;
texture texture1 : TEXLAYER1;
texture texture2 : TEXLAYER2;
texture texture3 : TEXLAYER3;
texture texture4 : TEXLAYER4;
texture texture5 : TEXLAYER5;
texture texture6 : TEXLAYER6;

sampler sampler0 = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler1 = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler2 = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler3 = sampler_state { Texture = (texture3); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler4 = sampler_state { Texture = (texture4); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler5 = sampler_state { Texture = (texture5); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler6 = sampler_state { Texture = (texture6); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };

sampler sampler2bilin = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler3bilin = sampler_state { Texture = (texture3); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = None;};
sampler sampler4bilin = sampler_state { Texture = (texture4); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler5bilin = sampler_state { Texture = (texture5); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler6bilin = sampler_state { Texture = (texture6); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };

struct APP2VS_Quad
{
    float2 Pos       : POSITION0;
    float2 TexCoord0 : TEXCOORD0;
};

struct APP2VS_D3DXMesh
{
    float4 Pos : POSITION0;
};

struct VS2PS_Quad
{
    float4 Pos       : POSITION;
    float2 TexCoord0 : TEXCOORD0;
};

struct VS2PS_Quad_SunLightStatic
{
    float4 Pos        : POSITION;
    float2 TexCoord0  : TEXCOORD0;
    float2 TCLightmap : TEXCOORD1;
};

struct VS2PS_D3DXMesh
{
    float4 Pos       : POSITION;
    float4 TexCoord0 : TEXCOORD0;
};

struct VS2PS_D3DXMesh2
{
    float4 Pos  : POSITION;
    float4 wPos : TEXCOORD0;
};

struct PS2FB_DiffSpec
{
    float4 Col0 : COLOR0;
    float4 Col1 : COLOR1;
};

struct PS2FB_Combine
{
    float4 Col0 : COLOR0;
};

/*
    Static and Dynamic sunlight shaders
*/

#include "shaders/lightmanager_r3x0_sunlight.fx"

technique SunLight
{
    pass opaqueDynamicObjects
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = (dwStencilRef);
        StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = (dwStencilPass);

        VertexShader = compile vs_2_a vsDx9_SunLightDynamicObjects();
        PixelShader = compile ps_2_a psDx9_SunLightDynamicObjects();
    }

    pass opaqueDynamicSkinObjects
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = (dwStencilRef);
        StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = (dwStencilPass);

        VertexShader = compile vs_2_a vsDx9_SunLightDynamicObjects();
        PixelShader = compile ps_2_a psDx9_SunLightDynamicSkinObjects();
    }

    pass opaqueStaticObjects
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = (dwStencilRef);
        StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_2_a vsDx9_SunLightStaticObjects();
        PixelShader = compile ps_2_a psDx9_SunLightStaticObjects();
    }

    pass transparent
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = NEVER;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_2_a vsDx9_SunLightDynamicObjects();
        PixelShader = compile ps_2_a psDx9_SunLightTransparent();
    }
}

technique SunLightShadowNV <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass opaqueDynamicObjects
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;

        CullMode = NONE;
        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = 0x20;
        StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = INCR;

        VertexShader = compile vs_2_a vsDx9_SunLightShadowDynamicObjects();
        PixelShader = compile ps_2_a psDx9_SunLightShadowDynamicObjectsNV();
    }
    pass opaqueDynamic1pObjects
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;

        CullMode = NONE;
        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = 0x80;
        StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = DECR;

        VertexShader = compile vs_2_a vsDx9_SunLightShadowDynamicObjects();
        PixelShader = compile ps_2_a psDx9_SunLightShadowDynamic1pObjectsNV();
    }
    pass opaqueStaticObjects
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;

        CullMode = NONE;
        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = 0x40;
        StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = INCR;

        DepthBias = 0.000;
        SlopeScaleDepthBias = 2;

        VertexShader = compile vs_2_a vsDx9_SunLightShadowStaticObjects();
        PixelShader = compile ps_2_a psDx9_SunLightShadowStaticObjectsNV();
    }
    pass foobar
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = 240;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_2_a vsDx9_SunLightShadowStaticObjects();
        PixelShader = compile ps_2_a psDx9_SunLightShadowStaticObjectsNV();
    }
}

technique SunLightShadow <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass opaqueDynamicObjects
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;

        CullMode = NONE;
        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = 0x20;
        StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = INCR;

        VertexShader = compile vs_2_a vsDx9_SunLightShadowDynamicObjects();
        PixelShader = compile ps_2_a psDx9_SunLightShadowDynamicObjects();
    }
    pass opaqueDynamic1pObjects
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;

        CullMode = NONE;
        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = 0x80;
        StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = DECR;

        VertexShader = compile vs_2_a vsDx9_SunLightShadowDynamicObjects();
        PixelShader = compile ps_2_a psDx9_SunLightShadowDynamic1pObjects();
    }
    pass opaqueStaticObjects
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;

        CullMode = NONE;
        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = 0x40;
        StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = INCR;

        VertexShader = compile vs_2_a vsDx9_SunLightShadowStaticObjects();
        PixelShader = compile ps_2_a psDx9_SunLightShadowStaticObjects();
    }
    pass foobar
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = 240;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_2_a vsDx9_SunLightShadowStaticObjects();
        PixelShader = compile ps_2_a psDx9_SunLightShadowStaticObjects();
    }
}

/*
    Pointlight shaders
*/

#include "shaders/lightmanager_r3x0_pointlight.fx"

technique PointLight <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 1;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_2_a vsDx9_PointLight();
        PixelShader = compile ps_2_a psDx9_PointLight();
    }

    pass p1
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;

        StencilFunc = (dwStencilFunc);

        VertexShader = compile vs_2_a vsDx9_PointLight();
        PixelShader = compile ps_2_a psDx9_PointLight2();
    }
}

technique PointLightNV40 <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ColorWriteEnable  = RED|GREEN|BLUE|ALPHA;
        ColorWriteEnable1 = RED|GREEN|BLUE|ALPHA;
        ColorWriteEnable2 = RED|GREEN|BLUE|ALPHA;
        ColorWriteEnable3 = RED|GREEN|BLUE|ALPHA;
        ZEnable = FALSE;
        ZWriteEnable = FALSE;

        CullMode = NONE;

        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        BlendOp = MAX;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilMask = 0xFF;
        StencilRef = 0x55;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_2_a vsDx9_PointLight();
        PixelShader = compile ps_2_a psDx9_PointLightNV40();
    }

    pass ReplaceStencil
    {
        ColorWriteEnable  = 0;
        ColorWriteEnable1 = 0;
        ColorWriteEnable2 = 0;
        ColorWriteEnable3 = 0;

        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESS;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = ALWAYS;
        StencilMask = 0xFF;
        StencilRef = 0x55;
        StencilFAIL = KEEP;
        StencilZFail = REPLACE;
        StencilPass = KEEP;

        VertexShader = compile vs_2_a vsDx9_PointLight();
        PixelShader = compile ps_2_a ps_dummy();
    }
}

technique PointLightShadowNV <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 1;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_2_a vsDx9_PointLight();
        PixelShader = compile ps_2_a psDx9_PointLightShadowNV();
    }
}

technique PointLightShadow <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 1;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_2_a vsDx9_PointLight();
        PixelShader = compile ps_2_a psDx9_PointLightShadow();
    }
}

technique PointLightShadowNV40 <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ColorWriteEnable  = RED|GREEN|BLUE|ALPHA;
        ColorWriteEnable1 = RED|GREEN|BLUE|ALPHA;
        ColorWriteEnable2 = RED|GREEN|BLUE|ALPHA;
        ColorWriteEnable3 = RED|GREEN|BLUE|ALPHA;
        ZEnable = FALSE;
        ZWriteEnable = FALSE;

        CullMode = NONE;

        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        BlendOp = MAX;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilMask = 0xFF;
        StencilRef = 0x55;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_2_a vsDx9_PointLight();
        PixelShader = compile ps_2_a psDx9_PointLightShadowNV40();
    }

    pass ReplaceStencil
    {
        ColorWriteEnable = 0;
        ColorWriteEnable1 = 0;
        ColorWriteEnable2 = 0;
        ColorWriteEnable3 = 0;

        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESS;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = ALWAYS;
        StencilMask = 0xFF;
        StencilRef = 0x55;
        StencilFAIL = KEEP;
        StencilZFail = REPLACE;
        StencilPass = KEEP;

        VertexShader = compile vs_2_a vsDx9_PointLight();
        PixelShader = compile ps_2_a ps_dummy();
    }
}

technique PointLightGlow <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        CullMode = CCW;

        AlphaBlendEnable = TRUE;
        SrcBlend = SRCCOLOR;
        DestBlend = ONE;

        StencilEnable = FALSE;

        VertexShader = compile vs_2_a vsDx9_PointLightGlow();
        PixelShader = compile ps_2_a psDx9_PointLightGlow();
    }
}

/*
    Spotlight shaders
*/

#include "shaders/lightmanager_r3x0_spotlight.fx"

technique SpotLight <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;

        VertexShader = compile vs_2_a vsDx9_SpotLight();
        PixelShader = compile ps_2_a psDx9_SpotLight();
    }
}

technique SpotLightNV40 <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        BlendOp = MAX;

        StencilEnable = FALSE;

        VertexShader = compile vs_2_a vsDx9_SpotLight();
        PixelShader = compile ps_2_a psDx9_SpotLightNV40();
    }
}


technique SpotLightShadow <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 1;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_2_a vsDx9_SpotLight();
        PixelShader = compile ps_2_a psDx9_SpotLightShadow();
    }
}

technique SpotLightShadowNV40 <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 1;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_2_a vsDx9_SpotLight();
        PixelShader = compile ps_2_a psDx9_SpotLightShadowNV40();
    }
}

technique SpotProjector <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;

        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 1;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_2_a vsDx9_SpotProjector();
        PixelShader = compile ps_2_a psDx9_SpotProjector();
    }
}

technique SpotProjectorNV40 <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;

        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        BlendOp = MAX;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 1;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_2_a vsDx9_SpotProjector();
        PixelShader = compile ps_2_a psDx9_SpotProjectorNV40();
    }
}

technique SpotProjectorShadowNV <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 1;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_2_a vsDx9_SpotProjector();
        PixelShader = compile ps_2_a psDx9_SpotProjectorShadowNV();
    }
}

technique SpotProjectorShadow <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 1;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_2_a vsDx9_SpotProjector();
        PixelShader = compile ps_2_a psDx9_SpotProjectorShadow();
    }
}

technique SpotProjectorShadowNV40 <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        BlendOp = MAX;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 1;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_2_a vsDx9_SpotProjector();
        PixelShader = compile ps_2_a psDx9_SpotProjectorShadowNV40();
    }
}

/*
    Blit and combiner shaders
*/

#include "shaders/lightmanager_r3x0_blitcombine.fx"

technique BlitBackLightContrib <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass point_
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;

        VertexShader = compile vs_2_a vsDx9_BlitBackLightContribPoint();
        PixelShader = compile ps_2_a psDx9_BlitBackLightContrib();
    }

    pass spot
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;

        VertexShader = compile vs_2_a vsDx9_BlitBackLightContribSpot();
        PixelShader = compile ps_2_a psDx9_BlitBackLightContrib();
    }

    pass spotprojector
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;

        VertexShader = compile vs_2_a vsDx9_BlitBackLightContribSpotProjector();
        PixelShader = compile ps_2_a psDx9_BlitBackLightContrib();
    }
}

technique Combine
{
    pass opaque
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        StencilEnable = FALSE;

        VertexShader = compile vs_2_a vsDx9_Combine();
        PixelShader = compile ps_2_a psDx9_Combine();
    }

    pass transparent
    {
        ZEnable = FALSE;
        ZWriteEnable = FALSE;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = 3;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_2_a vsDx9_Combine();
        PixelShader = compile ps_2_a psDx9_CombineTransparent();
    }
}
