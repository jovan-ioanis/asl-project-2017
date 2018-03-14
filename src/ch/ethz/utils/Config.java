package ch.ethz.utils;

import java.util.logging.Level;

/**
 * Static fields of this class are FIXED hyperparameters of this system.
 * @author jovan
 *
 */
public class Config {
	
	public static final byte[]	end										=		"END\r\n".getBytes();
	public static final String	delimiter								=		",";
	
	/*
	 * max key size = 256 characters
	 * max flag = 2^16=65536 -> 5 characters
	 * max expiration time = 10000 -> 5 characters
	 * datablock size = fixed to 1024 -> 4 characters
	 * 
	 * largest multi-GET request is with 10 keys:
	 * 3(GET) + 10*(1(space) + 256(key)) + 2 (\r\n) = 2575
	 * 
	 * largest response is with all 10 keys:
	 * 10*( 5(VALUE) + 1(space) + 256(key) + 1(space) + 5(flag) + 1(space) + 4(1024) + 2(\r\n) + 1024(value) + 2(\r\n) ) = 
	 * 		13010
	 */
	
	public static final int		maxBufferSize_worker					=		13010; //27000; //;
	public static final int		maxBufferSize_netthread					=		2575;
	public static final int		maxNumKeys								=		10;
	
	public static final int		counterLoggingFreq						=		20;
	public static final int		logsDumpingFreq							=		20000; // maybe 50 000 is too big
	public static final int		queueSizeLoggingFreq					=		20;
	
	public static final String	baseLogDir								=		"logs/";
	
	public static final boolean	enableIncomingMessageCompletenessVerification	=	true;
	public static final boolean enableGETresponsesCompletenessVerification		=	true;
	
	public static final Level	debugLogsLevel							=		Level.SEVERE;	
	
	public static int			numThreadsPTP							=		-1;
}
