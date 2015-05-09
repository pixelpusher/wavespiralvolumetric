// 3d sound spiral generator
//  by evan raskob evanraskob@gmail.com
// wave code uses code from http://code.google.com/p/musicg/
//
//  for 206: Tangible Media 2014 (BA Hons Design Interactions)
//
// Draw a base spiral and offset it by the sound volume (RMS)
//
// TODO
// - need flat base for stand and for printing properly...
// - gaps in between spiral sections don't really work on Makerbot, too
// small to pick out material and mushed together with other support material
// - how about filling it to the max spikiness in between shapes, so it is recessed rather 
// than filled
// - or inner removal of material rather than exterior extrusion
// -  base RMS on sample seconds and points per 360 (e.g. turns and resolution) 
// and sample rate rather than arbitrary numbers...
//

import java.io.*;
import toxi.geom.*;
import toxi.geom.mesh.*;
import toxi.math.*;
import toxi.volume.*;
import toxi.math.waves.*;
import toxi.processing.*;
import processing.opengl.*;
import peasy.*;
import tubesP5.library.CurveFactory;
import tubesP5.library.LineStrip3D;
import tubesP5.library.ParallelTransportFrame;
import tubesP5.library.Tube;
import toxi.geom.Vec3D;
import toxi.processing.ToxiclibsSupport;



boolean fileChosen = false;
PrintWriter output, outputRMS;
float[] soundAmplitudes;
float[] rmsAmplitudes;
//ToxiclibsSupport gfx;
PShape spiralShape = null;
TriangleMesh mesh = null;


String wavFileName = "";
int wavSampleRate; // sample rate of Wave file
int diameterQuality = 10;

//metal 3 sec - 6,0,60,90,120,0.125,44100*1*1.1/500.0

float turns = 6;
float distanceBetweenSpirals = 160;
float spiralThickness = 20;  
float spiralRadius = 160;
//float spikiness = 160*3;
float spikiness = 2;
float minThickness = 0.125; // percentage, 0 - 1
//int RMSSize = (int)(48000*4.873*0.00125); // 1/500th of a second  CHANGEME!!!!!  Remember that 44100 is 1 sec
// metal
//int RMSSize = (int)(44100*1*1.1/500.0); // 1/500th of a second  CHANGEME!!!!!  Remember that 44100 is 1 sec
// metal 22
int RMSSize = (int)(44100*2/turns / 100); // total length is 24.472 which encompasses 22 whole strides
// with 100 rms divisions per 360 degrees (e.g. per turn)


PeasyCam cam;

Vec3D spiralCoords; 

OffsetSpiral3D spiral;

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

  spiral = new OffsetSpiral3D();

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

  float[] amps = new float[ rmsAmplitudes.length ];
  for (int i=0; i<amps.length; i++)
  {
    amps[i] = rmsAmplitudes[i]*spikiness;
  }


  spiral.scaleEach(amps);

  // get PShape to visualise
  //spiralShape = spiralToShape(spiral);

  makeTube(spiral);

  loop(); // start drawing
}




int zDist = 0;

void draw()
{  
  background(0);
  fill(200, 0, 200, 100);
  stroke(255);

  lights();
  //camera(width - 2*mouseX, height - 2*mouseY, 400, 0, 0, 0, 0, 1, 0);
  // turn on backfce culling to make sure it looks as it will come out...


  // DRAW PSHAPE STUFF
  PGL pgl = beginPGL();
  pgl.enable(PGL.CULL_FACE);
  pgl.cullFace(PGL.FRONT);

  if (spiralShape != null)
    shape(spiralShape);

  endPGL(); // restores the GL defaults for Processing
}


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
  }
    else if (key == 's')
  {
    createSpiral(true);
    String fileName = wavFileName + "-" +
      turns +"-" +
      distanceBetweenSpirals + "-" +
      spiralThickness + "-" +
      spiralRadius + "-" +
      spikiness + "-" +
      wavSampleRate +
      ".stl" ;
    mesh.saveAsSTL(fileName );

    println("saved: " + fileName);
  } 
  else if (key==' ') 
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


PShape meshToRetained(Mesh3D mesh, boolean smth) {        
  PShape retained = createShape();
  // println("triangles1");
  retained.enableStyle();
  retained.beginShape(TRIANGLE_STRIP);
  retained.fill(200, 0, 200);
  //retained.stroke(0);
  retained.noStroke();
  retained.ambient(50);
  retained.emissive(10);
  retained.specular(50);

  // println("triangles2");
  if (smth) {
    mesh.computeVertexNormals();

    for (Face f : mesh.getFaces ()) {
      retained.normal(f.a.normal.x, f.a.normal.y, f.a.normal.z);
      retained.vertex(f.a.x, f.a.y, f.a.z);
      retained.normal(f.b.normal.x, f.b.normal.y, f.b.normal.z);
      retained.vertex(f.b.x, f.b.y, f.b.z);
      retained.normal(f.c.normal.x, f.c.normal.y, f.c.normal.z);
      retained.vertex(f.c.x, f.c.y, f.c.z);
    }
  } else {
    int i=0;
    for (Face f : mesh.getFaces ()) {
      // println("triangles"+ i++);
      retained.normal(f.normal.x, f.normal.y, f.normal.z);
      retained.vertex(f.a.x, f.a.y, f.a.z);
      retained.vertex(f.b.x, f.b.y, f.b.z);
      retained.vertex(f.c.x, f.c.y, f.c.z);
    }
  }
  retained.endShape();
  return retained;
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


void makeTube(Spiral3D spiral)
{
  ReadonlyVec3D[] spiralPoints = spiral.getPoints();

  float radius = spiralThickness;
  int steps = spiralPoints.length;

  LineStrip3D curve = new LineStrip3D();

  for (ReadonlyVec3D v : spiralPoints)
  {
    curve.add(v);
  }

  ParallelTransportFrame ptf = new ParallelTransportFrame(curve.getVertices());
  Tube tube = new Tube(ptf, (int)spiralThickness, diameterQuality);
  mesh = tube;

  spiralShape = meshToRetained(mesh, false);
}

