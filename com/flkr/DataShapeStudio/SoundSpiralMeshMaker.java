/*    
 * This file is by Evan Raskob <info@pixelist.info>, loosely based on other classes
 * from toxiclibs core by Karsten Schmidt.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * http://creativecommons.org/licenses/LGPL/2.1/
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
 */


// Direction and axis are handled only when getting a point or list of points



package com.flkr.DataShapeStudio;

import java.util.ArrayList;
import toxi.geom.LineStrip2D;
import toxi.geom.ReadonlyVec3D;
import toxi.geom.Spline2D;
import toxi.geom.Vec2D;
import toxi.geom.Vec3D;
import toxi.geom.mesh.TriangleMesh;
import processing.core.PApplet;


public final class SoundSpiralMeshMaker {

  // 
  // Build spiral mesh (use already allocated spiral to save time/memory) with
  // optional start and end caps.  Input mesh can be null.
  //

  @SuppressWarnings("unused")
static final public TriangleMesh makeMesh(DataStore dataStore, SoundSpiralProperties properties) throws NullPointerException
  {  
    // requires:
    // - profiles (list of circular profiles for each tube segment).  Will be cleared and regenerated
    // - profilesOnCurve (list of above profiles fit to the 3D spiral curve). Will be cleared and regenerated
    // - 

	  ArrayList<Vec3D> outwardVecs, tanVecs;
   ArrayList<LineStrip2D> profiles; // 2D polygon shapes for the tube geometry based on rms volume
  ArrayList<LineStrip3D2> profilesOnCurve; // the 3D profiles fitted to the underlying curve

  SpiralLineStrip3D spiral;
  TriangleMesh mesh; // do we need to keep this?
  
    mesh = new TriangleMesh("spiralmesh"); // mesh to hold final spiral for export
    spiral = new SpiralLineStrip3D( new Vec3D(0, 0, 0), new Vec3D(0, 0, 1) );

    profiles = new ArrayList<LineStrip2D>();
    outwardVecs = new ArrayList<Vec3D>();
    tanVecs = new ArrayList<Vec3D>();
    profilesOnCurve = new ArrayList<LineStrip3D2>();

    if (mesh == null) throw new NullPointerException("Mesh cannot be null in createSpiral");
    else
      mesh.clear();


    // set number of points

    spiral.setTurns(properties.turns, false)
      .setRadius(properties.spiralRadius, false)
      .setDistanceBetweenTurns(properties.distanceBetweenSpirals, false)
      .setEdgeThickness(properties.spiralThickness, false)
      .setNumPoints(dataStore.getData().length);

    System.out.println("total spiral points:" + spiral.getNumPoints() + " / " + dataStore.getData().length);

    // calculate tangents and outwards facing vectors
    // take the next point and subtract from previous point to get inwards pointing vector

    int numPoints = spiral.getNumPoints();

    System.out.println("DEBUG:: setting up tangent and outwards vectors");

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

      //Vec3D po = outwardVecs.get(i-1);
      //outVec.set(v0.add(v1).interpolateTo(po,0.1)); // try to smooth it a bit...
      outVec.set(v0.add(v1));
      outVec.normalize();
    }

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

    float data[] = dataStore.getData();

    for (int i=0; i<numPoints; i++)
    {
      Spline2D spline = new Spline2D();
      float currentRMS = (data[i] + properties.adjust);
      float minRMS = (dataStore.minVal+properties.adjust);
      float thick = spiral.getEdgeThickness();

      float yRMS =  currentRMS*properties.spikiness;
      float yBase = minRMS*properties.spikiness;
      float y = yRMS;


      float xRMS = currentRMS*thick;
      float xBase = minRMS*thick;
      float x = xRMS;


      // pointy on bottom
      spline.add(0, 0);    
      spline.add(x*0.66f, y*0.3f); // overhang
      spline.add(x, y);
      spline.add(x*0.4f, y*0.66f); //underhang
      spline.add(0, 0); // close spline

      LineStrip2D strip = spline.toLineStrip2D(properties.diameterQuality);


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


      //// SIN squared smoothed SPIKES smoothed
      //LineStrip2D strip = new LineStrip2D();

      //// pointy on top v2    
      //double inc = Math.PI/24d;
      //double maxAngle = Math.PI*2d;
      //double offset = Math.PI/6d;

      //for (double angle=0; angle<maxAngle; angle+=inc)
      //{
      ////double prog = Math.sin(Math.abs(angle/(maxAngle/2) - 1)*Math.PI*0.5d); // full sin
      //double prog = Math.sin(Math.abs(angle/(maxAngle/2) - 1)*Math.PI*0.2d); // little pointy on top
      ////prog = prog*prog; // smoothing
      ////prog = prog*prog; //cubic?

      //double xx = (1d-prog)*xBase + 2*prog*x;  //yeah, float/double conversion blah blah

      //strip.add((float)(0.5d*xx*(Math.cos(angle+offset)+1d)), (float)(0.5d*xx*(Math.sin(angle+offset)+1d)));
      //}
      //// END SIN squared SPIKES



      // DEBUG - removed this
      // add profile to internal tube list of profiles 
      //profiles.add(strip.add(strip.get(0)));

      // test 1st and last points are the same
      //float profDist = strip.get(0).distanceTo(strip.get(strip.getVertices().size()-1));
      //println("p0-p8 dist=" + profDist);

      profiles.add(strip);
    }

