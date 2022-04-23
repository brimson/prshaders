
#define SAMPLER(NAME, TEXTURE) \
    sampler NAME = sampler_state \
    { \
        Texture = TEXTURE; \
        AddressU = CLAMP; \
        AddressV = CLAMP; \
        MinFilter = LINEAR; \
        MagFilter = LINEAR; \
    };

float4x4 _ViewProj : VIEWPROJ;
float4x4 _WorldViewProj : WORLDVIEWPROJ;

float4x4 _ObjWorld : OBJWORLD;
float4x4 _CamView : CAMVIEW;
float4x4 _CamProj : CAMPROJ;

float4x4 _LightViewProj : LIGHTVIEWPROJ;
float4x4 _LightOccluderViewProj : LIGHTOCCLUDERVIEWPROJ;
float4x4 _CamViewI : CAMVIEWI;
float4x4 _CamProjI : CAMPROJI;
float4 _ViewportMap : VIEWPORTMAP;
float4 _ViewportMap2 : VIEWPORTMAP2;

float4 _EyePos : EYEPOS;
float4 _EyeDof : EYEDOF;

float4 _LightWorldPos : LIGHTWORLDPOS;
float4 _LightDir : LIGHTDIR;
float4 _LightPos : LIGHTPOS;
float4 _LightCol : LIGHTCOL;
float _LightAttenuationRange : LIGHTATTENUATIONRANGE;
float _LightAttenuationRangeInv : LIGHTATTENUATIONRANGEINV;

float4 _ProjectorMask : PROJECTORMASK;

float4 _ParaboloidZValues : PARABOLOIDZVALUES;

dword _DwStencilFunc : STENCILFUNC = 3;
dword _DwStencilRef : STENCILREF = 0;
dword _DwStencilPass : STENCILPASS = 1;

float _ShadowIntensityBias : SHADOWINTENSITYBIAS;
float _LightmapIntensityBias : LIGHTMAPINTENSITYBIAS;

texture Texture0 : TEXLAYER0;
texture Texture1 : TEXLAYER1;
texture Texture2 : TEXLAYER2;
texture Texture3 : TEXLAYER3;
texture Texture4 : TEXLAYER4;
texture Texture5 : TEXLAYER5;
texture Texture6 : TEXLAYER6;

SAMPLER(Sampler_0, Texture0)
SAMPLER(Sampler_1, Texture1)
SAMPLER(Sampler_2, Texture2)
SAMPLER(Sampler_3, Texture3)
SAMPLER(Sampler_4, Texture4)
SAMPLER(Sampler_5, Texture5)
SAMPLER(Sampler_6, Texture6)

struct APP2VS_Quad
{
    float2 Pos : POSITION0;
    float2 TexCoord0 : TEXCOORD0;
};

struct APP2VS_D3DXMesh
{
    float4 Pos : POSITION0;
    // float2 TexCoord0 : TEXCOORD0;
};

struct VS2PS_Quad
{
    float4 Pos : POSITION;
    float2 TexCoord0 : TEXCOORD0;
};

struct VS2PS_D3DXMesh
{
    float4 Pos : POSITION;
    float4 TexCoord0 : TEXCOORD0;
};

struct VS2PS_D3DXMesh_2
{
    float4 Pos : POSITION;
    float4 WorldPos : TEXCOORD0;
};

struct PS2FB_DiffSpec
{
    float4 Col0 : COLOR0;
    float4 Col1 : COLOR1;
};

struct PS2FB_Combine
{
    float4 Col0 : COLOR0;
};




/*
    Shared shader function
*/

VS2PS_Quad Basic_VS(APP2VS_Quad Input)
{
    VS2PS_Quad Output;
    Output.Pos = float4(Input.Pos.xy, 0.0, 1.0);
    Output.TexCoord0 = Input.TexCoord0;
    return Output;
}

void Scale_TexCoord(in float4 Pos, inout float4 TexCoord)
{
    TexCoord.xy = Pos.xy / Pos.w;
    TexCoord.xy = (TexCoord.xy * 0.5) + 0.5;
    TexCoord.y = 1.0 - TexCoord.y;
    TexCoord.xy += float2(0.5 / 800.0, 0.5 / 600.0);
    TexCoord.xy = TexCoord.xy * Pos.w;
    TexCoord.zw = Pos.zw;
}

float Static_Samples_Average(sampler2D Source, float2 TexCoord, float Texel)
{
    float4 StaticSamples;
    StaticSamples.x = tex2D(Sampler_4, TexCoord + float2(-Texel, -Texel * 2.0)).r;
    StaticSamples.y = tex2D(Sampler_4, TexCoord + float2( Texel, -Texel * 2.0)).r;
    StaticSamples.z = tex2D(Sampler_4, TexCoord + float2(-Texel,  Texel * 2.0)).r;
    StaticSamples.w = tex2D(Sampler_4, TexCoord + float2( Texel,  Texel * 2.0)).r;
    return dot(StaticSamples, 0.25);
}

float4 Dummy_PS() : COLOR
{
    return 0.0;
}




/*
    Sunlight shader
*/

struct Sunlight_Objects_Data
{
    float4 ViewNormal;
    float4 LightMap;
    float3 HalfVec;
};

Sunlight_Objects_Data Sunlight_Objects_Common(in float2 TexCoord)
{
    Sunlight_Objects_Data Output;

    Output.ViewNormal = tex2D(Sampler_0, TexCoord);
    Output.LightMap = tex2D(Sampler_2, TexCoord);
    float3 ViewPosition = tex2D(Sampler_1, TexCoord).xyz;
    Output.HalfVec = normalize(-_LightDir.xyz + normalize(-ViewPosition.xyz));
    return Output;
}

PS2FB_DiffSpec Sunlight_Objects_PS(VS2PS_Quad Input)
{
    PS2FB_DiffSpec Output;
    Sunlight_Objects_Data Data = Sunlight_Objects_Common(Input.TexCoord0);

    float Diffuse = saturate(dot(Data.ViewNormal.xyz, -_LightDir.xyz));
    float Specular = saturate(dot(Data.ViewNormal.xyz, Data.HalfVec));
    float ShadowIntensity = saturate(Data.LightMap.a + _ShadowIntensityBias);

    Output.Col0 = Diffuse * _LightCol * ShadowIntensity;
    Output.Col1 = pow(Specular, 36.0) * Data.ViewNormal.a * _LightCol * ShadowIntensity * ShadowIntensity;
    return Output;
}

PS2FB_DiffSpec Sunlight_Dynamic_Skin_Objects_PS(VS2PS_Quad Input)
{
    PS2FB_DiffSpec Output;
    Sunlight_Objects_Data Data = Sunlight_Objects_Common(Input.TexCoord0);

    float SpecTmp = dot(Data.ViewNormal.xyz, Data.HalfVec) + 0.5;
    float Specular = saturate(SpecTmp / 1.5);
    float ShadowIntensity = saturate(Data.LightMap.a + _ShadowIntensityBias);

    Output.Col0 = 0.0;
    Output.Col1 = pow(Specular, 16.0) * Data.ViewNormal.a * _LightCol * ShadowIntensity * ShadowIntensity;
    return Output;
}

