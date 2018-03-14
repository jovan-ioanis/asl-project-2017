package ch.ethz.utils;

import java.util.StringTokenizer;
import java.util.logging.Handler;
import java.util.logging.Level;
import java.util.logging.MemoryHandler;

import ch.ethz.asltest.MyMiddleware;

/**
 * This class implements various static methods used by various classes.
 * @author jovan
 *
 */
public class Utils {
	
	public static void printByteArray(byte[] thearray) {
		StringBuilder sbb = new StringBuilder();
		for(int i = 0; i < thearray.length; i++) {
			if(thearray[i] != 0) {
				sbb.append(thearray[i]).append(" ");
			}			
		}
		System.out.println(">" + sbb.toString() + "<");
	}
	
	public static void printByteArrayAsString(byte[] thearray) {
		String str = new String(thearray);
		System.out.println(">" + str + "<");
	}
	
	public static void print(String msg) {
		System.out.println(msg);
	}
	
	public static String extractIPaddress(String address) {
		StringTokenizer st = new StringTokenizer(address, ":");
		if(st.hasMoreTokens()) {
			return st.nextToken();
		} else {
			MyMiddleware.debugLogger.log(Level.SEVERE, "@Utils: Cannot extract IP Address from input " + address);
			return null;
		}		
	}
	
	public static int extractPort(String address) {
		StringTokenizer st = new StringTokenizer(address, ":");
		if(st.hasMoreTokens()) {
			st.nextToken();
		} else {
			MyMiddleware.debugLogger.log(Level.SEVERE, "@Utils: Cannot extract port from input " + address);
			return -1;
		}
		if(st.hasMoreTokens()) {
			int port = -1;
			try {
				port = Integer.parseInt(st.nextToken());
			} catch (NumberFormatException e) {
				MyMiddleware.debugLogger.log(Level.SEVERE, "@Utils: Cannot extract port from input " + address);
			}
			return port;
		} else {
			MyMiddleware.debugLogger.log(Level.SEVERE, "@Utils: Cannot extract port from input " + address);
			return -1;
		}
	}
	
	public static String wrapInCLIENT_ERROR(String msg) {
		return "CLIENT_ERROR" + " " + msg + "\r\n";
	}
	
	public static String wrapInSERVER_ERROR(String msg) {
		return "SERVER_ERROR" + " " + msg + "\r\n";
	}
	
	public static String nonExistentCommandName() {
		return "ERROR\r\n";
	}
	
	public static String wrapSingleGETresponse(String key, char flag, int numBytes, String datablock) {
		return "VALUE" + " " + key + " " + flag + " " + numBytes + "\r\n" + datablock + "\r\n" + "END\r\n";
	}
	
	public static String wrapEmptyGETresponse() {
		return "END\r\n";
	}
	
	/**
	 * If message ends with "\r\n" and first 3 bytes correspond to "get" then we determine that GET request is fully received.
	 * 
	 * If message ends with "\r\n" and first 3 bytes correspond to "set" and there is at least 1 "\r\n" before "\r\n" at the end,
	 * then we determine that SET request is fully received.  Note that this may not be completely correct. Since datablock
	 * can contain bytes 13 and 10 which correspond to '\r' and '\n' respectively, in case where SET request is received up to the
	 * point in datablock ending with 13 and 10, here we falsely conclude that message is fully received, even though last "\r\n"
	 * detected may correspond to somewhere in the middle of datablock. However, the probability that incomplete message received
	 * ends in "\r\n" is very low.
	 * 
	 * Position is:
	 * 	-	in case of non-flipped ByteBuffer 	=> buffer.position()
	 * 	-	in case of flipped ByteBuffer		=> buffer.limit()
	 * and it points to one position after the last written byte
	 * @param array
	 * @param position
	 * @return
	 */
	public static Command verifyInputMessage(byte[] array, int position) {
		byte slash_r = (byte)'\r';
		byte slash_n = (byte)'\n';
		
		if(array[position-1] != slash_n || array[position-2] != slash_r) {
			return null;
		}
		
		String command_name = new String(array, 0, 3);
		command_name.trim();
		
		if("set".equals(command_name)) {
			String received = new String(array, 0, position);
			StringTokenizer st = new StringTokenizer(received, "\r\n");
			if(st.hasMoreTokens()) {
				st.nextToken();
				if(st.hasMoreTokens()) {
					return Command.SET;
				} else {
					return null;
				}
			} else {
				return null;
			}			
		} else if("get".equals(command_name)) {
			return Command.GET;
		} else {
			return Command.NONEXISTENT;
		}				
	}
	
