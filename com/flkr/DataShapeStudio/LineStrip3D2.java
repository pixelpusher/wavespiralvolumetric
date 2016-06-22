
/**
 *  slightly more efficient LineStrip3D
 *
 * by Evan Raskob <info@pixelist.info>
 *
 **/
 

package com.flkr.DataShapeStudio;

import java.util.ArrayList;
import java.util.List;


import toxi.geom.LineStrip3D;

import toxi.geom.Vec3D;

public class LineStrip3D2 extends LineStrip3D {
  
  public LineStrip3D2()
  {
     // nothing... 
  }
  
  public LineStrip3D2(int numVerts) {
    ((ArrayList<Vec3D>)this.vertices).ensureCapacity(numVerts);
  }

  /**
   * @param vertices
   *            the vertices to be copied
   */
  public void copyVertices(LineStrip3D2 otherStrip) {
    this.vertices.clear(); // clear old references
    ((ArrayList<Vec3D>)this.vertices).ensureCapacity(otherStrip.size());
    for (Vec3D vert : otherStrip)
    {
      this.vertices.add( vert );
    }
  }


  /**
   * @param vertices
   *            the vertices to be copied
   */
  public void copyVertices(List<Vec3D> vertices) {
    this.vertices.clear(); // clear old references
    ((ArrayList<Vec3D>)this.vertices).ensureCapacity(vertices.size());
    for (Vec3D vert : vertices)
    {
      this.vertices.add( vert );
    }
  }
  
  public int size() {
    return this.vertices.size();
  }
}