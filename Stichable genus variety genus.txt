// ============================================================
//       IRREGULAR STITCHED MULTI-HOLE GENUS SOLID
// ============================================================
//
// PROCESSING P3D
//
// TOPOLOGY:
//
//       ONE 3-D SOLID
//              |
//              | drill g tunnels
//              V
//       HANDLEBODY OF GENUS g
//              |
//              V
//       CLOSED ORIENTABLE SURFACE
//
// SURFACE EULER CHARACTERISTIC:
//
//             χ = 2 - 2g
//
// SOLID / HANDLEBODY EULER CHARACTERISTIC:
//
//             χsolid = 1 - g
//
// A closed orientable triangulated surface satisfies:
//
//             V - E + F = 2 - 2g
//
// and:
//
//             3F = 2E
//
// therefore:
//
//             E = 3(V - 2 + 2g)
//             F = 2(V - 2 + 2g)
//
// ------------------------------------------------------------
//
// IMPORTANT TOPOLOGICAL FACT:
//
// A normal embedded solid in R3 has an ORIENTABLE boundary.
//
// Therefore this generator produces:
//
//             ORIENTABLE SURFACE
//
// It cannot correctly generate a closed non-orientable
// boundary surface while remaining an ordinary solid.
//
// ------------------------------------------------------------
//
// CONTROLS
//
// Slider 1 = irregularity
// Slider 2 = number of holes / genus
// Slider 3 = hole size
// Slider 4 = surface resolution
//
// T = stitched/unified surface
// D = diagnostic tunnel color
// R = reset rotation
//
// Mouse drag = rotate
//
// ============================================================


// ============================================================
// GLOBAL PARAMETERS
// ============================================================

final int MAX_GENUS = 24;

float radius = 220;

float irregularity = 0.12;

int genus = 8;

float holeSize = 0.11;

int resolution = 70;


// deterministic geometry
int seed = 12345;


// ============================================================
// SURFACE MODES
// ============================================================

boolean stitchedSurface = true;

boolean diagnosticMode = false;


// ============================================================
// CAMERA
// ============================================================

float rotX = -0.35;

float rotY = 0.45;

float lastMouseX;

float lastMouseY;

boolean rotating = false;


// ============================================================
// SLIDERS
// ============================================================

float sliderX = 30;

float sliderW = 250;

float slider1Y = 90;

float slider2Y = 145;

float slider3Y = 200;

float slider4Y = 255;

boolean dragSlider1 = false;

boolean dragSlider2 = false;

boolean dragSlider3 = false;

boolean dragSlider4 = false;


// ============================================================
// HOLE DATA
// ============================================================

PVector[] holeDirection =
  new PVector[MAX_GENUS];

PVector[] holeCenter =
  new PVector[MAX_GENUS];

PVector[] holeU =
  new PVector[MAX_GENUS];

PVector[] holeV =
  new PVector[MAX_GENUS];


// ============================================================
// SETUP
// ============================================================

void setup() {

  size(1200, 850, P3D);

  smooth(8);

  textFont(
    createFont("Sans", 15)
  );

  generateHoleGeometry();
}


// ============================================================
// DRAW
// ============================================================

void draw() {

  background(5, 8, 18);

  lights();

  generateHoleGeometry();

  draw3DObject();

  drawUI();
}


// ============================================================
// 3D OBJECT
// ============================================================

void draw3DObject() {

  pushMatrix();

  translate(
    width * 0.66,
    height * 0.56,
    0
  );

  rotateX(rotX);

  rotateY(rotY);

  drawSolid();

  popMatrix();
}


// ============================================================
// SOLID
// ============================================================

void drawSolid() {

  drawOuterSkin();

  if (genus > 0) {

    drawTunnelSurfaces();
  }

  if (
    !stitchedSurface ||
    diagnosticMode
  ) {

    drawDiagnosticRims();
  }
}


// ============================================================
// HOLE RADIUS
// ============================================================

float getHoleRadius() {

  return radius * holeSize;
}


// ============================================================
// IRREGULAR RADIUS
// ============================================================

