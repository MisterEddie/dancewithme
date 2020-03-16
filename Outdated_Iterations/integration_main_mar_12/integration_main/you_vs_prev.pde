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
final int YP_DURATION  = 20;
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

// Associated with silhouette colors 
FileInputStream YP_inputSilCol; 
FileOutputStream YP_outputSilCol; 
final String YP_IOFILE_SILCOL = "./testSilCol.txt"; 
byte[] YP_silColLoaded = new byte[YP_TOT_FRAMES*3]; 
byte[] YP_silhouetteColors = new byte[YP_TOT_FRAMES*3]; 
SilhouetteColor YP_SilCol; 
ArrayList<KSkeleton> YP_skeletonArray;


// Associated with median filtering 
MedianFilter YP_curr;
int[] YP_pixelTemp = new int[YP_NUM_PIXELS];
final int YP_FILTERORDER = 2;

// Colors

color YP_PREV_PERSON_COLOR;
color YP_CURR_PERSON_COLOR;
color YP_PREV_PERSON_COLOR_FADE;
color YP_CURR_PERSON_COLOR_FADE;

final double shade_factor = 0.75; 
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

color YP_intersection;


// Images shown on screen
PImage YP_justYou;
PImage YP_youAndPrev;
PImage YP_youAndPrevOutputImage;

// Output images
PGraphics YP_outputImage;

