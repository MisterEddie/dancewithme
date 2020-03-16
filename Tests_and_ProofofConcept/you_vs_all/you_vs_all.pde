import de.bezier.data.sql.*;
import de.bezier.data.sql.mapper.*;

import KinectPV2.*;
KinectPV2 kinect;
import java.lang.Long;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.Queue;

/*
 * Constants 
 */
final int DURATION  = 30;
final int FPS       = 16;
final int TOT_FRAMES = DURATION * FPS;
final int WIDTH = 512;
final int HEIGHT = 424;
final int NUM_PIXELS = WIDTH * HEIGHT;
final int CURR_MARK = 6; // size+1 of circle for current user's head location
final int OLD_MARK = 9; // size+1 of cross for old head locations
final String OUTPUT_FILENAME = "./data/output";
final String DB_PATH = "./data/you_vs_all_base.db";
final int MAX_USERS = 100; // max number of unique users in database

// Toggle what output image looks like.
// True: output image does not update unless current user is moving.
// False: output image updates even when current user is still.
final boolean NO_OUTPUT_WHEN_STILL = true;
final boolean OUTPUT_BODIES = false;

int frameCounter = 0;
// data to save to database
int[] pixelsToSave = new int[TOT_FRAMES*NUM_PIXELS];
int[] positionOnScreen = new int[TOT_FRAMES];
int[] headX = new int[TOT_FRAMES];
int[] headY = new int[TOT_FRAMES];
int[] red = new int[TOT_FRAMES];
int[] green = new int[TOT_FRAMES];
int[] blue = new int[TOT_FRAMES];
int userId;

//Associated with median filtering
MedianFilter curr;
int[] pixelTemp = new int[NUM_PIXELS];
final int MFILTERORDER = 2;

// Queue for fading out silhouettes
Queue<ArrayList<Integer>> q = new LinkedList<ArrayList<Integer>>();
// Hashmap for storing colors of previous silhouettes (user_id: color)
HashMap<Integer, Integer> oldSilhouetteColors = new HashMap<Integer, Integer>();

// database
SQLite db;
final String[] columnNames = {
    "user_id", "frame_number", "position_on_screen",
    "red", "green", "blue",
    "body_x", "body_y", "body_pixels"
  };

// images
PImage liveImage;
PImage tempOutputImage;
PGraphics outputImage;

// current silhouette color
color currSilhouetteColor;

// Skeleton array
ArrayList<KSkeleton> skeletonArray;

void setup() {
  size(1024, 424, P3D);
  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.enableSkeletonDepthMap(true); 
  kinect.enableDepthImg(true);
  kinect.init();
  
  // Initialize images
  liveImage = createImage(WIDTH, HEIGHT, PImage.RGB);
  tempOutputImage = createImage(WIDTH, HEIGHT, PImage.RGB);
  
  // set image backgrounds to black
  liveImage.loadPixels();
  tempOutputImage.loadPixels();
  for (int i = 0; i < NUM_PIXELS; i++) {
    liveImage.pixels[i] = color(0);
    tempOutputImage.pixels[i] = color(0);
  }
  liveImage.updatePixels();
  tempOutputImage.updatePixels();
  
  db = new SQLite( this, DB_PATH );  // open database file  
  
  // set debug on/off
  db.setDebug(false);
  
  // set user ID
  if (db.connect()) {
    db.query("SELECT MAX(user_id) FROM body_data");
    if (db.next()) {
      userId = db.getInt("MAX(user_id)") + 1;
    }
    else {
      userId = 1; //  first user!
    }
  }
  else {
    // exit, there is a problem
    println("Could not connect to database");
    exit();
    return;
  }
  
  // Create Median Filter object
  curr = new MedianFilter(NUM_PIXELS, TOT_FRAMES, HEIGHT, WIDTH, MFILTERORDER);
  
  frameRate(FPS);
  
  // try to avoid green screen
  boolean broken = true;
  while (broken)
  {
    int[] rawData = kinect.getRawBodyTrack();
    for (int i = 0; i < NUM_PIXELS; i++)
    {
      if (rawData[i] == 255) {
        broken = false;
        break;
      }
    }
  }
}

