
/*
	NOTE: TV shaders write to the same render target as optic shaders
*/

#include "shaders/Common.fx"

texture texture0 : TEXLAYER0;
texture texture1 : TEXLAYER1;
texture texture2 : TEXLAYER2;
texture texture3 : TEXLAYER3;

// Unused?
texture texture4 : TEXLAYER4;
texture texture5 : TEXLAYER5;
texture texture6 : TEXLAYER6;

float backbufferLerpbias : BACKBUFFERLERPBIAS;
float2 sampleoffset : SAMPLEOFFSET;
float2 fogStartAndEnd : FOGSTARTANDEND;
float3 fogColor : FOGCOLOR;
float glowStrength : GLOWSTRENGTH;

float nightFilter_noise_strength : NIGHTFILTER_NOISE_STRENGTH;
float nightFilter_noise : NIGHTFILTER_NOISE;
float nightFilter_blur : NIGHTFILTER_BLUR;
float nightFilter_mono : NIGHTFILTER_MONO;

float2 displacement : DISPLACEMENT;

float PI = 3.1415926535897932384626433832795;

// one pixel in screen texture units
float deltaU : DELTAU;
float deltaV : DELTAV;

sampler sampler0 = sampler_state
{
	Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT;
};

sampler sampler1 = sampler_state
{
	Texture = (texture1);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MinFilter = POINT;
	MagFilter = POINT;
};

sampler sampler0bilin = sampler_state
{
	Texture = (texture0);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
};

sampler sampler0bilin_SRGB = sampler_state
{
	Texture = (texture0);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	SRGBTexture = TRUE;
};

sampler sampler1bilin = sampler_state
{
	Texture = (texture1);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
};

sampler sampler2bilin = sampler_state
{
	Texture = (texture2);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
};

sampler sampler3bilin = sampler_state
{
	Texture = (texture3);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
};

sampler sampler3bilin_SRGB = sampler_state
{
	Texture = (texture3);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	SRGBTexture = TRUE;
};

float NPixels : NPIXLES = 1.0;
float2 ScreenSize : VIEWPORTSIZE = { 800, 600 };
float Glowness : GLOWNESS = 3.0;
float Cutoff : cutoff = 0.8;


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

struct VS2PS_Quad3
{
	float4 Pos : POSITION;
	float2 TexCoord0 : TEXCOORD0;
	float2 TexCoord1 : TEXCOORD1;
	float2 TexCoord2 : TEXCOORD2;
};

struct VS2PS_Quad4
{
	float4 Pos : POSITION;
	float2 TexCoord0 : TEXCOORD0;
	float2 TexCoord1 : TEXCOORD1;
	float2 TexCoord2 : TEXCOORD2;
	float2 TexCoord3 : TEXCOORD3;
};

struct VS2PS_Quad5
{
	float4 Pos : POSITION;
	float2 Color0 : COLOR0;
	float2 TexCoord0 : TEXCOORD0;
	float2 TexCoord1 : TEXCOORD1;
};

struct PS2FB_TV
{
	float2 Pos : VPOS;
	float2 TexCoord0 : TEXCOORD0;
	float2 TexCoord1 : TEXCOORD1;
	float2 TexCoord2 : TEXCOORD2;
};

struct PS2FB_Combine
{
	float4 Col0 : COLOR0;
};

VS2PS_Quad vsDx9_OneTexcoord(APP2VS_Quad indata)
{
	VS2PS_Quad outdata;
	outdata.Pos = float4(indata.Pos.xy, 0.0, 1.0);
	outdata.TexCoord0 = indata.TexCoord0;
	return outdata;
}

VS2PS_Quad2 vsDx9_Tinnitus(APP2VS_Quad indata)
{
	VS2PS_Quad2 outdata;
	outdata.Pos = float4(indata.Pos.x, indata.Pos.y, 0, 1);
	outdata.TexCoord0 = indata.TexCoord0;
	outdata.TexCoord1 = float2(indata.TexCoord0.x - sampleoffset.x, indata.TexCoord0.y - sampleoffset.y);
	return outdata;
}