PS2FB_DiffSpec Sunlight_Transparent_PS(VS2PS_Quad Input)
{
    PS2FB_DiffSpec Output;

    float4 ViewNormal = tex2D(Sampler_0, Input.TexCoord0);
    float4 WorldPos = tex2D(Sampler_1, Input.TexCoord0);
    float4 DiffuseTex = tex2D(Sampler_5, Input.TexCoord0);

    float Diffuse = saturate(dot(ViewNormal.xyz, -_LightDir.xyz));

    Output.Col0 = Diffuse * _LightCol * DiffuseTex.a;
    Output.Col1 = 0.0; // TL don't need specular decals; // pow(Specular, 36.0) * ViewNormal.a * _LightCol * DiffuseTex.a;
    return Output;
}

technique SunLight
{
    pass opaqueDynamicObjects
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = (_DwStencilRef);
        StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = (_DwStencilPass);

        VertexShader = compile vs_3_0 Basic_VS();
        PixelShader = compile ps_3_0 Sunlight_Objects_PS();
    }

    pass opaqueDynamicSkinObjects
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = (_DwStencilRef);
        StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = (_DwStencilPass);

        VertexShader = compile vs_3_0 Basic_VS();
        PixelShader = compile ps_3_0 Sunlight_Dynamic_Skin_Objects_PS();
    }

    pass opaqueStaticObjects
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = (_DwStencilRef);
        StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 Basic_VS();
        PixelShader = compile ps_3_0 Sunlight_Objects_PS();
    }

    pass transparent
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        // StencilFunc = EQUAL;
        // StencilRef = 3;
        StencilFunc = NEVER;
        // StencilRef = 223;
        // StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 Basic_VS();
        PixelShader = compile ps_3_0 Sunlight_Transparent_PS();
    }
}




/*
    Nvidia sunlight shadow
*/

VS2PS_D3DXMesh Sunlight_Shadow_Objects_VS(APP2VS_D3DXMesh Input)
{
    VS2PS_D3DXMesh Output;
    float4 ScaledPos = Input.Pos + float4(0, 0, 0.5, 0);
    ScaledPos = mul(ScaledPos, _ObjWorld);
    ScaledPos = mul(ScaledPos, _CamView);
    ScaledPos = mul(ScaledPos, _CamProj);

    Output.Pos = ScaledPos;
    Scale_TexCoord(Output.Pos, Output.TexCoord0);
    return Output;
}

struct Sunlight_Shadow_Dynamic_Objects_NV_Data
{
    float4 ViewNormal;
    float4 ViewPos;
    float4 LightUV;
    float StaticSamples;
    float Diffuse;
    float3 HalfVec;
    float Specular;
};

Sunlight_Shadow_Dynamic_Objects_NV_Data Sunlight_Shadow_Dynamic_Objects_Common_NV(VS2PS_D3DXMesh Input)
{
    Sunlight_Shadow_Dynamic_Objects_NV_Data Output;

    Output.ViewNormal = tex2Dproj(Sampler_0, Input.TexCoord0);
    Output.ViewPos = tex2Dproj(Sampler_1, Input.TexCoord0);
    Output.LightUV = mul(Output.ViewPos, _LightViewProj);
    Output.LightUV.xy = clamp(Output.LightUV.xy, _ViewportMap.xy, _ViewportMap.zw);

    float Texel = 1.0 / 1024.0;
    Output.StaticSamples = Static_Samples_Average(Sampler_4, Output.LightUV.xy, Texel);

    Output.Diffuse = saturate(dot(Output.ViewNormal.xyz, -_LightDir.xyz));
    Output.HalfVec = normalize(-_LightDir.xyz + normalize(-Output.ViewPos.xyz));
    Output.Specular = saturate(dot(Output.ViewNormal.xyz, Output.HalfVec));
    return Output;
}

PS2FB_DiffSpec Sunlight_Shadow_Dynamic_Objects_NV_PS(VS2PS_D3DXMesh Input)
{
    PS2FB_DiffSpec Output;
    Sunlight_Shadow_Dynamic_Objects_NV_Data Data = Sunlight_Shadow_Dynamic_Objects_Common_NV(Input);

    float AvgShadowValue = tex2Dproj(Sampler_3, Data.LightUV); // HW percentage closer filtering.

    Output.Col0 = Data.Diffuse * _LightCol * AvgShadowValue * Data.StaticSamples;
    Output.Col1 = pow(Data.Specular, 36.0) * Data.ViewNormal.a * _LightCol * AvgShadowValue * Data.StaticSamples;
    return Output;
}

PS2FB_DiffSpec Sunlight_Shadow_Dynamic_1p_Objects_NV_PS(VS2PS_D3DXMesh Input)
{
    PS2FB_DiffSpec Output;
    Sunlight_Shadow_Dynamic_Objects_NV_Data Data = Sunlight_Shadow_Dynamic_Objects_Common_NV(Input);

    float AvgShadowValue = tex2D(Sampler_3, Data.LightUV.xy); // HW percentage closer filtering.
    float TotalShadow = Data.StaticSamples;

    Output.Col0 = Data.Diffuse * _LightCol * TotalShadow;
    Output.Col1 = pow(Data.Specular, 36.0) * Data.ViewNormal.a * _LightCol * TotalShadow;
    return Output;
}

PS2FB_DiffSpec Sunlight_Shadow_Static_Objects_NV_PS(VS2PS_D3DXMesh Input)
{
    PS2FB_DiffSpec Output;

    float4 ViewNormal = tex2Dproj(Sampler_0, Input.TexCoord0);
    float4 ViewPos = tex2Dproj(Sampler_1, Input.TexCoord0);
    float4 LightMap = tex2Dproj(Sampler_2, Input.TexCoord0);
    float4 LightUV = mul(ViewPos, _LightViewProj);

    LightUV.xy = clamp(LightUV.xy, _ViewportMap.xy, _ViewportMap.zw);
    LightUV.z = saturate(LightUV.z) - 0.001;
    float AvgShadowValue = tex2Dproj(Sampler_3, LightUV); // HW percentage closer filtering.

    float Diffuse = saturate(dot(ViewNormal.xyz, -_LightDir.xyz));
    float3 HalfVec = normalize(-_LightDir.xyz + normalize(-ViewPos.xyz));
    float Specular = saturate(dot(ViewNormal.xyz, HalfVec));

    Output.Col0 = Diffuse * _LightCol * saturate((LightMap.a * AvgShadowValue) + _ShadowIntensityBias);
    Output.Col1 = pow(Specular, 36.0) * ViewNormal.a * _LightCol * saturate(LightMap.a*AvgShadowValue+_ShadowIntensityBias);
    return Output;
}

