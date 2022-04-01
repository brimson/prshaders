texture texture0 : TEXLAYER0;
texture texture1 : TEXLAYER1;
//texture texture2 : TEXLAYER2;
//texture texture3 : TEXLAYER3;

sampler sampler0point = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler1point = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
//sampler sampler2 = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
//sampler sampler3 = sampler_state { Texture = (texture3); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler0bilin = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler0bilinMirror = sampler_state { Texture = (texture0); AddressU = MIRROR; AddressV = MIRROR; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler0aniso = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = ANISOTROPIC; MagFilter = ANISOTROPIC; MaxAnisotropy = 8; };

dword dwStencilRef : STENCILREF = 0;
dword dwStencilPass : STENCILPASS = 1; // KEEP

float4x4 convertPosTo8BitMat : CONVERTPOSTO8BITMAT;

float4x4 customMtx : CUSTOMMTX;

float4 scaleDown2x2SampleOffsets[4] : SCALEDOWN2X2SAMPLEOFFSETS;
float4 scaleDown4x4SampleOffsets[16] : SCALEDOWN4X4SAMPLEOFFSETS;
float4 scaleDown4x4LinearSampleOffsets[4] : SCALEDOWN4X4LINEARSAMPLEOFFSETS;
float4 gaussianBlur5x5CheapSampleOffsets[13] : GAUSSIANBLUR5X5CHEAPSAMPLEOFFSETS;
float gaussianBlur5x5CheapSampleWeights[13] : GAUSSIANBLUR5X5CHEAPSAMPLEWEIGHTS;
float4 gaussianBlur15x15HorizontalSampleOffsets[15] : GAUSSIANBLUR15X15HORIZONTALSAMPLEOFFSETS;
float gaussianBlur15x15HorizontalSampleWeights[15] : GAUSSIANBLUR15X15HORIZONTALSAMPLEWEIGHTS;
float4 gaussianBlur15x15VerticalSampleOffsets[15] : GAUSSIANBLUR15X15VERTICALSAMPLEOFFSETS;
float gaussianBlur15x15VerticalSampleWeights[15] : GAUSSIANBLUR15X15VERTICALSAMPLEWEIGHTS;
float4 growablePoisson13SampleOffsets[12] : GROWABLEPOISSON13SAMPLEOFFSETS;

float glowHorizOffsets[5] : GLOWHORIZOFFSETS;
float glowHorizWeights[5] : GLOWHORIZWEIGHTS;
float glowVertOffsets[5] : GLOWVERTOFFSETS;
float glowVertWeights[5] : GLOWVERTWEIGHTS;

float bloomHorizOffsets[5] : BLOOMHORIZOFFSETS;
float bloomVertOffsets[5] : BLOOMVERTOFFSETS;

float highPassGate : HIGHPASSGATE; // 3d optics blur; xxxx.yyyy; x - aspect ratio(H/V), y - blur amount(0=no blur, 0.9=full blur)

float blurStrength : BLURSTRENGTH; // 3d optics blur; xxxx.yyyy; x - inner radius, y - outer radius

float2 texelSize : TEXELSIZE;

struct APP2VS_blit
{
    float2	Pos : POSITION0;
    float2	TexCoord0 : TEXCOORD0;
};

struct VS2PS_4TapFilter
{
    float4	Pos 		 : POSITION;
    float2	FilterCoords[4] : TEXCOORD0;
};

struct VS2PS_5SampleFilter
{
    float4	Pos 		    : POSITION;
    float2	TexCoord0		: TEXCOORD0;
    float4	FilterCoords[2] : TEXCOORD1;
};

struct VS2PS_blit_
{
    float4	Pos 		: POSITION;
    float2	TexCoord0	: TEXCOORD0;
};


struct VS2PS_blit
{
    float4	Pos 		: POSITION;
    float2	TexCoord0	: TEXCOORD0;
};

struct VS2PS_5SampleFilter14
{
    float4	Pos 		    : POSITION;
    float2	FilterCoords[5] : TEXCOORD0;
};

VS2PS_blit vsDx9_blit(APP2VS_blit indata)
{
	VS2PS_blit outdata;
 	outdata.Pos = float4(indata.Pos.x, indata.Pos.y, 0, 1);
 	outdata.TexCoord0 = indata.TexCoord0;
	return outdata;
}