// Rotated noise convolution tinnitus
// Vogel disk sampling: http://blog.marmakoide.org/?p=1
// Rotated noise sampling: http://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare (slide 123)

static const float Pi = 3.1415926535897932384626433832795;

float2 VogelSample(int Index, int SamplesCount)
{
	const float GoldenAngle = Pi * (3.0 - sqrt(5.0));
	float Radius = sqrt(float(Index) + 0.5) * rsqrt(float(SamplesCount));
	float Theta = float(Index) * GoldenAngle;

	float2 SinCosTheta = 0.0;
	sincos(Theta, SinCosTheta.x, SinCosTheta.y);
	return Radius * SinCosTheta;
}

float GradientNoise(float2 Position)
{
	const float3 Numbers = float3(0.06711056f, 0.00583715f, 52.9829189f);
	return frac(Numbers.z * frac(dot(Position.xy, Numbers.xy)));
}

PS2FB_Combine psDx9_Tinnitus(VS2PS_Tinnitus indata)
{
	PS2FB_Combine outdata;
	float2 PixelSize = float2(ddx(indata.TexCoord0.x), ddy(indata.TexCoord0.y));

	float4 blur = 0.0;
	float Samples = 4.0;
	float Radius = 32.0;

	float2 Rotation = 0.0;
	sincos(2.0 * Pi * GradientNoise(indata.Position.xy), Rotation.y, Rotation.x);

	float2x2 RotationMatrix = float2x2(Rotation.x, Rotation.y,
									  -Rotation.y, Rotation.x);

	for(int i = 0; i < Samples; i++)
	{
		float2 SampleOffset = mul(VogelSample(i, Samples) * Radius, RotationMatrix);
		blur += tex2D(sampler0bilin, indata.TexCoord0 + (SampleOffset * PixelSize));
	}

	blur = blur / Samples;

	float4 color = tex2D(sampler0bilin, indata.TexCoord0);
	float2 tcxy = indata.TexCoord0.xy;

	//parabolic function for x opacity to darken the edges, exponential function for yopacity to darken the lower part of the screen
	float darkness = max(4.0 * tcxy.x * tcxy.x - 4.0 * tcxy.x + 1.0, saturate((pow(2.5, tcxy.y) - tcxy.y / 2.0 - 1.0)));

	//weight the blurred version more heavily as you go lower on the screen
	float4 finalcolor = lerp(color, blur, saturate(2.0 * (pow(4.0, tcxy.y) - tcxy.y - 1.0)));

	//darken the left, right, and bottom edges of the final product
	finalcolor = lerp(finalcolor, float4(0, 0, 0, 1), darkness);
	float4 outcolor = float4(finalcolor.rgb,saturate(2*backbufferLerpbias));
	outdata.Col0 = outcolor;
	return outdata;
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

		VertexShader = compile vs_2_a vsDx9_Tinnitus();
		PixelShader = compile ps_2_a psDx9_Tinnitus();
	}
}

float4 psDx9_Glow(VS2PS_Quad indata) : COLOR
{
	return tex2D(sampler0bilin, indata.TexCoord0);
}

float4 psDx9_GlowMaterial(VS2PS_Quad indata) : COLOR
{
	float4 diffuse =  tex2D(sampler0bilin, indata.TexCoord0);
	// return (1.0 - diffuse.a);
	// temporary test, should be removed
	return glowStrength * /* diffuse + */ float4(diffuse.rgb*(1-diffuse.a),1);
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

		VertexShader = compile vs_2_a vsDx9_OneTexcoord();
		PixelShader = compile ps_2_a psDx9_GlowMaterial();
	}
}

technique Glow
{
	pass p0
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCCOLOR;
		DestBlend = ONE;

		VertexShader = compile vs_2_a vsDx9_OneTexcoord();
		PixelShader = compile ps_2_a psDx9_Glow();
	}
}

