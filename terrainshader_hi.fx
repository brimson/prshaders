#line 2 "TerrainShader_Hi.fx"

/*
	Hi Terrain
*/

// Special samplers for dynamic filtering types
sampler Dyn_Sampler_3_Wrap = sampler_state
{
	Texture = (Texture_3);
	AddressU = WRAP;
	AddressV = WRAP;
	MipFilter = FILTER_TRN_MIP;
	MinFilter = FILTER_TRN_DIFF_MIN;
	MagFilter = FILTER_TRN_DIFF_MAG;
	#ifdef FILTER_TRN_DIFF_MAX_ANISOTROPY
		MaxAnisotropy = FILTER_TRN_DIFF_MAX_ANISOTROPY;
	#endif
};

sampler Dyn_Sampler_4_Wrap = sampler_state
{
	Texture = (Texture_4);
	AddressU = WRAP;
	AddressV = WRAP;
	MipFilter = FILTER_TRN_MIP;
	MinFilter = FILTER_TRN_DIFF_MIN;
	MagFilter = FILTER_TRN_DIFF_MAG;
	#ifdef FILTER_TRN_DIFF_MAX_ANISOTROPY
		MaxAnisotropy = FILTER_TRN_DIFF_MAX_ANISOTROPY;
	#endif
};

sampler Dyn_Sampler_6_Wrap = sampler_state
{
	Texture = (Texture_6);
	AddressU = WRAP;
	AddressV = WRAP;
	MipFilter = FILTER_TRN_MIP;
	MinFilter = FILTER_TRN_DIFF_MIN;
	MagFilter = FILTER_TRN_DIFF_MAG;
	#ifdef FILTER_TRN_DIFF_MAX_ANISOTROPY
		MaxAnisotropy = FILTER_TRN_DIFF_MAX_ANISOTROPY;
	#endif
};




struct Hi_VS2PS_FullDetail
{
	float4 Pos : POSITION;
	float4 Tex0 : TEXCOORD0;
	float4 Tex1 : TEXCOORD1;
	float4 BlendValueAndFade : TEXCOORD2; // tl: texcoord because we don't want clamping
	float4 Tex3 : TEXCOORD3;
	float2 Tex5 : TEXCOORD4;
	float2 Tex6 : TEXCOORD5;
	float4 FogAndFade2 : COLOR0;
};

Hi_VS2PS_FullDetail Hi_FullDetail_VS(APP2VS_Shared_Default Input)
{
	Hi_VS2PS_FullDetail Output = (Hi_VS2PS_FullDetail)0;

	float4 WPos;
	WPos.xz = (Input.Pos0.xy * _ScaleTransXZ.xy) + _ScaleTransXZ.zw;
	WPos.yw = (Input.Pos1.xw * _ScaleTransY.xy);// + _ScaleTransY.zw;

	#if DEBUGTERRAIN
		Output.Pos = mul(WPos, _ViewProj);
		Output.Tex0 = float4(0.0);
		Output.Tex1 = float4(0.0);
		Output.BlendValueAndFade = float4(0.0);
		Output.Tex3 = float4(0.0);
		Output.Tex5.xy = float2(0.0);
		Output.FogAndFade2 = float4(0.0);
		return Output;
	#endif

	float YDelta, InterpVal;
	// Geo_MorphPosition(WPos, Input.MorphDelta, YDelta, InterpVal);
	Geo_MorphPosition(WPos, Input.MorphDelta, Input.Pos0.z, YDelta, InterpVal);

	// tl: output HPos as early as possible.
 	Output.Pos = mul(WPos, _ViewProj);

 	// tl: uncompress normal
 	Input.Normal = Input.Normal * 2.0 - 1.0;

	float3 Tex = float3(Input.Pos0.y * _TexScale.z, WPos.y * _TexScale.y, Input.Pos0.x * _TexScale.x);
	float2 YPlaneTexCoord = Tex.zx;
	#if HIGHTERRAIN
		float2 XPlaneTexCoord = Tex.xy;
		float2 ZPlaneTexCoord = Tex.zy;
	#endif

 	Output.Tex0.xy = (YPlaneTexCoord*_ColorLightTex.x) + _ColorLightTex.y;
 	Output.Tex6 = (YPlaneTexCoord*_DetailTex.x) + _DetailTex.y;

	// tl: Switched tex0.wz for tex3.xy to easier access it from 1.4
	Output.Tex3.xy = YPlaneTexCoord.xy * _NearTexTiling.z;

 	Output.Tex5.xy = YPlaneTexCoord * _FarTexTiling.z;

	#if HIGHTERRAIN
		Output.Tex0.wz = XPlaneTexCoord.xy * _FarTexTiling.xy;
		Output.Tex0.z += _FarTexTiling.w;
		Output.Tex3.wz = ZPlaneTexCoord.xy * _FarTexTiling.xy;
		Output.Tex3.z += _FarTexTiling.w;
	#endif

	Output.FogAndFade2.x = saturate(calcFog(Output.Pos.w));
	Output.FogAndFade2.yzw = 0.5 + InterpVal * 0.5;

	#if HIGHTERRAIN
		Output.BlendValueAndFade.w = InterpVal;
	#elif MIDTERRAIN
		// tl: optimized so we can do more advanced lerp in same number of instructions
		//     factors are 2c and (2-2c) which equals a lerp()*2
		//     Don't use w, it's harder to access from ps1.4
		Output.BlendValueAndFade.xz = InterpVal * float2(2.0, -2.0) + float2(0.0, 2.0);
	#endif

	#if HIGHTERRAIN
		Output.BlendValueAndFade.xyz = saturate(abs(Input.Normal) - _BlendMod);
		float Total = dot(1.0, Output.BlendValueAndFade.xyz);
		Output.BlendValueAndFade.xyz /= Total;
	#elif MIDTERRAIN
		// tl: use squared yNormal as blend val. pre-multiply with fade value.
		Output.BlendValueAndFade.yw = pow(Input.Normal.y, 8.0) /* Input.Normal.y*/ * Output.FogAndFade2.y;

		// tl: pre calculate half-lerp against constant, result is 2 ps instruction lerp distributed
		//     to 1 vs MAD and 1 ps MAD
		Output.FogAndFade2.z = Output.BlendValueAndFade.y * -0.5 + 0.5;
	#endif

	Output.FogAndFade2 = saturate(Output.FogAndFade2);

	Output.Tex1 = ProjToLighting(Output.Pos);

	// Output.Tex1 = float4(_MorphDeltaAdder[Input.Pos0.z*256], 1) * 256.0 * 256.0;

	return Output;
}

