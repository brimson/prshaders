
float4x4 World;
float4x4 ViewProjection;
int textureFactor = 0xffAFFFaF;
bool alphaBlendEnable = false;

// VS --- PS

string reqVertexElement[] =
{
    "Position"
};

string InstanceParameters[] =
{
    "World",
    "ViewProjection"
};

struct a2f
{
    float4 pos : POSITION0;
};

float4 vertexShader(a2f input) : POSITION0
{
    return mul(float4(input.pos, 1.0), mul(World, ViewProjection));
}

float4 shader() : COLOR
{
    return float4(0.9, 0.4, 0.8, 1.0);
};

technique defaultShader
{
    pass P0
    {
        pixelshader  = compile ps_2_a shader();
        vertexShader = compile vs_2_a vertexShader();
        #ifdef ENABLE_WIREFRAME
            FillMode = WireFrame;
        #endif
        SrcBlend         = srcalpha;
        DestBlend        = invsrcalpha;
        fogenable        = false;
        CullMode         = NONE;
        AlphaBlendEnable = <alphaBlendEnable>;
        AlphaTestEnable  = false;
    }
}