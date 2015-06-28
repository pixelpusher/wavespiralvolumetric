// 3d sound spiral generator
//  by evan raskob evanraskob@gmail.com
// wave code uses code from http://code.google.com/p/musicg/
//
// Draw a base spiral and offset it by the sound volume (RMS)
//
// TODO
// - end and start caps
// - bounding box check - model size display too!! How bug are these??
// - auto camera zoom on load?
// - how about a REPL for commands instead of stupid key presses
// - need flat base for stand and for printing properly...
// - gaps in between spiral sections don't really work on Makerbot, too
// small to pick out material and mushed together with other support material
// - how about filling it to the max spikiness in between shapes, so it is recessed rather 
// than filled?
// - or inner removal of material rather than exterior extrusion


import java.io.*;
import toxi.geom.*;
import toxi.geom.mesh.*;
import toxi.math.*;
import toxi.volume.*;
import toxi.math.waves.*;
//import toxi.processing.*;
import processing.opengl.*;
import controlP5.*;
import peasy.*;
<<<<<<< HEAD
import tubesP5.library.CurveFactory;
import tubesP5.library.LineStrip3D;
import tubesP5.library.SpiralLineStrip3D;
import tubesP5.library.ParallelTransportFrame;
import tubesP5.library.Tube;

import toxi.geom.Vec3D;
//import toxi.processing.ToxiclibsSupport;
=======


import wblut.math.*;
import wblut.processing.*;
import wblut.core.*;
import wblut.hemesh.*;
import wblut.geom.*;
import wblut.hemesh.HET_Export;
>>>>>>> master



boolean fileChosen = false;
PrintWriter output, outputRMS;
float[] soundAmplitudes;
float[] rmsAmplitudes;

PShape spiralShape = null;
<<<<<<< HEAD
TriangleMesh mesh = null;

ArrayList<LineStrip2D> profiles;

boolean showFrames = false;
=======
>>>>>>> master

TriangleMesh mesh;
String wavFileName = "";
int wavSampleRate; // sample rate of Wave file
<<<<<<< HEAD
int diameterQuality = 20;
=======
>>>>>>> master

//metal 3 sec - 6,0,60,90,120,0.125,44100*1*1.1/500.0

float turns = 6;
float distanceBetweenSpirals = 60/10;
float spiralThickness = 50/10;
float spiralRadius = 40/10;
//float spikiness = 160*3;
float spikiness = 720/10;
float minThickness = 0.05; // percentage, 0 - 1
//int RMSSize = (int)(48000*4.873*0.00125); // 1/500th of a second  CHANGEME!!!!!  Remember that 44100 is 1 sec
// metal
int RMSSize = (int)(44100.0*23.0/(6.0*40.0)); // 1/500th of a second  CHANGEME!!!!!  Remember that 44100 is 1 sec
// metal 22
//int RMSSize = (int)(44100*2/turns / 100); // total length is 24.472 which encompasses 22 whole strides
// with 100 rms divisions per 360 degrees (e.g. per turn)

PeasyCam cam;

Vec3D spiralCoords; 

SpiralLineStrip3D spiral;
ParallelTransportFrame ptf;


WB_Render render;
WB_BSpline C;
WB_Point[] points;
HE_Mesh hemesh;



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
  size(1024, 768, P3D);
 
  cam = new PeasyCam(this, width);
  cam.setMinimumDistance(50);
  cam.setMaximumDistance(width*3);
 
  background(0);

  fill(200);

  text("hit space", 10, 20);

  spiral = new SpiralLineStrip3D();

  spiral.setTurns(turns, false)
    .setRadius(spiralRadius, false)
      .setDistanceBetweenTurns(distanceBetweenSpirals, false)
        .setEdgeThickness(spiralThickness, false);

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
<<<<<<< HEAD


  println("total spiral points:" + spiral.getNumPoints() + " / " + rmsAmplitudes.length);

  profiles = new ArrayList<LineStrip2D>(rmsAmplitudes.length);
  // TODO - generate circular profiles with one edge pushed slightly 
  // outwards, as splines...


  for (int i=0, j=rmsAmplitudes.length; i<j; i++)
  {
    //Polygon2D based on amplitude...
    float triSize =  rmsAmplitudes[i]*spikiness;

    //Polygon2D tri = (new Triangle2D(new Vec2D(-triSize, 0), new Vec2D(0, 0), new Vec2D(-triSize/2, -triSize/2)))
    //  .toPolygon2D();

    Spline2D spline = new Spline2D();

    float angle = 0;
    float inc = TWO_PI/diameterQuality;
    float r = triSize + minThickness * spiralRadius;

//    for (int k=0; k < diameterQuality; k++)
//    {
//        float x = r*cos(angle)*sin(angle/2);
//        float y = r*sin(angle)*sin(angle/2);
//        
//        spline.add(x,y);
//        
//        angle += inc;
//    } 

    spline.add(r,0);
    spline.add(r/2,r/4);
    
    spline.add(0,0);
    spline.add(r/2,-r/4);
    spline.add(r,0);
    
    LineStrip2D strip = spline.toLineStrip2D(diameterQuality);
    
    // TODO - add Simplify method to strip
     
    profiles.add(strip);
   
   
   
  }

