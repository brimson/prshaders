
float backbufferLerpbias : BACKBUFFERLERPBIAS;
float2 sampleoffset : SAMPLEOFFSET;
float2 fogStartAndEnd : FOGSTARTANDEND;
float3 fogColor : FOGCOLOR;
float glowStrength : GLOWSTRENGTH;

float nightFilter_noise_strength : NIGHTFILTER_NOISE_STRENGTH;
float nightFilter_noise : NIGHTFILTER_NOISE;
float nightFilter_blur : NIGHTFILTER_BLUR;
float nightFilter_mono : NIGHTFILTER_MONO;

float2 displacement : DISPLACEMENT;

float PI = 3.1415926535897932384626433832795;

// one pixel in screen texture units
float deltaU : DELTAU;
float deltaV : DELTAV;

texture texture0 : TEXLAYER0;
texture texture1 : TEXLAYER1;
texture texture2 : TEXLAYER2;
texture texture3 : TEXLAYER3;
texture texture4 : TEXLAYER4;
texture texture5 : TEXLAYER5;
texture texture6 : TEXLAYER6;

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

#define dSamplerBilinWrap AddressU = WRAP; AddressV = WRAP; AddressW = WRAP; MinFilter = LINEAR; MagFilter = LINEAR
sampler sampler0bilinwrap = sampler_state { Texture = (texture0); dSamplerBilinWrap; };
sampler sampler1bilinwrap = sampler_state { Texture = (texture1); dSamplerBilinWrap; };
sampler sampler2bilinwrap = sampler_state { Texture = (texture2); dSamplerBilinWrap; };
sampler sampler3bilinwrap = sampler_state { Texture = (texture3); dSamplerBilinWrap; };
sampler sampler4bilinwrap = sampler_state { Texture = (texture4); dSamplerBilinWrap; };
sampler sampler5bilinwrap = sampler_state { Texture = (texture5); dSamplerBilinWrap; };

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

struct VS2PS_Quad2
{
    float4 Pos       : POSITION;
    float2 TexCoord0 : TEXCOORD0;
    float2 TexCoord1 : TEXCOORD1;
};

struct VS2PS_Quad3
{
    float4 Pos       : POSITION;
    float2 TexCoord0 : TEXCOORD0;
    float2 TexCoord1 : TEXCOORD1;
    float2 TexCoord2 : TEXCOORD2;
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
    float4 diffuse =  tex2D(sampler0bilin, indata.TexCoord0);
    return glowStrength * float4(diffuse.rgb * (1.0 - diffuse.a), 1.0);
}

