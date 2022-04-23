#line 2 "DebugD3DXMeshShapeShader.fx"

float4x4 _WorldViewProjection : WorldViewProjection;
float4x4 _World : World;

string Category = "Effects\\Lighting";

texture Texture_0 : TEXLAYER0;

sampler Sampler_0 = sampler_state
{
	Texture = (Texture_0);
	AddressU = WRAP;
	AddressV = WRAP;
	MinFilter = ANISOTROPIC;
	MagFilter = LINEAR /* ANISOTROPIC */;
	MaxAnisotropy = 8;
	MipFilter = LINEAR;
};

float _TextureScale : TEXTURESCALE;

float4 _LightDir = { 1.0f, 0.0f, 0.0f, 1.0f }; // light direction
float4 _LightDiffuse = { 1.0f, 1.0f, 1.0f, 1.0f }; // light diffuse
float4 _MaterialAmbient : MATERIALAMBIENT = { 0.5f, 0.5f, 0.5f, 1.0f };
float4 _MaterialDiffuse : MATERIALDIFFUSE = { 1.0f, 1.0f, 1.0f, 1.0f };

// float4 _Alpha : BLENDALPHA = { 1.0f, 1.0f, 1.0f, 1.0f };

float4 _ConeSkinValues : CONESKINVALUES;

struct APP2VS
{
	float4 Pos : POSITION;
	float3 Normal : NORMAL;
	float4 Color : COLOR;
};

struct VS2PS
{
	float4 Pos : POSITION;
	float4 Diffuse : COLOR;
};

struct VS2PS_Grid
{
	float4 Pos : POSITION;
	float4 Diffuse : COLOR;
	float2 Tex : TEXCOORD0;
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

VS2PS Shader_VS
(
	APP2VS Input,
	uniform float4x4 WorldViewProj,
	uniform float4 MaterialAmbient,
	uniform float4 MaterialDiffuse,
	uniform float4 LightDir
)
{
	VS2PS Output;

	float3 Pos;
	Pos = mul(Input.Pos, _World);
	Output.Pos = mul(float4(Pos.xyz, 1.0f), WorldViewProj);

	// Lighting. Shade (Ambient + etc.)
	Output.Diffuse.xyz = MaterialAmbient.xyz + Diffuse(Input.Normal, LightDir) * MaterialDiffuse.xyz;
	Output.Diffuse.w = _MaterialAmbient.a;
	return Output;
}

VS2PS CM_VS
(
	APP2VS Input,
	uniform float4x4 WorldViewProj,
	uniform float4 MaterialAmbient,
	uniform float4 MaterialDiffuse,
	uniform float4 LightDir
)
{
	VS2PS Output;
	float3 Pos;
	Pos = mul(Input.Pos, _World);

	Output.Pos = mul(float4(Pos.xyz, 1.0f), WorldViewProj);
	Output.Diffuse.xyz = MaterialAmbient.xyz + 0.1f * Diffuse(Input.Normal, float4(-1.0f, -1.0f, 1.0f, 0.0f)) * MaterialDiffuse.xyz;
	Output.Diffuse.w = 0.8f;
	return Output;
}

VS2PS ED_VS
(
	APP2VS Input,
	uniform float4x4 WorldViewProj,
	uniform float4 MaterialAmbient,
	uniform float4 MaterialDiffuse,
	uniform float4 LightDir
)
{
	VS2PS Output;

	float4 Pos = Input.Pos;

	float4 TempPos = Input.Pos;
	TempPos.z += 0.5f;
	float RadScale = lerp(_ConeSkinValues.x, _ConeSkinValues.y, TempPos.z);
	Pos.xy *= RadScale;
	Pos = mul(Pos, _World);

	Output.Pos = mul(Pos, _WorldViewProjection);
	Output.Diffuse.xyz = MaterialAmbient.xyz;
	Output.Diffuse.w = _MaterialAmbient.a;
	return Output;
}

VS2PS Shader_2_VS
(
	APP2VS Input,
	uniform float4x4 WorldViewProj,
	uniform float4 MaterialAmbient,
	uniform float4 MaterialDiffuse,
	uniform float4 LightDir
)
{
	VS2PS Output;

	float3 Pos;
	Pos = mul(Input.Pos, _World);
	Output.Pos = mul(float4(Pos.xyz, 1.0f), WorldViewProj);

	// Lighting. Shade (Ambient + etc.)
	Output.Diffuse.xyz = MaterialAmbient.xyz;
	Output.Diffuse.w = 0.3f;//_Alpha.xxxx;
	return Output;
}

VS2PS_Grid Grid_VS
(
	APP2VS Input,
	uniform float4x4 WorldViewProj,
	uniform float4 MaterialAmbient,
	uniform float4 MaterialDiffuse,
	uniform float4 LightDir,
	uniform float TextureScale
)
{
	VS2PS_Grid Output;

	float3 Pos;
	Pos = mul(Input.Pos, _World);
	Output.Pos = mul(float4(Pos.xyz, 1.0f), WorldViewProj);

	// Lighting. Shade (Ambient + etc.)
	Output.Diffuse.xyz = MaterialAmbient.xyz + Diffuse(Input.Normal, LightDir) * MaterialDiffuse.xyz;
	Output.Diffuse.w = _MaterialAmbient.a;
	Output.Tex = Input.Pos.xz * 0.5 + 0.5;
	Output.Tex *= TextureScale;
	return Output;
}

PS2FB Grid_PS(VS2PS_Grid Input)
{
	PS2FB Output;
	float4 Tex = tex2D(Sampler_0, Input.Tex);
	Output.Col.rgb = Tex * Input.Diffuse;
	Output.Col.a = (1.0 - Tex.b); // * Input.Diffuse.a;
	return Output;
}

PS2FB Shader_PS(VS2PS Input)
{
	PS2FB Output;
	Output.Col = Input.Diffuse;
	return Output;
}

VS2PS Occ_VS(APP2VS Input, uniform float4x4 WorldViewProj)
{
	VS2PS Output;
 	float4 Pos;
 	Pos = mul(Input.Pos, _World);
	Output.Pos = mul(Pos, WorldViewProj);
	Output.Diffuse = 1.0;
	return Output;
}

float4 Occ_PS(VS2PS Input) : COLOR
{
	return float4(1.0, 0.5, 0.5, 0.5);
}

PS2FB Marked_PS(VS2PS Input)
{
	PS2FB Output;
	Output.Col = Input.Diffuse; // + float4(1.0f, 0.0f, 0.0f, 0.0f);
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
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		// CullMode = NONE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		// FillMode = WIREFRAME;
		// ColorWriteEnable = 0;
		// ZWriteEnable = 0;
		// ZEnable = FALSE;

		VertexShader = compile vs_3_0 Shader_VS(_WorldViewProjection,_MaterialAmbient,_MaterialDiffuse,_LightDir);
		PixelShader = compile ps_3_0 Shader_PS();
	}
}

