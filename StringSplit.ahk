r4:=125
; r = 1,2,3
r = 1,2,3,4
StringSplit r, r, `,
MsgBox % r
MsgBox % r2
MsgBox % r0

Loop, %r0%
{
    this_color := r%A_Index%
    MsgBox, Color number %A_Index% is %this_color%.
}

myfunc(randomwordwithr) {
	return randomwordwithr
}