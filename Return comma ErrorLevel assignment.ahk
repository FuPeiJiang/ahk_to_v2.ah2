if true
    Return "", ErrorLevel := 1
else
    a:=1, b:=2

if true
    a:=1, b:=2
else
    Return "", ErrorLevel := 1

if true
    a:=1, b:=2
else {
    Return "", ErrorLevel := 1
}

if true {
    Return "", ErrorLevel := 1
}
else
    a:=1, b:=2
