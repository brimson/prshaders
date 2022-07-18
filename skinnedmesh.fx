//
// Description: 1,2 bone skinning 
//
// Author: Mats Dal

// Note: obj space light vectors
float4 sunLightDir : SunLightDirection;
float4 lightDir : LightDirection;
//float hemiMapInfo.z : hemiMapInfo.z;
float normalOffsetScale : NormalOffsetScale;
//float hemiMapInfo.w : hemiMapInfo.w;

// offset x/y hemiMapInfo.z z / hemiMapInfo.w w
float4 hemiMapInfo : HemiMapInfo;

float4 skyColor : SkyColor;
float4 ambientColor : AmbientColor;
float4 sunColor : SunColor;

float4 lightPos : LightPosition;
float attenuationSqrInv : AttenuationSqrInv;
float4 lightColor : LightColor;

float shadowAlphaThreshold : SHADOWALPHATHRESHOLD;

float coneAngle : ConeAngle;

float4 worldEyePos : WorldEyePos;

float4 objectEyePos : ObjectEyePos;

float4x4 mLightVP : LIGHTVIEWPROJ;
	float4x4 mLightVP2 : LIGHTVIEWPROJ2;
	float4x4 mLightVP3 : LIGHTVIEWPROJ3;
float4 vViewportMap : VIEWPORTMAP;

dword dwStencilRef : STENCILREF = 0;

float4x4 mWorld : World;
float4x4 mWorldT : WorldT;
float4x4 mWorldView : WorldView;
float4x4 mWorldViewI : WorldViewI; // (WorldViewIT)T = WorldViewI
float4x4 mWorldViewProj	: WorldViewProjection;
float4x3 mBoneArray[26]	: BoneArray;//  : register(c15) < bool sparseArray = true; int arrayStart = 15; >;

float4x4 vpLightMat : vpLightMat;
float4x4 vpLightTrapezMat : vpLightTrapezMat;

float4 paraboloidValues : ParaboloidValues;
float4 paraboloidZValues : ParaboloidZValues;

texture texture0: TEXLAYER0;
texture texture1: TEXLAYER1;
texture texture2: TEXLAYER2;
texture texture3: TEXLAYER3;
texture texture4: TEXLAYER4;

