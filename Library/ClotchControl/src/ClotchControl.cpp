/*****************************************************
    Clotch Control
    
    Copyright(c) 2015 Seiya Iwasaki
    
    This software is released under the MIT License.
    http://opensource.org/licenses/mit-license.php
*****************************************************/

/*--- �C���N���[�h ---*/
#include "CapacitiveSensor.h"
#include "ClotchControl.h"
 

/*--- �R���X�g���N�^ ---*/
ClotchControl::ClotchControl(int cSensorPin, int cTransPin, int cRecievePin) {
	this->type				= 0;										// ���
	this->BUFFER_LENGTH		= 5;										// �o�b�t�@�̃T�C�Y
	this->INDEX_OF_MIDDLE	= this->BUFFER_LENGTH / 2;					// �o�b�t�@�̒����̃C���f�b�N�X
	this->vindex			= 0;										// �d���l�o�b�t�@�p�C���f�b�N�X
	this->cindex			= 0;										// �Ód�e�ʃo�b�t�@�p�C���f�b�N�X
	this->vb1				= new long[this->BUFFER_LENGTH];			// �d���l�o�b�t�@1
	this->vb2				= new long[this->BUFFER_LENGTH];			// �d���l�o�b�t�@2
	this->cb				= new long[this->BUFFER_LENGTH];			// �Ód�e�ʃo�b�t�@
	this->volt				= 0;										// �X���[�W���O��̓d������l
	this->cap				= 0;										// �X���[�W���O��̐Ód�e�ʒl

	this->cSensorPin		= cSensorPin;									// �d������p�A�i���O���̓s��
	this->cTransPin			= cTransPin;									// �Ód�e�ʃZ���T�̑��M�s��
	this->cRecievePin		= cRecievePin;									// �Ód�e�ʃZ���T�̎�M�s��
	this->cThresholdH		= 100;											// �Ód�e�ʂ������l High
	this->cThresholdL		= 50;											// �Ód�e�ʂ������l Low
	this->cSamplingNum		= 30;											// �Ód�e�ʃZ���T���E���m�C�Y�̗�
	this->sensor			= new CapacitiveSensor(cTransPin, cRecievePin);	// �Ód�e�ʃZ���T�N���X

	this->preTouched		= false;									// �O��̃^�b�`���
	this->curTouched		= false;									// ����̃^�b�`���
}


/*--- �Ód�e�ʃZ���T�̃L�����u���[�V���� ---*/
void ClotchControl::sensorCalibrate(){
	sensor->reset_CS_AutoCal();
}


/*--- �Ód�e�ʃZ���T�̃I�[�g�L�����u���[�V�����̃I�t ---*/
void ClotchControl::offAutoCalibrate(){
	sensor->set_CS_AutocaL_Millis(0xFFFFFFFF);
}


/*--- �o�b�t�@�̃Z�b�g�A�b�v ---*/
void ClotchControl::setupBuffer(){
	// �d���l�o�b�t�@�̃Z�b�g�A�b�v
	int loopCount = BUFFER_LENGTH * BUFFER_LENGTH;
	for(int i = 0; i < loopCount; i++){
		this->senseVolt();
	}
	// �Ód�e�ʃo�b�t�@�̃Z�b�g�A�b�v
	for(int i = 0; i < BUFFER_LENGTH; i++){
		this->senseCap();
	}
}


/*--- �������l�̍Đݒ� ---*/
void ClotchControl::resetThreshold(int low, int high){
	cThresholdL = low;
	cThresholdH = high;
}


/*--- �T���v�����O���̍Đݒ� ---*/
void ClotchControl::resetSamplingNum(int num){
	cSamplingNum = num;
}


/*--- �X�C�b�`�̎�ނ�ۑ� ---*/
void ClotchControl::saveSwitchType(int t){
	type = t;
}


/*--- �d���𑪒� ---*/
void ClotchControl::senseVolt(){
	analogRead(cSensorPin);					// �A�i���O���͂̋�ǂ�

	long raw = analogRead(cSensorPin);		// ���肳�ꂽ�d���l���i�[
	vb1[vindex]	= raw;						// ����l���o�b�t�@�ɒ~��

	long average = smoothByMeanFilter(vb1);	// �X���[�W���O����
	vb2[vindex]	= average;					// ����l�̕��ϒl��~��
	
	vindex = (vindex + 1) % BUFFER_LENGTH;	// �C���f�b�N�X�X�V
	volt = smoothByMeanFilter(vb2);			// �d������l�i�X���[�W���O�ς݁j���i�[
}


/*--- �Ód�e�ʂ𑪒� ---*/
void ClotchControl::senseCap(){
	long raw = sensor->capacitiveSensor(cSamplingNum);	// �Ód�e�ʑ���l���i�[
	cb[cindex] = raw;									// ����l��~��
	
	cindex = (cindex + 1) % BUFFER_LENGTH;				// �C���f�b�N�X�X�V
	cap = smoothByMeanFilter(cb);						// �Ód�e�ʑ���l�i�X���[�W���O�ς݁j���i�[
}


/*--- �X���[�W���O�����i���ω��j ---*/
long ClotchControl::smoothByMeanFilter(long *box){
	long sum = 0;		// ����l�̍��v�l���i�[

	// ���v�����߂�
	for(int i = 0; i < BUFFER_LENGTH; i++){
		sum += box[i];
	}

	// ����l�̕��ϒl��Ԃ�
	return (long)(sum / BUFFER_LENGTH);
}


/*--- �^�b�`���� ---*/
void ClotchControl::decideTouched(){
	// �X�C�b�`�����݂���Ƃ�
	if(type != 0){
		if(cap > cThresholdH){          // �������l�̏���l���Ód�e�ʒl�������Ƃ�
			curTouched = true;
		}else if(cap < cThresholdL){    // �������l�̉����l���Ód�e�ʒl���Ⴂ�Ƃ�
			curTouched = false;
		}else{						    // �������l�̏���Ɖ����̊ԂɐÓd�e�ʒl������Ƃ�
			curTouched = preTouched;   
		}
		preTouched = curTouched;	    // ����̃^�b�`��Ԃ�ۑ�
	}else{
		preTouched = false;
		curTouched = false;
	}
}


/*--- �d���l���擾 ---*/
long ClotchControl::getVolt(){
	return volt;
}


/*--- �X�C�b�`�̎�ނ��擾 ---*/
int ClotchControl::getType(){
	return type;
}


/*--- �Ód�e�ʒl���擾 ---*/
long ClotchControl::getCap(){
	return cap;
}


/*--- �^�b�`��Ԃ̎擾 ---*/
bool ClotchControl::getTouched(){
	return curTouched;
}









