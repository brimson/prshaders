#line 2 "TerrainUGShader.fx"

uniform float4x4 _ViewProj: matVIEWPROJ;
uniform float4x4 _LightViewProj : LIGHTVIEWPROJ;
uniform float4 _ScaleTransXZ : SCALETRANSXZ;
uniform float4 _ScaleTransY : SCALETRANSY;
uniform float4 _ShadowTexCoordScaleAndOffset : SHADOWTEXCOORDSCALEANDOFFSET;
uniform float4 _ViewportMap : VIEWPORTMAP;

uniform texture	Texture_2 : TEXLAYER2;

sampler Sampler_2 = sampler_state
{
	Texture = (Texture_2);
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
};

struct APP2VS_BM_Dx9
{
    float4 Pos0 : POSITION0;
    float4 Pos1 : POSITION1;
    float4 MorphDelta : POSITION2;
    float2 TexCoord0 : TEXCOORD0;
    float3 Normal : NORMAL;
};

struct VS2PS_DynamicShadowmap
{
    float4 Pos : POSITION;
    float4 ShadowTex : TEXCOORD0;
};

VS2PS_DynamicShadowmap DynamicShadowmap_VS(APP2VS_BM_Dx9 Input)
{
	VS2PS_DynamicShadowmap Output;
	
	float4 WPos;
	WPos.xz = (Input.Pos0.xy * _ScaleTransXZ.xy) + _ScaleTransXZ.zw;
	WPos.yw = (Input.Pos1.xw * _ScaleTransY.xy) + _ScaleTransY.zw;

 	Output.Pos = mul(WPos, _ViewProj);

	Output.ShadowTex = mul(WPos, _LightViewProj);
	Output.ShadowTex.z -= 0.007;

	return Output;
}

float4 DynamicShadowmap_PS(VS2PS_DynamicShadowmap Input) : COLOR
{
	float2 Texel = 1.0 / 1024.0;
	float4 Samples;
	Input.ShadowTex.xy = clamp(Input.ShadowTex.xy, _ViewportMap.xy, _ViewportMap.zw);
	Samples.x = tex2D(Sampler_2, Input.ShadowTex.xy);
	Samples.y = tex2D(Sampler_2, Input.ShadowTex.xy + float2(Texel.x, 0.0));
	Samples.z = tex2D(Sampler_2, Input.ShadowTex.xy + float2(0.0, Texel.y));
	Samples.w = tex2D(Sampler_2, Input.ShadowTex.xy + Texel);

	float4 CMPBits = Samples >= saturate(Input.ShadowTex.z);
	float AvgShadowValue = dot(CMPBits, 0.25);
	return 1.0 - saturate(4.0 - Input.ShadowTex.z) + AvgShadowValue.x;
}

technique Dx9Style_BM
{
	pass DynamicShadowmap // p0
	{
		CullMode = CW;
		// ColorWriteEnable = RED|BLUE|GREEN|ALPHA;
		
		ZEnable = FALSE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;
		
 		AlphaBlendEnable = TRUE;
 		SrcBlend = DESTCOLOR;
 		DestBlend = ZERO;
 		
		VertexShader = compile vs_3_0 DynamicShadowmap_VS();
		PixelShader = compile ps_3_0 DynamicShadowmap_PS();
	}
}
