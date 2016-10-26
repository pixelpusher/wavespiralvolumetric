// 3d sound spiral generator //<>// //<>// //<>// //<>// //<>// //<>//
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
// - how about filling it to the max spikiness in between shapes, so it is recessed rather 
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

TriangleMesh mesh = null;

boolean drawProfiles = false, drawVecs=false, drawPrinterBox=false, drawRMSOverlay=false;

String wavFileName = "";
int wavSampleRate = 1; // sample rate of Wave file
int diameterQuality = 10;
byte numShapeSegments = 6; // how many segments to chop this into when saving

//metal 3 sec - 6,0,60,90,120,0.125,44100 *1*1.1/500.0

BezierInterpolation tween=new BezierInterpolation(-0.2, 0.2); // for interpolating between points
final int TWEEN_POINTS = 3; // resolution of tween

float adjust = 0.01f;
float turns = 3;
float spiralThickness = 60.0/turns; // in mm
float distanceBetweenSpirals = 12.0/turns; // in mm
float spiralRadius = 0.8f; // in mm
//float spikiness = 160*3;
float spikiness = 28f;
float minThickness = 0.01f; // percentage, 0 - 1
//int RMSSize = (int)(48000*4.873*0.00125); // 1/500th of a second  CHANGEME!!!!!  Remember that 44100 is 1 sec
// metal
int RMSSize =1; // will be overriden in fileSelected() function

//(int)(44100.0*12.0/(6.0*40.0)); // 1/500th of a second  CHANGEME!!!!!  Remember that 44100 is 1 sec
// metal 22
//int RMSSize = (int)(44100*2/turns / 100); // total length is 24.472 which encompasses 22 whole strides
// with 100 rms divisions per 360 degrees (e.g. per turn)

PeasyCam cam;

LineStrip3D2 spiral;

static final float log10 = log(10);

float ampMin = MAX_INT;
float ampMax = MIN_INT;

/*
 * format a float asa string with @places decimal places
 */
static String fstr(float val, int places)
{
  return String.format(java.util.Locale.ROOT, "%."+places+"f", val);
}

// convert number from 0 to 1 into log scale from 0 to 1
float logScale(float val, float minVal, float maxVal)
{
  val = map(val, minVal, maxVal, 1, 10);
  //val *= val;
  return log(val)/log10;
}

// convert number from 0 to 1 into log scale from 0 to 1
float revLogScale(float val, float minVal, float maxVal)
{
  val = map(val, minVal, maxVal, 10, 1);
  //val *= val;
  return log(val)/log10;
}


void setup()
{
  size(1280, 720, P3D);

  cam = new PeasyCam(this, 200);
  cam.setMinimumDistance(-5);
  cam.setMaximumDistance(200);
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

  spiral = new LineStrip3D2();


  profiles = new ArrayList<LineStrip2D>();
  outwardVecs = new ArrayList<Vec3D>();
  tanVecs = new ArrayList<Vec3D>();
  profilesOnCurve = new ArrayList<LineStrip3D2>();  

  noLoop(); //turn off loop until needed
}


// 
// Build spiral mesh (use already allocated spiral to save time/memory) with
// optional start and end caps.  Input mesh can be null.
//

