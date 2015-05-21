/*****************************************************
    Clotch
    
    Copyright(c) 2015 Seiya Iwasaki
    
    This software is released under the MIT License.
    http://opensource.org/licenses/mit-license.php
*****************************************************/

/*--- インクルード ---*/
#include <CapacitiveSensor.h>
#include <ClotchControl.h>


/*--- マクロ ---*/
//#define DEBUG


/*--- セットアップ用データ ---*/
const int cSwitchNum        = 2;                    // システムで扱うスイッチの数
const int SWITCHES          = 19;                   // 識別可能なスイッチの数
const int cTransPin[]       = {2, 4, 6, 8, 10, 12}; // センサとして使用する送信側のピン番号
const int cRecievePin[]     = {3, 5, 7, 9, 11, 13}; // センサとして使用する受信側のピン番号
const int cSensorPin[]      = {0, 1, 2, 3, 4, 5};   // 電圧値測定用アナログ入力ピン番号
const int cThresholdH       = 100;                  // 静電容量しきい値 High
const int cThresholdL       = 70;                   // 静電容量しきい値 Low
const int cSamplingNum      = 30;                   // 静電容量センサが拾うノイズの量

int switchRange[SWITCHES][2];      // 各スイッチの電圧範囲（[switchNum][最小値, 最大値]）


/*--- 布スイッチライブラリ ---*/
ClotchControl *clotches[cSwitchNum];


/*---------------------------------------------------------------------*/


void setup() {
    // 布スイッチライブラリの初期化
    for(int AIN = 0; AIN < cSwitchNum; AIN++){
        clotches[AIN] = new ClotchControl(cSensorPin[AIN], cTransPin[AIN], cRecievePin[AIN]);
        clotches[AIN]->sensorCalibrate();
        clotches[AIN]->offAutoCalibrate();
        clotches[AIN]->setupBuffer();
        clotches[AIN]->resetThreshold(cThresholdL, cThresholdH);
        clotches[AIN]->resetSamplingNum(cSamplingNum);
    }
    
    // 各スイッチの電圧幅の初期化
    initSwitchRange();
    
    // シリアル通信の開始
    Serial.begin(9600);
}


/*---------------------------------------------------------------------*/


void loop() {
    
    /* 各スイッチについて測定していく */
    for(int AIN = 0; AIN < cSwitchNum; AIN++){
        // 電圧値の測定
        clotches[AIN]->senseVolt();
        
        // スイッチの種類を判定（ clotches のメンバ変数 type に格納される ）
        checkSwitchExist(AIN);
        
        // スイッチが存在するときだけ、静電容量を測定
        if(clotches[AIN]->getType() != 0){
            clotches[AIN]->senseCap();
        }
        
        // タッチ判定
        clotches[AIN]->decideTouched();
        
        /* スイッチの種類とタッチ状態をシリアルに書き込む */
        // 複数の数値を通信したいときは、一つの文字列にまとめて、processing 側でパースする必要がある
        Serial.print(clotches[AIN]->getType());
        Serial.print(",");
        Serial.print(clotches[AIN]->getTouched());
        Serial.print(",");
        
        // デバッグ用
        #ifdef DEBUG
            Serial.println();
            Serial.print("AnalogInput : ");
            Serial.print(AIN);
            Serial.print("    ");
            Serial.print("Volt : ");
            Serial.print(clotches[AIN]->getVolt());
            Serial.print("    ");
            Serial.print("Cap : ");
            Serial.print(clotches[AIN]->getCap());
            Serial.println();
        #endif
    }
    Serial.println();
    
    // デバッグ用
    #ifdef DEBUG
        delay(300);
    #endif
}


/*---------------------------------------------------------------------*/


/* スイッチが取り付けられているかどうか判定する */
void checkSwitchExist(int ain){
   // 全てのスイッチの電圧幅情報と照らし合わせる
   int volt = clotches[ain]->getVolt();
   for(int i = 0; i < SWITCHES; i++){
        if(switchRange[i][0] <= volt && volt <= switchRange[i][1]){
            clotches[ain]->saveSwitchType(i + 1);
            return;
        }
    }
    
    // 測定された電圧値がどの電圧幅にも属しないとき
    clotches[ain]->saveSwitchType(0);
}


/*---------------------------------------------------------------------*/


/* 各スイッチの電圧範囲の初期化 */
void initSwitchRange(){
    // スイッチ 1 : 220Ω
    switchRange[0][0] = 18;     // min
    switchRange[0][1] = 26;     // max
    // スイッチ 2 : 470Ω
    switchRange[1][0] = 42;     // min
    switchRange[1][1] = 49;     // max
    // スイッチ 3 : 775Ω （楽曲選択）
    switchRange[2][0] = 70;     // min
    switchRange[2][1] = 78;     // max
    // スイッチ 4 : 1kΩ
    switchRange[3][0] = 89;     // min
    switchRange[3][1] = 96;     // max
    // スイッチ 5 : 2.2kΩ
    switchRange[4][0] = 181;    // min
    switchRange[4][1] = 188;    // max
    // スイッチ 6 : 3.3kΩ
    switchRange[5][0] = 242;    // min
    switchRange[5][1] = 266;    // max
    // スイッチ 7 : 4.7kΩ
    switchRange[6][0] = 323;    // min
    switchRange[6][1] = 330;    // max
    // スイッチ 8 : 5.1kΩ
    switchRange[7][0] = 342;    // min
    switchRange[7][1] = 349;    // max
    // スイッチ 9 : 6.8kΩ
    switchRange[8][0] = 410;    // min
    switchRange[8][1] = 417;    // max
    // スイッチ 10 : 9.1kΩ
    switchRange[9][0] = 484;    // min
    switchRange[9][1] = 491;    // max
    // スイッチ 11 : 10kΩ
    switchRange[10][0] = 508;    // min
    switchRange[10][1] = 515;    // max
    // スイッチ 12 : 22kΩ
    switchRange[11][0] = 700;    // min
    switchRange[11][1] = 707;    // max
    // スイッチ 13 : 33kΩ
    switchRange[12][0] = 781;    // min
    switchRange[12][1] = 789;    // max
    // スイッチ 14 : 47kΩ
    switchRange[13][0] = 840;    // min
    switchRange[13][1] = 848;    // max
    // スイッチ 15 : 68kΩ
    switchRange[14][0] = 888;    // min
    switchRange[14][1] = 896;    // max
    // スイッチ 16 : 91kΩ
    switchRange[15][0] = 918;    // min
    switchRange[15][1] = 926;    // max
    // スイッチ 17 : 220kΩ
    switchRange[16][0] = 975;    // min
    switchRange[16][1] = 983;    // max
    // スイッチ 18 : 330kΩ
    switchRange[17][0] = 989;    // min
    switchRange[17][1] = 997;    // max
    // スイッチ 19 : 570kΩ （ピアノ）
    switchRange[18][0] = 1002;   // min
    switchRange[18][1] = 1006;   // max
}