=======
  
  float[] amps = new float[ rmsAmplitudes.length ];
  for (int i=0; i<amps.length; i++)
  {
    amps[i] = rmsAmplitudes[i]*spikiness;
  }
  
  
  spiral.scaleEach(amps);
  
>>>>>>> master
  // get PShape to visualise
  //spiralShape = spiralToShape(spiral);
  
  makeTube(spiral);
  
  loop(); // start drawing
}




void drawFrames() {    
  int tube_size = ptf.getVertices().size();
  for (int i=0; i<tube_size-1; i++) {

    stroke(255, 0, 0, 100);      
    drawVectorOnPoint(ptf.vertices.get(i), ptf.getTangent(i));
    stroke(0, 255, 0, 100);
    drawVectorOnPoint(ptf.vertices.get(i), ptf.getBinormal(i));
    stroke(0, 0, 255, 100);
    drawVectorOnPoint(ptf.vertices.get(i), ptf.getNormal(i));
  }
}

void drawVectorOnPoint(Vec3D pos, Vec3D vector) {
  float k = 10;
  beginShape(LINES);
  vertex(pos.x, pos.y, pos.z);
  vertex(pos.x + vector.x*k, pos.y + vector.y*k, pos.z + vector.z*k);
  endShape();
}


void draw()
{  
  background(0);
  fill(200, 0, 200, 100);
  stroke(255);

//  lights();
  //camera(width - 2*mouseX, height - 2*mouseY, 400, 0, 0, 0, 0, 1, 0);
  // turn on backfce culling to make sure it looks as it will come out...
  
  // DRAW HEMESH STUFF 
  if (render != null)
  {
    render.drawEdges(hemesh);
    noStroke();
    render.drawFaces(hemesh);
  }

  // DRAW PSHAPE STUFF
  PGL pgl = beginPGL();
  pgl.enable(PGL.CULL_FACE);
  pgl.cullFace(PGL.FRONT);

  //pgl.disable(PGL.CULL_FACE);

  if (spiralShape != null)
    shape(spiralShape);

  endPGL(); // restores the GL defaults for Processing
<<<<<<< HEAD

  if (showFrames && ptf != null)
    drawFrames();
  
  
  if (true)
  {  
    // draw info overlay
    
    int fontsize = 18;
    int startX = fontsize;
    int startY = 2*fontsize;
    
    hint(ENABLE_NATIVE_FONTS);
    
    
    hint(DISABLE_DEPTH_TEST);
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
=======
  
}
>>>>>>> master


void keyReleased()
{
  if (key == '+')
  {
    noLoop();
    RMSSize *=1.1;
    println("RMSSize:" + RMSSize);
    computeRMS();
    loop();
  } else if (key == '-')
  {
    noLoop();
    RMSSize /=1.1;
    computeRMS();
    println("RMSSize:" + RMSSize);
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
  } 
  else if (key == 'h')
  {
    noLoop();
    spiralThickness/=1.1;
    computeRMS();
   println("spiralThickness:" + spiralThickness);
    loop();
  }
  else if (key == 'H')
  {
    noLoop();
    spiralThickness*=1.1;
    computeRMS();
   println("spiralThickness:" + spiralThickness);
    loop();
  } 
  else if (key == 'm')
  {
    noLoop();
    minThickness/=1.1;
    computeRMS();
    println("minThickness:" + minThickness);
    loop();
  }
  else if (key == 'M')
  {
    noLoop();
    minThickness*=1.1;
    computeRMS();
    println("minThickness:" + minThickness);
    loop();
  } 
  else if (key == 'r')
  {
    noLoop();
    spiralRadius /= 1.1;
    computeRMS();
    println("spiralRadius:" + spiralRadius);
    loop();
  }
  else if (key == 'R')
  {
    noLoop();
    spiralRadius *= 1.1;
    computeRMS();
    println("spiralRadius:" + spiralRadius);
    loop();
  }
<<<<<<< HEAD
  else if (key == 'f')
  {
    showFrames = !showFrames;
  }
  else if (key == 'F')
  {
    String fileName = wavFileName + "-" +
      turns +"-" +
      distanceBetweenSpirals + "-" +
      spiralThickness + "-" +
      spiralRadius + "-" +
      spikiness + "-" +
      RMSSize + "-" +
      wavSampleRate +
      "--" + hour() + "." + minute() + "." + second() +
      ".png" ;
    saveFrame(fileName);
  }
=======
>>>>>>> master
  else if (key == 's')
  {
  
    createSpiral(true);
    
    String fileName = wavFileName + "-" +
      turns +"-" +
      distanceBetweenSpirals + "-" +
      spiralThickness + "-" +
      spiralRadius + "-" +
      spikiness + "-" +
      wavSampleRate;
    
    if (mesh != null)  
      mesh.saveAsSTL(fileName + ".stl" );
    else if (hemesh != null) HET_Export.saveToOBJ(hemesh, ".", fileName+".obj");

    println("saved: " + fileName);
  } else if (key==' ') 
    if (!fileChosen) 
    {
      fileChosen = true;
      background(0, 200, 0);
      selectInput("Select a file to process:", "fileSelected");
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
  // println("RMS Size: " + RMSSize);

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
      if (rmsArrayIndex == rmsAmplitudes.length-1)
      {
        // println("data[" + currentIndex + "]=" + data);
      }
      RMSSum += data*data; // add square of data to sum
      currentIndex++; 
      RMSIndex++;
    }

    // find average value - could also scale logarithmically
    float RMSAve = RMSSum / float(RMSSize);
    ampMin = min(ampMin, RMSAve);
    ampMax = max(ampMax, RMSAve);

    rmsAmplitudes[rmsArrayIndex++] = RMSAve;
    
    // println("stored " + (rmsArrayIndex-1) + ":" + RMSAve);
  }
  createSpiral(true);
}