technique SunLightShadowNV <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass opaqueDynamicObjects
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;

        CullMode = NONE;
        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = 0x20;
        StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = INCR;

        VertexShader = compile vs_3_0 Sunlight_Shadow_Objects_VS();
        PixelShader = compile ps_3_0 Sunlight_Shadow_Dynamic_Objects_NV_PS();
    }

    pass opaqueDynamic1pObjects
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;

        CullMode = NONE;
        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = 0x80;
        StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = DECR;

        VertexShader = compile vs_3_0 Sunlight_Shadow_Objects_VS();
        PixelShader = compile ps_3_0 Sunlight_Shadow_Dynamic_1p_Objects_NV_PS();
    }

    pass opaqueStaticObjects
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;

        CullMode = NONE;
        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = 0x40;
        StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = INCR;

        DepthBias = 0.000;
        SlopeScaleDepthBias = 2;

        VertexShader = compile vs_3_0 Sunlight_Shadow_Objects_VS();
        PixelShader = compile ps_3_0 Sunlight_Shadow_Static_Objects_NV_PS();
    }

    pass foobar
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        // ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = 240;
        // StencilFunc = NOTEQUAL;
        // StencilRef = 1;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 Sunlight_Shadow_Objects_VS();
        PixelShader = compile ps_3_0 Sunlight_Shadow_Static_Objects_NV_PS();
    }
}




/*
    Other sunlight shadow
*/

struct Sunlight_Shadow_Dynamic_Objects_Data
{
    float4 ViewNormal;
    float4 ViewPos;
    float4 LightUV;
    float4 Samples;
    float Diffuse;
    float3 HalfVec;
    float Specular;
    float AvgShadowValue;
};

Sunlight_Shadow_Dynamic_Objects_Data Sunlight_Shadow_Dynamic_Objects_Common(float4 TexCoord, float Texel, const float Epsilon)
{
    Sunlight_Shadow_Dynamic_Objects_Data Output;

    Output.ViewNormal = tex2Dproj(Sampler_0, TexCoord);
    Output.ViewPos = tex2Dproj(Sampler_1, TexCoord);
    Output.LightUV = mul(Output.ViewPos, _LightViewProj);
    Output.LightUV.xy = clamp(Output.LightUV.xy, _ViewportMap.xy, _ViewportMap.zw);

    Output.Samples.x = tex2D(Sampler_3, Output.LightUV.xy);
    Output.Samples.y = tex2D(Sampler_3, Output.LightUV.xy + float2(Texel, 0.0));
    Output.Samples.z = tex2D(Sampler_3, Output.LightUV.xy + float2(0.0, Texel));
    Output.Samples.w = tex2D(Sampler_3, Output.LightUV.xy + float2(Texel, Texel));

    Output.Diffuse = saturate(dot(Output.ViewNormal.xyz, -_LightDir.xyz));
    Output.HalfVec = normalize(-_LightDir.xyz + normalize(-Output.ViewPos.xyz));
    Output.Specular = saturate(dot(Output.ViewNormal.xyz, Output.HalfVec));

    float4 CmpBits = (Output.Samples.xyzw + Epsilon) >= saturate(Output.LightUV.zzzz);
    Output.AvgShadowValue = dot(CmpBits, 0.25);
    return Output;
}

PS2FB_DiffSpec Sunlight_Shadow_Dynamic_Objects_PS(VS2PS_D3DXMesh Input)
{
    float Texel = 1.0 / 1024.0;
    PS2FB_DiffSpec Output;
    Sunlight_Shadow_Dynamic_Objects_Data Data = Sunlight_Shadow_Dynamic_Objects_Common(Input.TexCoord0, Texel, 0.05);

    float StaticSamples = Static_Samples_Average(Sampler_4, Data.LightUV.xy, Texel);
    Output.Col0 = Data.Diffuse * _LightCol * Data.AvgShadowValue * StaticSamples;
    Output.Col1 = pow(Data.Specular, 36.0) * Data.ViewNormal.a * _LightCol * Data.AvgShadowValue * StaticSamples;
    return Output;
}

PS2FB_DiffSpec Sunlight_Shadow_Static_Objects_PS(VS2PS_D3DXMesh Input)
{
    float Texel = 1.0 / 1024.0;
    PS2FB_DiffSpec Output;
    Sunlight_Shadow_Dynamic_Objects_Data Data = Sunlight_Shadow_Dynamic_Objects_Common(Input.TexCoord0, Texel, 0.0075);

    float4 LightMap = tex2Dproj(Sampler_2, Input.TexCoord0);
    Output.Col0 = Data.Diffuse * _LightCol * saturate((LightMap.a * Data.AvgShadowValue) + _ShadowIntensityBias);
    Output.Col1 = pow(Data.Specular, 36.0) * Data.ViewNormal.a * _LightCol * saturate(LightMap.a * Data.AvgShadowValue + _ShadowIntensityBias);
    return Output;
}

PS2FB_DiffSpec Sunlight_Shadow_Dynamic_1p_Objects_PS(VS2PS_D3DXMesh Input)
{
    PS2FB_DiffSpec Output;

    float4 ViewNormal = (tex2Dproj(Sampler_0, Input.TexCoord0));
    float4 ViewPos = tex2Dproj(Sampler_1, Input.TexCoord0);

    float4 LightUV = mul(ViewPos, _LightViewProj);
    LightUV.xy = clamp(LightUV.xy, _ViewportMap.xy, _ViewportMap.zw);

    float Texel = 1.0 / 1024.0;

    float Diffuse = saturate(dot(ViewNormal.xyz, -_LightDir.xyz));
    float3 HalfVec = normalize(-_LightDir.xyz + normalize(-ViewPos.xyz));
    float Specular = saturate(dot(ViewNormal.xyz, HalfVec));

    float TotalShadow = Static_Samples_Average(Sampler_4, LightUV.xy, Texel);

    Output.Col0 = Diffuse * _LightCol * TotalShadow;
    Output.Col1 = pow(Specular, 36.0) * ViewNormal.a * _LightCol * TotalShadow;
    return Output;
}

technique SunLightShadow <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass opaqueDynamicObjects
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;

        CullMode = NONE;
        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = 0x20;
        StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = INCR;

        VertexShader = compile vs_3_0 Sunlight_Shadow_Objects_VS();
        PixelShader = compile ps_3_0 Sunlight_Shadow_Dynamic_Objects_PS();
    }
    pass opaqueDynamic1pObjects
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;

        CullMode = NONE;
        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = 0x80;
        StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = DECR;

        VertexShader = compile vs_3_0 Sunlight_Shadow_Objects_VS();
        PixelShader = compile ps_3_0 Sunlight_Shadow_Dynamic_1p_Objects_PS();
    }
    pass opaqueStaticObjects
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;

        CullMode = NONE;
        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = 0x40;
        StencilMask = 0xFF;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = INCR;

        VertexShader = compile vs_3_0 Sunlight_Shadow_Objects_VS();
        PixelShader = compile ps_3_0 Sunlight_Shadow_Static_Objects_PS();
    }
    pass foobar
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        // ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = 240;
        // StencilFunc = NOTEQUAL;
        // StencilRef = 1;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 Sunlight_Shadow_Objects_VS();
        PixelShader = compile ps_3_0 Sunlight_Shadow_Static_Objects_PS();
    }
}




