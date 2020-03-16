import KinectPV2.*;
KinectPV2 kinect;
import java.lang.Long;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Iterator;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.Arrays; 

/*
 * General Constants 
 */
final int DURATION  = 20;
final int FPS       = 16;
final int TOT_FRAMES = DURATION * FPS;
final int HEIGHT = 424;
final int WIDTH = 512;
final int NUM_PIXELS = WIDTH * HEIGHT; // num pixels per inner window
final int NUM_SECONDS_TO_PERSIST = 3;
final String OUTPUT_FILENAME = "intersections.png";

// Dynamic frameCounter variable
int frameCounter = 0;

// Associated with depth 
FileInputStream input;
FileOutputStream output;
final String IOFILE_DEPTH = "./testDepth.txt";
byte[] pixelLoaded = new byte[NUM_PIXELS*TOT_FRAMES];
byte[] pixelToSave = new byte[NUM_PIXELS*TOT_FRAMES];

// Associated with joints
FileInputStream inputJoints;
FileOutputStream outputJoints;
final String IOFILE_JOINTS = "./testJoint.txt";
final int NUM_JOINT_CHECKS = 16;
byte[] jointsLoaded = new byte[NUM_JOINT_CHECKS*TOT_FRAMES]; 
JointChecks jntchks;

// Associated with median filtering 
MedianFilter curr;
int[] pixelTemp = new int[NUM_PIXELS];
final int MFILTERORDER = 2;

// Colors
final int MAX_SATURATION = 100; // starts at 100 and then fades away
final int PREV_PERSON_HUE = 180;
final int CURR_PERSON_HUE = 315;

// define these in setup() after setting colorMode
color PREV_PERSON_COLOR = color(PREV_PERSON_HUE, 60, 80);
color CURR_PERSON_COLOR = color(CURR_PERSON_HUE, 60, 80);
color PREV_PERSON_COLOR_FADE = color(PREV_PERSON_HUE, 40, 50);
color CURR_PERSON_COLOR_FADE = color(CURR_PERSON_HUE, 40, 50);
color BLACK = color(0,0,0);

/*******************************************
* Helper arrays to store data about pixels.
********************************************/
// Pixels in output image for youAndPrev
color[] youAndPrevIntersectionPixels = new color[NUM_PIXELS]; // pixels that end up in output image
// Pixels to fade out shapes for youAndPrev
color[] fadedPixels = new color[NUM_PIXELS];
// Array of counters to determine when to start fading out intersection shapes
// in youAndPrev. This allows the intersection shapes to stay on the screen for the
// number of seconds set in NUM_SECONDS_TO_PERSIST before the shape begins to fade.
int[] fadeIntersectionCounter = new int[NUM_PIXELS];

// Images shown on screen
PImage justYou;
PImage youAndPrev;
PImage youAndPrevOutputImage;

// Output images
PGraphics outputImage;

// TEMP: replace with joint similarity color
int intersectionHue;

void setup() {
  // Must use numbers in calls to size(), not variables
  size(1536, 848, P3D);
  
  // Create images
  justYou = createImage(WIDTH, HEIGHT, PImage.RGB);
  youAndPrev = createImage(WIDTH, HEIGHT, PImage.RGB);
  youAndPrevOutputImage = createImage(WIDTH, HEIGHT, PImage.RGB);
  
  // Change color mode
  colorMode(HSB, 360, 100, 100);
  
  // Set colors
  PREV_PERSON_COLOR = color(PREV_PERSON_HUE, 60, 80);
  CURR_PERSON_COLOR = color(CURR_PERSON_HUE, 60, 80);
  PREV_PERSON_COLOR_FADE = color(PREV_PERSON_HUE, 40, 50);
  CURR_PERSON_COLOR_FADE = color(CURR_PERSON_HUE, 40, 50);
  BLACK = color(0,0,0);

  // Initialize Kinect
  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.enableDepthImg(true);
  kinect.enableSkeletonColorMap(true); 
  kinect.init();

  // Create MedianFilter object
  curr = new MedianFilter(NUM_PIXELS, TOT_FRAMES, HEIGHT, WIDTH, MFILTERORDER);

	// Create JointChecks object
	jntchks = new JointChecks(TOT_FRAMES, kinect, NUM_JOINT_CHECKS);

  // Prints filepath save directory. For debugging purposes.
  File directory = new File("./");
  System.out.println(directory.getAbsolutePath());  

  // Load in depth data
  try {
    input = new FileInputStream(IOFILE_DEPTH);
    print("Please wait patiently, loading file contents into memory.\n");
    int start = millis();
    input.read(pixelLoaded, 0, NUM_PIXELS*TOT_FRAMES);
    int end = millis();
    print("Loading of file contents took " + (end-start)/1000 + " seconds.\n");
    input.close();
  } catch(IOException ex) {
    ex.printStackTrace(); 
  }
  
  // Load in joints data
  try {
    inputJoints = new FileInputStream(IOFILE_JOINTS);
    print("Please wait patiently, loading file contents into memory.\n");
    int start = millis();
    inputJoints.read(jointsLoaded, 0, NUM_JOINT_CHECKS*TOT_FRAMES);
    int end = millis();
    print("Loading of joints file contents took " + (end-start)/1000 + " seconds.\n");
    inputJoints.close();
  } catch(IOException ex) {
    ex.printStackTrace(); 
  }

  // Initialize pixels in helper arrays
  for (int i = 0; i < NUM_PIXELS; i += 1) {
    youAndPrevIntersectionPixels[i] = BLACK;
    fadedPixels[i] = BLACK;
    fadeIntersectionCounter[i] = 0;
  }
  // make sure this call to frameRate is at the bottom of setup
  frameRate(16);
}

