// 3d sound spiral generator
//  by evan raskob evanraskob@gmail.com
// wave code uses code from http://code.google.com/p/musicg/
//
// Draw a base spiral and offset it by the sound volume (RMS)
//
// TODO

// - better lighting
// - fix overlay colors (TColor bug? Or PShape stroke bug?)
// - how about a REPL for commands instead of stupid key presses
// - need flat base for stand and for printing properly...
// - how about filling it to the max zScale in between shapes, so it is recessed rather 
// than filled?
// - or inner removal of material rather than exterior extrusion


import java.io.*;
import java.util.Iterator;
import toxi.geom.*;
import toxi.geom.mesh.TriangleMesh;
import toxi.geom.mesh.Mesh3D;
import toxi.geom.mesh.Face;
import toxi.math.*;
import toxi.volume.*;
import processing.opengl.*;
import peasy.*;


boolean fileChosen = false;
PrintWriter output, outputRMS;
float[] soundAmplitudes;
float[] rmsAmplitudes, rmsAmplitudes2;
ArrayList<Vec3D> outwardVecs, tanVecs;
ArrayList<LineStrip2D> profiles; // 2D polygon shapes for the tube geometry based on rms volume
ArrayList<LineStrip3D2> profilesOnCurve; // the 3D profiles fitted to the underlying curve

PShape spiralShape = null;
PShape profileShape = null;
PShape printerBoundingBox = null;
PShape soundAmpsShape = null, soundRMSShape = null, soundRMSShape2 = null;

byte profileNumber = 1; // which swept helical profile to use

TriangleMesh mesh = null;

boolean drawProfiles = false, drawVecs=false, drawPrinterBox=false, drawRMSOverlay=false;
private Vec3D modelBounds; // size of actual generated model

int diameterQuality = 10; // for spline profile
int numShapeSegments = 1; // how many segments per spiral to chop this into when saving
int spiralNumPoints = 4*(154368/441); // points in the spiral total.  Seems arbitrary but there's a historical reason for this funny number.
// NOTE: arbitrarily changed this to 4 to get better resultion

BezierInterpolation tween=new BezierInterpolation(-0.2, 0.2); // for interpolating between points
final int TWEEN_POINTS = 3; // resolution of tween

float BaseThickness = 0.5; //mm /// NOTE: changed to 2mm at spiral 009, then 0.5mm got UM3 tests
/*
      fstr(turns, 2) +"-" +
 fstr(distanceBetweenSpirals, 2) + "-" +
 fstr(xScale, 2) + "-" +
 fstr(spiralRadius, 2) + "-" +
 fstr(adjust, 4) + "-" +
 fstr(zScale, 2) + "-" +
 */
// removed dependency on turns -- 2017-Aug-14

float turns = 3.5;
float distanceBetweenSpirals = 35.48f; // in mm
float xScale = 23.07f; // in mm
float spiralRadius = 14.172489f; // in mm
//float adjust = 0.2219f;
float adjust = 1f;
float zScale = 23.164747f;
float minThickness = 0.08916104f; // percentage, 0 - 1
//int RMSSize = (int)(48000*4.873*0.00125); // 1/500th of a second  CHANGEME!!!!!  Remember that 44100 is 1 sec
// metal

float totalHeight = turns*distanceBetweenSpirals+BaseThickness; // guesstimate for reference


PeasyCam cam; // 3d camera

SpiralLineStrip3D spiral; // basic line rendering of spiral (helix) shape in 3D 

static final float log10 = log(10);


/*
 * format a float @val as a string with @places decimal places
 */
static String fstr(float val, int places)
{
  return String.format(java.util.Locale.ROOT, "%."+places+"f", val);
}

// convert number from 0 to 1 into log scale from 0 to 1
float logScale(float val, float minVal, float maxVal)
{
  val = map(val, minVal, maxVal, 1, 10);
  return log(val)/log10;
}

// convert number from 0 to 1 into log scale from 0 to 1
float revLogScale(float val, float minVal, float maxVal)
{
  val = map(val, minVal, maxVal, 10, 1);
  return log(val)/log10;
}


