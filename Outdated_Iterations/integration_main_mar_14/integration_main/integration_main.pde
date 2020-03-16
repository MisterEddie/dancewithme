import KinectPV2.*;
import java.lang.Long;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Iterator;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.Arrays; 

// For playing video demos and music
// Make sure to download Processing Video library
import processing.video.*;
import processing.sound.*;

Movie yyDemo;
Movie ypDemo;
Movie yaDemo;
SoundFile backgroundMusic;

KinectPV2 kinect;

// for showing slides: 
PImage slide_YY_title; 
PImage slide_YP_title; 
PImage slide_YA_title;
PImage slide_afterimage;
PImage slide_dance;
PImage slide_desc1;
PImage slide_desc2;
PImage slide_desc3;
PImage slide_desc4;
PImage slide_desc5;
PImage slide_desc6;

PImage slide_waiting;

//loading screen
PImage slide_loading;

final String YY_TITLE_PATH = "./YouVsYou_slide.png"; 
final String YP_TITLE_PATH = "./YouVsPrvs_slide.png"; 
final String YA_TITLE_PATH = "./YouVsAll_slide.png"; 

final String FINAL_SLIDE_PATH = "./afterimage.png"; 
final String MAKE_ART_PATH = "./makeart.png"; 
final String DESC_1_PATH = "./desc1.png";
final String DESC_2_PATH = "./desc2.png";
final String DESC_3_PATH = "./desc3.png";
final String DESC_4_PATH = "./desc4.png";
final String DESC_5_PATH = "./desc5.png";
final String DESC_6_PATH = "./desc6.png";

final int DISPLAY_TIME_INTRO = 1000; // 1 second
final int DISPLAY_TIME_TITLE = 2000; // 2 seconds 
final int DISPLAY_TIME_DANCE = 1000; // 1 second 
final int DEMO_VIDEO_LENGTH = 6800; // 7 seconds

boolean showIntro = true;
boolean showTitle = true; // beginning slide that says afterimage
boolean showDesc1 = true;
boolean showDesc2 = true;
boolean showDesc3 = true;
boolean showDesc4 = true;
boolean showDesc5 = true;
boolean showDesc6 = true; // this one should be shown for 4 seconds
boolean showYY = true; 
boolean showYP = true; 
boolean showYA = true;
boolean showEndSlide = true;
boolean showYYdesc = true; 
boolean showYPdesc = true; 
boolean showYAdesc = true;
boolean showYYdance = true;
boolean showYPdance = true;
boolean showYAdance = true;
boolean YYsetUp = false;
boolean YPsetUp = false;
boolean YAsetUp = false;
boolean checkTime = true;

boolean yyVideoStarted = false;
boolean ypVideoStarted = false;
boolean yaVideoStarted = false;

int start; 
int end; 

//variables for checking presence
ArrayList<KSkeleton> body;
boolean begin_dance = false;
boolean checkUserPresence = true;
int start_user_presence;
final int TIME_USER_PRESENT = 5000; //how long a user must be detected before program decides there is a human present
final int TIME_BETWEEN_RUN = 2000; //minimum time between runs

PFont arial; 
int fontSize = 30; 
final int MARGIN = 10; 

boolean YY_finish = false;
boolean YP_finish = false;
boolean YA_finish = false;

// Used to save to database in a thread
boolean YA_savedToDatabase = false;