void draw() {
  // Load pixels for all images
  justYou.loadPixels();
  youAndPrevOutputImage.loadPixels(); 
  youAndPrev.loadPixels();
  
  // Exit out if no more old footage
  if (frameCounter == TOT_FRAMES) {
    // save outputImgIntersectionPixels
    createOutputImage(youAndPrevIntersectionPixels, OUTPUT_FILENAME);
    createOutputImage(fadedPixels, "fade.png");
    
    // Save depth data
    try {
      print("Writing file to memory\n");
      output = new FileOutputStream(IOFILE_DEPTH);
      output.write(pixelToSave, 0, NUM_PIXELS*TOT_FRAMES);
      output.close();
      print("Done writing file to memory\n");
    } catch (IOException ex) {
     ex.printStackTrace(); 
    }
    
    // Save joint data
    try {
      outputJoints = new FileOutputStream(IOFILE_JOINTS);
      int start = millis();        
      outputJoints.write(jntchks.getJointChecks(), 0, TOT_FRAMES*NUM_JOINT_CHECKS);
      int end = millis();
      print("Total time to save joints is " + (end-start)/1000 + " seconds.\n");
      outputJoints.close();
      print("Stream joint closed. \n"); 
    } catch (IOException ex) {}
    print("Ready to exit and close. \n"); 
    
    exit();
    return;
  }
 
  // Raw body data: 0-6 users 255 nothing
  int[] rawBodyData = kinect.getRawBodyTrack();
  int[] rawDepthData = kinect.getRawDepthData();
  
  // Median filter the rawBodyData array.
  int off = 0;
  int[] rawBodyDataUnfiltered = rawBodyData;
  curr.filterFrame(rawBodyData, pixelTemp, rawDepthData, off); //<>//
  rawBodyData = pixelTemp;
  
  // Extract joint data
  jntchks.runJointChecks();
  jntchks.storeJointChecks(frameCounter);
  jntchks.storeFrameJointChecks();
  byte[] compareJoints = jntchks.compareJoints(jointsLoaded, frameCounter);
  // Map joint similarities to colour
  intersectionHue = colorMap_countZeroes2(compareJoints);  

  // Normalize brightness level.
  // Amplify actual depth since we're only interested in
  // the body and throw away the rest of the data
  // (e.g. depth of things in the background, etc).
  float maxDepth = Float.MIN_VALUE;
  float minDepth = Float.MAX_VALUE;
  for (int i = 0; i < rawBodyData.length; i+=1){
    
    //////////////////////////////////////////////////
    // Save current user's depth for the next run
    // Sorry couldn't find a better place to put the code 
    // at the moment so shoving it randomly here.
    if(rawBodyData[i] != 255) {
      int depth = rawDepthData[i]*256/4000;
      pixelToSave[frameCounter*NUM_PIXELS + i] = byte(depth);
    }
  }
    //////////////////////////////////////////////////
    
  //  if (rawBodyDataUnfiltered[i] != 255 && pixelLoaded[frameCounter*NUM_PIXELS + i]!= 0) {
  //    float diff = abs(rawDepthData[i] - pixelLoaded[frameCounter*NUM_PIXELS + i]);
  //    if (diff > maxDepth) {
  //      maxDepth = rawDepthData[i];
  //    }
  //    if (diff < minDepth) {
  //      minDepth = rawDepthData[i];
  //    }
  //  }
  //} 
  
  //float adjustedScale = maxDepth - minDepth;
  
  // if right wrist is in same position (?)
  // make it some pink color 
  //if(compareJoints[2]==1){
  //  print("making blue...\n"); 
  //  if (frameCounter == 100) {
  //    print("hello");
  //  }
  //  intersectionHue = 180;  
  //}
  //else{
  //  print("making red \n"); 
  //  intersectionHue = 360; 
  //}
  
  // TEMP: replace with joint similarity color
  //intersectionHue = (intersectionHue + 1) % 360;
  
  // Next, adjust brightness according to normalized scale.
  for (int i = 0; i < rawBodyData.length; i+=1){
     
    // initialize pixel in justYou to black
    justYou.pixels[i] = BLACK;
    
    // Intersection
    if(rawBodyData[i] != 255 && pixelLoaded[frameCounter*NUM_PIXELS + i] != 0){
      float brightness = 100*(1-(rawDepthData[i]-minDepth));
      // Start intersection color off at max saturation
      color newColor = color(intersectionHue % 360, MAX_SATURATION, brightness);
      
      // Color justYou
      justYou.pixels[i] = CURR_PERSON_COLOR;
      
      // Color youAndPrev
      youAndPrev.pixels[i] = newColor;
      youAndPrevOutputImage.pixels[i] = newColor;
      youAndPrevIntersectionPixels[i] = newColor;
      
      // reset fade intersection counter
      fadeIntersectionCounter[i] = FPS*NUM_SECONDS_TO_PERSIST;
      // make the intersection fade off less quickly
      fadedPixels[i] = newColor;
      

    }
    // Current body, no intersection
    else if (rawBodyData[i] != 255) {      
      // Color justYou
      justYou.pixels[i] = CURR_PERSON_COLOR;
      
      // Color youAndPrev
      youAndPrev.pixels[i] = CURR_PERSON_COLOR;
      // make bodies fade off more quickly by starting at lower brightness
      // but preserve the colors of intersections
      if (fadeIntersectionCounter[i] == 0) {
        fadedPixels[i] = CURR_PERSON_COLOR_FADE;
      }
    }
    // Previous body, no intersection
    else if (pixelLoaded[frameCounter*NUM_PIXELS + i] != 0) {
      youAndPrev.pixels[i] = PREV_PERSON_COLOR;
      if (fadeIntersectionCounter[i] == 0) {
        fadedPixels[i] = PREV_PERSON_COLOR_FADE;
      }
    }
    // No body detected at that pixel
    else {
      // For youAndPrev, fade away pixels from previous scene
      color lastFadeColor = fadedPixels[i];
      // Fade the pixel if it should be faded away.
      if (fadeIntersectionCounter[i] == 0) {
        youAndPrev.pixels[i] = lastFadeColor;
        float newHue = hue(lastFadeColor);
        float newSaturation = max(0, saturation(lastFadeColor)-1.0);
        float newBrightness = max(0, brightness(lastFadeColor)-2.0);
        color newColor = color(newHue, newSaturation, newBrightness);
        youAndPrev.pixels[i] = newColor;
        fadedPixels[i] = newColor;
      }
      // Otherwise, update the counter and display the
      // the intersection shape.
      else {
        fadeIntersectionCounter[i] -= 1;
        youAndPrev.pixels[i] = youAndPrevIntersectionPixels[i];
      }
    }
  }

  // Call updatePixels() for all images after they have been updated.
  justYou.updatePixels();
  youAndPrev.updatePixels();
  youAndPrevOutputImage.updatePixels();
  
  // Render images
  image(justYou, 0, 0); // top left
  // This is where the heatmap stuff should go
  // image(youAndPrevOutputImage, 0, 424); // bottom left
  image(youAndPrev, WIDTH, 0); // top middle
  image(youAndPrevOutputImage, WIDTH, HEIGHT); // bottom middle
  image(youAndPrev, WIDTH*2, 0); // top right
  image(youAndPrevOutputImage, WIDTH*2, HEIGHT); // bottom right
  
  frameCounter++; 
}

