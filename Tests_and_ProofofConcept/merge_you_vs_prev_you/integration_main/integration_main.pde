import KinectPV2.*; //<>//
import java.lang.Long;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Iterator;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.Arrays; 

KinectPV2 kinect;
boolean YP_finish = false;
boolean YY_finish = false;


void setup() {
  size(1536, 848, P3D);

  // Initialize Kinect
  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.enableDepthImg(true);
  kinect.enableSkeletonColorMap(true); 
  kinect.init();

  YP_setup();
  YY_setup();
}

void draw() {
  if (YP_finish == false) {
    YP_draw();
  } else {
    println("here");
    YY_draw();
  }


  // End program.
  if (YY_finish == true) {
    exit();
    return;
  }
  //<>//
}
