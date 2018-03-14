package ch.ethz.asltest;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.ClosedChannelException;
import java.nio.channels.ClosedSelectorException;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.Set;
import java.util.StringTokenizer;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.logging.Level;

import ch.ethz.utils.BufferStruct;
import ch.ethz.utils.Command;
import ch.ethz.utils.Config;
import ch.ethz.utils.Utils;

public class NetThread extends Thread {
	
	private	String							myIp 				= 	null;
	private	int								myPort 				= 	0;
	private	Selector						selector			=	null;
	private ServerSocketChannel				server				=	null;
	private LinkedBlockingQueue<Request> 	queue				=	null;
	private ArrayList<SocketChannel>		clients				=	null;
	
	private boolean							active				=	false;
	
	public NetThread(String myIp, int myPort, LinkedBlockingQueue<Request> queue) {
		this.myIp = myIp;
		this.myPort = myPort;
		this.queue = queue;
		this.initServer();
		this.initSelector();
		this.populateSelector();
		this.clients = new ArrayList<SocketChannel>();
	}
	
	private void initServer() {
		try {
			this.server = ServerSocketChannel.open();
			InetSocketAddress address = new InetSocketAddress(this.myIp, this.myPort);
			this.server.socket().bind(address);
			this.server.configureBlocking(false);
			MyMiddleware.debugLogger.log(Level.SEVERE, "@NetThread: ServerChannel sucessfully bound to " + address.toString() + ".");
		} catch (IOException e) {
			MyMiddleware.debugLogger.log(Level.SEVERE, "", e);
		}
	}
	
	private void initSelector() {
		try {
			this.selector = Selector.open();
			MyMiddleware.debugLogger.log(Level.SEVERE, "@NetThread: Selector sucessfully opened.");
		} catch(IOException e) {
			MyMiddleware.debugLogger.log(Level.SEVERE, "", e);
		}
	}
	
	private void populateSelector() {
		try {
			this.server.register(this.selector, SelectionKey.OP_ACCEPT);
			this.active = true;
			MyMiddleware.debugLogger.log(Level.SEVERE, "@NetThread: ServerChannel successfully registered with selector.");
		} catch(ClosedChannelException e) {
			MyMiddleware.debugLogger.log(Level.SEVERE, "", e);
		} catch (Exception e) {
			MyMiddleware.debugLogger.log(Level.SEVERE, "", e);
		}
	}
	
	public void closeConnections() {
		try {
			this.server.close();
			MyMiddleware.debugLogger.log(Level.SEVERE, "@NetThread: ServerChannel successfully closed.");
		} catch (IOException e) {
			MyMiddleware.debugLogger.log(Level.SEVERE, "", e);
		}
		try {
			this.selector.close();
			MyMiddleware.debugLogger.log(Level.SEVERE, "@NetThread: Selector successfully closed.");
		} catch (IOException e) {
			e.printStackTrace();
			MyMiddleware.debugLogger.log(Level.SEVERE, "", e);
		}
		active = false;
	}
	
	private void acceptNewClients() {
		SocketChannel client = null;
		try {
			client = this.server.accept();
			client.configureBlocking(false);
			ByteBuffer buffer = ByteBuffer.allocate(Config.maxBufferSize_netthread);
			client.register(this.selector, SelectionKey.OP_READ, buffer);
			this.clients.add(client);
			MyMiddleware.debugLogger.log(Level.SEVERE, "@NetThread: New client " + client.getRemoteAddress().toString() + " accepted.");
		} catch (IOException e) {
			e.printStackTrace();
			MyMiddleware.debugLogger.log(Level.SEVERE, "", e);
		}		
	}
	
	private void putRequestInQueue(Request req) {		
		req.measurements.setPutInQueueTime(System.nanoTime());
		boolean success = this.queue.offer(req);
		if(!success) {
			MyMiddleware.debugLogger.log(Level.SEVERE, "@NetThread: Input request queue is full.");
		}
	}
	
