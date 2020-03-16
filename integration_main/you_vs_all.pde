import de.bezier.data.sql.*;
import de.bezier.data.sql.mapper.*;

import KinectPV2.*;
import java.lang.Long;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.Queue;

/*
 * Constants 
 */
final int YA_DURATION  = 20;
final int YA_FPS       = 16;
final int YA_TOT_FRAMES = YA_DURATION * YA_FPS;
final int YA_WIDTH = 512;
final int YA_HEIGHT = 424;
final int YA_NUM_PIXELS = YA_WIDTH * YA_HEIGHT;
final int YA_CURR_MARK = 6; // size+1 of circle for current user's RightHand location
final int YA_OLD_MARK = 9; // size+1 of cross for old RightHand locations
final String YA_OUTPUT_FILENAME = "3youvsall";
final String YA_DB_PATH = "./data/you_vs_all.db";
final int YA_MAX_USERS = 25; // max number of unique users in database
final int YA_NUM_SECONDS_OF_FADE = 5;
final int YA_START_FADE = (YA_DURATION-YA_NUM_SECONDS_OF_FADE) * YA_FPS; // when to start fading out live image

// Toggle what output image looks like.
// True: output image does not update unless current user is moving.
// False: output image updates even when current user is still.
final boolean YA_NO_OUTPUT_WHEN_STILL = true;
final boolean YA_OUTPUT_BODIES = true;

int YA_frameCounter = 0;
// data to save to database
int[] YA_pixelsToSave = new int[YA_TOT_FRAMES*YA_NUM_PIXELS];
int[] YA_positionOnScreen = new int[YA_TOT_FRAMES];
int[] YA_rightHandX = new int[YA_TOT_FRAMES];
int[] YA_rightHandY = new int[YA_TOT_FRAMES];
int[] YA_red = new int[YA_TOT_FRAMES];
int[] YA_green = new int[YA_TOT_FRAMES];
int[] YA_blue = new int[YA_TOT_FRAMES];
int YA_userId;

//Associated with median filtering
MedianFilter YA_curr;
int[] YA_pixelTemp = new int[YA_NUM_PIXELS];
final int YA_MFILTERORDER = 2;

// Queue for fading out silhouettes
Queue<ArrayList<Integer>> YA_q = new LinkedList<ArrayList<Integer>>();
// Hashmap for storing colors of previous silhouettes (user_id: color)
HashMap<Integer, Integer> YA_oldSilhouetteColors = new HashMap<Integer, Integer>();

// database
SQLite YA_db;
final String[] columnNames = {
    "user_id", "frame_number", "position_on_screen",
    "red", "green", "blue",
    "body_x", "body_y", "body_pixels"
  };

// images
PImage YA_liveImage;
PImage YA_tempOutputImage;
PGraphics YA_outputImage;

// current silhouette color
color YA_currSilhouetteColor;

// Skeleton array
ArrayList<KSkeleton> YA_skeletonArray;

void YA_setup() { 
  // Initialize images
  colorMode(RGB, 255, 255, 255);
  YA_liveImage = createImage(YA_WIDTH, YA_HEIGHT, PImage.RGB);
  YA_tempOutputImage = createImage(YA_WIDTH, YA_HEIGHT, PImage.RGB);
  
  // set image backgrounds to black
  YA_liveImage.loadPixels();
  YA_tempOutputImage.loadPixels();
  for (int i = 0; i < YA_NUM_PIXELS; i++) {
    YA_liveImage.pixels[i] = color(0);
    YA_tempOutputImage.pixels[i] = color(0);
  }
  YA_liveImage.updatePixels();
  YA_tempOutputImage.updatePixels();
  
  YA_db = new SQLite( this, YA_DB_PATH );  // open database file  
  
  // set debug on/off
  YA_db.setDebug(false);
  
  // set user ID
  if (YA_db.connect()) {
    YA_db.query("SELECT MAX(user_id) FROM body_data");
    if (YA_db.next()) {
      YA_userId = YA_db.getInt("MAX(user_id)") + 1;
    }
    else {
      YA_userId = 1; //  first user!
    }
  }
  else {
    // exit, there is a problem
    println("Could not connect to database");
    exit();
    return;
  }
  
  // Create Median Filter object
  YA_curr = new MedianFilter(YA_NUM_PIXELS, YA_TOT_FRAMES, YA_HEIGHT, YA_WIDTH, YA_MFILTERORDER);
  
  frameRate(YA_FPS);
  
  // try to avoid YA_green screen
  boolean broken = true;
  while (broken)
  {
    int[] rawData = kinect.getRawBodyTrack();
    for (int i = 0; i < YA_NUM_PIXELS; i++)
    {
      if (rawData[i] == 255) {
        broken = false;
        break;
      }
    }
  }
}