// #define LIGHTONLY 1
float4 Hi_FullDetail_PS(Hi_VS2PS_FullDetail Input) : COLOR
{
	//	return float4(0.0, 0.0, 0.25, 1.0);
	#if LIGHTONLY
		float4 AccumLights = tex2Dproj(Sampler_1_Clamp, Input.Tex1);
		float4 Light = 2.0 * AccumLights.w * _SunColor + AccumLights;
		float4 Component = tex2D(Sampler_2_Clamp, Input.Tex0.xy);
		float ChartContrib = dot(_ComponentSelector, Component);
		return ChartContrib * Light;
	#else
		#if DEBUGTERRAIN
			return float4(0.0, 0.0, 1.0, 1.0);
		#endif

		float3 ColorMap;
		float3 Light;

		float4 AccumLights = tex2Dproj(Sampler_1_Clamp, Input.Tex1);

		// tl: 2* moved later in shader to avoid clamping at -+2.0 in ps1.4
		if (FogColor.r < 0.01)
		{
			// On thermals no shadows
			Light = 2.0 * _SunColor.rgb + AccumLights.rgb;
			// And gray color
			ColorMap = 0.333;
		}
		else
		{
			Light = 2.0 * AccumLights.w * _SunColor.rgb + AccumLights.rgb;
			ColorMap = tex2D(Sampler_0_Clamp, Input.Tex0.xy);
		}

		float4 Component = tex2D(Sampler_2_Clamp, Input.Tex6);
		float ChartContrib = dot(_ComponentSelector, Component);
		float3 DetailMap = tex2D(Dyn_Sampler_3_Wrap, Input.Tex3.xy);

		#if HIGHTERRAIN
			float4 LowComponent = tex2D(Sampler_5_Clamp, Input.Tex6);
			float4 YPlaneLowDetailmap = tex2D(Sampler_4_Wrap, Input.Tex5.xy);
			float4 XPlaneLowDetailmap = tex2D(Sampler_4_Wrap, Input.Tex3.xy);
			float4 ZPlaneLowDetailmap = tex2D(Sampler_4_Wrap, Input.Tex0.wz);
			float LowDetailMap = lerp(0.5, YPlaneLowDetailmap.z, LowComponent.x*Input.FogAndFade2.y);
		#else
			float4 YPlaneLowDetailmap = tex2D(Sampler_4_Wrap, Input.Tex5.xy);

			// tl: do lerp in 1 MAD by precalculating constant factor in vShader
			// float LowDetailMap = YPlaneLowDetailmap.z * Input.BlendValueAndFade.y + Input.FogAndFade2.z;
			float LowDetailMap = lerp(YPlaneLowDetailmap.x, YPlaneLowDetailmap.z, Input.BlendValueAndFade.y);
		#endif

		#if HIGHTERRAIN
			float Mounten =	(XPlaneLowDetailmap.y * Input.BlendValueAndFade.x) +
							(YPlaneLowDetailmap.x * Input.BlendValueAndFade.y) +
							(ZPlaneLowDetailmap.y * Input.BlendValueAndFade.z);
			LowDetailMap *= (4.0 * lerp(0.5, Mounten, LowComponent.z));
			float3 BothDetailmap = DetailMap * LowDetailMap;
			float3 DetailOut = lerp(2.0 * BothDetailmap, LowDetailMap, Input.BlendValueAndFade.w);
		#else
			// tl: lerp optimized to handle 2*c*low + (2-2c)*detail, factors sent from vs
			float3 DetailOut = LowDetailMap*Input.BlendValueAndFade.x + DetailMap*Input.BlendValueAndFade.z;
		#endif
		float3 OutColor = DetailOut * ColorMap * Light * 2.0;
		float3 FogOutColor = lerp(FogColor, OutColor, Input.FogAndFade2.x);
		return float4(ChartContrib * FogOutColor, ChartContrib);
	#endif
}




