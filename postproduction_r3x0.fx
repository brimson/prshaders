texture texture0 : TEXLAYER0;
texture texture1 : TEXLAYER1;
texture texture2 : TEXLAYER2;
texture texture3 : TEXLAYER3;
texture texture4 : TEXLAYER4;
texture texture5 : TEXLAYER5;
texture texture6 : TEXLAYER6;

float backbufferLerpbias : BACKBUFFERLERPBIAS;
float2 sampleoffset : SAMPLEOFFSET;
float2 fogStartAndEnd : FOGSTARTANDEND;
float3 fogColor : FOGCOLOR;

sampler sampler0 = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler1 = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler2 = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler3 = sampler_state { Texture = (texture3); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler4 = sampler_state { Texture = (texture4); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler5 = sampler_state { Texture = (texture5); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler6 = sampler_state { Texture = (texture6); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };

sampler sampler0bilin = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler1bilin = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler2bilin = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler3bilin = sampler_state { Texture = (texture3); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler4bilin = sampler_state { Texture = (texture4); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler5bilin = sampler_state { Texture = (texture5); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };

float NPixels : NPIXLES = 1.0;
float2 ScreenSize : VIEWPORTSIZE = {800,600};
float Glowness : GLOWNESS = 3.0;
float Cutoff : cutoff = 0.8;


struct APP2VS_Quad
{
    float2	Pos : POSITION0;
    float2	TexCoord0 : TEXCOORD0;
};

struct VS2PS_Quad
{
    float4	Pos 		: POSITION;
    float2	TexCoord0	: TEXCOORD0;
};

struct VS2PS_Quad2
{
    float4	Pos 		: POSITION;
    float2	TexCoord0	: TEXCOORD0;
    float2	TexCoord1	: TEXCOORD1;
};

struct VS2PS_Tinnitus
{
    float2 Position : VPOS;
    float2 TexCoord0 : TEXCOORD0;
    float2 TexCoord1 : TEXCOORD1;
};

struct PS2FB_Combine
{
    float4 Col0 : COLOR0;
};

VS2PS_Quad vsDx9_OneTexcoord(APP2VS_Quad indata)
{
	VS2PS_Quad outdata;	
 	outdata.Pos = float4(indata.Pos.x, indata.Pos.y, 0, 1);
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
		
		VertexShader = compile vs_3_0 vsDx9_Tinnitus();
		PixelShader = compile ps_3_0 psDx9_Tinnitus();
		
	}
}

float4 psDx9_Glow(VS2PS_Quad indata) : COLOR
{
	return tex2D(sampler0bilin, indata.TexCoord0);
}

float4 psDx9_GlowMaterial(VS2PS_Quad indata) : COLOR
{
	float4 diffuse =  tex2D(sampler0bilin, indata.TexCoord0);
	//return (1-diffuse.a);
	return float4(diffuse.rgb*(1-diffuse.a),1);
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
	float uvCoord =  saturate((wPos.zzzz-fogStartAndEnd.r)/fogStartAndEnd.g); // fogColorAndViewDistance.a);
	return saturate(float4(fogColor.rgb,uvCoord));
	// float2 fogcoords = float2(uvCoord, 0.0);
	return tex2D(sampler1, float2(uvCoord, 0.0))*fogColor.rgbb;
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
		
		VertexShader = compile vs_2_a vsDx9_OneTexcoord();
		PixelShader = compile ps_2_a psDx9_Fog();
	}
}