void YA_draw() {
    YA_liveImage.loadPixels(); 
    YA_tempOutputImage.loadPixels();
    
        /*
    // for generating video demos
    background(60);
    
    textAlign(LEFT);
    final String displayTextYA = "Move your right hand around to find past users who were at the same place at the same time as you.";
    final int textPosX_YA = round((0.25*width)-(YA_WIDTH/2)); 
    final int textPosY_YA = round((0.5*height)-(YA_HEIGHT/2));
    final int textBoxWidth_YA = floor(YA_WIDTH * 2.5); 
    final int textBoxHeight_YA = floor(YA_HEIGHT / 2); 

    textSize(100);
    text("description", textPosX_YA, 150);
    textSize(40);
    text(displayTextYA, textPosX_YA, textPosY_YA + 500, textBoxWidth_YA, textBoxHeight_YA); 
    textSize(24);
    */

     // End the sketch.
    if (YA_frameCounter == YA_TOT_FRAMES) {
      thread("saveBodyDataToDatabase");
      YA_createOutputImage(YA_tempOutputImage.pixels, YA_OUTPUT_FILENAME);
      println("saved you vs all image");
      YA_finish = true;
      return;
    } 
     
    /****************
     * Main loop code
     ****************/
    int [] rawData = kinect.getRawBodyTrack();
    YA_skeletonArray = kinect.getSkeletonDepthMap();
    
    int off = 0;
    YA_curr.filterFrame(rawData, YA_pixelTemp, off);
    rawData = YA_pixelTemp;
    
    // Calculate current color of silhouette
    if (YA_skeletonArray.size() > 0) {
      KSkeleton yaSkeleton = (KSkeleton) YA_skeletonArray.get(0);
      if (yaSkeleton.isTracked()) {
        YA_currSilhouetteColor = getSilhouetteColor(yaSkeleton);   
      }
    }
    YA_red[YA_frameCounter] = int(red(YA_currSilhouetteColor));
    YA_green[YA_frameCounter] = int(green(YA_currSilhouetteColor));
    YA_blue[YA_frameCounter] = int(blue(YA_currSilhouetteColor));
    
    // Set data about head position
    setRightHandData();

    // Now draw current user's RightHand location on top
    int currRightHandX = YA_rightHandX[YA_frameCounter];
    int currRightHandY = YA_rightHandY[YA_frameCounter];
    if (!YA_OUTPUT_BODIES && currRightHandX > YA_CURR_MARK && currRightHandY > YA_CURR_MARK &&
      currRightHandX < YA_WIDTH - YA_CURR_MARK && currRightHandY < YA_HEIGHT - YA_CURR_MARK) {
        YA_drawCurrRightHand(currRightHandX,currRightHandY);
    }
    int currRightHandPosition = YA_positionOnScreen[YA_frameCounter];
    YA_db.query(
      "SELECT * FROM body_data WHERE frame_number=" +
      YA_frameCounter +
      " AND position_on_screen=" +
      currRightHandPosition +
      " LIMIT 1");
    
    // Load in silhouette data for this frame
    ArrayList<Object[]> oldFigures = new ArrayList<Object[]>();
    ArrayList<Integer> YA_userIds = new ArrayList<Integer>();
    
    // Go through between 0-3 past users
    int numOldUsersRetrieved = 0;
    while (YA_db.next()) {
      // Load in database info
      String YA_dbcontent =  (String) YA_db.getObject("body_pixels");
      int oldId = YA_db.getInt("user_id");
      int oldR = YA_db.getInt("red");
      int oldG = YA_db.getInt("green");
      int oldB = YA_db.getInt("blue");
      color oldColor = color(oldR, oldG, oldB);
      // remove [] from string
      YA_dbcontent = YA_dbcontent.substring(1, YA_dbcontent.length()-1);
      String[] pixelData = YA_dbcontent.split(", ");
      Object[] userAndPixels = {oldId, pixelData};
      oldFigures.add(userAndPixels);
      YA_userIds.add(oldId);
      YA_oldSilhouetteColors.put(oldId, oldColor); 
      numOldUsersRetrieved++;
      
      int oldRightHandX = YA_db.getInt("body_x");
      int oldRightHandY = YA_db.getInt("body_y");
      if (!YA_OUTPUT_BODIES && oldRightHandX > YA_OLD_MARK && oldRightHandY > YA_OLD_MARK &&
        oldRightHandX < YA_WIDTH - YA_OLD_MARK && oldRightHandY < YA_HEIGHT - YA_OLD_MARK) {
          YA_drawoldRightHand(oldRightHandX, oldRightHandY, oldColor);
      }
    }
    
    // Load trails of silhouettes from 1-3 timesteps ago
    String str = "";
    for (ArrayList<Integer> item: YA_q) {
      for (int i = 0; i < item.size(); i++) {
        int currUser = item.get(i);
        if (!YA_userIds.contains(currUser))
          str += " OR user_id=" + String.valueOf(currUser);
      }
    }
    
    YA_db.query(
      "SELECT user_id, body_x, body_y, body_pixels FROM body_data WHERE frame_number=" +
      YA_frameCounter +
      " AND (user_id=-1" +
      str +
      ")" );
      
    while (YA_db.next()) {
      int oldId = YA_db.getInt("user_id");
      String YA_dbcontent =  (String) YA_db.getObject("body_pixels");
      YA_dbcontent = YA_dbcontent.substring(1, YA_dbcontent.length()-1);
      String[] pixelData = YA_dbcontent.split(", ");
      Object[] userAndPixels = {oldId, pixelData};
      oldFigures.add(userAndPixels);

      // draw old RightHand
      int oldRightHandX = YA_db.getInt("body_x");
      int oldRightHandY = YA_db.getInt("body_y");
      
      if (!YA_OUTPUT_BODIES && oldRightHandX > YA_OLD_MARK && oldRightHandY > YA_OLD_MARK &&
        oldRightHandX < YA_WIDTH - YA_OLD_MARK && oldRightHandY < YA_HEIGHT - YA_OLD_MARK) {
          YA_drawoldRightHand(oldRightHandX, oldRightHandY, YA_oldSilhouetteColors.get(oldId));
      }
    }
    
    // Update queue of past users' silhouettes to display
    if (YA_q.size() >= 3) {
      YA_q.remove(); // ensure it goes away after half a second
    }
    YA_q.add(YA_userIds); // add old users
    
    // Draw the pixels
    for (int i = 0; i < YA_NUM_PIXELS; i++) {
      
      int localData = rawData[i];
      boolean pixelHasColor = false;
      
      color newColor = color(0);
      
      int numFigures = oldFigures.size();
      for (int j = 0; j < numFigures; j++) {
        String[] savedData = (String[]) oldFigures.get(j)[1];
        int savedDataInt = Integer.parseInt(savedData[i]);
        if (savedDataInt == 1) {
          newColor = YA_oldSilhouetteColors.get(oldFigures.get(j)[0]);
          pixelHasColor = true;
          // add old silhouette
          if (YA_OUTPUT_BODIES && j < numOldUsersRetrieved) {
            if (!YA_NO_OUTPUT_WHEN_STILL || (YA_NO_OUTPUT_WHEN_STILL &&
                abs(YA_rightHandX[max(0, YA_frameCounter-1)] - YA_rightHandX[YA_frameCounter]) > 3 &&
                abs(YA_rightHandY[max(0, YA_frameCounter-1)] - YA_rightHandY[YA_frameCounter]) > 3
              )
            ) {
              YA_tempOutputImage.pixels[i] = newColor;
            }
          }
          break;
        }
      }
      
      // Paint current silhouette on top and store color
      if ((localData != 255)) {
        newColor = YA_currSilhouetteColor;
        pixelHasColor = true;
      }
      
      if (!pixelHasColor) {
        // fade away the background
          color lastFadeColor = YA_liveImage.pixels[i];
          float newR = max(0, (lastFadeColor >> 16 & 0xFF)-40.0);
          float newG = max(0, (lastFadeColor >> 8 & 0xFF)-40.0);
          float newB = max(0, (lastFadeColor & 0xFF)-40.0);
          newColor = color(newR, newG, newB);
      }
      // fade out color near the end if necessary
      else if (YA_frameCounter > YA_START_FADE) {
        float newR = max(40, (newColor >> 16 & 0xFF) - (255 * (YA_frameCounter-YA_START_FADE)/(YA_TOT_FRAMES-YA_START_FADE)));
        float newG = max(40, (newColor >> 8 & 0xFF) - (255 * (YA_frameCounter-YA_START_FADE)/(YA_TOT_FRAMES-YA_START_FADE)));
        float newB = max(40, (newColor >> 8 & 0xFF) - (255 * (YA_frameCounter-YA_START_FADE)/(YA_TOT_FRAMES-YA_START_FADE)));
        newColor = color(newR, newG, newB);
      }
      YA_liveImage.pixels[i] = newColor;
      
      // Add old silhouette to YA_pixelsToSave
      if (localData != 255) {
        YA_pixelsToSave[YA_frameCounter*YA_NUM_PIXELS + i] = 1;
      } else {
        YA_pixelsToSave[YA_frameCounter*YA_NUM_PIXELS + i] = 0;
      }
    }

    YA_liveImage.updatePixels();
    YA_tempOutputImage.updatePixels();
    
    // Render images
    // center images
    int leftImgX = round((0.25*width)-(YA_WIDTH/2));
    int rightImgX = round((0.75*width)-(YA_WIDTH/2));
    int imgY = round((0.5*height)-(YA_HEIGHT/2));
    image(YA_liveImage, leftImgX, imgY); // left
    image(YA_tempOutputImage, rightImgX, imgY); // right
    text("live movement", round(0.25*width), imgY + 472);
    text("your artwork", round(0.75*width), imgY + 472);
    
    // render border
    strokeWeight(4);
    stroke(100);
    noFill();
    rect(leftImgX, imgY, YA_WIDTH, YA_HEIGHT);
    rect(rightImgX, imgY, YA_WIDTH, YA_HEIGHT);
    
    // show countdown
    if(YA_frameCounter > YA_START_FADE) {
      float tempCount = float((YA_frameCounter-YA_START_FADE))/(YA_TOT_FRAMES-YA_START_FADE);
      String currCountdown = Integer.toString(
        ceil(YA_NUM_SECONDS_OF_FADE - YA_NUM_SECONDS_OF_FADE*tempCount)
        );
      text(currCountdown, leftImgX + 462, imgY + 382, 50, 50); 
    }
      
    YA_frameCounter++;
}

