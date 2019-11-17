import KinectPV2.*;
KinectPV2 kinect;
import java.lang.Long;
import java.io.FileInputStream;
import java.io.FileOutputStream;
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
FileOutputStream output;
int frameCounter = 0;

PImage imgOne;
PImage imgFilt;
PImage imgPast;

MedianFilter curr;

byte[] pixelLoaded = new byte[NUM_PIXELS*TOT_FRAMES];
byte[] pixelFiltrd = new byte[NUM_PIXELS*TOT_FRAMES];

byte[] pixelToSave = new byte[NUM_PIXELS*TOT_FRAMES];

byte[] pixelSave = new byte[NUM_PIXELS*TOT_FRAMES];
int[] pixelTemp = new int[NUM_PIXELS];

void setup() {
  size(1024, 848, P3D);
  kinect = new KinectPV2(this);
  kinect.enableBodyTrackImg(true);
  kinect.enableDepthImg(true);
  kinect.init();

	imgOne = createImage(512, 424, PImage.RGB);
	imgFilt = createImage(512, 424, PImage.RGB);
  imgPast = createImage(512, 424, PImage.RGB);
  
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
	//MedianFilter loaded = new MedianFilter(NUM_PIXELS, TOT_FRAMES, pixelLoaded, ROWS, COLS, FILTERORDER);
	//pixelFiltrd = loaded.getFiltdArray();

	curr = new MedianFilter(NUM_PIXELS, TOT_FRAMES, ROWS, COLS, FILTERORDER);

  frameRate(FPS);
}
	

void draw() {
    background(0);

    imgOne.loadPixels();  
    imgFilt.loadPixels(); 
    imgPast.loadPixels();
		
   
    /*
     * These two statements consecutively must be executed to exit file immediately.
     */
    if (frameCounter == TOT_FRAMES) {
      try {
        print("Writing file to memory\n");
        output = new FileOutputStream(FILEPATH);
        output.write(pixelToSave, 0, NUM_PIXELS*TOT_FRAMES);
        output.close();
        print("Done writing file to memory\n");
      } catch (IOException ex) {
        ex.printStackTrace();
      }
         
      exit();
      return;
    }
     
    /*
     * Main loop code
     */
    int [] rawData = kinect.getRawBodyTrack();
    int[] rawDepthData = kinect.getRawDepthData();


    
		int off = 0;
		curr.filterFrame(rawData, pixelTemp, off);

    

          
    /*
     * Compare intersection. The way the data is saved on file, all non-silhouette values are default zero
     * and all non-zero values are the values of depth. However, on our local system, we need to check both
     * rawData and rawdepthData for proper computation.
     */
    for (int i = 0; i < NUM_PIXELS; i++) {
      int depth = rawDepthData[i]*256/4000;
			//int localData  = pixelTemp[i];
      //int savedDepth = pixelLoaded[frameCounter*NUM_PIXELS + i];
      //int filtdDepth = pixelFiltrd[frameCounter*NUM_PIXELS + i]; //<>//


			if (rawData[i] != 255) {
				imgOne.pixels[i] = color(0,0,255);
			} else {
        imgOne.pixels[i] = color(0,0,0);
      }
			if (pixelTemp[i] != 255) {
				imgFilt.pixels[i] = color(0,0,255);
        // Save the depth
        pixelToSave[frameCounter*NUM_PIXELS + i] = byte(depth);
			} else {
        imgFilt.pixels[i] = color(0,0,0);
      }
      if (pixelLoaded[frameCounter*NUM_PIXELS + i] != 0) {
        imgPast.pixels[i] = color(0, 0, 255);
      } else {
        imgPast.pixels[i] = color(0,0,0);
      }
      
      
    } 
  
		imgOne.updatePixels();
  //  imgFilt.filter(BLUR, 1);
		imgFilt.updatePixels();
    imgPast.updatePixels();

    image(imgOne, 0, 0); //top left
    image(imgFilt, 512, 0); // top right
    image(imgPast, 0, 512); 

    frameCounter++;
}


public class MedianFilter {
  private int n; //Median filter box order
  private int mRows;
  private int mCols;
  private int mFrames;
  private int mPixels; 
	private int mBox;
	private int mDim;