void createSpiral(float[] data, int startIndex, int endIndex, TriangleMesh mesh, boolean startcap, boolean endcap, boolean base) throws NullPointerException
{  
  // requires:
  // - profiles (list of circular profiles for each tube segment).  Will be cleared and regenerated
  // - profilesOnCurve (list of above profiles fit to the 3D spiral curve). Will be cleared and regenerated
  // - 

  spiral.clear();

  if (mesh == null) throw new NullPointerException("Mesh cannot be null in createSpiral");
  else
    mesh.clear();

  if (endIndex <=0 ) endIndex = data.length;
  int dataLength = endIndex - startIndex;
  if ( dataLength <= 0) 
  {
    println("no data to use (start and end indices are equal or less than 0):" + dataLength);
    return;
  }


  println("DEBUG:: setting up tangent and outwards vectors");

  outwardVecs.clear();
  tanVecs.clear();

  for (float i=startIndex; i < endIndex; i++)
  {
    Vec3D vert = new Vec3D(150f*i/dataLength, 0f, 0f);
    spiral.add(vert);

    outwardVecs.add(new Vec3D(0, 0, 0));
    tanVecs.add(new Vec3D(0, 0, 0));
  }

  for (int i=1; i < dataLength-1; i++)
  {
    Vec3D tanVec = tanVecs.get(i);
    Vec3D outVec = outwardVecs.get(i);
    Vec3D prevSpiralVec = spiral.get(i-1);
    Vec3D spiralVec = spiral.get(i);    
    Vec3D nextSpiralVec = spiral.get(i+1);

    // tangent at each point
    // won't really work if this is just a line... 
    //tanVec.set(nextSpiralVec.sub( prevSpiralVec) );
    tanVec.set(0f, 0f, 1f);
    //tanVec.normalize();

    // outward facing vector at each point
    // also won't work if this is a line. Then we need to define y-axis as "outward" 
    Vec3D v0 = spiralVec.sub( prevSpiralVec );
    Vec3D v1 = spiralVec.sub( nextSpiralVec );

    // TODO - FIXME
    // there's an issue... the vectors are slightly off every 90 degrees.  Hmm.
    // This causes errors in geometry.  This is caused by float/double error

    Vec3D po = outwardVecs.get(i-1);
    //outVec.set(v0.add(v1).interpolateTo(po,0.1)); // try to smooth it a bit...
    // Vec3D newOutVec = (v0.add(v1)).normalize();

    outVec.set(0f, 1f, 0f );
    //outVec.normalize();
  }

  ArrayList<Vec3D> smoothOutVecs = new ArrayList<Vec3D>();

  // deal with edge cases - 1st and last
  tanVecs.get(0).set(tanVecs.get(1));
  tanVecs.get(dataLength-1).set(tanVecs.get(dataLength-2));

  outwardVecs.get(0).set(outwardVecs.get(1));
  outwardVecs.get(dataLength-1).set(outwardVecs.get(dataLength-2));

  //
  // generate the profiles for each segment of the tube, based on RMS volume 
  // 
  profiles.clear();
  profiles.ensureCapacity(dataLength);

  profilesOnCurve.clear();
  profilesOnCurve.ensureCapacity(dataLength);


  for (int i=startIndex; i < endIndex; i++)
  {
    Spline2D spline = new Spline2D();
    float currentRMS = (rmsAmplitudes[i] + adjust);
    float minRMS = (ampMin+adjust);
    float thick = spiralThickness;
    //float spiralRadius = spiral.getRadius();

    float yRMS =  currentRMS*spikiness;
    float yBase = minRMS*spikiness;
    float y = yRMS;


    float xRMS = currentRMS*thick;
    float xBase = minRMS*thick;
    float x = xRMS;



    // pointy on bottom
    spline.add(0, adjust*spikiness*0.3);    
    spline.add(x*0.4, y*0.66); //underhang
    spline.add(x, y);
    spline.add(x*0.66, y*0.3); // overhang
    spline.add(adjust*thick*0.4, 0);
    //spline.add(0, 0.1);
    // close spline
    LineStrip2D strip = spline.toLineStrip2D(diameterQuality);
    strip.add(0, adjust*spikiness*0.3); 

    /*
    //classic inverted
     // pointy on top
     // if just reversed would never print because bottom too intricate
     spline.add(x, x);
     //spline.add(xBase,yBase);
     spline.add(x*0.8, x*0.2);
     //spline.add(xBase*0.66,yBase*0.3); // overhang
     spline.add(0, 0); // close spline    
     //spline.add(xBase*0.4,yBase*0.66); //underhang
     spline.add(x*0.2, x*0.8);
     //spline.add(xBase,yBase);
     spline.add(x, x);
     */

    //LineStrip2D strip = spline.toLineStrip2D(diameterQuality);

    /*
// SIN SPIKES
     LineStrip2D strip = new LineStrip2D();
     
     // pointy on top v2
     
     double inc = Math.PI/24;
     double maxAngle = Math.PI*2d;
     
     for (double angle=0; angle<maxAngle; angle+=inc)
     {
     double prog = Math.abs(angle/(maxAngle/2) - 1);
     double xx = prog*x;
     
     strip.add((float)(0.5d*xx*(Math.cos(angle+inc*6d)+1d)), (float)(0.5d*xx*(Math.sin(angle+inc*6d)+1d)));
     }
     // END SIN SPIKES
     */

    /*
     // SIN SPIKES smoothed
     LineStrip2D strip = new LineStrip2D();
     
     // pointy on top v2    
     double inc = Math.PI/24d;
     double maxAngle = Math.PI*2d;
     double offset = Math.PI/6d;
     
     for (double angle=0; angle<maxAngle; angle+=inc)
     {
     double prog = Math.abs(angle/(maxAngle/2) - 1);
     prog = prog*prog; // smoothing
     //prog = prog*prog; //cubic?
     
     double xx = (1d-prog)*xBase + prog*x;  //yeah, float/double conversion blah blah
     
     strip.add((float)(0.5d*xx*(Math.cos(angle+offset)+1d)), (float)(0.5d*xx*(Math.sin(angle+offset)+1d)));
     }
     // END SIN SPIKES
     */

    /*
    // SIN SPIKES smoothed 2
     LineStrip2D strip = new LineStrip2D();
     
     // pointy on top v2    
     double inc = Math.PI/24d;
     double maxAngle = Math.PI*2d;
     double offset = Math.PI/2d;
     
     for (double angle=0; angle<maxAngle; angle+=inc)
     {
     double prog = Math.abs(angle/(maxAngle/2) - 1);
     prog -= 1d;
     prog = prog*prog; // smoothing
     prog = prog*prog; //cubic?
     
     double xx = (1d-prog)*x + prog*xBase;  //yeah, float/double conversion blah blah
     
     strip.add((float)(0.5d*xx*(Math.cos(angle+offset)+1d)), (float)(0.5d*xx*(Math.sin(angle+offset)+1d)));
     }
     // END SIN SPIKES 2
     */

    /*
     // SIN squared smoothed SPIKES smoothed
     LineStrip2D strip = new LineStrip2D();
     
     // pointy on top v2    
     double inc = Math.PI/24d;
     double maxAngle = Math.PI*2d;
     double offset = Math.PI/6d;
     
     for (double angle=0; angle<maxAngle; angle+=inc)
     {
     //double prog = Math.sin(Math.abs(angle/(maxAngle/2) - 1)*Math.PI*0.5d); // full sin
     double prog = Math.sin(Math.abs(angle/(maxAngle/2) - 1)*Math.PI*0.2d); // little pointy on top
     //prog = prog*prog; // smoothing
     //prog = prog*prog; //cubic?
     
     double xx = (1d-prog)*xBase + 2*prog*x;  //yeah, float/double conversion blah blah
     
     strip.add((float)(0.5d*xx*(Math.cos(angle+offset)+1d)), (float)(0.5d*xx*(Math.sin(angle+offset)+1d)));
     }
     // END SIN squared SPIKES
     */


    // DEBUG - removed this
    // add profile to internal tube list of profiles 
    //profiles.add(strip.add(strip.get(0)));

    // test 1st and last points are the same
    //float profDist = strip.get(0).distanceTo(strip.get(strip.getVertices().size()-1));
    //println("p0-p8 dist=" + profDist);

    profiles.add(strip);
  }

  println("DEBUG:: added " + profiles.size() + " profiles");

  //
  // BUILDING MESH AND PSHAPE ----------------------=------------
  //

  // iterate through all profiles and build 3D mesh

  final int numProfilePoints = (profiles.get(0).getVertices()).size(); // all are the same size

  // store the previously calculated points for the bezier surface in between profile rings
  Vec3D[] prevInterpPoints = new Vec3D[TWEEN_POINTS]; 

  for (int i=0; i < dataLength-1; i++)
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
      //retained.stroke(helixColors.get(numPoints-i-1).toARGB());
      //retained.fill(helixColors.get(i).toARGB());
      mesh.addFace( ppOnCurve1, ppOnCurve3, ppOnCurve2 );

      //2-3-4
      //retained.fill(random(120, 130), 250, 80f+175f*(float)i/numPoints);
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
  if (profilesOnCurve.size() != profiles.size() ||  profilesOnCurve.size() != dataLength )
  {
    println( "ERROR: profiles have different sizes:: [cp] " + profilesOnCurve.size() + ", [pp] " + profiles.size() + ", [np] " + dataLength);
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
    float baseEndZ = baseStartZ - distanceBetweenSpirals/4f;
    double baseStartRadius = 0.95d*sqrt(firstPointsMinR);
    double baseEndRadius = 1.2d*sqrt(firstPointsMaxR); // add margin...

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

    LineStrip3D2 endProfilePoints = profilesOnCurve.get(dataLength-1);

    // find average (center) point of cap
    Vec3D centerPoint = new Vec3D(0, 0, 0);
    for (Vec3D p : endProfilePoints)
      centerPoint.addSelf(p);
    centerPoint.scaleSelf(1.0/numProfilePoints);

    //retained.fill(helixColors.get(numPoints-1).toARGB());

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
}
// finished createSpiral()
//

void drawOutVecs()
{
  beginShape(LINES);
  noFill();
  strokeWeight(2);

  int i=0;

  for (Vec3D v : outwardVecs)
  {
    stroke(200, 200, 0);
    vertex(spiral.get(i));
    vertex(v.scale(10).add(spiral.get(i)));
    i++;
  }

  i = 0;
  for (Vec3D v : tanVecs)
  {
    stroke(200, 0, 250);
    vertex(spiral.get(i));
    vertex(v.scale(10).add(spiral.get(i)));
    i++;
  }

  endShape();
}

void draw()
{  
  background(0);
  fill(200, 0, 200, 100);
  //stroke(255);


  if (drawRMSOverlay)
  {
    noLights();
    hint(DISABLE_DEPTH_TEST);
    colorMode(RGB);

    if (soundAmpsShape != null)  
      shape(soundAmpsShape);

    if (soundRMSShape != null)
      shape(soundRMSShape);

    if (soundRMSShape2 != null)
      shape(soundRMSShape2);

    hint(ENABLE_DEPTH_TEST);
  } else
  {
    PGL pgl = beginPGL();
    //lights();
    //camera(width - 2*mouseX, height - 2*mouseY, 400, 0, 0, 0, 0, 1, 0);
    // turn on backfce culling to make sure it looks as it will come out...
    pushMatrix();
    scale(5);

    // draw dektop 3D printer shape for reference
    if (drawPrinterBox) shape(printerBoundingBox);

    //lights();
    // DRAW PSHAPE STUFF

    //pgl.enable(PGL.CULL_FACE);
    // make sure we are culling the right faces - STL files need anti-clockwise winding orders for triangles
    //pgl.frontFace(PGL.CCW);
    //pgl.cullFace(PGL.BACK);

    //pgl.disable(PGL.CULL_FACE);

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
    }
    popMatrix();
    endPGL(); // restores the GL defaults for Processing
    //noLights();
  }

  if (true)
  {  
    // draw info overlay

    int fontsize = 18;
    int startX = fontsize;
    int startY = 2*fontsize;


    hint(DISABLE_DEPTH_TEST);

    if (drawProfiles)
      if (profileShape != null)
        shape(profileShape);

    if (drawVecs)
      drawOutVecs();

    if (soundAmplitudes != null)
    {
      cam.beginHUD();

      textSize(fontsize);
      textAlign(LEFT, BOTTOM);

      fill(255);
      text("file: " + wavFileName, startX, startY );
      startY += fontsize;
      text("file length: " + soundAmplitudes.length/(float)wavSampleRate + "sec", startX, startY );
      startY += fontsize;
      text("turns: " + turns, startX, startY );
      startY += fontsize;
      text("distanceBetweenSpirals: " + distanceBetweenSpirals, startX, startY );
      startY += fontsize;
      text("thickness: " + spiralThickness, startX, startY );
      startY += fontsize;
      text("radius: " + spiralRadius, startX, startY );
      startY += fontsize;
      text("layer thickness adjust: " + adjust, startX, startY );
      startY += fontsize;
      text("spikiness: " + spikiness, startX, startY );
      startY += fontsize;
      text("wavSampleRate: " + wavSampleRate, startX, startY );
      startY += fontsize;
      text("RMSSize: " + RMSSize + "samps / " + 1000.0*(RMSSize/(float)wavSampleRate) + "ms", startX, startY );
      startY += fontsize;
      text("elapsed: " + millis()/1000.0 + "s", startX, startY );

      cam.endHUD();
    }
    hint(ENABLE_DEPTH_TEST);
  }
} // end draw


