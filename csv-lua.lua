#!/usr/bin/lua

local lpeg   = require "lpeg"
local field  = '"' * lpeg.Cs (((lpeg.P (1) - '"')
             + lpeg.P'""' / '"')^0) * '"'
             + lpeg.C ((1 - lpeg.S',\n"')^0)

local record = field * (',' * field)^0 * (lpeg.P'\n' + -1)

function csv (s)
    return lpeg.match (record, s)
    end

-- Count total number of fields from stdin
local n = 0
for l in io.stdin:lines () do
    local rec = { csv (l) }
    n = n + #rec
    end
print (n)
