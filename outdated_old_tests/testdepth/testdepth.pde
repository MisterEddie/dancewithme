import KinectPV2.*;
KinectPV2 kinect;

Table table;
int count = 0;


void setup() {
  size(512,424);
  kinect = new KinectPV2(this);
  //Start up methods go here
  kinect.enableDepthImg(true);
  kinect.init();
  table = new Table();
  for(int i = 0; i<512;i++)
  {
    table.addColumn();
  }
  
  for(int i = 0; i<424;i++)
  {
    table.addRow();
  }
  
  
 }
  

 //void enableColorImg(boolean toggle);
 //void enableDepthImg(boolean toggle);
 //void enableInfraredImg(boolean toggle);
 //void enableBodyTrackImg(boolean toggle);
 //void enableInfraredLongExposureImg(boolean toggle);
 
 //PImage getColorImage();
 //PImage getDepthImage();
 //PImage getInfraredImage();
 //PImage getBodyTrackImage();
 //PImage getInfraredLongExposureImage();
 
 void draw()
 {
   int skip = 1;
   background(0);
   PImage img = kinect.getDepthImage();
   image(img,0,0);
   for(int x = 0; x<img.width;x+=skip){
     for(int y = 0; y < img.height; y+=skip) { //look at every skip pixels
       int index = x+y*img.width; //give (x,y) coordinate, translate to 1D array we use X+y*imagewidth
       float b = brightness(img.pixels[index]); //brightness is zero to 255, brightness of exactly that pixel
       table.setFloat(y,x,b);
       //fill(b);
       //rect(x,y,skip,skip);
     }
   }
   String name = "data/fun";
   name = name + str(count) + ".csv";
   
   saveTable(table,name);
   println("done");
   count = count+1;
   println(count);
 }
   


   