void setup() {
  
 fullScreen(); 
  
  // Initialize Kinect
  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.enableDepthImg(true);
  kinect.enableSkeletonColorMap(true); 
  kinect.enableSkeletonDepthMap(true); 
  kinect.init();

  slide_YY_title = loadImage(YY_TITLE_PATH); 
  slide_YP_title = loadImage(YP_TITLE_PATH); 
  slide_YA_title = loadImage(YA_TITLE_PATH); 
  slide_afterimage = loadImage(FINAL_SLIDE_PATH); 
  slide_dance = loadImage(MAKE_ART_PATH); 
  slide_desc1 = loadImage(DESC_1_PATH);
  slide_desc2 = loadImage(DESC_2_PATH);
  slide_desc3 = loadImage(DESC_3_PATH);
  slide_desc4 = loadImage(DESC_4_PATH);
  slide_desc5 = loadImage(DESC_5_PATH);
  slide_desc6 = loadImage(DESC_6_PATH);
  
  slide_loading = createImage(YY_WIDTH, YY_HEIGHT, PImage.RGB);
  
  // description at beginning
  
  arial = createFont("Arial", fontSize); 
  textFont(arial); 
  textAlign(CENTER); 
  frameRate(16); 
  
  // start background music
  backgroundMusic = new SoundFile(this, "reflective.mp3");
  backgroundMusic.loop();
  
  // video demos
  yyDemo = new Movie(this, "yyDemo.mp4");
  ypDemo = new Movie(this, "ypDemo.mp4");
  yaDemo = new Movie(this, "yaDemo.mp4");
}

