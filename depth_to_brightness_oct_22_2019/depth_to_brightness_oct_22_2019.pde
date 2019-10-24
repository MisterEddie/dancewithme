import KinectPV2.*;
KinectPV2 kinect;
import java.lang.Long;

/*
 * Constants 
 */
final int duration  = 20;
final int fps       = 60;
final int totframes = duration * fps;
final int numPixels = 512 * 424;

BufferedReader input;
int frameCounter = 0;
int[][] pixelLoaded = new int[numPixels][totframes];

int intersectionHue = 45;
int PREV_PERSON_HUE = 180;
int CURR_PERSON_HUE = 315;
int SATURATION = 100; // always 100% saturated
color[] lastPixels = new int[512*424];
color[] intersectionPixels = new int[512*424];

void setup() {
  // Change color mode
  colorMode(HSB, 360, 100, 100);
  size(512, 424, P3D);
  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.enableDepthImg(true);
  kinect.init();
  
  // Load in data
  input = createReader("../intersection_efficient_write/printwriter/test.txt");  
  print("Please wait patiently, loading file contents into memory.\n");
  int start = millis();
  String line = null;
  try {
    int linecount = 0;
    while ((line = input.readLine()) != null) {
      String[] pieces = split(line.trim()," ");  
      assert(pieces.length == numPixels/8);
      int pixelcount = 0;
      for (String entry : pieces) {
        pixelLoaded[pixelcount][linecount] = byte((Long.parseLong(entry) >> 56) & 0xFF);
        pixelLoaded[pixelcount+1][linecount] = byte((Long.parseLong(entry) >> 48) & 0xFF);
        pixelLoaded[pixelcount+2][linecount] = byte((Long.parseLong(entry) >> 40) & 0xFF);
        pixelLoaded[pixelcount+3][linecount] = byte((Long.parseLong(entry) >> 32) & 0xFF);
        pixelLoaded[pixelcount+4][linecount] = byte((Long.parseLong(entry) >> 24) & 0xFF);
        pixelLoaded[pixelcount+5][linecount] = byte((Long.parseLong(entry) >> 16) & 0xFF);
        pixelLoaded[pixelcount+6][linecount] = byte((Long.parseLong(entry) >>  8) & 0xFF);
        pixelLoaded[pixelcount+7][linecount] = byte(Long.parseLong(entry) & 0xFF);
        pixelcount+=8;
      }
      linecount++;
    }
    input.close();
  } catch(IOException e) {
    e.printStackTrace(); 
  }
  int end = millis();
  print("Loading of file contents took " + (end-start)/1000 + " seconds.\n");
}

void draw() {
  background(0);   
  
  // Before we deal with pixels
  loadPixels();  
  // load last scene's pixels
  for (int i = 0; i < pixels.length; i+=1) {
    pixels[i] = lastPixels[i];
  }
  
  // Exit out if no more old footage
  if (frameCounter == totframes) {
    // save intersectionPixels
    save("intersections.png");
    exit();
    return;
  }
  
  // intersectionPixels holds temp pixels to overwrite
  // if new intersection is detected during this loop.
  intersectionPixels = lastPixels;
  

  //raw body data 0-6 users 255 nothing
  int [] rawBodyData = kinect.getRawBodyTrack();
  int[] rawDepthData = kinect.getRawDepthData();

  // Normalize brightness level.
  // Amplify actual depth since we're only interested in
  // the body and throw away the rest of the data
  // (e.g. depth of things in the background, etc).
  float maxDepth = Float.MIN_VALUE;
  float minDepth = Float.MAX_VALUE;
  for (int i = 0; i < rawBodyData.length; i+=1){
    if (rawBodyData[i] != 255 && pixelLoaded[i][frameCounter]!= 0) {
      float diff = abs(rawDepthData[i] - pixelLoaded[i][frameCounter]);
      if (diff > maxDepth) {
        maxDepth = rawDepthData[i];
      }
      if (diff < minDepth) {
        minDepth = rawDepthData[i];
      }
    }
  } 
  
  float adjustedScale = maxDepth - minDepth;
  boolean intersectionDetected = false;
  intersectionHue = int(random(10, 350));
  // Next, adjust brightness according to normalized scale.
  for (int i = 0; i < rawBodyData.length; i+=1){
    intersectionDetected = false;
    // Intersection
    if(rawBodyData[i] != 255 && pixelLoaded[i][frameCounter] != 0){
      intersectionDetected = true;
      float brightness = 100*(1-(rawDepthData[i]-minDepth)/adjustedScale);
      color newColor = color(intersectionHue % 360, SATURATION, brightness);
      pixels[i] = newColor;
      intersectionPixels[i] = newColor;
    }
    // Current body
    else if (rawBodyData[i] != 255) {
      color newColor = color(CURR_PERSON_HUE % 360, 70, 80);
      pixels[i] = newColor;
    }
    else if (pixelLoaded[i][frameCounter] != 0) {
      color newColor = color(PREV_PERSON_HUE % 360, 70, 80);
      pixels[i] = newColor;
    }
  }
  if (intersectionDetected) {
    for (int i = 0; i < pixels.length; i+=1) {
      lastPixels[i] = intersectionPixels[i];
    }
  }

  // When we are finished dealing with pixels
  updatePixels();
  frameCounter++;
}
