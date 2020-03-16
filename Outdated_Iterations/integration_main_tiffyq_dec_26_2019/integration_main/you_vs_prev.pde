import KinectPV2.*;
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
final int YP_DURATION  = 10;
final int YP_FPS       = 16;
final int YP_TOT_FRAMES = YP_DURATION * YP_FPS;
int YP_HEIGHT = 424; 
int YP_WIDTH = 512;
int YP_NUM_PIXELS = YP_HEIGHT * YP_WIDTH; // num pixels per inner window
final int YP_NUM_SECONDS_TO_PERSIST = 2;
final String YP_OUTPUT_FILENAME = "2youvsprevious";
final int YP_NUM_SECONDS_OF_FADE = 5;
final int YP_START_FADE = (YP_DURATION-YP_NUM_SECONDS_OF_FADE) * YP_FPS; // when to start fading out live image

// Dynamic frameCounter variable
int YP_frameCounter = 0;

// Associated with depth 
FileInputStream YP_input;
FileOutputStream YP_output;
final String YP_IOFILE_DEPTH = "./testDepth.txt";
byte[] YP_pixelLoaded = new byte[YP_NUM_PIXELS*YP_TOT_FRAMES];
byte[] YP_pixelToSave = new byte[YP_NUM_PIXELS*YP_TOT_FRAMES];

// Associated with joints
FileInputStream YP_inputJoints;
FileOutputStream YP_outputJoints;
final String YP_IOFILE_JOINTS = "./testJoint.txt";
final int YP_NUM_JOINT_CHECKS = 16;
byte[] YP_jointsLoaded = new byte[YP_NUM_JOINT_CHECKS*YP_TOT_FRAMES]; 
JointChecks YP_jntchks;

// Associated with median filtering 
MedianFilter YP_curr;
int[] YP_pixelTemp = new int[YP_NUM_PIXELS];
final int YP_FILTERORDER = 2;

// Colors
final int YP_MAX_SATURATION = 100; // starts at 100 and then fades away
final int YP_PREV_PERSON_HUE = 180;
final int YP_CURR_PERSON_HUE = 340;

// define these in setup() after setting colorMode
color YP_PREV_PERSON_COLOR = color(YP_PREV_PERSON_HUE, 60, 80);
color YP_CURR_PERSON_COLOR = color(YP_CURR_PERSON_HUE, 100, 80);
color YP_PREV_PERSON_COLOR_FADE = color(YP_PREV_PERSON_HUE, 40, 50);
color YP_CURR_PERSON_COLOR_FADE = color(YP_CURR_PERSON_HUE, 40, 50);
color YP_BLACK = color(0,0,0);

/*******************************************
* Helper arrays to store data about pixels.
********************************************/
// Pixels in output image for youAndPrev
color[] YP_youAndPrevIntersectionPixels = new color[YP_NUM_PIXELS]; // pixels that end up in output image
// Pixels to fade out shapes for youAndPrev
color[] YP_fadedPixels = new color[YP_NUM_PIXELS];
// Array of counters to determine when to start fading out intersection shapes
// in youAndPrev. This allows the intersection shapes to stay on the screen for the
// number of seconds set in YP_NUM_SECONDS_TO_PERSIST before the shape begins to fade.
int[] YP_fadeIntersectionCounter = new int[YP_NUM_PIXELS];

// Images shown on screen
PImage YP_justYou;
PImage YP_youAndPrev;
PImage YP_youAndPrevOutputImage;

// Output images
PGraphics YP_outputImage;

// displayText
final String displayTextYP = "In you vs. previous, we find intersections in space and similarities in joint position between you and the previous person."; 
final int textPosX_YP = floor(YP_WIDTH * 0.05); 
final int textPosY_YP = floor(YP_HEIGHT * 1.1); 
final int textBoxWidth_YP = floor(YP_WIDTH* 1.9); 
final int textBoxHeight_YP = floor(YP_HEIGHT / 5); 

int YP_intersectionHue;

