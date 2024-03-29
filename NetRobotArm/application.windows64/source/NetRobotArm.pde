import net.tootallnate.websocket.*;



import processing.net.*;
import java.io.UnsupportedEncodingException; 
import java.security.MessageDigest; 
import java.security.NoSuchAlgorithmException; 
import sun.misc.BASE64Encoder;
import processing.serial.*;
import cc.arduino.*;
import processing.net.*;
import java.math.BigInteger;

Arduino arduino;

int OPENGRIP=11;
int CLOSEGRIP=10;
int M3U= 9;
int M3D =8;
int M2U= 6;
int M2D=7;
int M1U=4;
int M1D= 5;
int TURNLEFT= 2;
int TURNRIGHT= 3;
int SEARCHLIGHT= 12;


int[] onTimes=new int[13];
int[] onTimeLimits=new int[13];

ChatServer s;

private class ChatServer extends WebSocketServer {
  public String msg="";
  
    public ChatServer(int port) {
        super(port);
    }

    public void onClientOpen(WebSocket conn) {
        try {
            this.sendToAll(conn + " entered the room!");
        } catch (IOException ex) {
            ex.printStackTrace();
        }
        System.out.println(conn + " entered the room!");
    }

    public void onClientClose(WebSocket conn) {
        try {
            this.sendToAll(conn + " has left the room!");
        } catch (IOException ex) {
            ex.printStackTrace();
        }
        System.out.println(conn + " has left the room!");
    }

    public void onClientMessage(WebSocket conn, String message) {
        try {
            this.sendToAll(conn + ": " + message);
        } catch (IOException ex) {
            ex.printStackTrace();
        }
        System.out.println(conn + ": " + message);
        msg+=conn+": "+message+"\n";
    }

    public void onIOError(IOException ex) {
      ex.printStackTrace();
    }


}


String convertToHex(byte[] data) { 
        StringBuffer buf = new StringBuffer();
        for (int i = 0; i < data.length; i++) { 
            int halfbyte = (data[i] >>> 4) & 0x0F;
            int two_halfs = 0;
            do { 
                if ((0 <= halfbyte) && (halfbyte <= 9)) 
                    buf.append((char) ('0' + halfbyte));
                else 
                    buf.append((char) ('a' + (halfbyte - 10)));
                halfbyte = data[i] & 0x0F;
            } while(two_halfs++ < 1);
        } 
        return buf.toString();
} 

String SHA1(String text) throws NoSuchAlgorithmException, UnsupportedEncodingException  {
    MessageDigest md;
    md = MessageDigest.getInstance("SHA-1");
    byte[] sha1hash = new byte[40];
    md.update(text.getBytes("iso-8859-1"), 0, text.length());
    sha1hash = md.digest();
   // return convertToHex(sha1hash);
    return new String(new BASE64Encoder().encode(sha1hash));
} 

int port = 10002;       
Server myServer;        
int updateCount=0;
String messageFromClient;

/*void setup(){
 s=new ChatServer(port);
 s.start();
   size(1000, 1000);
     background(150);
}*/


void setup()
{
  size(1000, 1000);
  myServer = new Server(this, port);
  messageFromClient = new String("");

  background(150);
  
  arduino = new Arduino(this, Arduino.list()[0], 57600);
  
  for(int i=2;i<=12;i++){
      arduino.pinMode(i, Arduino.OUTPUT);
      arduino.digitalWrite(i, Arduino.LOW);
      onTimes[i]=0;
      onTimeLimits[i]=100;
  }
  onTimeLimits[2]=200;
  onTimeLimits[3]=200;
  onTimeLimits[0]=-1;
   onTimeLimits[1]=-1;
    onTimeLimits[12]=-1;
    
   arduino.digitalWrite(12,Arduino.HIGH);
   delay(1000);
   arduino.digitalWrite(12,Arduino.LOW);  
  
}