VS2PS_blit vsDx9_blitCustom(APP2VS_blit indata)
{
	VS2PS_blit outdata;
 	outdata.Pos = mul(float4(indata.Pos.x, indata.Pos.y, 0, 1), customMtx);
 	outdata.TexCoord0 = indata.TexCoord0;
	return outdata;
}

struct VS2PS_tr_blit
{
    float4	Pos 		: POSITION;
    float2	TexCoord0	: TEXCOORD0;
};

VS2PS_tr_blit vsDx9_tr_blit(APP2VS_blit indata) // TODO: implement support for old shader versions. TODO: try to use fakeHDRWeights as variables
{
	VS2PS_tr_blit outdata;
 	outdata.Pos = float4(indata.Pos.x, indata.Pos.y, 0, 1);
 	outdata.TexCoord0 = indata.TexCoord0;
	return outdata;
}

const float2 Offsets[5] =
{
	float2(0.0, 0.0),
	float2(0.0, 1.4584295167832),
	float2(0.0, 3.4039848066734835),
	float2(0.0, 5.351805780136256),
	float2(0.0, 7.302940716034593)
};

const float Weights[5] =
{
	0.1329807601338109,
	0.2322770777384485,
	0.13532693306504567,
	0.05115603510197893,
	0.012539291705835646
};

float4 LinearGaussianBlur(sampler2D Source, float2 TexCoord, bool IsHorizontal)
{
	float4 OutputColor = 0.0;
	float4 TotalWeights = 0.0;
	float2 PixelSize = 0.0;
	PixelSize.x = 1.0 / int(1.0 / abs(ddx(TexCoord.x)));
	PixelSize.y = 1.0 / int(1.0 / abs(ddy(TexCoord.y)));

	OutputColor += tex2D(Source, TexCoord + (Offsets[0].xy * PixelSize)) * Weights[0];
	TotalWeights += Weights[0];

	for(int i = 1; i < 5; i++)
	{
		float2 Offset = (IsHorizontal) ? Offsets[i].yx : Offsets[i].xy;
		OutputColor += tex2D(Source, TexCoord + (Offset * PixelSize)) * Weights[i];
		OutputColor += tex2D(Source, TexCoord - (Offset * PixelSize)) * Weights[i];
		TotalWeights += (Weights[i] * 2.0);
	}

	return OutputColor / TotalWeights;
}

float4 psDx9_tr_opticsBlurH(VS2PS_tr_blit indata) : COLOR
{
    return LinearGaussianBlur(sampler0bilinMirror, indata.TexCoord0, true);
}

float4 psDx9_tr_opticsBlurV(VS2PS_tr_blit indata) : COLOR
{
    return LinearGaussianBlur(sampler0bilinMirror, indata.TexCoord0, false);
}

float4 psDx9_tr_opticsNoBlurCircle(VS2PS_tr_blit indata) : COLOR
{
	float2 ScreenSize = 0.0;
	ScreenSize.x = int(1.0 / abs(ddx(indata.TexCoord0.x)));
	ScreenSize.y = int(1.0 / abs(ddy(indata.TexCoord0.y)));
	float AspectRatio = ScreenSize.x / ScreenSize.y;

	float BlurAmountMod = frac(highPassGate) / 0.9; // used for the fade-in effect
	float Radius1 = blurStrength / 1000.0; // 0.2 by default (floor() isn't used for perfomance reasons)
	float Radius2 = frac(blurStrength); // 0.25 by default
	float Distance = length((indata.TexCoord0 - 0.5) * float2(AspectRatio, 1.0)); // get distance from the center of the screen

	float BlurAmount = saturate((Distance - Radius1) / (Radius2 - Radius1)) * BlurAmountMod; 
	float4 InputColor = tex2D(sampler0aniso, indata.TexCoord0);
	return float4(InputColor.rgb, BlurAmount); // Alpha (.a) is the mask to be composited in the pixel shader's blend operation
}

float4 psDx9_tr_PassThrough_point(VS2PS_tr_blit indata) : COLOR
{
	return tex2D(sampler0point, indata.TexCoord0);
}

float4 psDx9_tr_PassThrough_aniso(VS2PS_tr_blit indata) : COLOR
{
	return tex2D(sampler0aniso, indata.TexCoord0);
}