void YP_setup() {
  // Must use numbers in calls to size(), not variables  
    
  // Create images
  YP_justYou = createImage(YP_WIDTH, YP_HEIGHT, PImage.RGB);
  YP_youAndPrev = createImage(YP_WIDTH, YP_HEIGHT, PImage.RGB);
  YP_youAndPrevOutputImage = createImage(YP_WIDTH, YP_HEIGHT, PImage.RGB);
  
  // Change color mode
  colorMode(HSB, 360, 100, 100);
  
  // Set colors
  YP_PREV_PERSON_COLOR = color(YP_PREV_PERSON_HUE, 60, 60);
  YP_CURR_PERSON_COLOR = color(YP_CURR_PERSON_HUE, 60, 100);
  YP_PREV_PERSON_COLOR_FADE = color(YP_PREV_PERSON_HUE, 40, 50);
  YP_CURR_PERSON_COLOR_FADE = color(YP_CURR_PERSON_HUE, 40, 50);
  YP_BLACK = color(0,0,0);


  // Create MedianFilter object
  YP_curr = new MedianFilter(YP_NUM_PIXELS, YP_TOT_FRAMES, YP_HEIGHT, YP_WIDTH, YP_FILTERORDER);

	// Create JointChecks object
	YP_jntchks = new JointChecks(YP_TOT_FRAMES, kinect, YP_NUM_JOINT_CHECKS);

  // Prints filepath save directory. For debugging purposes.
  File directory = new File("./");
  System.out.println(directory.getAbsolutePath());  

  // Load in depth data
  try {
    YP_input = new FileInputStream(YP_IOFILE_DEPTH);
    print("Please wait patiently, loading file contents into memory.\n");
    int start = millis();
    YP_input.read(YP_pixelLoaded, 0, YP_NUM_PIXELS*YP_TOT_FRAMES);
    int end = millis();
    print("Loading of file contents took " + (end-start)/1000 + " seconds.\n");
    YP_input.close();
  } catch(IOException ex) {
    ex.printStackTrace(); 
  }
  
  // Load in joints data
  try {
    YP_inputJoints = new FileInputStream(YP_IOFILE_JOINTS);
    print("Please wait patiently, loading file contents into memory.\n");
    int start = millis();
    YP_inputJoints.read(YP_jointsLoaded, 0, YP_NUM_JOINT_CHECKS*YP_TOT_FRAMES);
    int end = millis();
    print("Loading of joints file contents took " + (end-start)/1000 + " seconds.\n");
    YP_inputJoints.close();
  } catch(IOException ex) {
    ex.printStackTrace(); 
  }

  // Initialize pixels in helper arrays
  for (int i = 0; i < YP_NUM_PIXELS; i += 1) {
    YP_youAndPrevIntersectionPixels[i] = YP_BLACK;
    YP_fadedPixels[i] = YP_BLACK;
    YP_fadeIntersectionCounter[i] = 0;
  }
  // make sure this call to frameRate is at the bottom of setup
  //frameRate(16);
}

