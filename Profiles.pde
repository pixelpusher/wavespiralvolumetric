/**
 * Generator function for swept profiles.
 *
 * Copyright Evan Raskob, 2018.
 * evanraskob@gmail.com
 */


// non-symmetrical, B-spline leaf-shaped profile
LineStrip2D makeProfile1()
{
  //profileName = "B-spline-1";

  LineStrip2D strip = new LineStrip2D(); //container for final list of points
  Spline2D spline = new Spline2D(); //B-spline implementation 

  float x = xScale*adjust; // screen-adjusted horizontal coordinate
  float z = zScale*adjust; // screen-adjusted vertical coordinate

  int tightness = 10; // tightness for B-spline curve generation

  // pointy on bottom
  spline.add(0, 0);    
  spline.add(x*0.66, z*0.4); //underhang
  spline.add(x, z);
  spline.add(x*0.3, z*0.66); // overhang
  spline.add(0, 0); // close spline
  strip = spline.toLineStrip2D(tightness);

  return strip;
}


// for spiral 008
LineStrip2D makeProfile2()
{
  // rounded teardrop shape, with too-small tail (this profile has an error)
  //profileName = "Param ellipse 008";


  // Maximum angle for parametric sinusoidal shape envelope - needs to be 2PI so we get an elliptical, closed shape (only 
  // for elliptical shapes). Minimum angle is 0, of course.
  double maxAngle = Math.PI*2d; 

  LineStrip2D strip = new LineStrip2D(); //container for final list of points

  float x = xScale*adjust; // screen-adjusted horizontal coordinate
  float z = zScale*adjust; // screen-adjusted vertical coordinate


  // pointy on top v2    
  double inc = Math.PI/24d;
  double offset = Math.PI/2d;

  for (double angle=0; angle<maxAngle; angle+=inc)
  {
    double envelope = Math.abs(angle/(maxAngle/2) - 1);
    //double envelope = Math.sin(Math.abs(angle/(maxAngle/2) - 1)*Math.PI*0.2d); // little pointy on top

    envelope -= 1d;
    envelope = envelope*envelope; // smoothing
    envelope = envelope*envelope; //quadratic/rounder

    double xx = (1d-envelope)*x;

    strip.add((float)(0.5d*xx*(Math.cos(angle+offset)+1d)), 
      (float)(0.5d*xx*(Math.sin(angle+offset)+1d)));
  }

  return strip;
}



// for 005 & 006
LineStrip2D makeProfile3()
{
  // like a symmetrical leaf petal
  //profileName = "Param ellipse 005-6";

  // Maximum angle for parametric sinusoidal shape envelope - needs to be 2PI so we get an elliptical, closed shape (only 
  // for elliptical shapes). Minimum angle is 0, of course.
  double maxAngle = Math.PI*2d; 

  LineStrip2D strip = new LineStrip2D(); //container for final list of points

  float x = xScale*adjust; // screen-adjusted horizontal coordinate
  float z = zScale*adjust; // screen-adjusted vertical coordinate

  double inc = Math.PI/24d; // the resolution of the curve (smaller = more detail)
  double offset = Math.PI/8d; // smaller values ( < PI/2) curl shape CCW, larger values in CW direction
  // note: helix B uses offset of PI/3
  double curviness = 1/5d; // how curvy/paisley-like the final shape is. 0 is flattened, 0.5 is circular
  // and is max before outline splits

  float x0=0, z0=0;

  // pointy on top v2 
  for (double angle=0; angle<maxAngle; angle+=inc)
  {
    double envelope = Math.abs(angle/(maxAngle/2) - 1); // -1 to 1
    envelope = Math.sin(envelope*Math.PI*curviness); // little pointy on top

    double xx = envelope*x;  
    double curvinessMax = Math.sin(Math.PI*curviness);

    float newz = (float)(0.5d*xx/curvinessMax*(Math.cos(angle+offset)+1d));
    float newx = (float)(0.5d*xx/curvinessMax*(Math.sin(angle+offset)+1d)); 
    strip.add(newx, newz);

    // save first points to connect later
    if (angle == 0)
    {
      x0 = newx;
      z0 = newz;
    }
    strip.add(newx, newz);
  }
  strip.add(x0, z0);

  return strip;
}


