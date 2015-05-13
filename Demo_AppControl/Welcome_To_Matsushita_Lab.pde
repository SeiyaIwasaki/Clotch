/*******************************************
            Iwasaki Seiya
           Open Campus 2014
       Welcome To Matsushita Lab 
*******************************************/

/*-- ライブラリのインポート --*/
import processing.video.*;
import gab.opencv.*;
import java.awt.Rectangle;

/*-- オブジェクト作成 --*/
Capture cam;                // キャプチャークラス
Mosaic mos;                 // モザイク処理クラス
AnimString ani;             // アニメーションクラス
FaceDetection face;         // 顔認識クラス

//- 編集可能
int mos_num_x = 50;         // モザイクの水平方向の数(default:50)
int mos_num_y = 25;         // モザイクの垂直方向の数(default:25)
int mos_size = 10;          // モザイクのサイズ
int ani_num_x = 90;         // アニメーション中のモザイクの水平方向の数(default:90)
int ani_num_y = 90;         // アニメーション中のモザイクの垂直方向の数(default:90)
float min_size = 1.8;       // アニメーション中のモザイクのサイズの最小値
int ani_speed = 100;        // アニメーションの速さ
int face_min = 1500;        // 顔認識する顔の最小サイズを指定(w * h)(default:1500=実寸約150cm以内の顔)
int start_sec = 0;          // 顔認識が成功してから start_sec 秒後にアニメーションを開始させる
int end_sec = 8;            // アニメーションが完了してから end_sec 秒後にモザイク表示に復帰する
int next_sec = 2;           // 復帰後 next_sec 秒後に顔認識処理を開始する

//- 編集不可
int fps = 30;               // フレームレート
PImage[] string_img;        // 文字列のイメージ画（白黒）20個まで
int img_num = 0;            // イメージ画の数
int start_count = 0;        // 顔認識が成功してから数秒後にアニメーションを開始させるためのカウント
boolean count_flg = false;  // start_count のカウント処理を行うかどうか
int ani_stage = 0;          // アニメーション処理の段階分け（モザイク表示→アニメーション、 アニメーション→モザイク表示）
boolean ani_flg = false;    // アニメーション起動フラグ
int ani_count = 0;          // アニメーション用のフレームカウント
float ani_size = mos_size;  // 大きさを変化させていくための変数

//- ゼミ展用の機能
int pre_mouseX = 0, pre_mouseY = 0;  // 前回のマウスの位置を記憶させておく
int mouse_count = 0;                 // おなじ座標にマウスが連続してある場合カウントする
float mouse_off_sec = 1;             // おなじ座標に何秒マウスがあった場合モザイクの最大化をやめるか
int maximize_size = mos_size + 5;    // モザイクの最大化サイズ
int mosID;                           // 特定したモザイク識別用
boolean act_flg = false;             // モザイクの最大化のオン・オフ

ArrayList<Rectangle> faces = new ArrayList<Rectangle>(); // 顔リスト受け取り用
ArrayList<Integer> fmosID = new ArrayList<Integer>();      // 顔の位置にあるモザイクを番号を保存
int he_count = 0;                    // 合図エフェクトアニメーション用カウンタ


/*-----------------------------------------------------------------------------------------------------------------*/


/*-- Setup --*/
void setup(){
    
    /*---------- 画面基本設定 ----------*/
    size(displayWidth, displayHeight);
    colorMode(RGB, 256, 256, 256, 100);
    rectMode(CORNER);
    noStroke();
    noCursor();
    smooth();
    frameRate(fps);
    
    
    /*---------- インスタンス化 ----------*/
    
    // キャプチャークラス
    cam = new Capture(this, 320, 240, fps);
    cam.start();
    
    // モザイク処理クラス
    mos = new Mosaic(mos_num_x, mos_num_y, mos_size);
    mos.initPos(cam.width, cam.height);
    mos.updateRanSize();
    
    // 顔認識クラス
    face = new FaceDetection(this, cam.width, cam.height);
    
    // 画像読み込み
    loadStringImage();  
}


/*-- Draw --*/
void draw(){
    
    /*---------- 入力処理 ----------*/
    
    // モザイクの色の入力
    mos.updateColor(cam);
    // 顔認識用のイメージの入力
    face.inputImage(cam);
    
    
    /*---------- 内部処理 ----------*/
    
    // アニメーション処理全般
    animation();
    
    
    /*---------- 出力処理 ----------*/
    
    // 出力するサイズを現在のPCの画面サイズに合わせておく
    scale((float)width / cam.width, (float)height / cam.height);
    
    // 背景を黒にしておく
    background(0);
    
    // モザイクの表示
    mos.outMosaic();
    
    // マウスが動いている場合はその位置のモザイクを最前面にして最大化
    if(act_flg) mos.outMosaicTar(mosID);
    
    // 合図エフェクト
    if(ani_stage == 9){
        if(he_count < 15) hinteffect(he_count);
        else hinteffect(fps - he_count);
    }
    
    /*---------- 更新処理 ----------*/
    
    // カウント処理
    if(count_flg) start_count++;
    
    /*---------- テスト ------------*/
    
    // マウスの位置を出力
//    println("X = " + mouseX + " : Y = " + mouseY);

    // 顔認識結果を画面上に表示
//    stroke(#90FF8B);
//    noFill();
//    for(int i = 0; i < faces.size(); i++){
//        rect(faces.get(i).x + faces.get(i).width / 2, faces.get(i).y + faces.get(i).height / 2, faces.get(i).width, faces.get(i).height);            
//        println("face size = " + faces.get(i).width * faces.get(i).height);
//    }
    
    // 顔に対応するモザイクの確認
//    for(int i = 0; i < fmosID.size(); i++){
//        mos.inputOneMosSize(fmosID.get(i), maximize_size);
//        mos.outMosaicTar(fmosID.get(i));
//    }
}


