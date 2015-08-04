// 3d sound spiral generator
//  by evan raskob evanraskob@gmail.com
// wave code uses code from http://code.google.com/p/musicg/
//
// Draw a base spiral and offset it by the sound volume (RMS)
//
// TODO
// - fix bounding box pshape display - not showing due to some PShape thing?
// - bounding box check - model size display too!! How bug are these??
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
float[] rmsAmplitudes;
ArrayList<Vec3D> outwardVecs, tanVecs;
ArrayList<LineStrip2D> profiles; // 2D polygon shapes for the tube geometry based on rms volume
ArrayList<LineStrip3D2> profilesOnCurve; // the 3D profiles fitted to the underlying curve

PShape spiralShape = null;
PShape profileShape = null;
PShape printerBoundingBox = null;
TriangleMesh mesh = null;

boolean drawProfiles = false;

String wavFileName = "";
int wavSampleRate; // sample rate of Wave file
int diameterQuality = 4;

//metal 3 sec - 6,0,60,90,120,0.125,44100 *1*1.1/500.0

float turns = 6;
float spiralThickness = 80.0/turns; // in mm
float distanceBetweenSpirals = 20.0/turns; // in mm
float spiralRadius = 40; // in mm
//float spikiness = 160*3;
float spikiness = 40;
float minThickness = 0.15; // percentage, 0 - 1
//int RMSSize = (int)(48000*4.873*0.00125); // 1/500th of a second  CHANGEME!!!!!  Remember that 44100 is 1 sec
// metal
int RMSSize =1; // will be overriden in fileSelected() function

//(int)(44100.0*12.0/(6.0*40.0)); // 1/500th of a second  CHANGEME!!!!!  Remember that 44100 is 1 sec
// metal 22
//int RMSSize = (int)(44100*2/turns / 100); // total length is 24.472 which encompasses 22 whole strides
// with 100 rms divisions per 360 degrees (e.g. per turn)

PeasyCam cam;

SpiralLineStrip3D spiral;

static final float log10 = log(10);

float ampMin = MAX_INT;
float ampMax = MIN_INT;

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

  cam = new PeasyCam(this, width);
  cam.setMinimumDistance(0);
  cam.setMaximumDistance(width*200);
  cam.setResetOnDoubleClick(true);

  background(0);
  fill(200);

  //
  // create printer bounding box shape for reference
  Vec3D printerSizeInMM = new Vec3D(285, 153, 155); // Makerbot replicator 2
  TriangleMesh b = (TriangleMesh)new AABB(new Vec3D(), printerSizeInMM).toMesh(); 
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
        .setEdgeThickness(spiralThickness, false);

  profiles = new ArrayList<LineStrip2D>();
  outwardVecs = new ArrayList<Vec3D>();
  tanVecs = new ArrayList<Vec3D>();
  profilesOnCurve = new ArrayList<LineStrip3D2>();  

  noLoop(); //turn off loop until needed
}