void YP_draw() {
  // Load pixels for all images
  YP_justYou.loadPixels();
  YP_youAndPrevOutputImage.loadPixels(); 
  YP_youAndPrev.loadPixels();
  
  textSize(30);
  text(displayTextYP, textPosX_YP, textPosY_YP, textBoxWidth_YP, textBoxHeight_YP); 

  
  // Exit out if no more old footage
  if (YP_frameCounter == YP_TOT_FRAMES) {
    // save outputImgIntersectionPixels
    YP_createOutputImage(YP_youAndPrevOutputImage.pixels, YP_OUTPUT_FILENAME);
    
    // Save depth data
    try {
      print("Writing file to memory\n");
      YP_output = new FileOutputStream(YP_IOFILE_DEPTH);
      YP_output.write(YP_pixelToSave, 0, YP_NUM_PIXELS*YP_TOT_FRAMES);
      YP_output.close();
      print("Done writing file to memory\n");
    } catch (IOException ex) {
     ex.printStackTrace(); 
    }
    
    // Save joint data
    try {
      YP_outputJoints = new FileOutputStream(YP_IOFILE_JOINTS);
      int start = millis();        
      YP_outputJoints.write(YP_jntchks.getJointChecks(), 0, YP_TOT_FRAMES*YP_NUM_JOINT_CHECKS);
      int end = millis();
      print("Total time to save joints is " + (end-start)/1000 + " seconds.\n");
      YP_outputJoints.close();
      print("Stream joint closed. \n"); 
    } catch (IOException ex) {}
    print("Ready to exit and close. \n"); 
    
    YP_finish = true;
    return;
  }
 
  // Raw body data: 0-6 users 255 nothing
  int[] rawBodyData = kinect.getRawBodyTrack();
  int[] rawDepthData = kinect.getRawDepthData();
  
  //Median filter the rawBodyData array.
  int off = 0;
  YP_curr.filterFrame(rawBodyData, YP_pixelTemp, off);
  //if (YP_frameCounter == 180) {
  // print("hello"); 
  //}
  rawBodyData = YP_pixelTemp;
  
  // Extract joint data
  YP_jntchks.runJointChecks();
  YP_jntchks.storeJointChecks(YP_frameCounter);
  YP_jntchks.storeFrameJointChecks();
  byte[] compareJoints = YP_jntchks.compareJoints(YP_jointsLoaded, YP_frameCounter);
  // Map joint similarities to colour
  YP_intersectionHue = colorMap_countZeroes(compareJoints);  

  // Normalize brightness level.
  // Amplify actual depth since we're only interested in
  // the body and throw away the rest of the data
  // (e.g. depth of things in the background, etc).
  float maxDepth = Float.MIN_VALUE;
  float minDepth = Float.MAX_VALUE;
  for (int i = 0; i < rawBodyData.length; i+=1){
    
    //////////////////////////////////////////////////
    // Save YP_current user's depth for the next run
    // Sorry couldn't find a better place to put the code 
    // at the moment so shoving it randomly here.
    if(rawBodyData[i] != 255) {
      int depth = rawDepthData[i]*256/4000;
      YP_pixelToSave[YP_frameCounter*YP_NUM_PIXELS + i] = byte(depth);
    }
    //////////////////////////////////////////////////
    
    //REMOVING DEPTH BRIGHTNESS MAPPING
    //if (rawBodyData[i] != 255 && YP_pixelLoaded[YP_frameCounter*YP_NUM_PIXELS + i]!= 0) {
    //  float diff = abs(rawDepthData[i] - YP_pixelLoaded[YP_frameCounter*YP_NUM_PIXELS + i]);
    //  if (diff > maxDepth) {
    //    maxDepth = rawDepthData[i];
    //  }
    //  if (diff < minDepth) {
    //    minDepth = rawDepthData[i];
    //  }
    //}
  } 
  
  //float adjustedScale = maxDepth - minDepth;
  float adjustedScale = 1;
  
  // Next, adjust brightness according to normalized scale.
  for (int i = 0; i < rawBodyData.length; i+=1){
     
    // initialize pixel in YP_justYou to black
    YP_justYou.pixels[i] = YP_BLACK;
    boolean body = false;
    
    // Intersection
    if(rawBodyData[i] != 255 && YP_pixelLoaded[YP_frameCounter*YP_NUM_PIXELS + i] != 0){
      float brightness = 100;
      // Start intersection color off at max saturation
      color newColor = color(YP_intersectionHue % 360, YP_MAX_SATURATION, brightness);
      
      // Color YP_justYou
      YP_justYou.pixels[i] = YP_CURR_PERSON_COLOR;
      
      // Color youAndPrev
      YP_youAndPrev.pixels[i] = newColor;
      YP_youAndPrevOutputImage.pixels[i] = newColor;
      YP_youAndPrevIntersectionPixels[i] = newColor;
      
      // reset fade intersection counter
      YP_fadeIntersectionCounter[i] = YP_FPS*YP_NUM_SECONDS_TO_PERSIST;
      // make the intersection fade off less quickly
      YP_fadedPixels[i] = newColor;
      body = true;
      

    }
    // Current body, no intersection
    else if (rawBodyData[i] != 255) {      
      // Color YP_justYou
      YP_justYou.pixels[i] = YP_CURR_PERSON_COLOR;
      
      // Color youAndPrev
      YP_youAndPrev.pixels[i] = YP_CURR_PERSON_COLOR;
      // make bodies fade off more quickly by starting at lower brightness
      // but preserve the colors of intersections
      if (YP_fadeIntersectionCounter[i] == 0) {
        YP_fadedPixels[i] = YP_CURR_PERSON_COLOR_FADE;
      }
      body = true;
    }
    // Previous body, no intersection
    else if (YP_pixelLoaded[YP_frameCounter*YP_NUM_PIXELS + i] != 0) {
      YP_youAndPrev.pixels[i] = YP_PREV_PERSON_COLOR;
      if (YP_fadeIntersectionCounter[i] == 0) {
        YP_fadedPixels[i] = YP_PREV_PERSON_COLOR_FADE;
      }
      body = true;
    }
    // No body detected at that pixel
    else {
      // For YP_youAndPrev, fade away pixels from previous scene
      color lastFadeColor = YP_fadedPixels[i];
      // Fade the pixel if it should be faded away.
      if (YP_fadeIntersectionCounter[i] == 0) {
        YP_youAndPrev.pixels[i] = lastFadeColor;
        float newHue = hue(lastFadeColor);
        float newSaturation = max(0, saturation(lastFadeColor)-1.0);
        float newBrightness = max(0, brightness(lastFadeColor)-2.0);
        color newColor = color(newHue, newSaturation, newBrightness);
        YP_youAndPrev.pixels[i] = newColor;
        YP_fadedPixels[i] = newColor;
      }
      // Otherwise, update the counter and display the
      // the intersection shape.
      else {
        YP_fadeIntersectionCounter[i] -= 1;
        color tempColor = YP_youAndPrevIntersectionPixels[i];
        if (YP_frameCounter <= YP_START_FADE) {
          YP_youAndPrev.pixels[i] = tempColor;
        } else {
          float hue = hue(tempColor);
          float saturation = saturation(tempColor);
          float brightness = max(20, brightness(tempColor)-(YP_frameCounter-YP_START_FADE));
          tempColor = color(hue,saturation,brightness);
          YP_youAndPrev.pixels[i] = tempColor;
          YP_youAndPrevIntersectionPixels[i] = tempColor;
        }
      }
    }
    
    // finally, for live image, fade pixels if necessary
    if (body && YP_frameCounter > YP_START_FADE) {
      color tempColor = YP_youAndPrev.pixels[i];
      float hue = hue(tempColor);
      float saturation = saturation(tempColor);
      float brightness = max(20, brightness(tempColor)-(YP_frameCounter-YP_START_FADE));
      tempColor = color(hue,saturation,brightness);
      YP_youAndPrev.pixels[i] = tempColor;
    }
  }

  // Call updatePixels() for all images after they have been updated.
  YP_justYou.updatePixels();
  YP_youAndPrev.updatePixels();
  YP_youAndPrevOutputImage.updatePixels();

  image(YP_youAndPrev, 0, 0); 
  image(YP_youAndPrevOutputImage, YP_WIDTH, 0); 
  // show countdown
  if(YP_frameCounter > YP_START_FADE) {
    float tempCount = float((YP_frameCounter-YP_START_FADE))/(YP_TOT_FRAMES-YP_START_FADE);
    String currCountdown = Integer.toString(
      ceil(YP_NUM_SECONDS_OF_FADE - YP_NUM_SECONDS_OF_FADE*tempCount)
      );
    text(currCountdown, 450, 370, 50, 50); 
  }
  YP_frameCounter++; 
}

