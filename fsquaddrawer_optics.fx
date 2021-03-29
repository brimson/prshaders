
struct vs2ps_optics {
    float4 vpos    : POSITION;
    float2 uv_a    : TEXCOORD0;
    float4 uv_b[8] : TEXCOORD1;
};

vs2ps_optics vsDx9_tr_opticsBlurH(APP2VS_blit input) {
    float kAspectRatio = highPassGate / 1000.0f; // floor() isn't used for perfomance reasons
    float kBlurSize = 0.0033333333 / kAspectRatio;

    vs2ps_optics o;
    o.vpos = float4(input.Pos.xy, 0.0, 1.0);

    float2 coord = input.TexCoord0;
    o.uv_a = coord;

    for(int i = 1; i < 9; i++) {
        o.uv_b[i - 1].xy = float2(coord.x + (i * kBlurSize), coord.y);
        o.uv_b[i - 1].zw = float2(coord.x - (i * kBlurSize), coord.y);
    }

    return o;
}

vs2ps_optics vsDx9_tr_opticsBlurV(APP2VS_blit input) {
    float kAspectRatio = highPassGate / 1000.0f; // floor() isn't used for perfomance reasons
    float kBlurSize = 0.0033333333; // 1/300 - no ghosting for vertical resolutions up to 1200 pixels

    vs2ps_optics o;
    o.vpos = float4(input.Pos.xy, 0.0, 1.0);

    float2 coord = input.TexCoord0;
    o.uv_a = coord;

    for(int i = 1; i < 9; i++) {
        o.uv_b[i - 1].xy = float2(coord.x, coord.y + (i * kBlurSize));
        o.uv_b[i - 1].zw = float2(coord.x, coord.y - (i * kBlurSize));
    }

    return o;
}

const float tr_gauss[9] = {
    0.087544737, 0.085811235, 0.080813978,
    0.073123511, 0.063570527, 0.053098567,
    0.042612598, 0.032856512, 0.024340702
};

float4 psDx9_tr_opticsBlurH(vs2ps_optics input) : COLOR {
    float4 color = tex2D(sampler0point, input.uv_a) * tr_gauss[0];
    for (int i = 1; i < 9; i++)
    {
        color += tex2D(sampler0bilin, input.uv_b[i - 1].xy) * tr_gauss[i];
        color += tex2D(sampler0bilin, input.uv_b[i - 1].zw) * tr_gauss[i];
    }
    return color;
}

float4 psDx9_tr_opticsBlurV(vs2ps_optics input) : COLOR {
    float4 color = tex2D(sampler0point, input.uv_a) * tr_gauss[0];
    for (int i = 1; i < 9; i++)
    {
        color += tex2D(sampler0bilin, input.uv_b[i - 1].xy) * tr_gauss[i];
        color += tex2D(sampler0bilin, input.uv_b[i - 1].zw) * tr_gauss[i];
    }
    return color;
}

float4 psDx9_tr_opticsNoBlurCircle(VS2PS_tr_blit indata) : COLOR {
    float aspectRatio = highPassGate / 1000.0f; // aspect ratio (1.333 for 4:3) (floor() isn't used for perfomance reasons)
    float blurAmountMod = frac(highPassGate) / 0.9; // used for the fade-in effect

    float radius1 = blurStrength / 1000.0f; // 0.2 by default (floor() isn't used for perfomance reasons)
    float radius2 = frac(blurStrength); // 0.25 by default

    float dist = length((indata.TexCoord0 - 0.5) * float2(aspectRatio, 1.0)); // get distance from the center of the screen
    float blurAmount = saturate((dist - radius1) / (radius2 - radius1)) * blurAmountMod;

    return float4(tex2D(sampler0aniso, indata.TexCoord0).rgb, blurAmount);
}
