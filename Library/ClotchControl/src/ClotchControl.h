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
	// コンストラクタ
	public:
		ClotchControl(int sensorPin, int transPin, int recievePin);
  
	// メソッド
	public:
		void sensorCalibrate(void);			// 静電容量センサのキャリブレーション
		void offAutoCalibrate(void);		// 静電容量センサのオートキャリブレーションのオフ
		void setupBuffer(void);				// バッファのセットアップ
		void resetThreshold(int, int);		// しきい値の再設定
		void resetSamplingNum(int);			// サンプリング数の再設定
		void saveSwitchType(int);			// スイッチの種類を保存
		void senseVolt(void);				// 電圧を測定
		void senseCap(void);				// 静電容量を測定
		long smoothByMeanFilter(long*);		// スムージング処理（平均化）
		void decideTouched(void);			// タッチ判定
		long getVolt(void);					// 電圧値を取得
		int getType(void);					// スイッチの種類を取得
		long getCap(void);					// 静電容量値を取得
		bool getTouched(void);				// タッチ状態の取得
  
	// フィールド
	private:
		int type;					// 種類
		int BUFFER_LENGTH;			// バッファのサイズ
		int INDEX_OF_MIDDLE;		// バッファの中央のインデックス
		int vindex;					// 電圧値バッファ用インデックス
		int cindex;					// 静電容量バッファ用インデックス
		long *vb1;					// 電圧値バッファ1
		long *vb2;					// 電圧値バッファ2
		long *cb;					// 静電容量バッファ
		long volt;					// スムージング後の電圧測定値
		long cap;					// スムージング後の静電容量値

		int cSensorPin;				// 電圧測定用アナログ入力ピン
		int cTransPin;			    // 静電容量センサの送信ピン
		int cRecievePin;		    // 静電容量センサの受信ピン
		int cThresholdH;			// 静電容量しきい値 High
		int cThresholdL;			// 静電容量しきい値 Low
		int cSamplingNum;			// 静電容量センサが拾うノイズの量
		CapacitiveSensor *sensor;	// 静電容量センサクラス

		bool preTouched;			// 前回のタッチ状態
		bool curTouched;			// 今回のタッチ状態
};
 
#endif