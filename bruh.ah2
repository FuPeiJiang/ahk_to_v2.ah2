#SingleInstance force
ListLines 0
KeyHistory 0
SendMode "Input" ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir ; Ensures a consistent starting directory.

#Include <Array>

bruhArr:=[]
AHK_parse(str) {

    c_:=1
    OutputVar_comments:="" ;scope it
    OutputVar_v1str:="" ;scope it


    skip_s()

    statements_loop:
    loop {

        char1:=SubStr(str, c_ , 1)
        switch char1 {
            case "":
                return
            case "(":
                ; group
            case "{":
                ; block
            case "+", "-":
                ; assignment ++v++
                ; unary minus -2
                ; at THIS point, you can just start the expression branch
                ; in a function of course
            ; case "#":
            default:
                ; function call
                ; function definition
                ; assignement
                ; hotkey, label, hotstring
                ; if, while, for, loop,
                ; assignment if:=2
                ; if statement if :=2

                ; directive #NoEnv
                ; assignement #NoEnv:=2

                RegExMatch(str, "[a-zA-Z0-9_#@$\x80-\x{10ffff}]*", &OutputVar, c_)
                c_+=OutputVar.Len
                char_:=SubStr(str, c_, 1)
                switch char_ {
                    case "":
                        return
                    case " ", "`t", "`n", ",":
                        ;directive ONLY if starts with # of if
                        ; else, assignment or command only if no :=
                        ; msgbox := 2 is an assignment
                        if (char1=="#") {
                            ; directive
                            skip_commandArgs()
                        } else if (OutputVar.0="if") {
                            ; if statement
                        } else {
                            skip_comments()
                            if (RegExMatch(str, "^[&*+\-.\/:<=>^|]+", &OutputVar, c_)) {
                                ; assignment
                                MsgBox OutputVar.0
                                ; if it's unary plus, or *2, it's passed to MsgBox as v1str

                            } else {
                                ; command
                                ; if skipped a line, it's another statement now
                                ; if didn't skip a line, it's args...
                                if (InStr(OutputVar_comments.0, "`n", true)) {
                                    continue statements_loop
                                } else {
                                    skip_commandArgs()
                                }
                            }
                        }
                    default:
                        ;assignment
                        RegExMatch(str, "[&*+\-.\/:<=>^|]*", &OutputVar, c_)
                        msgbox OutputVar.0
                        c_+=OutputVar.Len
                        skip_s()

                }
        }
    }

    return

    skip_s() {
        RegExMatch(str, "[ \t]*", &OutputVar, c_)
        c_+=OutputVar.Len
    }

    skip_comments() {
        RegExMatch(str, "(?:(?:^|\s);.*|\/\*(?:.|\n)\n[ \t]*\*\/|\s)*", &OutputVar_comments, c_)
        c_+=OutputVar_comments.Len
    }

    skip_commandArgs() {
        argsArr:=[]
        loop {
            skip_comments()
            char_:=SubStr(str, c_, 1)
            switch char_ {
                case "":
                    bruhArr.Push(argsArr)
                    return
                case "%":
                    ; expression only if followed by a \s, yes, \n works too
                    char_:=SubStr(str, c_ + 1, 1)
                    if (char_~="\s") {
                        ; expression
                    } else {
                        ; v1str MsgBox %var%
                        skip_v1str()
                        argsArr.Push(OutputVar_v1str.0)
                    }
                    continue
                case ",":
                    c_++
                    continue
            }
            if (InStr(OutputVar_comments.0, "`n", true)) {
                bruhArr.Push(argsArr)
                return
            }
            ;v1str
            skip_v1str()
            argsArr.Push(OutputVar_v1str.0)
        }

    }

    skip_v1str() {
        RegExMatch(str, "[^\s,]+(?:[ \t]+[^; \t,][^\s,]*)*", &OutputVar_v1str, c_)
        c_+=OutputVar_v1str.Len
    }
}

AHK_parse(FileRead("test.ahk"))
d bruhArr

return

f3::Exitapp