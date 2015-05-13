/****************************************
        Seiya Iwasaki (12-0051)
        
          「旅人を守れ!!」
        
****************************************/


//--- ライブラリのインポート ---//
import processing.video.*;
import ddf.minim.*;


//--- 変数の宣言 ---//

//-基本クラス
Capture cam;                        //-キャプチャークラス
Minim minim;                        //-オーディオクラス
Traveler trav;                      //-旅人クラス
Sun sun;                            //-太陽クラス
ArrayList<Nwind> nw;                //-北風クラス

//-基本設定
int w = 1200, h = 800;              //-画面サイズ
int fps = 60;                       //-draw()が1秒間に実行される回数(原則60fpsで行う)
int ani_fps = 5;                    //-アニメーション用フレームレート
int cgf = fps / ani_fps;            //-draw()が何回実行される度にアニメーションメソッドを呼び出すか
int prec = 10;                      //-何ピクセルごとに明るさ判定を行うか（大きければ早いが精度は落ちる）
int nw_max = 10;                    //-北風の個数の最大値
int nw_time = 5;                    //-北風が何秒ごとに現れるか
int ease = 50;                      //-当たり判定を指定ピクセル分緩和する
boolean inmode = true;              //-入力方法を変える：マウス、光検知

//-素材クラス
PImage back;                        //-背景画像
PImage start;                       //-スタート画面背景画像
PImage start_tut;                   //-スタート画面説明
PImage goaltitle;                   //-ゴール画面文字画像
PImage goal_tut;                    //-ゴール画面説明
PImage pause;                       //-ポーズ
PImage end;                         //-エンド画面
PImage[] sa = new PImage[13];       //-GIFアニメーション
AudioPlayer bgm1;                   //-メインBGM
AudioPlayer bgm2;                   //-環境BGM
AudioPlayer voice;                  //-旅人の声

//-データ保存用
float[] bright_ave = new float[2];  //-明るい範囲の平均座標値 [0] = X, [1] = Y
float back_count = 0;               //-背景アニメーション用カウンタ
float tutint = 85.5;                //-説明の透明度
int game_count = 0;                 //-ゲーム本編用フレームカウンタ
int goal;                           //-ゴールの X 座標値
int game_flag = 0;                  //-ゲーム進行用フラグ
boolean tuf = true;                 //-説明の透明度変化のフラグ
int dc = 0;                         //-ダメージを受けた回数


//--- Setup ---//
void setup(){
    //-基本設定
    size(w, h);
    colorMode(RGB, 256, 256, 256, 256);
    noStroke();
    noCursor();
    imageMode(CENTER);
    frameRate(fps);
    PFont myfont = loadFont("Meiryo-Bold-48.vlw");
    textFont(myfont);
    textAlign(CENTER);
    
    //-基本クラスのインスタンス化
    cam = new Capture(this, width, height, 60);
    minim = new Minim(this);
    trav = new Traveler(width / 2, height - 200, 10);
    sun = new Sun(width / 2, height / 2);
    nw = new ArrayList<Nwind>();
    initNwind(0);
    
    //-素材のロード
    back = loadImage("back1.jpg");
    start = loadImage("start.jpg");
    start_tut = loadImage("start_tut.png");
    goaltitle = loadImage("goaltitle.png");
    goal_tut = loadImage("goal_tut.png");
    pause = loadImage("pause.png");
    end = loadImage("end.jpg");
    for(int i = 0; i < 13; i++){
        sa[i] = loadImage("sa" + (i + 1) + ".jpg");
    }
    bgm1 = minim.loadFile("yoake.mp3");
    bgm2 = minim.loadFile("kazeb.mp3");
    voice = minim.loadFile("voice.wav");
    
    //-ゴール座標の初期化
    goal = back.width - width;
    
    //-BGMの再生
    bgm1.loop();
    bgm2.loop();
}