float4 psDx9_Fog(VS2PS_Quad indata) : COLOR
{
	float3 wPos = tex2D(sampler0, indata.TexCoord0);
	float uvCoord =  saturate((wPos.zzzz-fogStartAndEnd.r)/fogStartAndEnd.g);//fogColorandomViewDistance.a);
	return saturate(float4(fogColor.rgb,uvCoord));
	// float2 fogcoords = float2(uvCoord, 0.0);
	return tex2D(sampler1, float2(uvCoord, 0.0))*fogColor.rgbb;
}
/*
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

			VertexShader = compile vs_2_a vsDx9_OneTexcoord();
			PixelShader = compile ps_2_a psDx9_Fog();
		}
	}
*/

// TVEffect specific...

float time_0_X : FRACTIME;
float time_0_X_256 : FRACTIME256;
float sin_time_0_X : FRACSINE;

float interference : INTERFERENCE; // = 0.050000 || -0.015;
float distortionRoll : DISTORTIONROLL; // = 0.100000;
float distortionScale : DISTORTIONSCALE; // = 0.500000 || 0.2;
float distortionFreq : DISTORTIONFREQ; //= 0.500000;
float granularity : TVGRANULARITY; // = 3.5;
float tvAmbient : TVAMBIENT; // = 0.15

float3 tvColor : TVCOLOR;

VS2PS_Quad3 vs_TVEffect(APP2VS_Quad indata)
{
	VS2PS_Quad3 output;
	indata.Pos.xy = sign(indata.Pos.xy);
	output.Pos = float4(indata.Pos.xy, 0.0, 1.0);
	output.TexCoord0 = indata.Pos.xy * granularity + displacement;
	output.TexCoord1 = indata.Pos.xy * 0.25 + float2(-0.35, 0.25) * sin_time_0_X;
	output.TexCoord2 = indata.TexCoord0;
	return output;
}

float gaussian(float z, float o)
{
	return (1.0 / (o * sqrt(2.0 * 3.1415))) * exp(-((z * z) / (2.0 * (o * o))));
}

PS2FB_Combine ps_TVEffect30(PS2FB_TV indata)
{
	PS2FB_Combine outdata;
	outdata.Col0 = 0.0;

	float2 img = indata.TexCoord2;
	float4 image = tex2D(sampler0bilin_SRGB, img);

	float seed = dot(indata.TexCoord2, float2(12.9898, 78.233));
	float gaussiannoise = frac(sin(seed) * 43758.5453 + (time_0_X * 4.0));
	gaussiannoise = gaussian(gaussiannoise, 0.5 * 0.5);

	if (interference <= 1)
	{
		float2 pos = indata.TexCoord0;
		float random = gaussiannoise - 0.2;
		if (interference < 0) // thermal imaging
		{
			// outdata.Col0.r = lerp(lerp(lerp(0.43, 0.17, image.g), lerp(0.75f, 0.50f, image.b), image.b),image.r,image.r); // M

			// terrain max light mod should be 0.608
			outdata.Col0.r = lerp(0.43, 0.0, image.g) + image.r;

			// add -interference
			outdata.Col0.r -= interference * random;
			outdata.Col0 = float4(tvColor * outdata.Col0.rrr, image.a);
		}
		else // normal tv effect
		{
			float noise = gaussiannoise - 0.5;

			float distort = frac(pos.y * distortionFreq + distortionRoll * sin_time_0_X);
			distort *= (1.0 - distort);
			distort /= 1.0 + distortionScale * abs(pos.y);

			img.x += distortionScale * noise * distort;
			image = Max3(image);
			outdata.Col0 = float4(tvColor, 1.0) * (interference * random + image * (1.0 - tvAmbient) + tvAmbient);
		}
	}
	else
	{
		outdata.Col0 = image;
	}

	return outdata;
}

//	TV Effect with usage of gradient texture

