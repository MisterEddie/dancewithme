import KinectPV2.*;
KinectPV2 kinect;
import java.lang.Long;
import java.io.FileOutputStream;
import java.io.IOException;

/*
 * Constants 
 */
final int duration  = 60;
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


/*
 * constants for joints
 */
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
/* 
 * end Joint shit 
 */

void setup() {
  size(512, 424, P3D);
  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.enableDepthImg(true);
  kinect.enableSkeletonColorMap(true); 
  
  kinect.init();
  try {
    stream = new FileOutputStream(writepath);
  
  } catch (IOException ex) {
    ex.printStackTrace();
  }
  
  try{
    streamJoint = new FileOutputStream(writepathJoint); 
  } catch (IOException ex) {
    ex.printStackTrace();
  }
  frameRate(fps);
}

void draw() {
    background(0);
    loadPixels();  
    
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
      } catch (IOException ex) {}
      
      try {
        int start = millis();        
            streamJoint.write(jointsSave, 0, totframes*nJointChecks*2);
        int end = millis();
        print("Total time to save joints is " + (end-start)/1000 + " seconds.\n");
        streamJoint.close();
        print("stream joint closed. \n"); 
      } catch (IOException ex) {}
      print("ready to exit and close. \n"); 
      /* 
       * These set of statements TOGETHER will exit the program immediately
       */
      exit();
      print("exited.\n");
      return;
    }
    
    /*
     * Main loop code
     */
    int [] rawData = kinect.getRawBodyTrack();
    int [] rawdepthData = kinect.getRawDepthData();
    
    assert(rawData.length == numPixels);
    for(int i = 0; i < numPixels; i++){
      if(rawData[i] != 255){
        int depth = rawdepthData[i] * 256 / 4000;
        color newColor = color(depth, 0, 255);
        pixels[i] = newColor;        
        
        // Save the data to the 2D array.
        pixelSave[counter*numPixels + i] = byte(depth);
      } 
    }
    
    ArrayList<KSkeleton> skeletonArray = kinect.getSkeletonColorMap(); 
    for(int i = 0; i < skeletonArray.size(); i++){
      KSkeleton skeleton = (KSkeleton) skeletonArray.get(i); 
      if(skeleton.isTracked()){
        KJoint[] joints = skeleton.getJoints();
        jointChecks(joints); 
      }
    }
    uncomp_saveJoints(); 
  
    updatePixels();      
    counter++;
}


void uncomp_saveJoints(){
  jointsSave[0 + counter*nJointChecks*2] = NECK_RIGHT_OF_TORSO[0]; 
  jointsSave[1 + counter*nJointChecks*2] = NECK_RIGHT_OF_TORSO[1]; 
  
  jointsSave[2 + counter*nJointChecks*2] = RIGHT_WRIST_ABOVE_RIGHT_ELBOW[0];
  jointsSave[3 + counter*nJointChecks*2] = RIGHT_WRIST_ABOVE_RIGHT_ELBOW[1];
  jointsSave[4 + counter*nJointChecks*2] = LEFT_WRIST_ABOVE_LEFT_ELBOW[0];
  jointsSave[5 + counter*nJointChecks*2] = LEFT_WRIST_ABOVE_LEFT_ELBOW[1];
  
  jointsSave[6 + counter*nJointChecks*2] = RIGHT_KNEE_RIGHT_OF_RIGHT_ANKLE[0];
  jointsSave[7 + counter*nJointChecks*2] = RIGHT_KNEE_RIGHT_OF_RIGHT_ANKLE[1];
  jointsSave[8 + counter*nJointChecks*2] = LEFT_KNEE_RIGHT_OF_LEFT_ANKLE[0];
  jointsSave[9 + counter*nJointChecks*2] = LEFT_KNEE_RIGHT_OF_LEFT_ANKLE[1];
  
  jointsSave[10 + counter*nJointChecks*2] = RIGHT_WRIST_ABOVE_NECK[0];
  jointsSave[11 + counter*nJointChecks*2] = RIGHT_WRIST_ABOVE_NECK[1];
  jointsSave[12 + counter*nJointChecks*2] = LEFT_WRIST_ABOVE_NECK[0];
  jointsSave[13 + counter*nJointChecks*2] = LEFT_WRIST_ABOVE_NECK[1];
  
  jointsSave[14 + counter*nJointChecks*2] = RIGHT_WRIST_ABOVE_TORSO[0];
  jointsSave[15 + counter*nJointChecks*2] = RIGHT_WRIST_ABOVE_TORSO[1];
  jointsSave[16 + counter*nJointChecks*2] = LEFT_WRIST_ABOVE_TORSO[0];
  jointsSave[17 + counter*nJointChecks*2] = LEFT_WRIST_ABOVE_TORSO[1];     
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