float4 ps_dummy() : COLOR
{
    return 0;
}

VS2PS_blit_ vsDx9_blitMagnified(APP2VS_blit indata)
{
	VS2PS_blit_ outdata;
 	outdata.Pos = float4(indata.Pos.x*1.1, indata.Pos.y*1.1, 0, 1);
 	outdata.TexCoord0 = indata.TexCoord0;
	return outdata;
}

VS2PS_4TapFilter vsDx9_4TapFilter(APP2VS_blit indata, uniform float4 offsets[4])
{
	VS2PS_4TapFilter outdata;
 	outdata.Pos = float4(indata.Pos.x, indata.Pos.y, 0, 1);

 	for (int i = 0; i < 4; ++i)
 	{
 		outdata.FilterCoords[i] = indata.TexCoord0 + offsets[i].xy;
 	}

	return outdata;
}

VS2PS_5SampleFilter vsDx9_5SampleFilter(APP2VS_blit indata, uniform float offsets[5], uniform bool horizontal)
{
	VS2PS_5SampleFilter outdata;
 	outdata.Pos = float4(indata.Pos.x, indata.Pos.y, 0, 1);

	if(horizontal)
	{
		outdata.TexCoord0 = indata.TexCoord0 + float2(offsets[4],0);
	}
	else
	{
		outdata.TexCoord0 = indata.TexCoord0 + float2(0,offsets[4]);
	}

	for(int i=0; i<2; ++i)
	{
		if(horizontal)
		{
			outdata.FilterCoords[i].xy = indata.TexCoord0.xy + float2(offsets[i*2],0);
			outdata.FilterCoords[i].zw = indata.TexCoord0.xy + float2(offsets[i*2+1],0);
		}
		else
		{
			outdata.FilterCoords[i].xy = indata.TexCoord0.xy + float2(0,offsets[i*2]);
			outdata.FilterCoords[i].zw = indata.TexCoord0.xy + float2(0,offsets[i*2+1]);
		}
	}

	return outdata;
}

VS2PS_5SampleFilter14 vsDx9_5SampleFilter14(APP2VS_blit indata, uniform float offsets[5], uniform bool horizontal)
{
	VS2PS_5SampleFilter14 outdata;
 	outdata.Pos = float4(indata.Pos.x, indata.Pos.y, 0, 1);

	for(int i=0; i<5; ++i)
	{
		if(horizontal)
		{
			outdata.FilterCoords[i] = indata.TexCoord0 + float2(offsets[i],0);
		}
		else
		{
			outdata.FilterCoords[i] = indata.TexCoord0 + float2(0,offsets[i]);
		}
	}

	return outdata;
}

struct VS2PS_Down4x4Filter14
{
    float4	Pos 		: POSITION;
    float2	TexCoord0	: TEXCOORD0;
    float2	TexCoord1	: TEXCOORD1;
    float2	TexCoord2	: TEXCOORD2;
    float2	TexCoord3	: TEXCOORD3;
};

VS2PS_Down4x4Filter14 vsDx9_Down4x4Filter14(APP2VS_blit indata)
{
	VS2PS_Down4x4Filter14 outdata;
 	outdata.Pos = float4(indata.Pos.x, indata.Pos.y, 0, 1);
 	outdata.TexCoord0 = indata.TexCoord0 + scaleDown4x4SampleOffsets[0].xy;
 	outdata.TexCoord1 = indata.TexCoord0 + scaleDown4x4SampleOffsets[4].xy*2;
 	outdata.TexCoord2 = indata.TexCoord0 + scaleDown4x4SampleOffsets[8].xy*2;
 	outdata.TexCoord3 = indata.TexCoord0 + scaleDown4x4SampleOffsets[12].xy*2;
	return outdata;
}

float4 psDx9_FSBMPassThrough(VS2PS_blit indata) : COLOR
{
	return tex2D(sampler0point, indata.TexCoord0);
}

float4 psDx9_FSBMPassThroughBilinear(VS2PS_blit indata) : COLOR
{
	return tex2D(sampler0bilin, indata.TexCoord0);
}

float4 psDx9_FSBMPassThroughSaturateAlpha(VS2PS_blit indata) : COLOR
{
	float4 color =  tex2D(sampler0point, indata.TexCoord0);
	color.a = 1.f;
	return color;
}


