
float4 psDx9_FSBMPassThrough(VS2PS_blit indata) : COLOR {
    return tex2D(sampler0point, indata.TexCoord0);
}

float4 psDx9_FSBMPassThroughBilinear(VS2PS_blit indata) : COLOR {
    return tex2D(sampler0bilin, indata.TexCoord0);
}

float4 psDx9_FSBMPassThroughSaturateAlpha(VS2PS_blit indata) : COLOR {
    float4 color = tex2D(sampler0point, indata.TexCoord0);
    return float4(color.rgb, 1.0);
}

float4 psDx9_tr_PassThrough_point(VS2PS_tr_blit indata) : COLOR {
    return tex2D(sampler0point, indata.TexCoord0);
}

float4 psDx9_tr_PassThrough_aniso(VS2PS_tr_blit indata) : COLOR {
    return tex2D(sampler0aniso, indata.TexCoord0);
}

float4 psDx9_FSBMCopyOtherRGBToAlpha(VS2PS_blit indata) : COLOR {
    float4 color = tex2D(sampler0point, indata.TexCoord0);
    color.a = dot(1.0 / 3.0, color);
    return color;
}

float4 psDx9_FSBMConvertPosTo8Bit(VS2PS_blit indata) : COLOR {
    float4 viewPos = tex2D(sampler0point, indata.TexCoord0);
    viewPos /= 50.0;
    viewPos = viewPos * 0.5 + 0.5;
    return viewPos;
}

float4 psDx9_FSBMConvertNormalTo8Bit(VS2PS_blit indata) : COLOR {
    return normalize(tex2D(sampler0point, indata.TexCoord0)) * 0.5 + 0.5;
}

float4 psDx9_FSBMConvertShadowMapFrontTo8Bit(VS2PS_blit indata) : COLOR {
    return tex2D(sampler0point, indata.TexCoord0); // depths
}

float4 psDx9_FSBMConvertShadowMapBackTo8Bit(VS2PS_blit indata) : COLOR {
    return -tex2D(sampler0point, indata.TexCoord0);
}

float4 psDx9_FSBMHighPassFilter(VS2PS_blit indata) : COLOR {
    float4 color = tex2D(sampler0point, indata.TexCoord0);
    color -= highPassGate;
    return max(0.0, color);
}

float4 psDx9_FSBMHighPassFilterFade(VS2PS_blit indata) : COLOR {
    float4 color = tex2D(sampler0point, indata.TexCoord0);
    color.rgb = saturate(color.rgb - highPassGate);
    color.a = blurStrength;
    return color;
}

float4 psDx9_FSBMClear() : COLOR {
    return 0.0;
}

float4 psDx9_FSBMExtractGlowFilter(VS2PS_blit indata) : COLOR {
    float4 color = tex2D(sampler0point, indata.TexCoord0);
    return float4(color.rgb, 1.0);
}

float4 psDx9_FSBMExtractHDRFilterFade(VS2PS_blit indata) : COLOR {
    float4 color = tex2D(sampler0point, indata.TexCoord0);
    color.rgb = saturate(color.a - highPassGate);
    color.a = blurStrength;
    return color;
}

float4 psDx9_FSBMLuminancePlusBrightPassFilter(VS2PS_blit indata) : COLOR {
    return tex2D(sampler0point, indata.TexCoord0) * highPassGate;
}
