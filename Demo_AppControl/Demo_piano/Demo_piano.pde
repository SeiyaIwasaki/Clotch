import ddf.minim.*;
import ddf.minim.effects.*;
import processing.serial.*;

// Arduinoとの通信用インスタンス
Serial port;                // シリアル通信用のポート
int infoType = 0;           // シリアルに書き込まれている情報の種類
int infoNum = 2;            // 書き込まれる情報の種類の数 
int switchType = 0;         // スイッチの種類
int touchFlg = 0;           // スイッチに触れてるかどうか

// アプリケーション用の素材インスタンス
int disW = 900, disH = 700;
PImage piano[];       // 動物イラスト
PImage backImage;     // 背景画像
int number = 0;
int alp = 0;

Minim minim;
AudioPlayer music;  // 楽曲



void setup(){
  
    /*--- Arduino 設定 ---*/
  
    // シリアルポートの設定
    println(Serial.list());                // シリアルポート一覧
    String portName = Serial.list()[2];    // Arduinoと接続しているシリアルを選択
    port = new Serial(this, portName, 9600);
    
    println("Byte in Port");
    println(port.available());
    
    
    /*--- アプリケーション設定 ---*/
    
    minim = new Minim(this);
    
    // 画面設定
    size(disW, disH);
    noCursor();
    noStroke();
    smooth();
    frameRate(60);
    imageMode(CENTER);
    colorMode(RGB, 256, 256, 256, 256);
    
    /* 素材ロード */
    
    // 動物イラスト
    piano = new PImage[2];
    for(int i = 0; i < piano.length; i++){
        piano[i] = loadImage("piano" + (i + 1) + ".png");
        piano[i].resize(piano[i].width / 2, piano[i].height / 2);
    }
    // 背景
    backImage = loadImage("background.jpg");
    backImage.resize(width, height);

    // 楽曲
    music = minim.loadFile("oldWatch.mp3");
    music.loop();
    music.pause();
}

void draw(){
    // 背景画像の描画
    background(backImage);
    
    // if switch exist
    if(switchType > 0){
        if(alp < 255) alp += 3;
        tint(255, alp);
        switchApp();
    }else{
        // 音楽が止まっていない時は止めておく
        if(music.isPlaying()){
          music.pause();
        }
        // 描画の点滅を防ぐためのフェードアウト処理
        if(alp > 0){
          alp -= 2;
          tint(255, alp);
          image(piano[0], width / 2, height / 2 + (height / 6));
        }
        if(alp < 0) alp = 0;
    }
    
}

/* switch Application */
void switchApp(){
    switch(switchType){
        case 3:
            pianoApp();
            break;
        default:
            break;
    }
    
}

/* piano aaprication */
void pianoApp(){
    if(touchFlg == 1){
        image(piano[1], width / 2, height / 2 + (height / 6));
        music.play();
    }else{
        image(piano[0], width / 2, height / 2 + (height / 6));
        music.pause();
    }
}

/* シリアル通信 */
void serialEvent(Serial p){
    /* 改行区切りでデータを読み込む (¥n == 10) */
    String inString = p.readStringUntil(10);

    /* ２つ以上のデータが存在している場合、数値として読み込む */
    if(inString != null){
      inString = trim(inString);
      int[] value = int(split(inString, ','));
      
      if(value.length > 1){
         switchType = value[0];
         touchFlg = value[1];
      }
    }
    
    println("スイッチの種類：" + switchType);  
    println("触れてるかどうか：" + touchFlg);
}

/* 終了処理 */
void stop(){
  music.close();
  minim.stop();
  super.stop();
}

