
void createRMSVizShapes()
{
  colorMode(RGB);
  
  soundAmpsShape = createShape(); 
  soundAmpsShape.enableStyle();
  soundAmpsShape.beginShape();
  
  soundAmpsShape.strokeWeight(1);
  soundAmpsShape.noFill();
  //soundAmpsShape.stroke(waveDataColor.toARGB());
  soundAmpsShape.stroke(255,10,20,165);

  float yPos = -height/2f;
  //float yPos = 0f;
  Vec3D v = new Vec3D((float)-width, yPos, 0f);

  float widthInc = (width*2f)/soundAmplitudes.length;

  for (int i=0; i < soundAmplitudes.length; i++)
  { 
    v.setY( height-(soundAmplitudes[i]+1f)*height);
    pvertex(soundAmpsShape, v);
    v.addSelf(widthInc, 0, 0);
  }
  soundAmpsShape.endShape();

  soundRMSShape = createShape();
  soundRMSShape.beginShape();
  soundRMSShape.enableStyle();
  soundRMSShape.strokeWeight(3.5);
  soundRMSShape.noFill();
  //soundRMSShape.stroke(RMSColor.toARGB());
  soundRMSShape.stroke(105,64,255);
  

  //yPos = -yPos;
  v.set(-width, yPos, 0);

  widthInc = (width*2f)/rmsAmplitudes.length;

  for (int i=0; i < rmsAmplitudes.length; i++)
  { 
    v.setY( -rmsAmplitudes[i]*height*2f);
    pvertex(soundRMSShape, v);
    v.addSelf(widthInc, 0, 0);
  }
  soundRMSShape.endShape();


  soundRMSShape2 = createShape();
  soundRMSShape2.beginShape();
  soundRMSShape2.enableStyle();
  soundRMSShape2.strokeWeight(3.5);
  //soundRMSShape2.stroke(RMSVelColor.toARGB());
  soundRMSShape2.stroke(20,30,204);
  
  soundRMSShape2.noFill();

  //yPos = -yPos;
  v.set(-width, yPos, 0);

  widthInc = (width*2f)/rmsAmplitudes2.length;

  for (int i=0; i < rmsAmplitudes2.length; i++)
  { 
    v.setY( -rmsAmplitudes2[i]*height*4f);
    pvertex(soundRMSShape2, v);
    v.addSelf(widthInc, 0, 0);
  }
  soundRMSShape2.endShape();
}


PShape meshToRetained(Mesh3D mesh, boolean smth) {        
  PShape retained = createShape();
  
  retained.beginShape(TRIANGLES);
  retained.enableStyle();
  mesh.computeFaceNormals();
  
  if (smth) 
  {  
    mesh.computeVertexNormals();

    for (Face f : mesh.getFaces ()) {
      retained.normal(f.a.normal.x, f.a.normal.y, f.a.normal.z);
      retained.vertex(f.a.x, f.a.y, f.a.z);
      retained.normal(f.b.normal.x, f.b.normal.y, f.b.normal.z);
      retained.vertex(f.b.x, f.b.y, f.b.z);
      retained.normal(f.c.normal.x, f.c.normal.y, f.c.normal.z);
      retained.vertex(f.c.x, f.c.y, f.c.z);
    }
  } else {
    int i=0;
    for (Face f : mesh.getFaces ()) {
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




PShape pathsToShape( ArrayList<LineStrip3D> paths)
{
  PShape retained = createShape();

  retained.enableStyle();
  retained.beginShape(LINES);
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

PShape pathsToShape2( ArrayList<LineStrip3D2> paths)
{
  PShape retained = createShape();

  retained.enableStyle();
  retained.beginShape(LINES);
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