extern crate quick_csv as csv;

fn main() {
    let fpath = ::std::env::args().nth(1).unwrap();
    let rdr = csv::Csv::from_file(fpath).unwrap();
    let sum = rdr.into_iter()
                 .map(|r| r.unwrap().len())
                 .fold(0usize, |c, n| c + n);
    println!("{}", sum);
}
