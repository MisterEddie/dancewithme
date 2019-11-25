import KinectPV2.*;
import java.lang.Long;
import java.io.FileOutputStream;
import java.io.IOException;

public class JointChecks{
  
  KinectPV2 KINECT; 
  
  private int TOTAL_FRAMES; 
  private int NUM_JOINT_CHECKS;
  
  private byte[] CHECKS; 
  private byte[] F_CHECKS;
  private final double THRESHOLD = 0.1; 
  
  // indices of checks 
  public final int i_HEAD_TILTED_RIGHT = 0; 
  public final int i_BENT_DOWN = 1; 
  
  public final int i_RIGHT_WRIST_ABOVE_RIGHT_ELBOW = 2; 
  public final int i_RIGHT_WRIST_ABOVE_TORSO = 3; 
  public final int i_RIGHT_WRIST_ABOVE_HEAD = 4; 
  
  public final int i_LEFT_WRIST_ABOVE_LEFT_ELBOW = 5; 
  public final int i_LEFT_WRIST_ABOVE_TORSO = 6; 
  public final int i_LEFT_WRIST_ABOVE_HEAD = 7; 
  
  public final int i_RIGHT_ANKLE_RIGHT_OF_RIGHT_KNEE = 8; 
  public final int i_RIGHT_KNEE_ABOVE_RIGHT_HIP = 9; 
  public final int i_RIGHT_ANKLE_ABOVE_RIGHT_KNEE = 10; 
  
  public final int i_LEFT_ANKLE_RIGHT_OF_LEFT_KNEE = 11; 
  public final int i_LEFT_KNEE_ABOVE_LEFT_HIP = 12; 
  public final int i_LEFT_ANKLE_ABOVE_LEFT_KNEE = 13; 
  
  public final int i_LEFT_WRIST_RIGHT_OF_RIGHT_WRIST = 14; 
  public final int i_LEFT_ANKLE_RIGHT_OF_RIGHT_ANKLE = 15; 
  
  // check values 
  private byte HEAD_TILTED_RIGHT; 
  private byte BENT_DOWN; 
  
  private byte RIGHT_WRIST_ABOVE_RIGHT_ELBOW; 
  private byte RIGHT_WRIST_ABOVE_TORSO; 
  private byte RIGHT_WRIST_ABOVE_HEAD; 
  
  private byte LEFT_WRIST_ABOVE_LEFT_ELBOW; 
  private byte LEFT_WRIST_ABOVE_TORSO; 
  private byte LEFT_WRIST_ABOVE_HEAD; 
  
  private byte RIGHT_ANKLE_RIGHT_OF_RIGHT_KNEE; 
  private byte RIGHT_KNEE_ABOVE_RIGHT_HIP; 
  private byte RIGHT_ANKLE_ABOVE_RIGHT_KNEE; 
  
  private byte LEFT_ANKLE_RIGHT_OF_LEFT_KNEE; 
  private byte LEFT_KNEE_ABOVE_LEFT_HIP; 
  private byte LEFT_ANKLE_ABOVE_LEFT_KNEE; 
  
  private byte LEFT_WRIST_RIGHT_OF_RIGHT_WRIST; 
  private byte LEFT_ANKLE_RIGHT_OF_RIGHT_ANKLE; 
  
  // positions 
  private int NUM_POSITION_CHECKS = 8; 
  private float[] F_POSITION_CHECKS; 
  private float[] POSITION_CHECKS; 
  public final int i_LEFT_SHOULDER_TO_ELBOW = 0; 
  public final int i_LEFT_ELBOW_TO_WRIST = 1; 
  public final int i_RIGHT_SHOULDER_TO_ELBOW = 2; 
  public final int i_RIGHT_ELBOW_TO_WRIST = 3; 
  public final int i_LEFT_HIP_TO_KNEE = 4; 
  public final int i_LEFT_KNEE_TO_ANKLE = 5; 
  public final int i_RIGHT_HIP_TO_KNEE = 6; 
  public final int i_RIGHT_KNEE_TO_ANKLE = 7; 
  
  private float o_LEFT_SHOULDER_TO_ELBOW; 
  private float o_LEFT_ELBOW_TO_WRIST; 
  private float o_RIGHT_SHOULDER_TO_ELBOW; 
  private float o_RIGHT_ELBOW_TO_WRIST; 
  private float o_LEFT_HIP_TO_KNEE; 
  private float o_LEFT_KNEE_TO_ANKLE; 
  private float o_RIGHT_HIP_TO_KNEE; 
  private float o_RIGHT_KNEE_TO_ANKLE; 
  
