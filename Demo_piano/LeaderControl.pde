/*****************************************************
    LeaderControl
    
    Copyright(c) 2015 Seiya Iwasaki
    
    This software is released under the MIT License.
    http://opensource.org/licenses/mit-license.php
*****************************************************/


class LeaderControl{
    /*--- フィールド ---*/
    
    // アプリケーション用イメージ
    private PImage imgLeader;
    private PImage titleBack;
    private PImage[] musicTitle;
    private float posX, posY;
    private int playingMusic;           // 現在再生中の楽曲の番号
    private boolean playable;           // 再生可能フラグ
    
    // シリアル通信用
    private int switchType;             // スイッチの種類（楽器の種類）
    private int isTouched;              // スイッチがタッチされているかどうか
    private int preTouched;             // 前回のタッチ状態

    
    /*--- コンストラクタ ---*/
    LeaderControl(float posX, float posY, String[] music_name){
        this.imgLeader = new PImage();
        this.titleBack = new PImage();
        this.musicTitle = new PImage[music_name.length];
        this.posX = posX;
        this.posY = posY;
        this.playingMusic = 0;
        this.playable = false;
        this.switchType = 0;
        this.isTouched = 0;
        this.preTouched = 0;
        
        this.imgLeader = loadImage("image\\leader\\leader.png");
        this.imgLeader.resize(this.imgLeader.width / 2, this.imgLeader.height / 2);
        this.titleBack = loadImage("image\\leader\\titleBack.png");
        for(int i = 0; i < musicTitle.length; i++){
            musicTitle[i] = loadImage("image\\leader\\" + music_name[i] + ".png");
        }
    }
    
    /*--- メソッド ---*/
    
    /* 画像イメージの表示 */
    void playImage(){
        if(playable){
            image(imgLeader, posX, posY);
            image(titleBack, displayWidth - titleBack.width / 2 - 30, displayHeight - titleBack.height);
            image(musicTitle[playingMusic], displayWidth - titleBack.width / 2 - 30, (displayHeight - titleBack.height) - musicTitle[playingMusic].height / 2);
        }else{
            image(imgLeader, posX, posY);
        }
    }
    
    /* 音楽を変更 */
    void changeMusic(){
        if(playingMusic < musicTitle.length - 1) playingMusic++;
        else playingMusic = 0;
    }
    

    /* スイッチの種類を更新 */
    void setSwitchType(int type){
        switchType = type;
        // スイッチの種類に応じて再生可能状態かどうか決定しておく
        if(switchType == 3){
            playable = true;
        }else{
            playable = false;
        }
    }


    /* スイッチが押された時に音楽を変更する */
    boolean updateMusic(){
        if(preTouched != isTouched){
            preTouched = isTouched;
            if(isTouched == 1){
                changeMusic();
                return true;
            }
        }
        return false;
    }


    /* スイッチのタッチ状態を更新 */
    void setSwitchTouched(int touch){
            isTouched = touch;
    }


    /* 音楽が再生可能状態かどうか取得する */
    boolean getPlayable(){
        return playable;
    }
    
    
    /* 再生中の楽曲の取得 */
    int getPlayingMusic(){
        return playingMusic;   
    }
    
    /* スイッチの種類の取得 */
    int getSwitchType(){
        return switchType;
    }


    /* スイッチのタッチ状態の取得 */
    int getSwitchTouched(){
        return isTouched;
    }
}