void createOutputImage(color[] outputPixels, String filename) {
    outputImage = createGraphics(WIDTH, HEIGHT);
    outputImage.beginDraw();
    outputImage.loadPixels();
    for (int i = 0; i < outputPixels.length; i += 1) {
      outputImage.pixels[i] = outputPixels[i];
    }
    outputImage.updatePixels();
    outputImage.save(filename);
    
}


// Some methods for mapping joint similarity to colour: 

int colorMap_countZeroes2(byte[] compareJoints){
  // try to make colours less green  
  int sum = 0; 
  for(int i = 0; i < compareJoints.length; i++){
    sum += compareJoints[i]; 
  }
  sum = NUM_JOINT_CHECKS - sum; 
  print("sum: " + sum + "\n");  
  // hard code some bs for shits and gigs 
  if (sum==0) intersectionHue = 0; 
  else if (sum==1) intersectionHue = 20; 
  else if (sum==2) intersectionHue = 40; 
  else if (sum==3) intersectionHue = 50; 
  else if (sum==4) intersectionHue = 60; 
  else if (sum==5) intersectionHue = 75; 
  else if (sum==6) intersectionHue = 90; 
  else if (sum==7) intersectionHue = 120; 
  else if (sum==8) intersectionHue = 145; 
  else if (sum==9) intersectionHue = 170; 
  else if (sum==10) intersectionHue = 185; 
  else if (sum==11) intersectionHue = 205; 
  else if (sum==12) intersectionHue = 260; 
  else if (sum==13) intersectionHue = 280; 
  else if (sum==14) intersectionHue = 320; 
  print("intersectionhue: " + intersectionHue + "\n" + "\n"); 
  return intersectionHue; 
}
int colorMap_countOnes2(byte[] compareJoints){
  // try to make colours less green  
  int sum = 0; 
  for(int i = 0; i < compareJoints.length; i++){
    sum += compareJoints[i]; 
  }
  print("sum: " + sum + "\n");  
  // hard code some bs for shits and gigs 
  if (sum==0) intersectionHue = 0; 
  else if (sum==1) intersectionHue = 20; 
  else if (sum==2) intersectionHue = 40; 
  else if (sum==3) intersectionHue = 50; 
  else if (sum==4) intersectionHue = 60; 
  else if (sum==5) intersectionHue = 75; 
  else if (sum==6) intersectionHue = 90; 
  else if (sum==7) intersectionHue = 120; 
  else if (sum==8) intersectionHue = 145; 
  else if (sum==9) intersectionHue = 170; 
  else if (sum==10) intersectionHue = 185; 
  else if (sum==11) intersectionHue = 205; 
  else if (sum==12) intersectionHue = 260; 
  else if (sum==13) intersectionHue = 280; 
  else if (sum==14) intersectionHue = 320; 
  print("intersectionhue: " + intersectionHue + "\n" + "\n"); 
  return intersectionHue; 
}

