package ch.ethz.asltest;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SocketChannel;
import java.util.ArrayList;
import java.util.List;
import java.util.StringTokenizer;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.logging.FileHandler;
import java.util.logging.Handler;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.logging.MemoryHandler;

import ch.ethz.instrumentation.MeasurementFormatter;
import ch.ethz.instrumentation.Measurements;
import ch.ethz.utils.BufferStruct;
import ch.ethz.utils.Command;
import ch.ethz.utils.Config;
import ch.ethz.utils.IPAddress;
import ch.ethz.utils.Utils;


public class Worker extends Thread {
	
	private static int 						globalID		=	0;
	private int								id				= 	globalID++;
	
	private LinkedBlockingQueue<Request>	queue			=	null;
	private List<IPAddress>					mcAddresses		=	null;
	private boolean							readSharded		=	false;
	private ArrayList<SocketChannel>		servers			=	null;
	private int								counter			=	0;						// support for even load distribution amongst servers
	private int[]							currentServerOrder;
	private ByteBuffer						buffer			=	null;
	private boolean							active			=	false;
	
	private int								logCounter		=	0;
	
	//------------------------------------------------------------------------
	//	INSTRUMENTATION SUPPORT
	//------------------------------------------------------------------------
	private int				currentQueueSize		=	-1;
	private long			num_SET					=	0;								// number of SET requests received
	private long[]			num_GET_n				=	new long[Config.maxNumKeys];	// number of each of multi-GET requests received
																						// every SET request is sent everywhere
	private long[]			serversLoad_GET			=	null;							// number of GET messages each server receives
																						// different meaning if shardedReading is ON or OFF
	private long[]			serversLoad_GET_reads	=	null;							// number of readings done by each server
	
	private long			errorsCount_SET			=	0; 								// number of times something other than "STORED\r\n" was response to client as reply to client's SET request.
																						// at least one server need to return something other than "STORED\r\n" for this counter to be incremented by exactly 1!
	private long			errorsCount_GET			=	0;								// cache-miss ratio. Number of times not all GET responses were answered. If K keys were received, but N (N < K) responses
																						// were received, then this counter is incremented by N-K.
	private long			unverifiedCommands		=	0;
	private int				counterLoggingFreq_cnt	=	0;
	
	public final Logger		counterLogger			=	Logger.getLogger("ch.ethz.asltest.counterLogger" + id);
	public final Logger		timerLogger				=	Logger.getLogger("ch.ethz.asltest.timerLogger" + id);	
	
	//------------------------------------------------------------------------
	
	public Worker(LinkedBlockingQueue<Request> queue, List<IPAddress> mcAddresses, boolean readSharded) {
		this.queue = queue;
		this.mcAddresses = mcAddresses;
		this.readSharded = readSharded;
		this.initLogging();
		this.initBuffer();
		this.initCounters();
		this.currentServerOrder = new int[mcAddresses.size()];
		this.openConnections();
	}
	
	private void initBuffer() {
		this.buffer = ByteBuffer.allocate(Config.maxBufferSize_worker);
	}
	
