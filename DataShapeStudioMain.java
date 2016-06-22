// 3d sound spiral generator
//  by evan raskob evanraskob@gmail.com
// wave code uses code from http://code.google.com/p/musicg/
//
// Draw a base spiral and offset it by the sound volume (RMS)
//
// TODO

// - better lighting
// - fix overlay colors (TColor bug? Or PShape stroke bug?)
// - how about a REPL for commands instead of stupid key presses
// - need flat base for stand and for printing properly...
// - how about filling it to the max spikiness in between shapes, so it is recessed rather
// than filled?
// - or inner removal of material rather than exterior extrusion

import java.io.*;
import java.util.EnumMap;
import java.util.Iterator;
import toxi.geom.*;
import toxi.geom.mesh.TriangleMesh;
import toxi.geom.mesh.Mesh3D;
import toxi.geom.mesh.Face;
import toxi.math.*;
import toxi.volume.*;
import processing.core.PApplet;
import processing.core.PShape;
import processing.opengl.*;
import peasy.*;
import com.flkr.DataShapeStudio.*;
import com.flkr.DataShapeStudio.Scenes.*;
import com.musicg.wave.Wave;
import com.musicg.wave.WaveHeader;
import com.musicg.wave.extension.NormalizedSampleAmplitudes;

public class DataShapeStudioMain extends PApplet implements IStudioEventHandler {

	// don't think we need these anymore...
	static public enum SCENES 
	{
		LOAD_SCENE,
		RMS_SCENE,
		SCULPT_SCENE
	};

	// holds available scenes
	EnumMap<SCENES, AScene> sceneMap;

	// current loaded scene
	AScene currentScene;

	LoadingScene loadingScene;
	SculptingScene sculptingScene;


	
	boolean fileChosen = false;
	PrintWriter output, outputRMS;
	float[] soundAmplitudes;
	float[] rmsAmplitudes, rmsAmplitudes2;
	PShape soundAmpsShape = null, soundRMSShape = null, soundRMSShape2 = null;

	TriangleMesh mesh = null;

	boolean drawProfiles = false, drawVecs=false, drawPrinterBox=false, drawRMSOverlay=false;

	String wavFileName = "";
	int wavSampleRate = 1; // sample rate of Wave file
	//int RMSSize = (int)(48000*4.873*0.00125); // 1/500th of a second  CHANGEME!!!!!  Remember that 44100 is 1 sec
	// metal
	int RMSSize =1; // will be overriden in fileSelected() function

	//(int)(44100.0*12.0/(6.0*40.0)); // 1/500th of a second  CHANGEME!!!!!  Remember that 44100 is 1 sec
	// metal 22
	//int RMSSize = (int)(44100*2/turns / 100); // total length is 24.472 which encompasses 22 whole strides
	// with 100 rms divisions per 360 degrees (e.g. per turn)

	PeasyCam cam;

	private DataStore dataStore;

	


	// IStudioHandler
	public void loadData()
	{
		// TODO
		// triggers loading data into Data Store

		if (!fileChosen)
		{
			fileChosen = true;
			//background(0, 200, 0);
			selectInput("Select a file to process:", "fileSelected");
		}
	}

	
	public void setup()
	{
		size(1280, 720, P3D); 

		sculptingScene = new SculptingScene(this);
		
		sceneMap  = new EnumMap<SCENES,AScene>(SCENES.class);
		sceneMap.put(SCENES.LOAD_SCENE, new LoadingScene(this));
		// TODO
		//sceneMap.put(SCENES.RMS_SCENE, new RMSScene(this));
		sceneMap.put(SCENES.SCULPT_SCENE, sculptingScene);

		currentScene = sceneMap.get(SCENES.LOAD_SCENE);

		cam = new PeasyCam(this, 200);
		cam.setMinimumDistance(-5);
		cam.setMaximumDistance(200);
		cam.setResetOnDoubleClick(true);

		background(0);
		fill(200);
	}


