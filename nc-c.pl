#!perl6

use v6;
use Slang::Tuxic;
use NativeCall;

my class CSV-Parser is repr("CStruct") {
    has int32          $.pstate = 0; # Parser state
    has int32          $.quoted;     # Is the current field a quoted field?
    has int64          $.spaces;     # Number of continious spaces after quote or in a non-quoted field
    has Pointer[uint8] $.entry_buf;  # Entry buffer
    has int64          $.entry_pos;  # Current position in entry_buf (and current size of entry)
    has int64          $.entry_size; # Size of entry buffer
    has int32          $.status;     # Operation status
    has uint8          $.options;
    has uint8          $.quote_char;
    has uint8          $.delim_char;
    has Pointer[int32] $.is_space;
    has Pointer[int32] $.is_term;
    has int64          $.blk_size;
    has Pointer[void]  $.malloc_func;
    has Pointer[void]  $.realloc_func;
    has Pointer[void]  $.free_func;
    }

# int csv_init (struct csv_parser *p, unsigned char options);
sub csv_init (CSV-Parser, uint8) returns int32 is native("csv3") { * }

# size_t csv_parse (struct csv_parser *p, const void *s, size_t len,
#     void (*cb1)(void *, size_t, void *), void (*cb2)(int, void *),
#     void *data);
sub csv_parse (CSV-Parser, Str, int64,
    &cb1 (Str, int64, int64 is rw),
    &cb2 (int64, int64 is rw),
    int64 is rw) returns int64 is native("csv3") { * }

# void csv_free(struct csv_parser *p);
sub csv_free (CSV-Parser) is native("csv3") { * }

# const int READ_SZ = 1024 * 1024;
my $READ-SZ = 1024 * 1024;

my $i = 0;
# void field_count (void* str, size_t str_len, void* data) {
sub field-count (Str $buf, int64 $str-len, int64 $data is rw) {
#     int* count = (int*)data;
#     *count += 1;
    say $i++;
    }

# int main (int argc, char* argv[]) {
#     struct csv_parser parser = {0};
my $parser = CSV-Parser.new;

#     csv_init (&parser, CSV_APPEND_NULL);
csv_init ($parser, 0);

#     char *buf = (char*)malloc (READ_SZ);
#     size_t buflen = READ_SZ;
#     int count = 0;
my int64 $count = 0;

#     while ((buflen = read (0, buf, READ_SZ)) > 0) {
while (my $blob = $*IN.read ($READ-SZ)) {

#   csv_parse (&parser, buf, buflen, field_count, 0, &count);
    csv_parse ($parser, $blob.decode, $READ-SZ, &field-count, Pointer, $count);
    }

#     printf ("%d\n", count);
say $count;

#     free (buf);
#     csv_free (&parser);
csv_free ($parser);

#     return EXIT_SUCCESS;
#     }