struct VS2PS_Hi_FullDetail_Mounten
{
	float4 Pos : POSITION;
	float4 Tex0 : TEXCOORD0;
	float4 Tex1 : TEXCOORD1;
	float4 BlendValueAndFade : TEXCOORD2; // tl: texcoord because we don't want clamping
	#if HIGHTERRAIN
		float4 Tex3 : TEXCOORD6;
	#endif
	float2 Tex5 : TEXCOORD5;
	float4 Tex6 : TEXCOORD3;
	float2 Tex7 : TEXCOORD4;
	float4 FogAndFade2 : COLOR0;
};

VS2PS_Hi_FullDetail_Mounten Hi_FullDetail_Mounten_VS(APP2VS_Shared_Default Input)
{
	VS2PS_Hi_FullDetail_Mounten Output;

	float4 WPos;
	WPos.xz = (Input.Pos0.xy * _ScaleTransXZ.xy) + _ScaleTransXZ.zw;
	// tl: Trans is always 0, and MADs cost more than MULs in certain cards.
	WPos.yw = Input.Pos1.xw * _ScaleTransY.xy;

	#if DEBUGTERRAIN
		Output.Pos = mul(WPos, _ViewProj);
		Output.Tex0 = float4(0.0);
		Output.Tex1 = float4(0.0);
		Output.BlendValueAndFade = float4(0.0);
		Output.Tex3 = float4(0.0);
		Output.Tex5.xy = float2(0.0);
		Output.Tex6 = float4(0.0);
		Output.FogAndFade2 = float4(0.0);
		return Output;
	#endif

	float YDelta, InterpVal;
	// Geo_MorphPosition(WPos, Input.MorphDelta, YDelta, InterpVal);
	Geo_MorphPosition(WPos, Input.MorphDelta, Input.Pos0.z, YDelta, InterpVal);

	// tl: output HPos as early as possible.
	Output.Pos = mul(WPos, _ViewProj);

	// tl: uncompress normal
	Input.Normal = Input.Normal * 2.0 - 1.0;

	float3 Tex = float3(Input.Pos0.y * _TexScale.z, WPos.y * _TexScale.y, Input.Pos0.x * _TexScale.x);
	float2 XPlaneTexCoord = Tex.xy;
	float2 YPlaneTexCoord = Tex.zx;
	float2 ZPlaneTexCoord = Tex.zy;

	Output.Tex0.xy = (YPlaneTexCoord*_ColorLightTex.x) + _ColorLightTex.y;
	Output.Tex7 = (YPlaneTexCoord*_DetailTex.x) + _DetailTex.y;

	Output.Tex6.xy = YPlaneTexCoord.xy * _NearTexTiling.z;
	Output.Tex0.wz = XPlaneTexCoord.xy * _NearTexTiling.xy;
	Output.Tex0.z += _NearTexTiling.w;
	Output.Tex6.wz = ZPlaneTexCoord.xy * _NearTexTiling.xy;
	Output.Tex6.z += _NearTexTiling.w;

	Output.Tex5.xy = YPlaneTexCoord * _FarTexTiling.z;

	Output.FogAndFade2.x = saturate(calcFog(Output.Pos.w));
	Output.FogAndFade2.yzw = saturate(0.5 + InterpVal * 0.5);

	#if HIGHTERRAIN
		Output.Tex3.xy = XPlaneTexCoord.xy * _FarTexTiling.xy;
		Output.Tex3.y += _FarTexTiling.w;
		Output.Tex3.wz = ZPlaneTexCoord.xy * _FarTexTiling.xy;
		Output.Tex3.z += _FarTexTiling.w;
		Output.BlendValueAndFade.w = InterpVal;
	#else
		// tl: optimized so we can do more advanced lerp in same number of instructions
		//     factors are 2c and (2-2c) which equals a lerp()*2
		//     Don't use w, it's harder to access from ps1.4
		// Output.BlendValueAndFade.xz = InterpVal * float2(2.0, -2.0) + float2(0.0, 2.0);
		Output.BlendValueAndFade.xz = InterpVal * float2(1, -2) + float2(1, 2);
		// Output.BlendValueAndFade = InterpVal * float4(2, 0, -2, 0) + float4(0, 0, 2, 0);
		// Output.BlendValueAndFade.w = InterpVal;
	#endif

	#if HIGHTERRAIN
		Output.BlendValueAndFade.xyz = saturate(abs(Input.Normal) - _BlendMod);
		float Total = dot(1.0, Output.BlendValueAndFade.xyz);
		Output.BlendValueAndFade.xyz /= Total;
	#else
		// tl: use squared yNormal as blend val. pre-multiply with fade value.
		// Output.BlendValueAndFade.yw = Input.Normal.y * Input.Normal.y * Output.FogAndFade2.y;
		Output.BlendValueAndFade.yw = pow(Input.Normal.y, 8.0);

		// tl: pre calculate half-lerp against constant, result is 2 ps instruction lerp distributed
		//     to 1 vs MAD and 1 ps MAD
		//     Output.FogAndFade2.z = Output.BlendValueAndFade.y*-0.5 + 0.5;
	#endif

	Output.FogAndFade2 = saturate(Output.FogAndFade2);

	Output.Tex1 = ProjToLighting(Output.Pos);

	return Output;
}

