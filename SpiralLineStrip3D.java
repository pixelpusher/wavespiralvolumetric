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


import java.util.ArrayList;
import java.util.List;

import toxi.geom.ReadonlyVec3D;
import toxi.geom.Vec3D;
import toxi.math.MathUtils;
//import processing.core.PApplet;



public class SpiralLineStrip3D extends LineStrip3D2 {

  public Vec3D dir;
  public Vec3D pos;


  private double radius;
  private int   numPoints;
  private double turns;
  private double distanceBetweenTurns;
  private double edgeThickness; // thickness of the line
  private double length;


  /**
   * Constructs a new 3D spiral instance.
   * 
   * @param pos
   *            start position
   * @param dir
   *            direction
   */
  public SpiralLineStrip3D(ReadonlyVec3D pos, ReadonlyVec3D dir) 
  {
    this.pos = new Vec3D(pos);
    this.dir = dir.getNormalized();
  }

  public SpiralLineStrip3D() 
  {
    // defaults to not much of a spiral
    this.pos = new Vec3D(0, 0, 0);
    this.radius = 0;
    this.numPoints = 0;
    this.turns = 0;
    this.distanceBetweenTurns = 0;
    this.edgeThickness = 0;
    this.dir = new Vec3D(Vec3D.Z_AXIS);
    this.recalculate();
  }

  /*
   * Boring get/set stuff
   */
  public SpiralLineStrip3D setRadius(double radius, boolean recalculate)
  {
    this.radius = radius;
    if (recalculate)
      this.recalculate();
    return this;
  }
  public SpiralLineStrip3D setRadius(double radius)
  {     
    return this.setRadius(radius, true);
  }

  public SpiralLineStrip3D setTurns(double turns)
  {     
    return this.setTurns(turns, true);
  }
  public SpiralLineStrip3D setTurns(double turns, boolean recalculate)
  {
    this.turns = turns;
    if (recalculate)
      this.recalculate();
    return this;
  }

  public SpiralLineStrip3D setDistanceBetweenTurns(double distanceBetweenTurns)
  {     
    return this.setDistanceBetweenTurns(distanceBetweenTurns, true);
  }
  public SpiralLineStrip3D setDistanceBetweenTurns(double distanceBetweenTurns, boolean recalculate)
  {
    this.distanceBetweenTurns = distanceBetweenTurns;
    if (recalculate)
      this.recalculate();
    return this;
  }


  public SpiralLineStrip3D setEdgeThickness(double edgeThickness)
  {     
    return this.setEdgeThickness(edgeThickness, true);
  }
  public SpiralLineStrip3D setEdgeThickness(double edgeThickness, boolean recalculate)
  {
    this.edgeThickness = edgeThickness;
    if (recalculate)
      this.recalculate();
    return this;
  }  

  public SpiralLineStrip3D setNumPoints(int numPoints)
  {     
    return this.setNumPoints(numPoints, true);
  }
  public SpiralLineStrip3D setNumPoints(int numPoints, boolean recalculate)
  {
    this.numPoints = numPoints;
    if (recalculate)
      this.recalculate();
    return this;
  }  

  public List<Vec3D> getVertices() 
  {
    return super.getVertices();
  }
  
  // TODO - handle rotation based on this.dir??
  // TODO - fix this, it's not following convention but quicker right now...

  public List<Vec3D> getVertices(boolean useOffset) 
  {
    if (useOffset)
    {
      final ArrayList<Vec3D> truePoints = new ArrayList<Vec3D>(this.vertices.size());
      for (Vec3D pt : this.vertices)
      {
        truePoints.add(pt.add(this.pos));
      }

      return truePoints;
    } else
      return super.getVertices();
  }


  public double getRadius() { 
    return radius;
  }
  public int   getNumPoints() { 
    return numPoints;
  }
  public double getTurns() { 
    return turns;
  }
  public double getDistanceBetweenTurns() { 
    return distanceBetweenTurns;
  }
  public double getEdgeThickness() { 
    return edgeThickness;
  }
  public double getLength() { 
    return length;
  }