float4 psDx9_FSBMCopyOtherRGBToAlpha(VS2PS_blit indata) : COLOR
{
	float4 color = tex2D(sampler0point, indata.TexCoord0);

	float3 avg = 1.0/3;

	color.a = dot(avg, color.rgb);

	return color;
}


float4 psDx9_FSBMConvertPosTo8Bit(VS2PS_blit indata) : COLOR
{
	float4 viewPos = tex2D(sampler0point, indata.TexCoord0);
	viewPos /= 50;
	viewPos = viewPos * 0.5 + 0.5;
	return viewPos;
}

float4 psDx9_FSBMConvertNormalTo8Bit(VS2PS_blit indata) : COLOR
{
	return normalize(tex2D(sampler0point, indata.TexCoord0)) / 2 + 0.5;
	//return tex2D(sampler0point, indata.TexCoord0).a;
}

float4 psDx9_FSBMConvertShadowMapFrontTo8Bit(VS2PS_blit indata) : COLOR
{
	float4 depths = tex2D(sampler0point, indata.TexCoord0);
	return depths;
}

float4 psDx9_FSBMConvertShadowMapBackTo8Bit(VS2PS_blit indata) : COLOR
{
	return -tex2D(sampler0point, indata.TexCoord0);
}

float4 psDx9_FSBMScaleUp4x4LinearFilter(VS2PS_blit indata) : COLOR
{
	return tex2D(sampler0bilin, indata.TexCoord0);
}

float4 psDx9_FSBMScaleDown2x2Filter(VS2PS_blit indata) : COLOR
{
	float4 accum;
	accum = tex2D(sampler0point, indata.TexCoord0 + scaleDown2x2SampleOffsets[0].xy);
	accum += tex2D(sampler0point, indata.TexCoord0 + scaleDown2x2SampleOffsets[1].xy);
	accum += tex2D(sampler0point, indata.TexCoord0 + scaleDown2x2SampleOffsets[2].xy);
	accum += tex2D(sampler0point, indata.TexCoord0 + scaleDown2x2SampleOffsets[3].xy);

	return accum * 0.25; // div 4
}

float4 psDx9_FSBMScaleDown4x4Filter(VS2PS_blit indata) : COLOR
{
	float4 accum = 0;

	for(int tap = 0; tap < 16; ++tap)
		accum += tex2D(sampler0point, indata.TexCoord0 + scaleDown4x4SampleOffsets[tap].xy);

	return accum * 0.0625; // div 16
}

float4 psDx9_FSBMScaleDown4x4Filter14(VS2PS_Down4x4Filter14 indata) : COLOR
{
	float4 accum;
	accum = tex2D(sampler0bilin, indata.TexCoord0);
	accum += tex2D(sampler0bilin, indata.TexCoord1);
	accum += tex2D(sampler0bilin, indata.TexCoord2);
	accum += tex2D(sampler0bilin, indata.TexCoord3);

	return accum * 0.25; // div 4
}

float4 psDx9_FSBMScaleDown4x4LinearFilter(VS2PS_4TapFilter indata) : COLOR
{
	float4 accum = float4(0,0,0,0);
	accum = tex2D(sampler0bilin, indata.FilterCoords[0].xy);
	accum += tex2D(sampler0bilin, indata.FilterCoords[1].xy);
	accum += tex2D(sampler0bilin, indata.FilterCoords[2].xy);
	accum += tex2D(sampler0bilin, indata.FilterCoords[3].xy);

	return accum/4;
}

float4 psDx9_FSBMGaussianBlur5x5CheapFilter(VS2PS_blit indata) : COLOR
{
	float4 accum = 0;

	for(int tap = 0; tap < 13; ++tap)
		accum += tex2D(sampler0point, indata.TexCoord0 + gaussianBlur5x5CheapSampleOffsets[tap].xy) * gaussianBlur5x5CheapSampleWeights[tap];

	return accum;
}

float4 psDx9_FSBMGaussianBlur5x5CheapFilterBlend(VS2PS_blit indata) : COLOR
{
	float4 accum = 0;

	for(int tap = 0; tap < 13; ++tap)
		accum += tex2D(sampler0point, indata.TexCoord0 + gaussianBlur5x5CheapSampleOffsets[tap].xy) * gaussianBlur5x5CheapSampleWeights[tap];

	accum.a = blurStrength;
	return accum;
}

