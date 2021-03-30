texture texture0 : TEXLAYER0;
texture texture1 : TEXLAYER1;
texture texture2 : TEXLAYER2;
texture texture3 : TEXLAYER3;
texture texture4 : TEXLAYER4;
texture texture5 : TEXLAYER5;
texture texture6 : TEXLAYER6;

float backbufferLerpbias : BACKBUFFERLERPBIAS;
float2 sampleoffset : SAMPLEOFFSET;
float2 fogStartAndEnd : FOGSTARTANDEND;
float3 fogColor : FOGCOLOR;

#define dSampler AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT
sampler sampler0 = sampler_state { Texture = (texture0); dSampler; };
sampler sampler1 = sampler_state { Texture = (texture1); dSampler; };
sampler sampler2 = sampler_state { Texture = (texture2); dSampler; };
sampler sampler3 = sampler_state { Texture = (texture3); dSampler; };
sampler sampler4 = sampler_state { Texture = (texture4); dSampler; };
sampler sampler5 = sampler_state { Texture = (texture5); dSampler; };
sampler sampler6 = sampler_state { Texture = (texture6); dSampler; };

#define dSamplerBilin AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR
sampler sampler0bilin = sampler_state { Texture = (texture0); dSamplerBilin; };
sampler sampler1bilin = sampler_state { Texture = (texture1); dSamplerBilin; };
sampler sampler2bilin = sampler_state { Texture = (texture2); dSamplerBilin; };
sampler sampler3bilin = sampler_state { Texture = (texture3); dSamplerBilin; };
sampler sampler4bilin = sampler_state { Texture = (texture4); dSamplerBilin; };
sampler sampler5bilin = sampler_state { Texture = (texture5); dSamplerBilin; };

float NPixels : NPIXLES = 1.0;
float2 ScreenSize : VIEWPORTSIZE = { 800.0, 600.0 };
float Glowness : GLOWNESS = 3.0;
float Cutoff : cutoff = 0.8;

struct APP2VS_Quad
{
    float2 Pos       : POSITION0;
    float2 TexCoord0 : TEXCOORD0;
};

struct VS2PS_Quad
{
    float4 Pos       : POSITION;
    float2 TexCoord0 : TEXCOORD0;
};

struct vs2ps_tinnitus
{
    float4 vpos  : POSITION;
    float4 uv[5] : TEXCOORD0;
};

struct PS2FB_Combine
{
    float4 Col0 : COLOR0;
};

VS2PS_Quad vsDx9_OneTexcoord(APP2VS_Quad indata)
{
    VS2PS_Quad outdata;
    outdata.Pos = float4(indata.Pos.xy, 0.0, 1.0);
    outdata.TexCoord0 = indata.TexCoord0;
    return outdata;
}

vs2ps_tinnitus vsDx9_Tinnitus(APP2VS_Quad input)
{
    vs2ps_tinnitus o;
    o.vpos = float4(input.Pos, 0.0, 1.0);
    float2 coord = input.TexCoord0;
    o.uv[0]    = coord.xyxy;
    o.uv[1].xy = coord + 0.02 * float2(-1.0,  1.0);
    o.uv[1].zw = coord + 0.02 * float2( 0.0,  1.0);
    o.uv[2].xy = coord + 0.02 * float2( 1.0,  1.0);
    o.uv[2].zw = coord + 0.02 * float2(-1.0,  0.0);
    o.uv[3].xy = coord + 0.02 * float2( 1.0,  0.0);
    o.uv[3].zw = coord + 0.02 * float2(-1.0, -1.0);
    o.uv[4].xy = coord + 0.02 * float2( 0.0, -1.0);
    o.uv[4].zw = coord + 0.02 * float2( 1.0, -1.0);
    return o;
}

PS2FB_Combine psDx9_Tinnitus(vs2ps_tinnitus input)
{
    PS2FB_Combine outdata;
    float4 blur = 0.0;

    for(int i = 1; i <= 4; i++) {
        blur += 0.125 * tex2D(sampler0bilin, input.uv[i].xy);
        blur += 0.125 * tex2D(sampler0bilin, input.uv[i].zw);
    }

    float4 color = tex2D(sampler0bilin, input.uv[0].xy);
    float2 tcxy = input.uv[0].xy;

    // parabolic function for x opacity to darken the edges
    // exponential function for yopacity to darken the lower part of the screen
    float darkness = max(4.0 * tcxy.x * tcxy.x - 4.0 * tcxy.x + 1.0, saturate((pow(2.5, tcxy.y) - tcxy.y / 2.0 - 1.0)));

    // weight the blurred version more heavily as you go lower on the screen
    float4 finalcolor = lerp(color, blur, saturate(2.0 * (pow(4.0, tcxy.y) - tcxy.y - 1.0)));

    // darken the left, right, and bottom edges of the final product
    finalcolor = lerp(finalcolor, float4(0.0, 0.0, 0.0, 1.0), darkness);
    float4 outcolor = float4(finalcolor.rgb, saturate(2.0 * backbufferLerpbias));
    outdata.Col0 = outcolor;
    return outdata;
}

technique Tinnitus
{
    pass p0
    {
        ZEnable = TRUE;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        StencilEnable = FALSE;

        VertexShader = compile vs_3_0 vsDx9_Tinnitus();
        PixelShader = compile ps_3_0 psDx9_Tinnitus();
    }
}

float4 psDx9_Glow(VS2PS_Quad indata) : COLOR
{
    return tex2D(sampler0bilin, indata.TexCoord0);
}

float4 psDx9_GlowMaterial(VS2PS_Quad indata) : COLOR
{
    float4 diffuse = tex2D(sampler0bilin, indata.TexCoord0);
    return float4(diffuse.rgb * (1.0 - diffuse.a), 1.0);
}

technique GlowMaterial
{
    pass p0
    {
        ZEnable = FALSE;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCCOLOR;
        DestBlend = ONE;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 0x80;
        StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 vsDx9_OneTexcoord();
        PixelShader = compile ps_3_0 psDx9_GlowMaterial();
    }
}

technique Glow
{
    pass p0
    {
        ZEnable = FALSE;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCCOLOR;
        DestBlend = ONE;

        VertexShader = compile vs_3_0 vsDx9_OneTexcoord();
        PixelShader = compile ps_3_0 psDx9_Glow();
    }
}

float4 psDx9_Fog(VS2PS_Quad indata) : COLOR
{
    float3 wPos = tex2D(sampler0, indata.TexCoord0);
    float uvCoord =  saturate((wPos.zzzz-  fogStartAndEnd.r) / fogStartAndEnd.g);
    return saturate(float4(fogColor.rgb, uvCoord));
    return tex2D(sampler1, float2(uvCoord, 0.0)) * fogColor.rgbb;
}

technique Fog
{
    pass p0
    {
        ZEnable = FALSE;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 0x00;
        StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 vsDx9_OneTexcoord();
        PixelShader = compile ps_3_0 psDx9_Fog();
    }
}
