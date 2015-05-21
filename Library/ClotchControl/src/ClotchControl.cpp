/*****************************************************
    Clotch Control
    
    Copyright(c) 2015 Seiya Iwasaki
    
    This software is released under the MIT License.
    http://opensource.org/licenses/mit-license.php
*****************************************************/

/*--- インクルード ---*/
#include "CapacitiveSensor.h"
#include "ClotchControl.h"
 

/*--- コンストラクタ ---*/
ClotchControl::ClotchControl(int cSensorPin, int cTransPin, int cRecievePin) {
	this->type				= 0;										// 種類
	this->BUFFER_LENGTH		= 5;										// バッファのサイズ
	this->INDEX_OF_MIDDLE	= this->BUFFER_LENGTH / 2;					// バッファの中央のインデックス
	this->vindex			= 0;										// 電圧値バッファ用インデックス
	this->cindex			= 0;										// 静電容量バッファ用インデックス
	this->vb1				= new long[this->BUFFER_LENGTH];			// 電圧値バッファ1
	this->vb2				= new long[this->BUFFER_LENGTH];			// 電圧値バッファ2
	this->cb				= new long[this->BUFFER_LENGTH];			// 静電容量バッファ
	this->volt				= 0;										// スムージング後の電圧測定値
	this->cap				= 0;										// スムージング後の静電容量値

	this->cSensorPin		= cSensorPin;									// 電圧測定用アナログ入力ピン
	this->cTransPin			= cTransPin;									// 静電容量センサの送信ピン
	this->cRecievePin		= cRecievePin;									// 静電容量センサの受信ピン
	this->cThresholdH		= 100;											// 静電容量しきい値 High
	this->cThresholdL		= 50;											// 静電容量しきい値 Low
	this->cSamplingNum		= 30;											// 静電容量センサが拾うノイズの量
	this->sensor			= new CapacitiveSensor(cTransPin, cRecievePin);	// 静電容量センサクラス

	this->preTouched		= false;									// 前回のタッチ状態
	this->curTouched		= false;									// 今回のタッチ状態
}


/*--- 静電容量センサのキャリブレーション ---*/
void ClotchControl::sensorCalibrate(){
	sensor->reset_CS_AutoCal();
}


/*--- 静電容量センサのオートキャリブレーションのオフ ---*/
void ClotchControl::offAutoCalibrate(){
	sensor->set_CS_AutocaL_Millis(0xFFFFFFFF);
}


/*--- バッファのセットアップ ---*/
void ClotchControl::setupBuffer(){
	// 電圧値バッファのセットアップ
	int loopCount = BUFFER_LENGTH * BUFFER_LENGTH;
	for(int i = 0; i < loopCount; i++){
		this->senseVolt();
	}
	// 静電容量バッファのセットアップ
	for(int i = 0; i < BUFFER_LENGTH; i++){
		this->senseCap();
	}
}


/*--- しきい値の再設定 ---*/
void ClotchControl::resetThreshold(int low, int high){
	cThresholdL = low;
	cThresholdH = high;
}


/*--- サンプリング数の再設定 ---*/
void ClotchControl::resetSamplingNum(int num){
	cSamplingNum = num;
}


/*--- スイッチの種類を保存 ---*/
void ClotchControl::saveSwitchType(int t){
	type = t;
}


/*--- 電圧を測定 ---*/
void ClotchControl::senseVolt(){
	analogRead(cSensorPin);					// アナログ入力の空読み

	long raw = analogRead(cSensorPin);		// 測定された電圧値を格納
	vb1[vindex]	= raw;						// 測定値をバッファに蓄積

	long average = smoothByMeanFilter(vb1);	// スムージング処理
	vb2[vindex]	= average;					// 測定値の平均値を蓄積
	
	vindex = (vindex + 1) % BUFFER_LENGTH;	// インデックス更新
	volt = smoothByMeanFilter(vb2);			// 電圧測定値（スムージング済み）を格納
}


/*--- 静電容量を測定 ---*/
void ClotchControl::senseCap(){
	long raw = sensor->capacitiveSensor(cSamplingNum);	// 静電容量測定値を格納
	cb[cindex] = raw;									// 測定値を蓄積
	
	cindex = (cindex + 1) % BUFFER_LENGTH;				// インデックス更新
	cap = smoothByMeanFilter(cb);						// 静電容量測定値（スムージング済み）を格納
}


/*--- スムージング処理（平均化） ---*/
long ClotchControl::smoothByMeanFilter(long *box){
	long sum = 0;		// 測定値の合計値を格納

	// 合計を求める
	for(int i = 0; i < BUFFER_LENGTH; i++){
		sum += box[i];
	}

	// 測定値の平均値を返す
	return (long)(sum / BUFFER_LENGTH);
}


/*--- タッチ判定 ---*/
void ClotchControl::decideTouched(){
	// スイッチが存在するとき
	if(type != 0){
		if(cap > cThresholdH){          // しきい値の上限値より静電容量値が高いとき
			curTouched = true;
		}else if(cap < cThresholdL){    // しきい値の下限値より静電容量値が低いとき
			curTouched = false;
		}else{						    // しきい値の上限と下限の間に静電容量値があるとき
			curTouched = preTouched;   
		}
		preTouched = curTouched;	    // 今回のタッチ状態を保存
	}else{
		preTouched = false;
		curTouched = false;
	}
}


/*--- 電圧値を取得 ---*/
long ClotchControl::getVolt(){
	return volt;
}


/*--- スイッチの種類を取得 ---*/
int ClotchControl::getType(){
	return type;
}


/*--- 静電容量値を取得 ---*/
long ClotchControl::getCap(){
	return cap;
}


/*--- タッチ状態の取得 ---*/
bool ClotchControl::getTouched(){
	return curTouched;
}









