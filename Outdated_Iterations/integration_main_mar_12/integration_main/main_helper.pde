//1-self, 2-prev, 3-all, else-run through entire program 

//IF YOU PRESS THE BUTTONS BEFORE THE END OF THE STARTING COUNTDOWN, ITLL AUTOMATICALLY TRIGGER SELF, PREV, OR ALL (ANY OTHER BUTTON)
//PRESSING BUTTON WHILE THE EXPERIENCE IS RUNNING HAS NO AFFECT. 
//MOSTLY USEFUL FOR SKIPPING WAIT TIMES. 
void keyPressed() {
  if (!begin_dance && kinect.getSkeletonDepthMap().size()>0) {
    begin_dance = true;
    if (key == '1') {
      YY_finish = false;
      YP_finish = true;
      YA_finish = true;
      YA_savedToDatabase = true;
    } else if (key == '2') {
      YY_finish = true;
      YP_finish = false;
      YA_finish = true;
      YA_savedToDatabase = true;
    } else if (key == '3') {
      YY_finish = true;
      YP_finish = true;
      YA_finish = false;
    } else {
      YY_finish = false;
      YP_finish = false;
      YA_finish = false;
    }
  }
}

void reset_all_global() {
  begin_dance = false; 
  //resetting intro slides
  showIntro = true;
  showTitle = true; 
  showDesc1 = true;
  showDesc2 = true;
  showDesc3 = true;
  showDesc4 = true;
  showDesc5 = true; 

  showYY = true;
  showYP = true;
  showYA = true;
  showEndSlide = true;
  showYYdesc = true;
  showYPdesc = true;
  showYAdesc = true;

  showYYdance = true;
  showYPdance = true;
  showYAdance = true;

  //reset setup
  YYsetUp = false;
  YPsetUp = false;
  YAsetUp = false;

  //reset all pixels
  YA_pixelsToSave = new int[YA_TOT_FRAMES*YA_NUM_PIXELS];
  YA_positionOnScreen = new int[YA_TOT_FRAMES];
  YA_rightHandX = new int[YA_TOT_FRAMES];
  YA_rightHandY = new int[YA_TOT_FRAMES];
  YA_red = new int[YA_TOT_FRAMES];
  YA_green = new int[YA_TOT_FRAMES];
  YA_blue = new int[YA_TOT_FRAMES];
  YA_savedToDatabase = false;

  YP_pixelLoaded = new byte[YP_NUM_PIXELS*YP_TOT_FRAMES];
  YP_pixelToSave = new byte[YP_NUM_PIXELS*YP_TOT_FRAMES];
  YP_youAndPrevIntersectionPixels = new color[YP_NUM_PIXELS]; // pixels that end up in output image
  YP_fadedPixels = new color[YP_NUM_PIXELS];
  YP_fadeIntersectionCounter = new int[YP_NUM_PIXELS];

  //reset finish flags
  YY_finish = false; 
  YP_finish = false; 
  YA_finish = false; 

  //reset checking user presence
  checkTime = true;

  //reset checking user presence
  checkUserPresence = true;

  YY_counter = 0;
  YP_frameCounter = 0;
  YA_frameCounter = 0;
}