float4 psDx9_FSBMGaussianBlur15x15HorizontalFilter(VS2PS_blit indata) : COLOR
{
	float4 accum = 0;

	for(int tap = 0; tap < 15; ++tap)
		accum += tex2D(sampler0point, indata.TexCoord0 + gaussianBlur15x15HorizontalSampleOffsets[tap].xy) * gaussianBlur15x15HorizontalSampleWeights[tap];

	return accum;
}

float4 psDx9_FSBMGaussianBlur15x15VerticalFilter(VS2PS_blit indata) : COLOR
{
	float4 accum = 0;

	for(int tap = 0; tap < 15; ++tap)
		accum += tex2D(sampler0point, indata.TexCoord0 + gaussianBlur15x15VerticalSampleOffsets[tap].xy) * gaussianBlur15x15VerticalSampleWeights[tap];

	return accum;
}

float4 psDx9_FSBMGaussianBlur15x15HorizontalFilter2(VS2PS_blit indata) : COLOR
{
	float4 accum = 0;

	for(int tap = 0; tap < 15; ++tap)
		accum += tex2D(sampler0point, indata.TexCoord0 + 2*gaussianBlur15x15HorizontalSampleOffsets[tap].xy) * gaussianBlur15x15HorizontalSampleWeights[tap];

	return accum;
}

float4 psDx9_FSBMGaussianBlur15x15VerticalFilter2(VS2PS_blit indata) : COLOR
{
	float4 accum = 0;

	for(int tap = 0; tap < 15; ++tap)
		accum += tex2D(sampler0point, indata.TexCoord0 + 2*gaussianBlur15x15VerticalSampleOffsets[tap].xy) * gaussianBlur15x15VerticalSampleWeights[tap];

	return accum;
}

float4 psDx9_FSBMGrowablePoisson13Filter(VS2PS_blit indata) : COLOR
{
	float4 accum = 0;
	float samples = 1;

	accum = tex2D(sampler0point, indata.TexCoord0);
	for(int tap = 0; tap < 11; ++tap)
	{
//		float4 v = tex2D(sampler0point, indata.TexCoord0 + growablePoisson13SampleOffsets[tap]*1);
		float4 v = tex2D(sampler0point, indata.TexCoord0 + growablePoisson13SampleOffsets[tap].xy*0.1*accum.a);
		if(v.a > 0)
		{
			accum.rgb += v;
			samples += 1;
		}
	}

//return tex2D(sampler0point, indata.TexCoord0);
	return accum / samples;
}

float4 psDx9_FSBMGrowablePoisson13AndDilationFilter(VS2PS_blit indata) : COLOR
{
	float4 center = tex2D(sampler0point, indata.TexCoord0);

	float4 accum = 0;
	if(center.a > 0)
	{
		accum.rgb = center;
		accum.a = 1;
	}

	for(int tap = 0; tap < 11; ++tap)
	{
		float scale = 3*(center.a);
		if(scale == 0)
			scale = 1.5;
		float4 v = tex2D(sampler0point, indata.TexCoord0 + growablePoisson13SampleOffsets[tap].xy*scale);
		if(v.a > 0)
		{
			accum.rgb += v;
			accum.a += 1;
		}
	}

//	if(center.a == 0)
//	{
//		accum.gb = center.gb;
//		accum.r / accum.a;
//		return accum;
//	}
//	else
		return accum / accum.a;
}

float4 psDx9_FSBMGlowFilter(VS2PS_5SampleFilter indata, uniform float weights[5], uniform bool horizontal) : COLOR
{
	float4 color = weights[0] * tex2D(sampler0bilin, indata.FilterCoords[0].xy);
	color += weights[1] * tex2D(sampler0bilin, indata.FilterCoords[0].zw);
	color += weights[2] * tex2D(sampler0bilin, indata.FilterCoords[1].xy);
	color += weights[3] * tex2D(sampler0bilin, indata.FilterCoords[1].zw);
	color += weights[4] * tex2D(sampler0bilin, indata.TexCoord0);

	return color;
}

