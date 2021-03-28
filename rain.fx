float4x4 wvp : WORLDVIEWPROJ;

float4 cellPositions[32] : CELLPOSITIONS;
float4 deviations[16] : DEVIATIONGROUPS;

float4 particleColor: PARTICLECOLOR;

float4 cameraPos : CAMERAPOS;

float3 fadeOutRange : FADEOUTRANGE;
float3 fadeOutDelta : FADEOUTDELTA;

float3 pointScale : POINTSCALE;
float particleSize : PARTICLESIZE;
float maxParticleSize : PARTICLEMAXSIZE;

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
    float3 Pos      : POSITION;
    float4 Data     : COLOR0;
    float2 TexCoord : TEXCOORD0;
};


// Point Technique

struct POINT_VSOUT
{
    float4 Pos       : POSITION;
    float2 TexCoord  : TEXCOORD0;
    float4 Color     : COLOR0;
    float  pointSize : PSIZE;
};

POINT_VSOUT vsPoint(VSINPUT input)
{
    POINT_VSOUT output;

    float3 cellPos = cellPositions[input.Data.x];
    float3 deviation = deviations[input.Data.y];

    float3 particlePos = input.Pos + cellPos + deviation;

    float3 camDelta = abs(cameraPos.xyz-particlePos);
    float camDist = length(camDelta);

    camDelta -= fadeOutRange;
    camDelta /= fadeOutDelta;
    float alpha = 1.f-length(saturate(camDelta));

    output.Color = float4(particleColor.rgb,particleColor.a*alpha);

    output.Pos = mul(float4(particlePos,1), wvp);
    output.TexCoord = input.TexCoord;

    output.pointSize = min(particleSize * sqrt(1/(pointScale[0]+pointScale[1]*camDist)), maxParticleSize);

    return output;
}

float4 psPoint(POINT_VSOUT input) : COLOR
{
    float4 texCol = tex2D(sampler0, input.TexCoord);
    return texCol * input.Color;
}

technique Point
{
    pass p0
    {
        FogEnable = FALSE;
        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = false;
        AlphaBlendEnable = TRUE;
        SrcBlend = SrcAlpha;
        DestBlend = One;
        CullMode = NONE;

        VertexShader = compile vs_2_a vsPoint();
        PixelShader = compile ps_2_a psPoint();
    }
}


// Line Technique

struct LINE_VSOUT
{
    float4 Pos      : POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Color    : COLOR0;
};

LINE_VSOUT vsLine(VSINPUT input)
{
    LINE_VSOUT output;

    float3 cellPos = cellPositions[input.Data.x];
    float3 particlePos = input.Pos + cellPos;

    float3 camDelta = abs(cameraPos.xyz-particlePos);
    camDelta -= fadeOutRange;
    camDelta /= fadeOutDelta;
    float alpha = 1.f-length(saturate(camDelta));

    output.Color = float4(particleColor.rgb,particleColor.a*alpha);

    output.Pos = mul(float4(particlePos,1), wvp);
    output.TexCoord = input.TexCoord;

    return output;
}

float4 psLine(LINE_VSOUT input) : COLOR
{
    return input.Color;
}

technique Line
{
    pass p0
    {
        FogEnable = FALSE;
        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = false;
        AlphaBlendEnable = TRUE;
        SrcBlend = SrcAlpha;
        DestBlend = One;
        CullMode = NONE;

        VertexShader = compile vs_2_a vsLine();
        PixelShader = compile ps_2_a psLine();
    }
}


// Debug Cell Technique

struct CELL_VSOUT
{
    float4 Pos      : POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Color    : COLOR0;
};

CELL_VSOUT vsCells(VSINPUT input)
{
    CELL_VSOUT output;

    float3 cellPos = cellPositions[input.Data.x];
    float3 particlePos = input.Pos + cellPos;

    output.Color = particleColor;

    output.Pos = mul(float4(particlePos,1), wvp);
    output.TexCoord = input.TexCoord;

    return output;
}

float4 psCells(CELL_VSOUT input) : COLOR
{
    return input.Color;
}

technique Cells
{
    pass p0
    {
        FogEnable = FALSE;
        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = false;
        AlphaBlendEnable = TRUE;
        SrcBlend = SrcAlpha;
        DestBlend = One;
        CullMode = NONE;

        VertexShader = compile vs_2_a vsCells();
        PixelShader = compile ps_2_a psCells();
    }
}