//--- Draw ---//
void draw(){
    
    /*-------------------- 計算処理(入力) --------------------*/
    
    //-左右反転処理と同時に明るいピクセル集合の平均座標値を求める
    if(inmode){
        revpix();
        //-入力情報の保存
        sun.move(bright_ave[0], bright_ave[1]);
    }else{
        sun.moveMouse();
    }
    
    //-入力方法切り替え
    if(keyPressed == true && key == ENTER){
        if(inmode) inmode = false;
        else inmode = true;
        //-連続入力防止
        delay(100);
    }
    
    /*-------------------- 描画処理(出力) --------------------*/
    
    //-ゲーム（30fps）
    switch(game_flag){
        //-ゲームタイトル
        case 0:
            titlestory();
            //-太陽が画面の中心下に来たらスタート
            if(hit(sun.getPosX(), sun.getPosY(), 870, 465, (sun.getWidth() / 2) - 30, (sun.getHeight() / 2) - 30)){
                //-ゲームオープニングへ
                game_flag = 1;
                //-旅人の位置を画面の左端へ
                trav.move(-1 * ((width / 2) + (trav.getWidth() / 2)), 0);
                tuf = true;
                tutint = 85.5;
            }
            break;
            
        //-タイトルオープニング
        case 1:
            image(sa[game_count], width / 2, height / 2);            
            delay(60);
            game_count++;
            if(game_count == 13){
                game_flag = 2;
                game_count = 0;
            }
            break;
            
        //-ゲーム本編オープニング
        case 2:
            opstory();
            game_count++;
            //-旅人が真ん中んに来たら本編へ
            if(trav.getPosX() >= width / 2){
                //-位置を補正
                trav.move(-1 * (trav.getPosX() - width / 2), 0);
                //-ゲーム本編へ
                game_flag = 3;
                game_count = 0;
            }        
            break;
            
        //-ゲーム本編
        case 3:
            /*----------------- frameRate = fpsで実行される -----------------*/
            //-ゲーム描画処理
            story();
            
            //-衝突判定処理
            storyhit();
            
            /*--- カウント関連処理 ---*/
            //-1秒間に45pixel背景が移動する
            back_count += 1.5;
            if(back_count > goal){
                back_count = goal;
                //-ゲームクリア画面へ
                game_flag = 5;
                //-ゲームカウントの初期化
                game_count = 0;
            }
            //-ゲーム本編カウント
            game_count++;
            //-(nw_time)秒経過するごとに北風の数を増やす
            if(game_count % (fps * nw_time) == 0){
                if(nw.size() < nw_max) initNwind(nw.size());
            }
            
            //-ポーズ画面移行
            if(keyPressed == true && key == ' '){
                if(trav.getHP() != 100){
                    voice.pause();
                }
                game_flag = 4;
                //-連続入力防止
                delay(100);
            }
            
            /*----------------- frameRate = ani_fpsで実行される -----------------*/
            if(game_count % cgf == 0){
                trav.addCount();
            }
            break;
            
        //-ポーズ
        case 4:
            pause();
        
            //-ゲーム画面移行
            if(keyPressed == true && key == ' '){
                game_flag = 3;
                //-連続入力防止
                delay(100);
                if(trav.getHP() != 100){
                    voice.play();
                }
            }
            break;
            
        //-ゲームクリア
        case 5:
            gamec();
            if(game_count < 300) game_count++;
            if(game_count == 300 && hit(sun.getPosX(), sun.getPosY(), width / 2, height / 2, (sun.getWidth() / 2) - 30, (sun.getHeight() / 2) - 30)){
                game_flag = 6;
                game_count = 0;
            }
                
            break;
            
        //-エンドロール
        case 6:
            tint(255, map(game_count, 0, 600, 0, 255));
            image(end, width / 2, height / 2);
            noTint();
            game_count++;
            if(game_count > 900){
                image(start, width / 2, height / 2);
                tint(255, map(game_count, 900, 1080, 255, 0));
                image(end, width / 2, height / 2);
                noTint();
            }
            if(game_count == 1080){
                game_flag = 0;
                game_count = 0;
                back_count = 0;
                dc = 0; 
                nw = new ArrayList<Nwind>();
                initNwind(0);
            }
                
            break;
            
        //-エラー回避
        default:
            game_flag = 0;
            break;
    }
}


//--- 最新のカメラ映像を読み込む ---//
void captureEvent(Capture cam){
    cam.read();
}


//--- 北風の初期化 ---//
void initNwind(int num){
    //-X = 70～1130, Y = 100～250
    float tmp = 0;
    int i = 0;
    while(true){
        //-X座標
        tmp = random(70, 1130);
        //-重複判定(全体の空きスペースは860pixel, 使うスペースは<北風の画像幅 / 2(=70) + 間隔(=70) * 10>で求められる(現在=770pixel))
        for(; i < num; i++){
            if(abs(nw.get(i).getPosX() - tmp) <= 70) break;
        }
        if(i == num && (tmp < width / 2 - 100 || width / 2 + 100 < tmp) ){
            nw.add(new Nwind(tmp, random(100, 250), width, height));
            break;
        }
        i = 0;
    }
}