technique occluder
<
	int DetailLevel = DLHigh+DLNormal+DLLow+DLAbysmal;
	int Compatibility = CMPR300+CMPNV2X;
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
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		ZWriteEnable = TRUE;
		ZEnable = TRUE;
		ZFunc = LESSEQUAL;

		VertexShader = compile vs_3_0 Occ_VS(_WorldViewProjection);
		PixelShader = compile ps_3_0 Occ_PS();
	}
}

technique EditorDebug
<
	int DetailLevel = DLHigh+DLNormal+DLLow+DLAbysmal;
	int Compatibility = CMPR300+CMPNV2X;
>
{
	pass p0
	{
		CullMode = NONE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		FillMode = SOLID;
		// ColorWriteEnable = 0;
		// DepthBias=-0.00001;
		ZWriteEnable = 1;
		ZEnable = TRUE;
		ShadeMode = FLAT;
		ZFunc = LESSEQUAL;


		VertexShader = compile vs_3_0 ED_VS(_WorldViewProjection,_MaterialAmbient,_MaterialDiffuse,_LightDir);
		PixelShader = compile ps_3_0 Shader_PS();
	}

	pass p1
	{
		CullMode = CW;
		// AlphaBlendEnable = FALSE;
		// SrcBlend = SRCALPHA;
		// DestBlend = INVSRCALPHA;
		// FillMode = WIREFRAME;
		// ColorWriteEnable = RED|GREEN|BLUE|ALPHA;
		// ZWriteEnable = 0;
		// DepthBias=-0.000028;

		ZEnable = TRUE;
		FillMode = WIREFRAME;

		VertexShader = compile vs_3_0 ED_VS(_WorldViewProjection,_MaterialAmbient/2,_MaterialDiffuse/2,_LightDir);
		PixelShader = compile ps_3_0 Shader_PS();
	}

	/*
		pass p2
		{
			CullMode = NONE;
			FillMode = SOLID;
			VertexShader = 0;
		}
	*/
}

technique collisionMesh
<
	int DetailLevel = DLHigh+DLNormal+DLLow+DLAbysmal;
	int Compatibility = CMPR300+CMPNV2X;