void setup()
{
  size(1920, 1080, P3D);

  // set up 3D view
  cam = new PeasyCam(this, 1000);
  cam.setMinimumDistance(-5);
  cam.setMaximumDistance(2000);
  cam.setResetOnDoubleClick(true);

  background(0);
  fill(200);

  setupColors();

  mesh = new TriangleMesh("spiralmesh"); // mesh to hold final spiral for export

  //
  // create printer bounding box shape for reference
  Vec3D printerSizeInMM = new Vec3D(285, 155, 153); // Makerbot replicator 2
  TriangleMesh b = (TriangleMesh)new AABB(new Vec3D(0, 0, printerSizeInMM.z()), printerSizeInMM).toMesh(); 
  //b.transform(new Matrix4x4().translateSelf(pos.x,pos.y,pos.z));  // if we need to move it
  printerBoundingBox = meshToRetained(b, false);
  printerBoundingBox.setFill(false);
  int c = color(255, 180);
  printerBoundingBox.setStroke(c);
  printerBoundingBox.setStrokeWeight(1);


  text("hit space", 10, 20);

  spiral = new SpiralLineStrip3D( new Vec3D(0, 0, 0), new Vec3D(0, 0, 1) );
  /*
  spiral.setRadius( this.width/3, false)
   .setTurns(turns, false)
   .setDistanceBetweenTurns(this.height/(turns*2), false)
   .setNumPoints(int(turns) * 12, false)
   .setEdgeThickness( this.height/(turns*8) ); 
   */

  spiral.setTurns(turns, false)
    .setRadius(spiralRadius, false)
    .setDistanceBetweenTurns(distanceBetweenSpirals, false)
    .setEdgeThickness(xScale, false);

  profiles = new ArrayList<LineStrip2D>();
  outwardVecs = new ArrayList<Vec3D>();
  tanVecs = new ArrayList<Vec3D>();
  profilesOnCurve = new ArrayList<LineStrip3D2>();  

  generateSpiralShapes();
}


// 
// Build spiral mesh (use already allocated spiral to save time/memory) with
// optional start and end caps.  Input mesh can be null.
//