float4 Hi_FullDetail_Mounten_PS(VS2PS_Hi_FullDetail_Mounten Input) : COLOR
{
	#if LIGHTONLY
		float4 AccumLights = tex2Dproj(Sampler_1_Clamp, Input.Tex1);
		float4 Light = 2.0 * AccumLights.w * _SunColor + AccumLights;
		float4 Component = tex2D(Sampler_2_Clamp, Input.Tex0.xy);
		float ChartContrib = dot(_ComponentSelector, Component);
		return ChartContrib * Light;
	#else
		#if DEBUGTERRAIN
			return float4(1,0, 0.0, 1.0);
		#endif

		float4 AccumLights = tex2Dproj(Sampler_1_Clamp, Input.Tex1);

		// tl: 2* moved later in shader to avoid clamping at -+2.0 in ps1.4
		float3 Light;
		float3 ColorMap;
		if (FogColor.r < 0.01)
		{
			// On thermals no shadows
			Light = 2.0 * _SunColor.rgb + AccumLights.rgb;
			// And gray color
			ColorMap = 0.333;
		}
		else
		{
			Light = 2.0 * AccumLights.w * _SunColor.rgb + AccumLights.rgb;
			ColorMap = tex2D(Sampler_0_Clamp, Input.Tex0.xy);
		}

		float4 Component = tex2D(Sampler_2_Clamp, Input.Tex7);
		float ChartContrib = dot(_ComponentSelector, Component);

		#if HIGHTERRAIN
			float3 YPlaneDetailmap = tex2D(Dyn_Sampler_3_Wrap, Input.Tex6.xy);
			float3 XPlaneDetailmap = tex2D(Dyn_Sampler_6_Wrap, Input.Tex0.wz);
			float3 ZPlaneDetailmap = tex2D(Dyn_Sampler_6_Wrap, Input.Tex6.wz);
			float3 YPlaneLowDetailmap = tex2D(Sampler_4_Wrap, Input.Tex5.xy);
			float3 XPlaneLowDetailmap = tex2D(Sampler_4_Wrap, Input.Tex3.xy);
			float3 ZPlaneLowDetailmap = tex2D(Sampler_4_Wrap, Input.Tex3.wz);
			float3 LowComponent = tex2D(Sampler_5_Clamp, Input.Tex7);
			float3 DetailMap = 	(XPlaneDetailmap * Input.BlendValueAndFade.x) +
								(YPlaneDetailmap * Input.BlendValueAndFade.y) +
								(ZPlaneDetailmap * Input.BlendValueAndFade.z);

			float LowDetailMap = lerp(0.5, YPlaneLowDetailmap.z, LowComponent.x*Input.FogAndFade2.y);
			float Mounten = (XPlaneLowDetailmap.y * Input.BlendValueAndFade.x) +
							(YPlaneLowDetailmap.x * Input.BlendValueAndFade.y) +
							(ZPlaneLowDetailmap.y * Input.BlendValueAndFade.z);
			LowDetailMap *= (4.0 * lerp(0.5, Mounten, LowComponent.z));

			float3 BothDetailmap = DetailMap * LowDetailMap;
			float3 DetailOut = lerp(2.0 * BothDetailmap, LowDetailMap, Input.BlendValueAndFade.w);
		#else
			float3 YPlaneDetailmap = tex2D(Sampler_3_Wrap, Input.Tex6.xy);
			float3 YPlaneLowDetailmap = tex2D(Sampler_4_Wrap, Input.Tex5.xy);
			float LowDetailMap = lerp(YPlaneLowDetailmap.x, YPlaneLowDetailmap.z, Input.BlendValueAndFade.y);
			// tl: lerp optimized to handle 2*c*low + (2-2c)*detail, factors sent from vs
			// tl: dont use detail mountains
			float3 DetailOut = LowDetailMap * Input.BlendValueAndFade.x + LowDetailMap * YPlaneDetailmap * Input.BlendValueAndFade.z;
			// float3 DetailOut = LowDetailMap * 2.0;
		#endif
		float3 OutColor = DetailOut * ColorMap * Light * 2.0;
		float3 FogOutColor = lerp(FogColor, OutColor, Input.FogAndFade2.x);
		return float4(ChartContrib * FogOutColor, ChartContrib);
	#endif
}




