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
final int duration  = 20;
final int fps       = 16;
final int totframes = duration * fps;
final int numPixels = 512 * 424;
final int nJointChecks = 9; 
final String writepath = "./test.txt";
final String writepathJoint = "./testJoint.txt"; 

FileOutputStream stream;
FileOutputStream streamJoint;
int counter = 0;
byte[] pixelSave = new byte[totframes*numPixels];
byte[] jointsSave = new byte[nJointChecks*2*totframes]; 

byte[] red = new byte[numPixels];
byte[] blue = new byte[numPixels];
byte[] green = new byte[numPixels];

color[] prevColor = new color[numPixels];

PImage img;
PImage himg;
PImage outimg;

void setup() {
  img = createImage(512, 424, PImage.RGB);
  himg = createImage(512, 424, PImage.ARGB);
  outimg = createImage(512, 424, PImage.ARGB);

  size(1024, 848, P3D);
  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.enableDepthImg(true);
  kinect.enableSkeletonColorMap(true);
  kinect.init();

  try {
    stream = new FileOutputStream(writepath);
  } 
  catch (IOException ex) {
    ex.printStackTrace();
  }

  try {
    streamJoint = new FileOutputStream(writepathJoint);
  }
  catch (IOException ex) {
    ex.printStackTrace();
  }

  frameRate(fps);
  for (int i = 0; i < numPixels; i++) {
    heat_map.put(i, 0);
  }

  int broken = 1;
  while (broken == 1)
  {
    int[] rawData = kinect.getRawBodyTrack();
    for (int i = 0; i < numPixels; i++)
    {
      if (rawData[i] != 255) {
        //print("broken");
      } else {
        broken=0;
      }
    }
  }
}

void draw() {
  img.loadPixels();
  outimg.loadPixels();
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

    try {
      int start = millis();
      streamJoint.write(jointsSave, 0, totframes*nJointChecks*2);
      int end = millis();
      print("Total time to save joints is" + (end-start)/1000 + "seconds.\n");
      streamJoint.close();
      print("stream join closed.\n");
    }
    catch (IOException ex) {
    }
    print("ready to exit and close\n");

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
  
  //*percentage for controlling colors*//
  float percent = 0; //right hand
  float percent_2 = 0; //left hand
  float percent_3 = 0; //right knee
  float percent_4 = 0; //left knee

  //number of bodies tracked
  ArrayList<KSkeleton> skeletonArray = kinect.getSkeletonColorMap(); 
  for (int i = 0; i < skeletonArray.size(); i++) {
    KSkeleton skeleton = (KSkeleton) skeletonArray.get(i); 
    if (skeleton.isTracked()) {
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
    }
  }

  assert(rawData.length == numPixels);
  for (int i = 0; i < numPixels; i++) {

    if (rawData[i] != 255) {
      heat_map.put(i, heat_map.get(i)+1);
      int depth = rawdepthData[i] * 256 / 4000;
      color newColor = color(depth, 0, 255);

      //red == right hand, green == left
      
      /*comment below out for just color control or no heat map*/
      //color hcolor = color(percent*255, percent_2*255, (percent_3+percent_4)*255, heat_map.get(i)*factor*255/totframes); 
      /*uncomment below to enable only color control*/
      color hcolor = color(percent*255, percent_2*255, (percent_4+percent_3)*255, 300);
      img.pixels[i] = newColor;        
      himg.pixels[i] = hcolor;
      outimg.pixels[i] = hcolor;

      // Save the data to the 2D array.
      pixelSave[counter*numPixels + i] = byte(depth);
    } else {

      //color hncolor = color(heat_map.get(i), 0, 0);
      //color hncolor = color(percent*255, percent_2*255, (percent_3+percent_4)*255, heat_map.get(i)*factor*255/totframes);
      color hncolor = color(percent*255, percent_2*255, (percent_3+percent_4)*255, 255);
      himg.pixels[i] = hncolor;
      img.pixels[i] = color(0, 0, 0);
      himg.pixels[i] = color(0, 0, 0); //can comment this out so we can see everything in real time.
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
