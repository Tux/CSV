package main

import (
    "encoding/csv"
    "fmt"
    "io"
    "os"
    )

func main () {

    reader := csv.NewReader (os.Stdin)
    sum := 0
    for {
        rows, err := reader.Read ()
        if err == io.EOF {
            break
            }
        sum += len (rows)
        }
    fmt.Println (sum)
    }
