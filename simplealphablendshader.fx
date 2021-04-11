
texture basetex: TEXLAYER0
<
    string File = "aniso2.dds";
    string TextureType = "2D";
>;

float4x4 mWorldViewProj : WorldViewProjection;

struct APP2VS
{
    float4 Pos  : POSITION;
    float2 Tex0 : TEXCOORD0;
};

struct VS2PS
{
    float4 HPos : POSITION;
    float2 Tex0 : TEXCOORD0;
};

sampler diffuseSampler = sampler_state
{
    Texture = <basetex>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
};

VS2PS VShader(APP2VS indata, uniform float4x4 wvp)
{
    VS2PS outdata;
    outdata.HPos = mul(float4(indata.Pos.xyz, 1.0f), wvp);
    outdata.Tex0 = indata.Tex0;
    return outdata;
}

float4 PShader(VS2PS input) : COLOR
{
    return tex2D(diffuseSampler, input.Tex0);
}

technique t0_States <bool Restore = true;>
{
    pass BeginStates
	{
        ZEnable = true;
        // MatsD 030903: Due to transparent isn't sorted yet. Write Z values
        ZWriteEnable = true;

        CullMode = None;
        AlphaBlendEnable = true;
        SrcBlend = ONE;
        DestBlend = ONE;
    }

    pass EndStates { }
}

technique t0
{
    pass p0
    {
        VertexShader = compile vs_2_a VShader(mWorldViewProj);
        PixelShader = compile ps_2_a PShader();
    }
}