void keyReleased()
{
  if (key == '+')
  {
    noLoop();
    if (RMSSize < 10) ++RMSSize;
    else
      RMSSize *=1.1;
    //println("RMSSize:" + RMSSize);
    computeRMS();
    loop();
  } else if (key == '-')
  {
    noLoop();
    if (RMSSize < 10)
    {
      if (RMSSize > 1) --RMSSize;
    } else
      RMSSize /= 1.1;

    computeRMS();
    //println("RMSSize:" + RMSSize);
    loop();
  } else if (key == 'o')
  {
    drawRMSOverlay = !drawRMSOverlay;
  } else if (key == 'D')
  {
    noLoop();
    distanceBetweenSpirals *= 1.10;
    computeRMS();
    println("distanceBetweenSpirals:" + distanceBetweenSpirals);
    loop();
  } else if (key == 'd')
  {
    noLoop();
    distanceBetweenSpirals /= 1.10;
    computeRMS();
    println("distanceBetweenSpirals:" + distanceBetweenSpirals);
    loop();
  } else if (key == 'P')
  {
    noLoop();
    spikiness *= 1.10;
    computeRMS();
    println("spikiness:" + spikiness);
    loop();
  } else if (key == 'p')
  {
    noLoop();
    spikiness /= 1.10;
    computeRMS();
    println("spikiness:" + spikiness);
    loop();
  } else if (key == 'T')
  {
    noLoop();
    turns+=0.05;
    computeRMS();
    println("turns:" + turns);
    loop();
  } else if (key == 't')
  {
    noLoop();
    turns-=0.05;
    computeRMS();
    println("turns:" + turns);
    loop();
  } else if (key == 'h')
  {
    noLoop();
    spiralThickness/=1.1;
    computeRMS();
    println("spiralThickness:" + spiralThickness);
    loop();
  } else if (key == 'H')
  {
    noLoop();
    spiralThickness*=1.1;
    computeRMS();
    println("spiralThickness:" + spiralThickness);
    loop();
  } else if (key == 'm')
  {
    noLoop();
    minThickness/=1.1;
    computeRMS();
    println("minThickness:" + minThickness);
    loop();
  } else if (key == 'M')
  {
    noLoop();
    minThickness*=1.1;
    computeRMS();
    println("minThickness:" + minThickness);
    loop();
  } else if (key == 'a')
  {
    noLoop();
    adjust /= 1.2;
    computeRMS();
    println("adjust:" + adjust);
    loop();
  } else if (key == 'A')
  {
    noLoop();
    adjust *= 1.2;
    computeRMS();
    println("adjust:" + adjust);
    loop();
  } else if (key == 'r')
  {
    noLoop();
    spiralRadius /= 1.1;
    computeRMS();
    println("spiralRadius:" + spiralRadius);
    loop();
  } else if (key == 'R')
  {
    noLoop();
    spiralRadius *= 1.1;
    computeRMS();
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
    // get first part of filename, ignore extension
    String filenameNoExt = split(wavFileName, '.')[0];
    String wavname = filenameNoExt.substring(0, min(filenameNoExt.length(), 50)); // paths have limits of about 255 chars these days

    String fileName = wavname + ".lin." + 
      fstr(turns, 2) +"-" +
      fstr(distanceBetweenSpirals, 2) + "-" +
      fstr(spiralThickness, 2) + "-" +
      fstr(spiralRadius, 2) + "-" +
      fstr(adjust, 4) + "-" +
      fstr(spikiness, 2) + "-" +
      RMSSize + "-" +
      wavSampleRate +
      ".png" ;
    saveFrame(dataPath(fileName));
  } else if (key == 's')
  {
    // get first part of filename, ignore extension
    String filenameNoExt = split(wavFileName, '.')[0];
    String wavname = filenameNoExt.substring(0, min(filenameNoExt.length(), 50)); // paths have limits of about 255 chars these days

    int segmentSize = rmsAmplitudes.length/numShapeSegments;

    for (int i=0; i < numShapeSegments; i++)
    {
      println("segments:" + segmentSize*i + " " + segmentSize*(i+1));
      createSpiral(rmsAmplitudes, segmentSize*i, segmentSize*(i+1), mesh, true, true, false);

      String fileName = wavname + ".lin-" + nf(i, 3) + "." +
        fstr(turns, 2) +"-" +
        fstr(distanceBetweenSpirals, 2) + "-" +
        fstr(spiralThickness, 2) + "-" +
        fstr(spiralRadius, 2) + "-" +
        fstr(adjust, 4) + "-" +
        fstr(spikiness, 2) + "-" +
        RMSSize + "-" +
        wavSampleRate +
        ".stl" ;
      mesh.saveAsSTL(dataPath(fileName) );

      println("saved: " + fileName);
    }
  } else if (key==' ')
  { 
    if (!fileChosen) 
    {
      fileChosen = true;
      //background(0, 200, 0);
      selectInput("Select a file to process:", "fileSelected");
    }
  }
}



