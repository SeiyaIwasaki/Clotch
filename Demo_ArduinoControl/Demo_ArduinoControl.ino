/* Arduino言語でアナログ入力を記述してみる
   switchNum = 1 での動作を試してみる */


#include <CapacitiveSensor.h>

// 静電容量・センサ
const int transPin[] = {0, 2, 4, 6};    // センサとして使用する送信側のピン番号
const int recievePin[] = {1, 3, 5, 7};  // センサとして使用する受信側のピン番号
CapacitiveSensor CapSensor[] = {CapacitiveSensor(transPin[0], recievePin[0]),
                                CapacitiveSensor(transPin[1], recievePin[1])};
//                                CapacitiveSensor(transPin[2], recievePin[2]),
//                                CapacitiveSensor(transPin[3], recievePin[3])};
const int thresholdH = 100;    // 静電容量しきい値 High
const int thresholdL = 50;     // 静電容量しきい値 Low
const int NOISE = 10;

// スイッチ
const int switchNum = 2;             // システムが識別可能なスイッチの種類の数
const int SWITCHES = 18;       // 使用できるスイッチの数 
int switchRange[SWITCHES][2];  // 各スイッチの電圧範囲（[switchNum][最小値, 最大値]）
int switchType[switchNum];     // スイッチの種類（0 = 存在しない）
boolean preTouched[switchNum]; // 前回のタッチ状態
boolean curTouched[switchNum]; // 今回のタッチ状態

// バッファ
const int BUFFER_LENGTH = 5;                    // バッファのサイズ
const int INDEX_OF_MIDDLE = BUFFER_LENGTH / 2;  // バッファの中央のインデックス
long volt_buffer1[switchNum][BUFFER_LENGTH];    // 電圧バッファ1
long volt_buffer2[switchNum][BUFFER_LENGTH];    // 電圧バッファ2
long cap_buffer1[switchNum][BUFFER_LENGTH];     // 静電容量バッファ1
long Volt[switchNum];                           // リアルタイム電圧値を格納する
int index = 0;                                  // 電圧バッファに書き込むインデックス
int capIndex = 0;                               // 静電容量バッファに書き込むインデックス
int LoopCount = BUFFER_LENGTH * BUFFER_LENGTH;  // 平均値を用いるために、セットアップ時に LoopCount 分 loop() を回しておく

/*---------------------------------------------------------------------*/

void setup() {
    // シリアル通信の開始
    Serial.begin(9600);
    
    // 各スイッチの電圧幅の初期化
    initSwitch();
    
    // 各スイッチの状態の初期化
    for(int i = 0; i < switchNum; i++){
        // 静電容量センサのキャリブレーション
        CapSensor[i].reset_CS_AutoCal();
    
        // 各スイッチの状態の初期化
        switchType[i] = 0;        // スイッチの種類
        preTouched[i] = false;    // タッチ状態
        
        // 電圧値の事前スムージング
        for(int j = 0; j < LoopCount; j++){
            SenseVolt(i);
            // インデックス更新
            index = (index + 1) % BUFFER_LENGTH;
        }
    
        // 静電容量の事前スムージング
        for(int j = 0; j < BUFFER_LENGTH; j++){
            SenseCap(i);
            // インデックス更新
            capIndex = (capIndex + 1) % BUFFER_LENGTH;
        }
    }
}

/*---------------------------------------------------------------------*/

void loop() {
    
    /* 各スイッチについて測定していく */
    for(int i = 0; i < switchNum; i++){
        /* タッチ状態を引き継ぐ */
        curTouched[i] = preTouched[i];
    
        /* 電圧を測定（2段階スムージング） */
        Volt[i] = SenseVolt(i);
//        Serial.println(Volt[i]);
    
        /* スイッチが存在するとき */
        if(switchExist(Volt[i])){
            /* 静電容量を測定 */
            long Cap = SenseCap(i);
//            Serial.print("Cap = ");
//            Serial.println(Cap);
            
            /* タッチ判定 */
            // 測定した静電容量の値が上のしきい値より大きければ触れていると判定
            if(Cap > thresholdH){
                curTouched[i] = true;
            }
            // 測定した静電容量の値が下のしきい値より小さければ触れていないと判定
            else if(Cap < thresholdL){
                curTouched[i] = false;
            }
            // ※しきい値の上と下の間である場合は、前回のタッチ状態を引き継ぐ
            preTouched[i] = curTouched[i];    // 現在のタッチ状態を保存しておく
        }
    
    
        /* スイッチの種類と触れているかどうかをシリアルに書き込む */
        /* 複数の数値を通信したいときは、一つの文字列にまとめて、processing 側でパースする必要がある */
        Serial.print(switchType[i]);
        Serial.print(",");
        Serial.print(curTouched[i]);
        Serial.print(",");
    }
    Serial.println();
}

/* 電圧を測定 */
long SenseVolt(int sp){
    analogRead(sp);                                                 // アナログ入力の空読み
    long raw = analogRead(sp);                                      // AnalogInputから電圧値を測定
    volt_buffer1[sp][index] = raw;                                  // その結果を buffer1 に蓄積する
    long average = smoothByMeanFilter(volt_buffer1[sp]);            // Meanフィルタでスムージング
    volt_buffer2[sp][index] = average;                              // 電圧の平均値を蓄積
    long FilterVoltValue = smoothByMeanFilter(volt_buffer2[sp]);    // スムージングした電圧値を保存
    
    return FilterVoltValue;
}

/* 静電容量を測定 */
long SenseCap(int sp){
    long raw = CapSensor[sp].capacitiveSensor(NOISE);
    cap_buffer1[sp][capIndex] = raw;
    long FilterCapValue = smoothByMeanFilter(cap_buffer1[sp]);
    
    return FilterCapValue;
}

/* スイッチが取り付けられているかどうか判定する */
boolean switchExist(int val){
    for(int i = 0; i < SWITCHES; i++){
        if(switchRange[i][0] < val && val < switchRange[i][1]){
            switchType[i] = i + 1;    // スイッチの種類を保存しておく
            //Serial.println(switchType);
            return true;           
        }else{
            // スイッチが取り付けられていないとき
            switchType[i] = 0;
        }
    }
    
    return false; 
}

/* Meanフィルタ(平均化)によるスムージング */
long smoothByMeanFilter(long *box){
    long sum = 0;
    // 電圧値の合計を求める
    for(int i = 0; i < BUFFER_LENGTH; i++){
        sum += box[i];
    }
    // その平均を返す
    return (long)(sum / BUFFER_LENGTH);
}

/* 各スイッチの電圧範囲の初期化 */
void initSwitch(){
    // スイッチ 1 : 220Ω
    switchRange[0][0] = 18;     // min
    switchRange[0][1] = 26;     // max
    // スイッチ 2 : 470Ω
    switchRange[1][0] = 42;     // min
    switchRange[1][1] = 49;     // max
    // スイッチ 3 : 680Ω
    switchRange[2][0] = 61;     // min
    switchRange[2][1] = 68;     // max
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
}