void createSpiral(int numPoints, int startIndex, int endIndex, float _turns, TriangleMesh mesh, boolean startcap, boolean endcap, boolean base) throws NullPointerException
{  
  // requires:
  // - profiles (list of circular profiles for each tube segment).  Will be cleared and regenerated
  // - profilesOnCurve (list of above profiles fit to the 3D spiral curve). Will be cleared and regenerated
  // - 

  if (mesh == null) throw new NullPointerException("Mesh cannot be null in createSpiral");
  else
    mesh.clear();

  if (endIndex <=0 ) endIndex = numPoints;
  int dataLength = endIndex - startIndex;
  if ( dataLength <= 0) 
  {
    println("no data to use (start and end indices are equal or less than 0):" + dataLength);
    return;
  }

  // set number of points
  spiral.setTurns(_turns, false)
    .setRadius(spiralRadius, false)
    .setDistanceBetweenTurns(distanceBetweenSpirals, false)
    .setEdgeThickness(xScale, false)
    .setNumPoints(dataLength);

  println("total spiral points:" + spiral.getNumPoints() + " / " + dataLength);

  // calculate tangents and outwards facing vectors
  // take the next point and subtract from previous point to get inwards pointing vector

  int _numPoints = spiral.getNumPoints();

  println("DEBUG:: setting up tangent and outwards vectors");

  outwardVecs.clear();
  tanVecs.clear();

  for (int i=0; i < _numPoints; i++)
  {
    outwardVecs.add(new Vec3D(0, 0, 0));
    tanVecs.add(new Vec3D(0, 0, 0));
  }

  for (int i=1; i < _numPoints-1; i++)
  {
    Vec3D tanVec = tanVecs.get(i);
    Vec3D outVec = outwardVecs.get(i);
    Vec3D prevSpiralVec = spiral.get(i-1);
    Vec3D spiralVec = spiral.get(i);    
    Vec3D nextSpiralVec = spiral.get(i+1);

    // tangent at each point    
    tanVec.set(nextSpiralVec.sub( prevSpiralVec) );
    tanVec.normalize();

    // outward facing vector at each point
    Vec3D v0 = spiralVec.sub( prevSpiralVec );
    Vec3D v1 = spiralVec.sub( nextSpiralVec );

    // NOTE: need double precision otherwise the vectors are slightly off every 90 degrees.  Hmm.
    // This causes errors in geometry.

    Vec3D po = outwardVecs.get(i-1);
    //outVec.set(v0.add(v1).interpolateTo(po,0.1)); // try to smooth it a bit...
    outVec.set(v0.add(v1));
    outVec.normalize();
  }

  ArrayList<Vec3D> smoothOutVecs = new ArrayList<Vec3D>();

  // deal with edge cases - 1st and last
  tanVecs.get(0).set(tanVecs.get(1));
  tanVecs.get(_numPoints-1).set(tanVecs.get(_numPoints-2));

  outwardVecs.get(0).set(outwardVecs.get(1));
  outwardVecs.get(_numPoints-1).set(outwardVecs.get(_numPoints-2));

  //
  // generate the profiles for each segment of the tube, based on RMS volume 
  // 
  profiles.clear();
  profiles.ensureCapacity(_numPoints);

  profilesOnCurve.clear();
  profilesOnCurve.ensureCapacity(_numPoints);


  float ripplesPerTurn = 20.0f; // 20 for tests

  for (int i=0; i<_numPoints; i++)
  {
    float percentDone = float(i)/_numPoints;
    float totalRadians = ripplesPerTurn*turns*TWO_PI;
    float currentAngle = totalRadians * percentDone;  

    // Normal - //0.5f + adjust; 
    float currentExtrusion = 0.5f + adjust;

    if (ripplesPerTurn >= 1)
      currentExtrusion = 0.125f*(sin(currentAngle)) +  currentExtrusion;

    float thick = spiral.getEdgeThickness();
    float spiralRadius = spiral.getRadius();

    float y =  currentExtrusion*zScale;
    float yBase = 1f*zScale;

    float x = currentExtrusion*thick;
    float xBase = 0; // minRMS*thick; 

    LineStrip2D strip = new LineStrip2D();

    switch(profileNumber)
    {
    case 1:   
      strip = makeProfile1();
      break;

    case 2:   
      strip = makeProfile2();
      break;

    case 3:   
      strip = makeProfile3();
      break;

    case 4:   
      strip = makeProfile4();
      break;

    case 5:   
      strip = makeProfile5();
      break;

    case 6:   
      strip = makeProfile6();
      break;

    case 7:   
      strip = makeProfile7(currentExtrusion);
      break;

    default:
      break;
    }

    profiles.add(strip);

    // DEBUG - removed this
    // add profile to internal tube list of profiles 
    //profiles.add(strip.add(strip.get(0)));

    // test 1st and last points are the same
    //float profDist = strip.get(0).distanceTo(strip.get(strip.getVertices().size()-1));
    //println("p0-p8 dist=" + profDist);
  }


  println("DEBUG:: added " + profiles.size() + " profiles");

  //
  // BUILDING MESH AND PSHAPE ----------------------=------------
  //

  // iterate through all profiles and build 3D mesh

  final int numProfilePoints = (profiles.get(0).getVertices()).size(); // all are the same size

  // store the previously calculated points for the bezier surface in between profile rings
  Vec3D[] prevInterpPoints = new Vec3D[TWEEN_POINTS]; 

  for (int i=0; i < _numPoints-1; i++)
  {
    LineStrip2D profilePointsC = profiles.get(i);
    LineStrip2D profilePointsN = profiles.get(i+1);
    LineStrip3D2 profileOnCurveC; // current profile points on the curve

    if (i == 0)
    {
      // calculate these profiles and add
      profileOnCurveC = new LineStrip3D2(numProfilePoints); // current profile
      profilesOnCurve.add(profileOnCurveC);
    } else
    {
      // we've already calculated this
      profileOnCurveC = profilesOnCurve.get(i);
    }

    // always calculate next profiles
    LineStrip3D2 profileOnCurveN = new LineStrip3D2(numProfilePoints); // next profile
    profilesOnCurve.add(profileOnCurveN);

    // DEBUG
    //println("profilesOnCurve size=" + profilesOnCurve.size());

    ReadonlyVec3D v0 = spiral.get(i);
    ReadonlyVec3D v1 = outwardVecs.get(i);

    ReadonlyVec3D v0n = spiral.get(i+1);
    ReadonlyVec3D v1n = outwardVecs.get(i+1);

    // now loop through and calculate current & next profile points
    // first profile point is same as last, so we don't have to worry about stitching them together
    // and for each profile, interpolate between them to create smooth connections    

    Vec3D ppOnCurve1, ppOnCurve2;
    Vec3D ppOnCurve3, ppOnCurve4;  // see diagram... goes 1-2 on curve 1 (clockwise) then 3-4 on curve 2 (clockwise)


    for (int j=0; j < numProfilePoints-1; j++)
    {
      int nextPointIndex = (j+1);
      Vec2D ppC = profilePointsC.get(j);
      Vec2D ppnC = profilePointsC.get(nextPointIndex);

      Vec2D ppN = profilePointsN.get(j);
      Vec2D ppnN = profilePointsN.get(nextPointIndex);

      if (j > 0)
      {
        //we've already calculated this
        ppOnCurve1 = profileOnCurveC.get(j);
        ppOnCurve3 = profileOnCurveN.get(j);
      } else
      {
        // current curve point and current in current profile (1)
        float x0 = v0.x() + ppC.y()*v1.x();  
        float y0 = v0.y() + ppC.y()*v1.y();
        float z0 = v0.z() + ppC.x();

        ppOnCurve1 = new Vec3D(x0, y0, z0);
        profileOnCurveC.add( ppOnCurve1 );

        // next curve point and next in profile (3)
        float x0n = v0n.x() + ppN.y()*v1n.x();  
        float y0n = v0n.y() + ppN.y()*v1n.y();
        float z0n = v0n.z() + ppN.x();

        ppOnCurve3 = new Vec3D(x0n, y0n, z0n);

        profileOnCurveN.add( ppOnCurve3 );
      }

      // (2) -- next in current profile
      float x1 = v0.x() + ppnC.y()*v1.x();  
      float y1 = v0.y() + ppnC.y()*v1.y();
      float z1 = v0.z() + ppnC.x();

      ppOnCurve2 = new Vec3D(x1, y1, z1);
      profileOnCurveC.add( ppOnCurve2 );

      // (4)
      float x1n = v0n.x() + ppnN.y()*v1n.x();  
      float y1n = v0n.y() + ppnN.y()*v1n.y();
      float z1n = v0n.z() + ppnN.x();

      ppOnCurve4 = new Vec3D(x1n, y1n, z1n);
      profileOnCurveN.add( ppOnCurve4 );

      // 1-3-2
      //retained.stroke(helixColors.get(_numPoints-i-1).toARGB());
      //retained.fill(helixColors.get(i).toARGB());
      mesh.addFace( ppOnCurve1, ppOnCurve3, ppOnCurve2 );

      //2-3-4
      //retained.fill(random(120, 130), 250, 80f+175f*(float)i/_numPoints);
      mesh.addFace( ppOnCurve2, ppOnCurve3, ppOnCurve4 );

      /*
      // DEBUG -- check for triangle sides that are too long
       float d12 = ppOnCurve1.distanceTo(ppOnCurve2);
       float d13 = ppOnCurve1.distanceTo(ppOnCurve3);
       float d23 = ppOnCurve2.distanceTo(ppOnCurve3);
       float d24 = ppOnCurve2.distanceTo(ppOnCurve4);
       float d34 = ppOnCurve3.distanceTo(ppOnCurve4);
       
       if (d12  > 14)
       {
       println("spiral point["+i+"]["+j+"] 1-2 dist=" + d12);
       }
       if (d13  > 14)
       {
       println("spiral point["+i+"]["+j+"] 1-3 dist=" + d13);
       }
       if (d23 > 14)
       {
       println("spiral point["+i+"]["+j+"] 2-3 dist=" + d23);
       }
       if (d24 > 14)
       {
       println("spiral point["+i+"]["+j+"] 2-4 dist=" + d24);
       }
       if (d34 > 14)
       {
       println("spiral point["+i+"]["+(j+1)+"] 3-4 dist=" + d34);
       }
       */
    }
  }


  // sanity check - profiles on curve should be same length as 2D profiles
  if (profilesOnCurve.size() != profiles.size() ||  profilesOnCurve.size() != _numPoints )
  {
    println( "ERROR: profiles have different sizes:: [cp] " + profilesOnCurve.size() + ", [pp] " + profiles.size() + ", [np] " + _numPoints);
  }


  if (startcap)
  {
    //
    // add start cap
    //

    LineStrip3D2 startProfilePoints = profilesOnCurve.get(0);

    //retained.fill(helixColors.get(0).toARGB());

    // find average (center) point of cap
    Vec3D centerPoint = new Vec3D(0, 0, 0);
    for (ReadonlyVec3D p : startProfilePoints)
      centerPoint.addSelf(p);
    centerPoint.scaleSelf(1.0/numProfilePoints);

    // profile points go clockwise, but this is the start, so we go clockwise
    int j=0;
    while (j < numProfilePoints-1)
    {
      Vec3D v0 = startProfilePoints.get(j);
      Vec3D v1 = startProfilePoints.get(j+1);

      mesh.addFace( v0, v1, centerPoint);

      ++j;
    }
  }

  if (base)
  {
    double maxAngle = ((double)PI)/2d;


    //generate curved tail that goes into base
    LineStrip3D2 curveToBaseProfiles0 = profilesOnCurve.get(0);
    int passes = curveToBaseProfiles0.size();
    LineStrip3D2 curveToBaseProfiles1 = new LineStrip3D2();  

    double ang = 0d;
    double inc = ((double)maxAngle)/passes;

    for (int pass = 0; pass <= passes; pass++)
    { 
      curveToBaseProfiles1 = new LineStrip3D2(curveToBaseProfiles0.size()); 

      for (ReadonlyVec3D v : curveToBaseProfiles0)
      {
        ReadonlyVec3D rotationAxis = v.copy().setZ(0).getNormalized();

        // the rotation axis is x,y portion of the first point in the current curve point b/c they rotate around 0,0,0
        // this is kind of dumb because it's always pointing upwards (X) in this case

        Vec3D vr = v.getRotatedAroundAxis(rotationAxis, (float)ang);
        curveToBaseProfiles1.add( vr );
      }
      //println("meshing base curve");
      mesh.addMesh( makeMesh(curveToBaseProfiles1, curveToBaseProfiles0));
      curveToBaseProfiles0 = curveToBaseProfiles1;
      ang += inc;
    }

    //println("done base curve");
    // add last bit that curves to the base below


    float firstPointsMinZ = 9999;
    float firstPointsMaxR = -9999;
    float firstPointsMinR = 9999;


    for (ReadonlyVec3D v : curveToBaseProfiles1)
    {
      firstPointsMinZ = min(firstPointsMinZ, v.z());
      float r = v.x()*v.x()+v.y()*v.y();
      firstPointsMaxR = max(firstPointsMaxR, r);
      firstPointsMinR = min(firstPointsMinR, r);
    }
    // setup cylindrical base
    float baseStartZ = firstPointsMinZ;
    // FIXME
    //float baseEndZ = baseStartZ - distanceBetweenSpirals/4f;
    float baseEndZ = baseStartZ - BaseThickness; //mm

    double baseStartRadius = 0.90d*sqrt(firstPointsMinR);
    double baseEndRadius = 1.05d*sqrt(firstPointsMaxR); // add margin...

    int resolution = 48; // for the curved segment joining the spiral to the base cylinder

    // curveToBaseProfiles0 is the last line strip at the bottom of this shape - now 
    // make a smooth transition down to it.

    // ----------------------
    // generate base geometry
    // TODO - make this a generic function
    //
    LineStrip3D2 c1 = makeHiResCircle3D(new Vec3D(0, 0, baseStartZ), baseStartRadius, resolution);
    LineStrip3D2 c2 = makeHiResCircle3D(new Vec3D(0, 0, baseStartZ), baseEndRadius, resolution);

    mesh.addMesh( makeMesh(c2, c1));


    LineStrip3D2 c3 = makeHiResCircle3D(new Vec3D(0, 0, baseEndZ), baseStartRadius, resolution);
    LineStrip3D2 c4 = makeHiResCircle3D(new Vec3D(0, 0, baseEndZ), baseEndRadius, resolution);

    mesh.addMesh( makeMesh(c3, c4) );


    // inner walls
    c3 = makeHiResCircle3D(new Vec3D(0, 0, baseStartZ), baseStartRadius, resolution);
    c4 = makeHiResCircle3D(new Vec3D(0, 0, baseEndZ), baseStartRadius, resolution);

    mesh.addMesh( makeMesh(c3, c4) );

    // outer walls
    c3 = makeHiResCircle3D(new Vec3D(0, 0, baseStartZ), baseEndRadius, resolution);
    c4 = makeHiResCircle3D(new Vec3D(0, 0, baseEndZ), baseEndRadius, resolution);

    mesh.addMesh( makeMesh(c4, c3) );
    // 
    // done with base geometry
    // -----------------------
  }


  if (endcap)
  {
    //
    // add end cap
    //

    LineStrip3D2 endProfilePoints = profilesOnCurve.get(_numPoints-1);

    // find average (center) point of cap
    Vec3D centerPoint = new Vec3D(0, 0, 0);
    for (Vec3D p : endProfilePoints)
      centerPoint.addSelf(p);
    centerPoint.scaleSelf(1.0/numProfilePoints);

    //retained.fill(helixColors.get(_numPoints-1).toARGB());

    // profile points go clockwise, so we go backwards
    int j=numProfilePoints;

    while (j>1)
    {
      --j;
      Vec3D v0 = endProfilePoints.get(j);
      Vec3D v1 = endProfilePoints.get(j-1);

      mesh.addFace( v0, v1, centerPoint);
    }
    /////// finished with end cap
  }

  println("spiral finished");
  println("mesh faces:" + mesh.getNumFaces());
  println("mesh verts:" + mesh.getNumVertices());

  AABB modelBoundsAABB = mesh.getBoundingBox();
  modelBounds = modelBoundsAABB.getExtent().scaleSelf(2*0.0393701);
  println("model bounds in inches:"+ modelBounds);

  totalHeight = turns*distanceBetweenSpirals+BaseThickness;

  println("Model is " + totalHeight + "mm tall");
  println("= " + (0.0393701*totalHeight));
}
// finished createSpiral()
//