  public JointChecks(int total_frames, KinectPV2 kinect, int numJointChecks){
    TOTAL_FRAMES = total_frames; 
    KINECT = kinect; 
    NUM_JOINT_CHECKS = numJointChecks;
    CHECKS = new byte[TOTAL_FRAMES * NUM_JOINT_CHECKS];
    F_POSITION_CHECKS = new float[NUM_POSITION_CHECKS]; 
    POSITION_CHECKS = new float[TOTAL_FRAMES*NUM_POSITION_CHECKS]; 
    F_CHECKS = new byte[NUM_JOINT_CHECKS]; 
    
  }
  
  public void runJointChecks(){
    ArrayList<KSkeleton> skeletonArray = KINECT.getSkeletonColorMap(); 
    for(int i = 0; i < skeletonArray.size(); i++){
      KSkeleton skeleton = (KSkeleton) skeletonArray.get(i); 
      if(skeleton.isTracked()){
        KJoint[] joints = skeleton.getJoints(); 
        checkJoints(joints); 
      }
    }
  }
  
  public void storeJointChecks(int counter){
    CHECKS[i_HEAD_TILTED_RIGHT + counter*NUM_JOINT_CHECKS] = HEAD_TILTED_RIGHT; 
    CHECKS[i_BENT_DOWN + counter*NUM_JOINT_CHECKS] = BENT_DOWN; 
    
    CHECKS[i_RIGHT_WRIST_ABOVE_RIGHT_ELBOW + counter*NUM_JOINT_CHECKS] = RIGHT_WRIST_ABOVE_RIGHT_ELBOW; 
    CHECKS[i_RIGHT_WRIST_ABOVE_TORSO + counter*NUM_JOINT_CHECKS] = RIGHT_WRIST_ABOVE_TORSO; 
    CHECKS[i_RIGHT_WRIST_ABOVE_HEAD + counter*NUM_JOINT_CHECKS] = RIGHT_WRIST_ABOVE_HEAD; 
    
    CHECKS[i_LEFT_WRIST_ABOVE_LEFT_ELBOW + counter*NUM_JOINT_CHECKS] = LEFT_WRIST_ABOVE_LEFT_ELBOW; 
    CHECKS[i_LEFT_WRIST_ABOVE_TORSO + counter*NUM_JOINT_CHECKS] = LEFT_WRIST_ABOVE_TORSO; 
    CHECKS[i_LEFT_WRIST_ABOVE_HEAD + counter*NUM_JOINT_CHECKS] = LEFT_WRIST_ABOVE_HEAD; 
    
    CHECKS[i_RIGHT_ANKLE_RIGHT_OF_RIGHT_KNEE + counter*NUM_JOINT_CHECKS] = RIGHT_ANKLE_RIGHT_OF_RIGHT_KNEE; 
    CHECKS[i_RIGHT_KNEE_ABOVE_RIGHT_HIP + counter*NUM_JOINT_CHECKS] = RIGHT_KNEE_ABOVE_RIGHT_HIP; 
    CHECKS[i_RIGHT_ANKLE_ABOVE_RIGHT_KNEE + counter*NUM_JOINT_CHECKS] = RIGHT_ANKLE_ABOVE_RIGHT_KNEE; 
    
    CHECKS[i_LEFT_ANKLE_RIGHT_OF_LEFT_KNEE + counter*NUM_JOINT_CHECKS] = LEFT_ANKLE_RIGHT_OF_LEFT_KNEE; 
    CHECKS[i_LEFT_KNEE_ABOVE_LEFT_HIP + counter*NUM_JOINT_CHECKS] = LEFT_KNEE_ABOVE_LEFT_HIP; 
    CHECKS[i_LEFT_ANKLE_ABOVE_LEFT_KNEE + counter*NUM_JOINT_CHECKS] = LEFT_ANKLE_ABOVE_LEFT_KNEE; 
    
    CHECKS[i_LEFT_WRIST_RIGHT_OF_RIGHT_WRIST + counter*NUM_JOINT_CHECKS] = LEFT_WRIST_RIGHT_OF_RIGHT_WRIST; 
    CHECKS[i_LEFT_ANKLE_RIGHT_OF_RIGHT_ANKLE + counter*NUM_JOINT_CHECKS] = LEFT_ANKLE_RIGHT_OF_RIGHT_ANKLE; 
    
    
    POSITION_CHECKS[i_LEFT_SHOULDER_TO_ELBOW + counter*NUM_POSITION_CHECKS] = o_LEFT_SHOULDER_TO_ELBOW; 
    POSITION_CHECKS[i_LEFT_ELBOW_TO_WRIST + counter*NUM_POSITION_CHECKS] = o_LEFT_ELBOW_TO_WRIST; 
    POSITION_CHECKS[i_RIGHT_SHOULDER_TO_ELBOW + counter*NUM_POSITION_CHECKS] = o_RIGHT_SHOULDER_TO_ELBOW; 
    POSITION_CHECKS[i_RIGHT_ELBOW_TO_WRIST + counter*NUM_POSITION_CHECKS] = o_RIGHT_ELBOW_TO_WRIST; 
    POSITION_CHECKS[i_LEFT_HIP_TO_KNEE + counter*NUM_POSITION_CHECKS] = o_LEFT_HIP_TO_KNEE; 
    POSITION_CHECKS[i_LEFT_KNEE_TO_ANKLE + counter*NUM_POSITION_CHECKS] = o_LEFT_KNEE_TO_ANKLE; 
    POSITION_CHECKS[i_RIGHT_HIP_TO_KNEE + counter*NUM_POSITION_CHECKS] = o_RIGHT_HIP_TO_KNEE; 
    POSITION_CHECKS[i_RIGHT_KNEE_TO_ANKLE + counter*NUM_POSITION_CHECKS] = o_RIGHT_KNEE_TO_ANKLE; 
  }
  
