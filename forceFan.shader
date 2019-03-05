Shader "JackyGun/forceFan"
{
	Properties
	{
		_Anim ("anim", Float) = 1
	}
		SubShader
	{
		Tags{ "RenderType" = "Opaque" }
		LOD 100

		Pass
	{
		CGPROGRAM
#pragma target 5.0
#pragma vertex mainVS
#pragma hull mainHS
#pragma domain mainDS
#pragma geometry mainGS
#pragma fragment mainFS

#include "UnityCG.cginc"

#define TESS 16 // [Max 64] 連続&&一意なIDは64が限界っぽい

	float _Anim;

	// Structure
	struct VS_IN
	{
		float4 pos   : POSITION;
	};

	struct VS_OUT
	{
		float4 pos    : POSITION;
	};

	struct CONSTANT_HS_OUT
	{
		float Edges[4] : SV_TessFactor;
		float Inside[2] : SV_InsideTessFactor;
	};

	struct HS_OUT
	{
	};

	struct DS_OUT
	{
		uint pid : PID;	// GeometryShaderに実行用の一意連続なIDを発行する
	};

	struct GS_OUT
	{
		float4 vertex : SV_POSITION;
		float2 uv : TEXCOORD0;
		float4 color : COLOR0;
	};

	// Main
	VS_OUT mainVS(VS_IN In)
	{
		VS_OUT Out;
		Out.pos = In.pos;
		return Out;
	}

	CONSTANT_HS_OUT mainCHS()
	{
		CONSTANT_HS_OUT Out;

		int t = TESS + 1;
		Out.Edges[0] = t;
		Out.Edges[1] = t;
		Out.Edges[2] = t;
		Out.Edges[3] = t;
		Out.Inside[0] = t;
		Out.Inside[1] = t;

		return Out;
	}

	[domain("quad")]
	[partitioning("pow2")]
	[outputtopology("point")]
	[outputcontrolpoints(4)]
	[patchconstantfunc("mainCHS")]
	HS_OUT mainHS()
	{
	}

	[domain("quad")]
	DS_OUT mainDS(CONSTANT_HS_OUT In, const OutputPatch<HS_OUT, 4> patch, float2 uv : SV_DomainLocation)
	{
		DS_OUT Out;
		Out.pid = (uint)(uv.x * TESS) + ((uint)(uv.y * TESS) * TESS);
		return Out;
	}

	[maxvertexcount(3)]
	void mainGS(point DS_OUT input[1], inout TriangleStream<GS_OUT> outStream)
	{

		GS_OUT o;
		DS_OUT v = input[0];
		uint id = v.pid;

		// 一意なidを用いて頑張って扇子の座標をGeometryShaderが作ってくれる
		const uint P_ONE = ((4 + 4) * 2);

		const float P0_W = 0.02f;
		const float P0_HU = 1.0f;
		const float P0_HD = -0.3f;

		const float P1_W = 0.01f;
		const float P1_HU = 0.4f;
		const float P1_HD = 0.05f;

		const float P_Z = 0.005f;
		const float D_Z = 0.0001f;

		uint p = id / P_ONE;
		uint q = id % P_ONE;
		uint r = q / 8 % 2;
		uint s = q / 4 % 2;
		uint t = q / 2 % 2;
		uint u = q / 1 % 2;

		float angle = 2.f * _Anim;
		float aC = angle * (p + 0) / 16;
		float aN = angle * (p + 1) / 16;

		float4 color[2] = { float4(0.752f, 1.0f, 0.93f, 1.0f), float4(0.05f, 0.01f, 0.02f, 1.0f) };

		float3 main_vertex[6] = {
			s ? float3(-P1_W * cos(aC) - +P1_HU * sin(aC), +P1_HU * cos(aC) + -P1_W * sin(aC), P_Z * (p + 0) + D_Z) : float3(-P0_W * cos(aC) - +P0_HU * sin(aC), +P0_HU * cos(aC) + -P0_W * sin(aC), P_Z * (p + 0)),
			s ? float3(+P1_W * cos(aC) - +P1_HU * sin(aC), +P1_HU * cos(aC) + +P1_W * sin(aC), P_Z * (p + 0) + D_Z) : float3(+P0_W * cos(aC) - +P0_HU * sin(aC), +P0_HU * cos(aC) + +P0_W * sin(aC), P_Z * (p + 0)),
			s ? float3(-P1_W * cos(aC) - -P1_HD * sin(aC), -P1_HD * cos(aC) + -P1_W * sin(aC), P_Z * (p + 0) + D_Z) : float3(-P0_W * cos(aC) - -P0_HD * sin(aC), -P0_HD * cos(aC) + -P0_W * sin(aC), P_Z * (p + 0)),
			s ? float3(+P1_W * cos(aC) - -P1_HD * sin(aC), -P1_HD * cos(aC) + +P1_W * sin(aC), P_Z * (p + 0) + D_Z) : float3(+P0_W * cos(aC) - -P0_HD * sin(aC), -P0_HD * cos(aC) + +P0_W * sin(aC), P_Z * (p + 0)),
			s ? float3(-P1_W * cos(aN) - +P1_HU * sin(aN), +P1_HU * cos(aN) + -P1_W * sin(aN), P_Z * (p + 1) + D_Z) : float3(-P0_W * cos(aN) - +P0_HU * sin(aN), +P0_HU * cos(aN) + -P0_W * sin(aN), P_Z * (p + 1)),
			s ? float3(-P1_W * cos(aN) - -P1_HD * sin(aN), -P1_HD * cos(aN) + -P1_W * sin(aN), P_Z * (p + 1) + D_Z) : float3(-P0_W * cos(aN) - -P0_HD * sin(aN), -P0_HD * cos(aN) + -P0_W * sin(aN), P_Z * (p + 1)),
		};

		float2 uv[6] = {
			float2(-1, +1),
			float2(+1, +1),
			float2(-1, -1),
			float2(+1, -1),
			float2(-1, +1),
			float2(-1, -1),
		};

		int3 index = 
			r ?
			  t ?
			    u ? int3(3, 4, 5)
			      : int3(5, 4, 3)
			    :
			    u ? int3(3, 4, 1)
			      : int3(1, 4, 3)
			:
			  t ?
			    u ? int3(3, 1, 2)
			      : int3(2, 1, 3)
			  :
			    u ? int3(2, 1, 0)
			      : int3(0, 1, 2)
		;

		if (r && s || r && p == 16 || p > 16)
			return;

		o.vertex = UnityObjectToClipPos(float4(main_vertex[index.x], 1));
		o.uv = uv[index.x];
		o.color = color[s];
		outStream.Append(o);
			
		o.vertex = UnityObjectToClipPos(float4(main_vertex[index.y], 1));
		o.uv = uv[index.y];
		o.color = color[s];;
		outStream.Append(o);

		o.vertex = UnityObjectToClipPos(float4(main_vertex[index.z], 1));
		o.uv = uv[index.z];
		o.color = color[s];;
		outStream.Append(o);

		outStream.RestartStrip();

	}

	float4 mainFS(GS_OUT i) : SV_Target
	{
		float4 col = i.color;
		col.rgb *= (abs(i.uv.x) < 0.9) * (abs(i.uv.y) < 0.9);
		return col;
	}
		ENDCG
	}
	}
}