struct Hi_VS2PS_FullDetail_EnvMap
{
	float4 Pos : POSITION;
	float4 Tex0 : TEXCOORD0;
	float4 Tex1 : TEXCOORD1;
	float4 Tex3 : TEXCOORD3;
	float4 BlendValueAndFade : COLOR0;
	float3 Tex5 : TEXCOORD2;
	float2 Tex6 : TEXCOORD5;
	float3 EnvMap : TEXCOORD4;
	float4 FogAndFade2 : COLOR1;
};

Hi_VS2PS_FullDetail_EnvMap Hi_FullDetail_EnvMap_VS(APP2VS_Shared_Default Input)
{
	Hi_VS2PS_FullDetail_EnvMap Output = (Hi_VS2PS_FullDetail_EnvMap)0;

	float4 WPos;
	WPos.xz = (Input.Pos0.xy * _ScaleTransXZ.xy) + _ScaleTransXZ.zw;
	WPos.yw = (Input.Pos1.xw * _ScaleTransY.xy); // + _ScaleTransY.zw;

	#if DEBUGTERRAIN
		Output.Pos = mul(WPos, _ViewProj);
		Output.Tex0 = float4(0.0);
		Output.Tex1 = float4(0.0);
		Output.BlendValueAndFade = float4(0.0);
		Output.Tex3 = float4(0.0);
		Output.Tex5.xy = float2(0.0);
		Output.EnvMap = float3(0.0);
		Output.FogAndFade2 = float4(0.0);
		return Output;
	#endif

	float YDelta, InterpVal;
	// Geo_MorphPosition(WPos, Input.MorphDelta, YDelta, InterpVal);
	Geo_MorphPosition(WPos, Input.MorphDelta, Input.Pos0.z, YDelta, InterpVal);

	// tl: output HPos as early as possible.
 	Output.Pos = mul(WPos, _ViewProj);

 	// tl: uncompress normal
 	Input.Normal = Input.Normal * 2.0 - 1.0;

	float3 Tex = float3(Input.Pos0.y * _TexScale.z, WPos.y * _TexScale.y, Input.Pos0.x * _TexScale.x);
	float2 YPlaneTexCoord = Tex.zx;
	#if HIGHTERRAIN
		float2 XPlaneTexCoord = Tex.xy;
		float2 ZPlaneTexCoord = Tex.zy;
	#endif

 	Output.Tex0.xy = (YPlaneTexCoord * _ColorLightTex.x) + _ColorLightTex.y;
 	Output.Tex6 = (YPlaneTexCoord * _DetailTex.x) + _DetailTex.y;

	// tl: Switched tex0.wz for tex3.xy to easier access it from 1.4
	Output.Tex3.xy = YPlaneTexCoord.xy * _NearTexTiling.z;

 	Output.Tex5.xy = YPlaneTexCoord * _FarTexTiling.z;

	#if HIGHTERRAIN
		Output.Tex0.wz = XPlaneTexCoord.xy * _FarTexTiling.xy;
		Output.Tex0.z += _FarTexTiling.w;
		Output.Tex3.wz = ZPlaneTexCoord.xy * _FarTexTiling.xy;
		Output.Tex3.z += _FarTexTiling.w;
	#endif

	Output.FogAndFade2.x = saturate(calcFog(Output.Pos.w));
	Output.FogAndFade2.yzw = 0.5 + InterpVal * 0.5;

	#if HIGHTERRAIN
		Output.BlendValueAndFade.w = InterpVal;
	#elif MIDTERRAIN
		// tl: optimized so we can do more advanced lerp in same number of instructions
		//    factors are 2c and (2-2c) which equals a lerp()*2.0
		//    Don't use w, it's harder to access from ps1.4
		Output.BlendValueAndFade.xz = InterpVal * float2(2.0, -2.0) + float2(0.0, 2.0);
	#endif

	#if HIGHTERRAIN
		Output.BlendValueAndFade.xyz = saturate(abs(Input.Normal) - _BlendMod);
		float Total = dot(1.0, Output.BlendValueAndFade.xyz);
		Output.BlendValueAndFade.xyz /= Total;
	#elif MIDTERRAIN
		// tl: use squared yNormal as blend val. pre-multiply with fade value.
		Output.BlendValueAndFade.yw = Input.Normal.y * Input.Normal.y * Output.FogAndFade2.y;

		Output.FogAndFade2.y = InterpVal;
		Output.FogAndFade2.z = Output.BlendValueAndFade.y * -0.5 + 0.5;
	#endif

	Output.BlendValueAndFade = saturate(Output.BlendValueAndFade);
	Output.FogAndFade2 = saturate(Output.FogAndFade2);

	Output.Tex1 = ProjToLighting(Output.Pos);

	// Environment map
	// tl: no need to normalize, reflection works with long vectors,
	//     and cube maps auto-normalize.
	// Output.EnvMap = reflect(WPos.xyz - _CameraPos.xyz, float3(0.0, 1.0, 0.0));
	// Output.EnvMap = float3(1.0, -1.0, 1.0) * WPos.xyz - float3(1.0, -1.0, 1.0) * _CameraPos.xyz;
	Output.EnvMap = reflect(WPos.xyz - _CameraPos.xyz, float3(0.0, 1.0, 0.0));

	return Output;
}