	public static boolean thoroughSETrequestCheck(byte[] array, int position) {
		String received = new String(array, 0, position);
		
		StringTokenizer st1 = new StringTokenizer(received, "\r\n");
		if(!st1.hasMoreTokens()) {
			System.out.println("Cannot process following >" + received + "<");
			MyMiddleware.debugLogger.log(Level.SEVERE, "Cannot process following >" + received + "<");
			return false;
		}
		String firstLine = st1.nextToken();
		
		StringTokenizer st2 = new StringTokenizer(firstLine, " ");
		if(!st2.hasMoreTokens()) {
			System.out.println("Cannot process following >" + received + "<");
			MyMiddleware.debugLogger.log(Level.SEVERE, "Cannot process following >" + received + "<");
			return false;
		}
		String commandName = st2.nextToken();
		if(!"set".equals(commandName)) {
			System.out.println("Cannot process following >" + received + "<");
			MyMiddleware.debugLogger.log(Level.SEVERE, "Cannot process following >" + received + "<");
			return false;
		}
		if(!st2.hasMoreTokens()) {
			System.out.println("Cannot process following >" + received + "<");
			MyMiddleware.debugLogger.log(Level.SEVERE, "Cannot process following >" + received + "<");
			return false;
		}
		String key = st2.nextToken();
		if(!st2.hasMoreTokens()) {
			System.out.println("Cannot process following >" + received + "<");
			MyMiddleware.debugLogger.log(Level.SEVERE, "Cannot process following >" + received + "<");
			return false;
		}
		String flags = st2.nextToken();
		if(!st2.hasMoreTokens()) {
			System.out.println("Cannot process following >" + received + "<");
			MyMiddleware.debugLogger.log(Level.SEVERE, "Cannot process following >" + received + "<");
			return false;
		}
		String expTime = st2.nextToken();
		if(!st2.hasMoreTokens()) {
			System.out.println("Cannot process following >" + received + "<");
			MyMiddleware.debugLogger.log(Level.SEVERE, "Cannot process following >" + received + "<");
			return false;
		}
		String dataBlockSizeStr = st2.nextToken();
		Integer dataBlockSize = null;
		try {
			dataBlockSize = Integer.parseInt(dataBlockSizeStr);
		} catch (NumberFormatException e) {
			System.out.println("Cannot process following >" + received + "<");
			MyMiddleware.debugLogger.log(Level.SEVERE, "Cannot process following >" + received + "<");
			return false;
		}
													//		 "spaces"  "\r\n"
		int firstLineLength = 	commandName.length()		+	1	+
								key.length()				+	1	+
								flags.length()				+	1	+
								expTime.length()			+	1	+
								dataBlockSizeStr.length()			+	2;
		
		if(position == firstLineLength + dataBlockSize + 2) {
			return true;
		} else {
			System.out.println("Cannot process following >" + received + "<");
			MyMiddleware.debugLogger.log(Level.SEVERE, "Cannot process following >" + received + "<");
			return false;
		}		
	}
	
