import KinectPV2.*;
KinectPV2 kinect;
import java.lang.Long;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Iterator;
import java.io.FileInputStream;

/*
 * Constants 
 */
final int DURATION  = 20;
final int FPS       = 16;
final int TOT_FRAMES = DURATION * FPS;
final int HEIGHT = 424;
final int WIDTH = 512;
final int NUM_PIXELS = WIDTH * HEIGHT; // num pixels per inner window
final int NUM_SECONDS_TO_PERSIST = 3;
final int NUM_JOINT_CHECKS = 9;
final String OUTPUT_FILENAME = "intersections.png";
final String INPUTFILE = "./test.txt";
final String INPUTFILE_JOINTS = "./testJoint.txt"; 

FileInputStream input;
FileInputStream inputJoints; 
int frameCounter = 0;
byte[] pixelLoaded = new byte[NUM_PIXELS*TOT_FRAMES];
byte[] jointsLoaded = new byte[NUM_JOINT_CHECKS*2*TOT_FRAMES]; 

// Constants for Joint Stuff
final double THRESHOLD = 0.1; 

byte[] NECK_RIGHT_OF_TORSO = new byte[2];
  
byte[] RIGHT_WRIST_ABOVE_RIGHT_ELBOW = new byte[2]; 
byte[] RIGHT_KNEE_RIGHT_OF_RIGHT_ANKLE = new byte[2]; 
byte[] RIGHT_WRIST_ABOVE_NECK = new byte[2];
byte[] RIGHT_WRIST_ABOVE_TORSO = new byte[2]; 

