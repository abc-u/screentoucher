import oscP5.*;
import netP5.*;
import java.util.ArrayList;
import processing.event.MouseEvent;

OscP5 osc;
PFont font;

// --- Marker positions & smoothing ---
float x1 = 100, y1 = 100, ang1 = 0;
float x2 = 200, y2 = 200, ang2 = 0;
float tx1, ty1, tAng1;
float tx2, ty2, tAng2;
float smoothing = 0.05;

// --- Circle appearance & drag state ---
float circleSize   = 50;
float circleRadius = circleSize / 2;
int draggedId = 0;  // 0=none, 1=ID1, 2=ID2

// --- Score counters ---
int score1 = 0;
int score2 = 0;

// --- Projectile management ---
ArrayList<Projectile> projectiles = new ArrayList<Projectile>();
float projectileSpeed = 15;           // 発射初速
int projectileSpawnInterval = 1000;   // 自動発射間隔 (ms)
int lastProjectileSpawnTime;
int radialShotCount = 4;             // 全方向に発射する弾数

// --- Block management ---
ArrayList<Block> blocks = new ArrayList<Block>();
float blockW = 100, blockH = 40;
int blockSpawnInterval = 1000;        // ブロック出現間隔 (ms)
int lastBlockSpawnTime;

// --- 追加: ホイール操作による回転速度（度／ノッチ） ---
float rotationSpeed = 20;


void setup() {
  size(1920, 1080);
  smooth(8);
  colorMode(HSB, 360, 100, 100, 100);
  frameRate(60);
  font = createFont("Arial", 18);
  textFont(font);

  surface.setResizable(false);
  osc = new OscP5(this, 8000);

  ellipseMode(CENTER);
  rectMode(CORNER);
  textAlign(LEFT, BOTTOM);

  // 初期ターゲット位置
  tx1 = x1; ty1 = y1; tAng1 = ang1;
  tx2 = x2; ty2 = y2; tAng2 = ang2;

  // タイマー初期化
  lastProjectileSpawnTime = millis();
  lastBlockSpawnTime      = millis();
}

void draw() {
  // グラデーション背景
  for (int y = 0; y < height; y++) {
    float t = map(y, 0, height, 0, 1);
    int c = lerpColor(color(200,50,90), color(260,60,60), t);
    stroke(c);
    line(0, y, width, y);
  }
  noStroke();

  // 定期的にブロックを出現
  if (millis() - lastBlockSpawnTime > blockSpawnInterval) {
    float bx = random(0, width - blockW);
    float by = random(100, height - blockH - 100);
    blocks.add(new Block(bx, by, blockW, blockH));
    lastBlockSpawnTime = millis();
  }

 // 定期的に両円から全方向へ球を発射（IDの角度をオフセットとして適用）
if (millis() - lastProjectileSpawnTime > projectileSpawnInterval) {
  for (int k = 0; k < radialShotCount; k++) {
    // 360度を均等分割した角度に、ID1の向きang1を足す
    float angle1 = ang1 + k * (360.0 / radialShotCount);
    spawnProjectile(x1, y1, angle1, 1);

    // 同様にID2の向きang2をオフセット
    float angle2 = ang2 + k * (360.0 / radialShotCount);
    spawnProjectile(x2, y2, angle2, 2);
  }
  lastProjectileSpawnTime = millis();
}

  // ブロック描画
  for (Block b : blocks) {
    b.display();
  }

  // 球の更新・描画・衝突処理
  for (int i = projectiles.size() - 1; i >= 0; i--) {
    Projectile p = projectiles.get(i);
    p.update();

    boolean hitBlock = false;
    for (int j = blocks.size() - 1; j >= 0; j--) {
      if (blocks.get(j).isHitCircle(p.pos.x, p.pos.y, p.radius)) {
        if (p.owner == 1) score1++;
        else if (p.owner == 2) score2++;
        blocks.remove(j);
        hitBlock = true;
        break;
      }
    }

    if (hitBlock || p.isDead()) {
      projectiles.remove(i);
    } else {
      p.display();
    }
  }

  // マーカーのスムーズ移動
  x1   = lerp(x1,   tx1,   smoothing);
  y1   = lerp(y1,   ty1,   smoothing);
  ang1 = lerp(ang1, tAng1, smoothing);
  x2   = lerp(x2,   tx2,   smoothing);
  y2   = lerp(y2,   ty2,   smoothing);
  ang2 = lerp(ang2, tAng2, smoothing);

  // 本体円で直接ブロック破壊
  for (int i = blocks.size() - 1; i >= 0; i--) {
    Block b = blocks.get(i);
    if      (b.isHitCircle(x1, y1, circleRadius)) { score1++; blocks.remove(i); }
    else if (b.isHitCircle(x2, y2, circleRadius)) { score2++; blocks.remove(i); }
  }

  // マーカー円に影と本体を描画
  // ID1
  fill(0,0,0,20);
  ellipse(x1+4, y1+4, circleSize, circleSize);
  fill(120,80,90);
  ellipse(x1,   y1,   circleSize, circleSize);
  // ID2
  fill(0,0,0,20);
  ellipse(x2+4, y2+4, circleSize, circleSize);
  fill(200,80,90);
  ellipse(x2,   y2,   circleSize, circleSize);

  // スコア表示
  fill(0,0,100);
  text("ID1 Breaks: " + score1, 10, 20);
  text("ID2 Breaks: " + score2, 10, 44);
}