float4 psDx9_FSBMGlowFilter14(VS2PS_5SampleFilter14 indata, uniform float weights[5]) : COLOR
{
	float4 color = weights[0] * tex2D(sampler0bilin, indata.FilterCoords[0].xy);
	color += weights[1] * tex2D(sampler0bilin, indata.FilterCoords[1].xy);
	color += weights[2] * tex2D(sampler0bilin, indata.FilterCoords[2].xy);
	color += weights[3] * tex2D(sampler0bilin, indata.FilterCoords[3].xy);
	color += weights[4] * tex2D(sampler0bilin, indata.FilterCoords[4].xy);

	return color;
}

float4 psDx9_FSBMHighPassFilter(VS2PS_blit indata) : COLOR
{
	float4 color = tex2D(sampler0point, indata.TexCoord0);

	color -= highPassGate;

	return max(color,0);
}

float4 psDx9_FSBMHighPassFilterFade(VS2PS_blit indata) : COLOR
{
	float4 color = tex2D(sampler0point, indata.TexCoord0);

	color.rgb = saturate(color.rgb - highPassGate);
	color.a = blurStrength;

	return color;
}

float4 psDx9_FSBMClear(VS2PS_blit_ indata) : COLOR
{
	return float4(0,0,0,0);
}

float4 psDx9_FSBMExtractGlowFilter(VS2PS_blit indata) : COLOR
{
	float4 color = tex2D(sampler0point, indata.TexCoord0);

	color.rgb = color.a;
	color.a = 1;

	return color;
}

float4 psDx9_FSBMExtractHDRFilterFade(VS2PS_blit indata) : COLOR
{
	float4 color = tex2D(sampler0point, indata.TexCoord0);

	color.rgb = saturate(color.a - highPassGate);
	color.a = blurStrength;

	return color;
}

float4 psDx9_FSBMLuminancePlusBrightPassFilter(VS2PS_blit indata) : COLOR
{
	float4 color = tex2D(sampler0point, indata.TexCoord0) * highPassGate;
//	float luminance = dot(color, float3(0.299f, 0.587f, 0.114f));
	return color;
}

float4 psDx9_FSBMBloomFilter(VS2PS_5SampleFilter indata, uniform bool is_blur) : COLOR
{
	float4 color = float4(0.f,0.f,0.f,0.f);

	if( is_blur )
	{
		color.a = blurStrength;
	}

	color.rgb += tex2D(sampler0bilin, indata.TexCoord0.xy);

	for(int i=0; i<2; ++i)
	{
		color.rgb += tex2D(sampler0bilin, indata.FilterCoords[i].xy);
		color.rgb += tex2D(sampler0bilin, indata.FilterCoords[i].zw);
	}

	color.rgb /= 5;
	return color;
}

float4 psDx9_FSBMBloomFilter14(VS2PS_5SampleFilter14 indata, uniform bool is_blur) : COLOR
{
	float4 color = float4(0.f,0.f,0.f,0.f);

	if( is_blur )
	{
		color.a = blurStrength;
	}

	for(int i=0; i<5; ++i)
	{
		color.rgb += tex2D(sampler0bilin, indata.FilterCoords[i]);
	}
	color.rgb /= 5;
	return color;
}

float4 psDx9_FSBMScaleUpBloomFilter(VS2PS_blit indata) : COLOR
{
	float offSet = 0.01;

	float4 close = tex2D(sampler0point, indata.TexCoord0);
/*
	close += tex2D(sampler0bilin, float2((indata.TexCoord0.x - offSet*4.5), indata.TexCoord0.y));
	close += tex2D(sampler0bilin, float2((indata.TexCoord0.x - offSet*3.5), indata.TexCoord0.y));
	close += tex2D(sampler0bilin, float2((indata.TexCoord0.x - offSet*2.5), indata.TexCoord0.y));
	close += tex2D(sampler0bilin, float2((indata.TexCoord0.x - offSet*1.5), indata.TexCoord0.y));
	close += tex2D(sampler0bilin, float2((indata.TexCoord0.x + offSet*1.5), indata.TexCoord0.y));
	close += tex2D(sampler0bilin, float2((indata.TexCoord0.x + offSet*2.5), indata.TexCoord0.y));
	close += tex2D(sampler0bilin, float2((indata.TexCoord0.x + offSet*3.5), indata.TexCoord0.y));
	close += tex2D(sampler0bilin, float2((indata.TexCoord0.x + offSet*4.5), indata.TexCoord0.y));

	close += tex2D(sampler0bilin, float2(indata.TexCoord0.x, indata.TexCoord0.y - offSet*4.5));
	close += tex2D(sampler0bilin, float2(indata.TexCoord0.x, indata.TexCoord0.y - offSet*3.5));
	close += tex2D(sampler0bilin, float2(indata.TexCoord0.x, indata.TexCoord0.y - offSet*2.5));
	close += tex2D(sampler0bilin, float2(indata.TexCoord0.x, indata.TexCoord0.y - offSet*1.5));
	close += tex2D(sampler0bilin, float2(indata.TexCoord0.x, indata.TexCoord0.y + offSet*1.5));
	close += tex2D(sampler0bilin, float2(indata.TexCoord0.x, indata.TexCoord0.y + offSet*2.5));
	close += tex2D(sampler0bilin, float2(indata.TexCoord0.x, indata.TexCoord0.y + offSet*3.5));
	//close += tex2D(sampler0bilin, float2(indata.TexCoord0.x, indata.TexCoord0.y + offSet*4.5));

	return close / 16;
*/
	return close;
}

