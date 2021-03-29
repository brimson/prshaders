
#include "shaders/RaCommon.fx"
#include "shaders/RaShaderBMCommon.fx"

string GenerateStructs[] =
{
    "reqVertexElement",
    "GlobalParameters",
    "TemplateParameters",
    "InstanceParameters"
};

string reqVertexElement[] =
{
    "Position",
    "Normal",
    "Bone4Idcs",
    "TBase2D"
};

string GlobalParameters[] =
{
    "ViewProjection"
};

string TemplateParameters[] =
{
    "DiffuseMap"
};

string InstanceParameters[] =
{
    "GeomBones",
    "Transparency"
};

struct a2v
{
    float4 Pos          : POSITION;
    float4 BlendIndices : BLENDINDICES;
    float4 Tex          : TEXCOORD0;
};

struct v2p
{
    float4 Pos : POSITION0;
    float4 Tex : TEXCOORD0;
    float Fog  : FOG;
};

v2p vs(a2v input)
{
    v2f Out;

    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    Out.Pos	= float4(mul(input.Pos, GeomBones[IndexArray[0]]), 1.0);
    Out.Pos	= mul(Out.Pos, ViewProjection);
    Out.Fog = calcFog(Out.Pos.w);
    Out.Tex = input.Tex;
    return Out;
}

float4 ps(v2f input) : COLOR
{
    float4 outCol = tex2D(DiffuseMapSampler, input.Tex);
    outCol.rgb *= Transparency;
    return outCol;
}

technique defaultTechnique
{
    pass P0
    {
        vertexShader = compile vs_2_a vs();
        pixelShader  = compile ps_2_a ps();

        #ifdef ENABLE_WIREFRAME
            FillMode = WireFrame;
        #endif
        ZFunc = ALWAYS;
        AlphaTestEnable  = TRUE;
        AlphaRef         = 0;
        AlphaFunc        = GREATER;
        AlphaBlendEnable = TRUE;
        SrcBlend         = ONE;
        DestBlend        = ONE;
        ZWriteEnable     = false;
    }
}
