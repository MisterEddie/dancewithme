import KinectPV2.*;
import java.lang.Long;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Map;

HashMap<Integer, Integer> heat_map = new HashMap<Integer, Integer>();

/*
 * Constants 
 */
final int YY_DURATION  = 15;
final int YY_FPS       = 16;
final int YY_TOT_FRAMES = YY_DURATION * YY_FPS;
final int YY_NUM_PIXELS = 512 * 424;

int YY_counter = 0;

PImage YY_img;
PImage YY_himg;
PImage YY_outimg;

void YY_setup() {
  YY_img = createImage(512, 424, PImage.RGB);
  YY_himg = createImage(512, 424, PImage.RGB);
  YY_outimg = createImage(512, 424, PImage.RGB);
  colorMode(HSB, 360, 100, 100);

  frameRate(YY_FPS);
  for (int i = 0; i < YY_NUM_PIXELS; i++) {
    heat_map.put(i, 0);
  }
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
    return;
  }

  /*
     * Main loop code
   */
  int [] rawData = kinect.getRawBodyTrack();
  int [] rawdepthData = kinect.getRawDepthData();

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
      color hcolor = color(heat_map.get(i)*360*1.3/YY_TOT_FRAMES, 100, 100);
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
  image(YY_img, 0, 0);
  image(YY_himg, 512, 0);
  image(YY_outimg, 512, 424);
  YY_counter++;
}
