// Types

public interface Location {
  float x();
  float y();
}

public interface Actor extends Location {
  void update(float dt, ArrayList<Actor> attractors, ArrayList<Actor> repellers);
  void draw();
  void relocate();
}

class Positional implements Location {
  float posX, posY;

  float x() {
    return posX;
  }

  float y() {
    return posY;
  }
}

class Attractor extends Positional implements Actor {

  Attractor() {
    relocate();
  }

  void relocate() {
    posX = random(0, width);
    posY = random(0, height);
  }

  void update(float dt, ArrayList<Actor> attractors, ArrayList<Actor> repellers) {
    if(random(0, 1) < 0.01) {
      relocate();
    }
  }

  void draw() {
    pushMatrix();
    translate(x(), y());
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

//Positional closest(ArrayList<Positional> attractors, )

class Mover extends Positional implements Actor {
  float rot;
  float velocity;
  PImage graphic;
  float scale;
  boolean turns;


  Mover(float x, float y, PImage g, float s, float speed, boolean canTurn) {
    posX = x;
    posY = y;
    graphic = g;
    scale = s * random(0.8, 1.2);
    velocity = speed * random(0.8, 1.2);
    turns = canTurn;
  }

  void relocate() {
    if(random(-1,1) < 0) {
      float r = random(-1, 1) < 0 ? -1. : 1.;
      if (r < 0) {
        // left
        posX = r * random(10, 30);
      } else {
        // right
        posX = r * random(width+10, width+30);
      }
      posY = random(0, height);
    } else {
      float r = random(-1, 1) < 0 ? -1. : 1.;
      if (r < 0) {
        // top
        posY = r * random(10, 30);
      } else {
        // bottom
        posY = r * random(height+10, height+30);
      }
      posX = random(0, width);
    }
  }

  void update(float dt, ArrayList<Actor> attractors, ArrayList<Actor> repellers) {

    // find our goal
    Actor closest = null;
    float clostestDistSq = 0;
    for( int i=0; i < attractors.size(); i++) {
      Actor cur = attractors.get(i);
      float dx = cur.x() - x();
      float dy = cur.y() - y();
      float distSq = dx*dx+dy*dy;
      if(closest == null ||  distSq < clostestDistSq) {
        closest = cur;
        clostestDistSq = distSq;
      }
    }

    // avoid other movers

    
    if(closest == null) {
      return;
    }

    float arrivalThreshold = 5;
    if (clostestDistSq < arrivalThreshold) {
      // we're already here
      return;
    }

    // turn to face where we're going
    if(turns) {
      float dx = closest.x() - x();
      float dy = closest.y() - y();
      float desiredRot = angleFromDirection(dx, dy);
      rot = lerp(rot, desiredRot, 0.1);
    }

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
    translate(x(), y());
    rotate(rot + PI*0.5);
    fill(color(100, 200, 100));
    float w = graphic.width * scale;
    float h = graphic.height * scale;
    image(graphic, -w*0.5, -h*0.5, w, h);
    //circle(0, 0, w*0.5);
    popMatrix();
  }
}


// Globals
//
int gLastTime = 0;

ArrayList<Actor> gAttractors;
ArrayList<Actor> gMovers;

class SpawnConfig {
  PImage image;
  float scale;
  int count;
  float speed;
  boolean canTurn;

  SpawnConfig(String filename, float scale_, int count_, float speed_, boolean canTurn_) {
    image = loadImage(filename);
    scale = scale_;
    count = count_;
    speed = speed_;
    canTurn = canTurn_;
  }
}

ArrayList<Actor> spawn(ArrayList<SpawnConfig> configs) {
  ArrayList<Actor> result = new ArrayList<Actor>();
  for(int i=0; i < configs.size(); i++) {
    SpawnConfig config = configs.get(i);
    for(int c=0; c < config.count; c++) {
      result.add(new Mover(random(0, width), random(0, height), config.image, config.scale, config.speed, config.canTurn));
    }
  }
  return result;
}

void setup() {
  size(1920, 1080, P2D);
  frameRate(30);

  // configuration
  ArrayList<SpawnConfig> configs = new ArrayList<SpawnConfig>();
  configs.add(new SpawnConfig("ant.png", 0.4, 40, 10, true));
  configs.add(new SpawnConfig("bee.png", 0.6, 15, 200, true));
  configs.add(new SpawnConfig("ghost.png", 2.0, 1, 100, false));
  configs.add(new SpawnConfig("scorpion.png", 1.0, 2, 50, true));
  gMovers = spawn(configs);

  gAttractors = new ArrayList<Actor>();
  for(int i=0; i < 4; i++ ) {
    gAttractors.add(new Attractor());
  }
  
}

void draw() {
  background(128);

  // get a dt
  int now = millis();
  float dt = float(now - gLastTime) / 1000;
  gLastTime = now;

  // update attractors (TODO: use neural net to place them)
  for (int i = 0; i < gAttractors.size(); i++) {
    Actor a = gAttractors.get(i);
    a.update(dt, gAttractors, gMovers);
    a.draw();
  }

  // update movers
  for (int i = 0; i < gMovers.size(); i++) {
    Actor m = gMovers.get(i);
    m.update(dt, gAttractors, gMovers);
    m.draw();
  }

  // respawn out of bounds movers
  float threshold = 50;
  for (int i = 0; i < gMovers.size(); i++) {
    Actor m = gMovers.get(i);
    if( m.x() < -threshold ||
        m.x() > float(width)+threshold ||
        m.y() < -threshold ||
        m.y() > float(height)+threshold) {
          m.relocate();
        }
  }

}
