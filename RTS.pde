import controlP5.*;

PImage img;  // Declare variable "a" of type PImage
PImage img1;
PGraphics pg;

int TABLE_SIZE = 20; 
int display_flag = 1;
int mX = mouseX,mY = mouseY; 
String MapTilesPath = "/Virtual Earth/ter_tiles";
int homeDetFlag = 0;
int MAP_MAX_ZOOM_LEVEL = 17;
int MAP_MIN_ZOOM_LEVEL = 3;
int TILES_WIDTH = 256;
int TILES_HEIGHT = 256;
int zoom = MAP_MAX_ZOOM_LEVEL-1;
int new_zoom = 0;
float Latitude = 0.0 ,Longitude = 0.0;
float[] home_lat_table = new float[TABLE_SIZE];
float[] home_lon_table = new float[TABLE_SIZE];
float[] det_lat_table = new float[TABLE_SIZE];
float[] det_lon_table = new float[TABLE_SIZE];
int home_table_size = 0;
int det_table_size = 0;

int tileX, tileY,offsetX, offsetY, lastTileX,lastTileY;
ControlP5 cp5;

MapData[] mpdt;

void setup() {
  //size(256*3, 256*2);
  size(displayWidth-100,displayHeight-100);
  pg = createGraphics(width, height);
  background(100);
  noStroke();
  cp5 = new ControlP5(this);
  mpdt = new MapData[26];
  mpdt[0] = new MapData(0);
  for(int i = 1; i<=25;i++)
  {
    mpdt[i] = new MapData(1);
    mpdt[i].setBattery(i*4);
  }
  readConfigFile();
  //create_button();
  createDataTable();
  homeDetFlag = 0;
  //noLoop();
}

void draw() {
  
  
  if(display_flag == 1)
  {
    display_flag = 0;
  display_map();

  }
  get_mouse_coordinates();
}
void get_mouse_coordinates()
{
  if(mX != mouseX || mY != mouseY || new_zoom != zoom)
  {
    mX = mouseX;
    mY = mouseY;  
    int[] a = get_tile_offset_from_mousepos(mX,mY);
    float[] coord = tile_to_coord(a[0],a[1],a[2],a[3],zoom);
    fill(51, 51, 255);
    rect(0, height-15, width, height);
    fill(0,0,0);
    textSize(10);
    text("Zoom: " + zoom + "  Coordinates: "+coord[0]+" , "+coord[1],3,height - 3);
    if(homeDetFlag == 1)
      text("Detonator Button Selected",width - 130,height - 3);
    else
      text("Home Button Selected",width - 110,height - 3);
    
  }
}

void display_map()
{
  pg.beginDraw();
  pg.background(100);
  int[] a = new int[6];
  a = get_tile_to_display();
  int tX = a[0];
  int tY = a[1];
  int oX = a[4];
  int oY = a[5];
  tileX = a[0];
  tileY = a[1];
  lastTileX = a[2];
  lastTileY = a[3];
  offsetX = a[4];
  offsetY = a[5];
  
  while(tX <= a[2])
  {
    while(tY <= a[3])
    {
      img = loadImage(tile_to_path(tX,tY,zoom));
      if(img == null)
        img = loadImage("no_image.png");
      pg.image(img,oX,oY); 
      oY += TILES_HEIGHT;
        
     tY++;
    }
    tX++;
    tY = a[1];
    oY = a[5];
    oX += TILES_HEIGHT;
  }
pg.endDraw();
image(pg,0,0);
CheckandPrintImageonMap();
UpdateMapdata();
}

int tiles_on_level(int zoom_level)
{
    return ((1 << (MAP_MAX_ZOOM_LEVEL - int(zoom_level))));
}

void keyPressed() {
  if (key == CODED){
   if (keyCode == UP) {
     if(Latitude < 90)
     {
       Latitude += 1.0;
        //redraw();
        display_flag = 1;
     }
    } else if (keyCode == DOWN) {
      if(Latitude > -90)
     {
       Latitude -= 1.0;
       //redraw();
        display_flag = 1;
     }
    } else if (keyCode == RIGHT) {
      if(Longitude < 180)
     {
       Longitude += 1.0;
       //redraw();
        display_flag = 1;
     }
    } else if (keyCode == LEFT) {
      if(Longitude > -180)
     {
       Longitude -= 1.0;
        //redraw();
        display_flag = 1;
     }
    }  
    
  } 
  else{
    if (key == '-' || key == '_') {
      change_zoom(1);
      
    } else if (key == '+' || key == '=') {
      change_zoom(-1);
    } 
  }

}

