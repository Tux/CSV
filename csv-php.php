#!/usr/bin/php

<?php

$filename = "/dev/stdin";
$sum = 0;
if (($handle = fopen ($filename, 'r')) !== FALSE) {
    while (($row = fgetcsv ($handle, 1000, ',')) !== FALSE) {
        $sum += count ($row);
        }
    fclose ($handle);
    }
printf ("%d\n", $sum);
?>
