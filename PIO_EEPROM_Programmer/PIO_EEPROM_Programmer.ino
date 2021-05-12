#define PIN_D0      4
#define PIN_D7      11

#define PIN_STB     A5
#define PIN_RDY     2

#define CTRL_WRITE  0b01000000
#define CTRL_READ   0b10000000
#define CTRL_RESET  0b11000000

#define PAGE_SIZE   64

bool isModeInput = true;

bool isEnabled = false;

void setup() {
  // put your setup code here, to run once:
  pinMode(PIN_STB, OUTPUT);
  digitalWrite(PIN_STB, HIGH);
  pinMode(PIN_RDY, INPUT);

  setValueMode(false);

  Serial.begin(115200);
  while (!Serial) {
    continue;
  }
}

void loop() {
  // put your main code here, to run repeatedly:
  if (Serial.available() > 0) {
    parseInstruction();
  }
}

void parseInstruction() {
  String message = Serial.readString();
  Serial.println(message);

  if (!isEnabled) {
    if (message.equals("begin")) {
      isEnabled = true;
    }

    return;
  }

//  Serial.println(message.c_str());
  if (message.length() < 1) {
    return;
  }

  if (message.c_str()[0] == 'p') {
    word start;
    word ending;

    sscanf(message.c_str(), "p %x %x", &start, &ending);

    flushContent(start, ending);

    return;
  }

  else if (message.c_str()[0] == 'r') {
    byte reset;

    sscanf(message.c_str(), "r %x", &reset);

    send_reset(reset);

    return;
  }

  else if (message.length() > 4 && message.c_str()[4] == ':') {
    word data[32];
    word addr;
    byte buf[PAGE_SIZE];
    sscanf(message.c_str(), "%x: %x %x %x %x %x %x %x %x %x %x %x %x %x %x %x %x  %x %x %x %x %x %x %x %x %x %x %x %x %x %x %x %x",
      addr, data, data+1, data+2, data+3, data+4, data+5, data+6, data+7,
      data+8, data+9, data+10, data+11, data+12, data+13, data+14, data+15,
      data+16, data+17, data+18, data+19, data+20, data+21, data+22, data+23,
      data+24, data+25, data+26, data+27, data+28, data+29, data+30, data+31);
  
    for (int i = 0; i < 32; i++) {
      buf[2*i + 1] = data[i] & 0xff;
      buf[2*i] = data[i] >> 8;
    }
    
    addr = addr >> 6;
    
    writePage(addr, buf);
  
    Serial.println("DONE");
  }
}

void setValueMode(bool isInput) {
  if (isInput == isModeInput)
    return;
    
  for (int i = PIN_D0; i <= PIN_D7; i++) {
    pinMode(i, isInput ? INPUT : OUTPUT);
  }

  isModeInput = isInput;
}

void send_reset(byte reset) {
  //setup value pins as output
  setValueMode(false);

  writeByte(CTRL_RESET | (reset % 8));
}

void readPage(word page, byte* buff) {
  //setup value pins as output
  setValueMode(false);

  //Send control byte
  writeByte(CTRL_READ);

  //Send Addr High Byte
  writeByte(page >> 8);

  //Send Addr Low Byte
  writeByte(page % 256);

  // Once data latched, change from output to input
  setValueMode(true);

  for (int i = 0; i < PAGE_SIZE; i++)
    buff[i] = readByte();

  //After last byte, delay for a while
  //to make sure the CPU has had time to change the PIO from output to input
  delay(10);  //Wait 10 ms, which is > 40k clk cycles (40k @ 4Mhz; 100k @ 10MHz)

  setValueMode(false);
}

byte readByte() {
  //Wait for RDY pin
  while(digitalRead(PIN_RDY) == LOW) {
    continue;
  }
  
  //read value
  byte value = 0;
  for (int i = PIN_D7; i >= PIN_D0; i--) {
    value = (value << 1) + digitalRead(i);
  }

  //Pulse STB to send INT
  digitalWrite(PIN_STB, HIGH);
  digitalWrite(PIN_STB, LOW);
  delayMicroseconds(1);
  digitalWrite(PIN_STB, HIGH);

  //return value
  return value;
}

void writeByte(byte value) {
  //Wait until RDY is High
  while(digitalRead(PIN_RDY) == LOW) {
    continue;
  }
  
  //Send value
  for (int i = PIN_D0; i <= PIN_D7; i++) {
    digitalWrite(i, value & 1);
    value = value >> 1;
  }

  //Pulse STB to send INT
  digitalWrite(PIN_STB, HIGH);
  digitalWrite(PIN_STB, LOW);
  delayMicroseconds(1);
  digitalWrite(PIN_STB, HIGH);
}

void writePage(word page, byte* values) {
  //setup value mode as output
  setValueMode(false);

  //Send control byte
  writeByte(CTRL_WRITE);

  //Send Addr High Byte
  writeByte(page >> 8);

  //Send Addr Low Byte
  writeByte(page % 256);

  //Send PAGE_SIZE Bytes of the page
  for (word i = 0; i < PAGE_SIZE; i++)
    writeByte(values[i]);
}

void flushContent(word start, word ending) {
  Serial.println("");
  for (int i = start; i <= ending; i += PAGE_SIZE) {
    byte data[PAGE_SIZE];

    readPage(i, data);

    for (int j = 0; j < PAGE_SIZE; j += 16) {
      char buf[80];
      sprintf(buf, "%04x: %02x %02x %02x %02x  %02x %02x %02x %02x   %02x %02x %02x %02x  %02x %02x %02x %02x",
      i + j, data[0 + j], data[1 + j], data[2 + j], data[3 + j], data[4 + j], data[5 + j], data[6 + j], data[7 + j],
      data[8 + j], data[9 + j], data[10 + j], data[11 + j], data[12 + j], data[13 + j], data[14 + j], data[15 + j]);
  
      Serial.println(buf);
    }
  }
  Serial.println("END");
}
