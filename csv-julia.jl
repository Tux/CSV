using CSV

function countCSVfields(file)
    n = 0
    for row in CSV.Rows(file; reusebuffer=true)
        n += length(row)
        end
    return n
    end

println(countCSVfields("/tmp/hello.csv"))
