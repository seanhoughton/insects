// Types

class Attractor {
  float posX, posY;

  Attractor() {
    relocate();
  }

  void relocate() {
    posX = random(0, width);
    posY = random(0, height);
    print("NOW AT " + posX + ", " + posY + "\n");
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
  float speed;

  Mover(float x, float y) {
    posX = x;
    posY = y;
    speed = random(1, 10); // pixels per second
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

    float dx = closest.posX - posX;
    float dy = closest.posY - posY;
    rot = angleFromDirection(dx, dy);
    float moveX = dx * dt * speed;
    float moveY = dy * dt * speed;
    posX += moveX;
    posY += moveY;
  }

  void draw() {
    pushMatrix();
    translate(posX, posY);
    rotate(rot);
    fill(color(100, 200, 100));
    float w = 10;
    float h = 5;
    rect(-w, -h, 2*w, 2*h);
    popMatrix();
  }
}


// Globals
//
int gLastTime = 0;

ArrayList<Attractor> gAttractors;
ArrayList<Mover> gMovers;

void setup() {
  size(800, 800);
  frameRate(30);

  gMovers = new ArrayList<Mover>();
  for(int i=0; i < 10; i++) {
    gMovers.add(new Mover(random(0, width), random(0, height)));
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
