package ch.ethz.instrumentation;

import ch.ethz.utils.Command;

/**
 * Measurement class storing all measurement logs for single request.
 * @author jovan
 *
 */
public class Measurements {
	
	private long	requestReceivedTime				=	0;		// time at which complete request was received from memtier client
	private long	putInQueueTime					=	0;		// reads from SocketChannel, 
																// ByteBuffer and pointer to SocketChannel stored in Request object,
																// and object is stored in queue
	private long	takenOutOfQueueTime				=	0;		// Request object is removed from the queue by Worker thread
	private long	sentToServerTime				=	0;		// after processing request, and after sending data to server method returns
																// includes sending as well. For multi-get it is after splitting and after 
																// sending each individual request.
	private long	receivedCompleteResponseTime	=	0;		// after receiving complete response. For multi-get it means just reading 
																// from all servers, but not assembling. For single get, complete response
																// is already assembled. For set response, it means reading responses from 
																// all three servers.
	private long	responseSentToClientTime		=	0;		// the moment just after sending, including sending time.
	
	private Command	command							=	null;	// SET or GET
	private int		numKeys							=	0;		// 1 and only 1 for SET
																// [1,10] for GET
	private int 	handledByWorkerID				=	-1;		// worker ID
	
	// if command is null, it means it couldn't be parsed!
	
	public void setRequestReceivedTime(long time) {
		this.requestReceivedTime = time;
	}
	
	public long getRequestReceivedTime() {
		return this.requestReceivedTime;
	}
	
	public void setPutInQueueTime(long time) {
		this.putInQueueTime = time;
	}
	
	public long getPutInQueueTime() {
		return this.putInQueueTime;
	}
	
	public void setTakenOutOfQueueTime(long time) {
		this.takenOutOfQueueTime = time;
	}
	
	public long getTakenOutOfQueueTime() {
		return this.takenOutOfQueueTime;
	}
	
	public void setSentToServerTime(long time) {
		this.sentToServerTime = time;
	}
	
	public long getSentToServerTime() {
		return this.sentToServerTime;
	}
	
	public void setReceivedCompleteResponseTime(long time) {
		this.receivedCompleteResponseTime = time;
	}
	
	public long getReceivedCompleteResponseTime() {
		return this.receivedCompleteResponseTime;
	}
	
	public void setResponseSentToClientTime(long time) {
		this.responseSentToClientTime = time;
	}
	
	public long getResponseSentToClientTime() {
		return this.responseSentToClientTime;
	}
	
	public void setCommand(Command command) {
		this.command = command;
	}
	
	public Command getCommand() {
		return this.command;
	}
	
	public void setNumKeys(int keys) {
		this.numKeys = keys;
	}
	
	public int getNumKeys() {
		return this.numKeys;
	}
	
	public void setHandledByWorkerID(int id) {
		this.handledByWorkerID = id;
	}
	
	public int getHandledByWorkerID() {
		return this.handledByWorkerID;
	}

}