void YP_setup() {
  // Must use numbers in calls to size(), not variables  
    
  // Create images
  YP_justYou = createImage(YP_WIDTH, YP_HEIGHT, PImage.RGB);
  YP_youAndPrev = createImage(YP_WIDTH, YP_HEIGHT, PImage.RGB);
  YP_youAndPrevOutputImage = createImage(YP_WIDTH, YP_HEIGHT, PImage.RGB);
  
  // Change color mode
  colorMode(RGB, 255, 255, 255);
  
  // Set colors  
  YP_BLACK = color(0,0,0);
    
  YP_PREV_PERSON_COLOR = YP_BLACK; 
  YP_CURR_PERSON_COLOR = YP_BLACK; 
  YP_PREV_PERSON_COLOR_FADE = YP_BLACK;
  YP_CURR_PERSON_COLOR_FADE = YP_BLACK; 
  
  // Create MedianFilter object
  YP_curr = new MedianFilter(YP_NUM_PIXELS, YP_TOT_FRAMES, YP_HEIGHT, YP_WIDTH, YP_FILTERORDER);

  // Create JointChecks object
  // YP_jntchks = new JointChecks(YP_TOT_FRAMES, kinect, YP_NUM_JOINT_CHECKS);
  YP_SilCol = new SilhouetteColor(YP_TOT_FRAMES, kinect); 

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
  
  
  try {
    YP_inputSilCol = new FileInputStream(YP_IOFILE_SILCOL);
    print("Please wait patiently, loading file contents into memory.\n");
    int start = millis();
    YP_inputSilCol.read(YP_silColLoaded, 0, YP_TOT_FRAMES*3);
    int end = millis();
    print("Loading of joints file contents took " + (end-start)/1000 + " seconds.\n");
    YP_inputSilCol.close();
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
    
    try {
      YP_outputSilCol = new FileOutputStream(YP_IOFILE_SILCOL);
      int start = millis();        
      YP_outputSilCol.write(YP_SilCol.getSilhouetteColors(), 0, YP_TOT_FRAMES*3);
      int end = millis();
      print("Total time to save silhouette colors is " + (end-start)/1000 + " seconds.\n");
      YP_outputSilCol.close();
      print("Stream silhouette colors closed. \n"); 
    } catch (IOException ex) {}
    print("Ready to exit and close. \n"); 
    
    YP_finish = true;
    return;
  }
 
  // Raw body data: 0-6 users 255 nothing
  int[] rawBodyData = kinect.getRawBodyTrack();
  int[] rawDepthData = kinect.getRawDepthData();
  YP_skeletonArray = kinect.getSkeletonDepthMap();

  //Median filter the rawBodyData array.
  int off = 0;
  YP_curr.filterFrame(rawBodyData, YP_pixelTemp, off);

  rawBodyData = YP_pixelTemp;
  
  setCurrSilhouetteColor_YP(); 
  storeCurrSilhouetteColor_YP(YP_frameCounter); // write YP_CURR_PERSON_COLOR to YP_outputSilCol; convert int to byte   
  
  // set colors for individual silhouettes 
  int YP_PREV_COLOR_R = convertByteToColorInt(YP_silColLoaded[0 + YP_frameCounter*3]); 
  int YP_PREV_COLOR_G = convertByteToColorInt(YP_silColLoaded[1 + YP_frameCounter*3]);
  int YP_PREV_COLOR_B = convertByteToColorInt(YP_silColLoaded[2 + YP_frameCounter*3]);
  int YP_CURR_COLOR_R = int(red(YP_CURR_PERSON_COLOR)); 
  int YP_CURR_COLOR_G = int(blue(YP_CURR_PERSON_COLOR)); 
  int YP_CURR_COLOR_B = int(green(YP_CURR_PERSON_COLOR)); 

  YP_PREV_PERSON_COLOR = color(YP_PREV_COLOR_R, YP_PREV_COLOR_G, YP_PREV_COLOR_B);

  // Mix color for the intersection 
  int YP_INTERSECT_R = (int) ((YP_PREV_COLOR_R + YP_CURR_COLOR_R)/2); 
  int YP_INTERSECT_G = (int) ((YP_PREV_COLOR_G + YP_CURR_COLOR_G)/2); 
  int YP_INTERSECT_B = (int) ((YP_PREV_COLOR_B + YP_CURR_COLOR_B)/2); 

  YP_intersection = color(YP_INTERSECT_R, YP_INTERSECT_G, YP_INTERSECT_B); 
  
  for (int i = 0; i < rawBodyData.length; i+=1){
    
    if(rawBodyData[i] != 255) {
      int depth = rawDepthData[i]*256/4000;
      YP_pixelToSave[YP_frameCounter*YP_NUM_PIXELS + i] = byte(depth);
    }
  } 
  
  // Next, adjust brightness according to normalized scale.
  for (int i = 0; i < rawBodyData.length; i+=1){
     
    // initialize pixel in YP_justYou to black
    YP_justYou.pixels[i] = YP_BLACK;
    boolean body = false;
    
    // Intersection
    if(rawBodyData[i] != 255 && YP_pixelLoaded[YP_frameCounter*YP_NUM_PIXELS + i] != 0){
      // Start intersection color off at max saturation
      color newColor = YP_intersection;
      
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
        YP_fadedPixels[i] = updateFadeColor(YP_CURR_PERSON_COLOR, 40); 
      }
      body = true;
    }
    // Previous body, no intersection
    else if (YP_pixelLoaded[YP_frameCounter*YP_NUM_PIXELS + i] != 0) {
      YP_youAndPrev.pixels[i] = YP_PREV_PERSON_COLOR;
      if (YP_fadeIntersectionCounter[i] == 0) {
        YP_fadedPixels[i] = updateFadeColor(YP_PREV_PERSON_COLOR, 40); 
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
        YP_youAndPrev.pixels[i] = updateFadeColor(lastFadeColor, 0); 
        YP_fadedPixels[i] = updateFadeColor(lastFadeColor, 0); 
      }
      // Otherwise, update the counter and display the
      // the intersection shape.
      else {
        YP_fadeIntersectionCounter[i] -= 1;
        color tempColor = YP_youAndPrevIntersectionPixels[i];
        if (YP_frameCounter <= YP_START_FADE) {
          YP_youAndPrev.pixels[i] = tempColor;
        } else {
          YP_youAndPrev.pixels[i] = updateFadeColor(tempColor, 20); 
          YP_youAndPrevIntersectionPixels[i] = updateFadeColor(tempColor, 20); 
        }
      }
    }
    
    // finally, for live image, fade pixels if necessary
    if (body && YP_frameCounter > YP_START_FADE) {
      color tempColor = YP_youAndPrev.pixels[i];
      YP_youAndPrev.pixels[i] = updateFadeColorForVizEnd(tempColor); 
    }
  }

  // Call updatePixels() for all images after they have been updated.
  YP_justYou.updatePixels();
  YP_youAndPrev.updatePixels();
  YP_youAndPrevOutputImage.updatePixels();
  // center images
  int leftImgX = round((0.25*width)-(YP_WIDTH/2));
  int rightImgX = round((0.75*width)-(YP_WIDTH/2));
  int imgY = round((0.5*height)-(YP_HEIGHT/2));
  image(YP_youAndPrev, leftImgX, imgY); 
  image(YP_youAndPrevOutputImage, rightImgX, imgY); 
  text("live movement", round(0.25*width), imgY + 472);
  text("your artwork", round(0.75*width), imgY + 472);
  
  // render border
  strokeWeight(4);
  stroke(100);
  noFill();
  rect(leftImgX, imgY, YA_WIDTH, YA_HEIGHT);
  rect(rightImgX, imgY, YA_WIDTH, YA_HEIGHT);
  // show countdown
  if(YP_frameCounter > YP_START_FADE) {
    float tempCount = float((YP_frameCounter-YP_START_FADE))/(YP_TOT_FRAMES-YP_START_FADE);
    String currCountdown = Integer.toString(
      ceil(YP_NUM_SECONDS_OF_FADE - YP_NUM_SECONDS_OF_FADE*tempCount)
      );
    text(currCountdown, leftImgX + 462, imgY + 382, 50, 50);  
  }
  YP_frameCounter++; 
}

void YP_createOutputImage(color[] outputPixels, String filename) {
    filename = "./data/" + filename;
    YP_outputImage = createGraphics(YP_WIDTH, YP_HEIGHT);
    YP_outputImage.beginDraw();
    YP_outputImage.loadPixels();
    for (int i = 0; i < outputPixels.length; i += 1) {
      YP_outputImage.pixels[i] = outputPixels[i];
    }
    YP_outputImage.updatePixels();
    YP_outputImage.save(filename + ".png");
    
}