/*
    Other point light shaders
*/

VS2PS_D3DXMesh Pointlight_VS(APP2VS_D3DXMesh Input)
{
    VS2PS_D3DXMesh Output;
     float3 WorldPos = Input.Pos.xyz * _LightAttenuationRange + _LightWorldPos.xyz;
     Output.Pos = mul(float4(WorldPos, 1.0), _ViewProj);
    Scale_TexCoord(Output.Pos, Output.TexCoord0);
    return Output;
}

struct Pointlight_Data
{
    float4 CurrDiff;
    float4 CurrSpec;
    float4 ViewNormal;
    float4 ViewPos;
    float3 LightVec;
    float LightDist;
    float4 RadialAtt;
    float Diffuse;
    float3 HalfVec;
    float Specular;
};

Pointlight_Data Pointlight_Common(float4 TexCoord, bool Diff_Spec, bool Specular)
{
    Pointlight_Data Output = (Pointlight_Data)0;

    Output.CurrDiff = (Diff_Spec) ? tex2Dproj(Sampler_0, TexCoord) : 0.0;
    Output.CurrSpec = (Diff_Spec) ? tex2Dproj(Sampler_1, TexCoord) : 0.0;

    Output.ViewNormal = tex2Dproj(Sampler_2, TexCoord);
    Output.ViewPos = tex2Dproj(Sampler_3, TexCoord);

    Output.LightVec = _LightPos.xyz - Output.ViewPos.xyz;
    Output.LightDist = length(Output.LightVec);
    Output.LightDist *= _LightAttenuationRangeInv;

    Output.RadialAtt = tex1D(Sampler_4, Output.LightDist);

    Output.Diffuse = saturate(dot(Output.ViewNormal.xyz, normalize(Output.LightVec))) * Output.RadialAtt;
    Output.HalfVec = normalize(-_LightDir.xyz + normalize(-Output.ViewPos.xyz));
    Output.Specular = (Specular) ? saturate(dot(Output.ViewNormal.xyz, Output.HalfVec)) * Output.RadialAtt : 0.0;
    return Output;
}

PS2FB_DiffSpec Pointlight_PS(VS2PS_D3DXMesh Input)
{
    PS2FB_DiffSpec Output;
    Pointlight_Data Data = Pointlight_Common(Input.TexCoord0, true, true);

    // float4 LightMap = tex2Dproj(Sampler_5, Input.TexCoord0);
    // Output.Col0 = max(max(LightMap,Diffuse * _LightCol), CurrDiff);
    Output.Col0 = max(Data.Diffuse * _LightCol, Data.CurrDiff);
    Output.Col1 = max(pow(Data.Specular, 36.0) * Data.ViewNormal.a * _LightCol, Data.CurrSpec);
    return Output;
}

technique PointLight <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;
        // ZFunc = LESSEQUAL;
        // CullMode = NONE;
        // ZFunc = GREATER;
        // CullMode = CW;

        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        // StencilFunc = (_DwStencilFunc); // NOTEQUAL;
        // StencilRef = (_DwStencilRef); // 1;
        StencilFunc = NOTEQUAL;
        StencilRef = 1;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 Pointlight_VS();
        PixelShader = compile ps_3_0 Pointlight_PS();
    }

    pass p1
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;
        // ZFunc = LESSEQUAL;
        // CullMode = NONE;
        // ZFunc = GREATER;
        // CullMode = CW;

        AlphaBlendEnable = FALSE;

        StencilFunc = (_DwStencilFunc); // EQUAL;

        VertexShader = compile vs_3_0 Pointlight_VS();
        PixelShader = compile ps_3_0 Pointlight_PS();
    }
}

/*
    Nvidia NV40 point light shaders
*/

PS2FB_DiffSpec psDx9_PointLightNV40(VS2PS_D3DXMesh Input)
{
    PS2FB_DiffSpec Output;
    Pointlight_Data Data = Pointlight_Common(Input.TexCoord0, false, true);

    Output.Col0 = Data.Diffuse * _LightCol;
    Output.Col1 = pow(Data.Specular, 36.0) * Data.ViewNormal.a * _LightCol;
    return Output;
}

technique PointLightNV40 <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ColorWriteEnable  = RED|GREEN|BLUE|ALPHA;
        ColorWriteEnable1 = RED|GREEN|BLUE|ALPHA;
        ColorWriteEnable2 = RED|GREEN|BLUE|ALPHA;
        ColorWriteEnable3 = RED|GREEN|BLUE|ALPHA;
        ZEnable = FALSE;
        ZWriteEnable = FALSE;

        CullMode = NONE;

        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        BlendOp = MAX;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilMask = 0xFF;
        StencilRef = 0x55;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 Pointlight_VS();
        PixelShader = compile ps_3_0 psDx9_PointLightNV40();
    }

    pass ReplaceStencil
    {
        ColorWriteEnable  = 0;
        ColorWriteEnable1 = 0;
        ColorWriteEnable2 = 0;
        ColorWriteEnable3 = 0;

        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESS;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = ALWAYS;
        StencilMask = 0xFF;
        StencilRef = 0x55;
        StencilFAIL = KEEP;
        StencilZFail = REPLACE;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 Pointlight_VS();
        PixelShader = compile ps_3_0 Dummy_PS();
    }

    /*
        pass p1
        {
            ZEnable = TRUE;
            ZWriteEnable = FALSE;
            ZFunc = GREATER;
            CullMode = NONE;
            // ZFunc = LESSEQUAL;
            // CullMode = NONE;
            // ZFunc = GREATER;
            // CullMode = CW;

            AlphaBlendEnable = TRUE;
            SrcBlend = ONE;
            DestBlend = ONE;
            BlendOp = MAX;

            StencilFunc = (_DwStencilFunc); // EQUAL;

            VertexShader = compile vs_3_0 Pointlight_VS();
            PixelShader = compile ps_3_0 Pointlight_PS();
        }
    */
}




/*
    Pointlight shadow shaders
*/

struct Pointlight_ParaPos_Data
{
    float3 ParaPos1;
    float HemiSel;
    float3 ParaPos2;
    float ParaPosZ;
};

