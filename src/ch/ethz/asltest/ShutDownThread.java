package ch.ethz.asltest;

import java.util.ArrayList;
import java.util.logging.Handler;
import java.util.logging.Level;

import ch.ethz.instrumentation.MyLogManager;
import ch.ethz.utils.Utils;

public class ShutDownThread extends Thread {
	
	private NetThread netThread					=	null;
	private ArrayList<Worker> workersPool		=	null;
	
	public ShutDownThread(NetThread netThread, ArrayList<Worker> workersPool) {
		this.netThread = netThread;
		this.workersPool = workersPool;
	}
	
	/**
	 * This method is called after ALL memtiers stop and internal request queue is empty.
	 * Internal request queue is empty for sure if memtier received all responses, and is closed!
	 * 
	 * At this time all worker threads are blocked on empty internal request queue.
	 */
	public void run() {
		System.out.println("Preparing to close..");
		MyMiddleware.debugLogger.log(Level.SEVERE, "@ShutDownthread: Preparing to close..");
		netThread.closeConnections();
//		System.out.println("1..");
		MyMiddleware.debugLogger.log(Level.SEVERE, "@ShutDownthread: NetThread closed all connections.");
		for(Worker worker : workersPool) {
			worker.closeConnections();
		}
//		System.out.println("2..");
		MyMiddleware.debugLogger.log(Level.SEVERE, "@ShutDownthread: All workers closed all connections.");
		for(Worker worker : workersPool) {
			worker.flushMeasurements();
		}
//		System.out.println("3..");
		MyMiddleware.debugLogger.log(Level.SEVERE, "@ShutDownthread: All workers pushed, flushed and closed all logs.");
		this.flushMeasurements();
//		System.out.println("4..");
		MyMiddleware.debugLogger.log(Level.SEVERE, "@ShutDownthread: Debuging logs pushed, flushed and closed.");
		MyLogManager.resetFinally();
//		System.out.println("5..");
		MyMiddleware.debugLogger.log(Level.SEVERE, "@ShutDownthread: Shutdown hook of Logger invoked.");
		System.out.println("Closed.");
	}
	
	public void flushMeasurements() {		
		Handler[] handlers = MyMiddleware.debugLogger.getHandlers();
		Utils.handleHandlers(handlers);				
	}

}
