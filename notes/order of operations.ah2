#SingleInstance force
ListLines 0
KeyHistory 0
SendMode "Input" ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir ; Ensures a consistent starting directory.

#Include <Array>

; 1*2+3*4+5
; {type:"sum", left:{type:"mul", left: 1, right:2}, right:{type:"sum", left: {type:"mul", left: 3, right:4}, right:5}}


; left:{type:"mul", left: 1, right:2}

ok:={
    left: {
        type: "number",
        value: "1"
    },
    op: "*",
    right: {
        left: {
            type: "number",
            value: "2"
        },
        op: "+",
        right: {
            type: "number",
            value: "3"
        },
        type: "binary"
    },
    type: "binary"
}

order:=Map("+", 2, "*", 1)
if (ok.right.type == "binary" && order[ok.right.op] > order[ok.op]) {
    ok.left:={type:"binary", op:ok.op, left: ok.left, right:ok.right.left}
    ok.op:=ok.right.op
    ok.right:=ok.right.right
}
d array_p(ok)



return

f3::Exitapp