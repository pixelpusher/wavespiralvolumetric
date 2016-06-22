package com.flkr.DataShapeStudio;

import java.util.ArrayList;
import java.util.Iterator;

import processing.core.PApplet;
import processing.core.PShape;
import toxi.geom.LineStrip3D;
import toxi.geom.Vec3D;
import toxi.geom.mesh.Face;
import toxi.geom.mesh.Mesh3D;
import toxi.geom.mesh.TriangleMesh;

final public class ShapeUtils {


	// create a circular path with the number of points (e.g. resolution)
	public static final LineStrip3D2 makeHiResCircle3D(Vec3D pos, double r, int res)
	{
		LineStrip3D2 result = new LineStrip3D2();
		double TWOPI = Math.PI*2d;
		double radiansPerPoint = TWOPI / res;

		double angle = 0d;
		while (angle < TWOPI)
		{
			Vec3D pt = new Vec3D(
					(float)(Math.cos(angle)*r)+pos.x(),
					(float)(Math.sin(angle)*r)+pos.y(),
					pos.z()
					);
			result.add(pt);
			//System.out.println(pt);

			angle +=  radiansPerPoint;
		}
		return result;
	}


	//
	// Make a triangle mesh from two lists of 3D points with the same number of points.
	// Assumes the point lists are clockwise.
	//
	public static final TriangleMesh makeMesh(LineStrip3D strip1, LineStrip3D strip2)
	{
		int strip1Size = strip1.getVertices().size();
		int strip2Size = strip2.getVertices().size();

		if (strip1Size != strip2Size) return null;

		TriangleMesh mesh = new TriangleMesh("mesh", strip2Size*2*3, strip2Size*2 );

		Iterator<Vec3D> strip1Iter = strip1.iterator();
		Iterator<Vec3D> strip2Iter = strip2.iterator();

		Vec3D p1, // prev point in strip 1
		p2, // current point in strip 1
		p3, // prev point in strip 2
		p4; // current point in strip 2

		p1 = strip1Iter.next();
		p3 = strip2Iter.next();

		while (strip1Iter.hasNext ())
		{
			p2 =  strip1Iter.next();
			p4 =  strip2Iter.next();

			// 1-3-2
			mesh.addFace(p1, p3, p2);

			//2-3-4
			mesh.addFace(p2, p3, p4);

			p1 = p2;
			p3 = p4;
		}

		return mesh;
	}


	public static final PShape meshToRetained(PApplet papp, Mesh3D mesh,  boolean smth)
	{
		PShape retained = papp.createShape();

		retained.beginShape(PApplet.TRIANGLES);
		retained.enableStyle();
		retained.fill(180);
		retained.noStroke();
		mesh.computeFaceNormals();

		if (smth)
		{
			mesh.computeVertexNormals();
			//int i=0;
			for (Face f : mesh.getFaces()) {
				retained.normal(f.a.normal.x, f.a.normal.y, f.a.normal.z);
				retained.vertex(f.a.x, f.a.y, f.a.z);
				retained.normal(f.b.normal.x, f.b.normal.y, f.b.normal.z);
				retained.vertex(f.b.x, f.b.y, f.b.z);
				retained.normal(f.c.normal.x, f.c.normal.y, f.c.normal.z);
				retained.vertex(f.c.x, f.c.y, f.c.z);
			}
		} else {
			//int i=0;
			for (Face f : mesh.getFaces())
			{
				// papp.println("triangles"+ i++);
				retained.normal(f.normal.x, f.normal.y, f.normal.z);
				retained.vertex(f.a.x, f.a.y, f.a.z);
				retained.vertex(f.b.x, f.b.y, f.b.z);
				retained.vertex(f.c.x, f.c.y, f.c.z);
			}
		}
		retained.endShape();
		return retained;
	}

	/*
static final PShape meshToRetained(PApplet papp, Mesh3D mesh, ColorList colorlist,  boolean smth)
{
  PShape retained = createShape();
  mesh.computeFaceNormals();

  retained.beginShape(TRIANGLES);
  retained.enableStyle();

  if (smth)
  {
    mesh.computeVertexNormals();
    int i=0;
    for (Face f : mesh.getFaces()) {
      retained.fill(colorlist.get(i++).toARGB());
      retained.normal(f.a.normal.x, f.a.normal.y, f.a.normal.z);
      retained.vertex(f.a.x, f.a.y, f.a.z);
      retained.normal(f.b.normal.x, f.b.normal.y, f.b.normal.z);
      retained.vertex(f.b.x, f.b.y, f.b.z);
      retained.normal(f.c.normal.x, f.c.normal.y, f.c.normal.z);
      retained.vertex(f.c.x, f.c.y, f.c.z);
    }
  } else {
    int i=0;
    for (Face f : mesh.getFaces())
    {
      retained.fill(colorlist.get(i++).toARGB());
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
	 */


	public static final PShape pathsToShape(PApplet papp, ArrayList<LineStrip3D> paths)
	{
		PShape retained = papp.createShape();

		retained.enableStyle();
		retained.beginShape(PApplet.LINES);
		//retained.fill(120,120,0,80);
		retained.noFill();
		retained.stroke(255, 180);
		retained.strokeWeight(2);


		for (LineStrip3D path : paths)
		{
			Iterator<Vec3D> iter = path.iterator();
			Vec3D currentP = iter.next();
			Vec3D nextP = currentP;

			while (iter.hasNext ())
			{
				nextP = iter.next();
				retained.vertex(currentP.x(), currentP.y(), currentP.z());
				retained.vertex(nextP.x(), nextP.y(), nextP.z());
				currentP = nextP;
			}
		}

		retained.endShape();
		return retained;
	}

	//
	// this is the version for LineStrip3D2, which is my version with convenience functions for vertices
	//
	public static final PShape pathsToShape2(PApplet papp, ArrayList<LineStrip3D2> paths)
	{
		PShape retained = papp.createShape();

		retained.enableStyle();
		retained.beginShape(PApplet.LINES);
		//retained.fill(120,120,0,80);
		retained.noFill();
		retained.stroke(255, 180);
		retained.strokeWeight(2);


		for (LineStrip3D2 path : paths)
		{
			Iterator<Vec3D> iter = path.iterator();
			Vec3D currentP = iter.next();
			Vec3D nextP = currentP;

			while (iter.hasNext ())
			{
				nextP = iter.next();
				retained.vertex(currentP.x(), currentP.y(), currentP.z());
				retained.vertex(nextP.x(), nextP.y(), nextP.z());
				currentP = nextP;
			}
		}

		retained.endShape();
		return retained;
	}
} // end class ShapeUtils