  public void storeFrameJointChecks(){
    F_CHECKS[i_HEAD_TILTED_RIGHT] = HEAD_TILTED_RIGHT; 
    F_CHECKS[i_BENT_DOWN] = BENT_DOWN; 
    
    F_CHECKS[i_RIGHT_WRIST_ABOVE_RIGHT_ELBOW] = RIGHT_WRIST_ABOVE_RIGHT_ELBOW; 
    F_CHECKS[i_RIGHT_WRIST_ABOVE_TORSO] = RIGHT_WRIST_ABOVE_TORSO; 
    F_CHECKS[i_RIGHT_WRIST_ABOVE_HEAD] = RIGHT_WRIST_ABOVE_HEAD; 
    
    F_CHECKS[i_LEFT_WRIST_ABOVE_LEFT_ELBOW] = LEFT_WRIST_ABOVE_LEFT_ELBOW; 
    F_CHECKS[i_LEFT_WRIST_ABOVE_TORSO] = LEFT_WRIST_ABOVE_TORSO; 
    F_CHECKS[i_LEFT_WRIST_ABOVE_HEAD] = LEFT_WRIST_ABOVE_HEAD; 
    
    F_CHECKS[i_RIGHT_ANKLE_RIGHT_OF_RIGHT_KNEE] = RIGHT_ANKLE_RIGHT_OF_RIGHT_KNEE; 
    F_CHECKS[i_RIGHT_KNEE_ABOVE_RIGHT_HIP] = RIGHT_KNEE_ABOVE_RIGHT_HIP; 
    F_CHECKS[i_RIGHT_ANKLE_ABOVE_RIGHT_KNEE] = RIGHT_ANKLE_ABOVE_RIGHT_KNEE; 
    
    F_CHECKS[i_LEFT_ANKLE_RIGHT_OF_LEFT_KNEE] = LEFT_ANKLE_RIGHT_OF_LEFT_KNEE; 
    F_CHECKS[i_LEFT_KNEE_ABOVE_LEFT_HIP] = LEFT_KNEE_ABOVE_LEFT_HIP; 
    F_CHECKS[i_LEFT_ANKLE_ABOVE_LEFT_KNEE] = LEFT_ANKLE_ABOVE_LEFT_KNEE; 
    
    F_CHECKS[i_LEFT_WRIST_RIGHT_OF_RIGHT_WRIST] = LEFT_WRIST_RIGHT_OF_RIGHT_WRIST; 
    F_CHECKS[i_LEFT_ANKLE_RIGHT_OF_RIGHT_ANKLE] = LEFT_ANKLE_RIGHT_OF_RIGHT_ANKLE; 

    F_POSITION_CHECKS[i_LEFT_SHOULDER_TO_ELBOW] = o_LEFT_SHOULDER_TO_ELBOW; 
    F_POSITION_CHECKS[i_LEFT_ELBOW_TO_WRIST] = o_LEFT_ELBOW_TO_WRIST; 
    F_POSITION_CHECKS[i_RIGHT_SHOULDER_TO_ELBOW] = o_RIGHT_SHOULDER_TO_ELBOW; 
    F_POSITION_CHECKS[i_RIGHT_ELBOW_TO_WRIST] = o_RIGHT_ELBOW_TO_WRIST; 
    F_POSITION_CHECKS[i_LEFT_HIP_TO_KNEE] = o_LEFT_HIP_TO_KNEE; 
    F_POSITION_CHECKS[i_LEFT_KNEE_TO_ANKLE] = o_LEFT_KNEE_TO_ANKLE; 
    F_POSITION_CHECKS[i_RIGHT_HIP_TO_KNEE] = o_RIGHT_HIP_TO_KNEE; 
    F_POSITION_CHECKS[i_RIGHT_KNEE_TO_ANKLE] = o_RIGHT_KNEE_TO_ANKLE; 
    
  }
  
