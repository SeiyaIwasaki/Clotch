/*****************************************************
    Demo_piano
    
    Copyright(c) 2015 Seiya Iwasaki
    
    This software is released under the MIT License.
    http://opensource.org/licenses/mit-license.php
*****************************************************/

/*--- ライブラリのインポート ---*/
import ddf.minim.*;
import ddf.minim.effects.*;
import processing.serial.*;


/*--- オブジェクト宣言 ---*/

// 音管理用クラス
LeaderControl leader;
MusicControl rabbit;
MusicControl bear;
MusicControl elephant;

// Arduinoとのシリアル通信用
Serial port; 

// アプリケーション用の素材インスタンス
PImage backImage;                               // アプリケーション背景画像
String[] music_name = {"canon", "oldWatch"};    // 楽曲名
int playingPoint = 0;                           // 再生位置同期用

// 音楽ファイルロード用クラス
Minim minim;



/*---------------------------------------------------------*/

void setup(){
  
    /*--- Arduino 設定 ---*/
  
    // シリアルポートの設定
    println(Serial.list());                // シリアルポート一覧
    String portName = Serial.list()[2];    // Arduinoと接続しているシリアルを選択
    port = new Serial(this, portName, 9600);
    
    // デバッグ用
//    println(port.available());
    
    
    /*--- アプリケーション設定 ---*/

    // 画面設定
    size(displayWidth, displayHeight);
    noStroke();
    noCursor();
    smooth();
    frameRate(60);
    imageMode(CENTER);
    colorMode(RGB, 256, 256, 256, 256);
    
    // 背景
    backImage = loadImage("image\\background.jpg");
    backImage.resize(width, height);

    // 楽曲
    minim = new Minim(this);
    leader = new LeaderControl(width * 0.5, height * 0.75, music_name);
    rabbit = new MusicControl("rabbit", width * 0.7, height * 0.60);
    bear = new MusicControl("bear", width * 0.5, height * 0.5);
    elephant = new MusicControl("elephant", width * 0.3, height * 0.60);
    rabbit.selectMusic(music_name[leader.getPlayingMusic()], minim);
    bear.selectMusic(music_name[leader.getPlayingMusic()], minim);
    elephant.selectMusic(music_name[leader.getPlayingMusic()], minim);
}



/*---------------------------------------------------------*/

void draw(){
    /* 前処理 */

    // 音楽再生位置の同期
    playingPoint = int(max(rabbit.getPosition(), bear.getPosition()));
    playingPoint = int(max(playingPoint, elephant.getPosition()));
    rabbit.setPosition(playingPoint);
    bear.setPosition(playingPoint);
    elephant.setPosition(playingPoint);

    /* 描画処理 */

    // 背景画像の描画
    background(backImage);
    
    // if switch exist
    // if(switchType > 0){
    //     if(alp < 255) alp += 3;
    //     tint(255, alp);
    //     switchApp();
    // }else{
    //     // 音楽が止まっていない時は止めておく
    //     if(music.isPlaying()){
    //       music.pause();
    //     }
    //     // 描画の点滅を防ぐためのフェードアウト処理
    //     if(alp > 0){
    //       alp -= 2;
    //       tint(255, alp);
    //       image(piano[0], width / 2, height / 2 + (height / 6));
    //     }
    //     if(alp < 0) alp = 0;
    // }

    // 演奏イメージの描画
    bear.playImage();
    rabbit.playImage();
    elephant.playImage();
    leader.playImage();
    
    /* 音楽再生処理 */
    if(leader.getPlayable()){
        rabbit.playSound();
        bear.playSound();
        elephant.playSound();
    }

    /* 更新処理 */
    rabbit.updatePosition();
    bear.updatePosition();
    elephant.updatePosition();
    if(leader.updateMusic()) changeMusic();
    
    // デバッグ用
//    println();
//    println("Position = " + playingPoint);
//    print(rabbit.getPosition());
//    println(" : " + rabbit.getSwitchTouched());
//    print(bear.getPosition());
//    println(" : " + bear.getSwitchTouched());
//    print(elephant.getPosition());
//    println(" : " + elephant.getSwitchTouched());
}


