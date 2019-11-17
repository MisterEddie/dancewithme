import KinectPV2.*;
import java.lang.Long;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.Arrays; 

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
