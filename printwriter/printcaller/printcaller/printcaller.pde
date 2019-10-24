import KinectPV2.*;
KinectPV2 kinect;

/*
 * Constants 
 */
final int duration  = 20;
final int fps       = 60;
final int totframes = duration * fps;
final int numPixels = 512 * 424;

BufferedReader input;
int frameCounter = 0;
int[][] pixelLoaded = new int[numPixels][totframes];

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
      assert(pieces.length == numPixels);
      int pixelcount = 0;
      for (String entry : pieces) {
        pixelLoaded[pixelcount][linecount] = int(entry);
        pixelcount++;
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
     * Load all the pixels.
     */
    for (int i = 0; i < numPixels; i++) {
      pixels[i] = pixelLoaded[i][frameCounter];
    } 
  
    updatePixels();  
    frameCounter++;
}