/*
* Sets RightHand data.
*/
void setRightHandData() {
  if (YA_skeletonArray.size() == 0) {
    YA_rightHandX[YA_frameCounter] = -1;
    YA_rightHandY[YA_frameCounter] = -1;
    YA_positionOnScreen[YA_frameCounter] = -1;
    return;
  }
  
  KSkeleton skeleton = (KSkeleton) YA_skeletonArray.get(0);
  if (!skeleton.isTracked()) {
    YA_rightHandX[YA_frameCounter] = -1;
    YA_rightHandY[YA_frameCounter] = -1;
    YA_positionOnScreen[YA_frameCounter] = -1;
    return;
  }
  
  KJoint rightHand = skeleton.getJoints()[KinectPV2.JointType_HandRight];
                    
  // Identify the square the RightHand belongs in.
  int x = floor(rightHand.getX());
  int y = floor(rightHand.getY());
  
  YA_rightHandX[YA_frameCounter] = x;
  YA_rightHandY[YA_frameCounter] = y;

  int dx = round(x/64.0);
  int dy = round(y/53.0);
  
  if (dy <= 1) dy = 1;
  else if (dy >= 7) dy = 7;
  
  YA_positionOnScreen[YA_frameCounter] = (dy*10)+dx;
}
// Draw RightHand location on output image as a square.
void YA_drawCurrRightHand(int x, int y) {
  for (int i=0; i < 360; i++) {
    for (int j=0; j < YA_CURR_MARK; j++) {
      float radX = x + sin(i) * (j);
      float radY = y + cos(i) * (j);
      YA_tempOutputImage.pixels[int(radX)+int(radY)*YA_WIDTH] = YA_currSilhouetteColor;
    }
  }
}