	/*
	 * NOT ANYMORE!
	 * 
	 
	void drawOutVecs()
	{
		beginShape(LINES);
		noFill();
		strokeWeight(2);
		stroke(180, 255, 220);

		int i=0;

		for (Vec3D v : outwardVecs)
		{
			vertex(spiral.get(i));
			vertex(v.scale(10).add(spiral.get(i)));
			i++;
		}
		endShape();
	}
	*/
	

	public void draw()
	{
		currentScene.draw();
	} // end draw


	public void keyReleased()
	{
		currentScene.handleKeyRelease(key, this);
		
		
	/*
		if (key == '+')
		{
			noLoop();
			if (RMSSize < 10) ++RMSSize;
			else
				RMSSize *=1.1;
			//println("RMSSize:" + RMSSize);
			computeRMS();
			loop();
		} else if (key == '-')
		{
			noLoop();
			if (RMSSize < 10)
			{
				if (RMSSize > 1) --RMSSize;
			} else
				RMSSize /= 1.1;

			computeRMS();
			//println("RMSSize:" + RMSSize);
			loop();
		} else if (key == 'o')
		{
			drawRMSOverlay = !drawRMSOverlay;
		} else if (key == 'D')
		{
			noLoop();
			distanceBetweenSpirals *= 1.10;
			computeRMS();
			println("distanceBetweenSpirals:" + currentProperties.distanceBetweenSpirals);
			loop();
		} else if (key == 'd')
		{
			noLoop();
			distanceBetweenSpirals /= 1.10;
			computeRMS();
			println("distanceBetweenSpirals:" + currentProperties.distanceBetweenSpirals);
			loop();
		} else if (key == 'P')
		{
			noLoop();
			spikiness *= 1.10;
			computeRMS();
			println("spikiness:" + currentProperties.spikiness);
			loop();
		} else if (key == 'p')
		{
			noLoop();
			spikiness /= 1.10;
			computeRMS();
			println("spikiness:" + currentProperties.spikiness);
			loop();
		} else if (key == 'T')
		{
			noLoop();
			turns+=0.05;
			computeRMS();
			println("turns:" + currentProperties.turns);
			loop();
		} else if (key == 't')
		{
			noLoop();
			turns-=0.05;
			computeRMS();
			println("turns:" + currentProperties.turns);
			loop();
		} else if (key == 'h')
		{
			noLoop();
			spiralThickness/=1.1;
			computeRMS();
			println("spiralThickness:" + currentProperties.spiralThickness);
			loop();
		} else if (key == 'H')
		{
			noLoop();
			spiralThickness*=1.1;
			computeRMS();
			println("spiralThickness:" + currentProperties.spiralThickness);
			loop();
		} else if (key == 'm')
		{
			noLoop();
			minThickness/=1.1;
			computeRMS();
			println("minThickness:" + currentProperties.minThickness);
			loop();
		} else if (key == 'M')
		{
			noLoop();
			minThickness*=1.1;
			computeRMS();
			println("minThickness:" + currentProperties.minThickness);
			loop();
		} else if (key == 'a')
		{
			noLoop();
			adjust /= 1.2;
			computeRMS();
			println("adjust:" + currentProperties.adjust);
			loop();
		} else if (key == 'A')
		{
			noLoop();
			adjust *= 1.2;
			computeRMS();
			println("adjust:" + currentProperties.adjust);
			loop();
		} else if (key == 'r')
		{
			noLoop();
			spiralRadius /= 1.1;
			computeRMS();
			println("spiralRadius:" + currentProperties.spiralRadius);
			loop();
		} else if (key == 'R')
		{
			noLoop();
			spiralRadius *= 1.1;
			computeRMS();
			println("spiralRadius:" + currentProperties.spiralRadius);
			loop();
		} else if (key == 'z')
		{
			drawProfiles = !drawProfiles;
		} else if (key =='v')
		{
			drawVecs = !drawVecs;
		} else if (key == 'F')
		{
			// get first part of filename, ignore extension
			String[] wavname = split(wavFileName, '.');
			String fileName = new String(wavname[0]);
			if (fileName.length() > 8) fileName = fileName.substring(0,8);

			fileName = fileName +
					"--" + nf(hour(), 2) + "." + nf(minute(), 2) + "." + nf(second(), 2) +
					nf(turns,2,2) +"-" +
					nf(distanceBetweenSpirals,3,2) + "-" +
					nf(spiralThickness,3,2) + "-" +
					nf(spiralRadius,2,2) + "-" +
					nf(spikiness,3,2) + "-" +
					RMSSize + "-" +
					wavSampleRate/100 +
					".png" ;
			saveFrame(fileName);
		} else if (key == 's')
		{

			// get first part of filename, ignore extension
			String[] wavname = split(wavFileName, '.');
			String fileName = new String(wavname[0]);
			if (fileName.length() > 8) fileName = fileName.substring(0,8);

			fileName +=
					nf(currentProperties.turns,2,2) +"-" +
							nf(currentProperties.distanceBetweenSpirals,3,2) + "-" +
							nf(currentProperties.spiralThickness,3,2) + "-" +
							nf(currentProperties.spiralRadius,2,2) + "-" +
							nf(currentProperties.spikiness,3,2) + "-" +
							RMSSize + "-" +
							wavSampleRate/100 +
							".stl" ;
			fileName = dataPath(fileName);
			println("saving: " + fileName);
			mesh.saveAsSTL(fileName );

			println("saved: " + fileName);
		}
		*/
	}



