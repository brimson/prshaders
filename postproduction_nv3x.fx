
/*
	Description: Controls the following post-production shaders
		1. Tinnitus
		2. Glow
		3. Thermal vision
		4. Wave distortion
		5. Flashbang
	Note: Some TV shaders write to the same render target as optic shaders
*/

#include "shaders/Common.fx"

texture Texture0 : TEXLAYER0;
texture Texture1 : TEXLAYER1;
texture Texture2 : TEXLAYER2;
texture Texture3 : TEXLAYER3;

/*
	Unused?
	texture Texture4 : TEXLAYER4;
	texture Texture5 : TEXLAYER5;
	texture Texture6 : TEXLAYER6;
*/

float _BackBufferLerpBias : BACKBUFFERLERPBIAS;
float2 _SampleOffset : SAMPLEOFFSET;
float2 _FogStartAndEnd : FOGSTARTANDEND;
float3 _FogColor : FOGCOLOR;
float _GlowStrength : GLOWSTRENGTH;

float _NightFilter_Noise_Strength : NIGHTFILTER_NOISE_STRENGTH;
float _NightFilter_Noise : NIGHTFILTER_NOISE;
float _NightFilter_Blur : NIGHTFILTER_BLUR;
float _NightFilter_Mono : NIGHTFILTER_MONO;

float2 _Displacement : DISPLACEMENT; // Random <x, y> jitter

// one pixel in screen texture units
float _DeltaU : DELTAU;
float _DeltaV : DELTAV;

sampler Sampler0 = sampler_state
{
	Texture = (Texture0);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MinFilter = POINT;
	MagFilter = POINT;
};

sampler Sampler1 = sampler_state
{
	Texture = (Texture1);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MinFilter = POINT;
	MagFilter = POINT;
};

sampler Sampler0Bilinear = sampler_state
{
	Texture = (Texture0);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
};

sampler Sampler1Bilinear = sampler_state
{
	Texture = (Texture1);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
};

sampler Sampler2Bilinear = sampler_state
{
	Texture = (Texture2);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
};

sampler Sampler3Bilinear = sampler_state
{
	Texture = (Texture3);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
};

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

struct VS2PS_Quad2
{
	float4 Pos : POSITION;
	float2 TexCoord0 : TEXCOORD0;
	float2 TexCoord1 : TEXCOORD1;
};

struct PS2FB_Quad2
{
	float2 Pos : VPOS;
	float2 TexCoord0 : TEXCOORD0;
	float2 TexCoord1 : TEXCOORD1;
};

VS2PS_Quad PostProcess_VS(APP2VS_Quad Input)
{
	VS2PS_Quad OutData;
	OutData.Pos = float4(Input.Pos.xy, 0.0, 1.0);
	OutData.TexCoord0 = Input.TexCoord0;
	return OutData;
}

/*
	TODO:
	1. Rewrite Tinnitus to be less predictable, through noise and such (may not be cache friendly, but we have lots of GPU headroom)
	2. Write helper file since "PostProduction_nv3x.fx" and "PostProduction_r3x0.fx" share the same tinnitus techniques
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
		Blur += FilterKernel[i].w * tex2D(Sampler0Bilinear, Input.TexCoord0.xy + 0.02 * FilterKernel[i].xy);
	}

	float4 Color = tex2D(Sampler0Bilinear, Input.TexCoord0);
	float2 UV = Input.TexCoord0;

	// Parabolic function for x opacity to darken the edges, exponential function for opacity to darken the lower part of the screen
	float darkness = max(4.0 * UV.x * UV.x - 4.0 * UV.x + 1.0, saturate((pow(2.5, UV.y) - UV.y / 2.0 - 1.0)));

	// Weight the blurred version more heavily as you go lower on the screen
	float4 FinalColor = lerp(Color, Blur, saturate(2.0 * (pow(4.0, UV.y) - UV.y - 1.0)));

	// Darken the left, right, and bottom edges of the final product
	FinalColor = lerp(FinalColor, float4(0.0, 0.0, 0.0, 1.0), darkness);
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

		VertexShader = compile vs_3_0 PostProcess_VS();
		PixelShader = compile ps_3_0 Tinnitus_PS();
	}
}

/*
	Glow shaders
*/

float4 Glow_PS(VS2PS_Quad Input) : COLOR
{
	return tex2D(Sampler0Bilinear, Input.TexCoord0);
}

float4 GlowMaterial_PS(VS2PS_Quad Input) : COLOR
{
	float4 Diffuse = tex2D(Sampler0Bilinear, Input.TexCoord0);
	// return (1.0 - Diffuse.a);
	// temporary test, should be removed
	return _GlowStrength * /* Diffuse + */ float4(Diffuse.rgb * (1.0 - Diffuse.a), 1.0);
}

technique Glow
{
	pass p0
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCCOLOR;
		DestBlend = ONE;

		VertexShader = compile vs_3_0 PostProcess_VS();
		PixelShader = compile ps_3_0 Glow_PS();
	}
}