String tile_to_path(int tileX, int tileY, int zoom_level)
{
  String[] str1 = new String[6];
  //str1[0] = "/Virtual Earth/ter_tiles";
  str1[0] = MapTilesPath;
  str1[1] = str(zoom_level);
  str1[2] = str(tileX / 1024);
  str1[3] = str(tileX % 1024);
  str1[4] = str(tileY / 1024);
  str1[5] = str(tileY % 1024);
  String[] str2 = new String[2];
  str2[0] = join(str1,"/");
  str2[1] = "png";
  String filename = join(str2,".");
  return (filename);
}

// Convert from coord(lat, lng, zoom_level) to (tileX, tileY, offsetX, offsetY)
int[] coord_to_tile(float lat, float lng, int zoom_level)
{
    int world_tiles = tiles_on_level(zoom_level);
    float x = world_tiles * ((lng + 180.0)/360);
    float tiles_pre_radian = world_tiles / 2;
    float e = 1/cos(lat * (PI / 180));
    float g = tan(lat * (PI / 180));
    float y = (1 - (log( e + g )/PI))*tiles_pre_radian;
    int[] result = new int[4];
    result[0] = int(x) % world_tiles;  // tileX
    result[1] = int(y) % world_tiles;  // tileY
    result[2] = int((x - int(x)) * TILES_WIDTH);  // offsetX
    result[3] = int((y - int(y)) * TILES_HEIGHT); // offsetY
    println("tx = " + result[0]+",ty = " + result[1]+",ox = " + result[2]+",oy = " + result[3]);
    return (result);
}

// Convert from ((tile, offset), zoom_level) to coord(lat, lon, zoom_level)
float[] tile_to_coord(int tilex,int tiley,int offsetx,int offsety, int zoom_level)
{
    int world_tiles = tiles_on_level(zoom_level);
  // println("world_tiles: " + world_tiles);
    float x = (float)((tilex * TILES_WIDTH) + offsetx) / TILES_WIDTH;
  //  println("x " + x);
    float y = (float)((tiley * TILES_HEIGHT) + offsety) / TILES_HEIGHT;
  // println("y " + y);
    float lon = ((x*360.0) /world_tiles) - 180.0;
   // println("lon " + lon);
    y = y / world_tiles;
   // println("y " + y);
    float e = (float)Math.sinh(PI - (y * 2 * PI));
   // println("e " + e);
    float lat = (180 / PI) * atan(e);
   // println("lat " + lat);
    float[] result = new float[2];
    result[0] = lat;
    result[1] = lon; 
    return result;
}

int[] get_tile_offset_from_mousepos(int posx,int posy)
{
  int[] a = new int[4];
  a[0] = tileX;
  a[1] = tileY;
  a[2] = offsetX;
  a[3] = offsetY;
  //println("posx: " + posx +" ,posy: " + posy);
  //println("sx: " + (posx - 128) +" ,sy: " + (posy));
  ////println("x: " + tileX + " ,y: " + tileY + " ,ox: " + offsetX + " ,oy: " + offsetY);
  if(a[2] < 0 && posx <= (TILES_WIDTH + a[2]))
  {
      a[2] = posx + abs(a[2]);  
  }
  
  else
  {
    if(a[2] < 0)
    {
      a[2] = (TILES_WIDTH + a[2]);
      a[0]++;
    }
    a[2] = posx - a[2];
    
    while(a[2] > TILES_WIDTH)
    {
      a[0]++;
      a[2] = a[2] - TILES_WIDTH;
    }
  }
  if(a[3] < 0 && posy <= (TILES_HEIGHT + a[3]))
  {
    a[3] = abs(a[3]) + posy;
  }
  else
  {
    if(a[3] < 0)
    {
      a[3] = TILES_HEIGHT + a[3];
      a[1]++;
    }
    a[3] = posy - a[3];
    
    while(a[3] > TILES_HEIGHT)
    {
      a[1]++;
      a[3] = a[3] - TILES_HEIGHT;
    }
  }
   //println("a[0]: " + a[0] + " ,a[1]: " + a[1] + " ,a[2]: " + a[2] + " ,a[3]: " + a[3]);
  return a;
}

