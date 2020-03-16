import KinectPV2.*;
KinectPV2 kinect;
import java.lang.Long;
import java.io.FileInputStream;

/*
 * Constants 
 */
final int duration  = 10;
final int fps       = 16;
final int totframes = duration * fps;
final int numPixels = 512 * 424;
final String filepath = "./test.txt";

FileInputStream input;
int frameCounter = 0;
byte[] pixelLoaded = new byte[numPixels*totframes];

void setup() {
  size(512, 424, P3D);
  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.enableDepthImg(true);
  kinect.init();
  
  File directory = new File("./");
  System.out.println(directory.getAbsolutePath());  // This prints out the path where the file is saved.
  
  try {
    input = new FileInputStream(filepath);
    print("Please wait patiently, loading file contents into memory.\n");
    int start = millis();
    input.read(pixelLoaded, 0, numPixels*totframes);
    int end = millis();
    print("Loading of file contents took " + (end-start)/1000 + " seconds.\n");
    input.close();
  } catch(IOException ex) {
    ex.printStackTrace(); 
  }
  
  frameRate(fps);
}

void draw() {
    background(0);
    loadPixels();  
   
    /*
     * These two statements consecutively must be executed to exit file immediately.
     */
    if (frameCounter == totframes) {
      exit();
      return;
    }
     
    /*
     * Main loop code
     */
    int [] rawData = kinect.getRawBodyTrack();
          
    /*
     * Compare intersection. The way the data is saved on file, all non-silhouette values are default zero
     * and all non-zero values are the values of depth. However, on our local system, we need to check both
     * rawData and rawdepthData for proper computation.
     */
    for (int i = 0; i < numPixels; i++) {
      
      int localData = rawData[i];
      int savedDepth = pixelLoaded[frameCounter*numPixels + i];
      
      // Skip if both not there
      if ((localData == 255) && (savedDepth == 0)) continue;
      
      // Get depth data for local
      //int localDepth = rawdepthData[i] * 256 / 4000;
      
      color newColor = color(0,0,0);
      
      // Intersection
      if ((localData != 255) && savedDepth !=0) {
        newColor = color(255,0,0);
      }
      
      // Only saved silhouette
      if ((localData != 255) && (savedDepth == 0)) {
        newColor = color(0, 0, 255); 
      }
      
      // Only local silhouette
      if ((localData == 255) && (savedDepth != 0)) {
        newColor = color(0,255,0); 
      }
      
      pixels[i] = newColor;
      
    } 
  
    updatePixels();  
    frameCounter++;
}
