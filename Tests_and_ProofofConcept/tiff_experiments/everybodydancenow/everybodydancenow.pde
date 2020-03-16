// paints using movement

import KinectPV2.*;
KinectPV2 kinect;

color[] lastPixels = new int[512*424];

void setup() {
  for (int i=0; i< lastPixels.length; i++) {
    lastPixels[i]=color(0);
  }
  size(512, 424, P3D);
  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.init();
}

void draw() {
  background(0);
  
  // Before we deal with pixels
  loadPixels();
  for (int i = 0; i < pixels.length; i+=1) {
    pixels[i] = lastPixels[i];
  }
  // load last scene's pixels
  
  //raw body data 0-6 users 255 nothing
  int [] rawData = kinect.getRawBodyTrack();

  float randR = random(255);
  float randG = random(255);
  float randB = random(255);
  color newColor = color(randR, randG, randB);
  
  for(int i = 0; i < rawData.length; i+=1){
    if(rawData[i] != 255){ //check that there is a person!
      // also do check against old data to see
      // if intersection occurred
      pixels[i] = newColor;
    }
  }
  
  for (int i = 0; i < pixels.length; i+=1) {
    lastPixels[i] = pixels[i];
  }

  // When we are finished dealing with pixels
  updatePixels();  
}