	/**
	 * position points to one slot after the last written byte in the array.
	 * Position also indicates the number of bytes written to array.
	 * @param buffer
	 * @return
	 */
	public static int verifyGETresponse(byte[] array, int position) {
		if(position < 5) {
			return -1;
		}
		String endstr = new String(array, position-5, position);
//		System.out.println("1. : " + ">" + endstr + "<");
		if(!compare(array, position-5, position, Config.end, 0, Config.end.length)) {
			return -1;
		}
		
//		System.out.println("2. : " + ">" + endstr + "<");
		if("END\r\n".equals(endstr) && position == 5) {
			return 0;
		}
//		System.out.println("3. : " + ">" + endstr + "<");
		int begin = 0;
		int end = position;
		int numKeys = 0;
		while(true) {
			String everything = new String(array, begin, end-begin);
//			System.out.println("4. : " + ">" + everything + "<");
			StringTokenizer st = new StringTokenizer(everything, "\r\n");
			if(!st.hasMoreTokens()) {
				return -1;
			}
			String firstLine = st.nextToken();
//			System.out.println("5. : " + ">" + firstLine + "<");
			if("END".equals(firstLine)) {
				return numKeys;
			}
			StringTokenizer stz = new StringTokenizer(firstLine, " ");
			if(!stz.hasMoreTokens()) {
				return -1;
			}
			String value = stz.nextToken();
//			System.out.println("6. : " + ">" + value + "<");
			if(!stz.hasMoreTokens()) {
				return -1;
			}
			String key = stz.nextToken();
//			System.out.println("7. : " + ">" + key + "<");
			if(!stz.hasMoreTokens()) {
				return -1;
			}
			String flags = stz.nextToken();
//			System.out.println("8. : " + ">" + flags + "<");
			if(!stz.hasMoreTokens()) {
				return -1;
			}
			String datablockSizeStr = stz.nextToken();
//			System.out.println("9. : " + ">" + datablockSizeStr + "<");
			Integer datablockSize;
			try {
				datablockSize = Integer.parseInt(datablockSizeStr);
			} catch(NumberFormatException e) {
				return -1;
			}
//			System.out.println("10. : " + ">" + datablockSize + "<");
//			 												    "spaces"  "\r\n"
			int firstLineLength = 	value.length()				+	1	+
									key.length()				+	1	+
									flags.length()				+	1	+
									datablockSizeStr.length()			+	2;
			int firstResponseLength = firstLineLength + datablockSize 	+ 	2;
//			System.out.println("11. : " + ">" + firstResponseLength + "<");
			if(begin + firstResponseLength < end) {
				numKeys++;
				begin += firstResponseLength;
//				System.out.println("11. : " + ">" + numKeys + "< and >" + begin + "<");
			} else {
				return -1;
			}
//			System.out.println("iteration finished.");
		}
		
	}
	
	
	public static int verifyGETresponse2(byte[] array, int position) {
		
		if(position < 5) {
			return -1;
		}
		String endstr = new String(array, position-5, 5);
//		System.out.println("1. : " + ">" + endstr + "<");
		if(!compare(array, position-5, position, Config.end, 0, Config.end.length)) {
			return -1;
		}
		
//		System.out.println("2. : " + ">" + endstr + "<");
		if("END\r\n".equals(endstr) && position == 5) {
			return 0;
		}
//		System.out.println("3. : " + ">" + endstr + "<");
		int begin = 0;
		int end = position;
		int numKeys = 0;
		while(true) {
			String everything = new String(array, begin, end-begin);
//			System.out.println("4. : " + ">" + everything + "<");
			StringTokenizer st = new StringTokenizer(everything, "\r\n");
			if(!st.hasMoreTokens()) {
//				System.out.println("Cannot parse: >" + everything + "<");
				MyMiddleware.debugLogger.log(Level.SEVERE, "Cannot parse: >" + everything + "<");
				return -1;
			}
			String firstLine = st.nextToken();
//			System.out.println("5. : " + ">" + firstLine + "<");
			if("END".equals(firstLine)) {
				return numKeys;
			}
			StringTokenizer stz = new StringTokenizer(firstLine, " ");
			if(!stz.hasMoreTokens()) {
//				System.out.println("Cannot parse: >" + everything + "<");
				MyMiddleware.debugLogger.log(Level.SEVERE, "Cannot parse: >" + everything + "<");
				return -1;
			}
			String value = stz.nextToken();
//			System.out.println("6. : " + ">" + value + "<");
			if(!stz.hasMoreTokens()) {
//				System.out.println("Cannot parse: >" + everything + "<");
				MyMiddleware.debugLogger.log(Level.SEVERE, "Cannot parse: >" + everything + "<");
				return -1;
			}
			String key = stz.nextToken();
//			System.out.println("7. : " + ">" + key + "<");
			if(!stz.hasMoreTokens()) {
//				System.out.println("Cannot parse: >" + everything + "<");
				MyMiddleware.debugLogger.log(Level.SEVERE, "Cannot parse: >" + everything + "<");
				return -1;
			}
			String flags = stz.nextToken();
//			System.out.println("8. : " + ">" + flags + "<");
			if(!stz.hasMoreTokens()) {
//				System.out.println("Cannot parse: >" + everything + "<");
				MyMiddleware.debugLogger.log(Level.SEVERE, "Cannot parse: >" + everything + "<");
				return -1;
			}
			String datablockSizeStr = stz.nextToken();
//			System.out.println("9. : " + ">" + datablockSizeStr + "<");
			Integer datablockSize;
			try {
				datablockSize = Integer.parseInt(datablockSizeStr);
			} catch(NumberFormatException e) {
//				System.out.println("Cannot parse: >" + everything + "<");
				MyMiddleware.debugLogger.log(Level.SEVERE, "Cannot parse: >" + everything + "<");
				return -1;
			}
//			System.out.println("10. : " + ">" + datablockSize + "<");
//			 												    "spaces"  "\r\n"
			int firstLineLength = 	value.length()				+	1	+
									key.length()				+	1	+
									flags.length()				+	1	+
									datablockSizeStr.length()			+	2;
			int firstResponseLength = firstLineLength + datablockSize 	+ 	2;
//			System.out.println("11. : " + ">" + firstResponseLength + "<");
			if(begin + firstResponseLength < end) {
				numKeys++;
				begin += firstResponseLength;
//				System.out.println("11. : " + ">" + numKeys + "< and >" + begin + "<");
			} else {
//				System.out.println("Cannot parse: >" + everything + "<");
				MyMiddleware.debugLogger.log(Level.SEVERE, "Cannot parse: >" + everything + "<");
				return -1;
			}
//			System.out.println("iteration finished.");
		}
		
	}
	