void YP_createOutputImage(color[] outputPixels, String filename) {
    filename = "./data/user" + YA_userId + "/" + filename;
    YP_outputImage = createGraphics(YP_WIDTH, YP_HEIGHT);
    YP_outputImage.beginDraw();
    YP_outputImage.loadPixels();
    for (int i = 0; i < outputPixels.length; i += 1) {
      YP_outputImage.pixels[i] = outputPixels[i];
    }
    YP_outputImage.updatePixels();
    YP_outputImage.save(filename + ".png");
    
}


// Some methods for mapping joint similarity to colour: 

int colorMap_countZeroes2(byte[] compareJoints){
  // try to make colours less green  
  int sum = 0; 
  for(int i = 0; i < compareJoints.length; i++){
    sum += compareJoints[i]; 
  }
  sum = YP_NUM_JOINT_CHECKS - sum; 
  //print("sum: " + sum + "\n");  
  // hard code some bs for shits and gigs 
  if (sum==0) YP_intersectionHue = 0; 
  else if (sum==1) YP_intersectionHue = 20; 
  else if (sum==2) YP_intersectionHue = 40; 
  else if (sum==3) YP_intersectionHue = 50; 
  else if (sum==4) YP_intersectionHue = 60; 
  else if (sum==5) YP_intersectionHue = 75; 
  else if (sum==6) YP_intersectionHue = 90; 
  else if (sum==7) YP_intersectionHue = 120; 
  else if (sum==8) YP_intersectionHue = 145; 
  else if (sum==9) YP_intersectionHue = 170; 
  else if (sum==10) YP_intersectionHue = 185; 
  else if (sum==11) YP_intersectionHue = 205; 
  else if (sum==12) YP_intersectionHue = 260; 
  else if (sum==13) YP_intersectionHue = 280; 
  else if (sum==14) YP_intersectionHue = 320; 
  //print("intersectionhue: " + YP_intersectionHue + "\n" + "\n"); 
  return YP_intersectionHue; 
}
int colorMap_countOnes2(byte[] compareJoints){
  // try to make colours less green  
  int sum = 0; 
  for(int i = 0; i < compareJoints.length; i++){
    sum += compareJoints[i]; 
  }
  print("sum: " + sum + "\n");  
  if (sum==0) YP_intersectionHue = 0; 
  else if (sum==1) YP_intersectionHue = 20; 
  else if (sum==2) YP_intersectionHue = 40; 
  else if (sum==3) YP_intersectionHue = 50; 
  else if (sum==4) YP_intersectionHue = 60; 
  else if (sum==5) YP_intersectionHue = 75; 
  else if (sum==6) YP_intersectionHue = 90; 
  else if (sum==7) YP_intersectionHue = 120; 
  else if (sum==8) YP_intersectionHue = 145; 
  else if (sum==9) YP_intersectionHue = 170; 
  else if (sum==10) YP_intersectionHue = 185; 
  else if (sum==11) YP_intersectionHue = 205; 
  else if (sum==12) YP_intersectionHue = 260; 
  else if (sum==13) YP_intersectionHue = 280; 
  else if (sum==14) YP_intersectionHue = 320; 
  //print("intersectionhue: " + YP_intersectionHue + "\n" + "\n"); 
  return YP_intersectionHue; 
}

