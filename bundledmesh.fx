#line 2 "BundledMesh.fx"

// UNIFORM INPUTS
float4x4 viewProjMatrix : WorldViewProjection;// : register(vs_1_1, c0);
float4x4 viewInverseMatrix : ViewI; // : register(vs_1_1, c8);
float4x3 mOneBoneSkinning[26]: matONEBONESKINNING;// : register(c15) < bool sparseArray = true; int arrayStart = 15; >;
float4x4 viewMatrix : ViewMatrix;
float4x4 viewITMatrix : ViewITMatrix;

float4 ambColor  : Ambient  = { 0.0f, 0.0f, 0.0f, 1.0f };
float4 diffColor : Diffuse  = { 1.0f, 1.0f, 1.0f, 1.0f };
float4 specColor : Specular = { 0.0f, 0.0f, 0.0f, 1.0f };

float4x4 vpLightMat : vpLightMat;
float4x4 vpLightTrapezMat : vpLightTrapezMat;
float4 PosUnpack : POSUNPACK;

float2 vTexProjOffset : TEXPROJOFFSET;

float2 zLimitsInv : ZLIMITSINV;

float shadowAlphaThreshold : SHADOWALPHATHRESHOLD;
float4x4 mLightVP : LIGHTVIEWPROJ;
float4 vViewportMap : VIEWPORTMAP;

dword dwStencilRef : STENCILREF = 0;
float4 eyePos : EYEPOS = {0.0f, 0.0f, 1.0f, .25f};
float altitudeFactor : ALTITUDEFACTOR = 0.7f;

// SHADOWS
float4 Attenuation : Attenuation;

float4x4 ViewPortMatrix : ViewPortMatrix;
float4   ViewportMap    : ViewportMap;

bool alphaBlendEnable:	AlphaBlendEnable;

float4 lightPos : LightPosition;
float4 lightDir : LightDirection;
float4 hemiMapInfo : HemiMapInfo;

float normalOffsetScale : NormalOffsetScale;

float4 skyColor : SkyColor;
float4 ambientColor : AmbientColor;
float4 sunColor : SunColor;

float attenuationSqrInv : AttenuationSqrInv;
float4 lightColor : LightColor;
float coneAngle : ConeAngle;

float4 paraboloidValues : ParaboloidValues;
float4 paraboloidZValues : ParaboloidZValues;

float4x3 uvMatrix[8]: UVMatrix;

texture texture0: TEXLAYER0;
sampler diffuseSamplerClamp = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler diffuseSampler      = sampler_state { Texture = (texture0); MinFilter = Linear; MagFilter = Linear; MipFilter = Linear; AddressU = Wrap; AddressV = Wrap; };

texture texture1: TEXLAYER1;
sampler lightSampler  = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler normalSampler = sampler_state { Texture = (texture1); MinFilter = Linear; MagFilter = Linear; MipFilter = Linear; AddressU = Wrap; AddressV = Wrap; };