//--- 左右反転処理と座標平均値 ---//
void revpix(){
    int count = 0;
    
    for(int i = 0; i < height * width; i++){
        //-反転処理と同時に明度99以上のピクセルの個数とその座標値の総和を求めておく
        if(i % prec == 0 && brightness(cam.pixels[((width-1) + (int)(i / width) * width) - (i % width)]) >= 99){
            //-個数の総和
            count++;
            
            //-座標値の総和
            bright_ave[0] += (i % width);
            bright_ave[1] += (i / width);
        }
    }
    //-0除算回避
    if(count == 0) count++;
    bright_ave[0] = bright_ave[0] / count;
    bright_ave[1] = bright_ave[1] / count;
}


//--- タイトル画面 ---//
void titlestory(){
    //-背景
    image(start, width / 2, height / 2);

    //-説明の表示
    tint(255, ceil(tutint + 30));
    image(start_tut, 940, 760);
    noTint();
    
    if(tuf){
        tutint += (255.0 / (float)(fps * 0.5));
        if(tutint >= 220.0) tuf = false;
    }else{
        tutint -= (255.0 / (float)(fps * 0.5));
        if(tutint <= 80.0) tuf = true;
    }
    
    //-マーカーの表示
    sun.playMarker(width, height);
    
}


//--- ゲームオープニングアニメーション ---//
void opstory(){
    //-背景の表示
    imageMode(CORNER);    
    image(back.get(0, 0, width, height), 0, 0);
    imageMode(CENTER);
    
    //-太陽の表示
    sun.playSun();
    
    //-旅人の表示と移動
    trav.playHoko();
    trav.move(2, 0);
    
    /*----------------- frameRate = ani_fpsで実行される -----------------*/
    if(game_count % cgf == 0){
        trav.addCount();
    }
}


//--- ポーズ ---//
void pause(){
    outback();
    for(int i = 0; i < nw.size(); i++){
        nw.get(i).playNwind();
        if(nw.get(i).getFlg()){
            nw.get(i).playWind();
        }
    }
    sun.playSun();
    if(trav.getHP() == 100){
        trav.playHoko();
    }else{
        trav.playDamage();
    }
    
    tint(255, ceil(tutint + 30));
    image(pause, width / 2, height / 2);
    noTint();
    
    if(tuf){
        tutint += (255.0 / (float)(fps * 1.5));
        if(tutint >= 220.0) tuf = false;
    }else{
        tutint -= (255.0 / (float)(fps * 1.5));
        if(tutint <= 80.0) tuf = true;
    }
}


//--- ゲーム本編 ---//
void story(){
    /*----------------- frameRate = fpsで実行される -----------------*/
    
    //-背景の表示
    outback();
    
    //-北風とその風の表示
    for(int i = 0; i < nw.size(); i++){
        //-北風とその風の表示
        nw.get(i).playNwind();
        if(nw.get(i).getFlg()){
            nw.get(i).playWind();
            //-風の移動処理
            if(nw.get(i).getCount() < fps * 3) transwind(i);
        }
        //-風の更新処理
        if(nw.get(i).addCount(fps) == 0) nw.get(i).updateWind(width, height);
    }
    
    //-太陽の表示
    sun.playSun();
    
    //-旅人の表示
    if(trav.getHP() == 100){
        trav.playHoko();
    }else{
        trav.playDamage();
    }
}



//--- ゲームクリア ---//
void gamec(){
    outback();
    for(int i = 0; i < nw.size(); i++){
        nw.get(i).playNwind();
    }
    trav.playGoal();
    
    //-説明の表示
    tint(255, ceil(tutint + 30));
    image(goal_tut, 940, 760);
    noTint();
    
    if(tuf){
        tutint += (255.0 / (float)(fps * 1.5));
        if(tutint >= 220.0) tuf = false;
    }else{
        tutint -= (255.0 / (float)(fps * 1.5));
        if(tutint <= 100.0) tuf = true;
    }
    
    //-ゴール画像
    tint(255, map(game_count, 0, 300, 0, 255));
    image(goaltitle, width / 2, height / 2, goaltitle.width * (float)((float)game_count / 300.0), goaltitle.height * (float)((float)game_count / 300.0));
    noTint();
    
    //-スコア
    fill(255, 117, 31, map(game_count, 0, 300, 0, 255));
    text("かぜにあたったかいすう：" + dc + " かい", width / 2, height / 2 - map(game_count, 0, 300, 0, 200));

    
    sun.playSun();
}


