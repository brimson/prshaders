#line 2 "SwiffMenu.fx"

#include "shaders/RaCommon.fx"

float4x4 WorldView : TRANSFORM;
float4 DiffuseColor : DIFFUSE;
float4 TexGenS : TEXGENS;
float4 TexGenT : TEXGENT;
texture TexMap : TEXTURE;
float Time : TIME;

sampler TexMapSampler = sampler_state
{
    Texture   = <TexMap>;
    AddressU  = Wrap;
    AddressV  = Wrap;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
};

sampler TexMapSamplerClamp = sampler_state
{
    Texture   = <TexMap>;
    AddressU  = Clamp;
    AddressV  = Clamp;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
};

sampler TexMapSamplerWrap = sampler_state
{
    Texture   = <TexMap>;
    AddressU  = Wrap;
    AddressV  = Wrap;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
};

struct VS_SHAPE
{
    float4 Position : POSITION;
    float4 Diffuse  : COLOR0;
};

struct VS_TS0
{
    float4 Position : POSITION;
    float2 TexCoord : TEXCOORD0;
};


struct VS_TS3
{
    float4 Position : POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Diffuse  : COLOR0;
};

struct VS_SHAPETEXTURE
{
    float4 Position : POSITION;
    float4 Diffuse  : COLOR0;
    float4 Selector : COLOR1;
    float2 TexCoord : TEXCOORD0;
};

struct VS_TEXTURE
{
    float4 Position : POSITION;
    float4 Diffuse  : COLOR0;
    float2 TexCoord : TEXCOORD0;
};

VS_SHAPE VSShape(float3 Position : POSITION, float4 VtxColor : COLOR0)
{
    VS_SHAPE Out;
    Out.Position = float4(Position.xy, 0.0f, 1.0);
    Out.Diffuse = VtxColor;
    return Out;
}

VS_SHAPE VSLine(float3 Position : POSITION)
{
    VS_SHAPE Out;
    Out.Position = float4(Position.xy, 0.0f, 1.0);
    Out.Diffuse = DiffuseColor;
    return Out;
}

VS_SHAPETEXTURE VSShapeTexture(float3 Position : POSITION)
{
    VS_SHAPETEXTURE Out;
    Out.Position = mul( float4(Position.xy, 0.0f, 1.0), WorldView);
    Out.Diffuse = DiffuseColor;
    Out.Selector = Position.zzzz;
    float4 texPos = float4(Position.xy, 0.0, 1.0);
    Out.TexCoord = float2(mul(texPos, TexGenS), mul(texPos, TexGenT));
    return Out;
}

float4 PSRegularWrap(VS_SHAPETEXTURE input) : COLOR
{
    float4 color;
    float4 tex = tex2D( TexMapSamplerWrap, input.TexCoord );
    color.rgb = tex * input.Diffuse * input.Selector + input.Diffuse * (1.0 - input.Selector);
    color.a = tex.a * input.Diffuse.a;
    return color;
}

float4 PSRegularClamp(VS_SHAPETEXTURE input) : COLOR
{
    float4 color;
    float4 tex = tex2D(TexMapSamplerClamp, input.TexCoord);
    color.rgb = tex * input.Diffuse * input.Selector + input.Diffuse * (1.0 - input.Selector);
    color.a = tex.a * input.Diffuse.a;
    return color;
}

float4 PSDiffuse(VS_SHAPE input) : COLOR
{
    return input.Diffuse;
}

VS_TS0 VSTS0_0(float3 Position : POSITION)
{
    VS_TS0 Out;
    Out.Position = mul(float4(Position.xy, 0.0f, 1.0), WorldView);
    float4 texPos = float4(Position.xy + sin(Time) * 240.5, 0.0, 1.0);
    Out.TexCoord.x = (mul(texPos, TexGenS) + sin(Time * 0.1) * 0.1) * 0.8 + 0.1;
    Out.TexCoord.y = (mul(texPos, TexGenT) + cos(Time * 0.12 + 0.2) * 0.1) * 0.8 + 0.1;
    return Out;
}

VS_SHAPE VSTS0_1(float3 Position : POSITION)
{
    VS_SHAPE Out;
    Out.Position = mul( float4(Position.xy, 0.0f, 1.0), WorldView);
    Out.Diffuse = sin(Time) * 0.2 + 0.2 + cos(Time * 0.31) * 0.1 + 0.1;
    return Out;
}