int colorMap_countZeroes(byte[] compareJoints){
  // colours tend to green 
  int sum = 0; 
  for(int i = 0; i < compareJoints.length; i++){
    sum += compareJoints[i]; 
  }
  print("sum: " + sum + "\n");
  float n_zeros = (float) (YP_NUM_JOINT_CHECKS - sum); 
  float scale = 360 / (float) (YP_NUM_JOINT_CHECKS);
  YP_intersectionHue = (int) (n_zeros * scale); 
  print("intersectionhue: " + YP_intersectionHue + "\n" + "\n"); 
  return YP_intersectionHue; 
}

int colorMap_countOnes(byte[] compareJoints){  
  // colours tend to blue/purple/violet with this one 
  int sum = 0; 
  for(int i = 0; i < compareJoints.length; i++){
    sum += compareJoints[i]; 
  }
  print("sum: " + sum + "\n");
  float n_ones = (float) (sum); 
  float scale = 360 / (float) (YP_NUM_JOINT_CHECKS);
  YP_intersectionHue = (int) (n_ones * scale); 
  print("intersectionhue: " + YP_intersectionHue + "\n" + "\n"); 
  return YP_intersectionHue; 
}

int colorMap_binary(byte[] compareJoints){
  
  float sum = 0; 
  float scale = 360 / 2^(compareJoints.length); 
  for(int i = 0; i < compareJoints.length; i++){
    sum += 2^compareJoints[i]; 
  }
  YP_intersectionHue = (int) (sum * scale); 
  
  return YP_intersectionHue; 
}
