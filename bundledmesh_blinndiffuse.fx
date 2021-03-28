
VS_OUTPUT bumpSpecularVertexShaderBlinn1
(
    appdata input,
    uniform float4x4 ViewProj,
    uniform float4x4 ViewInv,
    uniform float4 LightPos
)
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
    float u = dot(input.LightVec, (input.NormalMap - 0.5) * 2);
    float v = dot(input.HalfVec, (input.NormalMap - 0.5) * 2);
    float4 gloss = tex2D(diffuseSampler, float2(u,v));
    float4 diffusemap = tex2D(diffuseSampler, input.DiffMap);

    float4 outColor = saturate((gloss * diffuse) + ambient);
    outColor *= diffusemap;

    float spec = normalmap.a * gloss.a;
    outColor = saturate((spec * specular) + outColor);
    return outColor;
}

VS_OUTPUT20 bumpSpecularVertexShaderBlinn20
(
    appdata input,
    uniform float4x4 ViewProj,
    uniform float4x4 ViewInv,
    uniform float4 LightPos
)
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


float4 PShade2(	VS_OUTPUT20 i) : COLOR
{
    float4    cosang, tDiffuse, tNormal, col, tShadow;
    float3    tLight;

    // Sample diffuse texture and Normal map
    tDiffuse = tex2D( diffuseSampler, i.Tex0 );

    // sample tLight  (_bx2 = 2 * source � 1)
    tNormal = 2.0 * tex2D( normalSampler, i.Tex0) - 1.0;
    tLight = 2.0 * i.LightVec - 1.0;

    // DP Lighting in tangent space (where normal map is based)
    // Modulate with Diffuse texture
    col = dot(tNormal.xyz, tLight) * tDiffuse;

    // N.H for specular term
    cosang = dot(tNormal.xyz, i.HalfVec);

    // Raise to a power for falloff
    cosang = pow(cosang, 32) * tNormal.w; // try changing the power to 255!

    // Sample shadow texture
    tShadow = tex2D(sampler3, i.Tex0);

    // Add to diffuse lit texture value
    float4 res = (col  + cosang)*tShadow;
    return float4(res.xyz,tDiffuse.w);
}

VS_OUTPUT2 diffuseVertexShader
(
    appdata input,
    uniform float4x4 ViewProj,
    uniform float4x4 ViewInv,
    uniform float4 LightPos,
    uniform float4 EyePos
)
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

    // Need to calculate the WorldI based on each matBone skinning world matrix
    // There must be a more efficient way to do this...
    // Inverse is simplified to M-1 = Rt * T,
    // where Rt is the transpose of the rotaional part and T is the translation
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
    worldI[3] = float4(0.0,0.0,0.0,1.0);

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
