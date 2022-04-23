#line 2 "Nametag.fx"

float4x4 _WorldViewProj : WorldViewProjection;
float _TexBlendFactor : TexBlendFactor;
float2 _FadeoutValues : FadeOut;
float4 _LocalEyePos : LocalEye;

float4 _Transformations[64] : TransformationArray;

// dep: this is a suboptimal Camp EA hack; rewrite this
float _Alphas[64] : AlphaArray;
float4 _Colors[9] : ColorArray;
float4 _AspectMul : AspectMul;

float4 _ArrowMult = float4(1.05, 1.05, 1.0, 1.0);

float4 _ArrowTrans : ArrowTransformation;
float4 _ArrowRot : ArrowRotation; // this is a 2x2 rotation matrix [X Y] [Z W]

float4 _IconRot : IconRotation;
// float4 _FIconRot : FIconRotation;
float2 _IconTexOffset : IconTexOffset;
float4 _IconFlashTexScaleOffset : IconFlashTexScaleOffset;

int _ColorIndex1 : ColorIndex1;
int _ColorIndex2 : ColorIndex2;

float4 _HealthBarTrans : HealthBarTrans;
float _HealthValue : HealthValue;

float _CrossFadeValue : CrossFadeValue;
float _AspectComp = 4.0 / 3.0;

texture Detail_0 : TEXLAYER0;
texture Detail_1 : TEXLAYER1;

sampler Sampler_0_Point = sampler_state
{
	Texture = (Detail_0);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
};

sampler Sampler_0_Bilinear = sampler_state
{
	Texture = (Detail_0);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
};

sampler Sampler_1_Point = sampler_state
{
	Texture = (Detail_1);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
};

sampler Sampler_1_Bilinear = sampler_state
{
	Texture = (Detail_1);
	AddressU = CLAMP;
	AddressV = CLAMP;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
};

struct APP2VS
{
	float4 Pos : POSITION;
	float2 Tex0 : TEXCOORD0;
	int4 Indices : BLENDINDICES0;
};

struct VS2PS
{
	float4 Pos : POSITION;
	float2 Tex0 : TEXCOORD0;
	float2 Tex1 : TEXCOORD1;
	float4 Col : COLOR;
};

struct VS2PS_2TEX
{
	float4 Pos : POSITION;
	float2 Tex0 : TEXCOORD0;
	float2 Tex1 : TEXCOORD1;
	float4 Col0 : COLOR0;
	float4 Col1 : COLOR1;
};




/*
	Nametag shader
*/

VS2PS Nametag_VS(APP2VS Input)
{
	VS2PS Output = (VS2PS)0;

	float4 IndexedTrans = _Transformations[Input.Indices.x];

	Output.Pos = float4(Input.Pos.xyz + IndexedTrans.xyz, 1.0);

	Output.Tex0 = Input.Tex0;

	Output.Col = lerp(_Colors[Input.Indices.y], _Colors[Input.Indices.z], _CrossFadeValue);
	Output.Col.a = _Alphas[Input.Indices.x];
	Output.Col.a *= 1.0 - saturate(IndexedTrans.w * _FadeoutValues.x + _FadeoutValues.y);
	return Output;
}

float4 Nametag_PS(VS2PS Input) : COLOR0
{
	float4 Tx0 = tex2D(Sampler_0_Point, Input.Tex0);
	return Tx0 * Input.Col;
}

technique nametag
<
	int Declaration[] =
	{
		// StreamNo, DataType, Usage, UsageIdx
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
		{ 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0 },
		{ 0, D3DDECLTYPE_SHORT4, D3DDECLUSAGE_BLENDINDICES, 0 },
		DECLARATION_END	// End macro
	};
	int TechniqueStates = D3DXFX_DONOTSAVESHADERSTATE;
>
{
	pass p0
	{
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

		CullMode = NONE;
		ZEnable = FALSE;
		ZWriteEnable = FALSE;

		VertexShader = compile vs_3_0 Nametag_VS();
		PixelShader = compile ps_3_0 Nametag_PS();
	}
}




/*
	Nametag arrow shader
*/

VS2PS Nametag_Arrow_VS(APP2VS Input)
{
	VS2PS Output = (VS2PS)0;

	// Does a 2x2 matrix 2d rotation of the local vertex coordinates in screen space
	Output.Pos.x = dot(Input.Pos.xyz, float3(_ArrowRot.xy, 0));
	Output.Pos.y = dot(Input.Pos.xyz, float3(_ArrowRot.zw, 0));
	Output.Pos.z = 0.0;
	Output.Pos.xyz *= _AspectMul;
	Output.Pos.xyz += _ArrowTrans * _ArrowMult;
	Output.Pos.w = 1.0;

	Output.Tex0 = Input.Tex0;

	Output.Col = _Colors[Input.Indices.y];
	Output.Col.a = 0.5;
	return Output;
}

float4 Nametag_Arrow_PS(VS2PS Input) : COLOR0
{
	float4 Tx0 = tex2D(Sampler_0_Bilinear, Input.Tex0);
	float4 Result = Tx0 * Input.Col;
	return Result;
}

technique nametag_arrow
<
	int Declaration[] =
	{
		// StreamNo, DataType, Usage, UsageIdx
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
		{ 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0 },
		{ 0, D3DDECLTYPE_SHORT4, D3DDECLUSAGE_BLENDINDICES, 0 },
		DECLARATION_END	// End macro
	};
	int TechniqueStates = D3DXFX_DONOTSAVESHADERSTATE;
