// ============================================================
// ============================================================
//        IRREGULAR STITCHED MULTI-HOLE GENUS SOLID
// ============================================================
// ============================================================
//
// Processing P3D
//
// PURPOSE
// ------------------------------------------------------------
// Create one visually continuous 3D solid:
//
//              IRREGULAR BODY
//                    +
//              CUT OPENINGS
//                    +
//              HOLLOW TUNNELS
//                    |
//                    V
//          ONE CONTINUOUS SURFACE
//
// NO SEPARATE PINK RINGS IN NORMAL MODE.
//
// Each tunnel is:
//
//        OUTER SURFACE
//              |
//              | opening
//              V
//        ----------------
//       /                /
//      /    HOLLOW      /
//     /    TUNNEL      /
//    /                /
//   ----------------
//
// The tunnel wall is attached to the same opening
// boundary as the outer surface.
//
// ============================================================
//
// CONTROLS
// ------------------------------------------------------------
// Slider 1 = Irregularity
// Slider 2 = Number of holes
// Slider 3 = Hole size
// Slider 4 = Surface resolution
//
// STITCHED SURFACE toggle:
//     ON  = unified single-surface appearance
//     OFF = diagnostic mode
//
// Keyboard:
//     T = toggle stitched surface
//     D = toggle diagnostic tunnel color
//
// Mouse:
//     Drag = rotate solid
//
// ============================================================


// ============================================================
// GLOBAL PARAMETERS
// ============================================================

final int MAX_GENUS = 24;

float radius = 220;


// ------------------------------------------------------------
// USER PARAMETERS
// ------------------------------------------------------------

float irregularity = 0.12;

int genus = 8;

float holeSize = 0.11;

int resolution = 70;


// ------------------------------------------------------------
// DETERMINISTIC GEOMETRY
// ------------------------------------------------------------

int seed = 12345;


// ============================================================
// SURFACE MODE
// ============================================================

boolean stitchedSurface = true;

// Diagnostic mode:
// false = normal unified surface
// true  = tunnel walls shown pink

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
//
// Every hole has:
//
//      d  = tunnel direction
//      c  = tunnel axis offset
//      u,v = circular cross-section basis
//
// Tunnel:
//
//      P(t,a) = c + d*t
//               + radius*cos(a)*u
//               + radius*sin(a)*v
//
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

  size(
    1200,
    850,
    P3D
  );

  smooth(8);

  textFont(
    createFont(
      "Sans",
      15
    )
  );

  generateHoleGeometry();
}


// ============================================================
// MAIN DRAW
// ============================================================

void draw() {

  background(
    5,
    8,
    18
  );


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
    width * 0.65,
    height * 0.57,
    0
  );


  rotateX(rotX);

  rotateY(rotY);


  drawSolid();


  popMatrix();
}


// ============================================================
// DRAW SOLID
// ============================================================

void drawSolid() {

  // ----------------------------------------------------------
  // OUTER SKIN
  // ----------------------------------------------------------

  drawOuterSkin();


  // ----------------------------------------------------------
  // HOLLOW TUNNEL SKINS
  // ----------------------------------------------------------

  if (genus > 0) {

    drawTunnelSurfaces();
  }


  // ----------------------------------------------------------
  // OPTIONAL DIAGNOSTIC RIM
  // ----------------------------------------------------------

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

  float d =
    p.mag();


  if (
    d < 0.0001
  ) {

    return radius;
  }


  float nx =
    p.x / d;


  float ny =
    p.y / d;


  float nz =
    p.z / d;


  return irregularRadius(
    nx,
    ny,
    nz
  );
}


// ============================================================
// IS POINT ON / INSIDE OUTER BODY
// ============================================================

boolean insideBody(
  PVector p
) {

  return
    p.mag() <
    pointRadius(p);
}


// ============================================================
// GENERATE 3D HOLE DIRECTIONS
// ============================================================
//
// Fibonacci sphere distribution.
//
// This prevents all holes from forming one flat
// equatorial ring.
//
// ============================================================

void generateHoleGeometry() {

  float goldenAngle =
    PI *
    (3.0 - sqrt(5.0));


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
          1.0 -
          y*y
        )
      );


    float theta =
      i *
      goldenAngle;


    PVector d =
      new PVector(
        r * cos(theta),
        y,
        r * sin(theta)
      );


    d.normalize();


    holeDirection[i] =
      d;


    // --------------------------------------------------------
    // CREATE TANGENT BASIS
    // --------------------------------------------------------

    PVector reference;


    if (
      abs(d.y) < 0.85
    ) {

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


    holeU[i] =
      u;


    holeV[i] =
      v;


    // --------------------------------------------------------
    // AXIS OFFSET
    // --------------------------------------------------------
    //
    // Offset the tunnel from the exact centre.
    // This makes it behave more like a drilled handle
    // rather than every hole intersecting at the centre.
    //
    // --------------------------------------------------------

    float offset =
      radius *
      0.34;


    PVector c =
      PVector.mult(
        u,
        offset
      );


    holeCenter[i] =
      c;
  }
}