float4 Hi_FullDetail_EnvMap_PS(Hi_VS2PS_FullDetail_EnvMap Input) : COLOR
{
	#if LIGHTONLY
		float4 AccumLights = tex2Dproj(Sampler_1_Clamp, Input.Tex1);
		float4 Light = 2.0 * AccumLights.w * _SunColor + AccumLights;
		float4 Component = tex2D(Sampler_2_Clamp, Input.Tex0.xy);
		float ChartContrib = dot(_ComponentSelector, Component);
		return ChartContrib * Light;
	#else
		#if DEBUGTERRAIN
			return float4(0.0, 1.0, 0.0, 1.0);
		#endif

		float4 AccumLights = tex2Dproj(Sampler_1_Clamp, Input.Tex1);

		// tl: 2* moved later in shader to avoid clamping at -+2.0 in ps1.4
		float3 Light;
		float3 ColorMap;
		if (FogColor.r < 0.01)
		{
			// On thermals no shadows
			Light = 2.0 * _SunColor.rgb + AccumLights.rgb;
			// And gray color
			ColorMap = 0.333;
		}
		else
		{
			Light = 2.0 * AccumLights.w * _SunColor.rgb + AccumLights.rgb;
			ColorMap = tex2D(Sampler_0_Clamp, Input.Tex0.xy);
		}

		float4 Component = tex2D(Sampler_2_Clamp, Input.Tex6);
		float ChartContrib = dot(_ComponentSelector, Component);
		float4 DetailMap = tex2D(Dyn_Sampler_3_Wrap, Input.Tex3.xy);

		#if HIGHTERRAIN
			float4 LowComponent = tex2D(Sampler_5_Clamp, Input.Tex6);
			float4 YPlaneLowDetailmap = tex2D(Sampler_4_Wrap, Input.Tex5.xy);
			float4 XPlaneLowDetailmap = tex2D(Sampler_4_Wrap, Input.Tex3.xy);
			float4 ZPlaneLowDetailmap = tex2D(Sampler_4_Wrap, Input.Tex0.wz);
			float LowDetailMap = lerp(0.5, YPlaneLowDetailmap.z, LowComponent.x*Input.FogAndFade2.y);
		#else
			float4 YPlaneLowDetailmap = tex2D(Sampler_4_Wrap, Input.Tex5.xy);

			// tl: do lerp in 1 MAD by precalculating constant factor in vShader
			float LowDetailMap = 2.0 * YPlaneLowDetailmap.z * Input.BlendValueAndFade.y + Input.FogAndFade2.z;
		#endif

		#if HIGHTERRAIN
			float Mounten =	(XPlaneLowDetailmap.y * Input.BlendValueAndFade.x) +
							(YPlaneLowDetailmap.x * Input.BlendValueAndFade.y) +
							(ZPlaneLowDetailmap.y * Input.BlendValueAndFade.z);
			LowDetailMap *= (4.0 * lerp(0.5, Mounten, LowComponent.z));
			float3 BothDetailmap = DetailMap * LowDetailMap;
			float3 DetailOut = lerp(2.0 * BothDetailmap, LowDetailMap, Input.BlendValueAndFade.w);
		#else
			// tl: lerp optimized to handle 2*c*low + (2-2c)*detail, factors sent from vs
			float3 DetailOut = LowDetailMap*Input.BlendValueAndFade.x + 2*DetailMap*Input.BlendValueAndFade.z;
		#endif

		float3 OutColor = DetailOut * ColorMap * Light;
		float4 EnvMapColor = texCUBE(Sampler_6_Cube, Input.EnvMap);

		#if HIGHTERRAIN
			OutColor = lerp(OutColor, EnvMapColor, DetailMap.w * (1.0 - Input.BlendValueAndFade.w)) * 2.0;
		#else
			OutColor = lerp(OutColor, EnvMapColor, DetailMap.w * (1.0 - Input.FogAndFade2.y)) * 2.0;
		#endif

		OutColor = lerp(FogColor, OutColor, Input.FogAndFade2.x);
		return float4(ChartContrib * OutColor, ChartContrib);
	#endif
}