	void fileSelected(File selection)
	{
		if (selection == null)
		{
			println("Window was closed or the user hit cancel.");
		} else
		{
			println("file selected " + selection.getAbsolutePath());
			wavFileName = selection.getName();

			InputStream inputStream = null;
			WaveHeader waveHeader = null;

			try {
				inputStream = new FileInputStream(selection.getAbsolutePath());
				waveHeader = new WaveHeader(inputStream);
			}
			catch (FileNotFoundException e) {
				e.printStackTrace();
			}


			if (waveHeader != null && waveHeader.isValid())
			{
				try
				{
					wavSampleRate = waveHeader.getSampleRate();
					println("sample rate:" + wavSampleRate);
					// load data

					byte[] data = new byte[inputStream.available()];
					inputStream.read(data);
					Wave wavFile = new Wave(waveHeader, data);
					//short[] amplitudes = wavFile.getSampleAmplitudes();
					NormalizedSampleAmplitudes nsa = new NormalizedSampleAmplitudes(wavFile);
					double[] amps = nsa.getNormalizedAmplitudes();
					soundAmplitudes = new float[amps.length];

					// initialize to 100ths
					RMSSize = max(1, amps.length/100);

					for (int i=0; i<amps.length; i++)
						soundAmplitudes[i] = (float) amps[i];

					println("found " + soundAmplitudes.length + " samples");
				}
				catch (Exception e)
				{
					println(e.getMessage());
					e.printStackTrace();
				}

				computeRMS();
				loop();
				// end load data
			} else {
				println("Invalid Wave Header");
			}

			if (inputStream != null)
			{
				try {
					inputStream.close();
				}
				catch (IOException e) {
					e.printStackTrace();
				}
			}

			// short version:
			// Open the wav file specified as the first argument
			//Wave wavFile = new Wave(selection.getAbsolutePath());
		}
		fileChosen = false; // reset for next time
		
		
		/*
	    //spiralShape = meshToRetained(mesh, helixColors, false);
	    spiralShape = ShapeUtils.meshToRetained(mesh, false);

	    // create profiles shape (for future visualisation)
	    profileShape = pathsToShape2(profilesOnCurve);
	    profileShape.noFill();
	    profileShape.setStroke(color(255, 80));
		 */
		
		TriangleMesh mesh = SoundSpiralMeshMaker.makeMesh(dataStore, properties);
		// TODO - retained shapes & draw

	}

// TODO: this goes in DataStore, choose a method first
// load unedited data into array then choose a tool to analyse and load into data store?
	
