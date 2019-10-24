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

BufferedReader input;
int frameCounter = 0;
byte[][] pixelLoaded = new byte[numPixels][totframes];

void setup() {
  size(512, 424, P3D);
  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.enableDepthImg(true);
  kinect.init();
  
  input = createReader("../../printwriter/test.txt");  
  print("Please wait patiently, loading file contents into memory.\n");
  int start = millis();
  String line = null;
  try {
    int linecount = 0;
    while ((line = input.readLine()) != null) {
      String[] pieces = split(line.trim()," ");  
      assert(pieces.length == numPixels/8);
      int pixelcount = 0;
      for (String entry : pieces) {
      
        pixelLoaded[pixelcount][linecount] = byte((Long.parseLong(entry) >> 56) & 0xFF);
        pixelLoaded[pixelcount+1][linecount] = byte((Long.parseLong(entry) >> 48) & 0xFF);
        pixelLoaded[pixelcount+2][linecount] = byte((Long.parseLong(entry) >> 40) & 0xFF);
        pixelLoaded[pixelcount+3][linecount] = byte((Long.parseLong(entry) >> 32) & 0xFF);
        pixelLoaded[pixelcount+4][linecount] = byte((Long.parseLong(entry) >> 24) & 0xFF);
        pixelLoaded[pixelcount+5][linecount] = byte((Long.parseLong(entry) >> 16) & 0xFF);
        pixelLoaded[pixelcount+6][linecount] = byte((Long.parseLong(entry) >>  8) & 0xFF);
        pixelLoaded[pixelcount+7][linecount] = byte(Long.parseLong(entry) & 0xFF);
        pixelcount+=8;

      }
      linecount++;
    }
    input.close();
  } catch(IOException e) {
    e.printStackTrace(); 
  }
  int end = millis();
  print("Loading of file contents took " + (end-start)/1000 + " seconds.\n");
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
    int [] rawdepthData = kinect.getRawDepthData();
          
    /*
     * Compare intersection. The way the data is saved on file, all non-silhouette values are default zero
     * and all non-zero values are the values of depth. However, on our local system, we need to check both
     * rawData and rawdepthData for proper computation.
     */
    for (int i = 0; i < numPixels; i++) {
      
      int localData = rawData[i];
      int savedDepth = pixelLoaded[i][frameCounter];
      
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