struct VS2PS_Hi_PerPixelPointLight
{
	float4 Pos : POSITION;
	float3 WPos : TEXCOORD0;
	float3 Normal : TEXCOORD1;
};

VS2PS_Hi_PerPixelPointLight Hi_PerPixelPointLight_VS(APP2VS_Shared_Default Input)
{
	VS2PS_Hi_PerPixelPointLight Output;

	float4 WPos;
	WPos.xz = (Input.Pos0.xy * _ScaleTransXZ.xy) + _ScaleTransXZ.zw;
	// tl: Trans is always 0, and MADs cost more than MULs in certain cards.
	WPos.yw = Input.Pos1.xw * _ScaleTransY.xy;

	float YDelta, InterpVal;
	// Geo_MorphPosition(WPos, Input.MorphDelta, YDelta, InterpVal);
	Geo_MorphPosition(WPos, Input.MorphDelta, Input.Pos0.z, YDelta, InterpVal);

	// tl: output HPos as early as possible.
 	Output.Pos = mul(WPos, _ViewProj);

 	// tl: uncompress normal
 	Input.Normal = Input.Normal * 2.0 - 1.0;

 	Output.Normal = Input.Normal;
 	Output.WPos = WPos.xyz;

	return Output;
}

float4 Hi_PerPixelPointLight_PS(VS2PS_Hi_PerPixelPointLight Input) : COLOR
{
	return float4(calcPVPointTerrain(Input.WPos, Input.Normal), 0) * 0.5;
}

float4 Hi_DirectionalLightShadows_PS(VS2PS_Shared_DirectionalLightShadows Input) : COLOR
{
	float4 LightMap = tex2D(Sampler_0_Clamp, Input.Tex0);

	float4 AvgShadowValue = getShadowFactor(ShadowMapSampler, Input.ShadowTex);

	float4 Light = saturate(LightMap.z * _GIColor * 2.0) * 0.5;
	if (AvgShadowValue.z < LightMap.y)
		//Light.w = 1-saturate(4-Input.Z.x)+AvgShadowValue.x;
		Light.w = AvgShadowValue.z;
	else
		Light.w = LightMap.y;

	return Light;
}