// Draw RightHand location on output image as a square.
void YA_drawCurrRightHandSquare(int x, int y) {
  for (int i = (-1)*YA_CURR_MARK + 2; i < YA_CURR_MARK - 1; i++) {
    YA_tempOutputImage.pixels[x + i + (y+4)*YA_WIDTH] = YA_currSilhouetteColor;
    YA_tempOutputImage.pixels[x + i + (y-4)*YA_WIDTH] = YA_currSilhouetteColor;
    YA_tempOutputImage.pixels[x + i + (y+3)*YA_WIDTH] = YA_currSilhouetteColor;
    YA_tempOutputImage.pixels[x + i + (y-3)*YA_WIDTH] = YA_currSilhouetteColor;
    YA_tempOutputImage.pixels[x + i + (y+2)*YA_WIDTH] = YA_currSilhouetteColor;
    YA_tempOutputImage.pixels[x + i + (y-2)*YA_WIDTH] = YA_currSilhouetteColor;
    YA_tempOutputImage.pixels[x + i + (y+1)*YA_WIDTH] = YA_currSilhouetteColor;
    YA_tempOutputImage.pixels[x + i + (y-1)*YA_WIDTH] = YA_currSilhouetteColor;
    YA_tempOutputImage.pixels[x + i + (y)*YA_WIDTH] = YA_currSilhouetteColor;
  }
}

