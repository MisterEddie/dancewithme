import KinectPV2.*;
KinectPV2 kinect;
import java.lang.Long;

/*
 * Constants 
 */
final int duration  = 20;
final int fps       = 60;
final int totframes = duration * fps;
final int numPixels = 512 * 424;

PrintWriter output;
int counter = 0;
byte[][] pixelSave = new byte[numPixels][totframes];
long[][] compressedPixelSave = new long[numPixels/8][totframes];

void setup() {
  size(512, 424, P3D);
  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.enableDepthImg(true);
  kinect.init();
  
  output = createWriter("test.txt");  
}

void draw() {
    background(0);
    loadPixels();  
    
    /*
     * This code is executed after all frames have been saved to local memory.
     */   
    if (counter == totframes) {
       int startCompress = millis();
       compressBits();
       int endCompress = millis();
       print("Time to compress is " + (endCompress-startCompress)/1000 + " seconds.\n");
      
      
      int start = millis();
      for (int frame = 0; frame < totframes; frame++) {
        for (int pix = 0; pix < numPixels/8; pix++) {
          output.print(compressedPixelSave[pix][frame] + " ");
        }
        output.print("\n");
      }
      int end = millis();
      print("Total time to save is " + (end-start)/1000 + " seconds.\n");
      output.close();
            
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
        pixelSave[i][counter] = byte(rawdepthData[i]);
        
        
      } 
    }
  
    updatePixels();      
    counter++;
}

// The depth data is being stored at 32 bits per integer, whereas a number from 0-255 only requires
// 8 bits to store. So lets try to jam 4 values per integer using bit masking, and approximately cut
// time by 4 assuming negligible overhead. WARNING if the depth value is negative than this algorithm 
// may fail because signed operator may shift 1's instead of 0's. This is how it works in Java although
// processing documentation seems to not mention what happens if the integer is signed.

void compressBits() {
  for (int i = 0; i < totframes; i++) {
    for (int j = 0; j < numPixels - 8; j+=8) {
      compressedPixelSave[j/8][i] = ((Long.valueOf(pixelSave[j][i]) << 56) |
                                   (Long.valueOf(pixelSave[j+1][i]) << 48) |
                                   (Long.valueOf(pixelSave[j+2][i]) << 40) | 
                                   (Long.valueOf(pixelSave[j+3][i]) << 32) |
                                   (Long.valueOf(pixelSave[j+4][i]) << 24) |
                                   (Long.valueOf(pixelSave[j+5][i]) << 16) |
                                   (Long.valueOf(pixelSave[j+6][i]) <<  8) |
                                   (Long.valueOf(pixelSave[j+7][i])      ));
    }
  }
}