int[] get_tile_to_display()
{
  int[] a = new int[4];
  int[] b = new int[6];
  int world_tiles = tiles_on_level(zoom)-1;
 
  a = coord_to_tile(Latitude,Longitude,zoom);
  b[4] = (width/2) - a[2];
  b[5] = (height/2)- a[3];
  b[0] = b[2] = a[0];
  b[1] = b[3] = a[1];
  while(b[0] > 0)
  {
    b[0] --;
    b[4] = b[4] - TILES_WIDTH;
    if(b[4] < 0)
      break;
  }
  while(b[1] > 0)
  {
    b[1] --;
    b[5] = b[5] - TILES_HEIGHT;
    if(b[5] < 0)
      break;
  }
  a[2] = TILES_WIDTH - a[2];
  a[3] = TILES_HEIGHT- a[3];
  while(b[2] < world_tiles)
   {
     
     a[2] += TILES_WIDTH;
     if(a[2] >= width)
       break;
     b[2]++;
     
   } 
  while(b[3] < world_tiles)
   {
     
     a[3] += TILES_HEIGHT;
     if(a[3] >= height)
       break;
     b[3]++;
     
   }
  return b;
}

void readConfigFile ()
{
  String[] buff = loadStrings("config.cfg");
  String[] list = new String[2];
  for(int a = 0;a < buff.length; a++)
  { 
   list = split(buff[a], ':');
   if(list[0].equals("Sat_Tile_Path")) {
     if(list[1] != null)
       MapTilesPath = list[1];
   } else if(list[0].equals("Centre_Lon")) {
     if(list[1] != null)
       Longitude = float(list[1]);
     println("lon:" +Longitude);
   } else if(list[0].equals("Centre_Lat")) {
     if(list[1] != null)
       Latitude = float(list[1]);
       println("lat:"+ Latitude);
   } else if(list[0].equals("Min_Zoom")) {
     if(list[1] != null)
       MAP_MIN_ZOOM_LEVEL = int(list[1]);
       println("lat:"+ Latitude);
   } 
  }
}

void create_button(){
  noStroke();
  cp5 = new ControlP5(this);
  
  PImage[] btn = {loadImage("home_a.png"),loadImage("home_b.png"),loadImage("home_c.png")};
  cp5.addButton("home")
     .setValue(128)
     .setPosition(0,0)
     .setImages(btn)
     .updateSize()
     ;
   btn[0] = loadImage("detonator_a.png");
   btn[1] = loadImage("detonator_b.png");
   btn[2] = loadImage("detonator_c.png");
   cp5.addButton("detonator")
     .setValue(128)
     .setPosition(20,0)
     .setImages(btn)
     .updateSize()
     ;
   cp5.addTextfield("latitude , longitude")
     .setPosition(40,0)
     .setAutoClear(false)
     ;
}

void mouseWheel(MouseEvent event) {
  float e = event.getAmount();
  change_zoom(e);
}

void change_zoom(float e)
{
   if (e > 0) {
      if(zoom < MAP_MAX_ZOOM_LEVEL-1) {
        zoom++;
        
        display_flag = 1;
      }
    } else  {
      if(zoom > MAP_MIN_ZOOM_LEVEL) {
        zoom--;
        
        display_flag = 1;
      }
    } 
}

void mouseClicked(MouseEvent e) {
  if (e.getClickCount()==2) {
    if (mouseButton == LEFT) {
      int[] a = get_tile_offset_from_mousepos(mouseX,mouseY);
      float[] coord = tile_to_coord(a[0],a[1],a[2],a[3],zoom);
      Latitude = coord[0];
      Longitude = coord[1];
      change_zoom(-1);
   } 
   if (mouseButton == RIGHT) {
      int[] a = get_tile_offset_from_mousepos(mouseX,mouseY);
      float[] coord = tile_to_coord(a[0],a[1],a[2],a[3],zoom);
      AddImageOnCoordinate(coord[0],coord[1]);
      if(homeDetFlag == 0)
        img1 = loadImage("home_a.png"); 
      else
        img1 = loadImage("detonator_a.png");
      image(img1,mouseX,mouseY); 
   }
  }
}

