/**
 * 
 */
package com.flkr.DataShapeStudio;

import processing.core.PApplet;

/**
 * @author Evan Raskob
 *
 */
public class DataStore {

	private float[] data;
	
	static final float log10 = PApplet.log(10);

	float minVal;
	float maxVal;

	DataStore()
	{
		minVal = PApplet.MAX_INT;
		maxVal = PApplet.MIN_INT;
	}
	
	// convert number from 0 to 1 into log scale from 0 to 1
	static final float logScale(float val, float minVal, float maxVal)
	{
		val = PApplet.map(val, minVal, maxVal, 1, 10);
		//val *= val;
		return PApplet.log(val)/log10;
	}

	// convert number from 0 to 1 into log scale from 0 to 1
	static final float revLogScale(float val, float minVal, float maxVal)
	{
		val = PApplet.map(val, minVal, maxVal, 10, 1);
		//val *= val;
		return PApplet.log(val)/log10;
	}

	
	/*
	 * Copy data source into this object for future use
	 */
	public DataStore setData(float[] _data)
	{
		this.data = new float[_data.length];
		 System.arraycopy( _data, 0, this.data, 0, _data.length );
		return this;
	}

	public float[] getData() {
		return data;
	}
}
