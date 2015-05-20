/*****************************************************
    Clotch Control
    
    Copyright(c) 2015 Seiya Iwasaki
    
    This software is released under the MIT License.
    http://opensource.org/licenses/mit-license.php
*****************************************************/


#ifndef ClotchControl_h
#define ClotchControl_h
#include "arduino.h"
 
class ClotchControl {
	// �R���X�g���N�^
	public:
		ClotchControl(int BUFFER_LENGTH,
					  int sensorPin,
					  int transPin,
					  int recievePin,
					  int thresholdH,
					  int thresholdL,
					  int NOISE);
  
	// ���\�b�h
	public:
		void sensorCalibrate(void);			// �Ód�e�ʃZ���T�̃L�����u���[�V����
		void setupBuffer(void);				// �o�b�t�@�̃Z�b�g�A�b�v
		void senseVolt(void);				// �d���𑪒�
		void senseCap(void);				// �Ód�e�ʂ𑪒�
		long smoothByMeanFilter(long*);		// �X���[�W���O�����i���ω��j
		long getVolt(void);					// �d���l���擾
		long getCap(void);					// �Ód�e�ʒl���擾
		bool getTouched(void);				// �^�b�`����
  
	// �t�B�[���h
	private:
		int type;					// ���
		int BUFFER_LENGTH;			// �o�b�t�@�̃T�C�Y
		int INDEX_OF_MIDDLE;		// �o�b�t�@�̒����̃C���f�b�N�X
		int vindex;					// �d���l�o�b�t�@�p�C���f�b�N�X
		int cindex;					// �Ód�e�ʃo�b�t�@�p�C���f�b�N�X
		long *vb1;					// �d���l�o�b�t�@1
		long *vb2;					// �d���l�o�b�t�@2
		long *cb;					// �Ód�e�ʃo�b�t�@
		long volt;					// �X���[�W���O��̓d������l
		long cap;					// �X���[�W���O��̐Ód�e�ʒl

		int sensorPin;				// �d������p�A�i���O���̓s��
		int transPin;			    // �Ód�e�ʃZ���T�̑��M�s��
		int recievePin;			    // �Ód�e�ʃZ���T�̎�M�s��
		int thresholdH;				// �Ód�e�ʂ������l High
		int thresholdL;				// �Ód�e�ʂ������l Low
		int NOISE;					// �Ód�e�ʃZ���T���E���m�C�Y�̗�
		CapacitiveSensor *sensor;	// �Ód�e�ʃZ���T�N���X

		bool preTouched;			// �O��̃^�b�`���
		bool curTouched;			// ����̃^�b�`���
};
 
#endif