/*-- 最新の映像を取得する --*/
void captureEvent(Capture cam){
    cam.read();
}


/*-- 画像読み込み処理(ファイル数 20 まで) --*/
void loadStringImage(){
    string_img = new PImage[20];
    
    for(int i = 0; i < string_img.length; i++){
        string_img[i] = loadImage("message" + (i + 1) + ".jpg");
        
        // 画像が読み込めなかったとき(エラー表示は無視する)
        if(string_img[i] == null){
            // 数を記憶してループを抜ける
            img_num = i;
            break;
        }
        
        // 画像が読み込めたときはリサイズしておく
        string_img[i].resize(cam.width, cam.height);
    }
}


/*-- アニメーション処理全般 --*/
void animation(){
    // アニメーション処理
    switch(ani_stage){
        /*--- 通常のカメラ映像をモザイク表示にした状態 ---*/
        case 0:
           // マウスの位置によるモザイク最大化の判定
           mouseact();
           // 前回検出され保存されている顔のリストとそれに対応するモザイクのリストは削除しておく
           face.clearFaces();
           fmosID.clear();
           // 顔認識の結果に応じてアニメーションを開始する 
           if(face.faceDetect(face_min)){
               // 検出された顔リストを受け取っておく
               faces = face.getFaces();
               // 各々の顔に対応するモザイクを求めておく
               getFaceMos();
               
               // 合図エフェクトに飛ぶ
               ani_stage = 9;
               count_flg = true;
               
               break;
           }else{
               break;
           }
           
        /*--- 顔認識が成功してからアニメーションが起きるまでの間 ---*/
        case 1:
            // マウスの位置によるモザイク最大化の判定
            mouseact();
            // 顔認識が成功したら start_sec 秒待つ
            if(start_count / fps >= start_sec){
                ani_stage = 2;
                start_count = 0;
                count_flg = false;
                
                // アニメーションのための前準備
                initmostoani();
            }
            break;
            
        /*--- モザイクが動き出し文字を形取るアニメーション ---*/
        case 2:
            // モザイク表示からイメージ画へ
            mostoani();
            
            // アニメーションが完了したら
            if(ani_flg == false){
                ani_stage = 3;
                count_flg = true;
            }
            break;
            
        /*--- モザイクがシルエット形どっている状態 ---*/
        case 3:
            // end_sec 秒待つ
            if(start_count / fps >= end_sec){
                ani_stage = 4;
                start_count = 0;
                count_flg = false;
                
                // アニメーションのための前準備
                initanitomos();
            }
            break;
            
        /*--- シルエット表示から通常の表示に戻るアニメーション ---*/
        case 4:
            // イメージ画からモザイク表示へ
            anitomos();
            
            // アニメーションが完了したら
            if(ani_flg == false){
                ani_stage = 5;
                count_flg = true;
                
                // モザイクのサイズにばらつきを与えておく
                mos.updateRanSize();
                // アニメーション初期化
                ani_size = mos_size;
            }
            break;
            
        /*--- 次の顔認識までの間 ---*/
        case 5:
            // マウスの位置によるモザイク最大化の判定
            mouseact();
            // next_sec 秒待つ
            if(start_count / fps >= next_sec){
                ani_stage = 0;
                start_count = 0;
                count_flg = false;
            }
            break;
            
        /*--- 合図エフェクトアニメーション ---*/
        case 9:
            face.clearFaces();
            fmosID.clear();
            face.faceDetect(face_min);
            faces = face.getFaces();
            getFaceMos();
            
            he_count++;
            if(he_count > 30){
                ani_stage = 1;
                he_count = 0;
            }
            break;
    }
}


/*-- モザイク表示からアニメーションさせてイメージの表示へ --*/
void mostoani(){
    // アニメーション処理
    if(ani_flg){
        // ベジエ曲線を利用したアニメーション：曲線上の位置を 0.0 ～ 1.0 の割合で指定する
        mos.inputPos(ani.getAniPos((float)ani_count / ani_speed));
        
        // ベジエ曲線上にいる間はモザイクの大きさを徐々に小さくする（ばらつきは与えない）
        mos.inputSize(ani_size);
        if(ani_size > min_size) ani_size -= 0.15;
        
        // 終点に到達したとき
        if((float)ani_count / ani_speed >= 1.0){
            // アニメーション処理を終える
            ani_flg = false;
        }
    }
    
    // カウント処理
    ani_count++;
}


