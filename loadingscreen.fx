
float4x4 WorldViewProj : TRANSFORM;
texture TexMap : TEXTURE;

sampler TexMapSampler = sampler_state
{
    Texture   = <TexMap>;
    AddressU  = Wrap;
    AddressV  = Wrap;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
};

struct VS_OUT
{
    float4 Position : POSITION;
    float4 Diffuse  : COLOR0;
    float2 TexCoord : TEXCOORD0;
};

VS_OUT VSScreen(
    float3 Position : POSITION,
    float4 Diffuse : COLOR0,
    float2 TexCoord : TEXCOORD0)
{
    VS_OUT Out;
    Out.Position = float4(Position.x, Position.y, 0.0, 1.0);
    Out.Diffuse = Diffuse;
    Out.TexCoord = TexCoord;
    return Out;
}

float4 PSScreen(VS_OUT input) : COLOR
{
    float4 tex = tex2D(TexMapSampler, input.TexCoord);
    float4 output;
    output.rgb = tex * input.Diffuse;
    output.a = input.Diffuse.a;
    return output;
}

technique Screen
{
    pass P0
    {
        VertexShader = compile vs_2_a VSScreen();
        PixelShader  = compile ps_2_a PSScreen();
        AlphaBlendEnable = false;
        StencilEnable = false;
        AlphaTestEnable = false;
        CullMode = None;
    }
}