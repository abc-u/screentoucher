import oscP5.*;
import netP5.*;
import ddf.minim.*;
import ddf.minim.ugens.*;  // Oscil などの UGen を使うために必要

OscP5 osc;
Minim minim;
AudioOutput out;
Oscil sineOsc;  // ここでオシレーターを定義

float x1 = 100, y1 = 100, ang1 = 0;
float x2 = 200, y2 = 200, ang2 = 0;

float tx1 = 0, ty1 = 0, tAng1 = 0;
float tx2 = 0, ty2 = 0, tAng2 = 0;

float smoothing = 0.05;

float circleSize = 50;
float circleRadius = circleSize / 2;

int draggedId = 0;

void setup() {
  size(1920, 1080);
  osc = new OscP5(this, 8000);

  minim = new Minim(this);
  out = minim.getLineOut(Minim.STEREO);

  // オシレーター初期化：初期周波数440Hz, 振幅0.3, 波形はサイン波
  sineOsc = new Oscil(440, 0.3, Waves.SINE);
  sineOsc.patch(out);  // 出力へ接続

  ellipseMode(CENTER);
  textAlign(LEFT, BOTTOM);

  tx1 = x1;
  ty1 = y1;
  tAng1 = ang1;
  tx2 = x2;
  ty2 = y2;
  tAng2 = ang2;
}

void draw() {
  background(32);

  x1 = lerp(x1, tx1, smoothing);
  y1 = lerp(y1, ty1, smoothing);
  ang1 = lerp(ang1, tAng1, smoothing);

  x2 = lerp(x2, tx2, smoothing);
  y2 = lerp(y2, ty2, smoothing);
  ang2 = lerp(ang2, tAng2, smoothing);

  fill(0, 255, 0);
  ellipse(x1, y1, circleSize, circleSize);
  text("ID1: (" + nf(x1, 1, 1) + ", " + nf(y1, 1, 1) + ")  " + nf(ang1, 1, 1) + "°", 10, 20);

  fill(0, 0, 255);
  ellipse(x2, y2, circleSize, circleSize);
  text("ID2: (" + nf(x2, 1, 1) + ", " + nf(y2, 1, 1) + ")  " + nf(ang2, 1, 1) + "°", 10, 40);

  // x1 の位置に応じて音の周波数を変える（200Hz〜1000Hz）
  float freq = map(x1, 0, width, 200, 1000);
  sineOsc.setFrequency(freq);
}

void oscEvent(OscMessage msg) {
  if (draggedId != 0) return;

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

void mousePressed() {
  float d1 = dist(mouseX, mouseY, x1, y1);
  float d2 = dist(mouseX, mouseY, x2, y2);

  if (d1 < circleRadius) {
    draggedId = 1;
  } else if (d2 < circleRadius) {
    draggedId = 2;
  } else {
    draggedId = 0;
  }
}

void mouseDragged() {
  if (draggedId == 1) {
    tx1 = mouseX;
    ty1 = mouseY;
  } else if (draggedId == 2) {
    tx2 = mouseX;
    ty2 = mouseY;
  }
}

void mouseReleased() {
  draggedId = 0;
}
