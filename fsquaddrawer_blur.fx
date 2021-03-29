
struct VS2PS_4TapFilter {
    float4 Pos             : POSITION;
    float2 FilterCoords[4] : TEXCOORD0;
};

struct VS2PS_5SampleFilter {
    float4 Pos             : POSITION;
    float2 TexCoord0       : TEXCOORD0;
    float4 FilterCoords[2] : TEXCOORD1;
};

VS2PS_4TapFilter vsDx9_4TapFilter(APP2VS_blit indata, uniform float4 offsets[4]) {
    VS2PS_4TapFilter outdata;
    outdata.Pos = float4(indata.Pos.x, indata.Pos.y, 0.0, 1.0);

    for (int i = 0; i < 4; ++i) {
        outdata.FilterCoords[i] = indata.TexCoord0 + offsets[i].xy;
    }

    return outdata;
}

VS2PS_5SampleFilter vsDx9_5SampleFilter(APP2VS_blit indata,
                                        uniform float offsets[5],
                                        uniform bool horizontal) {
    VS2PS_5SampleFilter outdata;
    outdata.Pos = float4(indata.Pos.x, indata.Pos.y, 0, 1);

    if(horizontal) {
        outdata.TexCoord0 = indata.TexCoord0 + float2(offsets[4],0);
    } else{
        outdata.TexCoord0 = indata.TexCoord0 + float2(0,offsets[4]);
    }

    for(int i=0; i<2; ++i) {
        if(horizontal) {
            outdata.FilterCoords[i].xy = indata.TexCoord0.xy + float2(offsets[i*2], 0);
            outdata.FilterCoords[i].zw = indata.TexCoord0.xy + float2(offsets[i*2+1], 0);
        } else {
            outdata.FilterCoords[i].xy = indata.TexCoord0.xy + float2(0, offsets[i*2]);
            outdata.FilterCoords[i].zw = indata.TexCoord0.xy + float2(0, offsets[i*2+1]);
        }
    }

    return outdata;
}

float4 psDx9_FSBMScaleUp4x4LinearFilter(VS2PS_blit indata) : COLOR {
    return tex2D(sampler0bilin, indata.TexCoord0);
}

float4 psDx9_FSBMScaleDown2x2Filter(VS2PS_blit indata) : COLOR {
    float4 accum = 0.0;
    accum  = tex2D(sampler0point, indata.TexCoord0 + scaleDown2x2SampleOffsets[0]);
    accum += tex2D(sampler0point, indata.TexCoord0 + scaleDown2x2SampleOffsets[1]);
    accum += tex2D(sampler0point, indata.TexCoord0 + scaleDown2x2SampleOffsets[2]);
    accum += tex2D(sampler0point, indata.TexCoord0 + scaleDown2x2SampleOffsets[3]);
    return accum * 0.25; // div 4
}

float4 psDx9_FSBMScaleDown4x4Filter(VS2PS_blit indata) : COLOR {
    float4 accum = 0.0;
    for(int tap = 0; tap < 16; ++tap) {
        accum += tex2D(sampler0point, indata.TexCoord0 + scaleDown4x4SampleOffsets[tap]);
    }
    return accum * 0.0625; // div 16
}

float4 psDx9_FSBMScaleDown4x4LinearFilter(VS2PS_4TapFilter indata) : COLOR {
    float4 accum = 0.0;
    accum = tex2D(sampler0bilin, indata.FilterCoords[0].xy);
    accum += tex2D(sampler0bilin, indata.FilterCoords[1].xy);
    accum += tex2D(sampler0bilin, indata.FilterCoords[2].xy);
    accum += tex2D(sampler0bilin, indata.FilterCoords[3].xy);
    return accum * 0.25;
}

float4 psDx9_FSBMGaussianBlur5x5CheapFilter(VS2PS_blit indata) : COLOR {
    float4 accum = 0.0;
    for(int tap = 0; tap < 13; ++tap) {
        accum += tex2D(sampler0point, indata.TexCoord0 + gaussianBlur5x5CheapSampleOffsets[tap])
        * gaussianBlur5x5CheapSampleWeights[tap];
    }
    return accum;
}

float4 psDx9_FSBMGaussianBlur5x5CheapFilterBlend(VS2PS_blit indata) : COLOR {
    float4 accum = 0.0;
    for(int tap = 0; tap < 13; ++tap) {
        accum += tex2D(sampler0point, indata.TexCoord0 + gaussianBlur5x5CheapSampleOffsets[tap])
        * gaussianBlur5x5CheapSampleWeights[tap];
    }
    accum.a = blurStrength;
    return accum;
}

