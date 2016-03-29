Shader "ImageEffect/Refrection"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Distance("Refrect Distance", Range(0,10)) = 2
		_Intensity("Intensity", Range(0,1)) = 1
		_Coef("Terination Correct Cofficient", Range(0,3)) = 0.8
	}
	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Assets/CGINC/Util/CameraInfomation.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 screen : TEXCOORD1;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.uv;
				o.screen = o.vertex;
				return o;
			}

			//sampler2D _MainTex;
			sampler2D _CameraGBufferTexture2;//Normal
			sampler2D _CameraDepthTexture;
			float _Distance;
			float _Intensity;
			float _Coef;

			fixed4 frag (v2f i) : SV_Target
			{
				i.screen /= i.screen.w;
#if UNITY_UV_STARTS_AT_TOP
				i.screen.y *= -1;
#endif


				float d0 = tex2D(_CameraDepthTexture, i.uv).r;
				float d0_linear_01 = Linear01Depth(d0);
				float d0_linear_eye = LinearEyeDepth(d0);
				float4 c0 = tex2D(_MainTex, i.uv);

				//深度値一定以上のものはそのまま出力を返す
				if (d0_linear_01 > 0.99)
					return c0;

				float3 a = camera_to_screen_dir(i.screen);//入射光
				float3 n = normalize(mul(UNITY_MATRIX_P, tex2D(_CameraGBufferTexture2, i.uv)));//法線
				n.z = 1 - n.z * get_cam_visibl_len();
				float3 b = normalize(reflect(a, n));//反射光

				float3 pos = float3(0, 0, -1) + a;

				const float3 DIST = b * _Distance;

				pos += DIST;
				//UVの端っこの方の場合、あまりDISTを加算しないよう係数をかける
				float coef = clamp(_Coef - length((i.uv * 2 - 1)), 0, 1);
				pos *= coef;

				float2 uv = i.uv + pos.xy;

				if (uv.x < 0 || uv.x > 1 || uv.y < 0 || uv.y > 1)
					return c0;

				float4 c1 = tex2D(_MainTex, uv);
				float d1 = 1 - pow(tex2D(_CameraDepthTexture, uv), 10);

				return c0 + (c1 * _Intensity * d1);
			}
			ENDCG
		}
	}
}