  //
  // recalculate all the points in this spiral
  //
  public SpiralLineStrip3D recalculate()
  {

    turns = Math.max(0.0001,turns);
    

    double totalRadians = Math.PI * 2d * this.turns;
    double radiansPerPoint = totalRadians / this.numPoints;

    this.vertices = new ArrayList<Vec3D>( this.numPoints);

    // nothing to do here - too few points
    if (this.numPoints < 2)
    {
      this.numPoints = 2;
      for (int i=0; i< this.numPoints; i++)
        this.vertices.add(new Vec3D((float)this.radius, 0, 0));

      return this;
    }
    
    System.out.println("total points: " + this.numPoints);
    System.out.println("turns: " + this.turns);

    // NOTE: Direction and axis are handled only when getting a point or list of points

    // note - here we're calculating all points requested, even though the number of turns might not match exactly.. 
    // have to choose one or the other.
    
    Vec3D prev = new Vec3D(0f,0f,0f);
    
    for (int currentPoint=0; currentPoint < this.numPoints; currentPoint++)
    {
      double turnsProgress = ((float)currentPoint)/this.numPoints;
      double x = Math.cos( radiansPerPoint*currentPoint ) * this.radius;
      double y = Math.sin( radiansPerPoint*currentPoint ) * this.radius;
      double z = turnsProgress * this.turns * this.distanceBetweenTurns;
      Vec3D vert = new Vec3D((float)x, (float)y, (float)z);
      this.vertices.add(vert);
      //DEBUG
      //System.out.println("pdiff["+currentPoint+"]=" + prev.distanceTo(vert));
      
      prev.set(vert);
      
    }

    Vec3D topBottomDiff = this.vertices.get( this.vertices.size() - 1).sub(this.vertices.get(0));

    this.length = topBottomDiff.z; // aligning to Z axis internally makes this easier...

    return this;
  }

  // TODO - implement this??

  /*
  public Mesh3D toMesh(int steps) {
   return toMesh(steps, 0);
   }
   
   public Mesh3D toMesh(int steps, double thetaOffset) {
   return toMesh(null, steps, thetaOffset, true, true);
   }
   
   public Mesh3D toMesh(Mesh3D mesh, int steps, double thetaOffset, 
   boolean topClosed, boolean bottomClosed) {
   
   ReadonlyVec3D c = this.add(0.01f, 0.01f, 0.01f);
   ReadonlyVec3D n = c.cross(dir.getNormalized()).normalize();
   Vec3D halfAxis = dir.scale(length * 0.5f);
   Vec3D p = sub(halfAxis);
   Vec3D q = add(halfAxis);
   Vec3D[] south = new Vec3D[steps];
   Vec3D[] north = new Vec3D[steps];
   double phi = MathUtils.TWO_PI / steps;
   for (int i = 0; i < steps; i++) {
   double theta = i * phi + thetaOffset;
   ReadonlyVec3D nr = n.getRotatedAroundAxis(dir, theta);
   south[i] = nr.scale(radiusSouth).addSelf(p);
   north[i] = nr.scale(radiusNorth).addSelf(q);
   }
   int numV = steps * 2 + 2;
   int numF = steps * 2 + (topClosed ? steps : 0)
   + (bottomClosed ? steps : 0);
   if (mesh == null) {
   mesh = new TriangleMesh("cone", numV, numF);
   }
   for (int i = 0, j = 1; i < steps; i++, j++) {
   if (j == steps) {
   j = 0;
   }
   mesh.addFace(south[i], north[i], south[j], null, null, null, null);
   mesh.addFace(south[j], north[i], north[j], null, null, null, null);
   if (bottomClosed) {
   mesh.addFace(p, south[i], south[j], null, null, null, null);
   }
   if (topClosed) {
   mesh.addFace(north[i], q, north[j], null, null, null, null);
   }
   }
   return mesh;
   }
   */
}