float4 psDx9_FSBMGaussianBlur15x15HorizontalFilter(VS2PS_blit indata) : COLOR {
    float4 accum = 0.0;
    for(int tap = 0; tap < 15; ++tap) {
        accum += tex2D(sampler0point, indata.TexCoord0 + gaussianBlur15x15HorizontalSampleOffsets[tap])
        * gaussianBlur15x15HorizontalSampleWeights[tap];
    }
    return accum;
}

float4 psDx9_FSBMGaussianBlur15x15VerticalFilter(VS2PS_blit indata) : COLOR
{
    float4 accum = 0.0;
    for(int tap = 0; tap < 15; ++tap)
        accum += tex2D(sampler0point, indata.TexCoord0 + gaussianBlur15x15VerticalSampleOffsets[tap])
        * gaussianBlur15x15VerticalSampleWeights[tap];

    return accum;
}

float4 psDx9_FSBMGaussianBlur15x15HorizontalFilter2(VS2PS_blit indata) : COLOR
{
    float4 accum = 0.0;
    for(int tap = 0; tap < 15; ++tap)
        accum += tex2D(sampler0point, indata.TexCoord0 + 2*gaussianBlur15x15HorizontalSampleOffsets[tap])
        * gaussianBlur15x15HorizontalSampleWeights[tap];

    return accum;
}

float4 psDx9_FSBMGaussianBlur15x15VerticalFilter2(VS2PS_blit indata) : COLOR
{
    float4 accum = 0.0;
    for(int tap = 0; tap < 15; ++tap)
        accum += tex2D(sampler0point, indata.TexCoord0 + 2.0 * gaussianBlur15x15VerticalSampleOffsets[tap])
        * gaussianBlur15x15VerticalSampleWeights[tap];

    return accum;
}

float4 psDx9_FSBMGrowablePoisson13Filter(VS2PS_blit indata) : COLOR {
    float4 accum = 0.0;
    float samples = 1.0;
    accum = tex2D(sampler0point, indata.TexCoord0);

    for(int tap = 0; tap < 11; ++tap) {
        float4 v = tex2D(sampler0point, indata.TexCoord0 + growablePoisson13SampleOffsets[tap] * 0.1 * accum.a);
        if(v.a > 0) {
            accum.rgb += v;
            samples += 1;
        }
    }

    return accum / samples;
}

float4 psDx9_FSBMGrowablePoisson13AndDilationFilter(VS2PS_blit indata) : COLOR {
    float4 center = tex2D(sampler0point, indata.TexCoord0);
    float4 accum = 0.0;

    if(center.a > 0) {
        accum.rgb = center;
        accum.a = 1;
    }

    for(int tap = 0; tap < 11; ++tap) {
        float scale = 3.0 * center.a;
        if(scale == 0) {
            scale = 1.5;
        }
        float4 v = tex2D(sampler0point, indata.TexCoord0 + growablePoisson13SampleOffsets[tap]*scale);
        if(v.a > 0) {
            accum.rgb += v;
            accum.a += 1;
        }
    }

    return accum / accum.a;
}

float4 psDx9_FSBMGlowFilter(VS2PS_5SampleFilter indata,
                            uniform float weights[5],
                            uniform bool horizontal) : COLOR {
    float4 color = weights[0] * tex2D(sampler0bilin, indata.FilterCoords[0].xy);
    color += weights[1] * tex2D(sampler0bilin, indata.FilterCoords[0].zw);
    color += weights[2] * tex2D(sampler0bilin, indata.FilterCoords[1].xy);
    color += weights[3] * tex2D(sampler0bilin, indata.FilterCoords[1].zw);
    color += weights[4] * tex2D(sampler0bilin, indata.TexCoord0);
    return color;
}

float4 psDx9_FSBMBloomFilter(VS2PS_5SampleFilter indata,
                             uniform bool is_blur) : COLOR {
    float4 color;

    if(is_blur) {
        color.a = blurStrength;
    }

    color.rgb += tex2D(sampler0bilin, indata.TexCoord0.xy);

    for(int i = 0; i < 2; ++i) {
        color.rgb += tex2D(sampler0bilin, indata.FilterCoords[i].xy);
        color.rgb += tex2D(sampler0bilin, indata.FilterCoords[i].zw);
    }

    color.rgb /= 5;
    return color;
}

float4 psDx9_FSBMScaleUpBloomFilter(VS2PS_blit indata) : COLOR {
    float4 close = tex2D(sampler0point, indata.TexCoord0);
    return close;
}

float4 psDx9_FSBMBlur(VS2PS_blit indata) : COLOR {
    return float4(tex2D(sampler0point, indata.TexCoord0).rgb, blurStrength);
}