  public byte getJointCheckFromAll(int check_index){
    return CHECKS[check_index]; 
  }
  
  public byte getJointCheckFromFrame(int check_index){
    return F_CHECKS[check_index]; 
  }
  
  public float getPositionCheckFromAll(int check_index){
    return POSITION_CHECKS[check_index]; 
  }
  
  public float getPositionCheckFromFrame(int check_index){
    return F_POSITION_CHECKS[check_index];
  }
  
  public byte[] getFrameJointChecks(){
    return F_CHECKS;
  }
  
  public byte[] getJointChecks(){
    return CHECKS; 
  }
  
  public int getNumJointChecks(){
    return NUM_JOINT_CHECKS;
  }
  
  public float[] getPositionChecks(){
    return POSITION_CHECKS; 
  }
  
  public float[] getFramePositionChecks(){
    return F_POSITION_CHECKS;
  }
    
  private void checkJoints(KJoint[] joints){
     
    // joint checks: 
    HEAD_TILTED_RIGHT = isCenterisRight(joints, KinectPV2.JointType_Head, KinectPV2.JointType_SpineShoulder);
    BENT_DOWN = isCenterisAbove(joints, KinectPV2.JointType_Head, KinectPV2.JointType_SpineMid); 
    
    RIGHT_WRIST_ABOVE_RIGHT_ELBOW = isCenterisAbove(joints, KinectPV2.JointType_WristRight, KinectPV2.JointType_ElbowRight); 
    RIGHT_WRIST_ABOVE_TORSO = isCenterisAbove(joints, KinectPV2.JointType_WristRight, KinectPV2.JointType_SpineMid); 
    RIGHT_WRIST_ABOVE_HEAD = isCenterisAbove(joints, KinectPV2.JointType_WristRight, KinectPV2.JointType_Head); 
    
    LEFT_WRIST_ABOVE_LEFT_ELBOW = isCenterisAbove(joints, KinectPV2.JointType_WristLeft, KinectPV2.JointType_ElbowLeft); 
    LEFT_WRIST_ABOVE_TORSO = isCenterisAbove(joints, KinectPV2.JointType_WristLeft, KinectPV2.JointType_SpineMid);
    LEFT_WRIST_ABOVE_HEAD = isCenterisAbove(joints, KinectPV2.JointType_WristLeft, KinectPV2.JointType_Head); 
    
    RIGHT_ANKLE_RIGHT_OF_RIGHT_KNEE = isCenterisRight(joints, KinectPV2.JointType_AnkleRight, KinectPV2.JointType_KneeRight); 
    RIGHT_KNEE_ABOVE_RIGHT_HIP = isCenterisRight(joints, KinectPV2.JointType_KneeRight, KinectPV2.JointType_HipRight); 
    RIGHT_ANKLE_ABOVE_RIGHT_KNEE = isCenterisAbove(joints, KinectPV2.JointType_AnkleRight, KinectPV2.JointType_KneeRight); 
    
    LEFT_ANKLE_RIGHT_OF_LEFT_KNEE = isCenterisRight(joints, KinectPV2.JointType_AnkleLeft, KinectPV2.JointType_KneeLeft); 
    LEFT_KNEE_ABOVE_LEFT_HIP = isCenterisAbove(joints, KinectPV2.JointType_KneeLeft, KinectPV2.JointType_HipLeft); 
    LEFT_ANKLE_ABOVE_LEFT_KNEE = isCenterisAbove(joints, KinectPV2.JointType_AnkleLeft, KinectPV2.JointType_KneeLeft); 
    
    LEFT_WRIST_RIGHT_OF_RIGHT_WRIST = isCenterisRight(joints, KinectPV2.JointType_WristLeft, KinectPV2.JointType_WristRight); 
    LEFT_ANKLE_RIGHT_OF_RIGHT_ANKLE = isCenterisRight(joints, KinectPV2.JointType_AnkleLeft, KinectPV2.JointType_AnkleRight); 
    
    // position checks: 
    o_LEFT_SHOULDER_TO_ELBOW = PVecToAngle(getOrientation(joints, KinectPV2.JointType_ElbowLeft, KinectPV2.JointType_ShoulderLeft)); 
    o_LEFT_ELBOW_TO_WRIST= PVecToAngle(getOrientation(joints, KinectPV2.JointType_WristLeft, KinectPV2.JointType_ElbowLeft));
    o_RIGHT_SHOULDER_TO_ELBOW= PVecToAngle(getOrientation(joints, KinectPV2.JointType_ElbowRight, KinectPV2.JointType_ShoulderRight));  
    o_RIGHT_ELBOW_TO_WRIST = PVecToAngle(getOrientation(joints, KinectPV2.JointType_WristRight, KinectPV2.JointType_ElbowRight));  
    o_LEFT_HIP_TO_KNEE = PVecToAngle(getOrientation(joints, KinectPV2.JointType_KneeLeft, KinectPV2.JointType_HipLeft)); 
    o_LEFT_KNEE_TO_ANKLE = PVecToAngle(getOrientation(joints, KinectPV2.JointType_AnkleLeft, KinectPV2.JointType_KneeLeft)); 
    o_RIGHT_HIP_TO_KNEE = PVecToAngle(getOrientation(joints, KinectPV2.JointType_KneeRight, KinectPV2.JointType_HipRight)); 
    o_RIGHT_KNEE_TO_ANKLE = PVecToAngle(getOrientation(joints, KinectPV2.JointType_AnkleRight, KinectPV2.JointType_KneeRight)); 
  }
  
  
  private byte isCenterisRight(KJoint[] joints, int jointType1, int jointType2){
    PVector orientation = getOrientation(joints, jointType1, jointType2); 
    
    byte isCenterisRight = 2; 
    
    boolean isCenter; 
    isCenter = abs(orientation.x)<THRESHOLD; 
    if(isCenter){
      return isCenterisRight; 
    } 
    else{
      if(orientation.x>0) isCenterisRight = 1;
      else isCenterisRight = 0; 
    }
    return isCenterisRight;   
  }
  
