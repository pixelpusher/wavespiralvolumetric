package com.flkr.DataShapeStudio;

/*
 * TODO:
 * Properties files should have values mapped to keys for GUI?
 * Or maybe they just respond to key presses/GUI events themselves.
 */

public class SoundSpiralProperties extends Object
{
  // basic storage class for sound spiral properties objects

  public int diameterQuality = 10;
  public float adjust = 0.01f;
  public float turns = 3f;
  public float spiralThickness = 60.0f/turns; // in mm
  public float distanceBetweenSpirals = 12.0f/turns; // in mm
  public float spiralRadius = 0.8f; // in mm
  public float spikiness = 28f;
  public float minThickness = 0.01f; // percentage, 0 - 1
  public boolean startcap;
  public boolean endcap;
  public boolean base;

  public SoundSpiralProperties()
  {
    diameterQuality = 10;
    adjust = 0.01f;
    turns = 3f;
    spiralThickness = 60.0f/turns; // in mm
    distanceBetweenSpirals = 12.0f/turns; // in mm
    spiralRadius = 0.8f; // in mm
    spikiness = 28f;
    minThickness = 0.01f; // percentage, 0 - 1
    startcap = true;
    endcap = false;
    base = true;
  }

  public SoundSpiralProperties(SoundSpiralProperties _properties)
  {
    this.set(_properties);
  }

  /*
  @Override
  public toString() {
     // TODO
  }
 */
  public SoundSpiralProperties set(SoundSpiralProperties _properties)
  {
     this.diameterQuality = _properties.diameterQuality;
     this.adjust = _properties.adjust;
     this.turns = _properties.turns;
     this.spiralThickness = _properties.spiralThickness;
     this.distanceBetweenSpirals = _properties.distanceBetweenSpirals;
     this.spiralRadius = _properties.spiralRadius;
     this.spikiness = _properties.spikiness;
     this.minThickness = _properties.minThickness;
     this.startcap = _properties.startcap;
     this.endcap = _properties.endcap;
     this.base = _properties.base;

    return this;
  }
}