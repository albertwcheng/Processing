import processing.net.*;
import java.io.UnsupportedEncodingException; 
import java.security.MessageDigest; 
import java.security.NoSuchAlgorithmException; 
import sun.misc.BASE64Encoder;

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

void setup()
{
  size(1000, 1000);
  myServer = new Server(this, port);
  messageFromClient = new String("");

  background(150);
  

}



 
void draw()
{
  updateCount++;
  // Get the next available client
  background(150);
   text("updating "+updateCount,30,30);
  Client thisClient = myServer.available();
  // If the client is not null, and says something, display what it said
  if (thisClient !=null) {
    String whatClientSaid = thisClient.readString();
    
    if(whatClientSaid!=null){
       messageFromClient=thisClient.ip() + ":\n" +whatClientSaid;
       int clientKeyPos=whatClientSaid.indexOf("Sec-WebSocket-Key:");
       int protocolPos=whatClientSaid.indexOf("Sec-WebSocket-Protocol:");
       
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
      }
      
      if(protocolPos>-1){
         int protocolEnd=whatClientSaid.indexOf("\n",protocolPos);
         String protocolString=whatClientSaid.substring(protocolPos+23,protocolEnd).trim();
          messageFromClient= messageFromClient+"\n"+protocolString+"\n";
      }
    }
 
  } 
  

  text(messageFromClient,30,100);

}