  private byte[] mFiltrd;  //Array of filtered past depth frames
	private int[]  itempArr;
  private byte[] btempArr;

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
  public MedianFilter(int numPixels, int totframes, int rows, int cols, int fOrder) {
    mPixels = numPixels;
    mFrames = totframes;
    mRows   = rows;
    mCols   = cols;
    n       = fOrder;
		mDim    = (2*n+1);
		mBox    = mDim*mDim;

		itempArr = new int[mBox];
    btempArr = new byte[mBox];
  }
  /*
   * Takes a whole array of past frames and then returns a new array which is the
   * filtered version of all depth frames. Not useful for real-time filtering
   */
  byte[] filterAllPastFrames(byte[] arr) {
    mFiltrd = new byte[mPixels*mFrames];
    byte[] mLoaded = Arrays.copyOf(arr, mPixels*mFrames);
		assert(mFiltrd.length == mLoaded.length);
    for (int curFrame = 0; curFrame < mFrames; curFrame++) {
      filterPastFrame(mLoaded, mFiltrd, curFrame*mPixels);
    }
		return mFiltrd;
  }

  /* 
   * Filters an individual frame at index cFi for past frames. Not useful for real-time 
   * filtering.
   * cFi: the current frame's offset index in the array
   */
  void filterPastFrame(byte[] mLoaded, byte[] mFiltrd, int cFi) {
    for (int curRow = n; curRow < mRows-n; curRow++) {
      /* Apply median filter algorithm for non-edges */
      for (int i = cFi+curRow*mCols+n; i < cFi+(curRow+1)*mCols-n; i++) {
			  int iter = 0;
				for (int j = -n; j <= n; j++) {
					System.arraycopy(mLoaded, i+j*mCols-n, btempArr, iter*mDim, mDim);
          iter++;
				}
        mFiltrd[i] = findMedian(btempArr, mBox);
        
      }
      for (int i = 0; i < n; i++) {
      		/* For left/right edges of image, just fill with the exact value of the old image */
          mFiltrd[cFi+curRow*mCols+i] = mLoaded[cFi+curRow*mCols+i];
          mFiltrd[cFi+(curRow+1)*mCols-i-1] = mLoaded[cFi+(curRow+1)*mCols-i-1];

					/* For top/bottom edges of image, just fill with exact same value of old image */
					System.arraycopy(mLoaded, i*mCols, mFiltrd, i*mCols, mCols);
					System.arraycopy(mLoaded, mPixels-(i+1)*mCols-1, mFiltrd, mPixels-(i+1)*mCols-1, mCols);
      }
    }
  }

  /* 
   * 
   * Filters the exact frame at the index cFi
   * cFi: the current frame's offset index in the array
   */
  void filterFrame(int[] mLoaded, int[] mFiltrd, int cFi) {
    for (int curRow = n; curRow < mRows-n; curRow++) {
      /* Apply median filter algorithm for non-edges */
      for (int i = cFi+curRow*mCols+n; i < cFi+(curRow+1)*mCols-n; i++) {
			  int iter = 0;
				for (int j = -n; j <= n; j++) {
					System.arraycopy(mLoaded, i+j*mCols-n, itempArr, iter*mDim, mDim);
          iter++;
				}
        mFiltrd[i] = findMedian(itempArr, mBox);
        
      }
      for (int i = 0; i < n; i++) {
      		/* For left/right edges of image, just fill with the exact value of the old image */
          mFiltrd[cFi+curRow*mCols+i] = mLoaded[cFi+curRow*mCols+i];
          mFiltrd[cFi+(curRow+1)*mCols-i-1] = mLoaded[cFi+(curRow+1)*mCols-i-1];

					/* For top/bottom edges of image, just fill with exact same value of old image */
					System.arraycopy(mLoaded, i*mCols, mFiltrd, i*mCols, mCols);
					System.arraycopy(mLoaded, mPixels-(i+1)*mCols-1, mFiltrd, mPixels-(i+1)*mCols-1, mCols);
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
  
  int findMedian(int[] arr, int size) {
    assert(size % 2 != 0); // Must be an odd number
    Arrays.sort(arr);
    return arr[size/2];
  }

  byte[] getFiltdArray() {
    return mFiltrd;
  }
}
