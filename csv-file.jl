using CSV

function countCSVfields(file)
    n = 0
    for row in CSV.File(file; header=0, ntasks=1)
        n += length(row)
        end
    return n
    end

println(countCSVfields("/tmp/hello.csv"))