void fileSelected(File selection) 
{
  if (selection == null) 
  {
    println("Window was closed or the user hit cancel.");
  } else 
  {
    println("file selected " + selection.getAbsolutePath());
    wavFileName = selection.getName();

    InputStream inputStream = null;
    WaveHeader waveHeader = null;

    try {
      inputStream = new FileInputStream(selection.getAbsolutePath());
      waveHeader = new WaveHeader(inputStream);
    } 
    catch (FileNotFoundException e) {
      e.printStackTrace();
    } 


    if (waveHeader != null && waveHeader.isValid()) 
    {
      try
      {
        wavSampleRate = waveHeader.getSampleRate();   
        println("sample rate:" + wavSampleRate);
        // load data

        byte[] data = new byte[inputStream.available()];
        inputStream.read(data);
        Wave wavFile = new Wave(waveHeader, data);
        //short[] amplitudes = wavFile.getSampleAmplitudes();
        NormalizedSampleAmplitudes nsa = new NormalizedSampleAmplitudes(wavFile);
        double[] amps = nsa.getNormalizedAmplitudes();
        soundAmplitudes = new float[amps.length];

        // initialize to 20 points per turn, to start
        RMSSize = max(1, int(amps.length / (100.0 * turns))); 

        for (int i=0; i<amps.length; i++)
          soundAmplitudes[i] = (float) amps[i];

        println("found " + soundAmplitudes.length + " samples");
      } 
      catch (Exception e) 
      {
        println(e.getMessage());
        e.printStackTrace();
      }

      computeRMS();
      loop();
      // end load data
    } else {
      println("Invalid Wave Header");
    }

    if (inputStream != null)
    {
      try {
        inputStream.close();
      }
      catch (IOException e) {
        e.printStackTrace();
      }
    }

    // short version:
    // Open the wav file specified as the first argument
    //Wave wavFile = new Wave(selection.getAbsolutePath());
  }
  fileChosen = false; // reset for next time
}


