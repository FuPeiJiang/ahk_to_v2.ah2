class biga {
    class sure {
        foo(a,b) {
            return a+b+b
        }
    }
    foo(a,b) {
        return a+b
    }
}
MsgBox % biga.sure.foo(1,5,3)
