/*
 * Minimal interface for objects that can draw to the screen
 */

package com.flkr.DataShapeStudio.Scenes;
import com.flkr.DataShapeStudio.IStudioEventHandler;

import processing.core.PApplet;

public abstract class AScene {

	protected PApplet parent;
	
	public AScene(PApplet _parent) {
		parent = _parent;
	}

	public abstract void draw();
	
	public abstract void handleKeyRelease(char key, IStudioEventHandler handler);
	public abstract void handleKeyPress(char key, IStudioEventHandler handler);
	public abstract void handleMouseClick(int x, int y, IStudioEventHandler handler);
}
