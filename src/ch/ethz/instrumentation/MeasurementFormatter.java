package ch.ethz.instrumentation;

import java.util.logging.Formatter;
import java.util.logging.LogRecord;


/**
 * Formatter class for proper formatting of measurement logs.
 * @author jovan
 *
 */
public class MeasurementFormatter extends Formatter {

	@Override
	public String format(LogRecord record) {
		return record.getMessage();
	}

}