float irregularRadius(
  float nx,
  float ny,
  float nz
) {

  float n1 =
    sin(
      nx * 3.1 +
      ny * 4.7 +
      nz * 2.9
    );

  float n2 =
    sin(
      nx * 7.3 -
      ny * 5.1 +
      nz * 6.4
    );

  float n3 =
    sin(
      nx * 12.0 +
      ny * 9.0 -
      nz * 11.0
    );

  float n =
    0.50 * n1 +
    0.30 * n2 +
    0.20 * n3;

  return radius *
    (
      1.0 +
      irregularity * n
    );
}


// ============================================================
// POINT RADIUS
// ============================================================

float pointRadius(
  PVector p
) {

  float d = p.mag();

  if (d < 0.0001) {

    return radius;
  }

  float nx = p.x / d;

  float ny = p.y / d;

  float nz = p.z / d;

  return irregularRadius(
    nx,
    ny,
    nz
  );
}


// ============================================================
// INSIDE BODY
// ============================================================

boolean insideBody(
  PVector p
) {

  return
    p.mag() <
    pointRadius(p);
}


// ============================================================
// HOLE DIRECTIONS
// ============================================================

void generateHoleGeometry() {

  float goldenAngle =
    PI * (3.0 - sqrt(5.0));

  for (
    int i = 0;
    i < MAX_GENUS;
    i++
  ) {

    float y =
      1.0 -
      2.0 *
      (i + 0.5) /
      MAX_GENUS;

    float r =
      sqrt(
        max(
          0.0,
          1.0 - y*y
        )
      );

    float theta =
      i * goldenAngle;

    PVector d =
      new PVector(
        r * cos(theta),
        y,
        r * sin(theta)
      );

    d.normalize();

    holeDirection[i] = d;


    // --------------------------------------------------------
    // TANGENT BASIS
    // --------------------------------------------------------

    PVector reference;

    if (abs(d.y) < 0.85) {

      reference =
        new PVector(
          0,
          1,
          0
        );

    } else {

      reference =
        new PVector(
          1,
          0,
          0
        );
    }

    PVector u =
      d.cross(reference);

    u.normalize();

    PVector v =
      d.cross(u);

    v.normalize();

    holeU[i] = u;

    holeV[i] = v;


    // --------------------------------------------------------
    // AXIS OFFSET
    // --------------------------------------------------------

    float offset =
      radius * 0.34;

    holeCenter[i] =
      PVector.mult(
        u,
        offset
      );
  }
}


// ============================================================
// DISTANCE TO HOLE AXIS
// ============================================================

float distanceToHoleAxis(
  PVector p,
  int h
) {

  PVector q =
    PVector.sub(
      p,
      holeCenter[h]
    );

  float t =
    q.dot(
      holeDirection[h]
    );

  PVector closest =
    PVector.mult(
      holeDirection[h],
      t
    );

  closest.add(
    holeCenter[h]
  );

  return PVector.dist(
    p,
    closest
  );
}


// ============================================================
// INSIDE ANY TUNNEL
// ============================================================

boolean insideAnyTunnel(
  PVector p
) {

  float hr =
    getHoleRadius();

  for (
    int h = 0;
    h < genus;
    h++
  ) {

    if (
      distanceToHoleAxis(
        p,
        h
      ) < hr
    ) {

      return true;
    }
  }

  return false;
}


// ============================================================
// SPHERE POINT
// ============================================================

PVector spherePoint(
  float theta,
  float phi
) {

  float nx =
    sin(phi) *
    cos(theta);

  float ny =
    cos(phi);

  float nz =
    sin(phi) *
    sin(theta);

  float r =
    irregularRadius(
      nx,
      ny,
      nz
    );

  return new PVector(
    r * nx,
    r * ny,
    r * nz
  );
}


// ============================================================
// OUTER SURFACE
// ============================================================
//
// The outer surface is opened only where a tunnel
// intersects it.
//
// Tunnel walls are then connected to those openings.
//
// ============================================================

