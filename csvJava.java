import java.io.Reader;
import java.io.InputStreamReader;
import au.com.bytecode.opencsv.CSVReader;

public class csvJava {

    public static void main (String[] args) throws Exception {

	CSVReader r = new CSVReader (new InputStreamReader (System.in), ',', '"');
	int i = 0;
	String row[];
	while ((row = r.readNext ()) != null)
	    i += row.length;
	System.out.println (i);
	}
    }