VS_TS3 VSTS1_0(float3 Position : POSITION)
{
    VS_TS3 Out;
    Out.Position = mul( float4(Position.xy, 0.0f, 1.0), WorldView);
    float4 texPos = float4(Position.xy, 0.0, 1.0);
    Out.TexCoord.x = mul(texPos, TexGenS);
    Out.TexCoord.y = mul(texPos, TexGenT) + Time * 0.005;
    Out.Diffuse = 1.0;
    return Out;
}

VS_TS3 VSTS2_0(float3 Position : POSITION)
{
    VS_TS3 Out;
    Out.Position = mul(float4(Position.xy, 0.0f, 1.0), WorldView);
    float4 texPos = float4(Position.xy, 0.0, 1.0);
    Out.TexCoord.x = mul(texPos, TexGenS);
    Out.TexCoord.y = mul(texPos, TexGenT);
    float a = sin(Time + 1.0) * 0.15 + 0.4 + cos(Time * 33.0) * 0.03 + 0.03;
    Out.Diffuse = float2(1.0, a).xxxy;
    return Out;
}

VS_TS3 VSTS3_0(float3 Position : POSITION)
{
    VS_TS3 Out;
    Out.Position = mul(float4(Position.xy, 0.0f, 1.0), WorldView);
    float4 texPos = float4(Position.xy + sin(Time + 0.2) * 240.5, 0.0, 1.0);
    Out.TexCoord.x = (mul(texPos, TexGenS) + sin(Time * 0.1) * 0.1) * 0.8 + 0.1;
    Out.TexCoord.y = (mul(texPos, TexGenT) + cos(Time * 0.12 + 0.2) * 0.1) * 0.8 + 0.1;
    float a = sin(Time) * 0.15 + 0.4 + cos(Time * 33.0) * 0.03 + 0.03;
    Out.Diffuse = float2(1.0, a).xxxy;
    return Out;
}

float4 PSTS0_0(VS_TS0 input) : COLOR
{
    return tex2D(TexMapSamplerWrap, input.TexCoord);
}

float4 PSRegularTSX(VS_TS3 input) : COLOR
{
    return tex2D(TexMapSamplerWrap, input.TexCoord) * input.Diffuse;
}

technique Shape
{
    pass P0
    {
        VertexShader = compile vs_2_a VSShape();
        PixelShader  = compile ps_2_a PSDiffuse();
    }
}

technique ShapeTextureWrap
{
    pass P0
    {
        VertexShader = compile vs_2_a VSShapeTexture();
        PixelShader  = compile ps_2_a PSRegularWrap();
        AlphaTestEnable = false;
    }
}

technique ShapeTextureClamp
{
    pass P0
    {
        VertexShader = compile vs_2_a VSShapeTexture();
        PixelShader  = compile ps_2_a PSRegularClamp();
    }
}

technique Line
{
    pass P0
    {
        VertexShader = compile vs_2_a VSLine();
        PixelShader  = NULL;
        AlphaTestEnable = false;
        TexCoordIndex[0] = 0;
        TextureTransformFlags[0] = Disable;
        Sampler[0] = <TexMapSamplerClamp>;
    }
}

technique TS0
{
    pass P0
    {
        VertexShader = compile vs_2_a VSTS0_0();
        PixelShader  = compile ps_2_a PSTS0_0();
        AlphaTestEnable = false;
    }
    pass P1
    {
        VertexShader = compile vs_2_a VSTS0_1();
        PixelShader  = compile ps_2_a PSDiffuse();
        AlphaTestEnable = false;
    }

}

technique TS1
{
    pass P0
    {
        VertexShader = compile vs_2_a VSTS1_0();
        PixelShader  = compile ps_2_a PSRegularTSX();
        AlphaTestEnable = false;
    }
}

technique TS2
{
    pass P0
    {
        VertexShader = compile vs_2_a VSTS2_0();
        PixelShader  = compile ps_2_a PSRegularTSX();
        AlphaTestEnable = false;
    }
}

technique TS3
{
    pass P0
    {
        VertexShader = compile vs_2_a VSTS3_0();
        PixelShader  = compile ps_2_a PSRegularTSX();
        AlphaTestEnable = false;
    }
}