>
{
	pass p0
	{
		CullMode = NONE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		// FillMode = WIREFRAME;
		// ColorWriteEnable = 0;
		DepthBias=-0.00001;
		ZWriteEnable = 1;
		ZEnable = TRUE;
		ShadeMode = FLAT;
		ZFunc = LESSEQUAL;

		VertexShader = compile vs_3_0 CM_VS(_WorldViewProjection,_MaterialAmbient,_MaterialDiffuse,_LightDir);
		PixelShader = compile ps_3_0 Shader_PS();
	}

	pass p1
	{
		// CullMode = NONE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		// FillMode = WIREFRAME;
		// ColorWriteEnable = RED|GREEN|BLUE|ALPHA;
		ZWriteEnable = 1;
		DepthBias=-0.000018;

		ZEnable = TRUE;
		FillMode = WIREFRAME;

		VertexShader = compile vs_3_0 CM_VS(_WorldViewProjection,_MaterialAmbient/2,_MaterialDiffuse/2,_LightDir);
		PixelShader = compile ps_3_0 Shader_PS();
	}

	pass p2
	{
		FillMode = SOLID;
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
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

		VertexShader = compile vs_3_0 Shader_VS(_WorldViewProjection,_MaterialAmbient,_MaterialDiffuse,_LightDir);
		PixelShader = compile ps_3_0 Marked_PS();
	}
}

technique gamePlayObject
<
	int DetailLevel = DLHigh+DLNormal+DLLow+DLAbysmal;
	int Compatibility = CMPR300+CMPNV2X;
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
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		//ZWriteEnable = TRUE;
		ZEnable = TRUE;

		VertexShader = compile vs_3_0 Shader_2_VS(_WorldViewProjection,_MaterialAmbient,_MaterialDiffuse,_LightDir);
		PixelShader = compile ps_3_0 Shader_PS();
	}
}


technique bounding
<
	int DetailLevel = DLHigh+DLNormal+DLLow+DLAbysmal;
	int Compatibility = CMPR300+CMPNV2X;
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
		AlphaBlendEnable = FALSE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		ZWriteEnable = 0;
		ZEnable = FALSE;
		CullMode = NONE;
		FillMode = WIREFRAME;

		VertexShader = compile vs_3_0 Shader_2_VS(_WorldViewProjection,_MaterialAmbient,_MaterialDiffuse,_LightDir);
		PixelShader = compile ps_3_0 Marked_PS();
	}
}

technique grid
<
	int DetailLevel = DLHigh+DLNormal+DLLow+DLAbysmal;
	int Compatibility = CMPR300+CMPNV2X;
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
		// CullMode = NONE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		// FillMode = WIREFRAME;
		// ColorWriteEnable = 0;
		// ZWriteEnable = 0;
		// ZEnable = FALSE;

		VertexShader = compile vs_3_0 Grid_VS(_WorldViewProjection,_MaterialAmbient,_MaterialDiffuse,_LightDir,_TextureScale);
		PixelShader = compile ps_3_0 Grid_PS();
	}
}

VS2PS Pivot_VS(APP2VS Input)
{
	VS2PS Output;

 	float4 Pos = Input.Pos;
 	float RadScale = lerp(_ConeSkinValues.x, _ConeSkinValues.y, Pos.z + 0.5);
	Pos.xy *= RadScale;
 	Pos = mul(Pos, _World);
	Output.Pos = mul(Pos, _WorldViewProjection);

	// Lighting. Shade (Ambient + etc.)
	Output.Diffuse.rgb = _MaterialAmbient.rgb;
	Output.Diffuse.a = _MaterialAmbient.a;

	return Output;
}

VS2PS Pivot_Box_VS(APP2VS Input)
{
	VS2PS Output;

 	float4 Pos = Input.Pos;
 	Pos = mul(Pos, _World);
	Output.Pos = mul(Pos, _WorldViewProjection);

	// Lighting. Shade (Ambient + etc.)
	Output.Diffuse.rgb = _MaterialAmbient.rgb;
	Output.Diffuse.a = _MaterialAmbient.a;

	return Output;
}

VS2PS Spotlight_VS(APP2VS Input)
{
	VS2PS Output;

 	float4 Pos = Input.Pos;
 	Pos.z += 0.5;
 	float RadScale = lerp(_ConeSkinValues.x, _ConeSkinValues.y, Pos.z);
	Pos.xy *= RadScale;
	// Pos.xyz = mul(Pos, _World);
	// Pos.w = 1;
 	Pos = mul(Pos, _World);
	Output.Pos = mul(Pos, _WorldViewProjection);

	// Lighting. Shade (Ambient + etc.)
	Output.Diffuse.rgb = _MaterialAmbient.rgb;
	Output.Diffuse.a = _MaterialAmbient.a;

	return Output;
}

