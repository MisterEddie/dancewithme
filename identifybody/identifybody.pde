import KinectPV2.*;
KinectPV2 kinect;


void setup() {
  size(512, 424, P3D);
  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.init();
}

void draw() {
  background(0);
  
  // Before we deal with pixels
  loadPixels();  
  // load last scene's pixels
  
  //raw body data 0-6 users 255 nothing
  int [] rawData = kinect.getRawBodyTrack();

  float randR = random(255);
  float randG = random(255);
  float randB = random(255);
  color newColor = color(randR, randG, randB);
  
  for(int i = 0; i < rawData.length; i+=1){
    if(rawData[i] != 255){
      pixels[i] = newColor;
    } 
  }

  // When we are finished dealing with pixels
  updatePixels();  
}
