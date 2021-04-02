
float4x4 World;
float4x4 ViewProjection;
int textureFactor = 0xffAFFFaF;
bool alphaBlendEnable = false;

string reqVertexElement[] =
{
    "Position"
};

float4 vertexShader(float3 inPos: POSITION0) : POSITION0
{
    return mul(float4(inPos, 1), mul(World, ViewProjection));
}

float4 shader() : COLOR
{
    return float4(0.9, 0.4, 0.8, 1);
};

struct VS_OUTPUT
{
    float4 Pos : POSITION0;
};

string InstanceParameters[] =
{
    "World",
    "ViewProjection"
};

technique defaultShader
{
    pass P0
    {
        pixelshader = compile ps_2_a shader();
        vertexShader = compile vs_2_a vertexShader();

        #ifdef ENABLE_WIREFRAME
            FillMode = WireFrame;
        #endif

        SrcBlend = srcalpha;
        DestBlend = invsrcalpha;
        fogenable = false;
        CullMode = NONE;
        AlphaBlendEnable = <alphaBlendEnable>;
        AlphaTestEnable = false;
    }
}