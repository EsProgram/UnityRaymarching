#include "RaymarchStructure.cginc"
#include "DistanceFunction.cginc"
#include "CameraInfomation.cginc"

#ifndef RAY_HIT_DISTANCE
#define RAY_HIT_DISTANCE 0.001
#endif

//�g�p����DistanceFunction��ύX�������ꍇ��
//CUSTOM_DISTANCE_FUNCTION���`����
#if !defined(CUSTOM_DISTANCE_FUNCTION)
#define CUSTOM_DISTANCE_FUNCTION(p) __default_distance_func(p)
#endif //CUSTOM_DISTANCE_FUNCTION

//�g�p����Transform��ύX�������ꍇ��
//CUSTOM_TRANSFORM���`����
#if !defined(CUSTOM_TRANSFORM)
#define CUSTOM_TRANSFORM(p, r, s) init_transform(p, r, s)
#endif //CUSTOM_TRANSFORM

//��ԓ��̓_�̈ʒu���󂯎��, �}�`�Ɠ_�Ƃ̍ŒZ������Ԃ�
//���̊֐��̒l��0�ƂȂ�_�̏W�����}�`�̕\�ʂƂȂ�B
//�܂�0�ɋ߂��l��Ԃ����ꍇ�͕`�悳��邱�ƂɂȂ�
float __default_distance_func(float3 pos)
{
	return box(pos, 1);
}

//���C�̐i�ނׂ��������Z�o����
//�J���� -> �����_�����O����s�N�Z��
float3 compute_ray_dir(float2 screen)
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

//���f���̈ʒu�A��]�A�X�P�[������
//(ObjectSpace�̏ꍇ�APosition��Rotation�̓I�u�W�F�N�g��Transform�Ɠ����������ق����킩��₷�����H)
float3 localize(float3 p, transform tr)
{
	//Position
	p -= tr.position;

	//Rotation
	float3 x = rotate_x(p, radians(tr.rotation.x));
	float3 xy = rotate_y(x, radians(tr.rotation.y));
	float3 xyz = rotate_z(xy, radians(tr.rotation.z));
	p = xyz;

	//Scale
	p /= tr.scale;

	return p;
}

//����ʒu(���C���I�u�W�F�N�g�Ƀq�b�g�����ʒu)�̐[�x�l���擾����B
//depth�̎Z�o���@��Direct3D��OpenGL�n�ňႤ�B
float compute_depth(float4 pos)
{
#if UNITY_UV_STARTS_AT_TOP
	return pos.z / pos.w;
#else
	return (pos.z / pos.w) * 0.5 + 0.5;
#endif
}

//����ʒu(���C���I�u�W�F�N�g�Ƀq�b�g�����ʒu)�ɂ�����I�u�W�F�N�g�̖@�����擾����B
//x,y,z�͕Δ����ɂ���ċ��߂���B
//G-Bffer��normal(�@���o�b�t�@)�͕����Ȃ��f�[�^(RGBA 10, 10, 10, 2 bits)�Ŋi�[����邽��
//�i�[���� *0.5+0.5
//�擾���� *2.0-1.0
//���Ă��K�v������(�i�[���ɕ������Ȃ����A�擾���ɍČ�����)�B
float3 compute_normal(float3 pos)
{
	const float delta = 0.001;
	return normalize(float3(
		CUSTOM_DISTANCE_FUNCTION(pos + float3(delta, 0.0, 0.0)) - CUSTOM_DISTANCE_FUNCTION(pos + float3(-delta, 0.0, 0.0)),
		CUSTOM_DISTANCE_FUNCTION(pos + float3(0.0, delta, 0.0)) - CUSTOM_DISTANCE_FUNCTION(pos + float3(0.0, -delta, 0.0)),
		CUSTOM_DISTANCE_FUNCTION(pos + float3(0.0, 0.0, delta)) - CUSTOM_DISTANCE_FUNCTION(pos + float3(0.0, 0.0, -delta))))
		* 0.5 + 0.5;
}

//���C�}�[�`���s��
raymarch_out raymarch(float2 pos, transform tr, const int trial_num)
{
	raymarch_out o;

	float3 ray_dir = compute_ray_dir(pos);
	float3 cam_pos = get_cam_pos();
	float max_ray_dist = get_cam_visibl_len();

	o.ray_length = 0;
	o.ray_pos = cam_pos + _ProjectionParams.y * ray_dir;

	for (o.trial_count = 0; o.trial_count < trial_num; ++o.trial_count) {
		o.distance = CUSTOM_DISTANCE_FUNCTION(localize(o.ray_pos, tr));
		o.ray_length += o.distance;
		o.ray_pos += ray_dir * o.distance;
		if (o.distance < RAY_HIT_DISTANCE || o.ray_length > max_ray_dist)
			break;
	}
	return o;
}

v2f raymarch_vert(appdata v)
{
	v2f o;
#if OBJECT_SPACE_RAYMARCH
	o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
#else
	o.vertex = v.vertex;
#endif
	//���W�ϊ��̕K�v�Ȃ�(Command Buffer��Mesh�����̂܂ܕ`�悷��)
	//�t���O�����g�V�F�[�_�[�ł�TEXCOORD�̓��X�^���C�Y�ɂ��e�s�N�Z���ւ̈ʒu���擾�ł���
	o.screen = o.vertex;
	return o;
}

gbuffer raymarch_frag(v2f i)
{
	//w�͎ˉe��ԁi�������ԁj�ɂ��钸�_���W������Ŋ��邱�Ƃɂ��
	//�u���_���X�N���[���ɓ��e���邽�߂̗����̗̂̈�i-1��x��1�A-1��y��1������0��z��1�j�ɔ[�߂�v
	//�I�u�W�F�N�g�X�y�[�X�ł̃��C�}�[�`�ŕ`��̔j�]��h��
	i.screen.xy /= i.screen.w;

	raymarch_out ray_out;
	transform tr;
	tr = CUSTOM_TRANSFORM(0, 0, 1);

	ray_out = raymarch(i.screen.xy, tr, 100);
	//���C���q�b�g���Ȃ������ꍇ��clip
	clip(-ray_out.distance + RAY_HIT_DISTANCE);

	//���C���q�b�g�����ʒu����f�v�X�Ɩ@�����v�Z
	float depth = compute_depth(mul(UNITY_MATRIX_VP, float4(ray_out.ray_pos, 1)));
	float3 normal = compute_normal(localize(ray_out.ray_pos, tr));

	//MRT�ɂ��G-Buffer�o��(Depth,Normal�ȊO�͓K��)
	gbuffer gb_out;
	gb_out = init_gbuffer(0.5, 0.5, float4(normal, 1), 0, depth);

	return gb_out;
}