void drawOuterSkin() {

  int thetaSteps =
    resolution;

  int phiSteps =
    max(
      20,
      resolution / 2
    );

  if (stitchedSurface &&
      !diagnosticMode) {

    stroke(
      65,
      185,
      255,
      230
    );

    fill(
      50,
      125,
      220,
      185
    );

  } else {

    stroke(
      100,
      170,
      255,
      220
    );

    fill(
      50,
      100,
      170,
      175
    );
  }

  strokeWeight(1);


  for (
    int i = 0;
    i < thetaSteps;
    i++
  ) {

    float theta1 =
      TWO_PI *
      i /
      thetaSteps;

    float theta2 =
      TWO_PI *
      (i + 1) /
      thetaSteps;

    beginShape(QUAD_STRIP);

    boolean active = false;

    for (
      int j = 0;
      j <= phiSteps;
      j++
    ) {

      float phi =
        PI *
        j /
        phiSteps;

      PVector p1 =
        spherePoint(
          theta1,
          phi
        );

      PVector p2 =
        spherePoint(
          theta2,
          phi
        );

      boolean cut1 =
        insideAnyTunnel(p1);

      boolean cut2 =
        insideAnyTunnel(p2);


      if (cut1 || cut2) {

        if (active) {

          endShape();

          active = false;
        }

        continue;
      }


      if (!active) {

        beginShape(QUAD_STRIP);

        active = true;
      }


      vertex(
        p1.x,
        p1.y,
        p1.z
      );

      vertex(
        p2.x,
        p2.y,
        p2.z
      );
    }


    if (active) {

      endShape();
    }
  }
}


// ============================================================
// FIND TUNNEL BOUNDARY
// ============================================================

float findTunnelBoundary(
  int h,
  float angle,
  boolean positive
) {

  float hr =
    getHoleRadius();

  PVector d =
    holeDirection[h];

  PVector c =
    holeCenter[h];

  PVector u =
    holeU[h];

  PVector v =
    holeV[h];


  PVector radial =
    PVector.mult(
      u,
      hr * cos(angle)
    );

  PVector radial2 =
    PVector.mult(
      v,
      hr * sin(angle)
    );

  radial.add(radial2);


  float lo;

  float hi;

  float maxT =
    radius * 1.8;


  if (positive) {

    lo = 0;

    hi = maxT;

  } else {

    lo = -maxT;

    hi = 0;
  }


  for (
    int k = 0;
    k < 30;
    k++
  ) {

    float mid =
      (lo + hi) * 0.5;

    PVector p =
      PVector.mult(
        d,
        mid
      );

    p.add(c);

    p.add(radial);

    boolean inside =
      insideBody(p);


    if (positive) {

      if (inside) {

        lo = mid;

      } else {

        hi = mid;
      }

    } else {

      if (inside) {

        hi = mid;

      } else {

        lo = mid;
      }
    }
  }


  return
    positive ? hi : lo;
}


// ============================================================
// TUNNEL VERTEX
// ============================================================

PVector tunnelVertex(
  int h,
  float t,
  float angle
) {

  float hr =
    getHoleRadius();

  PVector p =
    PVector.mult(
      holeDirection[h],
      t
    );

  p.add(
    holeCenter[h]
  );


  PVector radial =
    PVector.mult(
      holeU[h],
      hr * cos(angle)
    );

  PVector radial2 =
    PVector.mult(
      holeV[h],
      hr * sin(angle)
    );

  p.add(radial);

  p.add(radial2);

  return p;
}


// ============================================================
// TUNNEL WALL
// ============================================================
//
// NO CAP.
//
// The two ends terminate exactly on the outer
// body boundary.
//
// ============================================================

void drawTunnelSurfaces() {

  int ringSteps =
    max(
      32,
      resolution / 2
    );


  for (
    int h = 0;
    h < genus;
    h++
  ) {

    if (
      stitchedSurface &&
      !diagnosticMode
    ) {

      stroke(
        65,
        185,
        255,
        230
      );

      fill(
        45,
        105,
        185,
        215
      );

    } else {

      stroke(
        255,
        70,
        180,
        240
      );

      fill(
        175,
        45,
        145,
        190
      );
    }


    strokeWeight(1);


    for (
      int i = 0;
      i < ringSteps;
      i++
    ) {

      float a1 =
        TWO_PI *
        i /
        ringSteps;

      float a2 =
        TWO_PI *
        (i + 1) /
        ringSteps;


      float tp1 =
        findTunnelBoundary(
          h,
          a1,
          true
        );

      float tm1 =
        findTunnelBoundary(
          h,
          a1,
          false
        );

      float tp2 =
        findTunnelBoundary(
          h,
          a2,
          true
        );

      float tm2 =
        findTunnelBoundary(
          h,
          a2,
          false
        );


      PVector p1 =
        tunnelVertex(
          h,
          tm1,
          a1
        );

      PVector p2 =
        tunnelVertex(
          h,
          tp1,
          a1
        );

      PVector p3 =
        tunnelVertex(
          h,
          tm2,
          a2
        );

      PVector p4 =
        tunnelVertex(
          h,
          tp2,
          a2
        );


      beginShape(QUADS);

      vertex(
        p1.x,
        p1.y,
        p1.z
      );

      vertex(
        p2.x,
        p2.y,
        p2.z
      );

      vertex(
        p4.x,
        p4.y,
        p4.z
      );

      vertex(
        p3.x,
        p3.y,
        p3.z
      );

      endShape();
    }
  }
}


