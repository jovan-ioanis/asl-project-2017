package ch.ethz.instrumentation;

import java.util.logging.LogManager;

/**
 * LogManager has it's own shutdown hook, and Java executes all shutdown threads in arbitrary order.
 * Consequently, logs may not be flushed in my shutdown hook.
 * 
 * This custom LogManager fixes this issue. Shutdown hook of LogManager will be invoked from
 * my custom ShutDown hook.
 * 
 * idea from: https://stackoverflow.com/questions/13825403/java-how-to-get-logger-to-work-in-shutdown-hook
 * @author jovan
 *
 */
public class MyLogManager extends LogManager {
	
	static MyLogManager instance;
	
	public MyLogManager() {
		instance = this;
	}
	
	@Override
	public void reset() { }
	
	private void reset0() {
		super.reset();
	}
	
	public static void resetFinally() {
		instance.reset0();
	}
	

}
