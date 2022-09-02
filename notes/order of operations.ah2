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

orderOfOperations:=Map(
    ":=", 11,
    "+=", 11,
    "-=", 11,
    "*=", 11,
    "/=", 11,
    "//=", 11,
    ".=", 11,
    "|=", 11,
    "&=", 11,
    "^=", 11,
    ">>=", 11,
    "<<=", 11,

    "||", 10,
    "or", 10,

    "&&", 9,
    "and", 9,

    "=", 8,
    "==", 8,
    "<>", 8,
    "!=", 8,

    ">", 7,
    "<", 7,
    ">=", 7,
    "<=", 7,

    "~=", 6,

    ".", 5,

    "&", 4,
    "^", 4,
    "|", 4,

    "<<", 3,
    ">>", 3,

    "+", 2,
    "-", 2,

    "*", 1,
    "/", 1,
    "//", 1,

    "**", 0,
)
if (ok.right.type == "binary" && orderOfOperations[ok.right.op] > orderOfOperations[ok.op]) {
    ok.left:={type:"binary", op:ok.op, left: ok.left, right:ok.right.left}
    ok.op:=ok.right.op
    ok.right:=ok.right.right
}
d array_p(ok)



return

f3::Exitapp