void computeRMS()
{
  println("RMS Size: " + RMSSize);

  ampMin = MAX_FLOAT;
  ampMax = MIN_FLOAT;

  rmsAmplitudes = new float[soundAmplitudes.length/RMSSize];
  rmsAmplitudes2 = new float[soundAmplitudes.length/RMSSize];

  // println("calculating " + rmsAmplitudes.length + " samples");

  int currentIndex = 0;
  int rmsArrayIndex = 0;

  while (rmsArrayIndex < rmsAmplitudes.length)
  {
    int samplesLeft = soundAmplitudes.length - currentIndex;
    if (samplesLeft < RMSSize)
    {
      // println("RMS calc done:" + samplesLeft);
      break; // stop loop!
    }

    int RMSIndex = 0;
    float RMSSum = 0, RMSSum2=0;
    float prevData = 0f;

    while (RMSIndex < RMSSize)
    {
      // convert data to float
      float data = (float)soundAmplitudes[currentIndex];
      float diffData = data - prevData;
      // debug
      /*if (rmsArrayIndex == rmsAmplitudes.length-1)
       {
       // println("data[" + currentIndex + "]=" + data);
       }*/
      RMSSum2 += diffData*diffData; // add square of data to sum
      RMSSum += data*data;
      currentIndex++; 
      RMSIndex++;
      prevData = data;
    }

    // find average value - could also scale logarithmically
    float RMSAve = RMSSum / float(RMSSize);

    rmsAmplitudes[rmsArrayIndex] = sqrt(RMSAve);
    ampMin = min(ampMin, rmsAmplitudes[rmsArrayIndex]);
    ampMax = max(ampMax, rmsAmplitudes[rmsArrayIndex]);

    rmsAmplitudes2[rmsArrayIndex++] = sqrt(RMSSum2/float(RMSSize));



    //println("stored " + (rmsArrayIndex-1) + ":" + RMSAve);
  }

  println("ampMin:" + ampMin);
  println("ampMax:" + ampMax);

  float[] rmsAmplitudesExtended = new float[rmsAmplitudes.length*TWEEN_POINTS];  //leave room for end->start

  for (int i=0; i<rmsAmplitudes.length-1; i++)
  {
    for (int ii=0; ii < TWEEN_POINTS; ii++)
    {
      // calculate linear mix of two vectors 
      float progress = (float)ii/(TWEEN_POINTS-1); // make sure it goes to 100%
      float tweenVal = tween.interpolate(rmsAmplitudes[i], rmsAmplitudes[i+1], progress); // get values btw 0 and 1
      rmsAmplitudesExtended[i*TWEEN_POINTS+ii] = tweenVal;
    }
  }
  // now start to finish
  float first = rmsAmplitudes[0];
  float last = rmsAmplitudes[rmsAmplitudes.length-1];

  for (int ii=0; ii < TWEEN_POINTS; ii++)
  {
    // calculate linear mix of two vectors 
    float progress = (float)ii/(TWEEN_POINTS-1); // make sure it goes to 100%
    float tweenVal = tween.interpolate(last, first, progress); // get values btw 0 and 1
    rmsAmplitudesExtended[(rmsAmplitudes.length-1)*TWEEN_POINTS+ii] = tweenVal;
  }

  rmsAmplitudes = rmsAmplitudesExtended;
  // use entire sound segment
  createSpiral(rmsAmplitudes, 0, -1, mesh, true, true, false);
  createRMSVizShapes();

  // set color scheme
  //helixColors = helixColorTheme.getColors(numPoints);

  helixColorGrad.addColorAt(0, helixStartColor);
  helixColorGrad.addColorAt(mesh.getNumFaces(), helixEndColor);
  helixColors = helixColorGrad.calcGradient(0, mesh.getNumFaces());

  //spiralShape = meshToRetained(mesh, helixColors, false);
  spiralShape = meshToRetained(mesh, false);

  // create profiles shape (for future visualisation)
  profileShape = pathsToShape2(profilesOnCurve);
  profileShape.noFill();
  profileShape.setStroke(color(255, 80));
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