Pointlight_ParaPos_Data Calc_Para_Pos(float3 LightVec, float LightDist)
{
    Pointlight_ParaPos_Data Output;
    Output.ParaPos1 = -LightVec;
    Output.ParaPos1 = normalize(Output.ParaPos1);
    Output.ParaPos1 = mul(Output.ParaPos1, _CamViewI);
    Output.HemiSel = Output.ParaPos1.z;
    Output.ParaPos2 = Output.ParaPos1 - float3(0.0, 0.0, 1.0);
    Output.ParaPos1 += float3(0.0, 0.0, 1.0);

    Output.ParaPos1.xy /= Output.ParaPos1.z;
    Output.ParaPos2.xy /= Output.ParaPos2.z;
    Output.ParaPosZ = LightDist * _ParaboloidZValues.x + _ParaboloidZValues.y;

    Output.ParaPos1.xy = saturate(Output.ParaPos1.xy * float2(0.5, -0.5) + 0.5);
    Output.ParaPos1.xy = Output.ParaPos1.xy * _ViewportMap.wz + _ViewportMap.xy;
    Output.ParaPos2.xy = saturate(Output.ParaPos2.xy * float2(-0.5, 0.5) + 0.5);
    Output.ParaPos2.xy = Output.ParaPos2.xy * _ViewportMap.wz + _ViewportMap.xy;
    return Output;
}

PS2FB_DiffSpec Pointlight_Shadow_PS(VS2PS_D3DXMesh Input)
{
    PS2FB_DiffSpec Output;
    Pointlight_Data Data = Pointlight_Common(Input.TexCoord0, true, true);
    Pointlight_ParaPos_Data PosData = Calc_Para_Pos(Data.LightVec, Data.LightDist);

    float2 ParaSamples;
    ParaSamples.x = tex2D(Sampler_5, PosData.ParaPos1.xy);
    ParaSamples.y = tex2D(Sampler_6, PosData.ParaPos2.xy);

    const float Epsilon = 0.0075;
    float2 AvgPara = (ParaSamples.xy + Epsilon) >= PosData.ParaPosZ;

    float Shad = PosData.HemiSel >= 0 ? AvgPara.x : AvgPara.y;
    Output.Col0 = max(Data.Diffuse * _LightCol * Shad, Data.CurrDiff);
    Output.Col1 = max(pow(Data.Specular, 36.0) * Data.ViewNormal.a * _LightCol, Data.CurrSpec);
    return Output;
}

PS2FB_DiffSpec Pointlight_Shadow_NV40_PS(VS2PS_D3DXMesh Input)
{
    PS2FB_DiffSpec Output;
    Pointlight_Data Data = Pointlight_Common(Input.TexCoord0, true, false);
    Pointlight_ParaPos_Data PosData = Calc_Para_Pos(Data.LightVec, Data.LightDist);

    PosData.ParaPosZ += PosData.ParaPosZ + 0.5;

    float2 ParaSamples;
    ParaSamples.x = tex2D(Sampler_5, PosData.ParaPos1.xy);
    ParaSamples.y = tex2D(Sampler_6, PosData.ParaPos2.xy);

    const float Epsilon = 0.0075;
    float2 AvgPara = (ParaSamples.xy + Epsilon) >= PosData.ParaPosZ;

    float Shad = PosData.HemiSel >= 0 ? AvgPara.x : AvgPara.y;
    Output.Col0 = Data.Diffuse * _LightCol * Shad;
    Output.Col1 = pow(Data.Specular, 36.0) * Data.ViewNormal.a * _LightCol;
    return Output;
}

technique PointLightShadow <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 1;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 Pointlight_VS();
        PixelShader = compile ps_3_0 Pointlight_Shadow_PS();
    }
}

PS2FB_DiffSpec Pointlight_Shadow_NV_PS(VS2PS_D3DXMesh Input)
{
    PS2FB_DiffSpec Output;
    Pointlight_Data Data = Pointlight_Common(Input.TexCoord0, true, false);
    Pointlight_ParaPos_Data PosData = Calc_Para_Pos(Data.LightVec, Data.LightDist);

    float2 AvgPara;
    AvgPara.x = tex2Dproj(Sampler_5, float4(PosData.ParaPos1.xy, PosData.ParaPosZ, 1.0));
    AvgPara.y = tex2Dproj(Sampler_6, float4(PosData.ParaPos2.xy, PosData.ParaPosZ, 1.0));

    float Shad = PosData.HemiSel >= 0 ? AvgPara.x : AvgPara.y;
    Output.Col0 = max(Data.Diffuse * _LightCol * Shad, Data.CurrDiff);
    Output.Col1 = max(pow(Data.Specular, 36) * Data.ViewNormal.a * _LightCol, Data.CurrSpec);
    return Output;
}

technique PointLightShadowNV <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 1;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 Pointlight_VS();
        PixelShader = compile ps_3_0 Pointlight_Shadow_NV_PS();
    }
}

technique PointLightShadowNV40 <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ColorWriteEnable  = RED|GREEN|BLUE|ALPHA;
        ColorWriteEnable1 = RED|GREEN|BLUE|ALPHA;
        ColorWriteEnable2 = RED|GREEN|BLUE|ALPHA;
        ColorWriteEnable3 = RED|GREEN|BLUE|ALPHA;
        ZEnable = FALSE;
        ZWriteEnable = FALSE;

        CullMode = NONE;

        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        BlendOp = MAX;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilMask = 0xFF;
        StencilRef = 0x55;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 Pointlight_VS();
        PixelShader = compile ps_3_0 Pointlight_Shadow_NV40_PS();
    }

    pass ReplaceStencil
    {
        ColorWriteEnable = 0;
        ColorWriteEnable1 = 0;
        ColorWriteEnable2 = 0;
        ColorWriteEnable3 = 0;

        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESS;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = ALWAYS;
        StencilMask = 0xFF;
        StencilRef = 0x55;
        StencilFAIL = KEEP;
        StencilZFail = REPLACE;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 Pointlight_VS();
        PixelShader = compile ps_3_0 Dummy_PS();
    }
}




/*
    Pointlight glow shaders
*/

VS2PS_D3DXMesh_2 Pointlight_Glow_VS(APP2VS_D3DXMesh Input)
{
    VS2PS_D3DXMesh_2 Output;
    float Scale = _LightAttenuationRange;
     float3 WorldPos = (Input.Pos.xyz * Scale) + _LightWorldPos.xyz;
     Output.Pos = mul(float4(WorldPos, 1.0), _ViewProj);

    Output.WorldPos = dot(normalize(_EyePos.xyz - _LightWorldPos.xyz), normalize(WorldPos - _LightWorldPos.xyz));
    Output.WorldPos = pow(Output.WorldPos, 4.0);
    return Output;
}

float4 Pointlight_Glow_PS(VS2PS_D3DXMesh_2 Input) : COLOR
{
    return float4(_LightCol.xyz * Input.WorldPos.rgb, 1.0);
}