  private byte isCenterisAbove(KJoint[] joints, int jointType1, int jointType2){
    PVector orientation = getOrientation(joints, jointType1, jointType2); 
    
    byte isCenterisAbove = 2; 
    boolean isCenter; 
    isCenter = abs(orientation.y)<THRESHOLD; 
    if(isCenter){
      return isCenterisAbove; 
    } 
    else{
      if(orientation.y>0) isCenterisAbove = 1;
      else isCenterisAbove = 0; 
    }
    return isCenterisAbove;  
  }
  
  private PVector getOrientation(KJoint[] joints, int jointType1, int jointType2){
    // probably modify this function so it returns just boolean 
    PVector orientation = PVector.sub(joints[jointType1].getPosition(), joints[jointType2].getPosition()); 
    return orientation; 
  }
  
  public float PVecToAngle(PVector pvec){    
    //in radians, -pi/2 <= theta <= pi/2
    
    //ignore z coordinate; use x and y only 
    // take absolute of x to stay in range 
    float theta = atan(-pvec.y/abs(pvec.x)); 
    return theta; 
  }
  
  public byte[] compareJoints(byte[] jointsLoaded, int frame){
    byte[] comparedJoints = new byte[NUM_JOINT_CHECKS]; 
    byte[] currJoints = getFrameJointChecks(); 
    for(int i = 0; i < NUM_JOINT_CHECKS; i++){
      if (i + NUM_JOINT_CHECKS*frame == 1440) {
       print("woah"); 
      }
      comparedJoints[i] = xnor(currJoints[i], jointsLoaded[i + NUM_JOINT_CHECKS*frame]); 
    } 
    return comparedJoints; 
  }
  /*
  private byte xnor_bitwise(int n1, int n2){
    if(n1 < n2){
      int temp = n1; 
      n1 = n2; 
      n2 = temp; 
    }
    n1 = togglebit(n1); 
    
    //pray to god this casting is okay
    return (byte) (n1^n2); 
  }
  
  private int togglebit(int n){
    if(n==0) return 1; 
    int i = n; 
    n |= n >> 1; 
    n |= n >> 2; 
    n |= n >> 4; 
    n |= n >> 8; 
    n |= n >> 16; 
    
    return i^n; 
  }
  */
  
  private byte xnor(int a, int b) {
    boolean xnor = (a==b); 
    return (byte) (xnor ? 1 : 0);
  }
  
  
}
