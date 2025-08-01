import oscP5.*;
import netP5.*;
OscP5 osc;

// Current positions and angles
float x1 = 100, y1 = 100, ang1 = 360; // 初期位置を少しずらしておきます
float x2 = 200, y2 = 200, ang2 = 0;

// Target positions and angles (updated via OSC or Mouse)
float tx1 = 0, ty1 = 0, tAng1 = 60;
float tx2 = 0, ty2 = 0, tAng2 = 0;

// Smoothing factor (0 = no movement, 1 = instant)
float smoothing = 0.05;

// 円の見た目に関する設定
float circleSize = 50;
float circleRadius = circleSize / 2;

// どの円をドラッグしているかを管理する変数 (0:なし, 1:ID1, 2:ID2)
int draggedId = 0;

// --- ここまで追加 ---
float baseAngle=0;

void setup() {

  size(1920, 1080);

  // ポート番号は Python 側の OSC_PORT と合わせる
  osc = new OscP5(this, 8000);
  ellipseMode(CENTER);
  textAlign(LEFT, BOTTOM);
  
  // 初期値をターゲットに合わせる
  tx1 = x1;
  ty1 = y1;
  tAng1 = ang1;
  tx2 = x2;
  ty2 = y2;
  tAng2 = ang2;
  fullScreen();
}



void draw() {
  fill(32, 32, 32, 30);  // 背景に半透明の黒を塗ることで残像を表現
  rect(0, 0, width, height);
  //background(32);
  
  // 線形補間でスムーズに移動
  x1 = lerp(x1, tx1, smoothing);
  y1 = lerp(y1, ty1, smoothing);
  ang1 = lerp(ang1, tAng1, smoothing);
  x2 = lerp(x2, tx2, smoothing);
  y2 = lerp(y2, ty2, smoothing);
  ang2 = lerp(ang2, tAng2, smoothing);
  
  
  fill(255);
  ellipse(x1, y1, circleSize, circleSize);
  text("ID1: (" + nf(x1, 1, 1) + ", " + nf(y1, 1, 1) + ")  " + nf(ang1, 1, 1) + "°", 10, 20);
  ellipse(x2, y2, circleSize, circleSize);
  text("ID2: (" + nf(x2, 1, 1) + ", " + nf(y2, 1, 1) + ")  " + nf(ang2, 1, 1) + "°", 10, 40);

  int count  = 100;// 点の数
  count=int(map(x1, 0, width, 10, 50));
  float radius = 0;    // 円の半径
  float cx = width * 0.5;
  float cy = height * 0.5;

  float hue=map(x2, 0, height, 0, 360);
  colorMode(HSB, 360, 100, 100);  // H:0-360, S:0-100, B:0-100 に設定
  stroke(hue, 100, 100);

  noFill();
  //stroke(255,0,0);

  float noiseScale = 0.05; // ノイズのスケール
  float noiseStrength = 100; // ゆらぎの強さ（px単位）

  float distBetweenTargets = dist(tx1, ty1, tx2, ty2);
  float baseRadius = map(distBetweenTargets, 0, width, 0, width); // 必要に応じてmin/max調整

  // --- 描画ループ内 ---
  for (int j = 0; j < count; j++) {
    float o = float(j) / (count - 1);
    float twist = map(ang2, 0, 360, -PI, PI);  // ねじれの最大幅
    float offset = map(j, 0, count, -twist / 2, twist / 2); // iに応じて徐々に変化する

    for (int i = 0; i < 50; i++) {
      float angle = TWO_PI * i / 50 + baseAngle + offset;

      // --- ノイズを使用して距離を揺らがせる ---
      float noiseFactor = noise(j * 0.1, i * 0.1, frameCount * 0.01);
      radius = baseRadius * o * (0.7 + 0.6 * noiseFactor);  // ← ここを修正

      float x = cx + sin(angle) * radius;
      float y = cy + cos(angle) * radius;

      float d = map(j, 0, count - 1, 1, 100);
      ellipse(x, y, d, d);
    }
  }

  // 角度に応じて回転速度を変える（最大±0.01rad/frame）
  float angleSpeed = map(ang1, 0, 360, -TWO_PI * 0.005, TWO_PI * 0.005);
  baseAngle += angleSpeed;
  //baseAngle+=TWO_PI*0.001;
}



// OSC メッセージ受信
void oscEvent(OscMessage msg) {
  // マウスでドラッグ中はOSCの座標更新を無視する
  if (draggedId != 0) {
    return;
  }

  String addr = msg.addrPattern();

  if (addr.equals("/marker/1")) {
    tx1 = msg.get(0).floatValue();
    ty1 = msg.get(1).floatValue();
    tAng1 = msg.get(2).floatValue();
  } else if (addr.equals("/marker/2")) {
    tx2 = msg.get(0).floatValue();
    ty2 = msg.get(1).floatValue();
    tAng2 = msg.get(2).floatValue();
  }
}



// --- ここから追加したマウス操作の関数 ---
/**
 
 * マウスボタンが押された瞬間に呼ばれる関数
 
 */

void mousePressed() {

  // マウスと円の中心との距離を計算
  float d1 = dist(mouseX, mouseY, x1, y1);
  float d2 = dist(mouseX, mouseY, x2, y2);

  // マウスが円の中にあるか判定
  if (d1 < circleRadius) {
    // 円1をクリックした
    draggedId = 1;
  } else if (d2 < circleRadius) {
    // 円2をクリックした
    draggedId = 2;
  } else {
    // 何もない場所をクリックした
    draggedId = 0;
  }
}



/**
 
 * マウスがドラッグされている間、常に呼ばれる関数
 
 */

void mouseDragged() {
  if (draggedId == 1) {
    // 円1をドラッグ中なら、円1の目標位置をマウス座標に更新
    tx1 = mouseX;
    ty1 = mouseY;
  } else if (draggedId == 2) {
    // 円2をドラッグ中なら、円2の目標位置をマウス座標に更新
    tx2 = mouseX;
    ty2 = mouseY;
  }
}


/**
 * マウスボタンが離された瞬間に呼ばれる関数
 */

void mouseReleased() {
  // どの円もドラッグしていない状態に戻す
  draggedId = 0;
}

void mouseWheel(MouseEvent event) {
  float delta = event.getCount(); // スクロール量（1または-1）
  // どちらかの円がクリックされているときだけ操作
  if (draggedId == 1) {
    tAng1 += delta * 5; // 角度を増減（調整可）
  } else if (draggedId == 2) {
    tAng2 += delta * 5;
  }
}
