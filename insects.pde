// Types

class Attractor {
  float posX, posY;

  Attractor() {
    relocate();
  }

  void relocate() {
    posX = random(0, width);
    posY = random(0, height);
  }

  void update() {
    if(random(0, 1) < 0.01) {
      relocate();
    }
  }

  void draw() {
    pushMatrix();
    translate(posX, posY);
    float w = 10;
    fill(color(200, 100, 100));
    rect(-w, -w, 2*w, 2*w);
    popMatrix();
  }
}

float angleFromDirection(float vx, float vy) {
  float len = sqrt(vx*vx + vy*vy);
  if (len < 0.01) {
    return 0.;
  }
  float x = vx / len;
  float y = vy / len;

  if (x == 0.) {
      return (y > 0.)? PI*0.5
          : (y == 0.)? 0
          : PI*1.5;
  }
  else if (y == 0) {
      return (x >= 0)? 0 : PI;
  }

  float ret = atan(y/x);
  if (x < 0 && y < 0) // quadrant Ⅲ
      ret = PI + ret;
  else if (x < 0) // quadrant Ⅱ
      ret = PI + ret; // it actually substracts
  else if (y < 0) // quadrant Ⅳ
      ret = PI*1.5 + (PI*0.5 + ret); // it actually substracts
  return ret;
}

class Mover {
  float posX, posY;
  float rot;
  float velocity;
  PImage graphic;

  Mover(float x, float y, PImage g) {
    posX = x;
    posY = y;
    graphic = g;
    velocity = random(50, 100); // pixels per second
  }

  void update(float dt, ArrayList<Attractor> attractors) {
    Attractor closest = null;
    float clostestDistSq = 0;
    for( int i=0; i < attractors.size(); i++) {
      Attractor cur = attractors.get(i);
      float dx = cur.posX - posX;
      float dy = cur.posY - posY;
      float distSq = dx*dx+dy*dy;
      if(closest == null ||  distSq < clostestDistSq) {
        closest = cur;
        clostestDistSq = distSq;
      }
    }
    
    if(closest == null) {
      return;
    }

    float arrivalThreshold = 5;
    if (clostestDistSq < arrivalThreshold) {
      // we're already here
      return;
    }

    // turn to face where we're going
    float dx = closest.posX - posX;
    float dy = closest.posY - posY;
    float desiredRot = angleFromDirection(dx, dy);
    rot = lerp(rot, desiredRot, 0.2);

    // move in the direction we're facing
    float hx = cos(rot);
    float hy = sin(rot);
    float moveX = hx * dt * velocity;
    float moveY = hy * dt * velocity;
    posX += moveX;
    posY += moveY;
  }

  void draw() {
    pushMatrix();
    translate(posX, posY);
    rotate(rot + PI);
    fill(color(100, 200, 100));
    float w = 30;
    float h = 30;
    image(graphic, -w, -h, 2*w, 2*h);
    popMatrix();
  }
}


// Globals
//
int gLastTime = 0;

ArrayList<Attractor> gAttractors;
ArrayList<Mover> gMovers;
PImage gScorpionImage;

void setup() {
  size(800, 800);
  frameRate(30);

  gScorpionImage = loadImage("scorpion.gif");
  if(gScorpionImage == null) {
    return;
  }

  gMovers = new ArrayList<Mover>();
  for(int i=0; i < 10; i++) {
    gMovers.add(new Mover(random(0, width), random(0, height), gScorpionImage));
  }

  gAttractors = new ArrayList<Attractor>();
  for(int i=0; i < 5; i++ ) {
    gAttractors.add(new Attractor());
  }
  
}

void draw() {
  background(204);

  // get a dt
  int now = millis();
  float dt = float(now - gLastTime) / 1000;
  gLastTime = now;

  // DEBUG - force attractor to mouse position
  for (int i = 0; i < gAttractors.size(); i++) {
    Attractor a = gAttractors.get(i);
    a.update();
    a.draw();
  }

  for (int i = 0; i < gMovers.size(); i++) {
    Mover m = gMovers.get(i);
    m.update(dt, gAttractors);
    m.draw();
  }

}
