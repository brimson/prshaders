
#line 2 "Decals.fx"

#include "shaders/RaCommon.fx"

// UNIFORM INPUTS
float4x4 worldViewProjection         : WorldViewProjection;
float4x3 instanceTransformations[10] : InstanceTransformations;

float4 ambientColor : AmbientColor;
float4 sunColor : SunColor;
float4 sunDirection : SunDirection;

float2 decalFadeDistanceAndInterval : DecalFadeDistanceAndInterval = float2(100.0f, 30.0f);

texture texture0: TEXLAYER0;
sampler decalSampler = sampler_state
{
    Texture = (texture0);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
};

struct appdata
{
    float4 Pos    : POSITION;
    float4 Normal : NORMAL;
    float4 Color  : COLOR;
    float4 TexCoordsInstanceIndexAndAlpha : TEXCOORD0;
};

struct OUT_vsDecal
{
    float4 HPos     : POSITION;
    float2 Texture0 : TEXCOORD0;
    float3 Color    : TEXCOORD1;
    float3 Diffuse  : TEXCOORD2;
    float4 Alpha    : COLOR0;
    float  Fog      : FOG;
};

// Decal Shadow shaders aren't used. Should we use it?
struct OUT_vsDecalShadowed
{
    float4 HPos        : POSITION;
    float2 Texture0    : TEXCOORD0;
    float4 TexShadow   : TEXCOORD1;
    float4 ViewPortMap : TEXCOORD2;
    float3 Color       : TEXCOORD3;
    float3 Diffuse     : TEXCOORD4;
    float4 Alpha       : COLOR0;
    float  Fog         : FOG;
};

OUT_vsDecal vsDecal(appdata input)
{
    OUT_vsDecal Out;

    int index = input.TexCoordsInstanceIndexAndAlpha.z;

    float3 Pos = mul(input.Pos, instanceTransformations[index]);
    Out.HPos = mul(float4(Pos.xyz, 1.0f), worldViewProjection);

    float3 worldNorm = mul(input.Normal.xyz, (float3x3)instanceTransformations[index]);
    Out.Diffuse = saturate(dot(worldNorm, -sunDirection)) * sunColor;

    float alpha = 1.0f - saturate((Out.HPos.z - decalFadeDistanceAndInterval.x)/decalFadeDistanceAndInterval.y);
    alpha *= input.TexCoordsInstanceIndexAndAlpha.w;

    Out.Alpha = alpha;
    Out.Color = input.Color;
    Out.Texture0 = input.TexCoordsInstanceIndexAndAlpha.xy;
    Out.Fog = calcFog(Out.HPos.xyz);

    return Out;
}

float4 psDecal(OUT_vsDecal indata) : COLOR
{
    float3 lighting =  ambientColor + indata.Diffuse;
    float4 outColor = tex2D(decalSampler, indata.Texture0); // * indata.Color;
    outColor.rgb *= indata.Color * lighting;
    outColor.a *= indata.Alpha;
    return outColor;
}

technique Decal
<
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
        { 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
        { 0, D3DDECLTYPE_D3DCOLOR, D3DDECLUSAGE_COLOR, 0 },
        { 0, D3DDECLTYPE_FLOAT4, D3DDECLUSAGE_TEXCOORD, 0 },
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        AlphaTestEnable = TRUE;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        AlphaRef = 0;
        AlphaFunc = GREATER;
        CullMode = CW;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        FogEnable = TRUE;
        RangeFogEnable = TRUE;
        FogVertexMode = 3;
        FogStart = 0.5f;
        FogEnd = 0.8f;

        VertexShader = compile vs_2_a vsDecal();
        PixelShader = compile ps_2_a psDecal();
    }

    pass p1
    {
        AlphaTestEnable = TRUE;
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        AlphaRef = 0;
        AlphaFunc = GREATER;
        CullMode = CW;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        FogEnable = TRUE;
        RangeFogEnable = TRUE;
        FogVertexMode = 3;
        FogStart = 0.5f;
        FogEnd = 0.8f;

        VertexShader = compile vs_2_a vsDecal();
        PixelShader = compile ps_2_a psDecal();
    }
}