technique PointLightGlow <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = LESSEQUAL;
        CullMode = CCW;

        AlphaBlendEnable = TRUE;
        SrcBlend = SRCCOLOR;
        DestBlend = ONE;

        StencilEnable = FALSE;

        VertexShader = compile vs_3_0 Pointlight_Glow_VS();
        PixelShader = compile ps_3_0 Pointlight_Glow_PS();
    }
}




/*
    Spotlight shaders
*/

struct Spotlight_Data
{
    float4 ViewNormal;
    float4 ViewPos;
    float3 LightVec;
    float LightDist;
    float4 RadialAtt;
    float3 LightVecN;
    float FallOff;
    float4 ConicalAtt;
    float Diffuse;
    float3 HalfVec;
    float Specular;
};

Spotlight_Data Spotlight_Common(float4 TexCoord)
{
    Spotlight_Data Output;

    Output.ViewNormal = tex2Dproj(Sampler_2, TexCoord);
    Output.ViewPos = tex2Dproj(Sampler_3, TexCoord);

    Output.LightVec = _LightPos.xyz - Output.ViewPos.xyz;
    Output.LightDist = length(Output.LightVec);
    Output.LightDist *= _LightAttenuationRangeInv;
    Output.RadialAtt = tex1D(Sampler_4, Output.LightDist);

    Output.LightVecN = normalize(Output.LightVec);
    Output.FallOff = dot(-Output.LightVecN, _LightDir.xyz);
    Output.ConicalAtt = tex1D(Sampler_5, 1.0 - (Output.FallOff * Output.FallOff));

    Output.Diffuse = saturate(dot(Output.ViewNormal.xyz, Output.LightVecN)) * Output.RadialAtt * Output.ConicalAtt;
    Output.HalfVec = normalize(-_LightDir.xyz + normalize(Output.ViewPos.xyz - _EyePos.xyz));
    Output.Specular = saturate(dot(Output.ViewNormal.xyz, Output.HalfVec)) * Output.RadialAtt;
    return Output;
}

VS2PS_D3DXMesh Spotlight_VS(APP2VS_D3DXMesh Input)
{
    VS2PS_D3DXMesh Output;
    float4 ScaledPos = Input.Pos * float4(1.5, 1.5, 1.0, 1.0) + float4(0.0, 0.0, 0.5, 0.0);
     Output.Pos = mul(ScaledPos, _WorldViewProj);
    Scale_TexCoord(Output.Pos, Output.TexCoord0);
    return Output;
}

PS2FB_DiffSpec Spotlight_NV40_PS(VS2PS_D3DXMesh Input)
{
    PS2FB_DiffSpec Output;
    Spotlight_Data Data = Spotlight_Common(Input.TexCoord0);

    Output.Col0 = Data.Diffuse * _LightCol;
    Output.Col1 = pow(Data.Specular, 36.0) * Data.ViewNormal.a * _LightCol;
    return Output;
}

PS2FB_DiffSpec Spotlight_PS(VS2PS_D3DXMesh Input)
{
    PS2FB_DiffSpec Output;
    Spotlight_Data Data = Spotlight_Common(Input.TexCoord0);

    float4 CurrDiff = tex2Dproj(Sampler_0, Input.TexCoord0);
    float4 CurrSpec = tex2Dproj(Sampler_1, Input.TexCoord0);

    Output.Col0 = max(Data.Diffuse * _LightCol, CurrDiff);
    Output.Col1 = max(pow(Data.Specular, 36.0) * Data.ViewNormal.a * _LightCol, CurrSpec);
    return Output;
}

technique SpotLightNV40 <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        BlendOp = MAX;

        StencilEnable = FALSE;

        VertexShader = compile vs_3_0 Spotlight_VS();
        PixelShader = compile ps_3_0 Spotlight_NV40_PS();
    }
}

technique SpotLight <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;

        VertexShader = compile vs_3_0 Spotlight_VS();
        PixelShader = compile ps_3_0 Spotlight_PS();
    }
}




/*
    Spotlight shadow shaders
*/

PS2FB_DiffSpec Spotlight_Shadow_PS(VS2PS_D3DXMesh Input)
{
    PS2FB_DiffSpec Output;
    Spotlight_Data Data = Spotlight_Common(Input.TexCoord0);

    float4 LightUV = mul(Data.ViewPos, _LightViewProj);
    LightUV.xyz /= LightUV.w;
    LightUV.xy = LightUV.xy * float2(0.5, -0.5) + 0.5;

    float4 CurrDiff = tex2Dproj(Sampler_0, Input.TexCoord0);
    float4 CurrSpec = tex2Dproj(Sampler_1, Input.TexCoord0);
    float4 Samples = tex2D(Sampler_6, LightUV.xy);

    Output.Col0 = max(Data.Diffuse * _LightCol, CurrDiff);
    Output.Col1 = max(pow(Data.Specular, 36.0) * Data.ViewNormal.a * _LightCol, CurrSpec);
    return Output;
}

PS2FB_DiffSpec Spotlight_Shadow_NV40_PS(VS2PS_D3DXMesh Input)
{
    PS2FB_DiffSpec Output;
    Spotlight_Data Data = Spotlight_Common(Input.TexCoord0);

    float4 LightUV = mul(Data.ViewPos, _LightViewProj);
    LightUV.xyz /= LightUV.w;
    LightUV.xy = LightUV.xy * float2(0.5, -0.5) + 0.5;

    float4 Samples = tex2D(Sampler_6, LightUV.xy);
    Output.Col0 = Data.Diffuse * _LightCol;
    Output.Col1 = pow(Data.Specular, 36.0) * Data.ViewNormal.a * _LightCol;
    return Output;
}

technique SpotLightShadow <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 1;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 Spotlight_VS();
        PixelShader = compile ps_3_0 Spotlight_Shadow_PS();
    }
}

technique SpotLightShadowNV40 <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 1;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 Spotlight_VS();
        PixelShader = compile ps_3_0 Spotlight_Shadow_NV40_PS();
    }
}




/*
    Spotlight projector shaders
*/

struct Spot_Projector_Data
{
    float4 ViewNormal;
    float4 ViewPos;
    float3 LightVec;
    float LightDist;
    float4 RadialAtt;
    float3 LightVecN;
    float Diffuse;
    float3 HalfVec;
    float Specular;
};

Spot_Projector_Data Spot_Projector_Common(float4 TexCoord)
{
    Spot_Projector_Data Output;

    Output.ViewNormal = tex2Dproj(Sampler_2, TexCoord);
    Output.ViewPos = tex2Dproj(Sampler_3, TexCoord);

    Output.LightVec = _LightPos.xyz - Output.ViewPos.xyz;
    Output.LightDist = length(Output.LightVec);
    Output.LightDist *= _LightAttenuationRangeInv;
    Output.RadialAtt = tex1D(Sampler_4, Output.LightDist);

    Output.LightVecN = normalize(Output.LightVec);

    Output.Diffuse = saturate(dot(Output.ViewNormal.xyz, Output.LightVecN)) * Output.RadialAtt;
    Output.HalfVec = normalize(-_LightDir.xyz + normalize(Output.ViewPos.xyz - _EyePos.xyz));
    Output.Specular = saturate(dot(Output.ViewNormal.xyz, Output.HalfVec)) * Output.RadialAtt;
    return Output;
}

