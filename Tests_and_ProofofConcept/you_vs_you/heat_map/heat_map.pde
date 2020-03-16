import KinectPV2.*;
KinectPV2 kinect;
import java.lang.Long;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Map;

HashMap<Integer, Integer> heat_map = new HashMap<Integer, Integer>();

/*
 * Constants 
 */
final int duration  = 30;
final int fps       = 16;
final int totframes = duration * fps;
final int numPixels = 512 * 424;
final String writepath = "./test.txt";

FileOutputStream stream;
int counter = 0;
byte[] pixelSave = new byte[totframes*numPixels];

color[] prevColor = new color[numPixels];

PImage img;
PImage himg;
PImage outimg;

void setup() {
  img = createImage(512, 424, PImage.RGB);
  himg = createImage(512, 424, PImage.RGB);
  outimg = createImage(512, 424, PImage.RGB);
  colorMode(HSB, 360, 100, 100);

  size(1024, 848, P3D);
  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.enableDepthImg(true);
  kinect.init();
  try {
    stream = new FileOutputStream(writepath);
  } 
  catch (IOException ex) {
    ex.printStackTrace();
  }
  frameRate(fps);
  for (int i = 0; i < numPixels; i++) {
    heat_map.put(i, 0);
  }
}

void draw() {
  img.loadPixels();
  himg.loadPixels();
  background(0);

  /*
     * This code is executed after all frames have been saved to local memory.
   */
  if (counter == totframes) {   
    try {
      int start = millis();        
      stream.write(pixelSave, 0, totframes*numPixels);
      int end = millis();
      print("Total time to save is " + (end-start)/1000 + " seconds.\n");
      stream.close();
    } 
    catch (IOException ex) {
    }

    /* 
     * These set of statements TOGETHER will exit the program immediately
     */
    exit();
    return;
  }

  /*
     * Main loop code
   */
  int [] rawData = kinect.getRawBodyTrack();
  int [] rawdepthData = kinect.getRawDepthData();

  int broken = 1;
  while (broken == 1)
  {
    rawData = kinect.getRawBodyTrack();
    for (int i = 0; i < numPixels; i++)
    {
      if (rawData[i] != 255) {
      } else {
        broken=0;
      }
    }
  }

  assert(rawData.length == numPixels);
  for (int i = 0; i < numPixels; i++) {

    if (rawData[i] != 255) {
      heat_map.put(i, heat_map.get(i)+1);
      int depth = rawdepthData[i] * 256 / 4000;
      color newColor = color(0, 100, 100);
      color hcolor = color(heat_map.get(i)*360*1.3/totframes, 100, 100);
      img.pixels[i] = newColor;        
      himg.pixels[i] = hcolor;

      // Save the data to the 2D array.
      pixelSave[counter*numPixels + i] = byte(depth);
    } else {

      color hncolor = color(heat_map.get(i), 0, 0);
      himg.pixels[i] = hncolor;
      img.pixels[i] = color(0, 0, 0);
      //himg.pixels[i] = color(0, 0, 0); //can comment this out so we can see everything in real time.
    }
    if (counter%1 == 0 ) {
      if (heat_map.get(i) < 5) {
        //print("if");
        outimg.pixels[i] = color(0, 0, 0);
      } else {
        //print("else");
        outimg.pixels[i] = color(heat_map.get(i)*360*1.3/totframes, 100, 100);
      }
    }
  }

  img.updatePixels();
  himg.updatePixels();
  outimg.updatePixels();
  image(img, 0, 0);
  image(himg, 512, 0);
  image(outimg, 512, 424);
  counter++;
}