// ============================================================
// DISTANCE FROM POINT TO TUNNEL AXIS
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
// POINT INSIDE HOLE
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
// DRAW OUTER SKIN
// ============================================================
//
// The outer sphere is sampled as a UV mesh.
//
// Any mesh point belonging to a tunnel opening
// is omitted.
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


  // ----------------------------------------------------------
  // UNIFIED SURFACE MATERIAL
  // ----------------------------------------------------------

  stroke(
    65,
    185,
    255,
    230
  );


  strokeWeight(
    1.0
  );


  fill(
    50,
    125,
    220,
    180
  );


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


    beginShape(
      QUAD_STRIP
    );


    for (
      int j = 0;
      j <= phiSteps;
      j++
    ) {

      float phi =
        PI *
        j /
        phiSteps;


      // ------------------------------------------------------
      // FIRST VERTEX
      // ------------------------------------------------------

      PVector p1 =
        spherePoint(
          theta1,
          phi
        );


      // ------------------------------------------------------
      // SECOND VERTEX
      // ------------------------------------------------------

      PVector p2 =
        spherePoint(
          theta2,
          phi
        );


      boolean cut1 =
        insideAnyTunnel(
          p1
        );


      boolean cut2 =
        insideAnyTunnel(
          p2
        );


      // ------------------------------------------------------
      // HOLE OPENING
      // ------------------------------------------------------

      if (
        cut1 ||
        cut2
      ) {

        endShape();

        beginShape(
          QUAD_STRIP
        );

        continue;
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


    endShape();
  }
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
// FIND TUNNEL END
// ============================================================
//
// For a tunnel ring angle:
//
//       P = c + d*t + radial
//
// Find t where this point reaches the
// actual irregular outer body.
//
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


  PVector temp =
    PVector.mult(
      v,
      hr * sin(angle)
    );


  radial.add(temp);


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


  // ----------------------------------------------------------
  // BINARY SEARCH
  // ----------------------------------------------------------

  for (
    int k = 0;
    k < 24;
    k++
  ) {

    float mid =
      (lo + hi) *
      0.5;


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


  if (positive) {

    return hi;

  } else {

    return lo;
  }
}


// ============================================================
// CREATE TUNNEL VERTEX
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
// DRAW HOLLOW TUNNEL SURFACES
// ============================================================
//
// IMPORTANT:
//
// There is NO CAP here.
//
// Therefore the tunnel is genuinely visually hollow.
//
// Looking into one opening shows the inner tunnel wall,
// not a pink circle or solid disk.
//
// ============================================================

void drawTunnelSurfaces() {

  float hr =
    getHoleRadius();


  int ringSteps =
    max(
      20,
      resolution / 2
    );


  for (
    int h = 0;
    h < genus;
    h++
  ) {

    // --------------------------------------------------------
    // NORMAL MODE
    // --------------------------------------------------------

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
        210
      );

    } else {

      // Diagnostic mode only

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
        180
      );
    }


    strokeWeight(
      1.0
    );


    // --------------------------------------------------------
    // TUNNEL CIRCUMFERENCE
    // --------------------------------------------------------

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


      float tPlus1 =
        findTunnelBoundary(
          h,
          a1,
          true
        );


      float tMinus1 =
        findTunnelBoundary(
          h,
          a1,
          false
        );


      float tPlus2 =
        findTunnelBoundary(
          h,
          a2,
          true
        );


      float tMinus2 =
        findTunnelBoundary(
          h,
          a2,
          false
        );


      PVector p1 =
        tunnelVertex(
          h,
          tMinus1,
          a1
        );


      PVector p2 =
        tunnelVertex(
          h,
          tPlus1,
          a1
        );


      PVector p3 =
        tunnelVertex(
          h,
          tMinus2,
          a2
        );


      PVector p4 =
        tunnelVertex(
          h,
          tPlus2,
          a2
        );


      // ------------------------------------------------------
      // ONE CONTINUOUS TUNNEL WALL
      // ------------------------------------------------------

      beginShape(
        QUAD_STRIP
      );


      // Inner side / lower direction

      vertex(
        p1.x,
        p1.y,
        p1.z
      );


      // Outer side / upper direction

      vertex(
        p2.x,
        p2.y,
        p2.z
      );


      vertex(
        p3.x,
        p3.y,
        p3.z
      );


      vertex(
        p4.x,
        p4.y,
        p4.z
      );


      endShape();
    }
  }
}


// ============================================================
// DIAGNOSTIC RIMS
// ============================================================
//
// This is ONLY for checking the hole boundary.
//
// Normal stitched mode does NOT show these.
//
// ============================================================

