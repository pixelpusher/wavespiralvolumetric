/*
 * Copyright (c) 2006-2011 Evan Raskob <info@pixelust.info>
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


/*
 * A 3D spiral with a 3D offset at each point
 *
 */

public class OffsetSpiral3D extends Spiral3D {

  private Vec3D[] offset;

  public OffsetSpiral3D()
  {
    super();
  }

  public OffsetSpiral3D(ReadonlyVec3D pos, ReadonlyVec3D dir)
  {
    super(pos, dir);
  }

  //
  // check if size has changed... if so, reinitialize offset
  //

  public OffsetSpiral3D recalculate()
  {
    super.recalculate();
    if (this.offset == null || this.offset.length != this.points.length)
    {
      resetOffset();
    }

    return this;
  }


  public OffsetSpiral3D resetOffset()
  {
    this.offset = new Vec3D[this.points.length]; // can't go past length of our points
    for (int i=0; i < offset.length; i++)
    {
      this.offset[i] = new Vec3D(0, 0, 0); // make sure to account for shorter length arrays...
    }

    return this;
  }

  public OffsetSpiral3D setOffset(Vec3D[] offset)
  {
    if (offset.length != this.points.length)
    {
      System.out.println("Warning: points arrays not same length in OffsetSpiral3D setOffset(Vec3D[] offset)");
    }

    // should we check for null? Probably should throw an exception
    this.offset = new Vec3D[this.points.length]; // can't go past length of our points
    for (int i=0; i < offset.length; i++)
    {
      this.offset[i] = offset[i % offset.length].copy(); // make sure to account for shorter length arrays...
    }

    return this;
  }

  // scale at each point a certain percentage...

  public OffsetSpiral3D scaleEach(float[] scale)
  {
    if (scale.length != this.points.length)
    {
      System.out.println("Warning: points arrays not same length in OffsetSpiral3D scaleEach(float[] scale)");
    }

    // should we check for null? Probably should throw an exception
    this.offset = new Vec3D[this.points.length]; // can't go past length of our points
    
    int maxIndex = this.points.length;
    if (scale.length < maxIndex) maxIndex = scale.length;
    
    
    for (int i=0; i < this.offset.length; i++)
    {
      float offsetMag = scale[i % maxIndex];
      
      // always building spiral along Z axis makes the math easier
      
      Vec3D scaled = this.points[i].scale(offsetMag);
      Vec3D diff = this.points[i].sub(scaled);
      diff.z = 0f;  // make sure to 0 out z coord
      this.offset[i] = diff;
    }

    return this;
  }




  public Vec3D[] getPoints()
  {
    final Vec3D[] origPoints = super.getPoints();

    for (int i=0; i<origPoints.length; i++)
    {
      origPoints[i].addSelf(this.offset[i]);
    }
    return origPoints;
  }
}


