import org.apache.commons.lang3.ObjectUtils;
import java.io.Reader;
import java.io.InputStreamReader;
import com.opencsv.CSVReader;
import com.opencsv.CSVReaderBuilder;
import com.opencsv.CSVParserBuilder;

public class csvJava {

    public static void main (String[] args) throws Exception {

	CSVReader r = new CSVReaderBuilder (new InputStreamReader (System.in))
            .withCSVParser (new CSVParserBuilder ()
                .withSeparator (',')
                .withQuoteChar ('"')
                .build ())
            .build ();
	int i = 0;
	String row[];
	while ((row = r.readNext ()) != null)
	    i += row.length;
	System.out.println (i);
	}
    }