VS2PS_D3DXMesh Spot_Projector_VS(APP2VS_D3DXMesh Input)
{
    VS2PS_D3DXMesh Output;

    float Near = 0.01;
    float Far = 10.0;
    float VDist = Far - Near;

    float4 ProperPos = Input.Pos + float4(0.0, 0.0, 0.5, 0.0);
    // ProperPos.xy *= ProperPos.z;
     Output.Pos = mul(ProperPos, _WorldViewProj);
    Scale_TexCoord(Output.Pos, Output.TexCoord0);
    return Output;
}

PS2FB_DiffSpec Spot_Projector_PS(VS2PS_D3DXMesh Input)
{
    PS2FB_DiffSpec Output;
    Spot_Projector_Data Data = Spot_Projector_Common(Input.TexCoord0);

    float4 CurrDiff = tex2Dproj(Sampler_0, Input.TexCoord0);
    float4 CurrSpec = tex2Dproj(Sampler_1, Input.TexCoord0);

    float4 LightUV = mul(Data.ViewPos, _LightViewProj);
    LightUV.xy /= LightUV.w;
    LightUV.xy = LightUV.xy * 0.5 + 0.5;
    float4 Headlight = tex2D(Sampler_5, LightUV.xy);

    Data.Diffuse *= saturate(dot(Headlight.rgb, _ProjectorMask.rgb)) * saturate(dot(-_LightDir.xyz, Data.LightVec));
    Output.Col0 = max(Data.Diffuse * _LightCol, CurrDiff);
    Output.Col1 = max(pow(Data.Specular, 36.0) * Data.ViewNormal.a * _LightCol, CurrSpec);
    return Output;
}

PS2FB_DiffSpec Spot_Projector_NV40_PS(VS2PS_D3DXMesh Input)
{
    PS2FB_DiffSpec Output;
    Spot_Projector_Data Data = Spot_Projector_Common(Input.TexCoord0);

    float4 LightUV = mul(Data.ViewPos, _LightViewProj);
    LightUV.xy /= LightUV.w;
    LightUV.xy = LightUV.xy * 0.5 + 0.5;
    float4 Headlight = tex2D(Sampler_5, LightUV.xy);

    Data.Diffuse *= saturate(dot(Headlight.rgb, _ProjectorMask.rgb)) * saturate(dot(-_LightDir.xyz, Data.LightVec));
    Output.Col0 = Data.Diffuse * _LightCol;
    Output.Col1 = pow(Data.Specular, 36.0) * Data.ViewNormal.a * _LightCol;
    return Output;
}

technique SpotProjector <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        // CullMode = NONE;
        // ZFunc = LESSEQUAL;
        // CullMode = NONE;

        AlphaBlendEnable = FALSE;
        // StencilEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 1;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 Spot_Projector_VS();
        PixelShader = compile ps_3_0 Spot_Projector_PS();
    }
}

technique SpotProjectorNV40 <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        // CullMode = NONE;
        // ZFunc = LESSEQUAL;
        // CullMode = NONE;

        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        BlendOp = MAX;
        // StencilEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 1;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 Spot_Projector_VS();
        PixelShader = compile ps_3_0 Spot_Projector_NV40_PS();
    }
}




/*
    Spotlight projector shadow shaders
*/

PS2FB_DiffSpec Spot_Projector_Shadow_Common_PS(VS2PS_D3DXMesh Input, bool IsNV40)
{
    PS2FB_DiffSpec Output;
    Spot_Projector_Data Data = Spot_Projector_Common(Input.TexCoord0);

    float4 CurrDiff = tex2Dproj(Sampler_0, Input.TexCoord0);
    float4 CurrSpec = tex2Dproj(Sampler_1, Input.TexCoord0);

    float4 LightUV = mul(Data.ViewPos, _LightViewProj);
    LightUV.xyz = (IsNV40) ? LightUV.xyz / LightUV.w : LightUV.xyz / 1.1 * LightUV.w;

    float2 HeadlightUV = LightUV.xy * float2(0.5, 0.5) + 0.5;
    float4 Headlight = tex2D(Sampler_5, HeadlightUV);

    if(IsNV40)
    {
        LightUV.xy = saturate(LightUV.xy * float2(0.5, -0.5) + 0.5);
        LightUV.xy = LightUV.xy * _ViewportMap.zw + _ViewportMap.xy;
    }
    else
    {
        LightUV.xy = LightUV.xy * float2(0.5, -0.5) + 0.5;
        LightUV.xy = saturate(LightUV.xy * _ViewportMap.zw + _ViewportMap.xy);
    }

    float Texel = 1.0 / 1024.0;
    const float Epsilon = 0.005;
    float4 Samples;
    Samples.x = tex2D(Sampler_6, LightUV.xy);
    Samples.y = tex2D(Sampler_6, LightUV.xy + float2(Texel, 0.0));
    Samples.z = tex2D(Sampler_6, LightUV.xy + float2(0.0, Texel));
    Samples.w = tex2D(Sampler_6, LightUV.xy + float2(Texel, Texel));
    float4 AvgSamples = (Samples.xyzw+Epsilon) > LightUV.zzzz;
    AvgSamples = dot(AvgSamples, 0.25);

    Data.Diffuse *= dot(Headlight.rgb, _ProjectorMask.rgb);
    Data.Diffuse *= AvgSamples * saturate(dot(-_LightDir.xyz, Data.LightVec));
    Output.Col0 = max(Data.Diffuse * _LightCol, CurrDiff);
    Output.Col1 = max(pow(Data.Specular, 36.0) * Data.ViewNormal.a * _LightCol, CurrSpec);
    return Output;
}

PS2FB_DiffSpec Spot_Projector_Shadow_NV_PS(VS2PS_D3DXMesh Input)
{
    PS2FB_DiffSpec Output;
    Spot_Projector_Data Data = Spot_Projector_Common(Input.TexCoord0);

    float4 CurrDiff = tex2Dproj(Sampler_0, Input.TexCoord0);
    float4 CurrSpec = tex2Dproj(Sampler_1, Input.TexCoord0);

    float4 LightUV = mul(Data.ViewPos, _LightViewProj);
    LightUV.xyz /= LightUV.w;

    float2 HeadlightUV = LightUV.xy * float2(0.5, 0.5) + 0.5;
    float4 Headlight = tex2D(Sampler_5, HeadlightUV);

    float4 AvgSamples = tex2D(Sampler_6, LightUV.xy);

    Data.Diffuse *= dot(Headlight.rgb, _ProjectorMask.rgb);
    Data.Diffuse *= AvgSamples * saturate(dot(-_LightDir.xyz, Data.LightVec));
    Output.Col0 = max(Data.Diffuse * _LightCol, CurrDiff);
    Output.Col1 = max(pow(Data.Specular, 36.0) * Data.ViewNormal.a * _LightCol, CurrSpec);
    return Output;
}

