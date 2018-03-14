package ch.ethz.asltest;

import java.nio.channels.SocketChannel;

import ch.ethz.instrumentation.Measurements;
import ch.ethz.utils.BufferStruct;
import ch.ethz.utils.Command;


/**
 * This class wraps received request. NetThread creates instances of this object, and they are stored
 * in internal request queue.
 * @author jovan
 *
 */
public class Request {
	
	private	SocketChannel	client						=	null;
	private BufferStruct	buffer						=	null;
	
	public Measurements		measurements				=	null;
	public boolean			shouldDump					=	false;
	
	public Request(SocketChannel client, BufferStruct buffer) {
		this.client = client;
		this.buffer = buffer;
		this.measurements = new Measurements();
	}
	
	public SocketChannel getClient() {
		return this.client;
	}
	
	public BufferStruct getBuffer() {
		return this.buffer;
	}
	
	public void setCommand(Command command) {
		this.measurements.setCommand(command);
	}
	
	public Command getCommand() {
		return this.measurements.getCommand();
	}	

}