final PShape spiralToShape(Spiral3D spiral) {        
  PShape retained = createShape();

  retained.enableStyle();
  retained.beginShape();
  retained.noFill();
  retained.stroke(220);
  retained.strokeWeight(2);

  ReadonlyVec3D[] points = spiral.getPoints();

  for (ReadonlyVec3D v : points) {
    retained.vertex(v.x(), v.y(), v.z());
  }

  retained.endShape();
  return retained;
}


void makeTube(SpiralLineStrip3D spiral)
{
<<<<<<< HEAD
  ptf = new ParallelTransportFrame(spiral.getVertices());
  Tube tube = new Tube(ptf, 1, diameterQuality);
=======
  // Several WB_Curve classes are in development. HEC_SweepTube provides
  // a way of generating meshes from them.

  ReadonlyVec3D[] spiralPoints = spiral.getPoints();
>>>>>>> master

  tube.splineQuality = 10; // change this!


<<<<<<< HEAD
  try {
    tube.compute(profiles);
  }
  catch (Exception e)
  {
    println("Exception in MakeTube: " + e.getMessage());
    e.printStackTrace();
  }

  mesh = tube;

  spiralShape = meshToRetained(mesh, false);
=======
  //Generate a BSpline
  points=new WB_Point[spiralPoints.length];
  
  for (int i=0; i<points.length; i++)
  {
    ReadonlyVec3D v = spiralPoints[i];
    points[i] = new WB_Point(v.x(), v.y(), v.z());
  }
  C = new WB_BSpline(points, 4);

  HEC_SweepTube creator = new HEC_SweepTube();
  creator.setCurve(C);//curve should be a WB_BSpline
  creator.setRadius(radius);
  creator.setSteps(steps);
  creator.setFacets(8);
  creator.setCap(true, true); // Cap start, cap end

  hemesh=new HE_Mesh(creator); 
  HET_Diagnosis.validate(hemesh);
  render=new WB_Render(this);
>>>>>>> master
}
