// paints using movement

import KinectPV2.*;
KinectPV2 kinect;

color[] lastPixels = new int[512*424];

void setup() {
  for (int i=0; i< lastPixels.length; i++) {
    lastPixels[i]=color(0);
  }
  // Change color mode
  colorMode(HSB, 360, 100, 100);
  size(512, 424, P3D);
  frameRate(20);
  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.enableDepthImg(true);
  kinect.enableSkeletonColorMap(true);
  kinect.init();
}

int currHue = 0;
int SATURATION = 100; // always 100% saturated
void draw() {
  background(0);
  
  // Before we deal with pixels
  loadPixels();
  for (int i = 0; i < pixels.length; i+=1) {
    pixels[i] = lastPixels[i];
  }
  // load last scene's pixels
  
  //raw body data 0-6 users 255 nothing
  int [] rawBodyData = kinect.getRawBodyTrack();
  int[] rawDepthData = kinect.getRawDepthData();
  ArrayList<KSkeleton> skeletonArray =  kinect.getSkeletonColorMap();

  // Generate new hue.
  // Note that in our actual implementation,
  // this colour would be determined by
  // computing joint similarity.
  currHue += 1;
  
  // Normalize brightness level.
  // Amplify actual depth since we're only interested in
  // the body and throw away the rest of the data
  // (e.g. depth of things in the background, etc).
  float maxDepth = Float.MIN_VALUE;
  float minDepth = Float.MAX_VALUE;
  for (int i = 0; i < rawBodyData.length; i+=1){
    if (rawBodyData[i] != 255) {
      if (rawDepthData[i] > maxDepth) {
        maxDepth = rawDepthData[i];
      }
      if (rawDepthData[i] < minDepth) {
        minDepth = rawDepthData[i];
      }
    }
  }
  
  float adjustedScale = maxDepth - minDepth;
  
  // Next, adjust brightness according to normalized scale.
  for (int i = 0; i < rawBodyData.length; i+=1){
    if(rawBodyData[i] != 255){
      float brightness = 100*(1-(rawDepthData[i]-minDepth)/adjustedScale);
      color newColor = color(currHue % 360, SATURATION, min(100, brightness+30));
      pixels[i] = newColor;
    }
  }

  // Finally, only save this if hand opened and closed.
    
  // only get one skeleton
  if (skeletonArray.size() > 0) {
    KSkeleton skeleton = (KSkeleton) skeletonArray.get(0);
    if (skeleton.isTracked()) {
      KJoint[] joints = skeleton.getJoints();
      if (tookSnapshot(joints[KinectPV2.JointType_HandRight])) {
          for (int i = 0; i < pixels.length; i+=1) {
            lastPixels[i] = pixels[i];
          }
      }
    }
  }
  // When we are finished dealing with pixels
  updatePixels();  
}

// global variables
boolean wasOpen = true;

/*
Different hand states:
 KinectPV2.HandState_Open
 KinectPV2.HandState_Closed
 KinectPV2.HandState_Lasso
 KinectPV2.HandState_NotTracked
 */
boolean tookSnapshot(KJoint hand) {
  boolean isClosed = hand.getState() == KinectPV2.HandState_Closed;
  boolean ans = isClosed && wasOpen;
  // now change wasOpen
  wasOpen = !isClosed;
  return ans;
}
