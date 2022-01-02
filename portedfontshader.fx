
float4 alpha : BLENDALPHA;

texture texture0: TEXLAYER0;

sampler sampler0_clamp = sampler_state
{
	Texture = (texture0);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
};

sampler sampler0_wrap = sampler_state
{
	Texture = (texture0);
	AddressU = WRAP;
	AddressV = WRAP;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
};

struct APP2VS
{
    float4	HPos : POSITION;
    float3	Col : COLOR;
    float2	TexCoord0 : TEXCOORD0;
};

struct VS2PS
{
    float4	HPos : POSITION;
    float3	Col : COLOR;
    float2	Tex0 : TEXCOORD0;
};

VS2PS HPosVS(APP2VS indata)
{
	VS2PS outdata;
	
	outdata.HPos = indata.HPos;
	outdata.Col = indata.Col;
 	outdata.Tex0 = indata.TexCoord0;
 	
	return outdata;
}

float4 HPosPS(VS2PS indata) : COLOR
{
    float4 outCol = tex2D(sampler0_clamp, indata.Tex0);
    float4 noAlpha = float4(1,1,1,0);
    outCol = dot(outCol, noAlpha);
    outCol.rgb = outCol.rgb * indata.Col;
    return outCol;
}

float4 Overlay_HPosPS(VS2PS Input) : COLOR
{
	float4 InputTexture0 = tex2D(sampler0_wrap, Input.Tex0);
	return InputTexture0 * float4(1.0, 1.0, 1.0, alpha.a);
}

technique Text_States <bool Restore = true;> {
	pass BeginStates {
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		// SrcBlend = INVSRCCOLOR;
		// DestBlend = SRCCOLOR;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
	}
	
	pass EndStates {
	}
}

technique Text <
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		0, D3DDECLTYPE_FLOAT4, D3DDECLUSAGE_POSITION, 0,
		0, D3DDECLTYPE_D3DCOLOR, D3DDECLUSAGE_COLOR, 0,
		0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0,
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{		
		VertexShader = compile vs_2_a HPosVS();
		PixelShader = compile ps_2_a HPosPS(); 
	}
}

technique Overlay_States <bool Restore = true;> {
	pass BeginStates {
		CullMode = NONE;
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
	}
	
	pass EndStates {
	}
}

technique Overlay <
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		0, D3DDECLTYPE_FLOAT4, D3DDECLUSAGE_POSITION, 0,
		0, D3DDECLTYPE_D3DCOLOR, D3DDECLUSAGE_COLOR, 0,
		0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0,
		DECLARATION_END	// End macro
	};
	int TechniqueStates = D3DXFX_DONOTSAVESHADERSTATE;
>
{
	pass p0
	{
		/*
			TextureFactor = (alpha);
			Texture[0] = (texture0);
			AddressU[0] = WRAP;
			AddressV[0] = WRAP;
			MipFilter[0] = LINEAR;
			MinFilter[0] = LINEAR;
			MagFilter[0] = LINEAR;
			
			ColorOp[0] = SELECTARG1;
			ColorArg1[0] = TEXTURE;
			AlphaOp[0] = MODULATE;
			AlphaArg1[0] = TEXTURE;
			AlphaArg2[0] = TFACTOR;
			ColorOp[1] = DISABLE;
			AlphaOp[1] = DISABLE;
		*/

		VertexShader = compile vs_2_a HPosVS();
		// PixelShader = NULL;
		PixelShader = compile ps_2_a Overlay_HPosPS();
	}
}