void setCurrSilhouetteColor_YP() {
    float currSilhouetteR = 0;
    float currSilhouetteG = 0;
    float currSilhouetteB = 0;
    if (YP_skeletonArray.size() > 0) {
       KSkeleton skeleton = (KSkeleton) YP_skeletonArray.get(0);
      if (skeleton.isTracked()) {
        float percent = 0; //right hand
        float percent_2 = 0; //left hand
        float percent_3 = 0; //right knee
        float percent_4 = 0; //left knee
        
        KJoint[] joints = skeleton.getJoints();
        PVector limb_len = PVector.sub(joints[KinectPV2.JointType_HandTipRight].getPosition(), joints[KinectPV2.JointType_ElbowRight].getPosition());
        float add_length = pow(pow(limb_len.x, 2) + pow(limb_len.y, 2), 0.5); 
  
        float y_right_foot = joints[KinectPV2.JointType_FootRight].getY();
        float y_head = joints[KinectPV2.JointType_Head].getY();
        float y_right_hand = joints[KinectPV2.JointType_HandTipRight].getY();
        float y_left_hand = joints[KinectPV2.JointType_HandTipLeft].getY();
        float bod_range = y_right_foot - y_head + add_length; //add length is the length of the arm
  
        float x_base_spine = joints[KinectPV2.JointType_SpineBase].getX();
        float y_base_spine = joints[KinectPV2.JointType_SpineBase].getY();
        float x_right_knee = joints[KinectPV2.JointType_KneeRight].getX();
        float y_right_knee = joints[KinectPV2.JointType_KneeRight].getY();
        float x_left_knee = joints[KinectPV2.JointType_KneeLeft].getX();
        float y_left_knee = joints[KinectPV2.JointType_KneeLeft].getY();
  
        //right knee
        float x_vec_r = abs(x_right_knee - x_base_spine);
        float y_vec_r = abs(y_right_knee - y_base_spine);
        float degree = 90 - (atan(y_vec_r/x_vec_r))*180/3.14159;
        percent_3 = degree/90;
  
        //left knee
        float x_vec_l = abs(x_left_knee - x_base_spine);
        float y_vec_l = abs(y_left_knee - y_base_spine);
        float degree_2 = 90 - (atan(y_vec_l/x_vec_l))*180/3.14159;
        percent_4 = degree_2/90;
  
        //right hand
        if (y_right_hand <= y_head - add_length) {
          percent = 100;
        } else if (y_right_hand >= y_right_foot) {
          percent = 0;
        } else {
          float y_rel_right_hand = y_right_foot - y_right_hand;
          percent = y_rel_right_hand/bod_range;
        }
  
        //left hand
        if (y_left_hand <= y_head - add_length) {
          percent_2 = 100;
        } else if (y_left_hand >= y_right_foot) {
          percent_2 = 0;
        } else {
          float y_rel_left_hand = y_right_foot - y_left_hand;
          percent_2 = y_rel_left_hand/bod_range;
        }
        
        currSilhouetteR = percent*255;
        currSilhouetteG = percent_2*255;
        currSilhouetteB = (percent_3+percent_4)*255;
      }
    }

    YP_CURR_PERSON_COLOR = color(currSilhouetteR, currSilhouetteG, currSilhouetteB);
}

void storeCurrSilhouetteColor_YP(int frame){
  byte r = convertColorIntToByte(int(red(YP_CURR_PERSON_COLOR))); 
  byte g = convertColorIntToByte(int(green(YP_CURR_PERSON_COLOR))); 
  byte b = convertColorIntToByte(int(blue(YP_CURR_PERSON_COLOR))); 
  
  
  YP_silhouetteColors[0 + frame*3] = r; 
  YP_silhouetteColors[1 + frame*3] = g; 
  YP_silhouetteColors[2 + frame*3] = b; 
}

color updateFadeColor(color col, int minFade){
  int r = max(minFade, (int) ((double) red(col) * shade_factor)); 
  int g = max(minFade, (int) ((double) green(col) * shade_factor)); 
  int b = max(minFade, (int) ((double) blue(col) * shade_factor)); 
  color faded_col = color(r, g, b); 
  return faded_col; 
}

// For fading out the live image at the end
color updateFadeColorForVizEnd(color col){
  float r = max(40, (col >> 16 & 0xFF) - (255 * (YP_frameCounter-YP_START_FADE)/(YP_TOT_FRAMES-YP_START_FADE)));
  float g = max(40, (col >> 8 & 0xFF) - (255 * (YP_frameCounter-YP_START_FADE)/(YP_TOT_FRAMES-YP_START_FADE)));
  float b = max(40, (col >> 8 & 0xFF) - (255 * (YP_frameCounter-YP_START_FADE)/(YP_TOT_FRAMES-YP_START_FADE)));

  color faded_col = color(r, g, b); 
  return faded_col; 
}

byte convertColorIntToByte(int c){
  // c is between 0 and 255
  byte c_b = byte(c - 128); 
  return c_b; 
}
  
int convertByteToColorInt(int c_b){
  // c_b is between -128 and 127
  int c = int(c_b) + 128; 
  return c; 
}