technique GlowMaterial
{
	pass p0
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		SrcBlend = SRCCOLOR;
		DestBlend = ONE;

		StencilEnable = TRUE;
		StencilFunc = NOTEQUAL;
		StencilRef = 0x80;
		StencilMask = 0xFF;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;

		VertexShader = compile vs_3_0 PostProcess_VS();
		PixelShader = compile ps_3_0 GlowMaterial_PS();
	}
}

/*
	float4 Fog_PS(VS2PS_Quad Input) : COLOR
	{
		float3 WorldPosition = tex2D(Sampler0, Input.TexCoord0).xyz;
		float Coord = saturate((WorldPosition.z - _FogStartAndEnd.r) / _FogStartAndEnd.g); // fogColorandomViewDistance.a);
		return saturate(float4(_FogColor.rgb, Coord));
		// float2 FogCoords = float2(Coord, 0.0);
		return tex2D(Sampler1, float2(Coord, 0.0)) * _FogColor.rgbb;
	}

	technique Fog
	{
		pass p0
		{
			ZEnable = FALSE;
			AlphaBlendEnable = TRUE;
			//SrcBlend = SRCCOLOR;
			//DestBlend = ZERO;
			SrcBlend = SRCALPHA;
			DestBlend = INVSRCALPHA;
			//StencilEnable = FALSE;

			StencilEnable = TRUE;
			StencilFunc = NOTEQUAL;
			StencilRef = 0x00;
			StencilMask = 0xFF;
			StencilFail = KEEP;
			StencilZFail = KEEP;
			StencilPass = KEEP;

			VertexShader = compile vs_3_0 PostProcess_VS();
			PixelShader = compile ps_3_0 Fog_PS();
		}
	}
*/

/*
	Thermal vision shaders
*/

float _FracTime : FRACTIME;
float _FracTime256 : FRACTIME256;
float _SinFracTime : FRACSINE;

float _Interference : INTERFERENCE; // = 0.050000 || -0.015;
float _DistortionRoll : DISTORTIONROLL; // = 0.100000;
float _DistortionScale : DISTORTIONSCALE; // = 0.500000 || 0.2;
float _DistortionFreq : DISTORTIONFREQ; //= 0.500000;
float _Granularity : TVGRANULARITY; // = 3.5;
float _TVAmbient : TVAMBIENT; // = 0.15
float3 _TVColor : TVCOLOR;

VS2PS_Quad2 ThermalVision_VS(APP2VS_Quad Input)
{
	VS2PS_Quad2 Output;
	Input.Pos.xy = sign(Input.Pos.xy);
	Output.Pos = float4(Input.Pos.xy, 0.0, 1.0);
	Output.TexCoord0 = Input.Pos.xy * _Granularity + _Displacement; // Outputs random jitter movement at [-x, x] range
	Output.TexCoord1 = Input.TexCoord0;
	return Output;
}

// Thermal vision with Gaussian noise
// The larger Random()'s result deviates, the lesser the noise would be, whether negative or positive

float4 ThermalVision_PS(PS2FB_Quad2 Input) : COLOR
{
	float4 OutColor = 0.0;

	// Calculate screen-space properties
	float2 PixelSize = float2(ddx(Input.TexCoord1.x), ddy(Input.TexCoord1.y));
	float2 ScreenSize = int2(1.0 / PixelSize); // Round to int

	// Sample pixelated version of buffer by picking every 2nd texel
	float2 PixelDensity = ScreenSize / 2.0;
	float4 PixelatedImage = tex2D(Sampler0Bilinear, round(Input.TexCoord1 * PixelDensity) / PixelDensity);

	// Use the jitter attribute interpolated by the pixel shader to generate noise
	float GaussianNoise = Gaussian(Random(Input.TexCoord0.xy), 0.5 * 0.5);

	if (_Interference <= 1.0)
	{
		float RandomNoise = GaussianNoise - 0.2;
		if (_Interference < 0) // Thermal imaging
		{
			// Terrain max light mod should be 0.608
			// OutData.Col0.r = lerp(lerp(lerp(0.43, 0.17, image.g), lerp(0.75f, 0.50f, image.b), image.b),image.r,image.r); // M
			OutColor.r = lerp(0.43, 0.0, PixelatedImage.g) + PixelatedImage.r;

			// Add -_Interference
			OutColor.r -= _Interference * RandomNoise;
			OutColor = float4(_TVColor * OutColor.rrr, PixelatedImage.a);
		}
		else // Normal thermal vision effect
		{
			// Compute brighness of the image (we use the maximum scalar in the vector)
			PixelatedImage = Max3(PixelatedImage);

			// Blend the luminance version of the buffer with the generated noise
			OutColor = _Interference * RandomNoise + PixelatedImage * (1.0 - _TVAmbient) + _TVAmbient;

			// Multiplied the blended image by the desired thermal vision color vector
			OutColor *= float4(_TVColor, 1.0); // <Red, Green, Blue, 1.0>
		}
	}
	else // Skip the processing if interference not within conditional range
	{
		OutColor = tex2D(Sampler0Bilinear, Input.TexCoord1);
	}

	return OutColor;
}

