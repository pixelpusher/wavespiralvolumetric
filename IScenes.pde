/*
 * Startup/loading screen
 */

final class LoadingScene implements IScene {

  void draw()
  {
    background(0);
    fill(200, 0, 200, 100);
    stroke(255);
    textSize(20);
    text("hit space", 10, 20);
    noLoop(); //turn off loop until needed
  }
} // end LoadingScene

/*
 * Draw shape view
 */

final class ShapeScene implements IScene
{
  void draw()
  {
    background(0);
    fill(200, 0, 200, 100);
    //stroke(255);

    PGL pgl = beginPGL();
    //lights();
    //camera(width - 2*mouseX, height - 2*mouseY, 400, 0, 0, 0, 0, 1, 0);
    // turn on backfce culling to make sure it looks as it will come out...
    pushMatrix();
    scale(5);

    // draw dektop 3D printer shape for reference
    if (drawPrinterBox) shape(printerBoundingBox);

    //lights();
    // DRAW PSHAPE STUFF

    //pgl.enable(PGL.CULL_FACE);
    // make sure we are culling the right faces - STL files need anti-clockwise winding orders for triangles
    //pgl.frontFace(PGL.CCW);
    //pgl.cullFace(PGL.BACK);

    //pgl.disable(PGL.CULL_FACE);

    if (!drawProfiles)
    {
      if (spiralShape != null)
      {
        lights();
        ambientLight(10, 10, 10);
        directionalLight(100, 100, 140, -0.6, 0, -1);

        directionalLight(104, 104, 124, 0.6, 0, 1);

        shape(spiralShape);
        noLights();
      }
    }
    popMatrix();
    endPGL(); // restores the GL defaults for Processing
      //noLights();


    if (true)
    {
      // draw info overlay

      int fontsize = 18;
      int startX = fontsize;
      int startY = 2*fontsize;

      hint(DISABLE_DEPTH_TEST);

      if (drawProfiles)
        if (profileShape != null)
          shape(profileShape);

      if (drawVecs)
        drawOutVecs();

      if (soundAmplitudes != null)
      {
        cam.beginHUD();

        textSize(fontsize);
        textAlign(LEFT, BOTTOM);

        fill(255);
        text("file: " + wavFileName, startX, startY );
        startY += fontsize;
        text("file length: " + soundAmplitudes.length/(float)wavSampleRate + "sec", startX, startY );
        startY += fontsize;
        text("turns: " + turns, startX, startY );
        startY += fontsize;
        text("distanceBetweenSpirals: " + distanceBetweenSpirals, startX, startY );
        startY += fontsize;
        text("thickness: " + spiralThickness, startX, startY );
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
      hint(ENABLE_DEPTH_TEST);
    }
  } // end draw
} // end class ShapeScene


/*
 * Draw RMS audio view
 */

final class RMSScene implements IScene {

  void draw() {
      noLights();
      hint(DISABLE_DEPTH_TEST); colorMode(RGB);
      if (soundAmpsShape != null)   shape(soundAmpsShape);

      if (soundRMSShape != null) shape(soundRMSShape);

      if (soundRMSShape2 != null) shape(soundRMSShape2);
      hint(ENABLE_DEPTH_TEST);
    }
}
