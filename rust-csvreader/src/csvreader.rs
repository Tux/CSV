extern crate csv;

fn main () {
    let fpath = ::std::env::args ().nth (1).unwrap ();
    let mut rdr = csv::Reader::from_file (fpath).unwrap ().has_headers (false);
    let mut sum = 0;
    loop {
        match rdr.next_bytes () {
            csv::NextField::Data (_)    => sum += 1,
            csv::NextField::EndOfRecord => {}
            csv::NextField::EndOfCsv    => break,
            csv::NextField::Error (err) => panic! ("{}", err),
            }
        }
    println!("{}", sum);
    }
