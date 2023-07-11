ff1(Byref aa1) {
    ff2(aa1)
}

ff2(Byref aa1:=0) {
    VarSetCapacity(aa1, 12)
    NumPut(155, aa1, 8, "UChar")
}

ff1(var)
MsgBox % NumGet(var, 8, "UChar")