// Draw previous RightHands' location on output image as a cross.
void YA_drawoldRightHand(int x, int y, color oldColor) {
  for (int i=0; i < YA_OLD_MARK - 1; i++) {
    // top left to bottom right corner
    YA_tempOutputImage.pixels[x+i + (y+i)*YA_WIDTH] = oldColor;
    YA_tempOutputImage.pixels[x+i + (y + (YA_OLD_MARK-2)-i)*YA_WIDTH] = oldColor;
    if (i != 0) {
      YA_tempOutputImage.pixels[x+i - 1 + (y+i)*YA_WIDTH] = oldColor;
      YA_tempOutputImage.pixels[x+i - 1 + (y + (YA_OLD_MARK-2)-i)*YA_WIDTH] = oldColor;
    }
    if (i != YA_OLD_MARK-2) {
      YA_tempOutputImage.pixels[x+i + 1 + (y+i)*YA_WIDTH] = oldColor;
      YA_tempOutputImage.pixels[x+i + 1 + (y + (YA_OLD_MARK-2)-i)*YA_WIDTH] = oldColor;
    }
  }
}

void YA_createOutputImage(color[] outputPixels, String filename) {
    filename = "./data/" + filename;
    YA_outputImage = createGraphics(YA_WIDTH, YA_HEIGHT);
    YA_outputImage.beginDraw();
    YA_outputImage.loadPixels();
    for (int i = 0; i < outputPixels.length; i += 1) {
      YA_outputImage.pixels[i] = outputPixels[i];
    }
    YA_outputImage.updatePixels();
    YA_outputImage.save(filename + ".png");
}

void saveBodyDataToDatabase() {
  // Save new body data to database
  for (int i = 0; i < YA_TOT_FRAMES; i++) {
   String pix = Arrays.toString(Arrays.copyOfRange(YA_pixelsToSave, i * YA_NUM_PIXELS, (i+1) * YA_NUM_PIXELS));
    Object[] frame =
      {YA_userId, i, YA_positionOnScreen[i], YA_red[i], YA_green[i], YA_blue[i], YA_rightHandX[i], YA_rightHandY[i], pix};
    YA_db.insertUpdateInDatabase("body_data", columnNames, frame);
  }
  println("Done writing to database");
  
  // Delete old users if necessary
  YA_db.query("SELECT COUNT(DISTINCT user_id) FROM body_data");
  if (YA_db.next()) {
    int numUsers = YA_db.getInt("COUNT(DISTINCT user_id)");
    if (numUsers > YA_MAX_USERS) {
      println("More than YA_MAX_USERS past users, deleting oldest user.");
      YA_db.query("SELECT MIN(user_id) from body_data");
      if (YA_db.next()) {
        int userToDelete = YA_db.getInt("MIN(user_id)");
        YA_db.query("DELETE FROM body_data WHERE user_id="+userToDelete);
        println("Deleted user number " + userToDelete);
      }
    }
  }
  YA_db.close();
  println("Closed database connection");
  YA_savedToDatabase = true;
}