PS2FB_Combine ps_TVEffect_Gradient_Tex(PS2FB_TV indata)
{
	PS2FB_Combine outdata;

	outdata.Col0 = 0.0;

	float seed = dot(indata.TexCoord2, float2(12.9898, 78.233));
	float gaussiannoise = frac(sin(seed) * 43758.5453 + (time_0_X * 4.0));
	gaussiannoise = gaussian(gaussiannoise, 0.5 * 0.5);

	if (interference >= 0 && interference <= 1)
	{
		float2 pos = indata.TexCoord0;
		float2 img = indata.TexCoord2;

		float random = gaussiannoise - 0.2;
		float noise = gaussiannoise - 0.5;

		float distort = frac(pos.y * distortionFreq + distortionRoll * sin_time_0_X);
		distort *= (1.0 - distort);
		distort /= 1.0 + distortionScale * abs(pos.y);

		img.x += distortionScale * noise * distort;
		float4 image = Max3(tex2D(sampler0bilin_SRGB, img));
		float4 intensity = (interference * random + image * (1.0 - tvAmbient) + tvAmbient);

		float4 gradient_col = tex2D(sampler3bilin, float2(intensity.r, 0.0f));
		outdata.Col0 = float4(gradient_col.rgb, intensity.a);
	}
	else
	{
		outdata.Col0 = tex2D(sampler0bilin_SRGB, indata.TexCoord2);
	}

	return outdata;
}

technique TVEffect
{
	pass p0
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		SRGBWriteEnable = TRUE;

		VertexShader = compile vs_3_0 vs_TVEffect();
		PixelShader = compile ps_3_0 ps_TVEffect30();
	}
}

technique TVEffect_Gradient_Tex
{
	pass p0
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		SRGBWriteEnable = TRUE;

		VertexShader = compile vs_3_0 vs_TVEffect();
		PixelShader = compile ps_3_0 ps_TVEffect_Gradient_Tex();
	}
}

// Wave Distortion

VS2PS_Quad2 vs_WaveDistortion(APP2VS_Quad indata)
{
	VS2PS_Quad2 output;
	output.Pos = float4(indata.Pos.xy, 0.0, 1.0);
	output.TexCoord0 = indata.TexCoord0;
	output.TexCoord1 = indata.Pos.xy;
	return output;
}

PS2FB_Combine ps_WaveDistortion(VS2PS_Quad2 indata)
{
	PS2FB_Combine outdata;
	outdata.Col0 = 0.0;
	return outdata;
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

		// PixelShaderConstant2[0] = <time_0_X>;
		// PixelShaderConstant1[1] = <deltaU>;
		// PixelShaderConstant1[2] = <deltaV>;
		// TextureTransform[2] = <UpScaleTexBy8>;

		VertexShader = compile vs_2_a vs_WaveDistortion();
		PixelShader = compile ps_2_a ps_WaveDistortion();
	}
}

VS2PS_Quad2 vsDx9_Flashbang(APP2VS_Quad indata)
{
	VS2PS_Quad2 outdata;
	outdata.Pos = float4(indata.Pos.x, indata.Pos.y, 0, 1);
	outdata.TexCoord0 = indata.TexCoord0;
	outdata.TexCoord1 = indata.TexCoord0;
	return outdata;
}

PS2FB_Combine psDx9_Flashbang(VS2PS_Quad2 indata)
{
	PS2FB_Combine outdata;
	float4 sample0 = tex2D(sampler0bilin, indata.TexCoord0);
	float4 sample1 = tex2D(sampler1bilin, indata.TexCoord0);
	float4 sample2 = tex2D(sampler2bilin, indata.TexCoord0);
	float4 sample3 = tex2D(sampler3bilin, indata.TexCoord0);

	float4 acc = sample0 * 0.5;
	acc += sample1 * 0.25;
	acc += sample2 * 0.15;
	acc += sample3 * 0.10;

	outdata.Col0 = acc;
	outdata.Col0.a = backbufferLerpbias;
	return outdata;
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

		VertexShader = compile vs_2_a vsDx9_Flashbang();
		PixelShader = compile ps_2_a psDx9_Flashbang();
	}
}