texture texture2: TEXLAYER2;
sampler sampler2point   = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT;  MagFilter = POINT; };
sampler samplerNormal1  = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler samplerNormal2  = sampler_state { Texture = (texture2); AddressU = WRAP;  AddressV = WRAP;  MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler colorLUTSampler = sampler_state { Texture = (texture2); MinFilter = Linear; MagFilter = Linear; AddressU = Clamp; AddressV = Clamp; };

texture texture3: TEXLAYER3;
sampler     shadowSampler = sampler_state { Texture = (texture3); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
samplerCUBE envmapSampler = sampler_state { Texture = (texture3); AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };

sampler dummySampler  = sampler_state { MinFilter = Linear; MagFilter = Linear;AddressU = Clamp; AddressV = Clamp; };

struct appdata
{
    float4 Pos          : POSITION;
    float3 Normal       : NORMAL;
    float4 BlendIndices : BLENDINDICES;
    float2 TexCoord     : TEXCOORD0;
    float3 Tan          : TANGENT;
    float3 Binorm       : BINORMAL;
};

struct VS_OUTPUT
{
    float4 HPos      : POSITION;
    float2 NormalMap : TEXCOORD0;
    float3 LightVec  : TEXCOORD1;
    float3 HalfVec   : TEXCOORD2;
    float2 DiffMap   : TEXCOORD3;
    float  Fog       : FOG;
};

struct VS_OUTPUT20
{
    float4 HPos     : POSITION;
    float2 Tex0     : TEXCOORD0;
    float3 LightVec : TEXCOORD1;
    float3 HalfVec  : TEXCOORD2;
    float  Fog      : FOG;
};

struct VS_OUTPUT2
{
    float4 HPos     : POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Diffuse  : COLOR;
    float Fog       : FOG;
};

struct VS_OUTPUT_AlphaScope
{
    float4 HPos         : POSITION;
    float3 Tex0AndTrans	: TEXCOORD0;
    float2 Tex1         : TEXCOORD1;
    float  Fog          : FOG;
};

struct VS_OUTPUT_Alpha
{
    float4 HPos       : POSITION;
    float2 DiffuseMap : TEXCOORD0;
    float4 Tex1       : TEXCOORD1;
    float Fog         : FOG;
};

struct VS_OUTPUT_AlphaEnvMap
{
    float4 HPos                : POSITION;
    float2 DiffuseMap          : TEXCOORD0;
    float4 TexPos              : TEXCOORD1;
    float2 NormalMap           : TEXCOORD2;
    float3 TanToCubeSpace[3]   : TEXCOORD5;
    float4 EyeVecAndReflection : TEXCOORD4;
    float Fog                  : FOG;
};

struct VS2PS_ShadowMap
{
    float4 HPos  : POSITION;
    float2 PosZW : TEXCOORD0;
};

struct VS2PS_ShadowMapAlpha
{
    float4 HPos        : POSITION;
    float4 Tex0PosZW   : TEXCOORD0;
    // SHADOWS
    float4 Attenuation : COLOR0;
};

/*
    Blinn lighting and diffuse shaders
*/

VS_OUTPUT bumpSpecularVertexShaderBlinn1(
    appdata input,
    uniform float4x4 ViewProj,
    uniform float4x4 ViewInv,
    uniform float4 LightPos)
{
    VS_OUTPUT Out = (VS_OUTPUT)0;

    float4 Constants = float4(0.5, 0.5, 0.5, 1.0);

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    float3 Pos = mul(input.Pos, mOneBoneSkinning[IndexArray[0]]);
    Out.HPos = mul(float4(Pos.xyz, 1.0f), ViewProj);

    // Cross product to create BiNormal
    float3 binormal = normalize(cross(input.Tan, input.Normal));

    // Need to calculate the WorldI based on each matBone skinning world matrix
    float3x3 TanBasis = float3x3(input.Tan, binormal, input.Normal);

    // Calculate WorldTangent directly... inverse is the transpose for affine rotations
    float3x3 worldI = transpose(mul(TanBasis, mOneBoneSkinning[IndexArray[0]]));

    // Pass-through texcoords
    Out.NormalMap = input.TexCoord;
    Out.DiffMap = input.TexCoord;

    // Transform Light pos to Object space
    float3 matsLightDir = float3(0.5, 0.5, 0.0);
    float3 normalizedTanLightVec = normalize(mul(matsLightDir, worldI));

    Out.LightVec = normalizedTanLightVec;

    // Transform eye pos to tangent space
    float3 worldEyeVec = ViewInv[3].xyz - Pos;
    float3 tanEyeVec = mul(worldEyeVec, worldI);

    Out.HalfVec = normalize(normalizedTanLightVec + normalize(tanEyeVec));
    Out.Fog = 0;

    return Out;
}

float4 bumpSpecularPixelShaderBlinn1(VS_OUTPUT input) : COLOR
{
    float4 ambient  = float4(0.4, 0.4, 0.4, 1);
    float4 diffuse  = float4(1, 1, 1, 1);
    float4 specular = float4(1, 1, 1, 1);

    float4 normalmap = tex2D(normalSampler, input.NormalMap);
    float u = dot(input.LightVec, (input.NormalMap * 2.0) - 1.0);
    float v = dot(input.HalfVec, (input.NormalMap * 2.0) - 1.0);
    float4 gloss = tex2D(diffuseSampler, float2(u,v));
    float4 diffusemap = tex2D(diffuseSampler, input.DiffMap);

    float4 outColor = saturate((gloss * diffuse) + ambient);
    outColor *= diffusemap;

    float spec = normalmap.a * gloss.a;
    outColor = saturate((spec * specular) + outColor);
    return outColor;
}

VS_OUTPUT20 bumpSpecularVertexShaderBlinn20(
    appdata input,
    uniform float4x4 ViewProj,
    uniform float4x4 ViewInv,
    uniform float4 LightPos)
{
    VS_OUTPUT20 Out = (VS_OUTPUT20)0;

    float4 Constants = float4(0.5, 0.5, 0.5, 1.0);

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    float3 Pos = mul(input.Pos, mOneBoneSkinning[IndexArray[0]]);
    Out.HPos = mul(float4(Pos.xyz, 1.0), ViewProj);

    // Cross product to create BiNormal
    float3 binormal = normalize(cross(input.Tan, input.Normal));

    // Need to calculate the WorldI based on each matBone skinning world matrix
    float3x3 TanBasis = float3x3(input.Tan, binormal, input.Normal);

    // Calculate WorldTangent directly... inverse is the transpose for affine rotations
    float3x3 worldI = transpose(mul(TanBasis, mOneBoneSkinning[IndexArray[0]]));

    // Pass-through texcoords
    Out.Tex0 = input.TexCoord;

    // Transform Light pos to Object space
    float3 matsLightDir = float3(0.5, 0.5, 0.0);
    float3 normalizedTanLightVec = normalize(mul(matsLightDir, worldI));

    Out.LightVec = normalizedTanLightVec;

    // Transform eye pos to tangent space
    float3 worldEyeVec = ViewInv[3].xyz - Pos;
    float3 tanEyeVec = mul(worldEyeVec, worldI);

    Out.HalfVec = normalize(normalizedTanLightVec + normalize(tanEyeVec));
    Out.Fog = 0;

    return Out;
}


float4 PShade2(VS_OUTPUT20 i) : COLOR
{
    float4 cosang, tDiffuse, tNormal, col, tShadow;
    float3 tLight;

    // Sample diffuse texture and Normal map
    tDiffuse = tex2D(diffuseSampler, i.Tex0 );

    // sample tLight
    tNormal = 2.0 * tex2D(normalSampler, i.Tex0) - 1.0;
    tLight = 2.0 * i.LightVec - 1.0;

    // DP Lighting in tangent space (where normal map is based)
    // Modulate with Diffuse texture
    col = dot(tNormal.xyz, tLight) * tDiffuse;

    cosang = dot(tNormal.xyz, i.HalfVec); // N.H for specular term
    cosang = pow(cosang, 32) * tNormal.w; // Raise to a power for falloff - try changing the power to 255!
    tShadow = tex2D(shadowSampler, i.Tex0); // Sample shadow texture

    // Add to diffuse lit texture value
    float4 res = (col  + cosang)*tShadow;
    return float4(res.xyz, tDiffuse.w);
}

VS_OUTPUT2 diffuseVertexShader(
    appdata input,
    uniform float4x4 ViewProj,
    uniform float4x4 ViewInv,
    uniform float4 LightPos,
    uniform float4 EyePos)
{
    VS_OUTPUT2 Out = (VS_OUTPUT2)0;

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    //float3 Pos = input.Pos;
    float3 Pos = mul(input.Pos, mOneBoneSkinning[IndexArray[0]]);
    Out.HPos = mul(float4(Pos.xyz, 1.0), ViewProj);

    float3 Normal = input.Normal;
    Normal = normalize(Normal);

    // Pass-through texcoords
    Out.TexCoord = input.TexCoord;

    /*
        Need to calculate the WorldI based on each matBone skinning world matrix
        There must be a more efficient way to do this...
        Inverse is simplified to M-1 = Rt * T,
        where Rt is the transpose of the rotaional part and T is the translation
    */
    float4x4 worldI;
    float3x3 R;
    R[0] = float3(mOneBoneSkinning[IndexArray[0]][0].xyz);
    R[1] = float3(mOneBoneSkinning[IndexArray[0]][1].xyz);
    R[2] = float3(mOneBoneSkinning[IndexArray[0]][2].xyz);
    float3x3 Rtranspose = transpose(R);
    float3 T = mul(mOneBoneSkinning[IndexArray[0]][3],Rtranspose);
    worldI[0] = float4(Rtranspose[0].xyz,T.x);
    worldI[1] = float4(Rtranspose[1].xyz,T.y);
    worldI[2] = float4(Rtranspose[2].xyz,T.z);
    worldI[3] = float4(0.0, 0.0, 0.0, 1.0);

    // Transform Light pos to Object space
    float3 matsLightDir = float3(0.2, 0.8, -0.2);
    float3 lightDirObjSpace = mul(-matsLightDir, worldI);
    float3 normalizedLightVec = normalize(lightDirObjSpace);

    float color = 0.8 + max(0.0, dot(Normal, normalizedLightVec));
    Out.Diffuse = float2(color, 1.0).xxxy;
    Out.Fog = 0;

    return Out;
}

float4 diffusePixelShader(VS_OUTPUT2 input) : COLOR
{
    float4 outColor = tex2D(diffuseSampler, input.TexCoord);
    outColor *= input.Diffuse;
    return outColor;
}

technique Full_States <bool Restore = true;>
{
    pass BeginStates
    {
        AlphaTestEnable = TRUE;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        Sampler[1] = <dummySampler>;
        Sampler[2] = <colorLUTSampler>;
    }

    pass EndStates { }
}

technique Full
{
    pass p0
    {
        VertexShader = compile vs_2_a bumpSpecularVertexShaderBlinn1(viewProjMatrix, viewInverseMatrix, lightPos);
        PixelShader = compile ps_2_a bumpSpecularPixelShaderBlinn1();
    }
}

technique Full20
{
    pass p0
    {
        ZEnable = true;
        ZWriteEnable = true;
        AlphaBlendEnable = false;
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        VertexShader = compile vs_2_a bumpSpecularVertexShaderBlinn20(viewProjMatrix, viewInverseMatrix, lightPos);
        PixelShader = compile ps_2_a PShade2();
    }
}

technique t1
{
    pass p0
    {

        ZEnable = true;
        ZWriteEnable = true;
        AlphaBlendEnable = false;
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        VertexShader = compile vs_2_a diffuseVertexShader(viewProjMatrix, viewInverseMatrix, lightPos, eyePos);
        PixelShader = compile ps_2_a diffusePixelShader();
    }
}










/*
    Alpha and alpha scope shaders
*/

VS_OUTPUT_Alpha vsAlpha(appdata input, uniform float4x4 ViewProj)
{
    VS_OUTPUT_Alpha Out;

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    float3 Pos = mul(input.Pos, mOneBoneSkinning[IndexArray[0]]);
    Out.HPos = mul(float4(Pos.xyz, 1.0), ViewProj);

    Out.DiffuseMap = input.TexCoord.xy;

    // Hacked to only support 800/600
    Out.Tex1.xy  = (Out.HPos.xy / Out.HPos.ww) * 0.5 + 0.5;
    Out.Tex1.y   = 1.0 - Out.Tex1.y;
    Out.Tex1.xy += vTexProjOffset;
    Out.Tex1.xy = Out.Tex1.xy * Out.HPos.w;
    Out.Tex1.zw = Out.HPos.zw;
    Out.Fog = 0.0;

    return Out;
}

float4 psAlpha(VS_OUTPUT_Alpha indata) : COLOR
{
    float4 projlight = tex2Dproj(lightSampler, indata.Tex1);
    float4 OutCol = tex2D(diffuseSamplerClamp, indata.DiffuseMap);
    OutCol.rgb = (OutCol.rgb * projlight.rgb) + projlight.aaa;
    return OutCol;
}

VS_OUTPUT_AlphaEnvMap vsAlphaEnvMap(appdata input, uniform float4x4 ViewProj)
{
    VS_OUTPUT_AlphaEnvMap Out;

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    float3 Pos = mul(input.Pos, mOneBoneSkinning[IndexArray[0]]);
    Out.HPos = mul(float4(Pos.xyz, 1.0), ViewProj);

    // Hacked to only support 800/600
    Out.TexPos.xy  = (Out.HPos.xy / Out.HPos.ww) * 0.5 + 0.5;
    Out.TexPos.y   = 1.0 - Out.TexPos.y;
    Out.TexPos.xy += vTexProjOffset;
    Out.TexPos.xy  = Out.TexPos.xy * Out.HPos.w;
    Out.TexPos.zw  = Out.HPos.zw;

    // Pass-through texcoords
    Out.DiffuseMap = input.TexCoord;
    Out.NormalMap = input.TexCoord;
    // Cross product to create BiNormal
    float3 binormal = normalize(cross(input.Tan, input.Normal));

    // Need to calculate the TanToCubeState based on each matBone skinning world matrix
    float3x3 TanToObjectBasis;
    TanToObjectBasis[0] = float3(input.Tan.x, binormal.x, input.Normal.x);
    TanToObjectBasis[1] = float3(input.Tan.y, binormal.y, input.Normal.y);
    TanToObjectBasis[2] = float3(input.Tan.z, binormal.z, input.Normal.z);
    Out.TanToCubeSpace[0].x = dot(mOneBoneSkinning[IndexArray[0]][0].xyz, TanToObjectBasis[0]);
    Out.TanToCubeSpace[0].y = dot(mOneBoneSkinning[IndexArray[0]][1].xyz, TanToObjectBasis[0]);
    Out.TanToCubeSpace[0].z = dot(mOneBoneSkinning[IndexArray[0]][2].xyz, TanToObjectBasis[0]);
    Out.TanToCubeSpace[1].x = dot(mOneBoneSkinning[IndexArray[0]][0].xyz, TanToObjectBasis[1]);
    Out.TanToCubeSpace[1].y = dot(mOneBoneSkinning[IndexArray[0]][1].xyz, TanToObjectBasis[1]);
    Out.TanToCubeSpace[1].z = dot(mOneBoneSkinning[IndexArray[0]][2].xyz, TanToObjectBasis[1]);
    Out.TanToCubeSpace[2].x = dot(mOneBoneSkinning[IndexArray[0]][0].xyz, TanToObjectBasis[2]);
    Out.TanToCubeSpace[2].y = dot(mOneBoneSkinning[IndexArray[0]][1].xyz, TanToObjectBasis[2]);
    Out.TanToCubeSpace[2].z = dot(mOneBoneSkinning[IndexArray[0]][2].xyz, TanToObjectBasis[2]);

    // Transform eye pos to tangent space
    Out.EyeVecAndReflection.xyz = Pos - eyePos.xyz;
    Out.EyeVecAndReflection.w = eyePos.w;
    Out.Fog = 0.0;
    return Out;
}

float4 psAlphaEnvMap(VS_OUTPUT_AlphaEnvMap indata) : COLOR
{
    float4 accumLight = tex2Dproj(lightSampler, indata.TexPos);

    float4 outCol;
    outCol = tex2D(diffuseSamplerClamp, indata.DiffuseMap);
    outCol.rgb *= accumLight.rgb;

    float4 normalmap = tex2D(samplerNormal1, indata.NormalMap);
    float3 expandedNormal = (normalmap.xyz * 2.0) - 1.0;
    float3 worldNormal;
    worldNormal.x = dot(indata.TanToCubeSpace[0], expandedNormal);
    worldNormal.y = dot(indata.TanToCubeSpace[1], expandedNormal);
    worldNormal.z = dot(indata.TanToCubeSpace[2], expandedNormal);

    float3 lookup = reflect(normalize(indata.EyeVecAndReflection.xyz),normalize(worldNormal));
    float3 envmapColor = texCUBE(envmapSampler,lookup)*normalmap.a*indata.EyeVecAndReflection.w;
    outCol.rgb += accumLight.a + envmapColor;

    return outCol;
}

VS_OUTPUT_AlphaScope vsAlphaScope(appdata input, uniform float4x4 ViewProj) {
    VS_OUTPUT_AlphaScope Out;

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    float3 Pos = mul(input.Pos, mOneBoneSkinning[IndexArray[0]]);
    Out.HPos = mul(float4(Pos.xyz, 1.0), ViewProj);

    float3 wNormal = mul(input.Normal, mOneBoneSkinning[IndexArray[0]]);
    float3 worldEyeVec = normalize(viewInverseMatrix[3].xyz - Pos);

    float f = dot(wNormal, worldEyeVec);
    f = smoothstep(0.965, 1.0, f);
    Out.Tex0AndTrans.xyz = float3(input.TexCoord, f);

    Out.Tex1.xy = (Out.HPos.xy / Out.HPos.ww) * 0.5 + 0.5;
    Out.Tex1.y = 1.0 - Out.Tex1.y;
    Out.Fog = 0.0;
    return Out;
}

float4 psAlphaScope(VS_OUTPUT_AlphaScope input) : COLOR
{
    float4 accumLight = tex2D(lightSampler, input.Tex1);
    float4 diffuse = tex2D(diffuseSamplerClamp, input.Tex0AndTrans);

    diffuse.rgb = diffuse * accumLight;
    diffuse.a *= (1.0 - input.Tex0AndTrans.b);
    return diffuse;
}
technique alpha
{
    pass p0
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        CullMode = NONE;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        AlphaTestEnable = TRUE;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        VertexShader = compile vs_2_a vsAlpha(viewProjMatrix);
        PixelShader = compile ps_2_a psAlpha();
    }

    pass p1EnvMap
    {
        ZEnable = TRUE;
        ZWriteEnable = FALSE;
        CullMode = NONE;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        AlphaTestEnable = TRUE;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        VertexShader = compile vs_2_a vsAlphaEnvMap(viewProjMatrix);
        PixelShader = compile ps_2_a psAlphaEnvMap();
    }
}

technique alphascope
{
    pass p0
    {
        ZEnable = FALSE;
        ZWriteEnable = FALSE;
        CullMode = NONE;
        AlphaBlendEnable = TRUE;
        SrcBlend = SRCALPHA;
        DestBlend = INVSRCALPHA;
        AlphaTestEnable = FALSE;
        AlphaRef = 0;
        AlphaFunc = GREATER;

        VertexShader = compile vs_2_a vsAlphaScope(viewProjMatrix);
        PixelShader = compile ps_2_a psAlphaScope();
    }
}










/*
    ShadowMap shaders
*/


float4 calcShadowProjCoords(float4 Pos, float4x4 matTrap, float4x4 matLight)
{
    float4 shadowcoords = mul(Pos, matTrap);
    float2 lightZW = mul(Pos, matLight).zw;
    shadowcoords.z = (lightZW.x * shadowcoords.w) / lightZW.y; // (zL*wT)/wL == zL/wL post homo
    return shadowcoords;
}

VS2PS_ShadowMap vsShadowMap(appdata input)
{
    VS2PS_ShadowMap Out;

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    float4 unpackPos = float4(input.Pos.xyz * PosUnpack, 1.0);
    float3 Pos = mul(unpackPos, mOneBoneSkinning[IndexArray[0]]);

    Out.HPos = calcShadowProjCoords(float4(Pos.xyz, 1.0), vpLightTrapezMat, vpLightMat);
    Out.PosZW = Out.HPos.zw;

    return Out;
}

float4 psShadowMap(VS2PS_ShadowMap indata) : COLOR
{
    #if NVIDIA
        return 0;
    #else
        return indata.PosZW.x / indata.PosZW.y;
    #endif
}

VS2PS_ShadowMapAlpha vsShadowMapAlpha(appdata input)
{
    VS2PS_ShadowMapAlpha Out;

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    float4 unpackPos = input.Pos * PosUnpack;
    float3 Pos = mul(unpackPos, mOneBoneSkinning[IndexArray[0]]);
    Out.HPos = calcShadowProjCoords(float4(Pos.xyz, 1.0), vpLightTrapezMat, vpLightMat);

    float4 wpos = float4(Pos.xyz, 1.0);

    Out.Tex0PosZW = float4(input.TexCoord, Out.HPos.zw);
    Out.Attenuation = 0;

    return Out;
}

float4 psShadowMapAlpha(VS2PS_ShadowMapAlpha indata) : COLOR
{
    float alpha = tex2D(diffuseSamplerClamp, indata.Tex0PosZW.xy).a - shadowAlphaThreshold;

    #if NVIDIA
        return alpha;
    #else
        clip(alpha);
        return indata.Tex0PosZW.z / indata.Tex0PosZW.w;
    #endif
}

float4 psShadowMapAlphaNV(VS2PS_ShadowMapAlpha indata) : COLOR
{
    return indata.Tex0PosZW.z / indata.Tex0PosZW.w;
    return tex2D(diffuseSamplerClamp, indata.Tex0PosZW.xy).a - shadowAlphaThreshold;
}

VS2PS_ShadowMap vsShadowMapPoint(appdata input)
{
    VS2PS_ShadowMap Out;

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    float3 wPos = mul(input.Pos*PosUnpack, mOneBoneSkinning[IndexArray[0]]);
    float3 hPos = wPos.xyz - lightPos;
    hPos.z *= paraboloidValues.x;

    float d = length(hPos.xyz);
    hPos.xyz /= d;
    hPos.z += 1.0;
    Out.HPos.xy = hPos.xy / hPos.zz;
    Out.HPos.z = (d * paraboloidZValues.x) + paraboloidZValues.y;
    Out.HPos.w = 1.0;

    Out.PosZW = Out.HPos.zw;

    return Out;
}

VS2PS_ShadowMapAlpha vsShadowMapPointAlpha(appdata input)
{
    VS2PS_ShadowMapAlpha Out;

    // Compensate for lack of UBYTE4 on Geforce3
    int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
    int IndexArray[4] = (int[4])IndexVector;

    float3 wPos = mul(input.Pos*PosUnpack, mOneBoneSkinning[IndexArray[0]]);
    float3 hPos = wPos.xyz - lightPos;
    hPos.z *= paraboloidValues.x;

    float d = length(hPos.xyz);
    hPos.xyz /= d;
    hPos.z += 1;
    Out.HPos.xy = hPos.xy / hPos.zz;
    Out.HPos.z = (d * paraboloidZValues.x) + paraboloidZValues.y;
    Out.HPos.w = 1.0;

    Out.Tex0PosZW = float4(input.TexCoord, Out.HPos.zw);

    // SHADOWS
    Out.Attenuation = 0.0;

    return Out;
}

float4 psShadowMapPointAlpha(VS2PS_ShadowMapAlpha indata) : COLOR
{
    clip(tex2D(diffuseSamplerClamp, indata.Tex0PosZW.xy).a-shadowAlphaThreshold);
    clip(indata.Tex0PosZW.z);
    return indata.Tex0PosZW.z;
}

float4 psShadowMapNV(VS2PS_ShadowMap indata) : COLOR
{
    return indata.PosZW.x / indata.PosZW.y;
}

#if NVIDIA
    PixelShader psShadowMap_Compiled = compile ps_2_a psShadowMap();
    PixelShader psShadowMapAlpha_Compiled = compile ps_2_a psShadowMapAlpha();
#else
    PixelShader psShadowMap_Compiled = compile ps_2_a psShadowMap();
    PixelShader psShadowMapAlpha_Compiled = compile ps_2_a psShadowMapAlpha();
#endif

technique DrawShadowMap
{
    pass directionalspot
    {
        #if NVIDIA
            ColorWriteEnable = 0;
        #endif

        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        AlphaBlendEnable = FALSE;
        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_a vsShadowMap();
        PixelShader = (psShadowMap_Compiled);

        CullMode = CCW;
    }

    pass directionalspotalpha
    {
        #if NVIDIA
            ColorWriteEnable = 0;
        #endif

        #if NVIDIA
            AlphaTestEnable = TRUE;
            AlphaRef = 0;
        #endif

        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        AlphaBlendEnable = FALSE;
        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_a vsShadowMapAlpha();
        PixelShader = (psShadowMapAlpha_Compiled);

        CullMode = CCW;
    }

    pass point_
    {
        #if NVIDIA
            ColorWriteEnable = 0;
        #endif

        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        AlphaBlendEnable = FALSE;
        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_a vsShadowMap();
        PixelShader = (psShadowMap_Compiled);

        CullMode = CCW;
    }

    pass pointalpha
    {
        #if NVIDIA
            ColorWriteEnable = 0;
        #endif

        #if NVIDIA
            AlphaTestEnable = TRUE;
            AlphaRef = 0;
        #endif

        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        AlphaBlendEnable = FALSE;
        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_a vsShadowMapAlpha();
        PixelShader = (psShadowMapAlpha_Compiled);

        CullMode = CCW;
    }
}

// We actually don't need to have 2 techniques here
// but it is kept for back-compatibility with original BF2
technique DrawShadowMapNV
{
    pass directionalspot
    {
        #if NVIDIA
            ColorWriteEnable = 0;
        #endif

        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        AlphaBlendEnable = FALSE;
        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_a vsShadowMap();
        PixelShader = (psShadowMap_Compiled);

        CullMode = CCW;
    }

    pass directionalspotalpha
    {
        #if NVIDIA
            ColorWriteEnable = 0;
        #endif

        #if NVIDIA
            AlphaTestEnable = TRUE;
            AlphaRef = 0;
        #endif

        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        AlphaBlendEnable = FALSE;
        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_a vsShadowMapAlpha();
        PixelShader = (psShadowMapAlpha_Compiled);

        CullMode = None;
    }

    pass point_
    {
        #if NVIDIA
            ColorWriteEnable = 0;
        #endif

        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        AlphaBlendEnable = FALSE;
        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_a vsShadowMap();
        PixelShader = (psShadowMap_Compiled);

        CullMode = None;
    }

    pass pointalpha
    {
        #if NVIDIA
            ColorWriteEnable = 0;
        #endif

        #if NVIDIA
            AlphaTestEnable = TRUE;
            AlphaRef = 0;
        #endif

        ZEnable = TRUE;
        ZFunc = LESSEQUAL;
        ZWriteEnable = TRUE;

        AlphaBlendEnable = FALSE;
        ScissorTestEnable = TRUE;

        VertexShader = compile vs_2_a vsShadowMapAlpha();
        PixelShader = (psShadowMapAlpha_Compiled);

        CullMode = None;
    }
}
