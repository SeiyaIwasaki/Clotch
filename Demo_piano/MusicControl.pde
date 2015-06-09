/*****************************************************
    MusicControl
    
    Copyright(c) 2015 Seiya Iwasaki
    
    This software is released under the MIT License.
    http://opensource.org/licenses/mit-license.php
*****************************************************/


class MusicControl{
    /*--- フィールド ---*/
    
    // アプリケーション用イメージ
    private PImage imgAnimal;
    private PImage[] imgPiano;
    private PImage[] imgViolin;
    private PImage[] imgDrum;
    private float posX, posY;

    // 音楽ファイル用
    private AudioPlayer soundPiano;
    private AudioPlayer soundViolin;
    private AudioPlayer soundDrum;
    private int playingPoint;           // 再生中の位置 ms
    private short playingSound;         // 現在再生されている楽器 0 = None, 1 = Piano, 2 = Violin, 3 = Drum
    private int sync;                   // 同期精度 (High = 1 - Low = 1000 ms)

    // シリアル通信用
    private int switchType;             // スイッチの種類（楽器の種類）
    private int isTouched;              // スイッチがタッチされているかどうか
    
    /* コンストラクタ */
    MusicControl(String animal_name, float posX, float posY){
        // インスタンス化
        this.imgAnimal = new PImage();
        this.imgPiano = new PImage[2];
        this.imgViolin = new PImage[2];
        this.imgDrum = new PImage[2];
        this.posX = posX;
        this.posY = posY;
        this.playingPoint = 0;
        this.playingSound = 0;
        this.switchType = 0;
        this.isTouched = 0;
        this.sync = 500;
        
        // 画像ファイル取得とリサイズ
        this.imgAnimal = loadImage("image\\" + animal_name + "\\" + animal_name + ".png");
        this.imgAnimal.resize(this.imgAnimal.width / 2, this.imgAnimal.height / 2);
        for(int i = 0; i < 2; i++){
            this.imgPiano[i] = loadImage("image\\" + animal_name + "\\piano" + str(i + 1) + ".png");
            this.imgPiano[i].resize(this.imgPiano[i].width / 2, this.imgPiano[i].height / 2);
            this.imgViolin[i] = loadImage("image\\" + animal_name + "\\violin" + str(i + 1) + ".png");
            this.imgViolin[i].resize(this.imgViolin[i].width / 2, this.imgViolin[i].height / 2);
            this.imgDrum[i] = loadImage("image\\" + animal_name + "\\drum" + str(i + 1) + ".png");
            this.imgDrum[i].resize(this.imgDrum[i].width / 2, this.imgDrum[i].height / 2);
        }
    }
    
    /* メソッド */
    
    /* 再生する楽曲の選択 */
    void selectMusic(String music_name, Minim minim){
        soundPiano = minim.loadFile("sound\\" + music_name + "\\piano.mp3");
        soundViolin = minim.loadFile("sound\\" + music_name + "\\violin.mp3");
        soundDrum = minim.loadFile("sound\\" + music_name + "\\drum.mp3");
    }
    
    /* 全停止 */
    void stopMusic(){
        soundPiano.close();
        soundViolin.close();
        soundDrum.close();
        playingPoint = 0;
    }
    
    /* ピアノ音源を再生する */
    void playPiano(){
        if(playingPoint > (soundPiano.position() / sync)){
            soundPiano.cue(playingPoint * sync);
        }
        if(!soundPiano.isPlaying()){
            soundPiano.play();
            playingSound = 1;
        }
    }
    
    /* バイオリン音源を再生する */
    void playViolin(){
        if(playingPoint > (soundViolin.position() / sync)){
            soundViolin.cue(playingPoint * sync);
        }
        if(!soundViolin.isPlaying()){
            soundViolin.play();
            playingSound = 2;
        }
    }
    
    /* ドラム音源を再生する */
    void playDrum(){
        if(playingPoint > (soundDrum.position() / sync)){
            soundDrum.cue(playingPoint * sync);
        }
        if(!soundDrum.isPlaying()){
            soundDrum.play();
            playingSound = 3;
        }
    }

    /* 音源再生処理 */
    void playSound(){
        switch(switchType){
            case 0:         // スイッチなし
                pauseSound();
                return;
            case 19:        // ピアノスイッチ
                if(isTouched == 1) playPiano();
                else if(playingSound == 1) pauseSound();
                return;
            case 8:         // バイオリンスイッチ
                if(isTouched == 1) playViolin();
                else if(playingSound == 2) pauseSound();
                return;
            case 5:         // ドラムスイッチ
                if(isTouched == 1) playDrum();
                else if(playingSound == 3) pauseSound();
                return;
            default :       // その他スイッチ
                return;    
        }
    }
    
    /* 再生中の音源を一時停止する */
    void pauseSound(){
        switch(playingSound){
            case 0:
                return;
            case 1:
                soundPiano.pause();
                playingPoint = soundPiano.position() / sync;
                playingSound = 0;
                return;
            case 2:
                soundViolin.pause();
                playingPoint = soundViolin.position() / sync;
                playingSound = 0;
                return;
            case 3:
                soundDrum.pause();
                playingPoint = soundDrum.position() / sync;
                playingSound = 0;
                return;
        }
    }
    
    /* 画像イメージの表示 */
    void playImage(){
        switch(switchType){
            case 0:
                image(imgAnimal, posX, posY);
                break;
            case 19:
                if(isTouched == 1) image(imgPiano[1], posX, posY);
                else image(imgPiano[0], posX, posY);
                break;
            case 8:
                if(isTouched == 1) image(imgViolin[1], posX, posY);
                else image(imgViolin[0], posX, posY);
                break;
            case 5:
                if(isTouched == 1) image(imgDrum[1], posX, posY);
                else image(imgDrum[0], posX, posY);
                break;
            default:
                break;
        }
    }
    
    /* 再生位置の更新（外部から） */
    void setPosition(int point){
        playingPoint = point;
    }

    /* 再生位置の更新（内部から） */
    void updatePosition(){
        switch(playingSound){
            case 0:
                break;
            case 1:
                playingPoint = soundPiano.position() / sync;
                break;
            case 2:
                playingPoint = soundViolin.position() / sync;
                break;
            case 3:
                playingPoint = soundDrum.position() / sync;
                break;
        }
    }

    /* スイッチの種類を更新 */
    void setSwitchType(int type){
        switchType = type;
    }

    /* スイッチのタッチ状態を更新 */
    void setSwitchTouched(int touch){
        isTouched = touch;
    }

    /* 現在の再生状態の取得 */
    short getPlayingSound(){
        return playingSound;
    }

    /* 再生位置の取得 */
    int getPosition(){
        return playingPoint;
    }

    /* スイッチの種類の取得 */
    int getSwitchType(){
        return switchType;
    }

    /* スイッチのタッチ状態の取得 */
    int getSwitchTouched(){
        return isTouched;
    }

    /* 終了処理 */
    void stop(){
        soundPiano.close();
        soundViolin.close();
        soundDrum.close();
    }
}
    