PS2FB_DiffSpec Spot_Projector_Shadow_PS(VS2PS_D3DXMesh Input)
{
    PS2FB_DiffSpec Output = Spot_Projector_Shadow_Common_PS(Input, false);
    return Output;
}

PS2FB_DiffSpec Spot_Projector_Shadow_NV40_PS(VS2PS_D3DXMesh Input)
{
    PS2FB_DiffSpec Output = Spot_Projector_Shadow_Common_PS(Input, true);
    return Output;
}

technique SpotProjectorShadowNV <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;
        // ZFunc = LESSEQUAL;
        // CullMode = NONE;

        AlphaBlendEnable = FALSE;
        // StencilEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 1;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 Spot_Projector_VS();
        PixelShader = compile ps_3_0 Spot_Projector_Shadow_NV_PS();
    }
}

technique SpotProjectorShadow <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;
        // ZFunc = LESSEQUAL;
        // CullMode = NONE;

        AlphaBlendEnable = FALSE;
        // StencilEnable = FALSE;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 1;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 Spot_Projector_VS();
        PixelShader = compile ps_3_0 Spot_Projector_Shadow_PS();
    }
}

technique SpotProjectorShadowNV40 <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;
        // ZFunc = LESSEQUAL;
        // CullMode = NONE;

        AlphaBlendEnable = TRUE;
        SrcBlend = ONE;
        DestBlend = ONE;
        BlendOp = MAX;

        StencilEnable = TRUE;
        StencilFunc = NOTEQUAL;
        StencilRef = 1;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 Spot_Projector_VS();
        PixelShader = compile ps_3_0 Spot_Projector_Shadow_NV40_PS();
    }
}




/*
    Backlight contribution shaders
*/

VS2PS_D3DXMesh Blit_Backlight_Contrib_Point_VS(APP2VS_D3DXMesh Input)
{
    VS2PS_D3DXMesh Output;
     float3 WorldPos = Input.Pos.xyz * _LightAttenuationRange + _LightWorldPos.xyz;
     Output.Pos = mul(float4(WorldPos, 1.0), _ViewProj);
    Scale_TexCoord(Output.Pos, Output.TexCoord0);
    return Output;
}

VS2PS_D3DXMesh Blit_Backlight_Contrib_Spot_VS(APP2VS_D3DXMesh Input)
{
    VS2PS_D3DXMesh Output;
    float4 ScaledPos = Input.Pos * float4(1.5, 1.5, 1.0, 1.0) + float4(0.0, 0.0, 0.5, 0.0);
     Output.Pos = mul(ScaledPos, _WorldViewProj);
    Scale_TexCoord(Output.Pos, Output.TexCoord0);
    return Output;
}

VS2PS_D3DXMesh Blit_Backlight_Contrib_Spot_Projector_VS(APP2VS_D3DXMesh Input)
{
    VS2PS_D3DXMesh Output;

    float Near = 0.01;
    float Far = 10.0;
    float VDist = Far-Near;
    float4 ProperPos = Input.Pos + float4(0.0, 0.0, 0.5, 0.0);

     Output.Pos = mul(ProperPos, _WorldViewProj);
    Scale_TexCoord(Output.Pos, Output.TexCoord0);
    return Output;
}

PS2FB_DiffSpec Blit_Backlight_Contrib_PS(VS2PS_D3DXMesh Input)
{
    PS2FB_DiffSpec Output;
    Output.Col0 = tex2Dproj(Sampler_0, Input.TexCoord0);
    Output.Col1 = tex2Dproj(Sampler_1, Input.TexCoord0);
    return Output;
}

technique BlitBackLightContrib <
    int Declaration[] =
    {
        // StreamNo, DataType, Usage, UsageIdx
        0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
        DECLARATION_END	// End macro
    };
>
{
    pass point_
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;

        VertexShader = compile vs_3_0 Blit_Backlight_Contrib_Point_VS();
        PixelShader = compile ps_3_0 Blit_Backlight_Contrib_PS();
    }

    pass spot
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;

        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;

        VertexShader = compile vs_3_0 Blit_Backlight_Contrib_Spot_VS();
        PixelShader = compile ps_3_0 Blit_Backlight_Contrib_PS();
    }

    pass spotprojector
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        ZFunc = GREATER;
        CullMode = NONE;
        // ZFunc = LESSEQUAL;
        // CullMode = NONE;

        AlphaBlendEnable = FALSE;
        StencilEnable = FALSE;

        VertexShader = compile vs_3_0 Blit_Backlight_Contrib_Spot_Projector_VS();
        PixelShader = compile ps_3_0 Blit_Backlight_Contrib_PS();
    }
}




/*
    Combine shaders
*/

PS2FB_Combine Combine_Common_PS(VS2PS_Quad Input, bool IsTransparent)
{
    PS2FB_Combine Output;

    float4 LightMap = tex2D(Sampler_0, Input.TexCoord0);
    float4 DiffuseTex = tex2D(Sampler_1, Input.TexCoord0);
    float4 Diff1 = tex2D(Sampler_2, Input.TexCoord0);
    float4 Spec1 = tex2D(Sampler_3, Input.TexCoord0);

    float4 DiffTot = (IsTransparent) ?  LightMap + Diff1 : (LightMap + _LightmapIntensityBias) + Diff1;
    float4 SpecTot = Spec1;

    Output.Col0 = DiffTot * DiffuseTex + SpecTot;
    Output.Col0.a = (IsTransparent) ? DiffuseTex.a : Output.Col0.a;
    return Output;
}

PS2FB_Combine Combine_PS(VS2PS_Quad Input)
{
    PS2FB_Combine Output = Combine_Common_PS(Input, false);
    return Output;
}

PS2FB_Combine Combine_Transparent_PS(VS2PS_Quad Input)
{
    PS2FB_Combine Output = Combine_Common_PS(Input, true);
    return Output;
}

technique Combine
{
    pass opaque
    {
        ZEnable = FALSE;
        AlphaBlendEnable = FALSE;

        StencilEnable = FALSE;

        VertexShader = compile vs_3_0 Basic_VS();
        PixelShader = compile ps_3_0 Combine_PS();
    }

    pass transparent
    {
        ZEnable = FALSE;
        ZWriteEnable = FALSE;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        // DestBlend = DESTALPHA;
        DestBlend = INVSRCALPHA;

        StencilEnable = TRUE;
        StencilFunc = EQUAL;
        StencilRef = 3;
        StencilFail = KEEP;
        StencilZFail = KEEP;
        StencilPass = KEEP;

        VertexShader = compile vs_3_0 Basic_VS();
        PixelShader = compile ps_3_0 Combine_Transparent_PS();
    }
}
