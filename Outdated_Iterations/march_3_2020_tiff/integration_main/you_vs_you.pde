import KinectPV2.*;
import java.lang.Long;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Map;

HashMap<Integer, Integer> heat_map = new HashMap<Integer, Integer>();

final boolean SHOW_COLOR_IN_SILHOUETTE = true;

/*
 * Constants 
 */
final int YY_DURATION  = 20;
final int YY_FPS       = 16;
final int YY_TOT_FRAMES = YY_DURATION * YY_FPS;
final int YY_WIDTH = 512; 
final int YY_HEIGHT = 424; 
final int YY_NUM_PIXELS = YY_WIDTH * YY_HEIGHT;
final String YY_OUTPUT_FILENAME = "1youvsyou";
final int YY_NUM_SECONDS_OF_FADE = 5;
final int YY_START_FADE = (YY_DURATION-YY_NUM_SECONDS_OF_FADE) * YY_FPS; // when to start fading out live image

int YY_counter = 0;

PImage YY_img;
PImage YY_himg;
PImage YY_outimg;
PGraphics YY_outputImage;

//Associated with median filtering
MedianFilter YY_curr;
int[] YY_pixelTemp = new int[YY_NUM_PIXELS];
final int YY_MFILTERORDER = 2;

void YY_setup() {

  
  System.out.println("YY_WIDTH: " + YY_WIDTH); 
  System.out.println("YY_HEIGHT: " + YY_HEIGHT); 
  
  YY_img = createImage(YY_WIDTH, YY_HEIGHT, PImage.RGB);
  YY_himg = createImage(YY_WIDTH, YY_HEIGHT, PImage.RGB);
  YY_outimg = createImage(YY_WIDTH, YY_HEIGHT, PImage.RGB);
  colorMode(HSB, 360, 100, 100);

  //frameRate(YY_FPS);
  for (int i = 0; i < YY_NUM_PIXELS; i++) {
    heat_map.put(i, 0);
  }
  
  
  // Create MedianFilter object
  YY_curr = new MedianFilter(YY_NUM_PIXELS, YY_TOT_FRAMES, YY_HEIGHT, YY_WIDTH, YY_MFILTERORDER);
}

void YY_draw() {
  YY_img.loadPixels();
  YY_himg.loadPixels();
  background(0); 
    
  if (YY_counter == YY_TOT_FRAMES) {   
    /* 
     * These set of statements TOGETHER will exit the program immediately
     */
    YY_finish = true;
    YY_createOutputImage(YY_outimg.pixels, YY_OUTPUT_FILENAME);
    return;
  }

  /*
     * Main loop code
   */
  int [] rawData = kinect.getRawBodyTrack();
  int [] rawdepthData = kinect.getRawDepthData();
  //Median filter the rawBodyData array.
  int off = 0;
  YY_curr.filterFrame(rawData, YY_pixelTemp, off);
  rawData = YY_pixelTemp;

  int broken = 1;
  while (broken == 1)
  {
    rawData = kinect.getRawBodyTrack();
    for (int i = 0; i < YY_NUM_PIXELS; i++)
    {
      if (rawData[i] != 255) {
      } else {
        broken=0;
      }
    }
  }

  assert(rawData.length == YY_NUM_PIXELS);
  for (int i = 0; i < YY_NUM_PIXELS; i++) {

    if (rawData[i] != 255) {
      heat_map.put(i, heat_map.get(i)+1);
      int depth = rawdepthData[i] * 256 / 4000;
      color newColor = color(0, 100, 100);
      int newBrightness = 100;
      if (YY_counter > YY_START_FADE) {
        newBrightness = 100 - (YY_counter - YY_START_FADE);
      }
      color hcolor = color(heat_map.get(i)*360*1.2/YY_TOT_FRAMES, 100, newBrightness);
      YY_img.pixels[i] = newColor;        
      YY_himg.pixels[i] = hcolor;

    } else {

      color hncolor = color(heat_map.get(i), 0, 0);
      YY_himg.pixels[i] = hncolor;
      YY_img.pixels[i] = color(0, 0, 0);
      //YY_himg.pixels[i] = color(0, 0, 0); //can comment this out so we can see everything in real time.
    }
    if (YY_counter%1 == 0 ) {
      if (heat_map.get(i) < 5) {
        //print("if");
        YY_outimg.pixels[i] = color(0, 0, 0);
      } else {
        //print("else");
        YY_outimg.pixels[i] = color(heat_map.get(i)*360*1.3/YY_TOT_FRAMES, 100, 100);
      }
    }
  }

  YY_img.updatePixels();
  YY_himg.updatePixels();
  YY_outimg.updatePixels();
  // center images
  int leftImgX = round((0.25*width)-(YY_WIDTH/2));
  int rightImgX = round((0.75*width)-(YY_WIDTH/2));
  int imgY = round((0.5*height)-(YY_HEIGHT/2));
  if (SHOW_COLOR_IN_SILHOUETTE) {
    image(YY_himg, leftImgX, imgY);
  } else {
    image(YY_img, leftImgX, imgY);
  }
  image(YY_outimg, rightImgX, imgY);
  text("live movement", round(0.25*width), imgY + 472);
  text("your artwork", round(0.75*width), imgY + 472);
  // render border
  strokeWeight(4);
  stroke(100);
  noFill();
  rect(leftImgX, imgY, YA_WIDTH, YA_HEIGHT);
  rect(rightImgX, imgY, YA_WIDTH, YA_HEIGHT);
  
  // show countdown
  if(YY_counter > YY_START_FADE) {
    float tempCount = float((YY_counter-YY_START_FADE))/(YY_TOT_FRAMES-YY_START_FADE);
    String currCountdown = Integer.toString(
      ceil(YY_NUM_SECONDS_OF_FADE - YY_NUM_SECONDS_OF_FADE*tempCount)
      );
    text(currCountdown, leftImgX + 462, imgY + 382, 50, 50);  
  }
  YY_counter++;
}

void YY_createOutputImage(color[] outputPixels, String filename) {
    filename = "./data/" + filename;
    YY_outputImage = createGraphics(YY_WIDTH, YY_HEIGHT);
    YY_outputImage.beginDraw();
    YY_outputImage.loadPixels();
    for (int i = 0; i < outputPixels.length; i += 1) {
      YY_outputImage.pixels[i] = outputPixels[i];
    }
    YY_outputImage.updatePixels();
    YY_outputImage.save(filename + ".png");
}