byte[] LEFT_WRIST_ABOVE_LEFT_ELBOW = new byte[2]; 
byte[] LEFT_KNEE_RIGHT_OF_LEFT_ANKLE = new byte[2]; 
byte[] LEFT_WRIST_ABOVE_NECK = new byte[2];
byte[] LEFT_WRIST_ABOVE_TORSO = new byte[2];


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
int intersectionHue = 0;

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

  // This prints out the path where the file is saved.
  // This code is just for debugging if running into filepath
  // problems, doesn't do anything significant functionally for the program.
  File directory = new File("./");
  System.out.println(directory.getAbsolutePath());  

  // Load in data
  try {
    input = new FileInputStream(INPUTFILE);
    print("Please wait patiently, loading file contents into memory.\n");
    int start = millis();
    input.read(pixelLoaded, 0, NUM_PIXELS*TOT_FRAMES);
    int end = millis();
    print("Loading of file contents took " + (end-start)/1000 + " seconds.\n");
    input.close();
  } catch(IOException ex) {
    ex.printStackTrace(); 
  }
  
  try {
    inputJoints = new FileInputStream(INPUTFILE_JOINTS);
    print("Please wait patiently, loading file contents into memory.\n");
    int start = millis();
    inputJoints.read(jointsLoaded, 0, NUM_JOINT_CHECKS*2*TOT_FRAMES);
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
    exit();
    return;
  }
 
  // Raw body data: 0-6 users 255 nothing
  int[] rawBodyData = kinect.getRawBodyTrack();
  int[] rawDepthData = kinect.getRawDepthData();

  // Normalize brightness level.
  // Amplify actual depth since we're only interested in
  // the body and throw away the rest of the data
  // (e.g. depth of things in the background, etc).
  float maxDepth = Float.MIN_VALUE;
  float minDepth = Float.MAX_VALUE;
  for (int i = 0; i < rawBodyData.length; i+=1){
    if (rawBodyData[i] != 255 && pixelLoaded[frameCounter*NUM_PIXELS + i]!= 0) {
      float diff = abs(rawDepthData[i] - pixelLoaded[frameCounter*NUM_PIXELS + i]);
      if (diff > maxDepth) {
        maxDepth = rawDepthData[i];
      }
      if (diff < minDepth) {
        minDepth = rawDepthData[i];
      }
    }
  } 
  
  float adjustedScale = maxDepth - minDepth;
  
  // Get your joint orientations: 
  KJoint[] joints;     
  ArrayList<KSkeleton> skeletonArray = kinect.getSkeletonColorMap(); 
  for(int i = 0; i < skeletonArray.size(); i++){
    KSkeleton skeleton = (KSkeleton) skeletonArray.get(i); 
    if(skeleton.isTracked()){
      joints = skeleton.getJoints(); 
      jointChecks(joints); 
    }
  }
  byte[] compareJoints = compareJoints();  
  print("compared joints. \n"); 
  // colour it some colour according to joints 

  // if right wrist is in same position (?)
  // make it some pink color 
  if(compareJoints[2]==1 && compareJoints[3]==1){
    print("making blue...\n"); 
    intersectionHue = 180;  
  }
  else{
    print("making red \n"); 
    intersectionHue = 360; 
  }
  
  // Next, adjust brightness according to normalized scale.
  for (int i = 0; i < rawBodyData.length; i+=1){
     
    // initialize pixel in justYou to black
    justYou.pixels[i] = BLACK;
    
    // Intersection
    if(rawBodyData[i] != 255 && pixelLoaded[frameCounter*NUM_PIXELS + i] != 0){
      // set colour for joint
      
      float brightness = 100*(1-(rawDepthData[i]-minDepth)/adjustedScale);
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
  } //<>//

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

/********************************************************
 * garbage helper functions
 ********************************************************/


byte[] compareJoints(){
  
  byte[] comparedJoints = new byte[NUM_JOINT_CHECKS*2]; 
  byte[] currJoints = getCurrJoints(); 
  for(int i = 0; i < NUM_JOINT_CHECKS*2; i++){
    comparedJoints[i] = xnor(currJoints[i], jointsLoaded[i + NUM_JOINT_CHECKS*2*frameCounter]); 
  } 
  
  return comparedJoints; 
}
byte xnor(int a, int b) {
  boolean a1 = (a != 0);
  boolean b1 = (b != 0);
  boolean xnor = !(a1 ^ b1); 
  return (byte) (xnor ? 1 : 0);
}

byte[] getCurrJoints(){
  
  byte[] currJoints = new byte[NUM_JOINT_CHECKS*2]; 
  currJoints[0] = NECK_RIGHT_OF_TORSO[0]; 
  currJoints[1] = NECK_RIGHT_OF_TORSO[1]; 
  
  currJoints[2] = RIGHT_WRIST_ABOVE_RIGHT_ELBOW[0];
  currJoints[3] = RIGHT_WRIST_ABOVE_RIGHT_ELBOW[1];
  currJoints[4] = LEFT_WRIST_ABOVE_LEFT_ELBOW[0];
  currJoints[5] = LEFT_WRIST_ABOVE_LEFT_ELBOW[1];
  
  currJoints[6] = RIGHT_KNEE_RIGHT_OF_RIGHT_ANKLE[0];
  currJoints[7] = RIGHT_KNEE_RIGHT_OF_RIGHT_ANKLE[1];
  currJoints[8] = LEFT_KNEE_RIGHT_OF_LEFT_ANKLE[0];
  currJoints[9] = LEFT_KNEE_RIGHT_OF_LEFT_ANKLE[1];
  
  currJoints[10] = RIGHT_WRIST_ABOVE_NECK[0];
  currJoints[11] = RIGHT_WRIST_ABOVE_NECK[1];
  currJoints[12] = LEFT_WRIST_ABOVE_NECK[0];
  currJoints[13] = LEFT_WRIST_ABOVE_NECK[1];
  
  currJoints[14] = RIGHT_WRIST_ABOVE_TORSO[0];
  currJoints[15] = RIGHT_WRIST_ABOVE_TORSO[1];
  currJoints[16] = LEFT_WRIST_ABOVE_TORSO[0];
  currJoints[17] = LEFT_WRIST_ABOVE_TORSO[1];   
  
  return currJoints; 
  
}

void jointChecks(KJoint[] joints){
  NECK_RIGHT_OF_TORSO = isCenterisRight(joints, KinectPV2.JointType_Neck, KinectPV2.JointType_SpineMid);
  
  RIGHT_WRIST_ABOVE_RIGHT_ELBOW = isCenterisAbove(joints, KinectPV2.JointType_WristRight, KinectPV2.JointType_ElbowRight); 
  RIGHT_KNEE_RIGHT_OF_RIGHT_ANKLE = isCenterisRight(joints, KinectPV2.JointType_KneeRight, KinectPV2.JointType_AnkleRight); 
  RIGHT_WRIST_ABOVE_NECK = isCenterisAbove(joints, KinectPV2.JointType_WristRight, KinectPV2.JointType_Neck);
  RIGHT_WRIST_ABOVE_TORSO = isCenterisAbove(joints, KinectPV2.JointType_WristRight, KinectPV2.JointType_SpineMid); 
  
  LEFT_WRIST_ABOVE_LEFT_ELBOW = isCenterisAbove(joints, KinectPV2.JointType_WristLeft, KinectPV2.JointType_ElbowLeft); 
  LEFT_KNEE_RIGHT_OF_LEFT_ANKLE = isCenterisRight(joints, KinectPV2.JointType_KneeLeft, KinectPV2.JointType_AnkleLeft); 
  LEFT_WRIST_ABOVE_NECK = isCenterisAbove(joints, KinectPV2.JointType_WristLeft, KinectPV2.JointType_Neck);
  LEFT_WRIST_ABOVE_TORSO = isCenterisAbove(joints, KinectPV2.JointType_WristLeft, KinectPV2.JointType_SpineMid);
}


byte[] isCenterisRight(KJoint[] joints, int jointType1, int jointType2){
  PVector orientation = getOrientation(joints, jointType1, jointType2); 
  
  boolean isCenter; 
  boolean isRight; 
  
  isCenter = abs(orientation.x)<THRESHOLD; 
  if(isCenter){
    isRight=false; 
  } 
  else{
    if(orientation.x>0) isRight = true;
    else isRight = false; 
  }
  
  byte isC = (byte) (isCenter ? 1 : 0); 
  byte isR = (byte) (isRight ? 1 : 0); 
  byte[] isCenterisRight = {isC, isR}; 
  return isCenterisRight;   
}

byte[] isCenterisAbove(KJoint[] joints, int jointType1, int jointType2){
  PVector orientation = getOrientation(joints, jointType1, jointType2); 
  
  boolean isCenter; 
  boolean isAbove; 
  
  isCenter = abs(orientation.y)<THRESHOLD; 
  if(isCenter){
    isAbove=false; 
  } 
  else{
    if(orientation.y>0) isAbove = true;
    else isAbove = false; 
  }
  
  byte isC = (byte) (isCenter ? 1 : 0); 
  byte isA = (byte) (isAbove ? 1 : 0); 
  byte[] isCenterisRight = {isC, isA}; 
  return isCenterisRight;  
}

PVector getOrientation(KJoint[] joints, int jointType1, int jointType2){
  // probably modify this function so it returns just boolean 
  PVector orientation = PVector.sub(joints[jointType1].getPosition(), joints[jointType2].getPosition()); 
  return orientation; 
}
