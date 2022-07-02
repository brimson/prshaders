
/*
	Description: Controls the following post-production shaders
		1. Tinnitus
		2. Glow
		3. Fog
*/

/*
	[Attributes from app]
*/

uniform float _BackBufferLerpBias : BACKBUFFERLERPBIAS;
uniform float2 _SampleOffset : SAMPLEOFFSET;
uniform float2 _FogStartAndEnd : FOGSTARTANDEND;
uniform float3 _FogColor : FOGCOLOR;

/*
	[Textures and samplers]
*/

#define CREATE_SAMPLER(NAME, TEXTURE, ADDRESS, FILTER) \
	sampler NAME = sampler_state \
	{ \
		Texture = TEXTURE; \
		AddressU = ADDRESS; \
		AddressV = ADDRESS; \
		MinFilter = FILTER; \
		MagFilter = FILTER; \
	};

uniform texture Texture_0 : TEXLAYER0;
uniform texture Texture_1 : TEXLAYER1;

/*
	Unused?
	uniform texture Texture2 : TEXLAYER2;
	uniform texture Texture3 : TEXLAYER3;
	uniform texture Texture4 : TEXLAYER4;
	uniform texture Texture5 : TEXLAYER5;
	uniform texture Texture6 : TEXLAYER6;
*/

CREATE_SAMPLER(PostProductionR3X0_Sampler_0_Bilinear, Texture_0, CLAMP, LINEAR)
CREATE_SAMPLER(PostProductionR3X0_Sampler_1_Bilinear, Texture_1, CLAMP, LINEAR)

struct APP2VS_Quad
{
	float2 Pos : POSITION0;
	float2 TexCoord0 : TEXCOORD0;
};

struct VS2PS_Quad
{
	float4 Pos : POSITION;
	float2 TexCoord0 : TEXCOORD0;
};

VS2PS_Quad Basic_VS(APP2VS_Quad Input)
{
	VS2PS_Quad OutData;
	OutData.Pos = float4(Input.Pos.xy, 0.0, 1.0);
	OutData.TexCoord0 = Input.TexCoord0;
	return OutData;
}

/*
	Tinnitus shader
*/

static const float4 FilterKernel[8] =
{
	-1.0, 1.0, 0, 0.125,
	0.0, 1.0, 0, 0.125,
	1.0, 1.0, 0, 0.125,
	-1.0, 0.0, 0, 0.125,
	1.0, 0.0, 0, 0.125,
	-1.0, -1.0, 0, 0.125,
	0.0, -1.0, 0, 0.125,
	1.0, -1.0, 0, 0.125,
};

float4 Tinnitus_PS(VS2PS_Quad Input) : COLOR
{
	float4 Blur = 0.0;

	for(int i = 0; i < 8; i++)
	{
		Blur += FilterKernel[i].w * tex2D(PostProductionR3X0_Sampler_0_Bilinear, Input.TexCoord0.xy + 0.02 * FilterKernel[i].xy);
	}

	float4 Color = tex2D(PostProductionR3X0_Sampler_0_Bilinear, Input.TexCoord0);
	float2 UV = Input.TexCoord0;

	// Parabolic function for x opacity to darken the edges, exponential function for opacity to darken the lower part of the screen
	float Darkness = max(4.0 * UV.x * UV.x - 4.0 * UV.x + 1.0, saturate((pow(2.5, UV.y) - UV.y / 2.0 - 1.0)));

	// Weight the blurred version more heavily as you go lower on the screen
	float4 FinalColor = lerp(Color, Blur, saturate(2.0 * (pow(4.0, UV.y) - UV.y - 1.0)));

	// Darken the left, right, and bottom edges of the final product
	FinalColor = lerp(FinalColor, float4(0.0, 0.0, 0.0, 1.0), Darkness);
	return float4(FinalColor.rgb, saturate(2.0 * _BackBufferLerpBias));
}

technique Tinnitus
{
	pass p0
	{
		ZEnable = TRUE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		StencilEnable = FALSE;

		VertexShader = compile vs_3_0 Tinnitus_VS();
		PixelShader = compile ps_3_0 Tinnitus_PS();

	}
}

/*
	Glow shaders
*/

float4 Glow_PS(VS2PS_Quad Input) : COLOR
{
	return tex2D(PostProductionR3X0_Sampler_0_Bilinear, Input.TexCoord0);
}

float4 Glow_Material_PS(VS2PS_Quad Input) : COLOR
{
	float4 Diffuse = tex2D(PostProductionR3X0_Sampler_0_Bilinear, Input.TexCoord0);
	// return (1.0 - Diffuse.a);
	return float4(Diffuse.rgb * (1.0 - Diffuse.a), 1.0);
}

technique Glow
{
	pass p0
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCCOLOR;
		DestBlend = ONE;

		VertexShader = compile vs_3_0 Basic_VS();
		PixelShader = compile ps_3_0 Glow_PS();
	}
}

technique GlowMaterial
{
	pass p0
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCCOLOR;
		DestBlend = ONE;

		StencilEnable = TRUE;
		StencilFunc = NOTEQUAL;
		StencilRef = 0x80;
		StencilMask = 0xFF;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;

		VertexShader = compile vs_3_0 Basic_VS();
		PixelShader = compile ps_3_0 Glow_Material_PS();
	}
}

/*
	Fog Shader
*/

float4 Fog_PS(VS2PS_Quad Input) : COLOR
{
	float3 WorldPosition = tex2D(PostProductionR3X0_Sampler_0_Bilinear, Input.TexCoord0).xyz;
	float Coord = saturate((WorldPosition.z - _FogStartAndEnd.r) /_FogStartAndEnd.g); // fogColorAndViewDistance.a);
	return saturate(float4(_FogColor.rgb,Coord));
	// float2 FogCoords = float2(Coord, 0.0);
	return tex2D(PostProductionR3X0_Sampler_1_Bilinear, float2(Coord, 0.0)) * _FogColor.rgbb;
}

technique Fog
{
	pass p0
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		// SrcBlend = SRCCOLOR;
		// DestBlend = ZERO;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		// StencilEnable = FALSE;

		StencilEnable = TRUE;
		StencilFunc = NOTEQUAL;
		StencilRef = 0x00;
		StencilMask = 0xFF;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;

		VertexShader = compile vs_3_0 Basic_VS();
		PixelShader = compile ps_3_0 Fog_PS();
	}
}
