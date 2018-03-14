package ch.ethz.asltest;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.logging.FileHandler;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.logging.MemoryHandler;
import java.util.logging.SimpleFormatter;

import ch.ethz.instrumentation.MeasurementFormatter;
import ch.ethz.instrumentation.MyLogManager;
import ch.ethz.utils.Config;
import ch.ethz.utils.IPAddress;

/**
 * This class starts off Net-Thread and Worker Threads.
 * @author jovan
 *
 */
public class MyMiddleware {
	
	static {
        // must be called before any Logger method is used.
        System.setProperty("java.util.logging.manager", MyLogManager.class.getName());
    }
	
	public static final Logger				debugLogger			=	Logger.getLogger("ch.ethz.asltest.debugLogger");
	
	private	String							myIp 				= 	null;
	private	int								myPort 				= 	0;
	private	List<IPAddress>					mcAddresses 		= 	null;
	private	int 							numThreadsPTP		= 	-1;
	private boolean 						readSharded 		= 	false;	
	private LinkedBlockingQueue<Request> 	queue				=	null;
	
	private NetThread						netThread			=	null;
	private ArrayList<Worker>				workersPool			= 	null;	
	
	public MyMiddleware(String myIp, int myPort, List<String> mcAddresses, int numThreadsPTP, boolean readSharded) {
		new MyLogManager();
		this.make_dirs();
		this.myIp = myIp;
		this.myPort = myPort;
		this.mcAddresses = this.getMemCachedAddresses(mcAddresses);
		this.numThreadsPTP = numThreadsPTP;
		Config.numThreadsPTP = numThreadsPTP;
		this.readSharded = readSharded;
		this.queue = new LinkedBlockingQueue<Request>();
		this.workersPool = new ArrayList<Worker>();
	}
	
	private void make_dirs() {
		File dir = new File(Config.baseLogDir);
		dir.mkdirs();
	}
	
	private void initLogging() {		
		try {
			FileHandler fh = new FileHandler(Config.baseLogDir + "debug.log");
			fh.setLevel(Config.debugLogsLevel);
			fh.setFormatter(new SimpleFormatter());
			
			MemoryHandler mh = new MemoryHandler(fh, Config.logsDumpingFreq, Level.SEVERE);		
			mh.setFormatter(new SimpleFormatter());
			mh.setLevel(Config.debugLogsLevel);
			
			MyMiddleware.debugLogger.addHandler(mh);
			MyMiddleware.debugLogger.setLevel(Config.debugLogsLevel);
			
		} catch (SecurityException | IOException e) {
			e.printStackTrace();
		}
	}
		
	private void initWorkers() {
		for(int i = 0; i < this.numThreadsPTP; i++) {
			Worker worker = new Worker(this.queue, this.mcAddresses, this.readSharded);
			this.workersPool.add(worker);
		}
		MyMiddleware.debugLogger.log(Level.SEVERE, "@MyMiddleware: All workers are created.");
	}
	
	private void startWorkers() {
		for(int i = 0; i < this.numThreadsPTP; i++) {
			this.workersPool.get(i).start();
		}
		MyMiddleware.debugLogger.log(Level.SEVERE, "@MyMiddleware: All workers are started.");
	}
	
	private void startNetThread() {
		this.netThread.start();
		MyMiddleware.debugLogger.log(Level.SEVERE, "@MyMiddleware: NetThread is started.");
	}
	
	private void initNetThread() {
		this.netThread = new NetThread(this.myIp, this.myPort, this.queue);		
		MyMiddleware.debugLogger.log(Level.SEVERE, "@MyMiddleware: NetThread is created.");
	}
	
	private ArrayList<IPAddress> getMemCachedAddresses(List<String> mcAddresses) {
		ArrayList<IPAddress> thelist = new ArrayList<IPAddress>();
		for(String adr : mcAddresses) {
			thelist.add(new IPAddress(adr));
		}
		return thelist;
	}
	
	
	public void run() {
		this.initWorkers();
		this.initNetThread();
		this.initLogging();
		this.startWorkers();
		this.startNetThread();
		
		/**
		 * If OS sends SIGKILL, then ShutDownHook won't execute.
		 * If SIGTERM is issued by OS (normal kill command, without -9), then ShutDownHook will execute
		 */
		
		Runtime.getRuntime().addShutdownHook(new ShutDownThread(this.netThread, this.workersPool));
		MyMiddleware.debugLogger.log(Level.SEVERE, "@MyMiddleware: ShutDownThread is added as ShutDown hook.");
	}
	
	
	

}
