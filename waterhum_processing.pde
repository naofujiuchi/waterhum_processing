import processing.serial.*;
PFont font;	// Instance of font class
PImage PAUSEIMG;
PImage RUNIMG;	// Instance of image class
boolean flag;
Serial myPort;
//variables for duty hour
public static final int OFFDUTY = 0;
public static final int ONDUTY = 1;
//variables for state
public static final int INITIAL = 0;
public static final int PAUSE = 1;
public static final int STOP = 2;
public static final int RUN = 3;
public static final int TERMINATE = 4;
//variables for level
public static final int LOW = 0;
public static final int HIGH = 1;
int s;
int m;
int h;
String t;
int[] alertcount = new int[4];
int[] press = new int[4];
int[] level = new int[4];
int[] inByte = new int[4];
int[] out = new int[4];
int[] serial = new int[8];
int[] state = new int[4];
int[] duty = new int[4];
PImage[] img = new PImage[4];
void setup(){
	int i;
	size(500, 400);
	frameRate(1);
	font = loadFont("Calibri-24.vlw");
	textFont(font);
	textAlign(RIGHT);
	myPort = new Serial(this, "COM7", 9600);
	myPort.buffer(10);
	RUNIMG = loadImage("playgreen.png");
	PAUSEIMG = loadImage("pausegreen.png");
	flag = false;
	for(i = 1; i <= 3; i++){
		press[i] = 0;
		level[i] = 0;
		inByte[i] = 0;
		serial[i] = 0;
		state[i] = INITIAL;
		duty[i] = OFFDUTY;
		img[i] = PAUSEIMG;
	}
}
void draw(){
	int i;
	background(100);
	gettime();
	for(i = 1; i <= 3; i++){
		duty[i] = getduty(i);
		state[i] = getstate(i);
	}
	if(myPort.available() == 5){
		readserial();
		myPort.clear();  //clear serial buffer
		inByte[1] = controlpump(1);
		inByte[2] = controlpump(2);
		inByte[3] = controlheater(3);
		for(i = 1; i <= 3; i++){
			img[i] = getpicture(state[i]);
			myPort.write(inByte[i]);
		}
    	println("success");
    }
    display();
	delay(1000);
}
int getduty(int _i){
	switch(_i){
		case 1:
			if((h == 5) && (m < 20)){
				return ONDUTY;
			}else{
				return OFFDUTY;
			}
		case 2:
			if((h % 2 == 0) && (m < 20)){
				return ONDUTY;
			}else{
				return OFFDUTY;
			}
		default:
			return OFFDUTY;
	}
}
int getstate(int _i){
	if(press[_i] % 2 == 1){
		return RUN;
	}else{
		return PAUSE;
	}
}
int controlpump(int _i){
	if(inByte[_i] != TERMINATE){
		if(state[_i] == RUN){
			if(duty[_i] == ONDUTY){
				if(level[_i] == LOW){
					alertcount[_i]++;
					if(alertcount[_i] >= 300){
						return TERMINATE;
					}else{
						return RUN;
					}
				}else{
					alertcount[_i] = 0;
					return STOP;
				}
			}else{
				alertcount[_i] = 0;
				return STOP;
			}
		}else{
			alertcount[_i] = 0;
			return PAUSE;
		}
	}else{	// when inBye = TERMINATE (4)
		if(state[_i] == RUN){
			return TERMINATE;
		}else{
			alertcount[_i] = 0;
			return PAUSE;
		}
	}
}
int controlheater(int _i){
	if(inByte[_i] != TERMINATE){
		if(alertcount[2] >= 300){
			return TERMINATE;
		}else{
			return RUN;
		}
	}else{
		if(state[_i] == RUN){
			return TERMINATE;
		}else{
			return PAUSE;
		}
	}
}
void gettime(){
	h = int(hour());
	m = int(minute());
	s = int(second());
	t = h + ":" + nf(m, 2) + ":" + nf(s, 2);
}
PImage getpicture(int _state){
	switch(_state){
		case RUN:
			return RUNIMG;
		case PAUSE:
			return PAUSEIMG;
		default:
			return PAUSEIMG;
	}
}
void readserial(){
	int i;
	for(i = 1; i <= 5; i++){
		serial[i] = myPort.read();
	}
	inByte[1] = serial[1];	//for SSR1 on WP1 on growth bed
	inByte[2] = serial[2];	//for SSR2 on WP2 on humidifier
	inByte[3] = serial[3];	//for SSR3 on heater on humidifier
	level[1] = serial[4];	//FS1 on growth bed
	level[2] = serial[5];	//FS2 on humidifier
}
void mousePressed(){
	press[0]++;
	if(press[0] == 1){
		initialize();
	}
	if(mouseX >= 40 && mouseX <= 220 && mouseY >= 180 && mouseY <= 360){
		press[1]++;
	}
	if(mouseX >= 290 && mouseX <= 470 && mouseY >= 180 && mouseY <= 360){
		press[2]++;
	}
}
void initialize(){
	myPort.clear();
	myPort.write(1);
	myPort.write(1);
	myPort.write(1);
	println("Serial initialized");
}
void display(){
	int i;
	text("Autowater", 180, 20);
	text("Humidifier1", 430, 20);
	text(t, 295, 20);
	text("duty", 275, 60);
	text(duty[1], 135, 60);
	text(duty[2], 380, 60);
	text("level", 275, 85);
	text(level[1], 135, 85);
	text(level[2], 380, 85);
	text("state", 275, 110);
	text(state[1], 135, 110);
	text(state[2], 380, 110);
	text("inByte", 280, 135);
	text(inByte[1], 135, 135);
	text(inByte[2], 360, 135);
	text(inByte[3], 400, 135);
	text("alertcount", 280, 160);
	text(alertcount[1], 135, 160);
	text(alertcount[2], 380, 160);
	for(i = 1; i <= 2; i++){
		image(img[i], 250 * (i - 1), 140);
	}
}