float4 psDx9_FSBMBlur(VS2PS_blit indata) : COLOR
{
	return float4( tex2D(sampler0point, indata.TexCoord0).rgb, blurStrength );
}

//
//	Techniques
//

technique Blit
{
	pass FSBMPassThrough
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_FSBMPassThrough();
	}

	pass FSBMBlend
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

		VertexShader = compile vs_2_a vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_FSBMPassThrough();
	}

	pass FSBMConvertPosTo8Bit
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_FSBMConvertPosTo8Bit();
	}

	pass FSBMConvertNormalTo8Bit
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_FSBMConvertNormalTo8Bit();
	}

	pass FSBMConvertShadowMapFrontTo8Bit
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_FSBMConvertShadowMapFrontTo8Bit();
	}

	pass FSBMConvertShadowMapBackTo8Bit
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_FSBMConvertShadowMapBackTo8Bit();
	}

	pass FSBMScaleUp4x4LinearFilter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_FSBMScaleUp4x4LinearFilter();
	}

	pass FSBMScaleDown2x2Filter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_FSBMScaleDown2x2Filter();
	}

	pass FSBMScaleDown4x4Filter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_FSBMScaleDown4x4Filter();
	}

	pass FSBMScaleDown4x4LinearFilter // pass 9, tinnitus
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_4TapFilter(scaleDown4x4LinearSampleOffsets);//vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_FSBMScaleDown4x4LinearFilter();
	}

	pass FSBMGaussianBlur5x5CheapFilter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_FSBMGaussianBlur5x5CheapFilter();
	}

	pass FSBMGaussianBlur15x15HorizontalFilter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_FSBMGaussianBlur15x15HorizontalFilter(); // psDx9_FSBMGaussianBlur15x15HorizontalFilter2();
	}

	pass FSBMGaussianBlur15x15VerticalFilter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_FSBMGaussianBlur15x15VerticalFilter(); // psDx9_FSBMGaussianBlur15x15VerticalFilter2();
	}

	pass FSBMGrowablePoisson13Filter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_FSBMGrowablePoisson13Filter();
	}

	pass FSBMGrowablePoisson13AndDilationFilter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_FSBMGrowablePoisson13AndDilationFilter();
	}

	pass FSBMScaleUpBloomFilter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_FSBMScaleUpBloomFilter();
	}

	pass FSBMPassThroughSaturateAlpha
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_FSBMPassThroughSaturateAlpha();
	}

	pass FSBMCopyOtherRGBToAlpha
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		ColorWriteEnable = ALPHA;

		VertexShader = compile vs_2_a vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_FSBMCopyOtherRGBToAlpha();
	}

	// X-Pack additions
	pass FSBMPassThroughBilinear
	{
  		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_tr_blit();
		PixelShader = compile ps_2_a psDx9_tr_PassThrough_point();
	}

	pass FSBMPassThroughBilinearAdditive
	{
/* 		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE; */
		//VertexShader = compile vs_2_a vsDx9_blit();
		//PixelShader = compile ps_2_a psDx9_FSBMPassThroughBilinear();

		  /*ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;*/
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		SrcBlend = ZERO;
		DestBlend = ONE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_tr_blit();
		PixelShader = compile ps_2_a psDx9_tr_PassThrough_point();
	}

	pass FSMBlur
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMScaleUp4x4LinearFilterAdditive
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMGaussianBlur5x5CheapFilterBlend
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMGaussianBlur5x5CheapFilterAdditive
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMScaleUpBloomFilterAdditive
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMGlowHorizontalFilter // pass 25
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_3_0 vsDx9_tr_blit();
		PixelShader = compile ps_3_0 psDx9_tr_opticsBlurH();
	}

	pass FSBMGlowVerticalFilter // pass 26
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_3_0 vsDx9_tr_blit();
		PixelShader = compile ps_3_0 psDx9_tr_opticsBlurV();
	}

	pass FSBMGlowVerticalFilterAdditive
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMHighPassFilter
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMHighPassFilterFade  // pass 29
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_tr_blit();
		PixelShader = compile ps_2_a psDx9_tr_PassThrough_point();
	}

	pass FSBMExtractGlowFilter
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMExtractHDRFilterFade
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMClearAlpha
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		ColorWriteEnable = ALPHA;

		VertexShader = compile vs_2_a vsDx9_blitMagnified(); // is this needed? -mosq
		PixelShader = compile ps_2_a psDx9_FSBMClear();
	}

	pass FSBMAdditive
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMAdditiveBilinear  // pass 34
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		BlendOp = ADD;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		VertexShader = compile vs_3_0 vsDx9_tr_blit();
		PixelShader = compile ps_3_0 psDx9_tr_opticsNoBlurCircle();
	}

	pass FSBMBloomHorizFilter   // pass 35
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_tr_blit();
		PixelShader = compile ps_2_a psDx9_tr_PassThrough_point();
	}

	pass FSBMBloomHorizFilterAdditive
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMBloomVertFilter   // pass 37
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_tr_blit();
		PixelShader = compile ps_2_a psDx9_tr_PassThrough_point();
	}

	pass FSBMBloomVertFilterAdditive
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMBloomVertFilterBlur
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMBloomVertFilterAdditiveBlur
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMLuminancePlusBrightPassFilter
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMScaleDown4x4LinearFilterHorizontal // pass 42
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_tr_blit();
		PixelShader = compile ps_2_a psDx9_tr_PassThrough_aniso();
	}

	pass FSBMScaleDown4x4LinearFilterVertical // pass 43
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_tr_blit();
		PixelShader = compile ps_2_a psDx9_tr_PassThrough_aniso();
	}

	pass FSBMClear
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_2_a vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_FSBMClear();
	}

	pass FSBMBlendCustom
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

		VertexShader = compile vs_2_a vsDx9_blitCustom();
		PixelShader = compile ps_2_a psDx9_FSBMPassThrough();
	}

}

