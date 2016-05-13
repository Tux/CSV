#include <iostream>     // cout, endl
#include <fstream>      // fstream
#include <vector>
#include <string>
#include <algorithm>    // copy
#include <iterator>     // ostream_operator

#include <boost/tokenizer.hpp>

int main (int argc, char* argv[]) {
    std::string data;
    if (argc == 1) {
        data = "/dev/stdin";
        }
    else {
        data = argv[1];
        }

    std::ifstream in (data.c_str ());
    if (!in.is_open ()) return 1;

    typedef boost::tokenizer<boost::escaped_list_separator<char>> Tokenizer;

    std::vector<std::string> vec;
    std::string line;
    int sum = 0;
    while (getline (in, line)) {
        Tokenizer tok (line);
        for (auto token : tok) {
            sum += 1;
            }
        }
    std::cout << sum << std::endl;
    }