// like 005 but rounder
LineStrip2D makeProfile6()
{
  // like a symmetrical leaf petal
  // profileName = "Param ellipse 005 round";

  // Maximum angle for parametric sinusoidal shape envelope - needs to be 2PI so we get an elliptical, closed shape (only 
  // for elliptical shapes). Minimum angle is 0, of course.
  double maxAngle = Math.PI*2d; 

  LineStrip2D strip = new LineStrip2D(); //container for final list of points

  float x = xScale*adjust; // screen-adjusted horizontal coordinate
  float z = zScale*adjust; // screen-adjusted vertical coordinate

  double inc = Math.PI/24d; // the resolution of the curve (smaller = more detail)
  double offset = Math.PI/8d; // smaller values ( < PI/2) curl shape CCW, larger values in CW direction
  // note: helix B uses offset of PI/3
  double curviness = 0.5d; // how curvy/paisley-like the final shape is. 0 is circular, 0.5 is max before outline splits

  float x0=0, z0=0;

  // pointy on top v2 
  for (double angle=0; angle<maxAngle; angle+=inc)
  {
    double envelope = Math.abs(angle/(maxAngle/2) - 1); // -1 to 1
    envelope = Math.sin(envelope*Math.PI*curviness); // little pointy on top

    double xx = envelope*x;
    double curvinessMax = Math.sin(Math.PI*curviness);

    float newx = (float)(0.5d*xx/curvinessMax*(Math.cos(angle+offset)+1d));
    float newz = (float)(0.5d*xx/curvinessMax*(Math.sin(angle+offset)+1d)); 
    strip.add(newx, newz);

    // save first points to connect later
    if (angle == 0)
    {
      x0 = newx;
      z0 = newz;
    }
    strip.add(newx, newz);
  }
  strip.add(x0, z0);

  return strip;
}


LineStrip2D makeProfile4()
{
  // ghost-shaped (rounded, angled teardrop)
  //profileName = "Param cubic ellipse 012";

  // Maximum angle for parametric sinusoidal shape envelope - needs to be 2PI so we get an elliptical, closed shape (only 
  // for elliptical shapes). Minimum angle is 0, of course.
  double maxAngle = Math.PI*2d; 

  LineStrip2D strip = new LineStrip2D(); //container for final list of points

  float x = xScale*adjust; // screen-adjusted horizontal coordinate
  float z = zScale*adjust; // screen-adjusted vertical coordinate

  double inc = Math.PI/48d; // the resolution of the curve (smaller = more detail)
  double offset = Math.PI/8d; // smaller means curlier on the bottom, PI/2 means symmetrical
  double curviness = 0.4d; // how curvy/paisley-like the final shape is. 0 is circular, 0.5 is max before outline splits

  float x0=0, z0=0;

  double centerOffX = 2.8; // Shape central offset in horizonal direction
  double centerOffZ = 2.2; // Shape central offset in vertical direction

  for (double angle=0; angle<=maxAngle; angle+=inc)
  {    
    double envelope = Math.sin(Math.abs(angle/(maxAngle/2) - 1)*Math.PI*curviness); // this will modify the elliptical profile shape
    double envelopeMin = Math.sin(Math.abs(Math.PI/(maxAngle/2) - 1d)*Math.PI*curviness); //  minimum value, for offsetting curve to 0
    double xBase = 0d;

    //envelope = 0.75d + 0.25d*Math.cos(8*Math.PI * envelope);

    envelope -= 1d; // 0 to -1 to 0
    envelope = envelope*envelope*Math.abs(envelope); // smoothing, petal-like
    envelope = 2d-envelope; // 0-1 range

    envelopeMin -= 1d;
    envelopeMin = envelopeMin*envelopeMin*Math.abs(envelopeMin); // smoothing, petal-like
    envelopeMin = 2d-envelopeMin; // 0-1 range

    double xx = envelope*x + envelope*xBase;
    double xxMin = envelopeMin*x + envelopeMin*xBase;

    float newz = (float)(0.185d*xx*(Math.sin(angle+offset)+centerOffX)-xxMin*(Math.sin(Math.PI+offset)+centerOffX)*0.185d);
    float newx = (float)(0.185d*xx*(Math.cos(angle+offset)+centerOffZ)-xxMin*(Math.cos(Math.PI+offset)+centerOffZ)*0.185d);

    // save first points to connect later
    if (angle == 0)
    {
      x0 = newx;
      z0 = newz;
    }
    strip.add(newx, newz);
  }
  strip.add(x0, z0);

  return strip;
}



