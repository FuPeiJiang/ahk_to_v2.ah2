if true {
    Return "", ErrorLevel := 1, third:=1, fourth:=1
}
else {
    Return "", ErrorLevel := 1, third:=1, fourth:=1
}

if true {
    ok:=1
    Return "", ErrorLevel := 1, third:=1, fourth:=1
}
else {
    ok:=1
    Return "", ErrorLevel := 1, third:=1, fourth:=1
}

if true
    Return "", ErrorLevel := 1, third:=1, fourth:=1
else
    Return "", ErrorLevel := 1, third:=1, fourth:=1

try
    Return "", ErrorLevel := 1, third:=1, fourth:=1
catch
    Return "", ErrorLevel := 1, third:=1, fourth:=1

Return [NumGet(SIZE, 0, "Int"), NumGet(SIZE, 4, "Int")], VarSetCapacity(SIZE, 0)
