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

#endif //CAMERA_INFOMATION