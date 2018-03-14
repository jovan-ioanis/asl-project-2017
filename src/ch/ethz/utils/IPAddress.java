package ch.ethz.utils;

/**
 * Parses and wraps ip address received as command line argument.
 * @author jovan
 *
 */
public class IPAddress {
	
	private String address;
	private int port;
	
	public IPAddress(String data) {
		this.address = Utils.extractIPaddress(data);
		this.port = Utils.extractPort(data);
	}
	
	public String getIPaddress() {
		return this.address;
	}
	
	public int getPort() {
		return this.port;
	}

}