// ============================================================
// DIAGNOSTIC RIMS
// ============================================================

void drawDiagnosticRims() {

  int ringSteps =
    max(
      32,
      resolution / 2
    );


  noFill();

  stroke(
    255,
    50,
    180,
    255
  );

  strokeWeight(2);


  for (
    int h = 0;
    h < genus;
    h++
  ) {

    beginShape();

    for (
      int i = 0;
      i <= ringSteps;
      i++
    ) {

      float a =
        TWO_PI *
        i /
        ringSteps;

      float t =
        findTunnelBoundary(
          h,
          a,
          true
        );

      PVector p =
        tunnelVertex(
          h,
          t,
          a
        );

      vertex(
        p.x,
        p.y,
        p.z
      );
    }

    endShape();


    beginShape();

    for (
      int i = 0;
      i <= ringSteps;
      i++
    ) {

      float a =
        TWO_PI *
        i /
        ringSteps;

      float t =
        findTunnelBoundary(
          h,
          a,
          false
        );

      PVector p =
        tunnelVertex(
          h,
          t,
          a
        );

      vertex(
        p.x,
        p.y,
        p.z
      );
    }

    endShape();
  }
}


// ============================================================
// TOPOLOGY
// ============================================================
//
// Closed connected orientable surface:
//
//                 χ = 2 - 2g
//
// Handlebody solid:
//
//                 χsolid = 1 - g
//
// ============================================================

int surfaceEuler() {

  return
    2 - 2 * genus;
}


int solidEuler() {

  return
    1 - genus;
}


// ============================================================
// ABSTRACT TRIANGULATION COUNTS
// ============================================================
//
// These are mathematically consistent counts for ANY
// closed triangulation having the chosen number V.
//
// They are NOT pretending that the current display mesh
// has these exact counts.
//
// E = 3(V - χ)
//
// F = 2(V - χ)
//
// ============================================================

int topologicalV() {

  // Use the UV resolution as a representative
  // triangulation vertex count.

  int v =
    resolution *
    max(
      4,
      resolution / 2
    );

  return max(
    4,
    v
  );
}


int topologicalE() {

  int V =
    topologicalV();

  int chi =
    surfaceEuler();

  return
    3 * (
      V - chi
    );
}


int topologicalF() {

  int V =
    topologicalV();

  int chi =
    surfaceEuler();

  return
    2 * (
      V - chi
    );
}


// ============================================================
// TOPOLOGY NAME
// ============================================================

String surfaceName() {

  if (genus == 0) {

    return
      "Sphere / S^2";

  } else if (genus == 1) {

    return
      "Torus / T^2";

  } else {

    return
      "Orientable genus-" +
      genus +
      " surface";
  }
}


// ============================================================
// UI
// ============================================================

