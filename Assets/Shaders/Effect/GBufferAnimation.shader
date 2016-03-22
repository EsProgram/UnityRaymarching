Shader "ImageEffect/GBufferAnimation"
{
	SubShader
	{
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

			sampler2D _CameraGBufferTexture0;
			sampler2D _CameraGBufferTexture1;
			sampler2D _CameraGBufferTexture2;
			sampler2D _CameraGBufferTexture3;
			sampler2D _CameraDepthTexture;
			float _DepthFade;
			float _ColorFade;

			float4 frag (v2f i) : SV_Target
			{
				float w = 1 / _ScreenParams.x;
				float h = 1 / _ScreenParams.y;

				float depth = tex2D(_CameraDepthTexture, i.uv).r;
				float4 col = tex2D(_CameraGBufferTexture3, i.uv);


				return depth * min(abs(_SinTime.x)*(1 - i.uv.y), 0.5) + col * max(abs(_SinTime.y) * (1 - i.uv.x), 0.1) + min(_SinTime.y - 0.3, 0);
			}
			ENDCG
		}
	}
}