int colorMap_countZeroes(byte[] compareJoints){
  // colours tend to green 
  int sum = 0; 
  for(int i = 0; i < compareJoints.length; i++){
    sum += compareJoints[i]; 
  }
  print("sum: " + sum + "\n");
  float n_zeros = (float) (NUM_JOINT_CHECKS - sum); 
  float scale = 360 / (float) (NUM_JOINT_CHECKS);
  intersectionHue = (int) (n_zeros * scale); 
  print("intersectionhue: " + intersectionHue + "\n" + "\n"); 
  return intersectionHue; 
}

int colorMap_countOnes(byte[] compareJoints){  
  // colours tend to blue/purple/violet with this one 
  int sum = 0; 
  for(int i = 0; i < compareJoints.length; i++){
    sum += compareJoints[i]; 
  }
  print("sum: " + sum + "\n");
  float n_ones = (float) (sum); 
  float scale = 360 / (float) (NUM_JOINT_CHECKS);
  intersectionHue = (int) (n_ones * scale); 
  print("intersectionhue: " + intersectionHue + "\n" + "\n"); 
  return intersectionHue; 
}

int colorMap_binary(byte[] compareJoints){
  
  float sum = 0; 
  float scale = 360 / 2^(compareJoints.length); 
  for(int i = 0; i < compareJoints.length; i++){
    sum += 2^compareJoints[i]; 
  }
  intersectionHue = (int) (sum * scale); 
  
  return intersectionHue; 
}