	private void acceptNewRequests(SelectionKey thekey) {
		long receptionTime = System.nanoTime();
		try {
			SocketChannel client = (SocketChannel) thekey.channel();
			ByteBuffer buffer = (ByteBuffer) thekey.attachment();
			
			if(Config.enableIncomingMessageCompletenessVerification) {				
				MyMiddleware.debugLogger.log(Level.FINEST, "@NetThread: Buffer capacity = " + buffer.capacity() + ", position = " + buffer.position() + ", limit = " + buffer.limit());
			
				int bytesRead = client.read(buffer);					
				if(bytesRead == -1) {  // reached end of stream!						
					thekey.cancel();
					MyMiddleware.debugLogger.log(Level.SEVERE, "@NetThread: Reached end of stream!");
					return;
				}
				
				Command verified = Utils.verifyInputMessage(buffer.array(), buffer.position());
				if(verified == null) {
					MyMiddleware.debugLogger.log(Level.FINEST, "@NetThread: Incoming message was NOT verified from client " + client.getRemoteAddress().toString());					
//					Request req = new Request(client, new BufferStruct(0, 0, 0, null, true));
//					req.measurements.setRequestReceivedTime(receptionTime);
//					req.setCommand(verified);
//					this.putRequestInQueue(req);
					
					/*
					 * Buffer is not cleared, it should be filled in with the rest of the message
					 */
				} else {
					buffer.flip();
					Request req = new Request(client, new BufferStruct(buffer.position(), buffer.capacity(), buffer.limit(), buffer.array(), true));
					req.setCommand(verified);
					req.measurements.setRequestReceivedTime(receptionTime);
					this.putRequestInQueue(req);
					buffer.clear();
				}				
					
			} else {
				MyMiddleware.debugLogger.log(Level.SEVERE, "@NetThread: Incoming message completeness verification is disabled. Requests are not put in the queue.");
				return;
			}			
			
		} catch (IOException e) {
			MyMiddleware.debugLogger.log(Level.SEVERE, "", e);
		}		
	}
	
	@Override
	public void run() {					
		while(active) {
			if(!this.selector.isOpen()) {
				continue;
			}
			boolean success = false;
			try {
				this.selector.select();
				success = true;
			} catch (IOException e) {
				MyMiddleware.debugLogger.log(Level.SEVERE, "", e);
			} catch (Exception e) {
				MyMiddleware.debugLogger.log(Level.SEVERE, "", e);
			}
			if(!success) continue;
			
			Set<SelectionKey> selectedKeys = null;
			try {
				selectedKeys = selector.selectedKeys();
			} catch (ClosedSelectorException e) {
				MyMiddleware.debugLogger.log(Level.SEVERE, "@NetThread: Selector is already close, probably by Shutdown Hook.", e);
				selectedKeys = null;
			}
			if(selectedKeys == null) {
				continue;
			}
			
			Iterator<SelectionKey> iter = selectedKeys.iterator();
			
			while(iter.hasNext()) {					
				SelectionKey thekey = iter.next();					
				if(thekey.isAcceptable()) {
					this.acceptNewClients();												
				}					
				if(thekey.isReadable()) {
					this.acceptNewRequests(thekey);
				}					
				iter.remove();
			}				
		}		
	}
	
//	private ByteBuffer testing(ByteBuffer req) {
//		String command = new String(req.array());
//		StringTokenizer st = new StringTokenizer(command, " ");
//		String commandName = st.nextToken().trim();
//		if(commandName.equals("set")) {
//			return req;
//		} else if(commandName.equals("get")) {
//			String key = st.nextToken().trim();
//			String newcommand = "get" + " " + key + " " + "memtier-23" + "\r\n";
//			ByteBuffer newreq = ByteBuffer.allocate(Config.maxBufferSize);
//			newreq.clear();
//			newreq.put(newcommand.getBytes());
//			newreq.flip();
//			return newreq;
//		}
//		return null;
//	}

}
