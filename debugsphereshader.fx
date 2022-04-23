float4x4 _WorldViewProjection : WorldViewProjection;
float4x4 _World : World;

string Category = "Effects\\Lighting";

float4 _LightDir = { 1.0f, 0.0f, 0.0f, 1.0f }; // light direction
float4 _LightDiffuse = { 1.0f, 1.0f, 1.0f, 1.0f }; // light diffuse
float4 _MaterialAmbient : MATERIALAMBIENT = { 0.5f, 0.5f, 0.5f, 1.0f };
float4 _MaterialDiffuse : MATERIALDIFFUSE = { 1.0f, 1.0f, 1.0f, 1.0f };

texture Base_Tex: TEXLAYER0
<
	string File = "aniso2.dds";
	string TextureType = "2D";
>;

sampler2D Sample_Base = sampler_state
{
	Texture = <Base_Tex>;
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
};

struct APP2VS
{
	float4 Pos : POSITION;
	float3 Normal : NORMAL;
	float2 TexCoord0 : TEXCOORD0;
};

struct VS2PS
{
	float4 Pos : POSITION;
	float4 Diffuse : COLOR;
	float2 Tex0 : TEXCOORD0;
};

struct PS2FB
{
	float4 Col : COLOR;
};

float3 Diffuse(float3 Normal, uniform float4 LightDir)
{
	float CosTheta;

	// N.L Clamped
	CosTheta = max(0.0f, dot(Normal, LightDir.xyz));

	// propogate float result to vector
	return (CosTheta);
}

VS2PS VS
(
	APP2VS Input,
	uniform float4x4 WorldViewProj,
	uniform float4 MaterialAmbient,
	uniform float4 MaterialDiffuse,
	uniform float4 LightDir
)
{
	VS2PS OutData;

 	float3 Pos;
 	Pos = mul(Input.Pos, _World);
	OutData.Pos = mul(float4(Pos.xyz, 1.0f), WorldViewProj);

	// Lighting. Shade (Ambient + etc.)
	OutData.Diffuse.xyz = MaterialAmbient.xyz + Diffuse(Input.Normal, LightDir) * MaterialDiffuse.xyz;
	OutData.Diffuse.w = 1.0f;
 	OutData.Tex0 = Input.TexCoord0;
	return OutData;
}

PS2FB PS(VS2PS Input, uniform sampler2D ColorMap)
{
	PS2FB OutData;
	float4 Base = tex2D(ColorMap, Input.Tex0);
	OutData.Col = Input.Diffuse * Base;
	return OutData;
}

PS2FB Marked_PS(VS2PS Input, uniform sampler2D ColorMap)
{
	PS2FB OutData;
	float4 Base = tex2D(ColorMap, Input.Tex0);
	OutData.Col = (Input.Diffuse * Base) + float4(1.0f, 0.0f, 0.0f, 0.0f);
	return OutData;
}


technique t0_States <bool Restore = false;>
{
	pass BeginStates
	{
		CullMode = NONE;
	}

	pass EndStates
	{
		CullMode = CCW;
	}
}

technique t0
<
	int Declaration[] =
	{
		// StreamNo, DataType, Usage, UsageIdx
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
		{ 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0 },
		DECLARATION_END	// End macro
	};

>
{
	pass p0
	{
		VertexShader = compile vs_3_0 VS(_WorldViewProjection,_MaterialAmbient,_MaterialDiffuse,_LightDir);
		PixelShader = compile ps_3_0 PS(Sample_Base);
	}
}



technique marked
<
	int DetailLevel = DLHigh+DLNormal+DLLow+DLAbysmal;
	int Compatibility = CMPR300+CMPNV2X;
	int Declaration[] =
	{
		// StreamNo, DataType, Usage, UsageIdx
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
		{ 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0 },
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		CullMode = NONE;
		AlphaBlendEnable = FALSE;

		VertexShader = compile vs_3_0 VS(_WorldViewProjection,_MaterialAmbient,_MaterialDiffuse,_LightDir);
		PixelShader = compile ps_3_0 Marked_PS(Sample_Base);
	}
}

VS2PS Light_Source_VS(APP2VS Input, uniform float4x4 WorldViewProj, uniform float4 MaterialDiffuse )
{
	VS2PS OutData;

 	float4 Pos;
 	Pos.xyz = mul(Input.Pos, _World);
 	Pos.w = 1.0;
	OutData.Pos = mul(Pos, WorldViewProj);

	// Lighting. Shade (Ambient + etc.)
	OutData.Diffuse.rgb = MaterialDiffuse.xyz;
	OutData.Diffuse.a = MaterialDiffuse.w;
	OutData.Tex0 = 0.0;
	return OutData;
}

float4 Light_Source_PS(VS2PS Input) : COLOR
{
	return Input.Diffuse;
}

technique lightsource
<
	int Declaration[] =
	{
		// StreamNo, DataType, Usage, UsageIdx
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		CullMode = NONE;
		ColorWriteEnable = 0;
		AlphaBlendEnable = FALSE;

		ZFunc = LESSEQUAL;
		ZWriteEnable = TRUE;

		VertexShader = compile vs_3_0 Light_Source_VS(_WorldViewProjection, _MaterialDiffuse);
		PixelShader = compile ps_3_0 Light_Source_PS();
	}
	pass p1
	{
		ColorWriteEnable = Red|Blue|Green|Alpha;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

		ZFunc = EQUAL;
		ZWriteEnable = FALSE;

		VertexShader = compile vs_3_0 Light_Source_VS(_WorldViewProjection, _MaterialDiffuse);
		PixelShader = compile ps_3_0 Light_Source_PS();
	}
}

technique editor
<
	int Declaration[] =
	{
		// StreamNo, DataType, Usage, UsageIdx
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		CullMode = NONE;
		ColorWriteEnable = 0;
		AlphaBlendEnable = FALSE;

		ZFunc = LESSEQUAL;
		ZWriteEnable = TRUE;

		VertexShader = compile vs_3_0 Light_Source_VS(_WorldViewProjection, _MaterialDiffuse);
		PixelShader = compile ps_3_0 Light_Source_PS();
	}

	pass p1
	{
		ColorWriteEnable = Red|Blue|Green|Alpha;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

		ZFunc = EQUAL;
		ZWriteEnable = FALSE;

		VertexShader = compile vs_3_0 Light_Source_VS(_WorldViewProjection, _MaterialDiffuse);
		PixelShader = compile ps_3_0 Light_Source_PS();
	}
}

technique EditorDebug
{
	pass p0
	{
		CullMode = NONE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		ZWriteEnable = 1;
		ZEnable = TRUE;
		ShadeMode = FLAT;
		ZFunc = LESSEQUAL;
		FillMode = SOLID;

		VertexShader = compile vs_3_0 Light_Source_VS(_WorldViewProjection, _MaterialDiffuse);
		PixelShader = compile ps_3_0 Light_Source_PS();
	}
}