technique GlowMaterial
{
    pass p0
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
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

// TVEffect specific...

float time_0_X : FRACTIME;
float time_0_X_256 : FRACTIME256;
float sin_time_0_X : FRACSINE;

float interference : INTERFERENCE; // = 0.050000 || -0.015;
float distortionRoll : DISTORTIONROLL; // = 0.100000;
float distortionScale : DISTORTIONSCALE; // = 0.500000 || 0.2;
float distortionFreq : DISTORTIONFREQ; //= 0.500000;
float granularity : TVGRANULARITY; // = 3.5;
float tvAmbient : TVAMBIENT; // = 0.15

float3 tvColor : TVCOLOR;

VS2PS_Quad3 vs_TVEffect(APP2VS_Quad indata)
{
    VS2PS_Quad3 output;
    indata.Pos.xy = sign(indata.Pos.xy);
    output.Pos = float4(indata.Pos.xy, 0.0, 1.0);
    output.TexCoord0 = indata.Pos.xy * granularity + displacement;
    output.TexCoord1 = indata.Pos.xy * 0.25 + float2(-0.35, 0.25) * sin_time_0_X;
    output.TexCoord2 = indata.TexCoord0;
    return output;
}

PS2FB_Combine ps_TVEffect(VS2PS_Quad3 indata)
{
    PS2FB_Combine outdata;
    float2 img = indata.TexCoord2;
    float4 image = tex2D(sampler0bilin, img);

    if (interference <= 1)
    {
        float2 pos = indata.TexCoord0;
        float rand = tex2D(sampler2bilinwrap, pos) - 0.2;
        if (interference < 0) // thermal imaging
        {
            float hblur = 0.0010;
            float vblur = 0.0015;
            image *= 0.25;
            image += tex2D(sampler0bilin, img + float2( hblur,  vblur)) * 0.0625;
            image += tex2D(sampler0bilin, img + float2(-hblur, -vblur)) * 0.0625;
            image += tex2D(sampler0bilin, img + float2(-hblur,  vblur)) * 0.0625;
            image += tex2D(sampler0bilin, img + float2( hblur, -vblur)) * 0.0625;
            image += tex2D(sampler0bilin, img + float2( hblur, 0.0)) * 0.125;
            image += tex2D(sampler0bilin, img + float2(-hblur, 0.0)) * 0.125;
            image += tex2D(sampler0bilin, img + float2( 0.0,  vblur)) * 0.125;
            image += tex2D(sampler0bilin, img + float2( 0.0, -vblur)) * 0.125;
            outdata.Col0.r = lerp(0.43,0,image.g) + image.r; // terrain max light mod should be 0.608
            outdata.Col0.r -= interference * rand; // add -interference
            outdata.Col0 = float4(tvColor * outdata.Col0.rrr,image.a);
        }
        else // normal tv effect
        {
            float noisy = tex2D(sampler1bilinwrap, indata.TexCoord1) - 0.5;
            float dst = frac(pos.y * distortionFreq + distortionRoll * sin_time_0_X);
            dst *= (1.0 - dst);
            dst /= 1.0 + distortionScale * abs(pos.y);
            img.x += distortionScale * noisy * dst;
            image = dot(float3(0.3, 0.59, 0.11), image);
            outdata.Col0 = float4(tvColor, 1.0) * (interference * rand + image * (1.0 - tvAmbient) + tvAmbient);
        }
    }
    else outdata.Col0 = image;
    return outdata;
}

//	TV Effect with usage of gradient texture

PS2FB_Combine ps_TVEffect_Gradient_Tex(VS2PS_Quad3 indata)
{
    PS2FB_Combine outdata;
    if (interference >= 0 && interference <= 1)
    {
        float2 pos = indata.TexCoord0;
        float2 img = indata.TexCoord2;
        float rand = tex2D(sampler2bilinwrap, pos) - 0.2;
        float noisy = tex2D(sampler1bilinwrap, indata.TexCoord1) - 0.5;
        float dst = frac(pos.y * distortionFreq + distortionRoll * sin_time_0_X);
        dst *= (1.0 - dst);
        dst /= 1.0 + distortionScale * abs(pos.y);
        img.x += distortionScale * noisy * dst;
        float4 image = dot(float3(0.3, 0.59, 0.11), tex2D(sampler0bilin, img));
        float4 intensity = (interference * rand + image * (1.0 - tvAmbient) + tvAmbient);
        float4 gradient_col = tex2D(sampler3bilin, float2(intensity.r, 0.0f));
        outdata.Col0 = float4( gradient_col.rgb, intensity.a );
    }
    else outdata.Col0 = tex2D(sampler0bilin, indata.TexCoord2);
    return outdata;
}

technique TVEffect
{
    pass p0
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;

        VertexShader = compile vs_3_0 vs_TVEffect();
        PixelShader = compile ps_3_0 ps_TVEffect();
    }
}

technique TVEffect_Gradient_Tex
{
    pass p0
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;

        VertexShader = compile vs_3_0 vs_TVEffect();
        PixelShader = compile ps_3_0 ps_TVEffect_Gradient_Tex();
    }
}

//	Wave Distortion

VS2PS_Quad2 vs_WaveDistortion( APP2VS_Quad indata )
{
    VS2PS_Quad2 output;
    output.Pos = float4(indata.Pos.xy, 0.0, 1.0);
    output.TexCoord0 = indata.TexCoord0;
    output.TexCoord1 = indata.Pos.xy;
    return output;
}

PS2FB_Combine ps_WaveDistortion(VS2PS_Quad2 indata)
{
    PS2FB_Combine outdata;
    outdata.Col0 = 0.0;
    return outdata;
}

technique WaveDistortion
{
    pass p0
    {
        ZEnable = FALSE;
        AlphaBlendEnable = TRUE;
        AlphaTestEnable = FALSE;
        StencilEnable = FALSE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;

        VertexShader = compile vs_3_0 vs_WaveDistortion();
        PixelShader = compile ps_3_0 ps_WaveDistortion();
    }
}

VS2PS_Quad2 vsDx9_Flashbang(APP2VS_Quad indata)
{
    VS2PS_Quad2 outdata;
    outdata.Pos = float4(indata.Pos.x, indata.Pos.y, 0.0, 1.0);
    outdata.TexCoord0 = indata.TexCoord0;
    outdata.TexCoord1 = indata.TexCoord0;
    return outdata;
}

PS2FB_Combine psDx9_Flashbang(VS2PS_Quad2 indata)
{
    PS2FB_Combine outdata;
    float4  acc  = tex2D(sampler0bilin, indata.TexCoord0) * 0.50;
            acc += tex2D(sampler1bilin, indata.TexCoord0) * 0.25;
            acc += tex2D(sampler2bilin, indata.TexCoord0) * 0.15;
            acc += tex2D(sampler3bilin, indata.TexCoord0) * 0.10;

    outdata.Col0 = acc;
    outdata.Col0.a = backbufferLerpbias;
    return outdata;
}

technique Flashbang
{
    pass P0
    {
        ZEnable = FALSE;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        StencilEnable = FALSE;

        VertexShader = compile vs_3_0 vsDx9_Flashbang();
        PixelShader = compile ps_3_0 psDx9_Flashbang();
    }
}