//--- 背景の表示 ---//
void outback(){
    imageMode(CORNER);    
    
    //進行度に応じて表示位置を変更していく(トリミングした部分の表示)
    image(back.get((int)back_count, 0, (int)back_count + width, height), 0, 0);
        
    imageMode(CENTER);
}


//--- 衝突判定によるゲーム処理 ---//
void storyhit(){
    //-衝突判定
    for(int i = 0; i < nw.size(); i++){
        /*--- 太陽と風(風が存在するときのみ) ---*/
        if(hit(sun.getPosX(), sun.getPosY(), nw.get(i).getPosWX(), nw.get(i).getPosWY(), (sun.getWidth() / 2 + nw.get(i).getWWidth() / 2), (sun.getHeight() / 2 + nw.get(i).getWHeight() / 2)) && nw.get(i).getFlg()){
            //-風を消す
            nw.get(i).outWF(false);
        }
        /*--- 旅人と風(風が存在するときのみ) ---*/
        if(hit(trav.getPosX(), trav.getPosY(), nw.get(i).getPosWX(), nw.get(i).getPosWY(), (trav.getWidth() / 2 + nw.get(i).getWWidth() / 2), (trav.getHeight() / 2 + nw.get(i).getWHeight() / 2)) && nw.get(i).getFlg()){
            //-ボイス    
            voice.rewind();
            voice.play(); 
            //-風を消す
            nw.get(i).outWF(false);
            //-旅人のダメージ処理
            trav.damage();
            //-ダメージカウント
            dc++;
        }else{
            trav.recover(fps);
        }
        /*--- 太陽と北風 ---*/
        if(hit(sun.getPosX(), sun.getPosY(), nw.get(i).getPosX(), nw.get(i).getPosY(), (sun.getWidth() / 2 + nw.get(i).getWidth() / 2), (sun.getHeight() / 2 + nw.get(i).getHeight() / 2))){
            nw.get(i).damage(fps);
            if(nw.get(i).getHP() == 0){
                nw.remove(i);
            }    
        }else{
            nw.get(i).recover(fps);
        }
    }
}


//--- 衝突判定（範囲座標一致判定） ---//
boolean hit(float x1, float y1, float x2, float y2, int rx, int ry){
    //-水平方向、垂直方向の2地点間の距離を求める
    float dx = abs(x1 - x2), dy = abs(y1 - y2);
    
    //-求めた距離が指定された範囲内にあるか判定する
    if(dx <= (rx - ease) && dy <= (ry - ease)) return true;
    else return false;
}
    


//--- 風の移動 ---//
void transwind(int num){
    float x, y;
    //-ベジエ曲線を利用して風の軌道を計算
    //-X = bezierPoint(始点(北風のX座標) + 補正値(imageMode(CENTER)に合わせる), 制御点①のX座標, 制御点②のX座標, 終点(旅人のX座標), 現在の曲線上の位置(0.0～1.0の割合))
    //-X = bezierPoint(始点(北風のY座標) + 補正値(imageMode(CENTER)に合わせる), 制御点①のY座標, 制御点②のY座標, 終点(旅人のY座標), 現在の曲線上の位置(0.0～1.0の割合))
    if(nw.get(num).getPosX() <= width / 2){
        x = bezierPoint(nw.get(num).getPosX() + nw.get(num).getWWidth() / 2, nw.get(num).getCP1X(), nw.get(num).getCP2X(), trav.getPosX(), map(nw.get(num).getCount(), 0.0, fps * 3, 0.0, 1.0));
        y = bezierPoint(nw.get(num).getPosY() + nw.get(num).getWHeight() / 2, nw.get(num).getCP1Y(), nw.get(num).getCP2Y(), trav.getPosY(), map(nw.get(num).getCount(), 0.0, fps * 3, 0.0, 1.0));
    }else{
        x = bezierPoint(nw.get(num).getPosX() - nw.get(num).getWWidth() / 2, nw.get(num).getCP1X(), nw.get(num).getCP2X(), trav.getPosX(), map(nw.get(num).getCount(), 0.0, fps * 3, 0.0, 1.0));
        y = bezierPoint(nw.get(num).getPosY() + nw.get(num).getWHeight() / 2, nw.get(num).getCP1Y(), nw.get(num).getCP2Y(), trav.getPosY(), map(nw.get(num).getCount(), 0.0, fps * 3, 0.0, 1.0));
    }
    nw.get(num).moveW(x, y);
}


//--- サウンド終了処理 ---//
void stop(){
    bgm1.close();
    bgm2.close();
    voice.close();
    minim.stop();
    super.stop();
}
