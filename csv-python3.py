import sys
import csv

n = 0
csvreader = csv.reader (sys.stdin, delimiter=",", quotechar='"')
for row in csvreader:
    n += len (row)

print (n)