/*-- イメージ表示からアニメーションさせてモザイクの表示へ --*/
void anitomos(){
    // アニメーション処理
    if(ani_flg){
        // ベジエ曲線を利用したアニメーション：曲線上の位置を 0.0 ～ 1.0 の割合で指定する
        mos.inputPos(ani.getAniPos(1.0 - (float)ani_count / ani_speed));
        
        // ベジエ曲線上にいる間はモザイクの大きさを徐々に大きくする（ばらつきは与えない）
        mos.inputSize(ani_size);
        if(ani_size < mos_size) ani_size += 0.15;
        
        // 始点に到達したとき
        if((float)ani_count / ani_speed >= 1.0){
            // アニメーション処理を終える
            ani_flg = false;
        }
    }
    
    // カウント処理
    ani_count++;
}


/*-- モザイク表示からアニメーションへ移る前準備 --*/
void initmostoani(){
    ani_flg = true;
    ani_count = 0;
    
    // アニメーション用にモザイクの数を増やす
    mos = new Mosaic(90, 90, 7);
    mos.initPos(cam.width, cam.height);
    
    // アニメーション処理の準備
    ani = new AnimString(string_img[(int)random(0, 2000) % img_num]);
    ani.inputWhitePos();
    ani.inputMosNum(mos.getMosNum());
    ani.inputStart(mos.getMosPos());
    ani.inputEndPos();
    ani.initControlPoint(cam.width, cam.height);
}


/*-- イメージ画からアニメーションへ移る前準備 --*/
void initanitomos(){
    ani_flg = true;
    ani_count = 0;
    
    // モザイクの数を元に戻す
    mos = new Mosaic(mos_num_x, mos_num_y, mos_size);
    mos.initPos(cam.width, cam.height);
    
    // アニメーション処理の準備
    ani.inputMosNum(mos.getMosNum());
    ani.inputStart(mos.getMosPos());
    ani.inputEndPos();
    ani.initControlPoint(cam.width, cam.height);
}


/*-- マウスアクション：マウスの位置のモザイクを最大化 --*/
void mouseact(){
    // 前回のマウスの位置と現在のマウスの位置が異なる場合
    // モザイクの指定を更新して最大化を継続する
    if(pre_mouseX != mouseX || pre_mouseY != mouseY){
        // 前回のマウスの位置にあるモザイクを特定する
        int mos_x = (int)map(pre_mouseX, 0, displayWidth, 0, mos_num_x);
        int mos_y = (int)map(pre_mouseY, 0, displayHeight, 0, mos_num_y);
        mosID = mos_y * mos_num_x + mos_x;
        
        // まず前回最大化したモザイクを通常のサイズへ戻しておく
        mos.inputOneMosSize(mosID, mos_size);
        
        // 現在のマウスの位置にあるモザイクを特定する
        mos_x = (int)map(mouseX, 0, displayWidth, 0, mos_num_x);
        mos_y = (int)map(mouseY, 0, displayHeight, 0, mos_num_y);
        mosID = mos_y * mos_num_x + mos_x;
        
        // 現在のマウスの位置にあるモザイクを最大化する
        mos.inputOneMosSize(mosID, maximize_size);
        
        // カウント初期化
        mouse_count = 0;
        
        // フラグを立てる
        act_flg = true;
    }else{
        // 前回とマウスの位置が同じ場合はカウントアップ
        mouse_count++;
        
        // 指定の時間以上マウスが同じ位置にある場合はモザイクの最大化をオフ
        if(mouse_count > mouse_off_sec * fps && act_flg){
            // 最大化されていたモザイクを元のサイズに戻す
            int mos_x = (int)map(pre_mouseX, 0, displayWidth, 0, mos_num_x);
            int mos_y = (int)map(pre_mouseY, 0, displayHeight, 0, mos_num_y);
            mosID = mos_y * mos_num_x + mos_x;
            mos.inputOneMosSize(mosID, mos_size);
            
            // フラグを折る
            act_flg = false;
        }
    }
    
    // 現在のマウスの位置を記憶しておく
    pre_mouseX = mouseX;
    pre_mouseY = mouseY;
}


// 顔の位置(顔の中心の座標)にあるモザイクを取得
void getFaceMos(){
    int cen_x, cen_y;        // 顔の中心の座標
    int mos_x, mos_y;        
    for(int i = 0; i < faces.size(); i++){
        cen_x = faces.get(i).x + faces.get(i).width / 2;
        cen_y = faces.get(i).y + faces.get(i).height / 2;
        mos_x = (int)map(cen_x, 0, cam.width, 0, mos_num_x);
        mos_y = (int)map(cen_y, 0, cam.height, 0, mos_num_y);
        fmosID.add(mos_y * mos_num_x + mos_x);
    }
}


// アニメーション開始合図エフェクト
void hinteffect(int i){
    int[] pos = new int[2];
    
    fill(#FF9E43);
    for(int j = 0; j < fmosID.size(); j++){
        pos = mos.getOneMosPos(fmosID.get(j));
        ellipse(pos[0], pos[1], i * i, i * i);
    }   
}