	void computeRMS()
	{
		println("RMS Size: " + RMSSize);

		ampMin = MAX_FLOAT;
		ampMax = MIN_FLOAT;

		rmsAmplitudes = new float[soundAmplitudes.length/RMSSize];
		rmsAmplitudes2 = new float[soundAmplitudes.length/RMSSize];

		// println("calculating " + rmsAmplitudes.length + " samples");

		int currentIndex = 0;
		int rmsArrayIndex = 0;

		while (rmsArrayIndex < rmsAmplitudes.length)
		{
			int samplesLeft = soundAmplitudes.length - currentIndex;
			if (samplesLeft < RMSSize)
			{
				// println("RMS calc done:" + samplesLeft);
				break; // stop loop!
			}

			int RMSIndex = 0;
			float RMSSum = 0, RMSSum2=0;
			float prevData = 0f;

			while (RMSIndex < RMSSize)
			{
				// convert data to float
				float data = (float)soundAmplitudes[currentIndex];
				float diffData = data - prevData;
				// debug
				/*if (rmsArrayIndex == rmsAmplitudes.length-1)
       {
       // println("data[" + currentIndex + "]=" + data);
       }*/
				RMSSum2 += diffData*diffData; // add square of data to sum
				RMSSum += data*data;
				currentIndex++;
				RMSIndex++;
				prevData = data;
			}

			// find average value - could also scale logarithmically
			float RMSAve = RMSSum / float(RMSSize);

			rmsAmplitudes[rmsArrayIndex] = sqrt(RMSAve);
			ampMin = min(ampMin, rmsAmplitudes[rmsArrayIndex]);
			ampMax = max(ampMax, rmsAmplitudes[rmsArrayIndex]);

			rmsAmplitudes2[rmsArrayIndex++] = sqrt(RMSSum2/float(RMSSize));



			//println("stored " + (rmsArrayIndex-1) + ":" + RMSAve);
		}

		println("ampMin:" + ampMin);
		println("ampMax:" + ampMax);

		float[] rmsAmplitudesExtended = new float[rmsAmplitudes.length*TWEEN_POINTS];  //leave room for end->start

		for (int i=0; i<rmsAmplitudes.length-1; i++)
		{
			for (int ii=0; ii < TWEEN_POINTS; ii++)
			{
				// calculate linear mix of two vectors
				float progress = (float)ii/(TWEEN_POINTS-1); // make sure it goes to 100%
				float tweenVal = tween.interpolate(rmsAmplitudes[i], rmsAmplitudes[i+1], progress); // get values btw 0 and 1
				rmsAmplitudesExtended[i*TWEEN_POINTS+ii] = tweenVal;
			}
		}
		// now start to finish
		float first = rmsAmplitudes[0];
		float last = rmsAmplitudes[rmsAmplitudes.length-1];

		for (int ii=0; ii < TWEEN_POINTS; ii++)
		{
			// calculate linear mix of two vectors
			float progress = (float)ii/(TWEEN_POINTS-1); // make sure it goes to 100%
			float tweenVal = tween.interpolate(last, first, progress); // get values btw 0 and 1
			rmsAmplitudesExtended[(rmsAmplitudes.length-1)*TWEEN_POINTS+ii] = tweenVal;
		}

		rmsAmplitudes = rmsAmplitudesExtended;
		createSpiral(mesh, false, true, true);
		createRMSVizShapes();

		// set color scheme
		//helixColors = helixColorTheme.getColors(numPoints);
		/*
		helixColorGrad.addColorAt(0, helixStartColor);
		helixColorGrad.addColorAt(mesh.getNumFaces(), helixEndColor);
		helixColors = helixColorGrad.calcGradient(0, mesh.getNumFaces());
		 */
		
	}


	void pvertex(PShape p, Vec3D v)
	{
		p.vertex(v.x(), v.y(), v.z());
	}

	void vertex(Vec3D v)
	{
		vertex(v.x(), v.y(), v.z());
	}

	void vertex(float[] v)
	{
		vertex(v[0], v[1], v[2]);
	}

	public void createRMSVizShapes()
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
}
