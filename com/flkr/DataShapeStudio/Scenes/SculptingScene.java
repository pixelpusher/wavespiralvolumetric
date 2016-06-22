package com.flkr.DataShapeStudio.Scenes;

import com.flkr.DataShapeStudio.IStudioEventHandler;
import com.flkr.DataShapeStudio.ShapeUtils;
import com.flkr.DataShapeStudio.SoundSpiralProperties;

import peasy.PeasyCam;
import processing.core.PApplet;
import processing.core.PShape;
import toxi.geom.AABB;
import toxi.geom.Vec3D;
import toxi.geom.mesh.TriangleMesh;
//import processing.opengl.PGL;

// TODO: key presses go here!!!!  

public class SculptingScene extends AScene {

	public boolean drawProfiles;
	public PeasyCam cam;
	
	private boolean drawVecs;
	private PShape theShape;
	private PShape theProfilesShape; 
	// properties of the current shape
	// change to generic PROPERTIES object with hashtable for all keys?
	private SoundSpiralProperties spiralProperties;
	private PShape printerBoundingBox = null;
	

	
	public SculptingScene(PApplet _parent) {
		super(_parent);
		spiralProperties = new SoundSpiralProperties();
		
		//
		// create printer bounding box shape for reference
		Vec3D printerSizeInMM = new Vec3D(285, 155, 153); // Makerbot replicator 2
		TriangleMesh b = (TriangleMesh)new AABB(new Vec3D(0, 0, printerSizeInMM.z()), printerSizeInMM).toMesh();
		//b.transform(new Matrix4x4().translateSelf(pos.x,pos.y,pos.z));  // if we need to move it
		printerBoundingBox = ShapeUtils.meshToRetained(parent,b, false);
		printerBoundingBox.setFill(false);
		int c = parent.color(255, 180);
		printerBoundingBox.setStroke(c);
		printerBoundingBox.setStrokeWeight(1);
	}

	
	// FIXME: Does this make sense???
	public void makeShape(TriangleMesh mesh)
	{
		theShape = ShapeUtils.meshToRetained(parent, mesh, false);
	}

	/*
	public void setProfilesShape()
	{
		// create profiles shape (for future visualisation)
		profileShape = pathsToShape2(profilesOnCurve);
		profileShape.noFill();
		profileShape.setStroke(color(255, 80));
	}
	*/

	@Override
	public void draw() {
		// TODO Auto-generated method stub
		parent.background(0);
		parent.fill(200, 0, 200, 100);
		//stroke(255);

		//PGL pgl = parent.beginPGL();
		//lights();
		//camera(width - 2*mouseX, height - 2*mouseY, 400, 0, 0, 0, 0, 1, 0);
		// turn on backface culling to make sure it looks as it will come out...
		parent.pushMatrix();
		parent.scale(5);

		// draw desktop 3D printer shape for reference
//		if (drawPrinterBox) shape(printerBoundingBox);

		//lights();
		// DRAW PSHAPE STUFF

		//pgl.enable(PGL.CULL_FACE);
		// make sure we are culling the right faces - STL files need anti-clockwise winding orders for triangles
		//pgl.frontFace(PGL.CCW);
		//pgl.cullFace(PGL.BACK);

		//pgl.disable(PGL.CULL_FACE);

		if (!drawProfiles)
		{
			if (theShape != null)
			{
				parent.lights();
				parent.ambientLight(10, 10, 10);
				parent.directionalLight(100f, 100f, 140f, -0.6f, 0f, -1f);

				parent.directionalLight(104f, 104f, 124f, 0.6f, 0f, 1f);

				parent.shape(theShape);
				parent.noLights();
			}
		}
		parent.popMatrix();
		parent.endPGL(); // restores the GL defaults for Processing
		//noLights();


		if (true)
		{
			// draw info overlay
			int fontsize = 18;
			int startX = fontsize;
			int startY = 2*fontsize;

			parent.hint(PApplet.DISABLE_DEPTH_TEST);

			if (drawProfiles)
				if (theProfilesShape != null)
					parent.shape(theProfilesShape);

			if (drawVecs)
				drawOutVecs();

			/*
			 * THIS IS A TOTAL FUCKING MESS
			 * TODO
			 * 
			if (soundAmplitudes != null)
			{
				cam.beginHUD();

				textSize(fontsize);
				textAlign(LEFT, BOTTOM);

				parent.fill(255);
				parent.text("file: " + wavFileName, startX, startY );
				startY += fontsize;
				parent.text("file length: " + soundAmplitudes.length/(float)wavSampleRate + "sec", startX, startY );
				startY += fontsize;
				parent.text("turns: " + turns, startX, startY );
				startY += fontsize;
				parent.text("distanceBetweenSpirals: " + distanceBetweenSpirals, startX, startY );
				startY += fontsize;
				parent.text("thickness: " + spiralThickness, startX, startY );
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
			*/
			parent.hint(parent.ENABLE_DEPTH_TEST);
		}
	}


	private void drawOutVecs() {
		// TODO Auto-generated method stub
		
	}

	@Override
	public void handleKeyRelease(char key, IStudioEventHandler handler) {
		// TODO Auto-generated method stub
		
	}

	@Override
	public void handleKeyPress(char key, IStudioEventHandler handler) {
		// TODO Auto-generated method stub
		
	}

	@Override
	public void handleMouseClick(int x, int y, IStudioEventHandler handler) {
		// TODO Auto-generated method stub
		
	}

}