    //println("DEBUG:: added " + profiles.size() + " profiles");

    //
    // BUILDING MESH AND PSHAPE ----------------------=------------
    //

    // iterate through all profiles and build 3D mesh

    final int numProfilePoints = (profiles.get(0).getVertices()).size(); // all are the same size

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
    if (profilesOnCurve.size() != profiles.size() ||  profilesOnCurve.size() != numPoints )
    {
      System.err.println( "ERROR: profiles have different sizes:: [cp] " + profilesOnCurve.size() + ", [pp] " + profiles.size() + ", [np] " + numPoints);
    }


    if (properties.startcap)
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
      
      centerPoint.scaleSelf(1.0f/numProfilePoints);

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

    if (properties.base)
    {
      double maxAngle = Math.PI/2d;

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
        mesh.addMesh( ShapeUtils.makeMesh(curveToBaseProfiles1, curveToBaseProfiles0));
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
        firstPointsMinZ = PApplet.min(firstPointsMinZ, v.z());
        float r = v.x()*v.x()+v.y()*v.y();
        firstPointsMaxR = PApplet.max(firstPointsMaxR, r);
        firstPointsMinR = PApplet.min(firstPointsMinR, r);
      }
      // setup cylindrical base
      float baseStartZ = firstPointsMinZ;
      float baseEndZ = baseStartZ - properties.distanceBetweenSpirals/4f;
      double baseStartRadius = 0.95d*Math.sqrt(firstPointsMinR);
      double baseEndRadius = 1.2d*Math.sqrt(firstPointsMaxR); // add margin...

      int resolution = 48; // for the curved segment joining the spiral to the base cylinder

      // curveToBaseProfiles0 is the last line strip at the bottom of this shape - now 
      // make a smooth transition down to it.

      // ----------------------
      // generate base geometry
      // TODO - make this a generic function
      //
      LineStrip3D2 c1 = ShapeUtils.makeHiResCircle3D(new Vec3D(0, 0, baseStartZ), baseStartRadius, resolution);
      LineStrip3D2 c2 = ShapeUtils.makeHiResCircle3D(new Vec3D(0, 0, baseStartZ), baseEndRadius, resolution);

      mesh.addMesh( ShapeUtils.makeMesh(c2, c1));


      LineStrip3D2 c3 = ShapeUtils.makeHiResCircle3D(new Vec3D(0, 0, baseEndZ), baseStartRadius, resolution);
      LineStrip3D2 c4 = ShapeUtils.makeHiResCircle3D(new Vec3D(0, 0, baseEndZ), baseEndRadius, resolution);

      mesh.addMesh( ShapeUtils.makeMesh(c3, c4) );


      // inner walls
      c3 = ShapeUtils.makeHiResCircle3D(new Vec3D(0, 0, baseStartZ), baseStartRadius, resolution);
      c4 = ShapeUtils.makeHiResCircle3D(new Vec3D(0, 0, baseEndZ), baseStartRadius, resolution);

      mesh.addMesh( ShapeUtils.makeMesh(c3, c4) );

      // outer walls
      c3 = ShapeUtils.makeHiResCircle3D(new Vec3D(0, 0, baseStartZ), baseEndRadius, resolution);
      c4 = ShapeUtils.makeHiResCircle3D(new Vec3D(0, 0, baseEndZ), baseEndRadius, resolution);

      mesh.addMesh( ShapeUtils.makeMesh(c4, c3) );
      // 
      // done with base geometry
      // -----------------------
    }


    if (properties.endcap)
    {
      //
      // add end cap
      //

      LineStrip3D2 endProfilePoints = profilesOnCurve.get(numPoints-1);

      // find average (center) point of cap
      Vec3D centerPoint = new Vec3D(0, 0, 0);
      for (Vec3D p : endProfilePoints)
        centerPoint.addSelf(p);
      centerPoint.scaleSelf(1.0f/numProfilePoints);

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

    System.out.println("spiral finished");
    System.out.println("mesh faces:" + mesh.getNumFaces());
    System.out.println("mesh verts:" + mesh.getNumVertices());
    
    return mesh;
  }
  // finished createSpiral()
  //

  // end class SoundSpiralMesh
}