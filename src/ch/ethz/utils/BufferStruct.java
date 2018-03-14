package ch.ethz.utils;


/**
 * Instances of this class store information received from servers by Worker threads in 2 cases:
 * 	- responses from all servers in case of SET request
 * 	- responses from all servers in case of sharded GET request
 * 
 * The goal was to save time on allocating new ByteBuffer for every reading. Instead, only byte array
 * is generated with length equal to number of bytes received from the server.
 * @author jovan
 *
 */
public class BufferStruct {
	
	private int		position		=	0;
	private int 	capacity		=	0;
	private int		limit			=	0;
	private byte[]	array			=	null;
	
	public BufferStruct(int position, int capacity, int limit, byte[] array, boolean isFlippedAlready) {
		this.position = position;
		this.capacity = capacity;
		this.limit = limit;
		int p = -1;
		if(isFlippedAlready) {
			p = this.limit;
		} else {
			p = this.position;
		}
		this.array = new byte[p];
		for(int i = 0; i < p; i++) {
			this.array[i] = array[i];
		}
//		System.out.println("BS: cap = " + this.capacity + ", limit = " + this.limit + ", position = " + this.position + ", array = " + new String(this.array));
	}
	
	public int getPosition() {
		return this.position;
	}
	
	public int getCapacity() {
		return this.capacity;
	}
	
	public int getLimit() {
		return this.limit;
	}
	
	public byte[] getArray() {
		return this.array;
	}

}