//	TV Effect with usage of gradient texture (what objects use this?)

float4 ThermalVisionGradient_PS(PS2FB_Quad2 Input) : COLOR
{
	float4 OutColor = 0.0;

	// Calculate screen-space properties
	float2 PixelSize = float2(ddx(Input.TexCoord1.x), ddy(Input.TexCoord1.y));
	float2 ScreenSize = int2(1.0 / PixelSize); // Round to int

	// Use the jitter attribute interpolated by the pixel shader to generate noise
	float GaussianNoise = Gaussian(Random(Input.TexCoord0.xy), 0.5 * 0.5);

	if (_Interference >= 0.0 && _Interference <= 1.0)
	{
		float2 ImageCoord = Input.TexCoord1;

		float Random = GaussianNoise - 0.2;
		float Noise = GaussianNoise - 0.5;

		float Distort = frac(Input.TexCoord0.y * _DistortionFreq + _DistortionRoll * _SinFracTime);
		Distort *= (1.0 - Distort);
		Distort /= 1.0 + _DistortionScale * abs(Input.TexCoord0.y);

		ImageCoord.x += _DistortionScale * Noise * Distort;

		// Sample pixelated version of buffer by picking every 2nd texel
		float2 PixelDensity = ScreenSize / 2.0;
		float4 PixelatedImage = tex2D(Sampler0Bilinear, round(ImageCoord * PixelDensity) / PixelDensity);
		PixelatedImage = Max3(PixelatedImage);

		float4 Intensity = (_Interference * Random + PixelatedImage * (1.0 - _TVAmbient) + _TVAmbient);

		float4 GradientColor = tex2D(Sampler3Bilinear, float2(Intensity.r, 0.0f));
		OutColor = float4(GradientColor.rgb, Intensity.a);
	}
	else // Skip the processing if interference not within conditional range
	{
		OutColor = tex2D(Sampler0Bilinear, Input.TexCoord1);
	}

	return OutColor;
	// return float4(0.0, 1.0, 0.0, 1.0);
}

technique TVEffect //  BF2 calls Thermal Vision "TV", but we renamed the TV methods to "ThermalVision" to avoid confusion.
{
	pass p0
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;

		VertexShader = compile vs_3_0 ThermalVision_VS();
		PixelShader = compile ps_3_0 ThermalVision_PS();
	}
}

technique TVEffect_Gradient_Tex // BF2 calls Thermal Vision "TV", but we renamed the TV methods to "ThermalVision" to avoid confusion.
{
	pass p0
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;

		VertexShader = compile vs_3_0 ThermalVision_VS();
		PixelShader = compile ps_3_0 ThermalVisionGradient_PS();
	}
}

/*
	Wave Distortion Shader
*/

VS2PS_Quad2 WaveDistortion_VS(APP2VS_Quad Input)
{
	VS2PS_Quad2 Output;
	Output.Pos = float4(Input.Pos.xy, 0.0, 1.0);
	Output.TexCoord0 = Input.TexCoord0;
	Output.TexCoord1 = Input.Pos.xy;
	return Output;
}

float4 WaveDistortion_PS(VS2PS_Quad2 Input) : COLOR
{
	return 0.0;
}

technique WaveDistortion
{
	pass p0
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		AlphaTestEnable = FALSE;
		StencilEnable = FALSE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

		// PixelShaderConstant2[0] = <_FracTime>;
		// PixelShaderConstant1[1] = <_DeltaU>;
		// PixelShaderConstant1[2] = <_DeltaV>;
		// TextureTransform[2] = <UpScaleTexBy8>;

		VertexShader = compile vs_3_0 WaveDistortion_VS();
		PixelShader = compile ps_3_0 WaveDistortion_PS();
	}
}

/*
	Flashbang frame-blending shader

	Assumption:
	1. sampler 0, 1, 2, and 3 are based on history textures
	2. The shader spatially blends these history buffers in the pixel shader, and temporally blend through blend operation

	TODO: See what the core issue is with this.
	Theory is that the texture getting temporally blended or sampled has been rewritten before the blendop
*/

float4 Flashbang_PS(VS2PS_Quad Input) : COLOR
{
	float4 Sample0 = tex2D(Sampler0Bilinear, Input.TexCoord0);
	float4 Sample1 = tex2D(Sampler1Bilinear, Input.TexCoord0);
	float4 Sample2 = tex2D(Sampler2Bilinear, Input.TexCoord0);
	float4 Sample3 = tex2D(Sampler3Bilinear, Input.TexCoord0);

	float4 Accumulation = Sample0 * 0.5;
	Accumulation += Sample1 * 0.25;
	Accumulation += Sample2 * 0.15;
	Accumulation += Sample3 * 0.10;
	return float4(Accumulation.rgb, _BackBufferLerpBias);
}

technique Flashbang
{
	pass P0
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;

		BlendOp = ADD;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		StencilEnable = FALSE;

		VertexShader = compile vs_3_0 PostProcess_VS();
		PixelShader = compile ps_3_0 Flashbang_PS();
	}
}
