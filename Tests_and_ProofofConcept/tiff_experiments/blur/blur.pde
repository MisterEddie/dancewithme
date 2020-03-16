// paints using movement, blurs shape

import KinectPV2.*;
KinectPV2 kinect;

color[] lastPixels = new int[512*424];
color WHITE = color(255,255,255);

void setup() {
  // Initialize last pixels
  for (int i=0; i< lastPixels.length; i++) {
    lastPixels[i]=color(0);
  }
  size(512, 424, P3D);
  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.init();
}

int currCol = 0;
void draw() {
  background(0);
  
  //raw body data 0-6 users 255 nothing
  int [] rawData = kinect.getRawBodyTrack();

  // generate new color
  float red = currCol % 255;
  float green = (currCol + 75) % 255;
  float blue = (currCol +25) % 255;
  color newColor = color(red, green, blue);
  currCol += 1; // change colour
  
  // must load pixels
  loadPixels();
  
  // read in body shape
  for(int i = 0; i < rawData.length; i+=1){
    if(rawData[i] != 255){
      pixels[i] = newColor;
    } else {
      pixels[i] = WHITE;
    }
  }
  
  // next, blur object
  filter(BLUR,5);
  // then copy old pixels to the photo to write over white pixels
  for (int i = 0; i < pixels.length; i+=1) {
    // if pixels are too white, paint over them
    if (
      (red(pixels[i]) > 230 && green(pixels[i]) > 230) ||
      (blue(pixels[i]) > 230 && green(pixels[i]) > 230) ||
      (red(pixels[i]) > 230 && blue(pixels[i]) > 230)
      ) {
      pixels[i] = lastPixels[i];
    }
  } 

  // finally, save these pixels into lastPixels  
  for (int i = 0; i < pixels.length; i+=1) {
    lastPixels[i] = pixels[i];
  }

  // When we are finished dealing with pixels
  updatePixels();  
}