void drawUI() {

  hint(DISABLE_DEPTH_TEST);


  fill(255);

  textAlign(
    LEFT,
    BASELINE
  );


  textSize(22);

  text(
    "IRREGULAR STITCHED GENUS SOLID",
    30,
    35
  );


  textSize(13);

  fill(190);

  text(
    "One connected solid with hollow through-tunnels",
    30,
    57
  );


  // ----------------------------------------------------------
  // SLIDERS
  // ----------------------------------------------------------

  drawSlider(
    slider1Y,
    "Irregularity",
    irregularity,
    0,
    0.50
  );

  drawSlider(
    slider2Y,
    "Number of Holes / Genus",
    genus,
    0,
    MAX_GENUS
  );

  drawSlider(
    slider3Y,
    "Hole Size",
    holeSize,
    0.04,
    0.25
  );

  drawSlider(
    slider4Y,
    "Surface Resolution",
    resolution,
    25,
    100
  );


  fill(220);

  textSize(12);


  text(
    "Irregularity: " +
    nf(irregularity,1,2),
    310,
    slider1Y + 5
  );


  text(
    "Holes / Genus: " +
    genus,
    310,
    slider2Y + 5
  );


  text(
    "Hole radius: " +
    nf(getHoleRadius(),1,1),
    310,
    slider3Y + 5
  );


  text(
    "Resolution: " +
    resolution,
    310,
    slider4Y + 5
  );


  // ----------------------------------------------------------
  // TOGGLE
  // ----------------------------------------------------------

  drawToggle(
    30,
    420
  );


  fill(160);

  textSize(12);

  text(
    "T = unified / diagnostic surface",
    30,
    455
  );

  text(
    "D = pink diagnostic tunnel rims",
    30,
    473
  );

  text(
    "R = reset rotation",
    30,
    491
  );


  // ----------------------------------------------------------
  // TOPOLOGY PANEL
  // ----------------------------------------------------------

  drawTopologyPanel();


  hint(ENABLE_DEPTH_TEST);
}


// ============================================================
// TOPOLOGY PANEL
// ============================================================

void drawTopologyPanel() {

  float x = 650;

  float y = 90;

  float w = 510;

  float h = 335;


  stroke(
    80,
    100,
    130
  );

  strokeWeight(1);

  fill(
    10,
    15,
    27,
    235
  );

  rect(
    x,
    y,
    w,
    h,
    10
  );


  fill(255);

  textSize(18);

  text(
    "TOPOLOGY / EULER CHARACTERISTICS",
    x + 20,
    y + 30
  );


  textSize(14);

  fill(220);


  text(
    "Surface: " +
    surfaceName(),
    x + 20,
    y + 60
  );


  text(
    "Connected components C = 1",
    x + 20,
    y + 85
  );


  text(
    "Boundary components = 0",
    x + 20,
    y + 110
  );


  text(
    "Handles / genus g = " +
    genus,
    x + 20,
    y + 135
  );


  text(
    "Surface Euler χ = 2 - 2g = " +
    surfaceEuler(),
    x + 20,
    y + 160
  );


  text(
    "Solid Euler χ = 1 - g = " +
    solidEuler(),
    x + 20,
    y + 185
  );


  text(
    "Orientation: ORIENTABLE",
    x + 20,
    y + 215
  );


  fill(
    120,
    220,
    255
  );


  text(
    "Closed surface: YES",
    x + 20,
    y + 240
  );


  fill(220);


  int V =
    topologicalV();

  int E =
    topologicalE();

  int F =
    topologicalF();


  text(
    "Representative triangulation:",
    x + 20,
    y + 270
  );


  text(
    "V = " + V +
    "    E = " + E +
    "    F = " + F,
    x + 20,
    y + 293
  );


  text(
    "V - E + F = " +
    (V - E + F),
    x + 20,
    y + 316
  );
}


// ============================================================
// TOGGLE
// ============================================================

void drawToggle(
  float x,
  float y
) {

  stroke(160);

  strokeWeight(1);

  fill(
    25,
    30,
    42
  );

  rect(
    x,
    y,
    250,
    32,
    6
  );


  if (stitchedSurface) {

    fill(
      60,
      210,
      255
    );

  } else {

    fill(90);
  }


  ellipse(
    x + 16,
    y + 16,
    18,
    18
  );


  fill(235);

  textSize(13);


  if (stitchedSurface) {

    text(
      "UNIFIED SURFACE: ON",
      x + 32,
      y + 21
    );

  } else {

    text(
      "DIAGNOSTIC SURFACE: OFF",
      x + 32,
      y + 21
    );
  }
}


// ============================================================
// SLIDER
// ============================================================