byte[] decodeDataFrame(byte[] bytes){
  int length_code=bytes[1] & 127;
  //return length_code;
  byte[] data;
  byte[] masks=new byte[4];
  
  masks[0]=bytes[2];
  masks[1]=bytes[3];
  masks[2]=bytes[4];
  masks[3]=bytes[5];
  
  /*if (length_code==126){
    masks=bytes.slice(4,8);
    data=bytes.slice(8); 
  }
  else if(length_code=127){
    masks=bytes.slice(10,14);
   data=bytes.slice(14); 
  }
  else{
   masks=bytes.slice(2,6);
   data=bytes.slice(6); 
  }*/
  
  byte[] decode=new byte[bytes.length-6];
  
  for(int i=6;i<bytes.length;i++){
    decode[i-6]= byte(bytes[i] ^ masks[ (i-6) % 4 ]); 
  }
  
  return decode;
  
}

 
byte[] makeHandshakeValue(String ClientKey1,String ClientKey2, byte[] ClientKey3) throws NoSuchAlgorithmException,UnsupportedEncodingException {
  StringBuffer key1DigitCat=new StringBuffer();
  StringBuffer key2DigitCat=new StringBuffer();
  int numSpaceKey1=0;
  int numSpaceKey2=0;
  
  for(int i=0;i<ClientKey1.length();i++){
     char c=ClientKey1.charAt(i);
     if(c==' '){
        numSpaceKey1++;
     } 
     else{
       if(Character.isDigit(c)){
          key1DigitCat.append(c);
       }
     }
  }
 
   for(int i=0;i<ClientKey2.length();i++){
     char c=ClientKey2.charAt(i);
     if(c==' '){
        numSpaceKey2++;
     } 
     else{
       if(Character.isDigit(c)){
          key2DigitCat.append(c);
       }
     }
  }
  
 BigInteger u1=new BigInteger(key1DigitCat.toString());
 BigInteger u2=new BigInteger(key2DigitCat.toString());
 BigInteger d1=new BigInteger(new Integer(numSpaceKey1).toString());
 BigInteger d2=new BigInteger(new Integer(numSpaceKey2).toString());
 int numDivide1=u1.divide(d1).intValue();
 int numDivide2=u2.divide(d2).intValue();
  
  byte[] enc=new byte[16];
  
  enc[0] =(byte)( numDivide1 >> 24 );
  enc[1] =(byte)( (numDivide1 << 8) >> 24 );
  enc[2] =(byte)( (numDivide1 << 16) >> 24 );
  enc[3] =(byte)( (numDivide1 << 24) >> 24 );
  enc[4] =(byte)( numDivide2 >> 24 );
  enc[5] =(byte)( (numDivide2 << 8) >> 24 );
  enc[6] =(byte)( (numDivide2 << 16) >> 24 );
  enc[7] =(byte)( (numDivide2 << 24) >> 24 ); 
  for(int i=8;i<16;i++){
   enc[i]=ClientKey3[i-8];
  }  
  
  MessageDigest md = MessageDigest.getInstance("MD5");
  //digest.update(enc, 0, enc.length);
  byte[] md5sum = md.digest(enc);
  
  
  
  return md5sum;// new String(md5sum,"UTF8");
}
 
 
/*void draw(){
  text(s.msg,50,50);
}*/
 