LineStrip2D makeProfile5()
{
  // looks a bit like a cat paw - sinusoidally-modulated ellipse
  // profileName = "Param cubic ellipse 011";

  // Maximum angle for parametric sinusoidal shape envelope - needs to be 2PI so we get an elliptical, closed shape (only 
  // for elliptical shapes). Minimum angle is 0, of course.
  double maxAngle = Math.PI*2d; 

  LineStrip2D strip = new LineStrip2D(); //container for final list of points

  float x = xScale*adjust; // screen-adjusted horizontal coordinate
  float z = zScale*adjust; // screen-adjusted vertical coordinate

  double inc = Math.PI/48d; // the resolution of the curve (smaller = more detail)
  double envelopeMin = 0.75d; // values greater than 0.65 are more circular, less than that and outline sections cross one another

  float x0=0, z0=0; // initial points

  double centerOffX = 1.15d; // Shape central offset in horizonal direction
  double centerOffZ = 2.8d;  // Shape central offset in vertical direction

  for (double angle=0; angle<=maxAngle; angle+=inc)
  {
    double envelope = Math.abs(angle/(maxAngle/2) - 1); // this will modify the elliptical profile shape
    double xBase = 0d;

    envelope = envelopeMin + (1-envelopeMin)*Math.cos(8*Math.PI * envelope);  
    envelope -= 1d; // 0 to -1 to 0
    envelope = envelope*envelope*Math.abs(envelope); // smoothing, petal-like

    double xx = (2d-envelope)*x + envelope*xBase;

    float newx = (float)(0.25d*xx*(Math.sin(angle)+centerOffX))-xScale*3.6;
    float newz = (float)(0.25d*xx*(Math.cos(angle)+centerOffZ))-xScale*11;

    if (angle == 0)
    {
      x0 = newx;
      z0 = newz;
    }

    strip.add(newx, newz);
  }
  strip.add(x0, z0);     // END SIN SPIKES 2

  return strip;
}



// for 005 & 006 // rewrite parametrically
LineStrip2D makeProfile7(float currentExtrusion)
{
  // like a symmetrical leaf petal
  println( "Param ellipse NEW");

  // Maximum angle for parametric sinusoidal shape envelope - needs to be 2PI so we get an elliptical, closed shape (only 
  // for elliptical shapes). Minimum angle is 0, of course.
  double maxAngle = Math.PI*2d; 

  LineStrip2D strip = new LineStrip2D(); //container for final list of points

  float x = xScale*adjust*currentExtrusion; // screen-adjusted horizontal coordinate
  float z = zScale*adjust*currentExtrusion; // screen-adjusted vertical coordinate

  double inc = Math.PI/48d; // the resolution of the curve (smaller = more detail)

  float x0=0, z0=0;

  float flattenParam = 1/3f;

  // pointy on top v2 
  for (double angle=0; angle<maxAngle; angle+=inc)
  {
    float ax = (float)(x*Math.cos(angle))*0.5;
    float sinTheta = (float)Math.sin(angle);
    float sin2Theta = (float)Math.sin(2*angle);

    float newz = ax+x/2;
    float newx = ax;

    if (angle < PI)
    {
      newx = 0.5*x*(flattenParam*sinTheta + (flattenParam/2)*sin2Theta);
    } else 
    {
      newx = 1.33*x*(flattenParam*sinTheta - (flattenParam/2)*sin2Theta);
    }

    float rotAngle = -PI/3;

    float nx = newz*cos(rotAngle)+newx*sin(rotAngle);
    float nz = newx*cos(rotAngle)-newz*sin(rotAngle);

    // save first points to connect later
    if (angle == 0)
    {
      x0 = nx;
      z0 = nz;
    }
    strip.add(nx, nz);
  }
  strip.add(x0, z0);

  return strip;
}



