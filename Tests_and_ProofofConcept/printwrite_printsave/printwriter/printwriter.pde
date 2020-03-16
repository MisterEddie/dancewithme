import KinectPV2.*;
KinectPV2 kinect;

/*
 * Constants 
 */
final int duration  = 20;
final int fps       = 60;
final int totframes = duration * fps;
final int numPixels = 512 * 424;

PrintWriter output;
int counter = 0;
int[][] pixelSave = new int[numPixels][totframes];

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
    if(counter == totframes) {
      int start = millis();
      for (int frame = 0; frame < totframes; frame++) {
        for (int pix = 0; pix < numPixels; pix++) {
          output.print(pixelSave[pix][frame] + " ");
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
        int redColor = rawdepthData[i] * 256 / 4000;
        color newColor = color(redColor, 0, 255);
        pixels[i] = newColor;
        
        // Save the data to the 2D array.
        pixelSave[i][counter] = rawdepthData[i];
      } 
    }
  
    updatePixels();      
    counter++;
}
