float4x4 _WorldViewProjection : WorldViewProjection;
bool _ZBuffer : ZBUFFER;

// string Category = "Effects\\Lighting";

struct APP2VS
{
	float4 Pos : POSITION;
	float4 Diffuse : COLOR;
};

struct VS2PS
{
	float4 Pos : POSITION;
	float4 Diffuse : COLOR;
};

struct PS2FB
{
	float4 Col : COLOR;
};

VS2PS Shader_VS(APP2VS Input, uniform float4x4 WorldViewProj)
{
	VS2PS Output;
	Output.Pos = mul(float4(Input.Pos.xyz, 1.0f), WorldViewProj);
	Output.Diffuse.xyz = Input.Diffuse.xyz;
	Output.Diffuse.w = 0.8f; // Input.Diffuse.w;
 	return Output;
}

PS2FB Shader_PS(VS2PS Input)
{
	PS2FB Output;
	Output.Col = Input.Diffuse;
	return Output;
}

technique t0
<
	int DetailLevel = DLHigh+DLNormal+DLLow+DLAbysmal;
	int Compatibility = CMPR300+CMPNV2X;
	int Declaration[] =
	{
		// StreamNo, DataType, Usage, UsageIdx
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
		{ 0, D3DDECLTYPE_D3DCOLOR, D3DDECLUSAGE_COLOR, 0 },
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		/*
			CullMode = NONE;
			AlphaBlendEnable = TRUE;
			// FillMode = WIREFRAME;
			// ColorWriteEnable = 0;
			ZWriteEnable = 0;
			ZEnable = TRUE;
		*/

		CullMode = NONE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		// FillMode = WIREFRAME;
		// ColorWriteEnable = 0;
		DepthBias=-0.00001;
		ZWriteEnable = 1;
		// float zbuffe = TRUE;
		ZEnable = FALSE; // TRUE;
		ShadeMode = FLAT;
		ZFunc = LESSEQUAL;

		VertexShader = compile vs_3_0 Shader_VS(_WorldViewProjection);
		PixelShader = compile ps_3_0 Shader_PS();
	}
}

//$ TODO: Temporary fix for enabling z-buffer writing for collision meshes.
technique t0_usezbuffer
<
	int DetailLevel = DLHigh+DLNormal+DLLow+DLAbysmal;
	int Compatibility = CMPR300+CMPNV2X;
	int Declaration[] =
	{
		// StreamNo, DataType, Usage, UsageIdx
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
		{ 0, D3DDECLTYPE_D3DCOLOR, D3DDECLUSAGE_COLOR, 0 },
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		CullMode = NONE;
		AlphaBlendEnable = FALSE;
 		ZWriteEnable = 1;
 		ZEnable = TRUE;

		VertexShader = compile vs_3_0 Shader_VS(_WorldViewProjection);
		PixelShader = compile ps_3_0 Shader_PS();
	}
}
