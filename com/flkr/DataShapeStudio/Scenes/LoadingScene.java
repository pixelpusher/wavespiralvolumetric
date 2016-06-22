/*
 * Startup/loading screen
 */

package com.flkr.DataShapeStudio.Scenes;

import com.flkr.DataShapeStudio.IStudioEventHandler;

import processing.core.PApplet;


public class LoadingScene extends AScene {

	public LoadingScene(PApplet _parent) {
		super(_parent);
	}

	@Override
	public void draw()
	{
		parent.background(0);
		parent.fill(200, 0, 200, 100);
		parent.stroke(255);
		parent.textSize(20);
		parent.text("hit space", 10, 20);
		parent.noLoop(); //turn off loop until needed
	}

	@Override
	public void handleKeyRelease(char key, IStudioEventHandler handler) {
		handler.loadData();  // trigger load data file GUI
	}

	@Override
	public void handleKeyPress(char key, IStudioEventHandler handler) {
	}

	@Override
	public void handleMouseClick(int x, int y, IStudioEventHandler handler) {		
	}
} // end LoadingScene
