#line 2 "QuadGeom.fx"

/*
	Assumption: Shader that generates the fullscreen quad for FSQuaddrawer and postproduction
	Reason: Vertex position normalized from [-1.0, 1.0] to [0.0, 1.0], flipping the Y axis
*/

/*
	[Textures and samplers]
*/

uniform texture Texture_0 : TEXLAYER0;

sampler QuadGeom_Sampler = sampler_state
{
	Texture = (Texture_0);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
};

struct APP2VS
{
    float2 Pos : POSITION;
};

struct VS2PS
{
    float4 Pos : POSITION;
    float2 TexCoord : TEXCOORD0;
};

VS2PS Quad_VS(APP2VS Input)
{
	VS2PS Output;
	Output.Pos = float4(Input.Pos.xy, 0.0f, 1.0f);
	Output.TexCoord = Input.Pos.xy * float2(0.5, -0.5) + float2(0.5, 0.5);
	return Output;
}

float4 Quad_PS(VS2PS Input) : COLOR
{
	return tex2D(QuadGeom_Sampler, Input.TexCoord);
}

technique TexturedQuad
<
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_POSITION, 0,
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		// App alpha/depth settings
		CullMode = NONE;
		ZEnable = TRUE;
		ZFunc = ALWAYS;
		ZWriteEnable = TRUE;
		
		// SET UP STENCIL TO ONLY WRITE WHERE STENCIL IS SET TO ZERO
		StencilEnable = TRUE;
		StencilFunc = EQUAL;
		StencilPass = ZERO;
		StencilRef = 0;

		// StencilEnable = FALSE;
		// StencilFunc = ALWAYS;
		// StencilPass = ZERO;
		// StencilRef = 0;

		VertexShader = compile vs_3_0 Quad_VS();
		PixelShader = compile ps_3_0 Quad_PS();
	}
}
