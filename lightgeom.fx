#line 2 "lightGeom.fx"

// UNIFORM INPUTS
float4x4 _WorldViewProj : WorldViewProj;
float4x4 _WorldView : WorldView;
float4 _LightColor : LightColor;

float3 _SpotDir : SpotDir;
float _ConeAngle : ConeAngle;

// float3 _SpotPosition : SpotPosition;

struct APP2VS
{
	float4 Pos : POSITION;
};

struct VS2PS
{
	float4 HPos : POSITION;
};

VS2PS Point_Light_VS(APP2VS Input)
{
	VS2PS Out;
 	Out.HPos = mul(float4(Input.Pos.xyz, 1.0f), _WorldViewProj);
	return Out;
}

float4 Point_Light_PS() : COLOR
{
	return _LightColor;
}

technique Pointlight
<
	int Declaration[] =
	{
		// StreamNo, DataType, Usage, UsageIdx
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		CullMode = NONE;
		ZEnable = TRUE;
		ZFunc = LESSEQUAL;
		ZWriteEnable = TRUE;
		StencilEnable = TRUE;
		StencilFunc = ALWAYS;
		StencilPass = ZERO;

 		VertexShader = compile vs_3_0 Point_Light_VS();
		PixelShader = compile ps_3_0 Point_Light_PS();
	}
}

struct VS2PS_Spot
{
	float4 HPos : POSITION;
	float3 LightDir : TEXCOORD0;
	float3 LightVec : TEXCOORD1;
};

VS2PS_Spot Spot_Light_VS(APP2VS Input)
{
	VS2PS_Spot Out;
 	Out.HPos = mul(float4(Input.Pos.xyz, 1.0f), _WorldViewProj);

	// transform vertex
	float3 VertPos = mul(float4(Input.Pos.xyz, 1.0f), _WorldView);
	Out.LightVec = -normalize(VertPos);

	// transform LightDir to objectSpace
	Out.LightDir = mul(_SpotDir, float3x3(_WorldView[0].xyz, _WorldView[1].xyz, _WorldView[2].xyz));

	return Out;
}

float4 Spot_Light_PS(VS2PS_Spot Input) : COLOR
{
	float3 LightVec = normalize(Input.LightVec);
	float3 LightDir = normalize(Input.LightDir);
	float ConicalAtt = saturate(pow(saturate(dot(LightVec, LightDir)), 2.0) + (1.0f - _ConeAngle));
	return _LightColor * ConicalAtt;
}

technique Spotlight
<
	int Declaration[] =
	{
		// StreamNo, DataType, Usage, UsageIdx
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		CullMode = NONE;
		ZEnable = TRUE;
		ZFunc = LESSEQUAL;
		ZWriteEnable = TRUE;
		StencilEnable = TRUE;
		StencilFunc = ALWAYS;
		StencilPass = ZERO;

 		VertexShader = compile vs_3_0 Spot_Light_VS();
		PixelShader = compile ps_3_0 Spot_Light_PS();
	}
}
