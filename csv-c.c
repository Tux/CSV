#include <libcsv/csv.h>
#include <stdio.h>
#include <string.h>

void field_count (void* str, size_t str_len, void* data) {
    int* count = (int*)data;
    *count += 1;
    }

const int READ_SZ = 1024 * 1024;

int main (int argc, char* argv[]) {
    struct csv_parser parser = {0};
    csv_init (&parser, CSV_APPEND_NULL);
    char *buf = (char*)malloc (READ_SZ);
    size_t buflen = READ_SZ;
    int count = 0; 
    while ((buflen = read (0, buf, READ_SZ)) > 0) {
        csv_parse (&parser, buf, buflen, field_count, 0, &count);
        }
    printf ("%d\n", count);
    free (buf);
    csv_free (&parser);
    return EXIT_SUCCESS;
    }
