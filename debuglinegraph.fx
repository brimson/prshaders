
float2 _GraphPos : GRAPHSIZE;
float2 _ViewportSize : VIEWPORTSIZE;

struct APP2VS
{
	float2 ScreenPos : POSITION;
	float4 Color : COLOR;
};

struct VS2PS
{
	float4 HPos : POSITION;
	float4 Color : COLOR;
};

VS2PS VS(APP2VS Input)
{
	VS2PS Output;

	float2 ScreenPos = Input.ScreenPos + _GraphPos;
	ScreenPos.xy = (ScreenPos.xy / (_ViewportSize.xy / 2.0) - 1.0) * float2(1.0, -1.0);

	Output.HPos = float4(ScreenPos, 0.001, 1.0);
	Output.Color = Input.Color;
	return Output;
}

float4 PS(VS2PS Input) : COLOR
{
	return Input.Color;
}

technique Graph <
	int Declaration[] =
	{
		// StreamNo, DataType, Usage, UsageIdx
		0, D3DDECLTYPE_FLOAT2, D3DDECLUSAGE_POSITION, 0,
		0, D3DDECLTYPE_D3DCOLOR, D3DDECLUSAGE_COLOR, 0,
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		ZEnable = FALSE;

		VertexShader = compile vs_3_0 VS();
		PixelShader = compile ps_3_0 PS();
	}
}
