foo() {
    MsgBox % "Hello"
}

var:="foo"
Func("foo").Call()
Func(var).Call()