float4 psDx9_StencilGather(VS2PS_blit indata) : COLOR
{
	return dwStencilRef / 255.0;
}

float4 psDx9_StencilMap(VS2PS_blit indata) : COLOR
{
	float4 stencil = tex2D(sampler0point, indata.TexCoord0);
	return tex1D(sampler1point, stencil.x / 255.0);
}

technique StencilPasses
{
	pass StencilGather
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		AlphaTestEnable = FALSE;

		StencilEnable = TRUE;
		StencilRef = (dwStencilRef);
		StencilFunc = EQUAL;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;

		VertexShader = compile vs_2_a vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_StencilGather();
	}

	pass StencilMap
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		AlphaTestEnable = FALSE;
		StencilEnable = FALSE;

		VertexShader = compile vs_2_a vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_StencilMap();
	}
}

technique ResetStencilCuller
{
	pass NV4X
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = ALWAYS;

		AlphaBlendEnable = FALSE;
		AlphaTestEnable = FALSE;
		ColorWriteEnable = 0;
		ColorWriteEnable1 = 0;
		ColorWriteEnable2 = 0;
		ColorWriteEnable3 = 0;

		StencilEnable = TRUE;
		StencilRef = (dwStencilRef);
		StencilMask = 0xFF;
		StencilWriteMask = 0xFF;
		StencilFunc = EQUAL;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = (dwStencilPass);
		TwoSidedStencilMode = FALSE;

		VertexShader = compile vs_2_a vsDx9_blit();
		PixelShader = compile ps_2_a ps_dummy();
	}
}