int countdown = 0;
void draw() {
  //ensure there is user present before running program
  if (!begin_dance) {
    body = kinect.getSkeletonDepthMap();
    background(0);
  }

  if (body.size() > 0 && !begin_dance) {

    slide_loading.loadPixels();
    
    int[] rawData = kinect.getRawBodyTrack();
    KSkeleton loadingSkeleton = (KSkeleton) body.get(0);
    color loadingBodyColor;
    if (loadingSkeleton.isTracked()) {
      loadingBodyColor = getSilhouetteColor(loadingSkeleton);
    } else {
      loadingBodyColor = color(255,0,0);
    }
    for (int i = 0; i < rawData.length; i+=1) {
      if (rawData[i] != 255) {
        slide_loading.pixels[i] = loadingBodyColor;
      } else
        slide_loading.pixels[i] = color(0, 0, 0);
    }
    slide_loading.updatePixels();
    int ImgX = round((0.5*width)-(YY_WIDTH/2));
    int ImgY = round((0.5*height)-(YY_HEIGHT/2));
    image(slide_loading, ImgX, ImgY);
    String currCountdown = Integer.toString(
      ceil((TIME_USER_PRESENT-(millis()-start_user_presence))/1000) + 1
      );
    text("starting in: " + currCountdown, floor(width/2), height-100);

    if (checkUserPresence) {
      start_user_presence = millis();
      checkUserPresence = false;
    }
  } else {
    if (!begin_dance) {
      start_user_presence = millis();
      checkUserPresence = true;
    }
  }
  
  // ensures that the text is on top of the live image
  if (!begin_dance) {
    textAlign(LEFT); 
    textSize(100);
    text("afterimage ", 100, 100);
    textSize(30);
    text("music: 'Reflective' by Ketsa", 100, 200);
    text("from the Free Music Archive", 100, 250);
    text("CC BY-NC-ND 4.0", 100, 300);
    textAlign(CENTER); 
  }

  //check if program should run now
  if ( !begin_dance &&  ((millis() - start_user_presence)>TIME_USER_PRESENT) ) {
    begin_dance = true;
  }
  if (begin_dance) {
    // first show intro
    if (showIntro) {
      if (checkTime) {
        start = millis(); 
        checkTime = false; 
      }
      if (showTitle) {
        image(slide_afterimage, 0, 0, width, height); 
        end = millis();
        if (end - start >= DISPLAY_TIME_TITLE) {
          showTitle = false;
          start = millis();
        }
      } else if (showDesc1) {
        image(slide_desc1, 0, 0, width, height); 
        end = millis();
        if (end - start >= DISPLAY_TIME_INTRO * 2) {
          showDesc1 = false;
          start = millis();
        }
      } else if (showDesc2) {
        image(slide_desc2, 0, 0, width, height); 
        end = millis();
        if (end - start >= DISPLAY_TIME_INTRO) {
          showDesc2 = false;
          start = millis();
        }
      } else if (showDesc3) {
        image(slide_desc3, 0, 0, width, height); 
        end = millis();
        if (end - start >= DISPLAY_TIME_INTRO) {
          showDesc3 = false;
          start = millis();
        }
      } else if (showDesc4) {
        image(slide_desc4, 0, 0, width, height); 
        end = millis();
        if (end - start >= DISPLAY_TIME_INTRO * 2) {
          showDesc4 = false;
          start = millis();
        }
      } else if (showDesc5) {
        image(slide_desc5, 0, 0, width, height); 
        end = millis();
        if (end - start >= DISPLAY_TIME_INTRO * 4) {
          showDesc5 = false;
          start = millis();
        }
      } else {
        image(slide_desc6, 0, 0, width, height); 
        end = millis();
        if (end-start >= 3000) {
          // show countdown
          textAlign(RIGHT);
          String countdownNum = "starts in " + Integer.toString(
            ceil(10 - (end-start)/1000)
            );
          text(countdownNum, round(width*0.95), round(height*0.95));
        }
        if (end - start >= 9900) {
          showDesc6 = false;
          showIntro = false;
          checkTime = true;
          textAlign(CENTER); 
        }
      }
    }
    // You Versus You
    else if (showIntro == false && YY_finish == false) {
      if (!YYsetUp) {
        YY_setup();
        YYsetUp = true;
      }
      if (checkTime) {
        start = millis(); 
        checkTime = false; 
      }
      if(showYY){
        image(slide_YY_title, 0, 0, width, height); 
        end = millis(); 
        if (end - start >= DISPLAY_TIME_TITLE) {
          showYY = false; 
          start = millis(); 
        }
      } else if (showYYdesc) {
        if (!yyVideoStarted) {
          yyDemo.jump(0);
          yyDemo.play();
          yyVideoStarted = true;
        }
        yyDemo.volume(0);
          
        image(yyDemo, 0, 0, width, height);
        end = millis();
        
        // show countdown
        textAlign(RIGHT);   
        if (end - start >= 4000) {
          String countdownNum = "starts in " + Integer.toString(
            ceil(7 - (end-start)/1000)
            );
          text(countdownNum, round(width*0.97), round(height*0.97));
        }
          
        if (end - start >= DEMO_VIDEO_LENGTH) {
          showYYdesc = false; 
          textAlign(CENTER);  
          start = millis();
        }
      } else if (showYYdance) {
        image(slide_dance, 0, 0, width, height); 
        end = millis(); 
        if (end - start >= DISPLAY_TIME_DANCE) {
          showYYdance = false; 
          background(0);
        }
      } else {
        YY_draw();
        checkTime = true; 
      } 
    // You Versus Previous
    } else if (showIntro == false && YY_finish == true && YP_finish == false) {
        if (!YPsetUp) {
          YP_setup();
          YPsetUp = true;
        }
        if(checkTime) {
          start = millis(); 
          checkTime = false; 
        }
        if(showYP) {
          image(slide_YP_title, 0, 0, width, height);
          end = millis(); 
          if (end - start >= DISPLAY_TIME_TITLE) {
            showYP = false; 
            start = millis();
          }
        } else if (showYPdesc) {
          if (!ypVideoStarted) {
            ypDemo.jump(0);
            ypDemo.play();
            ypVideoStarted = true;
          }
          ypDemo.volume(0);
            
          image(ypDemo, 0, 0, width, height);
          end = millis(); 
          
          textAlign(RIGHT);  
          if (end - start >= 4000) {
            String countdownNum = "starts in " + Integer.toString(
              ceil(7 - (end-start)/1000)
              );
            text(countdownNum, round(width*0.97), round(height*0.97));
          }
            
          if (end - start >= DEMO_VIDEO_LENGTH) {
            showYPdesc = false; 
            start = millis();
            textAlign(CENTER);  
          }
        } else if (showYPdance) {
          image(slide_dance, 0, 0, width, height); 
          end = millis(); 
          if (end - start >= DISPLAY_TIME_DANCE) {
            showYPdance = false; 
            background(0);
          }
        } else {
          YP_draw(); 
          checkTime = true;
        }
      // You Versus All
      } else if (showIntro == false && YP_finish == true && YA_finish == false) {
      if (!YAsetUp) {
        YA_setup();
        YAsetUp = true;
      }
      if(checkTime){
        start = millis(); 
        checkTime = false; 
      }
      if(showYA){
        image(slide_YA_title, 0, 0, width, height);
        end = millis(); 
        if (end - start >= DISPLAY_TIME_TITLE) {
          showYA = false; 
          start = millis();
        }
      } else if (showYAdesc) {
        if (!yaVideoStarted) {
          yaDemo.jump(0);
          yaDemo.play();
          yaVideoStarted = true;
        }
        yaDemo.volume(0);
          
        image(yaDemo, 0, 0, width, height);
        end = millis(); 
        
        textAlign(RIGHT);  
        if (end - start >= 7000) {
          String countdownNum = "starts in " + Integer.toString(
            ceil(10 - (end-start)/1000)
            );
          text(countdownNum, round(width*0.97), round(height*0.97));
        }
          
        if (end - start >= DEMO_VIDEO_LENGTH + 3000) {
          showYAdesc = false; 
          textAlign(CENTER);  
          start = millis();
        }
      } else if (showYAdance) {
          image(slide_dance, 0, 0, width, height); 
          end = millis(); 
          if (end - start >= DISPLAY_TIME_DANCE) {
            showYAdance = false; 
            background(0);
          }
      } else {
        YA_draw(); 
        checkTime = true;
      }
    }
    
    // End program.
    if (YY_finish && YP_finish && YA_finish) {
      // Show the output images
      if (checkTime) {
        start = millis();
        checkTime = false;
      }
      end = millis();
      background(0);
      String YY_output_path = "./data/1youvsyou.png";
      String YP_output_path = "./data/2youvsprevious.png";
      String YA_output_path = "./data/3youvsall.png";
        
      textAlign(CENTER);
      if (end-start >= 1000) {
        PImage YY_output = loadImage(YY_output_path); 
        image(YY_output, round(width*0.25 - 154), round(height*0.2), 307, 254);
        text("you & you", round(width*0.25), round(height*0.2) + 300);
        // render border
        strokeWeight(4); stroke(100); noFill();
        rect(round(width*0.25 - 154), round(height*0.2), 307, 254);
      }
      if (end - start >= 2000) {
        PImage YP_output = loadImage(YP_output_path); 
        image(YP_output, round(width*0.5 - 154), round(height*0.2), 307, 254);
        text("you & the last user", round(width*0.5), round(height*0.2) + 300);
        // render border
        strokeWeight(4); stroke(100); noFill();
        rect(round(width*0.5 - 154), round(height*0.2), 307, 254);      
      }
      if (end - start >= 3000) {
        PImage YA_output = loadImage(YA_output_path); 
        image(YA_output, round(width*0.75 - 154), round(height*0.2), 307, 254);
        text("you & the last 25 users", round(width*0.75), round(height*0.2) + 300);
        // render border
        strokeWeight(4); stroke(100); noFill();
        rect(round(width*0.75 - 154), round(height*0.2), 307, 254);
      }
      if (end - start >= 4000) {
        textSize(100);
        text("afterimage", round(width*0.5), round(height*0.85));
        // show countdown in the corner
        textSize(30);
        textAlign(RIGHT); 
        String countdownNum = "restarts in " + Integer.toString(
          ceil(25 - (end-start)/1000)
          );
        text(countdownNum, round(width*0.9), round(height*0.9));
      }
      
      if (end - start >= 25000 && YA_savedToDatabase) {
        reset_all_global();
      }
    } //<>//
 }
}

void movieEvent(Movie m) {
  m.read();
}
