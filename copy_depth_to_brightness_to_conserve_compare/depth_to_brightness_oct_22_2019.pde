import KinectPV2.*;
KinectPV2 kinect;
import java.lang.Long;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Iterator;

/*
 * Constants 
 */
final int DURATION  = 20;
final int FPS       = 60;
final int TOT_FRAMES = DURATION * FPS;
final int HEIGHT = 424;
final int WIDTH = 512;
final int NUM_PIXELS = WIDTH * HEIGHT; // num pixels per inner window
final String FILENAME = "intersections.png";

BufferedReader input;
int frameCounter = 0;
int[][] pixelLoaded = new int[NUM_PIXELS][TOT_FRAMES];

int intersectionHue = 0;
int PREV_PERSON_HUE = 180;
int CURR_PERSON_HUE = 315;
int SATURATION = 100; // starts at 100 and then fades away
color[] lastPixels = new int[NUM_PIXELS]; // also the pixels that end up in output image
color[] fadedPixels = new int[NUM_PIXELS];

// Queue to fade body away
Deque<color[]> framesToFade = new ArrayDeque<color[]>();

// Images
PImage imgOne;
PImage imgFade;
PGraphics outputImage;

void setup() {
  // Change color mode
  colorMode(HSB, 360, 100, 100);
  size(1024, 848, P3D);
  
  imgOne = createImage(512, 424, PImage.RGB);
  imgFade = createImage(512, 424, PImage.ARGB); // includes transparency
  
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
      assert(pieces.length == NUM_PIXELS/8);
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
  
  // initialize lastPixels
  for (int i = 0; i < NUM_PIXELS; i += 1) {
    lastPixels[i] = color(0,0,0);
  }
  // make sure this call to frameRate is at the bottom of setup
  //frameRate(30);
}

void draw() {
  background(0);   
  
  // Before we deal with pixels
  imgOne.loadPixels(); 
  imgFade.loadPixels();
  
  // Initialize new blank intersection shape
  color[] currIntersectionPixels = new int[NUM_PIXELS];
  
  // Exit out if no more old footage
  if (frameCounter == TOT_FRAMES) {
    // save outputImgIntersectionPixels
    createOutputImage(lastPixels);
    exit();
    return;
  }
 
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
  intersectionHue = (intersectionHue + 1) % 360;
  // Next, adjust brightness according to normalized scale.
  for (int i = 0; i < rawBodyData.length; i+=1){
    currIntersectionPixels[i] = color(0,0,0,0); // initial pixel to be transparent
    // Intersection
    if(rawBodyData[i] != 255 && pixelLoaded[i][frameCounter] != 0){
      intersectionDetected = true;
      float brightness = 100*(1-(rawDepthData[i]-minDepth)/adjustedScale);
      color newColor = color(intersectionHue % 360, SATURATION, brightness);
      imgOne.pixels[i] = newColor;
      imgFade.pixels[i] = newColor;
      lastPixels[i] = newColor;
      currIntersectionPixels[i] = newColor;
    }
    // Current body
    else if (rawBodyData[i] != 255) {
      color newColor = color(CURR_PERSON_HUE % 360, 70, 80);
      imgOne.pixels[i] = newColor;
      imgFade.pixels[i] = newColor;
      currIntersectionPixels[i] = newColor;
    }
    else if (pixelLoaded[i][frameCounter] != 0) {
      color newColor = color(PREV_PERSON_HUE % 360, 70, 80);
      imgOne.pixels[i] = newColor;
      imgFade.pixels[i] = newColor;
      currIntersectionPixels[i] = newColor;
    } else {
    // load last scene's pixels
    imgOne.pixels[i] = lastPixels[i];
    imgFade.pixels[i] = fadedPixels[i];
    }
  }

  // Update faded pixels
  // Add latest intersection
  if (intersectionDetected) {
    framesToFade.addLast(currIntersectionPixels); // is the error something to do pass by reference not value?
  } else {
    framesToFade.addLast(new color[0]);
  }
  
  // Remove intersection shape if too many
  if (framesToFade.size() >= 30) { //<>//
    framesToFade.pollFirst();
  }
  Iterator<color[]> iter = framesToFade.descendingIterator();
  while (iter.hasNext()) {
    color[] shape = iter.next(); //<>//
    for (int i = 0; i < shape.length; i += 1) {
      color currPixel = shape[i];
      
      if (alpha(currPixel) > 0) {
        fadedPixels[i] = currPixel;
        
        // update the shape's fade for the next iteration
        float hue = hue(currPixel);
        float saturation = saturation(currPixel)-2;
        float brightness = min(10, brightness(currPixel)-2);
        float alpha = alpha(currPixel) - 0.01;
        shape[i] = color(hue, saturation, brightness, alpha); //<>//
      }
    }
  }

  // When we are finished dealing with pixels
  imgOne.updatePixels();
  imgFade.updatePixels();
  
  image(imgOne, 0, 0); // top left
  image(imgFade, 512, 0); // top right
  //image(imgOne, 0, 424); // bottom left
  //image(imgOne, 512, 424); // bottom right
  
  frameCounter++;
}

void createOutputImage(color[] outputPixels) {
    outputImage = createGraphics(WIDTH, HEIGHT);
    outputImage.beginDraw();
    outputImage.loadPixels();
    for (int i = 0; i < outputPixels.length; i += 1) {
      outputImage.pixels[i] = outputPixels[i];
    }
    outputImage.updatePixels();
    outputImage.save(FILENAME);
    
}
