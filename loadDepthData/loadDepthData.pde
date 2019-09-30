  Table table;
void setup()
{ 
   table = loadTable("fun63.csv","header");
   size(512, 424);

}

void draw()
{
  // Before we deal with pixels
  loadPixels();  
  // Loop through every pixel
  int x_table = 0;
  int y_table = 0;
  for (int x = 0; x < 10; x++) 
  {
    for (int y = 0; y < 512; y++)
    {
      int index = y+x*512;
      String column = "col" + str(y);
      int bright = table.getInt(x,column);
      //println(bright);
      color c = bright;
      pixels[index] = c;
      delay(10);
    }
    //println("hello" + str(x));
  }
  
  // When we are finished dealing with pixels
  updatePixels(); 
  print("DONE");
}