void drawDiagnosticRims() {

  float hr =
    getHoleRadius();


  int ringSteps =
    max(
      20,
      resolution / 2
    );


  noFill();


  stroke(
    255,
    50,
    180,
    255
  );


  strokeWeight(
    2.0
  );


  for (
    int h = 0;
    h < genus;
    h++
  ) {

    // Front opening

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


    // Back opening

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
// UI
// ============================================================

void drawUI() {

  hint(
    DISABLE_DEPTH_TEST
  );


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
    "Hollow tunnels joined directly to one continuous surface",
    30,
    57
  );


  // ----------------------------------------------------------
  // SLIDER 1
  // ----------------------------------------------------------

  drawSlider(
    slider1Y,
    "Irregularity",
    irregularity,
    0.0,
    0.50
  );


  // ----------------------------------------------------------
  // SLIDER 2
  // ----------------------------------------------------------

  drawSlider(
    slider2Y,
    "Number of Holes / Genus",
    genus,
    0,
    MAX_GENUS
  );


  // ----------------------------------------------------------
  // SLIDER 3
  // ----------------------------------------------------------

  drawSlider(
    slider3Y,
    "Hole Size",
    holeSize,
    0.04,
    0.25
  );


  // ----------------------------------------------------------
  // SLIDER 4
  // ----------------------------------------------------------

  drawSlider(
    slider4Y,
    "Surface Resolution",
    resolution,
    25,
    100
  );


  // ----------------------------------------------------------
  // VALUES
  // ----------------------------------------------------------

  fill(220);

  textSize(12);


  text(
    "Irregularity: " +
    nf(
      irregularity,
      1,
      2
    ),
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
    nf(
      getHoleRadius(),
      1,
      1
    ),
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
  // STITCH TOGGLE
  // ----------------------------------------------------------

  drawToggle(
    30,
    420
  );


  fill(155);

  textSize(12);


  text(
    "T = toggle stitched surface",
    30,
    455
  );


  text(
    "D = diagnostic tunnel/rim view",
    30,
    473
  );


  text(
    "Drag solid = rotate",
    30,
    491
  );


  text(
    "0 holes = closed irregular sphere",
    30,
    509
  );


  text(
    "24 holes = maximum genus setting",
    30,
    527
  );


  hint(
    ENABLE_DEPTH_TEST
  );
}


// ============================================================
// TOGGLE
// ============================================================

void drawToggle(
  float x,
  float y
) {

  // Background

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


  // ----------------------------------------------------------
  // LEFT / RIGHT STATE
  // ----------------------------------------------------------

  if (stitchedSurface) {

    fill(
      60,
      210,
      255
    );

  } else {

    fill(
      90
    );
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
      "STITCHED SURFACE: ON",
      x + 32,
      y + 21
    );

  } else {

    text(
      "STITCHED SURFACE: OFF",
      x + 32,
      y + 21
    );
  }
}


// ============================================================
// SLIDER DRAWING
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

  // ----------------------------------------------------------
  // STITCH TOGGLE
  // ----------------------------------------------------------

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


  // ----------------------------------------------------------
  // SLIDER 1
  // ----------------------------------------------------------

  if (
    nearSlider(slider1Y)
  ) {

    dragSlider1 = true;

    updateSlider1();

    return;
  }


  // ----------------------------------------------------------
  // SLIDER 2
  // ----------------------------------------------------------

  if (
    nearSlider(slider2Y)
  ) {

    dragSlider2 = true;

    updateSlider2();

    return;
  }


  // ----------------------------------------------------------
  // SLIDER 3
  // ----------------------------------------------------------

  if (
    nearSlider(slider3Y)
  ) {

    dragSlider3 = true;

    updateSlider3();

    return;
  }


  // ----------------------------------------------------------
  // SLIDER 4
  // ----------------------------------------------------------

  if (
    nearSlider(slider4Y)
  ) {

    dragSlider4 = true;

    updateSlider4();

    return;
  }


  // ----------------------------------------------------------
  // ROTATION
  // ----------------------------------------------------------

  rotating = true;


  lastMouseX =
    mouseX;


  lastMouseY =
    mouseY;
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
      ) *
      0.01;


    rotX -=
      (
        mouseY -
        lastMouseY
      ) *
      0.01;


    lastMouseX =
      mouseX;


    lastMouseY =
      mouseY;
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

  // ----------------------------------------------------------
  // T = STITCHED SURFACE
  // ----------------------------------------------------------

  if (
    key == 't' ||
    key == 'T'
  ) {

    stitchedSurface =
      !stitchedSurface;
  }


  // ----------------------------------------------------------
  // D = DIAGNOSTIC
  // ----------------------------------------------------------

  if (
    key == 'd' ||
    key == 'D'
  ) {

    diagnosticMode =
      !diagnosticMode;
  }
}


// ============================================================
// SLIDER HIT TEST
// ============================================================

boolean nearSlider(
  float y
) {

  return
    mouseX >=
      sliderX - 12 &&

    mouseX <=
      sliderX +
      sliderW +
      12 &&

    mouseY >=
      y - 15 &&

    mouseY <=
      y + 15;
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