float4 Spotlight_PS(VS2PS Input) : COLOR
{
	return Input.Diffuse;
}

technique spotlight
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

		VertexShader = compile vs_3_0 Spotlight_VS();
		PixelShader = compile ps_3_0 Spotlight_PS();
	}
	pass p1
	{
		ColorWriteEnable = Red|Blue|Green|Alpha;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		ZFunc = EQUAL;
		ZWriteEnable = FALSE;

		VertexShader = compile vs_3_0 Spotlight_VS();
		PixelShader = compile ps_3_0 Spotlight_PS();
	}
}

technique pivotBox
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
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		ZWriteEnable = 0;
		ZEnable = FALSE;

		VertexShader = compile vs_3_0 Pivot_Box_VS();
		PixelShader = compile ps_3_0 Spotlight_PS();
	}
	pass p1
	{
		ColorWriteEnable = Red|Blue|Green|Alpha;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		ZFunc = EQUAL;
		ZWriteEnable = FALSE;

		VertexShader = compile vs_3_0 Pivot_Box_VS();
		PixelShader = compile ps_3_0 Spotlight_PS();
	}
}

technique pivot
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
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		ZWriteEnable = 0;
		ZEnable = FALSE;

		VertexShader = compile vs_3_0 Pivot_VS();
		PixelShader = compile ps_3_0 Spotlight_PS();
	}
	pass p1
	{
		ColorWriteEnable = Red|Blue|Green|Alpha;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		ZFunc = EQUAL;
		ZWriteEnable = FALSE;

		VertexShader = compile vs_3_0 Pivot_VS();
		PixelShader = compile ps_3_0 Spotlight_PS();
	}
}


struct APP2VS_F
{
	float4 Pos : POSITION;
	float4 Col : COLOR;
};

struct VS2PS_F
{
	float4 Pos : POSITION;
	float4 Col : COLOR;
};

VS2PS_F Frustum_VS(APP2VS_F Input)
{
	VS2PS_F Output;
	Output.Pos = mul(Input.Pos, _WorldViewProjection);
	Output.Col = Input.Col;
	return Output;
}

float4 Frustum_PS(VS2PS_F Input, uniform float AlphaVal) : COLOR
{
	return float4(Input.Col.rgb, Input.Col.a * AlphaVal);
}

technique wirefrustum
{
	pass p0
	{
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = ONE;
		ZEnable = TRUE;
		ZFunc = GREATER;
		ZWriteEnable = FALSE;
		CullMode = NONE;
		FillMode = SOLID;
		// FillMode = WIREFRAME;

		VertexShader = compile vs_3_0 Frustum_VS();
		PixelShader = compile ps_3_0 Frustum_PS(0.025);
	}
	pass p1
	{
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZFunc = LESSEQUAL;
		ZWriteEnable = FALSE;
		CullMode = NONE;
		FillMode = SOLID;
		// FillMode = WIREFRAME;

		VertexShader = compile vs_3_0 Frustum_VS();
		PixelShader = compile ps_3_0 Frustum_PS(1);
	}
}

technique solidfrustum
{
	pass p0
	{
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = ONE;
		ZEnable = TRUE;
		ZFunc = GREATER;
		ZWriteEnable = FALSE;
		CullMode = NONE;
		FillMode = SOLID;
		// FillMode = WIREFRAME;

		VertexShader = compile vs_3_0 Frustum_VS();
		PixelShader = compile ps_3_0 Frustum_PS(0.25);
	}
	pass p1
	{
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZFunc = LESSEQUAL;
		ZWriteEnable = FALSE;
		CullMode = NONE;
		FillMode = SOLID;
		// FillMode = WIREFRAME;

		VertexShader = compile vs_3_0 Frustum_VS();
		PixelShader = compile ps_3_0 Frustum_PS(1);
	}
}

technique projectorfrustum
{
	pass p0
	{
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = ONE;
		ZEnable = TRUE;
		ZFunc = LESSEQUAL;
		ZWriteEnable = FALSE;
		// CullMode = CW;
		// FillMode = WIREFRAME;

		VertexShader = compile vs_3_0 Frustum_VS();
		PixelShader = compile ps_3_0 Frustum_PS(1);
	}
}