///////////////////////// OLD CODE ////////////////////////

/*
    //classic inverted -- not used
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
     // SIN SPIKES -- not used
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
    // VERSION FOR SPIRAL 008 -- SIN SPIKES smoothed 2
 LineStrip2D strip = new LineStrip2D();
 
 // pointy on top v2    
 double inc = Math.PI/48d;
 double maxAngle = Math.PI*2d;
 double offset = Math.PI/4d;
 
 float x0=0, y0=0;
 
 double centerOffX = 1.15d;
 double centerOffY = 1.8d; // try 1.2 or 1.8
 
 for (double angle=0; angle<=maxAngle; angle+=inc)
 {
 double prog = Math.abs(angle/(maxAngle/2) - 1); //-1 to 1 --> 1 to 0 to 1
 //double prog = Math.sin(Math.abs(angle/(maxAngle/2) - 1)*Math.PI*0.2d); // little pointy on top
 
 prog -= 1d; // 0 to -1 to 0
 prog = prog*prog*Math.abs(prog); // smoothing, petal-like
 //prog = prog*prog; //cubic?
 
 double xx = (1d-prog)*x + prog*xBase;
 
 float newx = (float)(0.5d*xx*(Math.sin(angle+offset)+centerOffX));
 float newy = (float)(0.5d*xx*(Math.cos(angle+offset)+centerOffY));
 
 if (angle ==0)
 {
 x0 = newx;
 y0 = newy;
 }
 
 strip.add(newx, newy);
 }
 strip.add(x0, y0);     // END SIN SPIKES 2
 */


// for spirals 005 & 6
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

/*
    //profileName = "Param cubic ellipse 012";
 LineStrip2D strip = new LineStrip2D();
 
 double inc = Math.PI/48d;
 double maxAngle = Math.PI*2d;
 double offset = Math.PI/3d;
 
 float x0=0, z0=0;
 
 double centerOffX = 1.2;
 double centerOffZ = 1.2; // try 1.2 or 1.8
 
 for (double angle=0; angle<=maxAngle; angle+=inc)
 {
 //double prog = Math.abs(angle/(maxAngle/2) - 1); //-1 to 1 --> 1 to 0 to 1
 double prog = Math.sin(Math.abs(angle/(maxAngle/2) - 1)*Math.PI*0.4d); // little pointy on top
 
 //prog = 0.75d + 0.25d*Math.cos(8*Math.PI * prog);
 
 prog -= 1d; // 0 to -1 to 0
 prog = prog*prog*Math.abs(prog); // smoothing, petal-like
 //prog = prog*prog; //cubic?
 
 double xx = (2d-prog)*x + prog*xBase;
 
 float newx = (float)(0.25d*xx*(Math.sin(angle+offset)+centerOffX));
 float newz = (float)(0.25d*xx*(Math.cos(angle+offset)+centerOffZ));
 
 if (angle == 0)
 {
 x0 = newx;
 z0 = newz;
 }
 
 strip.add(newx, newz);
 }
 strip.add(x0, z0);     // END SIN SPIKES 2
 */