sampler sampler0 = sampler_state { Texture = (texture0); MipFilter = LINEAR; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler1 = sampler_state { Texture = (texture1); MipFilter = LINEAR; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler2 = sampler_state { Texture = (texture2); MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler3 = sampler_state { Texture = (texture3); MipFilter = LINEAR; MinFilter = LINEAR; MagFilter = LINEAR; };

sampler sampler2point = sampler_state { Texture = (texture2); MinFilter = POINT; MagFilter = POINT; };

struct APP2VS
{
	float4	Pos 		: POSITION;    
	float3	Normal 		: NORMAL;
	float	BlendWeights	: BLENDWEIGHT;
	float4	BlendIndices 	: BLENDINDICES;    
	float2	TexCoord0 	: TEXCOORD0;
};

// object based lighting

void skinSoldierForPP(uniform int NumBones, in APP2VS indata, in float3 lightVec, out float3 Pos, out float3 Normal, out float3 SkinnedLVec)
{
	float LastWeight = 0.0;
	Pos = 0.0;
	Normal = 0.0;    
	SkinnedLVec = 0.0;
	
	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(indata.BlendIndices);
	
	// Cast the vectors to arrays for use in the for loop below
	float BlendWeightsArray[1] = (float[1])indata.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;    
	
	// Calculate the pos/normal using the "normal" weights 
	// and accumulate the weights to calculate the last weight
	for (int iBone = 0; iBone < NumBones-1; iBone++)
	{
		LastWeight += BlendWeightsArray[iBone];
		
		Pos += mul(indata.Pos, mBoneArray[IndexArray[iBone]]) * BlendWeightsArray[iBone];
		Normal += mul(indata.Normal, mBoneArray[IndexArray[iBone]]) * BlendWeightsArray[iBone];
		float3x3 mat = transpose((float3x3)mBoneArray[IndexArray[iBone]]);
		SkinnedLVec += mul(lightVec, mat) * BlendWeightsArray[iBone];
	}
	LastWeight = 1.0 - LastWeight; 
	
	// Now that we have the calculated weight, add in the final influence
	Pos += mul(indata.Pos, mBoneArray[IndexArray[NumBones-1]]) * LastWeight;
	Normal += mul(indata.Normal, mBoneArray[IndexArray[NumBones-1]]) * LastWeight;
	float3x3 mat = transpose((float3x3)mBoneArray[IndexArray[NumBones-1]]);
	SkinnedLVec += mul(lightVec, mat) * LastWeight;
	
	// Normalize normals
	Normal = normalize(Normal);
	//SkinnedLVec = normalize(SkinnedLVec); // Don't normalize
}


// tangent based lighting

struct APP2VStangent
{
	float4	Pos 		: POSITION;    
	float3	Normal 		: NORMAL;
	float	BlendWeights	: BLENDWEIGHT;
	float4	BlendIndices 	: BLENDINDICES;    
	float2	TexCoord0 	: TEXCOORD0;
    float3  Tan : TANGENT;
};



struct VS2PS_PP
{
	float4	Pos		: POSITION;
	float2	Tex0		: TEXCOORD0;
	float3	GroundUVAndLerp	: TEXCOORD1;
	float3	SkinnedLVec		: TEXCOORD2;
	float3	HalfVec		: TEXCOORD3;
};



//----------------
// humanskin
//----------------

struct VS2PS_Skinpre
{
	float4	Pos				: POSITION;
	float2	Tex0			: TEXCOORD0;
	float3	SkinnedLVec		: TEXCOORD1;
	float3	ObjEyeVec		: TEXCOORD2;
	float3	GroundUVAndLerp : TEXCOORD3;
};

VS2PS_Skinpre vsSkinpre(APP2VS indata, uniform int NumBones)
{
	VS2PS_Skinpre outdata;
	float3 Pos, Normal;
	
	skinSoldierForPP(NumBones, indata, -sunLightDir.xyz, Pos, Normal, outdata.SkinnedLVec);

	outdata.ObjEyeVec = normalize(objectEyePos.xyz-Pos);

	outdata.Pos.xy = indata.TexCoord0 * float2(2,-2) - float2(1, -1);
	outdata.Pos.zw = float2(0, 1);

 	// Hemi lookup values
	float4 wPos = mul(Pos, mWorld); 
 	outdata.GroundUVAndLerp.xy = ((wPos.xyz +(hemiMapInfo.z/2) + Normal*1/*normalOffsetScale*/).xz - hemiMapInfo.xy)/ hemiMapInfo.z;
	outdata.GroundUVAndLerp.y = 1-outdata.GroundUVAndLerp.y;
	outdata.GroundUVAndLerp.z = (Normal.y+1/*normalOffsetScale*/)/2;
	outdata.GroundUVAndLerp.z -= hemiMapInfo.w;
	
	outdata.Tex0 = indata.TexCoord0;
	outdata.SkinnedLVec = normalize(outdata.SkinnedLVec);
	
	return outdata;
}

float4 psSkinpre(VS2PS_Skinpre indata) : COLOR
{
	//return float4(indata.ObjEyeVec,0);
	float4 expnormal = tex2D(sampler0, indata.Tex0);
	float4 groundcolor = tex2D(sampler1, indata.GroundUVAndLerp.xy);
	
	expnormal.rgb = (expnormal * 2) - 1;
	float wrapDiff = dot(expnormal.xyz, indata.SkinnedLVec) + 0.5;
	wrapDiff = saturate(wrapDiff / 1.5);

	float rimDiff = 1-dot(expnormal.xyz, indata.ObjEyeVec);
	rimDiff = pow(rimDiff,3);

	rimDiff *= saturate(0.75-saturate(dot(indata.ObjEyeVec, indata.SkinnedLVec)));
	//rimDiff *= saturate(0.1-saturate(dot(indata.ObjEyeVec, normalize(indata.SkinnedLVec))));
	
	return float4((wrapDiff.rrr + rimDiff)*groundcolor.a*groundcolor.a, expnormal.a);
}

struct VS2PS_Skinpreshadowed
{
	float4	Pos				: POSITION;
	float4	Tex0AndHZW		: TEXCOORD0;
	float3	SkinnedLVec		: TEXCOORD1;
	float4	ShadowTex		: TEXCOORD2;
	float3	ObjEyeVec		: TEXCOORD3;
};

VS2PS_Skinpreshadowed vsSkinpreshadowed(APP2VS indata, uniform int NumBones)
{
	VS2PS_Skinpreshadowed outdata;
	float3 Pos, Normal;
	
	// don't need as much code for this case.. will rewrite later
	skinSoldierForPP(NumBones, indata, -sunLightDir.xyz, Pos, Normal, outdata.SkinnedLVec);

	outdata.ObjEyeVec = normalize(objectEyePos.xyz-Pos);

	outdata.ShadowTex = mul(float4(Pos, 1), mLightVP);
	outdata.ShadowTex.z -= 0.007;

	outdata.Pos.xy = indata.TexCoord0 * float2(2,-2) - float2(1, -1);
	outdata.Pos.zw = float2(0, 1);
	outdata.Tex0AndHZW/*.xy*/ = indata.TexCoord0.xyyy;
	
	return outdata;
}

float4 psSkinpreshadowed(VS2PS_Skinpreshadowed indata) : COLOR
{
	float4 expnormal = tex2D(sampler0, indata.Tex0AndHZW.xy);
	expnormal.rgb = (expnormal * 2) - 1;

	float wrapDiff = dot(expnormal.xyz, indata.SkinnedLVec) + 0.5;
	wrapDiff = saturate(wrapDiff / 1.5);

	float rimDiff = 1-dot(expnormal.xyz, indata.ObjEyeVec);
	rimDiff = pow(rimDiff,3);
	rimDiff *= saturate(0.75-saturate(dot(indata.ObjEyeVec, indata.SkinnedLVec)));

	float2 texel = float2(1.0/1024.0, 1.0/1024.0);
	float4 samples;
	//indata.ShadowTex.xy = clamp(indata.ShadowTex.xy, vViewportMap.xy, vViewportMap.zw);
	samples.x = tex2D(sampler2point, indata.ShadowTex.xy);
	samples.y = tex2D(sampler2point, indata.ShadowTex.xy + float2(texel.x, 0));
	samples.z = tex2D(sampler2point, indata.ShadowTex.xy + float2(0, texel.y));
	samples.w = tex2D(sampler2point, indata.ShadowTex.xy + texel);
	
	float4 staticSamples;
	staticSamples.x = tex2D(sampler1, indata.ShadowTex.xy + float2(-texel.x*1, -texel.y*2)).b;
	staticSamples.y = tex2D(sampler1, indata.ShadowTex.xy + float2( texel.x*1, -texel.y*2)).b;
	staticSamples.z = tex2D(sampler1, indata.ShadowTex.xy + float2(-texel.x*1,  texel.y*2)).b;
	staticSamples.w = tex2D(sampler1, indata.ShadowTex.xy + float2( texel.x*1,  texel.y*2)).b;
	staticSamples.x = dot(staticSamples.xyzw, 0.25);
	
	float4 cmpbits = samples > saturate(indata.ShadowTex.z);
	float avgShadowValue = dot(cmpbits, float4(0.25, 0.25, 0.25, 0.25));

	float totShadow = avgShadowValue.x*staticSamples.x;
	float totDiff = wrapDiff + rimDiff;
	return float4(totDiff, totShadow, saturate(totShadow+0.35), expnormal.a);
}

float4 psSkinpreshadowedNV(VS2PS_Skinpreshadowed indata) : COLOR
{
	float4 expnormal = tex2D(sampler0, indata.Tex0AndHZW.xy);
	expnormal.rgb = (expnormal * 2) - 1;

	float wrapDiff = dot(expnormal.xyz, indata.SkinnedLVec) + 0.5;
	wrapDiff = saturate(wrapDiff / 1.5);

	float rimDiff = 1-dot(expnormal.xyz, indata.ObjEyeVec);
	rimDiff = pow(rimDiff,3);
	rimDiff *= saturate(0.75-saturate(dot(indata.ObjEyeVec, indata.SkinnedLVec)));

	float2 texel = float2(1.0/1024.0, 1.0/1024.0);
	float avgShadowValue = tex2Dproj(sampler2, indata.ShadowTex); // HW percentage closer filtering.
	
	float4 staticSamples;
	//indata.ShadowTex.xy = clamp(indata.ShadowTex.xy, vViewportMap.xy, vViewportMap.zw);
	staticSamples.x = tex2D(sampler1, indata.ShadowTex.xy + float2(-texel.x*1, -texel.y*2)).b;
	staticSamples.y = tex2D(sampler1, indata.ShadowTex.xy + float2( texel.x*1, -texel.y*2)).b;
	staticSamples.z = tex2D(sampler1, indata.ShadowTex.xy + float2(-texel.x*1,  texel.y*2)).b;
	staticSamples.w = tex2D(sampler1, indata.ShadowTex.xy + float2( texel.x*1,  texel.y*2)).b;
	staticSamples.x = dot(staticSamples.xyzw, 0.25);
	
	//float4 cmpbits = samples > saturate(indata.ShadowTex.z);
	//float avgShadowValue = dot(cmpbits, float4(0.25, 0.25, 0.25, 0.25));

	float totShadow = avgShadowValue.x*staticSamples.x;
	float totDiff = wrapDiff + rimDiff;
	return float4(totDiff, totShadow, saturate(totShadow+0.35), expnormal.a);
}

VS2PS_PP vsSkinapply(APP2VS indata, uniform int NumBones)
{
	VS2PS_PP outdata;
	
	float3 Pos,Normal;
	
	skinSoldierForPP(NumBones, indata, -sunLightDir.xyz, Pos, Normal, outdata.SkinnedLVec);
	
	// Transform position into view and then projection space
	outdata.Pos = mul(float4(Pos.xyz, 1.0f), mWorldViewProj); 

 	// Hemi lookup values
	float4 wPos = mul(Pos, mWorld); 
 	outdata.GroundUVAndLerp.xy = ((wPos.xyz +(hemiMapInfo.z/2) + Normal*1/*normalOffsetScale*/).xz - hemiMapInfo.xy)/ hemiMapInfo.z;
	outdata.GroundUVAndLerp.y = 1-outdata.GroundUVAndLerp.y;
	outdata.GroundUVAndLerp.z = (Normal.y+1/*normalOffsetScale*/)/2;
	outdata.GroundUVAndLerp.z -= hemiMapInfo.w;

	outdata.Tex0 = indata.TexCoord0;
	outdata.HalfVec = normalize(normalize(objectEyePos.xyz-Pos) + outdata.SkinnedLVec);
	outdata.SkinnedLVec = normalize(outdata.SkinnedLVec);

	
	return outdata;
}

float4 psSkinapply(VS2PS_PP indata) : COLOR
{
	//return float4(1,1,1,1);
	float4 groundcolor = tex2D(sampler0, indata.GroundUVAndLerp.xy);
	//return groundcolor;
	float4 hemicolor = lerp(groundcolor, skyColor, indata.GroundUVAndLerp.z);
	float4 expnormal = tex2D(sampler1, indata.Tex0);
	expnormal.rgb = (expnormal * 2) - 1;
	float4 diffuse = tex2D(sampler2, indata.Tex0);
	float4 diffuseLight = tex2D(sampler3, indata.Tex0);
//return diffuseLight;
	// glossmap is in the diffuse alpha channel.
	float specular = pow(dot(expnormal.rgb, indata.HalfVec), 16)*diffuse.a;

	float4 totalcolor = saturate(ambientColor*hemicolor + diffuseLight.r*diffuseLight.b*sunColor);
	//return totalcolor;
	totalcolor *= diffuse;//+specular;

	// what to do what the shadow???
	float shadowIntensity = saturate(diffuseLight.g/*+ShadowIntensityBias*/);
	totalcolor.rgb += specular* shadowIntensity*shadowIntensity;

	return totalcolor;
}


technique humanskin
{
	pass pre
	{
		CullMode = NONE;
		AlphaBlendEnable = FALSE;
		ZEnable = FALSE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;

		StencilEnable = FALSE;

		VertexShader = compile vs_2_a vsSkinpre(2);
		PixelShader = compile ps_2_a psSkinpre();
	}
	pass preshadowed
	{
		CullMode = NONE;
		AlphaBlendEnable = FALSE;
		ZEnable = FALSE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;

		StencilEnable = FALSE;

		VertexShader = compile vs_2_a vsSkinpreshadowed(2);
		PixelShader = compile ps_2_a psSkinpreshadowed();
	}
	pass apply
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
		//FillMode = WIREFRAME;

		VertexShader = compile vs_2_a vsSkinapply(2);
		PixelShader = compile ps_2_a psSkinapply();
	}
}


struct VS2PS_ShadowMap
{
	float4	Pos		: POSITION;
	float2	PosZW	: TEXCOORD0;
};

VS2PS_ShadowMap vsShadowMap(APP2VS indata)
{
	VS2PS_ShadowMap outdata;
	
	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(indata.BlendIndices);
	
	// Cast the vectors to arrays for use in the for loop below
	float BlendWeightsArray[1] = (float[1])indata.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;    
	
	float3 Pos = mul(indata.Pos, mBoneArray[IndexArray[0]]) * BlendWeightsArray[0];
	Pos += mul(indata.Pos, mBoneArray[IndexArray[1]]) * (1-BlendWeightsArray[0]);
	
 	outdata.Pos = mul(float4(Pos.xyz, 1.0), vpLightTrapezMat);
 	float2 lightZW = mul(float4(Pos.xyz, 1.0), vpLightMat).zw;
	outdata.Pos.z = (lightZW.x*outdata.Pos.w)/lightZW.y;			// (zL*wT)/wL == zL/wL post homo
 	outdata.PosZW = outdata.Pos.zw;

 	return outdata;

//SHADOW
// TBD: mul matrices on CPU	
/*	matrix m = mul( vpLightMat, vpLightTrapezMat );
	outdata.Pos = mul( float4(Pos.xyz, 1.0), m );
*/	outdata.Pos = mul( float4(Pos.xyz, 1.0), vpLightMat );
 	outdata.PosZW = outdata.Pos.zw;	
//\SHADOW	
	return outdata;
}

float4 psShadowMap(VS2PS_ShadowMap indata) : COLOR
{
#if NVIDIA
	return 0;
#else
	return indata.PosZW.x / indata.PosZW.y;
#endif
}


struct VS2PS_ShadowMapAlpha
{
	float4	Pos		: POSITION;
	float4	Tex0PosZW	: TEXCOORD0;
};

VS2PS_ShadowMapAlpha vsShadowMapAlpha(APP2VS indata)
{
	VS2PS_ShadowMapAlpha outdata;
	
	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(indata.BlendIndices);
	
	// Cast the vectors to arrays for use in the for loop below
	float BlendWeightsArray[1] = (float[1])indata.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;    
	
	float3 Pos = mul(indata.Pos, mBoneArray[IndexArray[0]]) * BlendWeightsArray[0];
	Pos += mul(indata.Pos, mBoneArray[IndexArray[1]]) * (1-BlendWeightsArray[0]);
	

 	outdata.Pos = mul(float4(Pos.xyz, 1.0), vpLightTrapezMat);
 	float2 lightZW = mul(float4(Pos.xyz, 1.0), vpLightMat).zw;
	outdata.Pos.z = (lightZW.x*outdata.Pos.w)/lightZW.y;			// (zL*wT)/wL == zL/wL post homo
 	outdata.Tex0PosZW.xy = indata.TexCoord0;
 	outdata.Tex0PosZW.zw = outdata.Pos.zw;

 	return outdata;
}

float4 psShadowMapAlpha(VS2PS_ShadowMapAlpha indata) : COLOR
{
	float alpha = tex2D(sampler0, indata.Tex0PosZW.xy).a-shadowAlphaThreshold;

#if NVIDIA
	return alpha;
#else
	clip( alpha );
	return indata.Tex0PosZW.z / indata.Tex0PosZW.w;
#endif
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
		ColorWriteEnable = 0;//0x0000000F;
#endif
	
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
		CullMode = CW;

		ScissorTestEnable = TRUE;

		VertexShader = compile vs_2_a vsShadowMap();
		PixelShader = (psShadowMap_Compiled);

		CullMode = None;
	}

	pass directionalspotalpha
	{
#if NVIDIA
		ColorWriteEnable = 0;//0x0000000F;
#endif

#if NVIDIA
		AlphaTestEnable = TRUE;
		AlphaRef = 0;
#endif
		
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
		
		ScissorTestEnable = TRUE;

		VertexShader = compile vs_2_a vsShadowMapAlpha();
		PixelShader = (psShadowMapAlpha_Compiled);
		
		CullMode = CCW;
		CullMode = None;
	}

	pass point_
	{
#if NVIDIA
		ColorWriteEnable = 0;//0x0000000F;
#endif
		
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;

		ScissorTestEnable = TRUE;

		VertexShader = compile vs_2_a vsShadowMap();
		PixelShader = (psShadowMap_Compiled);

		CullMode = None;
	}
}
//#endif

// We actually don't need to have 2 techniques here
// but it is kept for back-compatibility with original BF2
technique DrawShadowMapNV
{
	pass directionalspot
	{
#if NVIDIA
		ColorWriteEnable = 0;//0x0000000F;
#endif
	
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
		CullMode = CW;

		ScissorTestEnable = TRUE;

		VertexShader = compile vs_2_a vsShadowMap();
		PixelShader = (psShadowMap_Compiled);

		CullMode = None;
	}

	pass directionalspotalpha
	{	
#if NVIDIA
		ColorWriteEnable = 0;//0x0000000F;
#endif

#if NVIDIA
		AlphaTestEnable = TRUE;
		AlphaRef = 0;
#endif
		
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
		
		ScissorTestEnable = TRUE;

		VertexShader = compile vs_2_a vsShadowMapAlpha();
		PixelShader = (psShadowMapAlpha_Compiled);
		
		CullMode = CCW;
		CullMode = None;
	}

	pass point_
	{
#if NVIDIA
		ColorWriteEnable = 0;//0x0000000F;
#endif
		
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;

		ScissorTestEnable = TRUE;

		VertexShader = compile vs_2_a vsShadowMap();
		PixelShader = (psShadowMap_Compiled);

		CullMode = None;
	}
}
//#endif