technique Hi_Terrain
{
	pass ZFillLightMap // p0
	{
		CullMode = CW;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESS;
		AlphaBlendEnable = FALSE;

		#if IS_NV4X
			StencilEnable = TRUE;
			StencilFunc = NOTEQUAL;
			StencilRef = 0xa;
			StencilPass = KEEP;
			StencilZFail = KEEP;
			StencilFail = KEEP;
		#endif

		VertexShader = compile vs_3_0 Shared_ZFillLightMap_VS();
		PixelShader = compile ps_3_0 Shared_ZFillLightMap_1_PS();
	}

	pass pointlight		//p1
	{
		CullMode = CW;
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;

		#if IS_NV4X
			StencilEnable = TRUE;
			StencilFunc = NOTEQUAL;
			StencilRef = 0xa;
			StencilPass = KEEP;
			StencilZFail = KEEP;
			StencilFail = KEEP;
		#endif

		VertexShader = compile vs_3_0 Shared_PointLight_VS();
		PixelShader = compile ps_3_0 Shared_PointLight_PS();
	}

	pass {} // spotlight (removed) p2

	pass LowDiffuse //p3
	{
		CullMode = CW;
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;
		AlphaBlendEnable = FALSE;
		AlphaTestEnable = FALSE;
		// FillMode = WireFrame;

		#if IS_NV4X
			StencilEnable = TRUE;
			StencilFunc = NOTEQUAL;
			StencilRef = 0xa;
			StencilPass = KEEP;
			StencilZFail = KEEP;
			StencilFail = KEEP;
		#endif

		VertexShader = compile vs_3_0 Shared_LowDetail_VS();
		PixelShader = compile ps_3_0 Shared_LowDetail_PS();
	}

	pass FullDetail // p4
	{
		CullMode = CW;
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;
		AlphaTestEnable = TRUE;
		AlphaFunc = GREATER;
		AlphaRef = 0;
		// ColorWriteEnable = RED|BLUE|GREEN|ALPHA;
		// FillMode = WireFrame;

		#if IS_NV4X
			StencilEnable = TRUE;
			StencilFunc = NOTEQUAL;
			StencilRef = 0xa;
			StencilPass = KEEP;
			StencilZFail = KEEP;
			StencilFail = KEEP;
		#endif

		VertexShader = compile vs_3_0 Hi_FullDetail_VS();
		PixelShader = compile ps_3_0 Hi_FullDetail_PS();
	}

	pass FullDetailMounten // p5
	{
		CullMode = CW;
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;

		#if IS_NV4X
			StencilEnable = TRUE;
			StencilFunc = NOTEQUAL;
			StencilRef = 0xa;
			StencilPass = KEEP;
			StencilZFail = KEEP;
			StencilFail = KEEP;
		#endif

		VertexShader = compile vs_3_0 Hi_FullDetail_Mounten_VS();
		PixelShader = compile ps_3_0 Hi_FullDetail_Mounten_PS();
	}

	pass {} // p6 tunnels (removed)

	pass DirectionalLightShadows // p7
	{
		CullMode = CW;
		//ColorWriteEnable = RED|BLUE|GREEN|ALPHA;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
 		AlphaBlendEnable = FALSE;

		#if IS_NV4X
			StencilEnable = TRUE;
			StencilFunc = NOTEQUAL;
			StencilRef = 0xa;
			StencilPass = KEEP;
			StencilZFail = KEEP;
			StencilFail = KEEP;
		#endif

		VertexShader = compile vs_3_0 Shared_DirectionalLightShadows_VS();
		PixelShader = compile ps_3_0 Hi_DirectionalLightShadows_PS();
	}

	pass {} // DirectionalLightShadowsNV (removed) //p8
	pass DynamicShadowmap {} // Obsolete // p9
	pass {} // p10

	pass FullDetailWithEnvMap	//p11
	{
		CullMode = CW;
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;
		AlphaTestEnable = TRUE;
		AlphaFunc = GREATER;
		AlphaRef = 0;
		// ColorWriteEnable = RED|BLUE|GREEN|ALPHA;

		#if IS_NV4X
			StencilEnable = TRUE;
			StencilFunc = NOTEQUAL;
			StencilRef = 0xa;
			StencilPass = KEEP;
			StencilZFail = KEEP;
			StencilFail = KEEP;
		#endif

		VertexShader = compile vs_3_0 Hi_FullDetail_EnvMap_VS();
		PixelShader = compile ps_3_0 Hi_FullDetail_EnvMap_PS();
	}

	pass {} // mulDiffuseFast (removed) p12

	pass PerPixelPointlight // p13
	{
		CullMode = CW;
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;

		#if IS_NV4X
			StencilEnable = TRUE;
			StencilFunc = NOTEQUAL;
			StencilRef = 0xa;
			StencilPass = KEEP;
			StencilZFail = KEEP;
			StencilFail = KEEP;
		#endif

		VertexShader = compile vs_3_0 Hi_PerPixelPointLight_VS();
		PixelShader = compile ps_3_0 Hi_PerPixelPointLight_PS();
	}

	pass underWater // p14
	{
		CullMode = CW;
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;
		AlphaTestEnable = TRUE;
		AlphaRef = 15; // tl: leave cap above 0 for better results
		AlphaFunc = GREATER;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

		#if IS_NV4X
			StencilEnable = TRUE;
			StencilFunc = NOTEQUAL;
			StencilRef = 0xa;
			StencilPass = KEEP;
			StencilZFail = KEEP;
			StencilFail = KEEP;
		#endif

		VertexShader = compile vs_3_0 Shared_UnderWater_VS();
		PixelShader = compile ps_3_0 Shared_UnderWater_PS();
	}

	pass ZFillLightMap2 // p15
	{
		//note: ColorWriteEnable is disabled in code for this
		CullMode = CW;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESS;
		AlphaBlendEnable = FALSE;

		VertexShader = compile vs_3_0 Shared_ZFillLightMap_VS();
		PixelShader = compile ps_3_0 Shared_ZFillLightMap_2_PS();
	}
}
