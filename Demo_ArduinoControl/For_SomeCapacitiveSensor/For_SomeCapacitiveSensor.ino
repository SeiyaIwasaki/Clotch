#include <CapacitiveSensor.h>

// 静電容量・センサ
const int transPin[]   = {52, 44, 36, 28};          // センサとして使用する送信側のピン番号
const int recievePin[] = {48, 40, 32, 24};          // センサとして使用する受信側のピン番号
const int voltPin[] = {0, 1, 2, 3};                 // 電圧センサ   
int val[] = {0, 0, 0, 0};
int volt[] = {0, 0, 0, 0};
const int holdH = 150;
const int holdL = 80;
String touch[] = {"OFF", "OFF", "OFF", "OFF"};

// 静電容量センサのインスタンス
CapacitiveSensor CapSensor[] = {
    CapacitiveSensor(transPin[0], recievePin[0]), 
    CapacitiveSensor(transPin[1], recievePin[1]), 
    CapacitiveSensor(transPin[2], recievePin[2]), 
    CapacitiveSensor(transPin[3], recievePin[3]) };
const int NOISE = 10;

// バッファ - スムージング
const int BUFFER_LENGTH = 5;
long cap_buffer1[BUFFER_LENGTH];                // 静電容量バッファ1
long cap_buffer2[BUFFER_LENGTH];                // 静電容量バッファ2
long cap_buffer3[BUFFER_LENGTH];                // 静電容量バッファ3
long cap_buffer4[BUFFER_LENGTH];                // 静電容量バッファ4
int capIndex = 0;


void setup(){
    // 静電容量センサーのキャリブレーション
    for(int i = 0; i < 4; i++){
        CapSensor[i].reset_CS_AutoCal();
    }
    // 静電容量変化吸収
    for(int i = 0; i < 5; i++){
        SenseCap1();
        SenseCap2();
        SenseCap3();
        SenseCap4();
        capIndex = (capIndex + 1) % BUFFER_LENGTH;
    }
    Serial.begin(9600);
}



void loop() {
    
    // 測定
    val[0] = SenseCap1();
    val[1] = SenseCap2();
    val[2] = SenseCap3();
    val[3] = SenseCap4();
    capIndex = (capIndex + 1) % BUFFER_LENGTH;
    
//    for(int i = 0; i < 4; i++){
//        volt[i] = analogRead(voltPin[i]);
//    }
    
    // タッチ判定
    for(int i = 0; i < 4; i++){
        if(val[i] > holdH){
            touch[i] = "ON";
        }else if(val[i] < holdL){
            touch[i] = "OFF";
        }
    }
    
    // キャリブレーション設定
    for(int i = 0; i < 4; i++){
        if(touch[i].equals("ON")){
            // ONの間はキャリブレーションしないようにする
            CapSensor[i].set_CS_AutocaL_Millis(0xFFFFFFFF);
        }else{
            // OFFのときは 20秒 ごとにキャリブレーションする
//            CapSensor[i].reset_CS_AutoCal();
        } 
    }
    
    // 表示
    for(int i = 0; i < 4; i++){
        Serial.print("Cap Value" + String(i + 1) + " = ");
        Serial.print(val[i]);
        Serial.print("            " + touch[i]);
        Serial.println(" ");                 
    }
    Serial.println(" ");
    
    delay(400);
}

long SenseCap1(){
    long raw = CapSensor[0].capacitiveSensor(NOISE);
    cap_buffer1[capIndex] = raw;
    long FilterCapValue = smoothByMeanFilter(cap_buffer1);
    
    return FilterCapValue;
}

long SenseCap2(){
    long raw = CapSensor[1].capacitiveSensor(NOISE);
    cap_buffer2[capIndex] = raw;
    long FilterCapValue = smoothByMeanFilter(cap_buffer2);
    
    return FilterCapValue;
}

long SenseCap3(){
    long raw = CapSensor[2].capacitiveSensor(NOISE);
    cap_buffer3[capIndex] = raw;
    long FilterCapValue = smoothByMeanFilter(cap_buffer3);
    
    return FilterCapValue;
}

long SenseCap4(){
    long raw = CapSensor[3].capacitiveSensor(NOISE);
    cap_buffer4[capIndex] = raw;
    long FilterCapValue = smoothByMeanFilter(cap_buffer4);
    
    return FilterCapValue;
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