void drawOutVecs()
{
  beginShape(LINES);
  noFill();
  strokeWeight(2);
  stroke(180, 255, 220);

  int i=0;

  for (Vec3D v : outwardVecs)
  {
    vertex(spiral.get(i));
    vertex(v.scale(10).add(spiral.get(i)));
    i++;
  }
  endShape();
}

void draw()
{  
  if (drawProfiles)
    background(255);
  else
    background (0);

  fill(200, 0, 200, 100);
  //stroke(255);

  pushMatrix();
  scale(5);

  // draw dektop 3D printer shape for reference
  if (drawPrinterBox) shape(printerBoundingBox);

  if (!drawProfiles)
  {
    if (spiralShape != null)
    {
      lights();
      ambientLight(10, 10, 10);
      directionalLight(100, 100, 140, -0.6, 0, -1);
      directionalLight(104, 104, 124, 0.6, 0, 1);
      shape(spiralShape);
      noLights();
    }
  } else
  {
    noLights();
    stroke(0);
    fill(0);
    translate(0, 0, -100);
    scale(3);
    profileShape.setStroke(color(0, 200));

    if (profileShape != null)
      shape(profileShape);
  }
  popMatrix();

  if (true)
  {  
    // draw info overlay

    int fontsize = 18;
    int startX = fontsize;
    int startY = 2*fontsize;

    if (drawVecs)
      drawOutVecs();
    hint(ENABLE_DEPTH_TEST);

    cam.beginHUD();
    textSize(fontsize);
    textAlign(LEFT, BOTTOM);

    fill(255);
    text("spiral points: " + spiralNumPoints, startX, startY );
    startY += fontsize;
    text("turns: " + turns, startX, startY );
    startY += fontsize;
    text("distanceBetweenSpirals: " + distanceBetweenSpirals, startX, startY );
    startY += fontsize;
    text("thickness: " + xScale, startX, startY );
    startY += fontsize;
    text("radius: " + spiralRadius, startX, startY );
    startY += fontsize;
    text("layer thickness adjust: " + adjust, startX, startY );
    startY += fontsize;
    text("zScale: " + zScale, startX, startY );
    startY += fontsize;
    text("elapsed: " + millis()/1000.0 + "s", startX, startY );  
    cam.endHUD();
  }
} // end draw


