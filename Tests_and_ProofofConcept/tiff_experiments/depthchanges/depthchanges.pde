// paints using movement

import KinectPV2.*;
KinectPV2 kinect;

void setup() {
  size(512, 424, P3D);
  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.enableDepthImg(true);
  kinect.init();
}

void draw() {
  background(0);
  
  // Before we deal with pixels
  loadPixels();
  
  //raw body data 0-6 users 255 nothing
  int[] rawData = kinect.getRawBodyTrack();
  int[] rawDepthData = kinect.getRawDepthData();
  
  float averageDepth = 0;
  float numBodyPixels = 0;
  for (int i=0; i< rawDepthData.length; i++) {
    if (rawData[i] != 255) {
      averageDepth += rawDepthData[i]*255/4450;
      numBodyPixels+=1;
    }
  }
  averageDepth = averageDepth/numBodyPixels;

  // now map this somewhere along a two-hue spectrum
  float r = 50;
  float g = 100;
  float b = min(255, averageDepth);
  color newColor = color(r,g,b);
  
  for(int i = 0; i < rawData.length; i+=1){
    if(rawData[i] != 255){
      pixels[i] = newColor;
    }
  }

  // When we are finished dealing with pixels
  updatePixels();  
}