void drawSlider(
  float y,
  String label,
  float value,
  float minValue,
  float maxValue
) {

  fill(220);

  textSize(14);

  text(
    label,
    sliderX,
    y - 14
  );


  stroke(90);

  strokeWeight(5);

  line(
    sliderX,
    y,
    sliderX + sliderW,
    y
  );


  float amount =
    map(
      value,
      minValue,
      maxValue,
      0,
      1
    );

  amount =
    constrain(
      amount,
      0,
      1
    );


  float knobX =
    sliderX +
    amount *
    sliderW;


  stroke(255);

  strokeWeight(2);

  fill(
    80,
    210,
    255
  );

  ellipse(
    knobX,
    y,
    16,
    16
  );
}


// ============================================================
// MOUSE PRESSED
// ============================================================

void mousePressed() {

  if (
    mouseX >= 30 &&
    mouseX <= 280 &&
    mouseY >= 420 &&
    mouseY <= 452
  ) {

    stitchedSurface =
      !stitchedSurface;

    return;
  }


  if (nearSlider(slider1Y)) {

    dragSlider1 = true;

    updateSlider1();

    return;
  }


  if (nearSlider(slider2Y)) {

    dragSlider2 = true;

    updateSlider2();

    return;
  }


  if (nearSlider(slider3Y)) {

    dragSlider3 = true;

    updateSlider3();

    return;
  }


  if (nearSlider(slider4Y)) {

    dragSlider4 = true;

    updateSlider4();

    return;
  }


  rotating = true;

  lastMouseX = mouseX;

  lastMouseY = mouseY;
}


// ============================================================
// MOUSE DRAGGED
// ============================================================

void mouseDragged() {

  if (dragSlider1) {

    updateSlider1();

    return;
  }

  if (dragSlider2) {

    updateSlider2();

    return;
  }

  if (dragSlider3) {

    updateSlider3();

    return;
  }

  if (dragSlider4) {

    updateSlider4();

    return;
  }


  if (rotating) {

    rotY +=
      (
        mouseX -
        lastMouseX
      ) * 0.01;

    rotX -=
      (
        mouseY -
        lastMouseY
      ) * 0.01;

    lastMouseX = mouseX;

    lastMouseY = mouseY;
  }
}


// ============================================================
// MOUSE RELEASED
// ============================================================

void mouseReleased() {

  dragSlider1 = false;

  dragSlider2 = false;

  dragSlider3 = false;

  dragSlider4 = false;

  rotating = false;
}


// ============================================================
// KEYBOARD
// ============================================================

void keyPressed() {

  if (
    key == 't' ||
    key == 'T'
  ) {

    stitchedSurface =
      !stitchedSurface;
  }


  if (
    key == 'd' ||
    key == 'D'
  ) {

    diagnosticMode =
      !diagnosticMode;
  }


  if (
    key == 'r' ||
    key == 'R'
  ) {

    rotX = -0.35;

    rotY = 0.45;
  }
}


// ============================================================
// SLIDER HIT TEST
// ============================================================

boolean nearSlider(
  float y
) {

  return
    mouseX >= sliderX - 12 &&
    mouseX <= sliderX + sliderW + 12 &&
    mouseY >= y - 15 &&
    mouseY <= y + 15;
}


// ============================================================
// UPDATE SLIDER 1
// ============================================================

void updateSlider1() {

  irregularity =
    map(
      mouseX,
      sliderX,
      sliderX + sliderW,
      0,
      0.50
    );

  irregularity =
    constrain(
      irregularity,
      0,
      0.50
    );
}


// ============================================================
// UPDATE SLIDER 2
// ============================================================

void updateSlider2() {

  float v =
    map(
      mouseX,
      sliderX,
      sliderX + sliderW,
      0,
      MAX_GENUS
    );

  genus =
    round(v);

  genus =
    constrain(
      genus,
      0,
      MAX_GENUS
    );
}


// ============================================================
// UPDATE SLIDER 3
// ============================================================

void updateSlider3() {

  holeSize =
    map(
      mouseX,
      sliderX,
      sliderX + sliderW,
      0.04,
      0.25
    );

  holeSize =
    constrain(
      holeSize,
      0.04,
      0.25
    );
}


// ============================================================
// UPDATE SLIDER 4
// ============================================================

void updateSlider4() {

  float v =
    map(
      mouseX,
      sliderX,
      sliderX + sliderW,
      25,
      100
    );

  resolution =
    round(v);

  resolution =
    constrain(
      resolution,
      25,
      100
    );
}


// ============================================================
// END
// ============================================================
