import oscP5.*;
import netP5.*;

OscP5 osc;

// Current positions and angles
float x1 = 100, y1 = 100, ang1 = 0; // 初期位置を少しずらしておきます
float x2 = 200, y2 = 200, ang2 = 0;

// Target positions and angles (updated via OSC or Mouse)
float tx1 = 0, ty1 = 0, tAng1 = 0;
float tx2 = 0, ty2 = 0, tAng2 = 0;

// Smoothing factor (0 = no movement, 1 = instant)
float smoothing = 0.05;

// --- ここから追加 ---
// 円の見た目に関する設定
float circleSize = 50;
float circleRadius = circleSize / 2;

// どの円をドラッグしているかを管理する変数 (0:なし, 1:ID1, 2:ID2)
int draggedId = 0;
// --- ここまで追加 ---


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
}

void draw() {
  background(32);

  // 線形補間でスムーズに移動
  x1 = lerp(x1, tx1, smoothing);
  y1 = lerp(y1, ty1, smoothing);
  ang1 = lerp(ang1, tAng1, smoothing);

  x2 = lerp(x2, tx2, smoothing);
  y2 = lerp(y2, ty2, smoothing);
  ang2 = lerp(ang2, tAng2, smoothing);

  // ID=1 を緑、ID=2 を青で描画
  fill(0, 255, 0);
  ellipse(x1, y1, circleSize, circleSize);
  text("ID1: (" + nf(x1, 1, 1) + ", " + nf(y1, 1, 1) + ")  " + nf(ang1, 1, 1) + "°", 10, 20);

  fill(0, 0, 255);
  ellipse(x2, y2, circleSize, circleSize);
  text("ID2: (" + nf(x2, 1, 1) + ", " + nf(y2, 1, 1) + ")  " + nf(ang2, 1, 1) + "°", 10, 40);
}

// OSC メッセージ受信
void oscEvent(OscMessage msg) {
  // マウスでドラッグ中はOSCの座標更新を無視する
  if (draggedId != 0) {
    return;
  }
  
  String addr = msg.addrPattern();
  if (addr.equals("/marker/1")) {
    tx1 = width - msg.get(0).floatValue();
    ty1 = msg.get(1).floatValue();
    tAng1 = msg.get(2).floatValue();
  } else if (addr.equals("/marker/2")) {
    tx2 = width - msg.get(0).floatValue();
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
