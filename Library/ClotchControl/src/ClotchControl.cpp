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
ClotchControl::ClotchControl(int BUFFER_LENGTH, int sensorPin, int transPin, int recievePin, int thresholdH, int thresholdL, int NOISE) {
	this->type				= 0;										// 種類
	this->BUFFER_LENGTH		= BUFFER_LENGTH;							// バッファのサイズ
	this->INDEX_OF_MIDDLE	= BUFFER_LENGTH / 2;						// バッファの中央のインデックス
	this->vindex			= 0;										// 電圧値バッファ用インデックス
	this->cindex			= 0;										// 静電容量バッファ用インデックス
	this->vb1				= new long[BUFFER_LENGTH];					// 電圧値バッファ1
	this->vb2				= new long[BUFFER_LENGTH];					// 電圧値バッファ2
	this->cb				= new long[BUFFER_LENGTH];					// 静電容量バッファ
	this->volt				= 0;										// スムージング後の電圧測定値
	this->cap				= 0;										// スムージング後の静電容量値

	this->sensorPin			= sensorPin;									// 電圧測定用アナログ入力ピン
	this->transPin			= transPin;										// 静電容量センサの送信ピン
	this->recievePin		= recievePin;									// 静電容量センサの受信ピン
	this->thresholdH		= thresholdL;									// 静電容量しきい値 High
	this->thresholdL		= thresholdL;									// 静電容量しきい値 Low
	this->NOISE				= NOISE;										// 静電容量センサが拾うノイズの量
	this->sensor			= new CapacitiveSensor(transPin, recievePin);	// 静電容量センサクラス

	this->preTouched		= false;									// 前回のタッチ状態
	this->curTouched		= false;									// 今回のタッチ状態
}


/*--- 静電容量センサのキャリブレーション ---*/
void ClotchControl::sensorCalibrate(){
	sensor->reset_CS_AutoCal();
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


/*--- 電圧を測定 ---*/
void ClotchControl::senseVolt(){
	analogRead(sensorPin);					// アナログ入力の空読み

	long raw = analogRead(sensorPin);		// 測定された電圧値を格納
	vb1[vindex]	= raw;						// 測定値をバッファに蓄積

	long average = smoothByMeanFilter(vb1);	// スムージング処理
	vb2[vindex]	= average;					// 測定値の平均値を蓄積
	
	vindex = (vindex + 1) % BUFFER_LENGTH;	// インデックス更新
	volt = smoothByMeanFilter(vb2);			// 電圧測定値（スムージング済み）を格納
}


/*--- 静電容量を測定 ---*/
void ClotchControl::senseCap(){
	long raw = sensor->capacitiveSensor(NOISE);	// 静電容量測定値を格納
	cb[cindex] = raw;							// 測定値を蓄積
	
	cindex = (cindex + 1) % BUFFER_LENGTH;		// インデックス更新
	cap = smoothByMeanFilter(cb);				// 静電容量測定値（スムージング済み）を格納
}


/*--- スムージング処理（平均化） ---*/
long ClotchControl::smoothByMeanFilter(long* box){
	long sum = 0;		// 測定値の合計値を格納

	// 合計を求める
	for(int i = 0; i < BUFFER_LENGTH; i++){
		sum += box[i];
	}

	// 測定値の平均値を返す
	return (long)(sum / BUFFER_LENGTH);
}


/*--- 電圧値を取得 ---*/
long ClotchControl::getVolt(){
	return volt;
}


/*--- 静電容量値を取得 ---*/
long ClotchControl::getCap(){
	return cap;
}


/*--- タッチ判定 ---*/
bool ClotchControl::getTouched(){

	if(cap > thresholdH){          // しきい値の上限値より静電容量値が高いとき
		curTouched = true;
	}else if(cap < thresholdL){    // しきい値の下限値より静電容量値が低いとき
		curTouched = false;
	}else{						   // しきい値の上限と下限の間に静電容量値があるとき
		curTouched = preTouched;   
	}

	preTouched = curTouched;	   // 今回のタッチ状態を保存

	return curTouched;
}









