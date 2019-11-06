import KinectPV2.*;
KinectPV2 kinect;
import java.lang.Long;
import java.io.FileInputStream;
import java.util.Arrays; 

/*
 * Constants 
 */
final int DURATION  = 20;
final int FPS       = 16;
final int TOT_FRAMES = DURATION * FPS;
final int COLS = 512;
final int ROWS = 424;
final int NUM_PIXELS = COLS * ROWS;
final String FILEPATH = "./test.txt";

final int FILTERORDER = 2;

FileInputStream input;
int frameCounter = 0;

PImage imgOne;
PImage imgFilt;

byte[] pixelLoaded = new byte[NUM_PIXELS*TOT_FRAMES];
byte[] pixelFiltrd = new byte[NUM_PIXELS*TOT_FRAMES];

void setup() {
  size(1024, 848, P3D);
  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.enableDepthImg(true);
  kinect.init();

	imgOne = createImage(512, 424, PImage.RGB);
	imgFilt = createImage(512, 424, PImage.RGB);
  
  File directory = new File("./");
  System.out.println(directory.getAbsolutePath());  // This prints out the path where the file is saved.
  
  try {
    input = new FileInputStream(FILEPATH);
    print("Please wait patiently, loading file contents into memory.\n");
    int start = millis();
    input.read(pixelLoaded, 0, NUM_PIXELS*TOT_FRAMES);
    int end = millis();
    print("Loading of file contents took " + (end-start)/1000 + " seconds.\n");
    input.close();
  } catch(IOException ex) {
    ex.printStackTrace(); 
  }

	// Initialize the values in pixelFiltrd with new image movie with the median filter applied
	MedianFilter m = new MedianFilter(NUM_PIXELS, TOT_FRAMES, pixelLoaded, ROWS, COLS, FILTERORDER);
	pixelFiltrd = m.getFiltdArray();

  frameRate(FPS);
}
	

void draw() {
    background(0);

    imgOne.loadPixels();  
    imgFilt.loadPixels();  
		
   
    /*
     * These two statements consecutively must be executed to exit file immediately.
     */
    if (frameCounter == TOT_FRAMES) {
      exit();
      return;
    }
     
    /*
     * Main loop code
     */
    int [] rawData = kinect.getRawBodyTrack();
          
    /*
     * Compare intersection. The way the data is saved on file, all non-silhouette values are default zero
     * and all non-zero values are the values of depth. However, on our local system, we need to check both
     * rawData and rawdepthData for proper computation.
     */
    for (int i = 0; i < NUM_PIXELS; i++) {

      int savedDepth = pixelLoaded[frameCounter*NUM_PIXELS + i];
      int filtdDepth = pixelFiltrd[frameCounter*NUM_PIXELS + i]; //<>//
      
      if (savedDepth != 0) {
        imgOne.pixels[i] = color(0, 0, 255); 
      } else {
				imgOne.pixels[i] = color(0,0,0);
			}

      if (filtdDepth != 0) {
        imgFilt.pixels[i] = color(0, 0, 255); 
      } else {
        imgFilt.pixels[i] = color(0, 0, 0); 
			}
      
    } 
  
		imgOne.updatePixels();
    imgFilt.filter(BLUR, 1);
		imgFilt.updatePixels();

    image(imgOne, 0, 0); //top left
    image(imgFilt, 512, 0); // top right

    frameCounter++;
}


public class MedianFilter {
  private int n; //Median filter box order
  private int mRows;
  private int mCols;
  private int mFrames;
  private int mPixels; 

  private byte[] mLoaded;
  private byte[] mFiltrd;  

  /* 
  * Initializes MedianFilter which can implement median filtering on an array of frames, 
  * using a filter order fOrder = n.
  * The window size is determined by 2n+1 for an index n
  * For example:
  * n = 1 --> 3x3 window
  * n = 2 --> 5x5 window
  *
  * Parameters
  * numPixels : number of pixels per frame
  * totframes : total number of frames
  * cols      : number of columns in image
  * rows      : number of rows in image
  * fOrder    : the n value in for filter order explained above
  * 
  */
  public MedianFilter(int numPixels, int totframes, byte[] arr, int rows, int cols, int fOrder) {
    mLoaded = Arrays.copyOf(arr, numPixels*totframes);
    mFiltrd = new byte[numPixels*totframes];

    mPixels = numPixels;
    mFrames = totframes;
    mRows   = rows;
    mCols   = cols;
    n       = fOrder;

    filterAllFrames();
  }
  /*
   * Takes the loaded pixels and initializes the values of filtdFrames which holds the filtered pixels
   * for the whole movie (all frames are filtered).
   */
  void filterAllFrames() {
    for (int curFrame = 0; curFrame < mFrames; curFrame++) {
      filterFrame(curFrame*mPixels);
    }
  }

  /* 
   * Filters an individual frame at index cFi
   * cFi: the current frame's offset index in the array
   */
  void filterFrame(int cFi) {
    int windowSize = 2*n + 1;

    for (int curRow = 0; curRow < mRows; curRow++) {
      /* Apply median filter algorithm for non-edges */
      for (int i = cFi+curRow*mCols+n; i < cFi+(curRow+1)*mCols-n; i++) {
        mFiltrd[i] = findMedian(Arrays.copyOfRange(mLoaded, i-n, i+n), windowSize);
      }
      /* For edges/borders of image, just fill with the exact value of the old image */
      for (int i = 0; i < n; i++) {
          mFiltrd[cFi+curRow*mCols+i] = mLoaded[cFi+curRow*mCols+i];
          mFiltrd[cFi+(curRow+1)*mCols-i-1] = mLoaded[cFi+(curRow+1)*mCols-i-1];
      }
    }
  }

  /*
   * Find the median value for a byte array of size size
   *
   * arr  : the 1D array to find the median of
   * size : the number of the array
   */
  byte findMedian(byte[] arr, int size) {
    assert(size % 2 != 0); // Must be an odd number
    Arrays.sort(arr);
    return arr[size/2];
  }

  byte[] getFiltdArray() {
    return mFiltrd;
  }
}
