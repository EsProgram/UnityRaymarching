Shader "ImageEffect/Blur"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Diff ("Diff", Range(0,10)) = 1
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.uv;
				return o;
			}

			sampler2D _MainTex;
			float _Diff;

			fixed4 frag (v2f i) : SV_Target
			{
				float diff_x = _Diff / _ScreenParams.x;
				float diff_y = _Diff / _ScreenParams.y;
				float x = i.uv.x;
				float y = i.uv.y;

				fixed4 col =
					tex2D(_MainTex, i.uv) +
					tex2D(_MainTex, float2(x + diff_x, y)) +
					tex2D(_MainTex, float2(x - diff_x, y)) +
					tex2D(_MainTex, float2(x, y + diff_y)) +
					tex2D(_MainTex, float2(x, y - diff_y));

				return col * 0.2;
			}
			ENDCG
		}
	}
}
