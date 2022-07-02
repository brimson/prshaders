#line 2 "PointSpriteParticles.fx"

/*
	[Attributes from app]
*/

//$TODO this is a temporary solution that is inefficient

/*
	[Attributes from app]
*/

// UNIFORM INPUTS
uniform float4x4 _WorldViewProj : WorldViewProj;
uniform float _BaseSize : BaseSize;
uniform float2 _HeightmapSize : HeightmapSize = 2048.0f;
uniform float _AlphaPixelTestRef : AlphaPixelTestRef = 0.0;

/*
	[Textures and samplers]
*/

// Particle Texture
uniform texture Texture_0: Texture0;

// Groundhemi Texture
uniform texture Texture_1: Texture1;

sampler PointSpritePartices_Diffuse_Sampler = sampler_state
{
	Texture = <Texture_0>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = CLAMP;
	AddressV = CLAMP;
};

sampler PointSpritePartices_Sampler_LUT = sampler_state
{
	Texture = <Texture_1>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = CLAMP;
	AddressV = CLAMP;
};

// Constant array
struct TemplateParameters
{
	float4 m_uvRangeLMapIntensiyAndParticleMaxSize;
	float4 m_lightColorAndRandomIntensity;
	float4 m_color1;
	float4 m_color2;
	float4 m_colorBlendGraph;
	float4 m_transparencyGraph;
	float4 m_sizeGraph;
};

TemplateParameters _Temps[10] : TemplateParameters;
// TemplateParameters _Temps : TemplateParameters;

struct APP2VS
{
	float4 Pos : POSITION;
	float1 AgeFactor : TEXCOORD0;
	float1 GraphIndex : TEXCOORD1;
	float2 RandomSizeAndAlpha : TEXCOORD2;
	float2 IntensityAndRandomIntensity : TEXCOORD3;
};

struct VS2PS
{
	float4 HPos : POSITION;
	float4 Color : COLOR;
	float4 TexCoords : TEXCOORD0; // .xy = Diffuse Coord; .zw = Hemi lookup-table Coord
	float LightMapIntensityOffset : TEXCOORD1;
	float PointSize : PSIZE0;
};

VS2PS Pointsprite_VS(APP2VS Input)
{
	VS2PS Output;
	Output.HPos = mul(float4(Input.Pos.xyz, 1.0f), _WorldViewProj);

	// Particle diffuse coords
	Output.TexCoords.xy = 0;

	// Hemi lookup coords
	Output.TexCoords.zw = (Input.Pos.xyz + (_HeightmapSize / 2.0)).xz / _HeightmapSize;

	// Compute Cubic polynomial factors.
	float4 PC = float4(pow(Input.AgeFactor, float3(3.0, 2.0, 1.0)), 1.0);

	// compute size of particle using the constants of the template (mSizeGraph)
	float PointSize = min(dot(_Temps[Input.GraphIndex.x].m_sizeGraph, PC), 1.0) * _Temps[Input.GraphIndex.x].m_uvRangeLMapIntensiyAndParticleMaxSize.w;
	PointSize = (PointSize + Input.RandomSizeAndAlpha.x) * _BaseSize;
	Output.PointSize = PointSize / Output.HPos.w;

	Output.LightMapIntensityOffset = _Temps[Input.GraphIndex.x].m_uvRangeLMapIntensiyAndParticleMaxSize.z;

	float ColorBlendFactor = min(dot(_Temps[Input.GraphIndex.x].m_colorBlendGraph, PC), 1);
	float3 Color = ColorBlendFactor * _Temps[Input.GraphIndex.x].m_color2;
	Color += (1.0 - ColorBlendFactor) * _Temps[Input.GraphIndex.x].m_color1;
	Output.Color.rgb = (Color * Input.IntensityAndRandomIntensity[0]) + Input.IntensityAndRandomIntensity[1];
	float AlphaBlendFactor = min(dot(_Temps[Input.GraphIndex.x].m_transparencyGraph, PC), 1.0);
	Output.Color.a = AlphaBlendFactor * Input.RandomSizeAndAlpha[1];
	Output.Color = saturate(Output.Color);

	return Output;
}

float4 Pointsprite_PS(VS2PS Input) : COLOR
{
	float4 TDiffuse = tex2D(PointSpritePartices_Diffuse_Sampler, Input.TexCoords.xy);
	float4 TLUT = tex2D(PointSpritePartices_Sampler_LUT, Input.TexCoords.zw);
	float4 Color = Input.Color * TDiffuse;
	Color.rgb *= TLUT.a + Input.LightMapIntensityOffset;
	return Color;
}

technique PointSprite
<
	int Declaration[] =
	{
		// StreamNo, DataType, Usage, UsageIdx
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
		{ 0, D3DDECLTYPE_FLOAT1, D3DDECLUSAGE_TEXCOORD, 0 },
		{ 0, D3DDECLTYPE_FLOAT1, D3DDECLUSAGE_TEXCOORD, 1 },
		{ 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 2 },
		{ 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 3 },
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		CullMode = NONE;
		ZEnable = TRUE;
		ZFunc = LESSEQUAL;
		ZWriteEnable = FALSE;
		StencilEnable = TRUE;
		StencilFunc = ALWAYS;
		StencilPass = ZERO;
		AlphaTestEnable = TRUE;
		AlphaRef = <_AlphaPixelTestRef>;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = ONE;

		Texture[0] = (Texture_0);
		Texture[1] = NULL;
		Texture[2] = NULL;
		Texture[3] = NULL;

		PointSpriteEnable = TRUE;
		PointScaleEnable = TRUE;
		// ColorArg1[0] = DIFFUSE;
		// ColorArg2[0] = TEXTURE;
		// ColorOp[0] = MODULATE;
		// PointSpriteScaleEnable = TRUE;
		VertexShader = compile vs_3_0 Pointsprite_VS();
		PixelShader = compile ps_3_0 Pointsprite_PS();
	}
}
