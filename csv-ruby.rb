require "csv"

i = 0
CSV ($stdin) { |csv|
    csv.each { |row|
        i += row.length
        }
    }

p i