void draw() {
    liveImage.loadPixels(); 
    tempOutputImage.loadPixels();

     // End the sketch.
    if (frameCounter == TOT_FRAMES) {
      // Save new body data to database
      for (int i = 0; i < TOT_FRAMES; i++) {
       String pix = Arrays.toString(Arrays.copyOfRange(pixelsToSave, i * NUM_PIXELS, (i+1) * NUM_PIXELS));
        Object[] frame =
          {userId, i, positionOnScreen[i], red[i], green[i], blue[i], headX[i], headY[i], pix};
        db.insertUpdateInDatabase("body_data", columnNames, frame);
      }
      println("Done writing to database");
      
      // Delete old users if more than 100 in the database
      db.query("SELECT COUNT(DISTINCT user_id) FROM body_data");
      if (db.next()) {
        int numUsers = db.getInt("COUNT(DISTINCT user_id)");
        if (numUsers > MAX_USERS) {
          db.query("SELECT MIN(user_id) from body_data");
          if (db.next()) {
            int userToDelete = db.getInt("MIN(user_id)");
            db.query("DELETE FROM body_data WHERE user_id="+userToDelete);
            println("Deleted user number " + userToDelete);
          }
        }
      }
      db.close();
      createOutputImage(tempOutputImage.pixels, OUTPUT_FILENAME);
      exit();
      return;
    } 
     
    /****************
     * Main loop code
     ****************/
    int [] rawData = kinect.getRawBodyTrack();
    skeletonArray = kinect.getSkeletonDepthMap();
    
    int off = 0;
    curr.filterFrame(rawData, pixelTemp, off);
    rawData = pixelTemp;
    
    // Calculate current color of silhouette
    setCurrSilhouetteColor();    
    // Set data about head position
    setHeadData();

    // Now draw current user's head location on top
    int currHeadX = headX[frameCounter];
    int currHeadY = headY[frameCounter];
    if (!OUTPUT_BODIES && currHeadX > CURR_MARK && currHeadY > CURR_MARK &&
      currHeadX < WIDTH - CURR_MARK && currHeadY < HEIGHT - CURR_MARK) {
        drawCurrHead(currHeadX,currHeadY);
    }
    int currHeadPosition = positionOnScreen[frameCounter];
    db.query(
      "SELECT * FROM body_data WHERE frame_number=" +
      frameCounter +
      " AND position_on_screen=" +
      currHeadPosition +
      " LIMIT 3");
    
    // Load in silhouette data for this frame
    ArrayList<Object[]> oldFigures = new ArrayList<Object[]>();
    ArrayList<Integer> userIds = new ArrayList<Integer>();
    
    // Go through between 0-3 past users
    int numOldUsersRetrieved = 0;
    while (db.next()) {
      // Load in database info
      String dbcontent =  (String) db.getObject("body_pixels");
      int oldId = db.getInt("user_id");
      int oldR = db.getInt("red");
      int oldG = db.getInt("green");
      int oldB = db.getInt("blue");
      color oldColor = color(oldR, oldG, oldB);
      // remove [] from string
      dbcontent = dbcontent.substring(1, dbcontent.length()-1);
      String[] pixelData = dbcontent.split(", ");
      Object[] userAndPixels = {oldId, pixelData};
      oldFigures.add(userAndPixels);
      userIds.add(oldId);
      oldSilhouetteColors.put(oldId, oldColor); 
      numOldUsersRetrieved++;
      
      int oldHeadX = db.getInt("body_x");
      int oldHeadY = db.getInt("body_y");
      if (!OUTPUT_BODIES && oldHeadX > OLD_MARK && oldHeadY > OLD_MARK &&
        oldHeadX < WIDTH - OLD_MARK && oldHeadY < HEIGHT - OLD_MARK) {
          drawOldHead(oldHeadX, oldHeadY, oldColor);
      }
    }
    
    // Load trails of silhouettes from 1-3 timesteps ago
    String str = "";
    for (ArrayList<Integer> item: q) {
      for (int i = 0; i < item.size(); i++) {
        int currUser = item.get(i);
        if (!userIds.contains(currUser))
          str += " OR user_id=" + String.valueOf(currUser);
      }
    }
    
    db.query(
      "SELECT user_id, body_x, body_y, body_pixels FROM body_data WHERE frame_number=" +
      frameCounter +
      " AND (user_id=-1" +
      str +
      ")" );
      
    while (db.next()) {
      int oldId = db.getInt("user_id");
      String dbcontent =  (String) db.getObject("body_pixels");
      dbcontent = dbcontent.substring(1, dbcontent.length()-1);
      String[] pixelData = dbcontent.split(", ");
      Object[] userAndPixels = {oldId, pixelData};
      oldFigures.add(userAndPixels);

      // draw old head
      int oldHeadX = db.getInt("body_x");
      int oldHeadY = db.getInt("body_y");
      
      if (!OUTPUT_BODIES && oldHeadX > OLD_MARK && oldHeadY > OLD_MARK &&
        oldHeadX < WIDTH - OLD_MARK && oldHeadY < HEIGHT - OLD_MARK) {
          drawOldHead(oldHeadX, oldHeadY, oldSilhouetteColors.get(oldId));
      }
    }
    
    // Update queue of past users' silhouettes to display
    if (q.size() >= 3) {
      q.remove(); // ensure it goes away after half a second
    }
    q.add(userIds); // add old users
    
    // Draw the pixels
    for (int i = 0; i < NUM_PIXELS; i++) {
      
      int localData = rawData[i];
      boolean pixelHasColor = false;
      
      color newColor = color(0,0,0);

      int numFigures = oldFigures.size();
      for (int j = 0; j < numFigures; j++) {
        String[] savedData = (String[]) oldFigures.get(j)[1];
        int savedDataInt = Integer.parseInt(savedData[i]);
        if (savedDataInt == 1) {
          newColor = oldSilhouetteColors.get(oldFigures.get(j)[0]);
          pixelHasColor = true;
          // add old silhouette
          if (OUTPUT_BODIES) {
            if (NO_OUTPUT_WHEN_STILL &&
              abs(headX[max(0, frameCounter-1)] - headX[frameCounter]) > 1 &&
              abs(headY[max(0, frameCounter-1)] - headY[frameCounter]) > 1
            ) {
              tempOutputImage.pixels[i] = newColor;
            }
            else if (j < numOldUsersRetrieved) {
              tempOutputImage.pixels[i] = newColor;
            }
          }
          break;
        }
      }
      
      // Paint current silhouette on top and store color
      if ((localData != 255)) {
        newColor = currSilhouetteColor;
        pixelHasColor = true;
      }
      
      if (!pixelHasColor) {
        // fade away the background
          color lastFadeColor = liveImage.pixels[i];
          float newR = max(0, red(lastFadeColor)-40.0);
          float newG = max(0, green(lastFadeColor)-40.0);
          float newB = max(0, blue(lastFadeColor)-40.0);
          color fadedColor = color(newR, newG, newB);
          liveImage.pixels[i] = fadedColor;
      }
      else {
        liveImage.pixels[i] = newColor;
      }
      // Add old silhouette to pixelsToSave
      if (localData != 255) {
        pixelsToSave[frameCounter*NUM_PIXELS + i] = 1;
      } else {
        pixelsToSave[frameCounter*NUM_PIXELS + i] = 0;
      }
    }


    liveImage.updatePixels();
    tempOutputImage.updatePixels();
    
    // Render images
    image(liveImage, 0, 0); // left
    image(tempOutputImage, WIDTH, 0); // right
    frameCounter++;
}