byte[] draft76_getPart(String key) {
    long keyNumber = Long.parseLong(key.replaceAll("[^0-9]",""));
    long keySpace = key.split("\u0020").length - 1;
    long part = new Long(keyNumber / keySpace);
    return new byte[] {
      (byte)( part >> 24 ),
      (byte)( (part << 8) >> 24 ),
      (byte)( (part << 16) >> 24 ),
      (byte)( (part << 24) >> 24 )      
 };
}
 
 
void draw()
{
  updateCount++;
  // Get the next available client
  background(150);
 // byte[] newEnc;
 /* try
  { newEnc=makeHandshakeValue("18x 6]8vM;54 *(5:  {   U1]8  z [  8","1_ tx7X d  <  nw  334J702) 7]o}` 0",("Tm[K T2u").getBytes());
  }catch(NoSuchAlgorithmException e){
    newEnc=new byte[0]; 
  }catch(UnsupportedEncodingException e){
    newEnc=new byte[0]; 
  }*/
   text("updating "+updateCount,30,30);
   // text("encoded as "+new String(newEnc),30,50);
  Client thisClient = myServer.available();
  // If the client is not null, and says something, display what it said
  if (thisClient !=null) {
    byte[] bytesRead = thisClient.readBytes();
    String whatClientSaid = new String(bytesRead);
    
    if(bytesRead!=null){
       
       
       messageFromClient=thisClient.ip() + ":\n" +whatClientSaid;
       
       int clientKeyPos=whatClientSaid.indexOf("Sec-WebSocket-Key:");
       
       int clientKey1Pos=whatClientSaid.indexOf("Sec-WebSocket-Key1:");
       int clientKey2Pos=whatClientSaid.indexOf("Sec-WebSocket-Key2:");
       
       
       
       if (clientKeyPos>-1)
        {
            int clientKeyEnd=whatClientSaid.indexOf("\n",clientKeyPos);
            String clientKey=whatClientSaid.substring(clientKeyPos+18,clientKeyEnd).trim();

            
            try{
              //clientKey="dGhlIHNhbXBsZSBub25jZQ==";
              String SHA1AcceptKey=SHA1(clientKey+"258EAFA5-E914-47DA-95CA-C5AB0DC85B11");
              String headerSend="HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: "+SHA1AcceptKey+"\r\n\r\n";
              myServer.write(headerSend);
              messageFromClient= messageFromClient+"["+clientKey+"]"+"\n"+headerSend+"\n";
              //delay(5000);
            }catch(Exception e){
              
            }
            
            //reset light when client connect
            arduino.digitalWrite(12,Arduino.LOW);
      }
      else if(clientKey1Pos>-1)
     {
         int clientKey1End=whatClientSaid.indexOf("\n",clientKey1Pos);
          int clientKey2End=whatClientSaid.indexOf("\n",clientKey2Pos);
           String key1=whatClientSaid.substring(clientKey1Pos+19,clientKey1End).trim();
       String key2=whatClientSaid.substring(clientKey2Pos+19,clientKey2End).trim();
       
       byte[] key3=new byte[8];
       for(int i=0;i<8;i++){
         key3[i]=bytesRead[bytesRead.length-8+i]; 
       }
        messageFromClient= messageFromClient+"\n["+key1+"|"+key2+"|"+key3+"]"+"\n";
        //  try
        //{ 
         // newEnc=makeHandshakeValue(clientKey1,clientKey2,clientKey3);
        //}catch(NoSuchAlgorithmException e){
        //  newEnc=new byte[0]; 
        //}catch(UnsupportedEncodingException e){
   // newEnc=new byte[0];
 // }
       byte[] part1 = draft76_getPart(key1);
        byte[] part2 = draft76_getPart(key2);
        byte[] challenge = new byte[16];
        challenge[0] = part1[0];
        challenge[1] = part1[1];
        challenge[2] = part1[2];
        challenge[3] = part1[3];
        challenge[4] = part2[0];
        challenge[5] = part2[1];
        challenge[6] = part2[2];
        challenge[7] = part2[3];
        challenge[8] = key3[0];
        challenge[9] = key3[1];
        challenge[10] = key3[2];
        challenge[11] = key3[3];
        challenge[12] = key3[4];
        challenge[13] = key3[5];
        challenge[14] = key3[6];
        challenge[15] = key3[7];
        
        
        byte[] responseChallenge;
       
       try{
         MessageDigest md5 = MessageDigest.getInstance("MD5");
       responseChallenge = md5.digest(challenge);
       }catch(NoSuchAlgorithmException e){
        responseChallenge=new byte[0]; 
       }
       //messageFromClient=messageFromClient+"\nReplyKey:["+newEnc+"]\n";
      
         String headerSend="HTTP/1.1 101 WebSocket Protocol Handshake\r\nUpgrade: WebSocket\r\nConnection: Upgrade\r\nSec-WebSocket-Origin: http://www.albertcheng.info\r\nSec-WebSocket-Location: ws://50.136.30.53:10002/\r\n\r\n";
         
              myServer.write(headerSend.getBytes());
              myServer.write(responseChallenge);
      //messageFromClient=messageFromClient+"\n\n"+headerSend+"\n"+newEnc; 
    }else
      {
          
       
        String decodedString;
       
       String JustGrapString=new String(bytesRead);
       int starter=JustGrapString.lastIndexOf("<");
       int ender=JustGrapString.lastIndexOf(">");
       //some hack here
       if(starter>=0 && ender>starter){ 
         
         decodedString=new String(bytesRead).substring(starter+1,ender);
        
       }else{
          byte[] decoded=decodeDataFrame(bytesRead);
         decodedString=new String(decoded);
         decodedString=decodedString.substring(1,decodedString.length()-1);
       }
       
       
        messageFromClient= messageFromClient+"\ndata decoded="+decodedString+"\n";
        
       String[] splits=decodedString.split(":");
       
       if(splits.length<2){
         System.err.println("splits lenght < 2:"+decodedString);
         return;
       }
       messageFromClient= messageFromClient+"\n"+splits[0];
messageFromClient= messageFromClient+"\n"+splits[1];//+"]";
      int pinNum;
       try{
        pinNum=Integer.parseInt(splits[0]);
       }catch(Exception e){
         pinNum=-1;
       }
       if(pinNum>=2 && pinNum<=12){
          messageFromClient= messageFromClient+"\npin Num accepted\n";
         if(splits[1].equals("hi")){
           arduino.digitalWrite(pinNum,Arduino.HIGH); 
           onTimes[pinNum]=updateCount;
         }else if(splits[1].equals("lo")){
           arduino.digitalWrite(pinNum,Arduino.LOW);
           onTimes[pinNum]=0;
         }
       }else{
          messageFromClient= messageFromClient+"\npin Num out of range\n"; 
       }
        
      }
      
     
    }
 
  } 
  

  
  
  for(int i=2;i<=12;i++){
     if(onTimeLimits[i]>0 && onTimes[i]>0 && updateCount-onTimes[i]>onTimeLimits[i]){
       //protect that motor by shutting off;
      
      onTimes[i]=0;
      arduino.digitalWrite(i,Arduino.LOW);
      System.err.println("turning off motor "+i+" to avoid overusing"); 
     }
  }
  
  text(messageFromClient,30,100);

}
