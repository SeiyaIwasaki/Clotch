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
		ClotchControl(int BUFFER_LENGTH,
					  int sensorPin,
					  int transPin,
					  int recievePin,
					  int thresholdH,
					  int thresholdL,
					  int NOISE);
  
	// メソッド
	public:
		void sensorCalibrate(void);			// 静電容量センサのキャリブレーション
		void setupBuffer(void);				// バッファのセットアップ
		void senseVolt(void);				// 電圧を測定
		void senseCap(void);				// 静電容量を測定
		long smoothByMeanFilter(long*);		// スムージング処理（平均化）
		long getVolt(void);					// 電圧値を取得
		long getCap(void);					// 静電容量値を取得
		bool getTouched(void);				// タッチ判定
  
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

		int sensorPin;				// 電圧測定用アナログ入力ピン
		int transPin;			    // 静電容量センサの送信ピン
		int recievePin;			    // 静電容量センサの受信ピン
		int thresholdH;				// 静電容量しきい値 High
		int thresholdL;				// 静電容量しきい値 Low
		int NOISE;					// 静電容量センサが拾うノイズの量
		CapacitiveSensor *sensor;	// 静電容量センサクラス

		bool preTouched;			// 前回のタッチ状態
		bool curTouched;			// 今回のタッチ状態
};
 
#endif