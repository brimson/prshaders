
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
    float4 projlight = tex2Dproj(sampler1, indata.Tex1);
    float4 OutCol = tex2D(sampler0, indata.DiffuseMap);
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

float4 psAlphaEnvMap(VS_OUTPUT_AlphaEnvMap indata) : COLOR {
    float4 accumLight = tex2Dproj(sampler1, indata.TexPos);

    float4 outCol;
    outCol = tex2D(sampler0, indata.DiffuseMap);
    outCol.rgb *= accumLight.rgb;

    float4 normalmap = tex2D(sampler2, indata.NormalMap);
    float3 expandedNormal = (normalmap.xyz * 2.0) - 1.0;
    float3 worldNormal;
    worldNormal.x = dot(indata.TanToCubeSpace[0], expandedNormal);
    worldNormal.y = dot(indata.TanToCubeSpace[1], expandedNormal);
    worldNormal.z = dot(indata.TanToCubeSpace[2], expandedNormal);

    float3 lookup = reflect(normalize(indata.EyeVecAndReflection.xyz),normalize(worldNormal));
    float3 envmapColor = texCUBE(samplerCube3,lookup)*normalmap.a*indata.EyeVecAndReflection.w;
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
    float4 accumLight = tex2D(sampler1, input.Tex1);
    float4 diffuse = tex2D(sampler0, input.Tex0AndTrans);

    diffuse.rgb = diffuse * accumLight;
    diffuse.a *= (1.0 - input.Tex0AndTrans.b);
    return diffuse;
}