	private void initLogging() {
		try {
			FileHandler fh = new FileHandler(Config.baseLogDir + "counters_" + id + ".log");
			fh.setLevel(Level.ALL);
			fh.setFormatter(new MeasurementFormatter());
			
			MemoryHandler mh = new MemoryHandler(fh, Config.logsDumpingFreq, Level.SEVERE);
			mh.setFormatter(new MeasurementFormatter());
			mh.setLevel(Level.ALL);
			this.counterLogger.addHandler(mh);
			this.counterLogger.setLevel(Level.ALL);
			this.counterLogger.setUseParentHandlers(false);
			this.counterLogger.fine(Worker.headerCounters(mcAddresses.size()));
			
		} catch (SecurityException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
		
		try {
			FileHandler fh = new FileHandler(Config.baseLogDir + "timers_" + id + ".log");
			fh.setLevel(Level.ALL);
			fh.setFormatter(new MeasurementFormatter());
			
			MemoryHandler mh = new MemoryHandler(fh, Config.logsDumpingFreq, Level.SEVERE);		
			mh.setFormatter(new MeasurementFormatter());
			mh.setLevel(Level.ALL);
			this.timerLogger.addHandler(mh);
			this.timerLogger.setLevel(Level.ALL);
			this.timerLogger.setUseParentHandlers(false);
			this.timerLogger.fine(Worker.headerTimings());
			this.incrementLogCounter();
			
		} catch (SecurityException | IOException e) {
			e.printStackTrace();
		}
	}
	
	private int strategy() {
		int current = counter++;
		if(counter >= this.servers.size()) {
			counter = 0;
		}
		return current;
	}
	
	private void initCounters() {
		for(int i = 0; i < Config.maxNumKeys; i++) {
			this.num_GET_n[i] = 0;
		}
		this.serversLoad_GET = new long[mcAddresses.size()];
		this.serversLoad_GET_reads = new long[mcAddresses.size()];
		for(int i = 0; i < mcAddresses.size(); i++) {
			this.serversLoad_GET[i] = 0;
			this.serversLoad_GET_reads[i] = 0;
		}
	}
	
	private Request getNewRequest() {
		try {
			Request req = this.queue.take();
			req.measurements.setTakenOutOfQueueTime(System.nanoTime());
			req.measurements.setHandledByWorkerID(this.id);
			this.currentQueueSize = this.queue.size();
			return req;
		} catch (InterruptedException e) {
			MyMiddleware.debugLogger.log(Level.SEVERE, "@Worker " + id + " was interrupted.", e);
		}
		return null;
	}
	
	//------------------------------------------------
	//	HANDLING CONNECTIONS
	//------------------------------------------------
	
	private void openConnections() {
		this.servers = new ArrayList<SocketChannel>();
		for(int i = 0; i < this.mcAddresses.size(); i++) {
			this.openConnection(i);
		}
		this.active = true;
	}
	
	private void openConnection(int i) {		
		try {
			SocketChannel server = SocketChannel.open();
			server.connect(new InetSocketAddress(mcAddresses.get(i).getIPaddress(), mcAddresses.get(i).getPort()));
			server.configureBlocking(true);
			this.servers.add(server);
			MyMiddleware.debugLogger.log(Level.SEVERE, "@Worker " + id + ": Opened connection with server " + server.getRemoteAddress());
		} catch (IOException e) {
			MyMiddleware.debugLogger.log(Level.SEVERE, "@Worker " + id, e);
		}
	}
	
	public void closeConnections() {
		for(SocketChannel socket : this.servers) {
			this.closeConnection(socket);
		}
		this.active = false;
		MyMiddleware.debugLogger.log(Level.FINEST, "@Worker " + id + ": Closed connection with all servers.");
	}
	
	private void closeConnection(SocketChannel server) {
		try {
			server.close();
		} catch (IOException e) {
			MyMiddleware.debugLogger.log(Level.SEVERE, "@Worker " + id, e);
		}
	}
	
	//------------------------------------------------
	//	MAIN LOOP
	//------------------------------------------------

	@Override
	public void run() {
		while(active) {
			Request req = this.getNewRequest();
			if(req == null) continue;	
			
			/**
			 * From this point on, BufferStruct contains flipped ByteBuffer content. 
			 * Meaning: position = 0, limit = number of bytes read, capacity normal
			 */
				
			this.counterLoggingFreq_cnt++;
			
			Command command;		
			if(Config.enableIncomingMessageCompletenessVerification && req.getCommand() != null) {
				command = req.getCommand();
			} else {
				command = this.getCommand(req);
			}
			
			switch (command) {
			case SET:
				this.processSETrequest(req);
				break;
			case GET:
				this.processGETrequest(req);
				break;
			default:
				this.unverifiedCommands++;
				MyMiddleware.debugLogger.log(Level.SEVERE, "@Worker " + id + ": Received request couldn't be parsed. Unknown command.");
				this.buffer.put(Utils.nonExistentCommandName().getBytes());
				this.buffer.flip();
				this.sendDataToClient(req.getClient());
				break;
			}
						
			this.logTimings(req.measurements);
			this.logCounters(req.measurements.getResponseSentToClientTime());
			
			// At the end of using buffer, we need to clear it. Buffer is exclusively used by one instance of thread.
			this.buffer.clear();
			this.currentQueueSize = -1;
		}		
	}
	
	private Command getCommand(Request req) {
		if(req.getCommand() == null && req.getBuffer().getArray() == null) {
			return Command.NONEXISTENT;
		}
		String commandline = new String(req.getBuffer().getArray(), 0, req.getBuffer().getLimit());
		StringTokenizer st = new StringTokenizer(commandline, " ");
		String command = null;
		if(st.hasMoreTokens()) {
			command = st.nextToken();
		} else {
			MyMiddleware.debugLogger.log(Level.SEVERE, "@Worker " + id + ": Command doesn't contain space: >" + commandline + "<");
			return Command.NONEXISTENT;
		}
		switch(command) {
		case "set":
			return Command.SET;
		case "get":
			return Command.GET;
		default:
			return Command.NONEXISTENT;
		}
	}
	
	private void processSETrequest(Request req) {
		if(!Utils.thoroughSETrequestCheck(req.getBuffer().getArray(), req.getBuffer().getLimit())) {
			MyMiddleware.debugLogger.log(Level.SEVERE, "@Worker " + id + ": Received SET request couldn't be parsed. Unknown command.");
			Handler[] handlers = MyMiddleware.debugLogger.getHandlers();
			for(Handler h : handlers) {
				if(h instanceof MemoryHandler) {
					MemoryHandler mh = (MemoryHandler) h;
					mh.push();
					mh.flush();
				} else {
					h.flush();
				}			
			}
			this.buffer.put(Utils.nonExistentCommandName().getBytes());
			this.buffer.flip();
			this.sendDataToClient(req.getClient());
			this.unverifiedCommands++;
			return;
		}
		this.num_SET++;
		
		this.buffer.put(req.getBuffer().getArray());
		this.buffer.flip();
		// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		// Server service time is time between first request sent and last response received
		req.measurements.setSentToServerTime(System.nanoTime());
		this.sendDataToServers();				
		this.readResponses(req);	
//		req.measurements.setReceivedCompleteResponseTime(System.nanoTime());
		this.sendDataToClient(req.getClient());
		req.measurements.setResponseSentToClientTime(System.nanoTime());
	}
	
	private void processGETrequest(Request req) {
		ArrayList<String> keys = this.getGETkeys(req);
		req.measurements.setNumKeys(keys.size());
		if(keys.size() > 0) {
			this.num_GET_n[keys.size()-1]++;
		}
		switch (keys.size()) {
		case 1:
			this.processSingleGET(req, keys);
			break;
		case 0:
			MyMiddleware.debugLogger.log(Level.SEVERE, "@Worker " + id + ": GET request - No keys found.");
			this.buffer.put(Utils.nonExistentCommandName().getBytes());
			this.buffer.flip();
			this.unverifiedCommands++;
			this.sendDataToClient(req.getClient());
			break;
		default:
			MyMiddleware.debugLogger.log(Level.FINEST, "@Worker " + id + ": GET request - keys found = " + keys.size());
			this.processMultiGET(req, keys);
			break;
		}
	}
	
	//----------------------------------------------
	//	GET COMMAND SUPPORT
	//----------------------------------------------
	
	/**
	 * This method assumes that content of BufferStruct corresponds to already flipped ByteBuffer.
	 * Moreover, it expects that buffer of the thread is already cleared.
	 * 
	 * It sends full GET request to the server of choice, waits for response, 
	 * verifies that full response was received and sends data back to the client.
	 * @param req
	 * @param keys
	 */
	private void processSingleGET(Request req, ArrayList<String> keys) {
		int chosenServer = this.strategy();	
		
		this.serversLoad_GET[chosenServer]++;
		this.serversLoad_GET_reads[chosenServer] += keys.size();
		
		this.buffer.put(req.getBuffer().getArray());
		this.buffer.flip();
		// server service time includes sending time as well
		req.measurements.setSentToServerTime(System.nanoTime());
		this.sendDataToServer(chosenServer, buffer);
		this.readGETResponseFromOneServer(chosenServer);
		req.measurements.setReceivedCompleteResponseTime(System.nanoTime());
		this.sendDataToClient(req.getClient());
		req.measurements.setResponseSentToClientTime(System.nanoTime());
	}
	
	private void processMultiGET(Request req, ArrayList<String> keys) {
		if(this.readSharded) {
			if(mcAddresses.size() == 1) {
				this.processSingleGET(req, keys);
			} else {
				this.processMultiGETsharded(req, keys);	
			}					
		} else {
			this.processSingleGET(req, keys);
		}		
	}
	
	private void processMultiGETsharded(Request req, ArrayList<String> keys) {
		int[] numKeysPerServer = this.shredMultiGET2(req, keys);
		ArrayList<BufferStruct> responses = this.collectResponses2(req);
		this.assembleResponses3(responses);
		MyMiddleware.debugLogger.log(Level.FINEST, "@Worker " + id + ": GET request - sending response.");
		this.sendDataToClient(req.getClient());
		MyMiddleware.debugLogger.log(Level.FINEST, "@Worker " + id + ": GET request - response sent.");
		req.measurements.setResponseSentToClientTime(System.nanoTime());
	}
	
	/**
	 * This method requires that worker's buffer is cleared!
	 * Moreover, worker's buffer is cleared at the end of this method.
	 * @param req
	 * @param keys
	 * @return
	 */
	
	private int[] shredMultiGET2(Request req, ArrayList<String> keys) {
		MyMiddleware.debugLogger.log(Level.FINEST, "@Worker " + id + ": GET request - sharding request.");
		
//		System.out.println("Original request: >" + new String(req.getBuffer().getArray(), 0, req.getBuffer().getLimit()) + "<");
		
		int numServers = this.servers.size();
		int numKeys = keys.size();
		int step = numKeys / numServers;
		int overflow = numKeys % numServers;
		
//		System.out.println("Servers = " + numServers + ", Keys = " + numKeys + ", step = " + step + ", overflow = " + overflow);
		
		for(int i = 0; i < numServers; i++) {
			this.currentServerOrder[i] = this.strategy();
		}
		
		int[] numKeysPerServer = new int[numServers];
		for(int i = 0; i < numKeysPerServer.length; i++) {
			numKeysPerServer[i] = step;
		}
		int position = 0;
		while(overflow > 0) {
			numKeysPerServer[position] += 1;
			overflow--;
			position += 1;
			if(position >= numKeysPerServer.length) {
				position = 0;
			}
		}
		
		for(int i = 0; i < numKeysPerServer.length; i++) {
//			System.out.println("Server " + currentServerOrder[i] + ": keys = " + numKeysPerServer[i]);
		}
		
		position = 4;
		byte white_space = (byte)' ';
		byte slash_r = (byte)'\r';
		byte slash_n = (byte)'\n';
		
		for(int i = 0; i < currentServerOrder.length; i++) {
			this.buffer.clear();
			byte[] originalrequest = req.getBuffer().getArray();
			// adding "get" and space in the beginning of request
			this.buffer.put(originalrequest[0]); this.buffer.put(originalrequest[1]); this.buffer.put(originalrequest[2]); this.buffer.put(originalrequest[3]);
			int keysWritten = 0;
			while(keysWritten < numKeysPerServer[i]) {
				while(originalrequest[position] != white_space && originalrequest[position] != slash_r) {
					this.buffer.put(originalrequest[position]);
					position++;
				}
				keysWritten++; // if not last key for this server add space
				if(keysWritten < numKeysPerServer[i] && originalrequest[position] != slash_r) {
					this.buffer.put(originalrequest[position]);
					position++;
				}
			}
			if(originalrequest[position] == white_space) {
				position++;
			}			
			this.buffer.put(slash_r);	// \r
			this.buffer.put(slash_n);   // \n
			
//			System.out.println("Buffer: >" + new String(this.buffer.array(), 0, this.buffer.position()) + "<");
			
			this.buffer.flip();
			if(i == 0) {
				// we record time only before first request was sent
				req.measurements.setSentToServerTime(System.nanoTime());
			}
			this.sendDataToServer(this.currentServerOrder[i], this.buffer);
			
			this.serversLoad_GET[this.currentServerOrder[i]]++;
			this.serversLoad_GET_reads[this.currentServerOrder[i]] += numKeysPerServer[i];
		}
		
//		Handler[] handlers = MyMiddleware.debugLogger.getHandlers();
//		for(Handler h : handlers) {
//			if(h instanceof MemoryHandler) {
//				MemoryHandler mh = (MemoryHandler) h;
//				mh.push();
//				mh.flush();
//			} else {
//				h.flush();
//			}			
//		}
		
		return numKeysPerServer;		
	}
	
	
	private ArrayList<BufferStruct> collectResponses2(Request req) {
		MyMiddleware.debugLogger.log(Level.FINEST, "@Worker " + id + ": GET request - collecting responses.");
		
		ArrayList<BufferStruct> responses = new ArrayList<BufferStruct>();
		for(int i = 0; i < this.currentServerOrder.length; i++) {
			this.buffer.clear();
			this.readGETResponseFromOneServer(this.currentServerOrder[i]);
//			System.out.println("From server " + currentServerOrder[i] + " received: >" + new String(this.buffer.array(), 0, this.buffer.limit()) + "<");
			responses.add(new BufferStruct(this.buffer.position(), buffer.capacity(), buffer.limit(), buffer.array(), true));
		}
		req.measurements.setReceivedCompleteResponseTime(System.nanoTime());
		return responses;
	}
	
	private void assembleResponses3(ArrayList<BufferStruct> responses) {
		MyMiddleware.debugLogger.log(Level.FINEST, "@Worker " + id + ": GET request - assembling requests.");
		this.buffer.clear();
		for(int i = 0; i < responses.size(); i++) {
			if(i == responses.size()-1) {
				this.buffer.put(responses.get(i).getArray(), 0, responses.get(i).getLimit());
			} else {
				this.buffer.put(responses.get(i).getArray(), 0, responses.get(i).getLimit()-5);
			}	
		}
//		System.out.println("Final response is: >" + new String(this.buffer.array(), 0, this.buffer.position()) + "<");
		this.buffer.flip();
	}
	
	private ArrayList<String> getGETkeys(Request req) {
		String commandline = new String(req.getBuffer().getArray(), 0, req.getBuffer().getLimit()-2);
		StringTokenizer st = new StringTokenizer(commandline, " ");
		String get = st.nextToken();
		ArrayList<String> keys = new ArrayList<String>();
		while(st.hasMoreTokens()) {
			String key = st.nextToken().trim();
			keys.add(key);
		}
		return keys;
	}	
	
	//----------------------------------------------
	//	SET COMMAND SUPPORT
	//----------------------------------------------
	
	/**
	 * This method does *NOT* allocate new buffer! It reuses buffer of the worker thread!
	 * Instead, for every server, it creates BufferStruct which copies written content of the buffer
	 * into byte array of the length equal to number of written bytes. This way memory is saved, and time
	 * necessary for buffer allocation is saved.
	 * Returns flipped buffer ready to be read from!
	 * @param buffer
	 * @return
	 */
	private void readResponses(Request req) {
		ArrayList<BufferStruct> responses = new ArrayList<BufferStruct>();
		for(int i = 0; i < this.servers.size(); i++) {
			this.readResponseFromOneServer(i, false, null);		// all buffers are flipped and ready for reading
			responses.add(new BufferStruct(this.buffer.position(), this.buffer.capacity(), this.buffer.limit(), this.buffer.array(), true));
		}
		// server service time is time between first request is sent and last response is received
		// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		// excludes verification, it is part of post-processing
		req.measurements.setReceivedCompleteResponseTime(System.nanoTime());
		boolean flag = true;
		int errorPosition = -1;
		for(int i = 0; i < responses.size(); i++) {
			boolean f = isResponseError(responses.get(i).getArray(), responses.get(i).getLimit());
			flag = flag & f;
			if(!flag) {
				errorPosition = 0;
				break;
			}
		}
		if(flag) {
			this.buffer.clear();
			this.buffer.put(responses.get(0).getArray());
			this.buffer.flip();
		} else {
			MyMiddleware.debugLogger.log(Level.SEVERE, "@Worker " + id + ": Response of SET request is not STORED. >" + new String(responses.get(errorPosition).getArray()) + "<");
			this.errorsCount_SET++;
			this.buffer.clear();
			this.buffer.put(responses.get(errorPosition).getArray());
			this.buffer.flip();
		}		
	}
	
	/**
	 * It clears the buffer before reading.
	 * After execution, worker's buffer is flipped!
	 * @param i
	 * @param expectedGETresponse
	 * @return
	 */
	private void readResponseFromOneServer(int i, boolean expectedGETresponse, Request req) {
		int numKeys = 0;
		this.buffer.clear();
		while(true) {
			try {
				int bytesRead = this.servers.get(i).read(this.buffer);
				if(bytesRead == -1) {
					MyMiddleware.debugLogger.log(Level.SEVERE, "@Worker " + id + ": Connection closed, bytes read -1");
				}
			} catch (IOException e) {
				MyMiddleware.debugLogger.log(Level.SEVERE, "@Worker " + id, e);
				return;
			}
			
			if(expectedGETresponse && Config.enableGETresponsesCompletenessVerification) {
				if(req != null) {
					req.measurements.setReceivedCompleteResponseTime(System.nanoTime());
				}				
				numKeys = Utils.verifyGETresponse2(this.buffer.array(), this.buffer.position());
				if(numKeys >= 0) break;
			} else {
				break;
			}
		}
		this.buffer.flip();
	}
	
	/**
	 * It clears the buffer before reading.
	 * After execution, worker's buffer is flipped!
	 * @param i
	 * @param expectedGETresponse
	 * @return
	 */
	private void readGETResponseFromOneServer(int i) {
		int numKeys = 0;
		this.buffer.clear();
		while(true) {
			try {
				int bytesRead = this.servers.get(i).read(this.buffer);
				if(bytesRead == -1) {
					MyMiddleware.debugLogger.log(Level.SEVERE, "@Worker " + id + ": Connection closed, bytes read -1");
				}
			} catch (IOException e) {
				MyMiddleware.debugLogger.log(Level.SEVERE, "@Worker " + id, e);
				return;
			}
			
			boolean comparison = Utils.compare(Config.end, 0, Config.end.length, this.buffer.array(), this.buffer.position()-5, this.buffer.position());
			if(comparison) {
				break;
			}
		}
		this.buffer.flip();
	}
	
	/**
	 * Accepts BufferStruct with content of already flipped ByteBuffers. 
	 * It means that position points to first byte to be read, 
	 * and limit points to one spot after the last written byte.
	 * Length of response is limit-0.
	 * 
	 * Check is performed only for SET request
	 * @param response
	 * @return
	 */
	private boolean isResponseError(byte[] array, int limit) {
		String rs = new String(array, 0, limit);
		if("STORED\r\n".equals(rs)) {
			return true;
		} else {
			return false;
		}
	}
	
	//-----------------------------------------
	//	DATA-SENDING
	//-----------------------------------------

	private void sendDataToServers() {
		for(int i = 0; i < this.servers.size(); i++) {
			this.sendDataToServer(i, this.buffer);
			this.buffer.rewind();						// !!!! important to come back to the beginning of the buffer, before sending new one
		}
	}
	
	private void sendDataToServer(int i, ByteBuffer data) {
		try {
			while(data.hasRemaining()) {
				this.servers.get(i).write(data);
			}
//			System.out.println("Data sent to server!");
		} catch (IOException e) {
			MyMiddleware.debugLogger.log(Level.SEVERE, "@Worker " + id, e);
		}
	}
	
	/**
	 * This method expects that ByteBuffer of worker thread is already flipped
	 * and ready for reading!
	 * @param client
	 */
	private void sendDataToClient(SocketChannel client) {
		try {
			while(this.buffer.hasRemaining()) {
				client.write(this.buffer);
			}
		} catch (IOException e) {
			MyMiddleware.debugLogger.log(Level.SEVERE, "@Worker " + id, e);
		}
	}
	
	//-----------------------------------------
	//	LOGGING SUPPORT
	//-----------------------------------------
	
	public void incrementLogCounter() {
		this.logCounter++;
	}
	
	public static String headerTimings() {
		StringBuilder sb = new StringBuilder();
		sb.append("WorkerID").append(Config.delimiter);
		sb.append("Command").append(Config.delimiter);
		sb.append("NumberOfKeys").append(Config.delimiter);
		sb.append("QueueSize").append(Config.delimiter);
		sb.append("RequestReceived_time").append(Config.delimiter);
		sb.append("PutInQueue_time").append(Config.delimiter);
		sb.append("TakenOutOfQueue_time").append(Config.delimiter);
		sb.append("SentToServer_time").append(Config.delimiter);
		sb.append("ReceivedCompleteResponse_time").append(Config.delimiter);
		sb.append("ResponseSentToClient_time").append(Config.delimiter);
		sb.append("DumpingToDisk_flag").append(System.lineSeparator());
		return sb.toString();
	}
	
	private void logTimings(Measurements measurements) {		
		StringBuilder sb = new StringBuilder();
		sb.append(this.id).append(Config.delimiter);
		sb.append(measurements.getCommand()).append(Config.delimiter);
		sb.append(measurements.getNumKeys()).append(Config.delimiter);
		sb.append(this.currentQueueSize).append(Config.delimiter);
		sb.append(measurements.getRequestReceivedTime()).append(Config.delimiter);
		sb.append(measurements.getPutInQueueTime()).append(Config.delimiter);
		sb.append(measurements.getTakenOutOfQueueTime()).append(Config.delimiter);
		sb.append(measurements.getSentToServerTime()).append(Config.delimiter);
		sb.append(measurements.getReceivedCompleteResponseTime()).append(Config.delimiter);
		sb.append(measurements.getResponseSentToClientTime()).append(Config.delimiter);
		
		if(this.logCounter == Config.logsDumpingFreq-1) {
			sb.append("1").append(System.lineSeparator());
			this.forceDump(sb.toString());
		} else {
			sb.append("0").append(System.lineSeparator());			
			timerLogger.fine(sb.toString());
			this.incrementLogCounter();
		}		
	}
	
	private void forceDump(String lastmeassage) {
		if(lastmeassage != null) {
			this.timerLogger.fine(lastmeassage);
		}		
		Handler[] handlers = this.timerLogger.getHandlers();
		for(Handler h : handlers) {
			if(h instanceof MemoryHandler) {
				MemoryHandler mh = (MemoryHandler) h;
				mh.push();
				mh.flush();
			}		
		}		
		handlers = this.counterLogger.getHandlers();
		for(Handler h : handlers) {
			if(h instanceof MemoryHandler) {
				MemoryHandler mh = (MemoryHandler) h;
				mh.push();
				mh.flush();
			}		
		}
		this.logCounter = 0;
	}
	
	public static String headerCounters(int serverCount) {
		StringBuilder sb = new StringBuilder();
		sb.append("Time").append(Config.delimiter);
		sb.append("NumberOfSETrequests").append(Config.delimiter);
		for(int i = 1; i <= Config.maxNumKeys; i++) {
			sb.append("NumberOfGETrequests_keys"+i).append(Config.delimiter);
		}
		for(int i = 0; i < serverCount; i++) {
			sb.append("RequestsLoad_server"+(i+1)).append(Config.delimiter);
		}
		for(int i = 0; i < serverCount; i++) {			
			sb.append("ReadsLoad_server"+(i+1));
			sb.append(Config.delimiter);	
		}
		sb.append("ErrorSET").append(Config.delimiter);
		sb.append("ErrorGET").append(Config.delimiter);
		sb.append("UnverifiedCommands").append(System.lineSeparator());
		return sb.toString();
	}
	
	private void logCounters(long logtime) {
		if(this.counterLoggingFreq_cnt % Config.counterLoggingFreq == 0) {
			this.logcnts(logtime);
		}
	}	
	
	private void logcnts(long logtime) {
		StringBuilder sb = new StringBuilder();
		sb.append(logtime).append(Config.delimiter);
		sb.append(num_SET).append(Config.delimiter);
		for(int i = 0; i < num_GET_n.length; i++) {
			sb.append(num_GET_n[i]).append(Config.delimiter);
		}
		for(int i = 0; i < serversLoad_GET.length; i++) {
			sb.append(serversLoad_GET[i]).append(Config.delimiter);
		}
		for(int i = 0; i < serversLoad_GET_reads.length; i++) {			
			sb.append(serversLoad_GET_reads[i]);
			sb.append(Config.delimiter);		
		}
		sb.append(this.errorsCount_SET).append(Config.delimiter);
		sb.append(this.errorsCount_GET).append(Config.delimiter);
		sb.append(this.unverifiedCommands).append(System.lineSeparator());
		
		this.counterLogger.fine(sb.toString());
		this.counterLoggingFreq_cnt = 0;
	}
	
	public void flushMeasurements() {
		this.logcnts(System.nanoTime());
		Handler[] handlers = this.timerLogger.getHandlers();
		Utils.handleHandlers(handlers);
		handlers = this.counterLogger.getHandlers();
		Utils.handleHandlers(handlers);
	}
	
	//-----------------------------------------

}
