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
  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.enableDepthImg(true);
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
      color newColor = color(currHue % 360, SATURATION, brightness);
      pixels[i] = newColor;
    }
  }

  for (int i = 0; i < pixels.length; i+=1) {
    lastPixels[i] = pixels[i];
  }

  // When we are finished dealing with pixels
  updatePixels();  
}
