import KinectPV2.*;
KinectPV2 kinect;
Table table;
int duration = 20;
int counter = 0;

void setup() {
  size(512, 424, P3D);
  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.enableDepthImg(true);
  kinect.init(); //<>//
  
  table = new Table();
  /*
   * Initialize all columns of the table
   */
   
  int startcols = millis();
  for (int i = 1; i < 512*424 + 1; i++) {
   table.addColumn(str(i)); 
   
  } //<>//
  
  int endcols = millis();
  
  print("Time for column function call is " + (endcols-startcols)/1000 + " seconds.");
  
  int startrows = millis();
  
   // /*
   //* Initialize all rows to duration in seconds assuming 60fps
   //*/
   //for (int i = 1; i < (duration * 60 + 1); i++) {
   // table.addRow();
   //}
   
   int endrows = millis();
   print("Time for row function call is " + (endrows-startrows)/1000 + " seconds.");
  
}

void draw() {
  

    background(0);
    // Before we deal with pixels
    loadPixels();  
    // load last scene's pixels
    
    //raw body data 0-6 users 255 nothing
    int [] rawData = kinect.getRawBodyTrack();
    int [] rawdepthData = kinect.getRawDepthData();
    
    for(int i = 0; i < rawData.length; i+=1){
      if(rawData[i] != 255){
        int redColor = rawdepthData[i] * 256 / 4000;
        //if (redColor != 0) print("redcolor is " + redColor + "\n");
        color newColor = color(redColor, 0, 255);
        pixels[i] = newColor;
      } 
    }
  
    // When we are finished dealing with pixels
    updatePixels();  
    
    if(counter == 20) {
      saveTable(table, "data/sample_save.csv");
      exit();
    }
    
    counter++;
  
}
