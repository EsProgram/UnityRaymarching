Shader "Raymarching/e#23658"
{
	Properties{
		[KeywordEnum(NONE,KALEIDOSCOPIC_IFS,TGLAD_FORMULA,HARTVERDRAHTET,PSEUDO_KLEINIAN,PSEUDO_KNIGHTYAN)]
		_MAP("Distacne Func", Float) = 0
	}
	SubShader
	{
		Pass
		{
			Tags { "LightMode" = "Deferred" }
			//G-Bufferへの描画はStencil を有効にして7bit目を立てる(128を足す)。
			//Stencilの7bit目が立っていないピクセルはライティングされない。
			//なので常にステンシルテストに合格させ、128で上書きする。
			Stencil
			{
				Comp Always
				Pass Replace
				Ref 128
			}

			CGPROGRAM

#pragma shader_feature _ _MAP_KALEIDOSCOPIC_IFS _MAP_TGLAD_FORMULA _MAP_HARTVERDRAHTET _MAP_PSEUDO_KLEINIAN _MAP_PSEUDO_KNIGHTYAN
#pragma vertex vert
#pragma fragment frag
#pragma target 3.0

#include "Raymarching.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 screen : TEXCOORD0;
			};

			//MRTにより出力するG-Buffer
			struct gbuffer
			{
				half4 diffuse : SV_Target0; // rgb: diffuse,  a: occlusion
				half4 specular : SV_Target1; // rgb: specular, a: smoothness
				half4 normal : SV_Target2; // rgb: normal,   a: unused
				half4 emission : SV_Target3; // rgb: emission, a: unused
				float depth : SV_Depth;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = v.vertex;
				//座標変換の必要なし(Command BufferでMeshをそのまま描画する)
				//フラグメントシェーダーではTEXCOORDはラスタライズにより各ピクセルへの位置を取得できる
				o.screen = v.vertex;
				return o;
			}

			gbuffer frag(v2f i)
			{
				const float HIT_DISTANCE = 0.001;

				float3 rayDir = compute_ray_dir(i.screen);//ピクセル位置とカメラからレイを飛ばす方向ベクトルを算出
				float3 camPos = get_cam_pos();//カメラ位置の取得
				float maxDist = get_cam_visibl_len();//カメラの最大描画範囲取得

				float distance = 0;//距離関数から返却される図形と点との最短距離
				float len = 0;//点(Ray)の進んだ長さ
				float3 pos = camPos + _ProjectionParams.y * rayDir;//点(Ray)開始位置

				//レイを飛ばす処理
				for (int count = 0; count < 128; ++count) {
					distance = distance_func(pos);
					len += distance;
					pos += rayDir * distance;
					//レイがヒットした || レイの長さが描画範囲を超えた
					if (distance < HIT_DISTANCE || len > maxDist)
						break;
				}

				//レイがヒットしなかった場合はclip
				clip(-distance + HIT_DISTANCE);

				//レイがヒットした位置からデプスと法線を計算
				float depth = compute_depth(mul(UNITY_MATRIX_VP, float4(pos, 1)));
				float3 normal = compute_normal(pos);

				//MRTによるG-Buffer出力(Depth,Normal以外は適当)
				gbuffer o;
				o.diffuse = float4(0.5, 0.5, 0.5, 0.5);
				o.specular = float4(1, 1, 1, 1);
				o.emission = float4(0.1, 0.1, 0.1, 1);
				o.depth = depth;
				o.normal = float4(normal, 1);
				return o;
			}
			ENDCG
		}
	}
}