	public static boolean compare(byte[] array1, int offset1, int limit1, byte[] array2, int offset2, int limit2) {
		if(limit1-offset1 != limit2-offset2) {
			return false;
		}
		int dif = limit1-offset1;
		for(int i = 0; i < dif; i++) {
			if(array1[offset1 + i] != array2[offset2 + i]) {
				return false;
			}
		}
		return true;
	}
	
	public static void handleHandlers(Handler[] handlers) {		
		for(Handler h : handlers) {
			if(h instanceof MemoryHandler) {
//				System.out.println("\t\t\tmmmmmmmmmmmmmmmmmmmmmm");
				MemoryHandler mh = (MemoryHandler) h;
				mh.push();
				mh.flush();
				mh.close();
			} else {
//				System.out.println("\t\t\tffffffffffffffffff");
				h.flush();
				h.close();
			}			
		}
	}

}






























//String received = new String(array, 0, position);
////System.out.println("1. : " + ">" + received + "<");
//StringTokenizer st = new StringTokenizer(received, "\r\n");
//if(!st.hasMoreTokens()) {
//	return null;
//}
//String firstline = st.nextToken();
////System.out.println("2. : " + ">" + firstline + "<");
//StringTokenizer stz = new StringTokenizer(firstline, " ");
//if(!stz.hasMoreTokens()) {
//	return null;
//}
//String command = stz.nextToken();
////System.out.println("3. : " + ">" + command + "<");
//if("set".equals(command)) {
//	if(!stz.hasMoreTokens()) {
//		return null;
//	}
//	String key = stz.nextToken();
////	System.out.println("4. : " + ">" + key + "<");
//	if(!stz.hasMoreTokens()) {
//		return null;
//	}
//	String flags = stz.nextToken();
////	System.out.println("5. : " + ">" + flags + "<");
//	if(!stz.hasMoreTokens()) {
//		return null;
//	}
//	String expirationTime = stz.nextToken();
////	System.out.println("6. : " + ">" + expirationTime + "<");
//	if(!stz.hasMoreTokens()) {
//		return null;
//	}
//	String datablockSizeStr = stz.nextToken();
////	System.out.println("7. : " + ">" + datablockSizeStr + "<");
//	Integer datablockSize;
//	try {
//		datablockSize = Integer.parseInt(datablockSizeStr);
//	} catch(NumberFormatException e) {
//		return null;
//	}
////	System.out.println("8. : " + ">" + datablockSize + "<");
////														 "spaces"  "\r\n"
//	int firstLineLength = 	command.length()			+	1	+
//							key.length()				+	1	+
//							flags.length()				+	1	+
//							expirationTime.length()		+	1	+
//							datablockSizeStr.length()			+	2;
////	System.out.println("9. : " + ">" + firstLineLength + "<");
////	System.out.println("10. : position = " + position + " and firstLineLength is = " + firstLineLength);
//	if(position == firstLineLength + datablockSize + 2) {
//		return Command.SET;
//	} else {
//		return null;
//	}		
//} else if("get".equals(command)) {
//	return Command.GET;
//} else {
//	return null;
//}