void keyReleased()
{
  // number keys 1-6
  if (key > 48 && key < 58)
  {
    noLoop();
    profileNumber = (byte)(key-48);
    println("profile: " + profileNumber);
    generateSpiralShapes();
    loop();
  } else
    if (key == 'D')
    {
      noLoop();
      distanceBetweenSpirals *= 1.10;
      generateSpiralShapes();
      println("distanceBetweenSpirals:" + distanceBetweenSpirals);
      loop();
    } else if (key == 'd')
    {
      noLoop();
      distanceBetweenSpirals /= 1.10;
      generateSpiralShapes();
      println("distanceBetweenSpirals:" + distanceBetweenSpirals);
      loop();
    } else if (key == 'P')
    {
      noLoop();
      zScale *= 1.10;
      generateSpiralShapes();
      println("zScale:" + zScale);
      loop();
    } else if (key == 'p')
    {
      noLoop();
      zScale /= 1.10;
      generateSpiralShapes();
      println("zScale:" + zScale);
      loop();
    } else if (key == 'T')
    {
      noLoop();
      turns+=0.05;
      generateSpiralShapes();
      println("turns:" + turns);
      loop();
    } else if (key == 't')
    {
      noLoop();
      turns-=0.05;
      generateSpiralShapes();
      println("turns:" + turns);
      loop();
    } else if (key == 'h')
    {
      noLoop();
      xScale/=1.1;
      generateSpiralShapes();
      println("xScale:" + xScale);
      loop();
    } else if (key == 'H')
    {
      noLoop();
      xScale*=1.1;
      generateSpiralShapes();
      println("xScale:" + xScale);
      loop();
    } else if (key == 'm')
    {
      noLoop();
      minThickness/=1.1;
      generateSpiralShapes();
      println("minThickness:" + minThickness);
      loop();
    } else if (key == 'M')
    {
      noLoop();
      minThickness*=1.1;
      generateSpiralShapes();
      println("minThickness:" + minThickness);
      loop();
    } else if (key == 'a')
    {
      noLoop();
      adjust /= 1.2;
      generateSpiralShapes();
      println("adjust:" + adjust);
      loop();
    } else if (key == 'A')
    {
      noLoop();
      adjust *= 1.2;
      generateSpiralShapes();
      println("adjust:" + adjust);
      loop();
    } else if (key == 'r')
    {
      noLoop();
      spiralRadius /= 1.1;
      generateSpiralShapes();
      println("spiralRadius:" + spiralRadius);
      loop();
    } else if (key == 'R')
    {
      noLoop();
      spiralRadius *= 1.1;
      generateSpiralShapes();
      println("spiralRadius:" + spiralRadius);
      loop();
    } else if (key == 'z')
    {
      drawProfiles = !drawProfiles;
    } else if (key =='v')
    {
      drawVecs = !drawVecs;
    } else if (key == 'F')
    {
      String fileName = "spiral" +
        fstr(turns, 2) +"-" +
        fstr(distanceBetweenSpirals, 2) + "-" +
        fstr(xScale, 2) + "-" +
        fstr(spiralRadius, 2) + "-" +
        fstr(adjust, 4) + "-" +
        fstr(zScale, 2) + "-" +
        ".png" ;
      saveFrame(dataPath(fileName));
    } else if (key == 's')
    {
      println("SAVING!!!!");

      String fileName = "spiral" +
        fstr(turns, 2) +"-" +
        fstr(distanceBetweenSpirals, 2) + "-" +
        fstr(xScale, 2) + "-" +
        fstr(spiralRadius, 2) + "-" +
        fstr(adjust, 4) + "-" +
        fstr(zScale, 2) + "-" +
        ".stl" ;
      mesh.saveAsSTL(dataPath(fileName) );

      println("saved: " + fileName);

      // reset to full spiral
      createSpiral(spiralNumPoints, 0, -1, turns, mesh, false, true, true);
    }
}



void generateSpiralShapes()
{
  noLoop(); //turn off loop until needed
  createSpiral(spiralNumPoints, 0, -1, turns, mesh, false, true, true);

  // set color scheme
  //helixColors = helixColorTheme.getColors(_numPoints);

  helixColorGrad.addColorAt(0, helixStartColor);
  helixColorGrad.addColorAt(mesh.getNumFaces(), helixEndColor);
  helixColors = helixColorGrad.calcGradient(0, mesh.getNumFaces());

  //spiralShape = meshToRetained(mesh, helixColors, false);
  spiralShape = meshToRetained(mesh, false);

  // create profiles shape (for future visualisation)
  profileShape = pathsToShape2(profilesOnCurve);
  profileShape.noFill();
  profileShape.setStroke(color(255, 80));
  loop();
}


void pvertex(PShape p, Vec3D v)
{
  p.vertex(v.x(), v.y(), v.z());
}

void vertex(Vec3D v)
{
  vertex(v.x(), v.y(), v.z());
}

void vertex(float[] v)
{
  vertex(v[0], v[1], v[2]);
}