/*-- 楽曲変更 --*/
void changeMusic(){
    rabbit.stopMusic();
    bear.stopMusic();
    elephant.stopMusic();
    rabbit.selectMusic(music_name[leader.getPlayingMusic()], minim);
    bear.selectMusic(music_name[leader.getPlayingMusic()], minim);
    elephant.selectMusic(music_name[leader.getPlayingMusic()], minim);
}


/*-- シリアル通信 --*/
void serialEvent(Serial p){
    try{
        // 改行区切りでデータを読み込む (¥n == 10)
        String inString = p.readStringUntil(10);
        
        // カンマ区切りのデータの文字列をパースして数値として読み込む
        if(inString != null){
            inString = trim(inString);
            int[] value = int(split(inString, ','));
      
            if(value.length > 7){
                // *指揮者位置のスイッチ情報は 0 と 1 
                leader.setSwitchType(value[0]);
                leader.setSwitchTouched(value[1]);
                rabbit.setSwitchType(value[2]);
                rabbit.setSwitchTouched(value[3]);
                bear.setSwitchType(value[4]);
                bear.setSwitchTouched(value[5]);
                elephant.setSwitchType(value[6]);
                elephant.setSwitchTouched(value[7]);
            }
        }
        
        // デバッグ用
        println("leader : " + leader.getSwitchType() + " , " + leader.getSwitchTouched());
        println("rabbit : " + rabbit.getSwitchType() + " , " + rabbit.getSwitchTouched());
        println("bear : " + bear.getSwitchType() + " , " + bear.getSwitchTouched());
        println("elephant : " + elephant.getSwitchType() + " , " + elephant.getSwitchTouched());
        println();
    }catch(RuntimeException e){
        e.printStackTrace();
    }
}


/*-- デバッグ用キーボード操作 --*/
void keyPressed(){
    switch(key){
        case 's':
            leader.setSwitchType(3);
            rabbit.setSwitchType(19);
            bear.setSwitchType(8);
            elephant.setSwitchType(5);
            break;
        case 'l':
            if(leader.getSwitchTouched() == 0) leader.setSwitchTouched(1);
            else leader.setSwitchTouched(0);
            break;
        case 'r':
            if(rabbit.getSwitchTouched() == 0) rabbit.setSwitchTouched(1);
            else rabbit.setSwitchTouched(0);
            break;
        case 'b':
            if(bear.getSwitchTouched() == 0) bear.setSwitchTouched(1);
            else bear.setSwitchTouched(0);
            break;
        case 'e':
            if(elephant.getSwitchTouched() == 0) elephant.setSwitchTouched(1);
            else elephant.setSwitchTouched(0);
            break;
        case 'q':
            rabbit.setSwitchType(0);
            break;
        case '0':
            leader.setSwitchType(3);
            break;
        case '1':
            rabbit.setSwitchType(5);
            break;
        case '2':
            rabbit.setSwitchType(19);
            break;
        case '3':
            rabbit.setSwitchType(8);
            break;
        case 'a':
            bear.setSwitchType(0);
            break;
        case '4':
            bear.setSwitchType(19);
            break;
        case '5':
            bear.setSwitchType(8);
            break;
        case '6':
            bear.setSwitchType(5);
            break;
        case 'z':
            elephant.setSwitchType(0);
            break;
        case '7':
            elephant.setSwitchType(19);
            break;
        case '8':
            elephant.setSwitchType(8);
            break;
        case '9':
            elephant.setSwitchType(5);
            break;
        default :
            break;    
    }
    println(key);
}


/*-- 終了処理 --*/
void stop(){
    rabbit.stop();
    bear.stop();
    elephant.stop();
    minim.stop();
    super.stop();
}