>
{
	pass p0
	{
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

		CullMode = NONE;
		ZEnable = FALSE;
		ZWriteEnable = FALSE;

		VertexShader = compile vs_3_0 Nametag_Arrow_VS();
		PixelShader = compile ps_3_0 Nametag_Arrow_PS();
	}
}




/*
	Nametag healthbar shader
*/

VS2PS_2TEX Nametag_Healthbar_VS(APP2VS Input)
{
	VS2PS_2TEX Output = (VS2PS_2TEX)0;

	Output.Pos = float4(Input.Pos.xyz + _HealthBarTrans.xyz, 1.0);

	Output.Tex0 = Input.Tex0;
	Output.Tex1 = Input.Tex0;

	Output.Col0.rgb = Input.Tex0.x;
	Output.Col0.a = 1.0 - saturate(_HealthBarTrans.w * _FadeoutValues.x + _FadeoutValues.y);
	float4 Col0 = _Colors[_ColorIndex1];
	float4 Col1 = _Colors[_ColorIndex2];
	Output.Col1 = lerp(Col0, Col1, _CrossFadeValue);
	return Output;
}

float4 Nametag_Healthbar_PS(VS2PS_2TEX Input) : COLOR0
{
	float4 Tx0 = tex2D(Sampler_0_Point, Input.Tex0);
	float4 Tx1 = tex2D(Sampler_1_Point, Input.Tex1);
	return lerp(Tx0, Tx1, _HealthValue<Input.Col0.b) * Input.Col0.a * Input.Col1;
}

technique nametag_healthbar
<
	int Declaration[] =
	{
		// StreamNo, DataType, Usage, UsageIdx
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
		{ 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0 },
		{ 0, D3DDECLTYPE_SHORT4, D3DDECLUSAGE_BLENDINDICES, 0 },
		DECLARATION_END	// End macro
	};
	int TechniqueStates = D3DXFX_DONOTSAVESHADERSTATE;
>
{
	pass p0
	{
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

		CullMode = NONE;
		ZEnable = FALSE;
		ZWriteEnable = FALSE;

		VertexShader = compile vs_3_0 Nametag_Healthbar_VS();
		PixelShader = compile ps_3_0 Nametag_Healthbar_PS();
	}
}




/*
	Nametag vecicle icon shader
*/

VS2PS Nametag_Vehicle_Icons_VS(APP2VS Input)
{
	VS2PS Output = (VS2PS)0;

	float3 TempPos = Input.Pos;

	// since Input is aspectcompensated we need to compensate for that
	TempPos.y /= _AspectComp;

	float3 RotPos;
	RotPos.x = dot(TempPos, float3(_IconRot.x, _IconRot.z, 0));
	RotPos.y = dot(TempPos, float3(_IconRot.y, _IconRot.w, 0));
	RotPos.z = Input.Pos.z;

	// Fix aspect again
	RotPos.y *= _AspectComp;

	Output.Pos = float4(RotPos.xyz + _HealthBarTrans.xyz, 1.0);

	Output.Tex0 = Input.Tex0 + _IconTexOffset;
	Output.Tex1 = Input.Tex0 * _IconFlashTexScaleOffset.xy + _IconFlashTexScaleOffset.zw;

	// counter - rotate tex1 (flash icon)
	// float2 TempUV = Input.Tex0;
	// TempUV -= 0.5;
	// float2 RotUV;
	// RotUV.x = dot(TempUV, float2(_FIconRot.x, _FIconRot.z));
	// RotUV.y = dot(TempUV, float2(_FIconRot.y, _FIconRot.w));
	// RotUV += 0.5;
	// Output.Tex1 = RotUV * _IconFlashTexScaleOffset.xy + _IconFlashTexScaleOffset.zw;

	float4 Col0 = _Colors[_ColorIndex1];
	float4 Col1 = _Colors[_ColorIndex2];

	Output.Col = lerp(Col0, Col1, _CrossFadeValue);
	Output.Col.a *= 1.0 - saturate(_HealthBarTrans.w * _FadeoutValues.x + _FadeoutValues.y);

	return Output;
}

float4 Nametag_Vehicle_Icons_PS(VS2PS Input) : COLOR0
{
	float4 Tx0 = tex2D(Sampler_0_Bilinear, Input.Tex0);
	float4 Tx1 = tex2D(Sampler_1_Bilinear, Input.Tex1);
	return lerp(Tx0, Tx1, _CrossFadeValue) * Input.Col;
}

technique nametag_vehicleIcons
<
	int Declaration[] =
	{
		// StreamNo, DataType, Usage, UsageIdx
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
		{ 0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_TEXCOORD, 0 },
		{ 0, D3DDECLTYPE_SHORT4, D3DDECLUSAGE_BLENDINDICES, 0 },
		DECLARATION_END	// End macro
	};
	int TechniqueStates = D3DXFX_DONOTSAVESHADERSTATE;
>
{
	pass p0
	{
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

		CullMode = NONE;
		ZEnable = FALSE;
		ZWriteEnable = FALSE;

		VertexShader = compile vs_3_0 Nametag_Vehicle_Icons_VS();
		PixelShader = compile ps_3_0 Nametag_Vehicle_Icons_PS();
	}
}
