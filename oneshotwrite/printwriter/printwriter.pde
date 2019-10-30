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
final String writepath = "./test.txt";

FileOutputStream stream;
int counter = 0;
byte[] pixelSave = new byte[totframes*numPixels];

void setup() {
  size(512, 424, P3D);
  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.enableDepthImg(true);
  kinect.init();
  try {
    stream = new FileOutputStream(writepath);
  
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
  
    updatePixels();      
    counter++;
}
