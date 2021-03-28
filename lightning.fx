float4x4 wvp : WORLDVIEWPROJ;

float4 lightningColor: LIGHTNINGCOLOR = {1,1,1,1};

texture texture0 : TEXTURE;

sampler sampler0 = sampler_state
{
    Texture = <texture0>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

struct VSINPUT
{
    float3 Pos: POSITION;
    float2 TexCoords: TEXCOORD0;
    float4 Color : COLOR;
};

struct VSOUT
{
    float4 Pos: POSITION;
    float2 TexCoords: TEXCOORD0;
    float4 Color : COLOR;
};

VSOUT vsLightning(VSINPUT input)
{
    VSOUT output;
    output.Pos = mul(float4(input.Pos,1), wvp);
    output.TexCoords = input.TexCoords;
    output.Color = input.Color;
    return output;
}

float4 psLightning(VSOUT input) : COLOR
{
    float4 texCol = tex2D(sampler0, input.TexCoords);
    return float4(texCol.rgb * lightningColor.rgb, texCol.a * lightningColor.a * input.Color.a);
}

technique Lightning
{
    pass p0
    {
        FogEnable = FALSE;
        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;
        AlphaBlendEnable = TRUE;
        SrcBlend = SrcAlpha;
        DestBlend = One;
        CullMode = NONE;

        VertexShader = compile vs_2_a vsLightning();
        PixelShader = compile ps_2_a psLightning();
    }
}