void createSpiral(boolean forPrint)
{
  // set number of points
  spiral.setTurns(turns, false)
    .setRadius(spiralRadius, false)
      .setDistanceBetweenTurns(distanceBetweenSpirals, false)
        .setEdgeThickness(spiralThickness, false)
          .setNumPoints(rmsAmplitudes.length);

  println("total spiral points:" + spiral.getNumPoints() + " / " + rmsAmplitudes.length);

  // calculate tangents and outwards facing vectors
  // take the next point and subtract from previous point to get inwards pointing vector

  int numPoints = spiral.getNumPoints(); 

  println("DEBUG:: setting up tangent and outwards vectors");

  outwardVecs.clear(); 
  tanVecs.clear();

  for (int i=0; i < numPoints; i++)
  {
    outwardVecs.add(new Vec3D(0, 0, 0));
    tanVecs.add(new Vec3D(0, 0, 0));
  }

  for (int i=1; i < numPoints-1; i++)
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

    outVec.set(v0.add(v1));
    outVec.normalize();
  }
  println("DEBUG:: tanvec3");

  // deal with edge cases - 1st and last
  tanVecs.get(0).set(tanVecs.get(1));
  tanVecs.get(numPoints-1).set(tanVecs.get(numPoints-2));

  outwardVecs.get(0).set(outwardVecs.get(1));
  outwardVecs.get(numPoints-1).set(outwardVecs.get(numPoints-2));

  //
  // generate the profiles for each segment of the tube, based on RMS volume 
  // 
  profiles.clear();
  profiles.ensureCapacity(numPoints);

  profilesOnCurve.clear();
  profilesOnCurve.ensureCapacity(numPoints);


  for (int i=0; i<numPoints; i++)
  {
    Spline2D spline = new Spline2D();
    float minRMS = (rmsAmplitudes[i] + minThickness);
    float thick = spiral.getEdgeThickness();
    float spiralRadius = spiral.getRadius();
    float profileLength =  minThickness*thick + rmsAmplitudes[i]*spikiness;
    
    

    spline.add(0, 0);
    //spline.add(thick*0.1*minRMS, profileLength*0.15);    
    spline.add(thick*0.3*minRMS, profileLength*0.1);
    spline.add(thick*minRMS, profileLength);
    spline.add(thick*0.4*minRMS, profileLength*0.9);
    //spline.add(thick*0.15*minRMS, profileLength*0.75);
    spline.add(0, 0); // close spline

    LineStrip2D strip = spline.toLineStrip2D(diameterQuality);

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
  if (mesh == null) mesh = new TriangleMesh();
  else
    mesh.clear();


  // start recording shape
  PShape retained = createShape();
  retained.beginShape(TRIANGLES);
  //retained.beginShape();  
  retained.enableStyle();
  retained.strokeWeight(0.5);
  retained.stroke(220);
  //retained.noFill();
  

  int numProfilePoints = (profiles.get(0).getVertices()).size(); // all are the same size

  for (int i=0; i < numPoints-1; i++)
  {
    LineStrip2D profilePointsC = profiles.get(i);
    LineStrip2D profilePointsN = profiles.get(i+1);
    LineStrip3D2 profileOnCurveC; // current profile points on the curve

    if (i == 0)
    {
      // calculate these profiles and add
      profileOnCurveC = new LineStrip3D2(numProfilePoints); // current profile
      profilesOnCurve.add(profileOnCurveC);      
    } 
    else
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

    Vec3D ppOnCurve1, ppOnCurve2;
    Vec3D ppOnCurve3, ppOnCurve4;  // see diagram... goes 1-2 on curve 1 (clockwise) then 3-4 on curve 2 (clockwise)

    // now loop through and calculate current & next profile points
    // first profile point is same as last, so we don't have to worry about stitching them together
    for (int j=0; j < numProfilePoints-1; j++)
    {
      int nextPointIndex = (j+1);
      Vec2D ppC = profilePointsC.get(j);
      Vec2D ppnC = profilePointsC.get(nextPointIndex);

      Vec2D ppN = profilePointsN.get(j);
      Vec2D ppnN = profilePointsN.get(nextPointIndex);

      if (j > 0)
      {
        //we've already calcuated this
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

      retained.fill(random(100, 255), random(50, 255), random(0, 80));

      // 1-3-2
    
      retained.vertex( ppOnCurve1.x(), ppOnCurve1.y(), ppOnCurve1.z());
      retained.vertex( ppOnCurve3.x(), ppOnCurve3.y(), ppOnCurve3.z());
      retained.vertex( ppOnCurve2.x(), ppOnCurve2.y(), ppOnCurve2.z());

      mesh.addFace( ppOnCurve1, ppOnCurve3, ppOnCurve2 );

      retained.fill(random(100, 255), random(50, 255), random(0, 80));
      // 2-3-4
      
      retained.vertex( ppOnCurve2.x(), ppOnCurve2.y(), ppOnCurve2.z());
      retained.vertex( ppOnCurve3.x(), ppOnCurve3.y(), ppOnCurve3.z());
      retained.vertex( ppOnCurve4.x(), ppOnCurve4.y(), ppOnCurve4.z());

      mesh.addFace( ppOnCurve2, ppOnCurve3, ppOnCurve4 );
      
      
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

    }
  }


  // sanity check - profiles on curve should be same length as 2D profiles
  if (profilesOnCurve.size() != profiles.size() ||  profilesOnCurve.size() != numPoints )
  {
    println( "ERROR: profiles have different sizes:: [cp] " + profilesOnCurve.size() + ", [pp] " + profiles.size() + ", [np] " + numPoints);
  }


  //
  // add end cap
  //

  LineStrip3D2 endProfilePoints = profilesOnCurve.get(numPoints-1);

  // find average (center) point of cap
  Vec3D centerPoint = new Vec3D(0, 0, 0);
  for (Vec3D p : endProfilePoints)
    centerPoint.addSelf(p);
  centerPoint.scaleSelf(1.0/numProfilePoints);

  // profile points go clockwise, so we go backwards
  int j=numProfilePoints;

  while (j>1)
  {
    --j;
    Vec3D v0 = endProfilePoints.get(j);
    Vec3D v1 = endProfilePoints.get(j-1);

    mesh.addFace( v0, v1, centerPoint);

    retained.vertex( v0.x(), v0.y(), v0.z());
    retained.vertex( v1.x(), v1.y(), v1.z());
    retained.vertex( centerPoint.x(), centerPoint.y(), centerPoint.z());
  }
  /////// finished with end cap


  //
  // add start cap
  //

  endProfilePoints = profilesOnCurve.get(0);

  // find average (center) point of cap
  centerPoint.set(0, 0, 0);
  for (Vec3D p : endProfilePoints)
    centerPoint.addSelf(p);
  centerPoint.scaleSelf(1.0/numProfilePoints);

  // profile points go clockwise, but this is the start, so we go clockwise
  j=0;
  while (j < numProfilePoints-1)
  {
    Vec3D v0 = endProfilePoints.get(j);
    Vec3D v1 = endProfilePoints.get(j+1);

    mesh.addFace( v0, v1, centerPoint);

    retained.vertex( v0.x(), v0.y(), v0.z());
    retained.vertex( v1.x(), v1.y(), v1.z());
    retained.vertex( centerPoint.x(), centerPoint.y(), centerPoint.z());
    ++j;
  }

  retained.endShape();
  // update current 3D PShape
  spiralShape = retained;

  loop(); // start drawing
}



void draw()
{  
  background(0);
  fill(200, 0, 200, 100);
  stroke(255);

  //lights();
  //camera(width - 2*mouseX, height - 2*mouseY, 400, 0, 0, 0, 0, 1, 0);
  // turn on backfce culling to make sure it looks as it will come out...

  // draw dektop 3D printer shape for reference
  shape(printerBoundingBox);

  lights();
  // DRAW PSHAPE STUFF
  PGL pgl = beginPGL();
  pgl.enable(PGL.CULL_FACE);
  // make sure we are culling the right faces - STL files need anti-clockwise winding orders for triangles
  pgl.frontFace(PGL.CCW);
  pgl.cullFace(PGL.BACK);

  //pgl.disable(PGL.CULL_FACE);

  if (!drawProfiles)
  {
    if (spiralShape != null)
      shape(spiralShape);
  }

  endPGL(); // restores the GL defaults for Processing

  noLights();


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



    cam.beginHUD();

    textSize(fontsize);
    textAlign(LEFT, BOTTOM);

    fill(255);
    text("file: " + wavFileName, startX, startY );
    startY += fontsize;
    text("turns: " + turns, startX, startY );
    startY += fontsize;
    text("distanceBetweenSpirals: " + distanceBetweenSpirals, startX, startY );
    startY += fontsize;
    text("spiralThickness: " + spiralThickness, startX, startY );
    startY += fontsize;
    text("spikiness: " + spikiness, startX, startY );
    startY += fontsize;
    text("wavSampleRate: " + wavSampleRate, startX, startY );
    startY += fontsize;
    text("RMSSize: " + RMSSize, startX, startY );

    cam.endHUD();
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
  } else if (key == 'F')
  {
    // get first part of filename, ignore extension
    String[] wavname = split(wavFileName, '.');

    String fileName = wavname[0] +
      "--" + nf(hour(), 2) + "." + nf(minute(), 2) + "." + nf(second(), 2) + 
      "-" +
      turns +"-" +
      distanceBetweenSpirals + "-" +
      spiralThickness + "-" +
      spiralRadius + "-" +
      spikiness + "-" +
      RMSSize + "-" +
      wavSampleRate +
      ".png" ;
    saveFrame(fileName);
  } else if (key == 's')
  {

    // get first part of filename, ignore extension
    String[] wavname = split(wavFileName, '.');

    String fileName = wavname[0] +
      turns +"-" +
      distanceBetweenSpirals + "-" +
      spiralThickness + "-" +
      spiralRadius + "-" +
      spikiness + "-" +
      wavSampleRate +
      ".stl" ;
    mesh.saveAsSTL(fileName );

    println("saved: " + fileName);
  } else if (key==' ')
  { 
    if (!fileChosen) 
    {
      fileChosen = true;
      background(0, 200, 0);
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
    float RMSSum = 0;

    while (RMSIndex < RMSSize)
    {
      // convert data to float
      float data = (float)soundAmplitudes[currentIndex];

      // debug
      /*if (rmsArrayIndex == rmsAmplitudes.length-1)
       {
       // println("data[" + currentIndex + "]=" + data);
       }*/
      RMSSum += data*data; // add square of data to sum
      currentIndex++; 
      RMSIndex++;
    }

    // find average value - could also scale logarithmically
    float RMSAve = RMSSum / float(RMSSize);
    ampMin = min(ampMin, RMSAve);
    ampMax = max(ampMax, RMSAve);

    rmsAmplitudes[rmsArrayIndex++] = RMSAve;

    //println("stored " + (rmsArrayIndex-1) + ":" + RMSAve);
  }
  createSpiral(true);
}