void oscEvent(OscMessage msg) {
  if (draggedId != 0) return;
  String addr = msg.addrPattern();
  if (addr.equals("/marker/1")) {
    tx1   = width - msg.get(0).floatValue();
    ty1   = msg.get(1).floatValue();
    tAng1 = msg.get(2).floatValue();
  } else if (addr.equals("/marker/2")) {
    tx2   = width - msg.get(0).floatValue();
    ty2   = msg.get(1).floatValue();
    tAng2 = msg.get(2).floatValue();
  }
}

void mousePressed() {
  float d1 = dist(mouseX, mouseY, x1, y1);
  float d2 = dist(mouseX, mouseY, x2, y2);
  if      (d1 < circleRadius) draggedId = 1;
  else if (d2 < circleRadius) draggedId = 2;
  else                        draggedId = 0;
}

void mouseDragged() {
  if (draggedId == 1) { tx1 = mouseX; ty1 = mouseY; }
  else if (draggedId == 2) { tx2 = mouseX; ty2 = mouseY; }
}

void mouseReleased() {
  draggedId = 0;
}

void mouseWheel(MouseEvent event) {
  // ドラッグ中の円だけ角度を変える
  if (draggedId == 1) {
    tAng1 += event.getCount() * rotationSpeed;
  } else if (draggedId == 2) {
    tAng2 += event.getCount() * rotationSpeed;
  }
}

// ── Projectile 発射ヘルパー ──
void spawnProjectile(float cx, float cy, float angleDeg, int owner) {
  float rad = radians(angleDeg);
  float vx  = cos(rad) * projectileSpeed;
  float vy  = sin(rad) * projectileSpeed;
  float sx  = cx + cos(rad) * (circleRadius + 5);
  float sy  = cy + sin(rad) * (circleRadius + 5);
  projectiles.add(new Projectile(sx, sy, vx, vy, owner));
}

// ── Projectile クラス ──
class Projectile {
  PVector pos, vel;
  float lifespan = 255;
  float radius   = 8;
  int owner;
  ArrayList<PVector> trail = new ArrayList<PVector>();

  Projectile(float x, float y, float vx, float vy, int owner) {
    pos = new PVector(x, y);
    vel = new PVector(vx, vy);
    this.owner = owner;
  }

  void update() {
    pos.add(vel);
    lifespan -= 4;
    trail.add(pos.copy());
    if (trail.size() > 12) trail.remove(0);
  }

  void display() {
    for (int i = 0; i < trail.size(); i++) {
      float a = map(i, 0, trail.size(), 0, lifespan);
      fill(50,100,100, a*0.2);
      PVector p = trail.get(i);
      ellipse(p.x, p.y, radius*1.2, radius*1.2);
    }
    noStroke();
    fill(50,100,100, lifespan);
    ellipse(pos.x, pos.y, radius*2, radius*2);
  }

  boolean isDead() {
    return lifespan <= 0
        || pos.x < -radius || pos.x > width+radius
        || pos.y < -radius || pos.y > height+radius;
  }
}

// ── Block クラス ──
class Block {
  float x, y, w, h;
  Block(float x, float y, float w, float h) {
    this.x = x; this.y = y; this.w = w; this.h = h;
  }

  void display() {
    fill(0,0,0,20);
    rect(x+5, y+5, w, h, 8);
    float hue = map(y, 0, height, 180, 300);
    fill(hue,70,100);
    rect(x, y, w, h, 8);
  }

  boolean isHitCircle(float cx, float cy, float r) {
    return cx > x - r &&
           cx < x + w + r &&
           cy > y - r &&
           cy < y + h + r;
  }
}