void setCurrSilhouetteColor() {
    float currSilhouetteR = 0;
    float currSilhouetteG = 0;
    float currSilhouetteB = 0;
    if (skeletonArray.size() > 0) {
       KSkeleton skeleton = (KSkeleton) skeletonArray.get(0);
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
    red[frameCounter] = int(currSilhouetteR);
    green[frameCounter] = int(currSilhouetteG);
    blue[frameCounter] = int(currSilhouetteB);
    currSilhouetteColor = color(currSilhouetteR, currSilhouetteG, currSilhouetteB);
}

/*
* Sets head data.
*/
void setHeadData() {
  if (skeletonArray.size() == 0) {
    headX[frameCounter] = -1;
    headY[frameCounter] = -1;
    positionOnScreen[frameCounter] = -1;
    return;
  }
  
  KSkeleton skeleton = (KSkeleton) skeletonArray.get(0);
  if (!skeleton.isTracked()) {
    headX[frameCounter] = -1;
    headY[frameCounter] = -1;
    positionOnScreen[frameCounter] = -1;
    return;
  }
  
  KJoint head = skeleton.getJoints()[KinectPV2.JointType_HandRight];
                    
  // Identify the head belongs in.
  int x = floor(head.getX());
  int y = floor(head.getY());
  
  headX[frameCounter] = x;
  headY[frameCounter] = y;

  int dx = round(x/64.0);
  int dy = round(y/53.0);
  
  if (dy <= 2) dy = 1;
  else if (dy == 3) dy = 2;
  else if (dy == 4) dy = 3;
  else dy = 4;
  
  positionOnScreen[frameCounter] = (dy*10)+dx;
}
// Draw head location on output image as a square.
void drawCurrHead(int x, int y) {
  for (int i=0; i < 360; i++) {
    for (int j=0; j < CURR_MARK; j++) {
      float radX = x + sin(i) * (j);
      float radY = y + cos(i) * (j);
      tempOutputImage.pixels[int(radX)+int(radY)*WIDTH] = currSilhouetteColor;
    }
  }
}

// Draw head location on output image as a square.
void drawCurrHeadSquare(int x, int y) {
  for (int i = (-1)*CURR_MARK + 2; i < CURR_MARK - 1; i++) {
    tempOutputImage.pixels[x + i + (y+4)*WIDTH] = currSilhouetteColor;
    tempOutputImage.pixels[x + i + (y-4)*WIDTH] = currSilhouetteColor;
    tempOutputImage.pixels[x + i + (y+3)*WIDTH] = currSilhouetteColor;
    tempOutputImage.pixels[x + i + (y-3)*WIDTH] = currSilhouetteColor;
    tempOutputImage.pixels[x + i + (y+2)*WIDTH] = currSilhouetteColor;
    tempOutputImage.pixels[x + i + (y-2)*WIDTH] = currSilhouetteColor;
    tempOutputImage.pixels[x + i + (y+1)*WIDTH] = currSilhouetteColor;
    tempOutputImage.pixels[x + i + (y-1)*WIDTH] = currSilhouetteColor;
    tempOutputImage.pixels[x + i + (y)*WIDTH] = currSilhouetteColor;
  }
}

// Draw previous heads' location on output image as a cross.
void drawOldHead(int x, int y, color oldColor) {
  for (int i=0; i < OLD_MARK - 1; i++) {
    // top left to bottom right corner
    tempOutputImage.pixels[x+i + (y+i)*WIDTH] = oldColor;
    tempOutputImage.pixels[x+i + (y + (OLD_MARK-2)-i)*WIDTH] = oldColor;
    if (i != 0) {
      tempOutputImage.pixels[x+i - 1 + (y+i)*WIDTH] = oldColor;
      tempOutputImage.pixels[x+i - 1 + (y + (OLD_MARK-2)-i)*WIDTH] = oldColor;
    }
    if (i != OLD_MARK-2) {
      tempOutputImage.pixels[x+i + 1 + (y+i)*WIDTH] = oldColor;
      tempOutputImage.pixels[x+i + 1 + (y + (OLD_MARK-2)-i)*WIDTH] = oldColor;
    }
  }
}

void createOutputImage(color[] outputPixels, String filename) {
    outputImage = createGraphics(WIDTH, HEIGHT);
    outputImage.beginDraw();
    outputImage.loadPixels();
    for (int i = 0; i < outputPixels.length; i += 1) {
      outputImage.pixels[i] = outputPixels[i];
    }
    outputImage.updatePixels();
    outputImage.save(filename + userId + ".png");
}
