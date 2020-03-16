//1-self, 2-prev, 3-all, else-run through entire program
void keyPressed() {
  if (!begin_dance && kinect.getSkeletonDepthMap().size()>0) {
    begin_dance = true;
    if (key == '1') {
      end_dance[1] = true; 
      end_dance[2] = true;
      YY_finish = false;
      YP_finish = true;
      YA_finish = true;
      saveBlankBodyDataToDatabase();
    } else if (key == '2') {
      end_dance[0] = true; 
      end_dance[2] = true;
      YY_finish = true;
      YP_finish = false;
      YA_finish = true;
      saveBlankBodyDataToDatabase();
    } else if (key == '3') {
      end_dance[0] = true; 
      end_dance[1] = true;
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
  println("resetting dance :) ");
  //needs to be called again says tiffyq
  YA_setup(); 
  YA_db.close();
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
  YP_jointsLoaded = new byte[YP_NUM_JOINT_CHECKS*YP_TOT_FRAMES];
  YP_youAndPrevIntersectionPixels = new color[YP_NUM_PIXELS]; // pixels that end up in output image
  YP_fadedPixels = new color[YP_NUM_PIXELS];
  YP_fadeIntersectionCounter = new int[YP_NUM_PIXELS];

  begin_dance = false; 
  YY_finish = false; 
  YP_finish = false; 
  YA_finish = false; 
  end_dance[0] = false; 
  end_dance[1] = false; 
  end_dance[2] = false;

  showYY = true;
  showYP = true;
  showYA = true;
  showEndSlide = true;
  showYYdesc = true;
  showYPdesc = true;
  showYAdesc = true;

  YYsetUp = false;
  YPsetUp = false;
  YAsetUp = false;

  checkTime = true;
  checkTimeGlobal = true;
  checkUserPresence = true;

  YY_counter = 0;
  YP_frameCounter = 0;
  YA_frameCounter = 0;
  
  System.out.println("Ready to Run Again! :)");
}

//im sorry tiffany this is going to cringe you here...future work might include deleting old users kinda thing
void saveBlankBodyDataToDatabase() {
  // Save blank body data to database to take up a user id in database
  YA_setup();
  for (int i = 0; i < YA_TOT_FRAMES; i++) {
    Object[] frame =
      {YA_userId, i, YA_positionOnScreen[i], 0, 0, 0, 0, 0, 0};
    YA_db.insertUpdateInDatabase("body_data", columnNames, frame);
  }
  println("Done writing BLANK to database");
  YA_db.close();
  println("Closed database connection");
  YA_savedToDatabase = true;
}
