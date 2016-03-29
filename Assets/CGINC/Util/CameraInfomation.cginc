#ifndef CAMERA_INFOMATION
#define CAMERA_INFOMATION

#include "UnityCG.cginc"
#include "UnityStandardCore.cginc"

//���[���h���W�n�̃J�����̈ʒu
float3 get_cam_pos() { return _WorldSpaceCameraPos; }
//�ϊ��s�񂩂�J�����̏����擾
float3 get_cam_fwd() { return -UNITY_MATRIX_V[2].xyz; }
float3 get_cam_up() { return UNITY_MATRIX_V[1].xyz; }
float3 get_cam_right() { return UNITY_MATRIX_V[0].xyz; }
float  get_cam_focal_len() { return abs(UNITY_MATRIX_P[1][1]); }
//_ProjectionParams��y�̓J������ClippingPlanes[Near]�Az��[Far]
//�J�����������_�����O���鋗�����Z�o����
float  get_cam_visibl_len() { return _ProjectionParams.z - _ProjectionParams.y; }

//�J���� -> �����_�����O����s�N�Z��
float3 camera_to_screen_dir(float2 screen)
{
	//UNITY_UV_START_AT_TOP��V�l�̃g�b�v�ʒu
	//Direct3D�ł�1�A OpenGL�n�ł�0
#if UNITY_UV_STARTS_AT_TOP
	//Direct3D�̏ꍇ�A���_��y���Ώ̂ɔ��]�����邱�Ƃŗ���
	screen.y *= -1.0;
#endif
	//_ScreenParams��x�̓����_�����O�^�[�Q�b�g�̃s�N�Z���̕��Ay�̓s�N�Z���̍���
	screen.x *= _ScreenParams.x / _ScreenParams.y;

	//�J�����̏��ƃs�N�Z���ʒu���� �J���� -> �s�N�Z�� �̃��C�̕����x�N�g�������߂�
	float3 camDir = get_cam_fwd();
	float3 camUp = get_cam_up();
	float3 camSide = get_cam_right();
	float  focalLen = get_cam_focal_len();

	return normalize((camSide * screen.x) + (camUp * screen.y) + (camDir * focalLen));
}

#endif //CAMERA_INFOMATION