void controlEvent(ControlEvent theEvent) {
  if(theEvent.isAssignableFrom(Textfield.class)) {
   String[] cd = split(theEvent.getStringValue(),',');
   float lt = float(cd[0]);
   float ld = float(cd[1]);
   //println(lt + "," + ld);
   AddImageOnCoordinate(lt,ld);  
  CheckandPrintImageonMap(); 
  }
}

void AddImageOnCoordinate(float lt, float ld)
{
  if(homeDetFlag == 0)
  {
    if(home_table_size < TABLE_SIZE)
    {
      home_lat_table[home_table_size ] = lt;
      home_lon_table[home_table_size ] = ld;
      home_table_size++;
    }
    else
    {
      //println("home table full");
    }
  }
  else
  {
     if(det_table_size < TABLE_SIZE)
    {
      det_lat_table[det_table_size ] = lt;
      det_lon_table[det_table_size ] = ld;
      det_table_size++;
    }
    else
    {
      //println("Detonator table full");
    }
  }
}

void CheckandPrintImageonMap()
{
  int[] b = new int[4];
  int[] c = new int[2];
  img = loadImage("home_a.png");
  for(int a = 0; a < home_table_size; a++)
  {
    b = coord_to_tile(home_lat_table[a],home_lon_table[a],zoom);
    if((b[0] >= tileX && b[0] <= lastTileX) && (b[1] >= tileY && b[1] <= lastTileY))
    {
      c = coord_to_display_xy(home_lat_table[a],home_lon_table[a],zoom);
      image(img,c[0],c[1]);
    }
  }
  img = loadImage("detonator_a.png");
  for(int a = 0; a < det_table_size; a++)
  {
    b = coord_to_tile(det_lat_table[a],det_lon_table[a],zoom);
    if((b[0] >= tileX && b[0] <= lastTileX) && (b[1] >= tileY && b[1] <= lastTileY))
    {
      c = coord_to_display_xy(det_lat_table[a],det_lon_table[a],zoom);
      image(img,c[0],c[1]);
    }
  }
}
public void home(int theValue) {
  homeDetFlag = 0;
  //println("home");
}

public void detonator(int theValue) {
  homeDetFlag = 1;
  //println("detonator");
}

int[] coord_to_display_xy(float lat, float lng, int zoom_level)
{
    int[] a = coord_to_tile(lat,lng,zoom_level);
    int[] b = new int[2];
    int c;
    println("tileX =" + tileX+",tileY =" + tileY+",offsetX =" + offsetX+",offsetY =" + offsetY);
    if(a[0] == tileX)
    {
      if(offsetX < 0)
        b[0] = a[2]-abs(offsetX);
      else
        b[0] = a[2] + offsetX;
    }
    else
    {
      if(offsetX < 0)
      {
          b[0] = TILES_WIDTH - abs(offsetX);
          c = tileX + 1;
      }
      else
      {
          b[0] = offsetX;
          c = tileX;
      }
      while(c < a[0])
      {
        b[0] = b[0] + TILES_WIDTH;
        c++;
      }
      b[0] = b[0] + a[2];
    }
    if(a[1] == tileY)
    {
      if(offsetY < 0)
      b[1] = a[3]-abs(offsetY);
      else
      b[1] = a[3]+abs(offsetY);
    }
    else
    {
      if(offsetY < 0)
      {
          b[1] = TILES_HEIGHT - abs(offsetY);
          c = tileY + 1;
      }
      else
      {
        b[1] = offsetY;
        c = tileY;
      }
      while(c < a[1])
      {
        b[1] = b[1] + TILES_HEIGHT;
        c++;
      }
      b[1] = b[1] + a[3];
    }
    println("x = " + b[0] + " , y = "+ b[1]);
    return (b);
}

float[] get_pan_constant(int zoom_level)
{
  float[] a = tile_to_coord(0,0,5,5,zoom);
  float[] b = tile_to_coord(0,0,6,6,zoom);
  b[0] = b[0] - a[0];
  b[1] = b[1] - a[1];
  return b;  
}
