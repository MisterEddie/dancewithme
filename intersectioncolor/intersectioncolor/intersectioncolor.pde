Table table;
import KinectPV2.*;
KinectPV2 kinect;
int colMax = 512;
int rowMax = 424;


void setup() {
  size(512, 424, P3D);
  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.enableDepthImg(true);
  kinect.init();
  
  /*
   * Make table and add all the columns to initialize it.
   * To index it, call "col x" where x is the column number.
   */ 
  table = new Table();
  for (int i = 1; i < colMax + 1; i++) {
   table.addColumn("col" + str(i));
  }
  for (int i = 0; i < rowMax ; i++) {
   table.addRow(); 
  }
}

void draw() {
  background(0);
  loadPixels();
    
 //<>//
  for (int i = 5; i > 0; i--) {
   delay(1000); 
   print("delay: " + i + "\n");
  }
  
  //raw body data 0-6 users 255 nothing
  int [] rawData = kinect.getRawBodyTrack();
  
  for (int row = 0; row < rowMax; row++) 
  {
    for (int col = 1; col < colMax; col++) //<>//
    {
      int loc = row + col * (colMax-1);
      String column = "col" + str(col);
      table.setInt(row, column, rawData[loc]);
      
      if (rawData[loc] != 255) {
        color newColor = color(0,0,255);
        pixels[loc] = newColor;
      }
    }
  }

  updatePixels();

  saveTable(table, "data/sample_save.csv");  
  exit();
}
