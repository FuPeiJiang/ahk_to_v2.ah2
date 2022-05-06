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


    skip_comments()

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

                RegExMatch(str, "[a-zA-Z0-9_#@$\x80-\x{10ffff}]*", &OutputVar_varName, c_)
                c_+=OutputVar_varName.Len
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
                            skip_directiveArgs()
                        } else if (OutputVar_varName.0="if") {
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

    skip_directiveArgs() {
        argsArr:=[]

        loop {
            skip_comments()
            char_:=SubStr(str, c_, 1)
            switch char_ {
                case "":
                    break
                case "%":
                    ; expression only if followed by a \s, yes, \n works too
                    char_:=SubStr(str, c_ + 1, 1)
                    if (char_~="\s") {
                        ; expression
                    } else {
                        ; v1str MsgBox %var%
                        skip_v1str_commaDelim()
                        argsArr.Push(OutputVar_v1str.0)
                    }
                    continue
                case ",":
                    c_++
                    continue
            }
            if (InStr(OutputVar_comments.0, "`n", true)) {
                break
            }
            ;v1str
            skip_v1str_commaDelim()
            argsArr.Push(OutputVar_v1str.0)
        }

        switch (OutputVar_varName.0), 0 {
            case "#NoEnv":
            case "#KeyHistory":
                bruhArr.Push({_name:"KeyHistory",args:argsArr})
            default:
                bruhArr.Push({_name:OutputVar_varName.0,args:argsArr})

        }

    }

    skip_commandArgs() {
        argsArr:=[]
        toPush:=""

        skip_comments()
        char_:=SubStr(str, c_, 1)
        if (char_==",") {
            c_++
            skip_comments()
        }

        if (OutputVar_varName.0="MsgBox") {
            cLoL:=0
            loop {
                char_:=SubStr(str, c_, 1)
                switch char_ {
                    case "":
                        break
                    case "%":
                        ; expression only if followed by a \s, yes, \n works too
                        char_:=SubStr(str, c_ + 1, 1)
                        if (char_~="\s") {
                            ; expression
                        } else {
                            ; v1str MsgBox %var%
                            skip_v1str_noNeedToEscapeComma()
                            toPush:=v1str_to_expression(OutputVar_v1str.0)
                        }
                        skip_comments()
                        continue
                    case ",":
                        c_++
                        argsArr.Push(toPush)
                        toPush:=""
                        skip_comments()
                        continue
                }
                if (InStr(OutputVar_comments.0, "`n", true)) {
                    break
                }
                ;v1str

                cBak:=c_
                skip_v1str_commaDelim()
                if (OutputVar_v1str.0~="^(?!\.$)\d*(?:\.\d*)?$") {
                    toPush:=OutputVar_v1str.0
                } else if (argsArr.Length==1 || argsArr.Length==2) {
                    toPush:=v1str_to_expression(OutputVar_v1str.0)
                    cLoL:=cBak
                } else if (argsArr.Length==3 && !(OutputVar_v1str.0~="^(?!\.$)\d*(?:\.\d*)?$")) {
                    c_:=cLoL
                    skip_v1str_noNeedToEscapeComma()
                    toPush:=v1str_to_expression(OutputVar_v1str.0)
                    argsArr.Pop()
                } else {
                    c_:=cBak
                    skip_v1str_noNeedToEscapeComma()
                    toPush:=v1str_to_expression(OutputVar_v1str.0)
                }
                skip_comments()
                continue
            }
            argsArr.Push(toPush)
        } else {
            loop {
                skip_comments()
                char_:=SubStr(str, c_, 1)
                switch char_ {
                    case "":
                        break
                    case "%":
                        ; expression only if followed by a \s, yes, \n works too
                        char_:=SubStr(str, c_ + 1, 1)
                        if (char_~="\s") {
                            ; expression
                        } else {
                            ; v1str MsgBox %var%
                            skip_v1str_commaDelim()
                            argsArr.Push(v1str_to_expression(OutputVar_v1str.0))
                        }
                        continue
                    case ",":
                        c_++
                        continue
                }
                if (InStr(OutputVar_comments.0, "`n", true)) {
                    break
                }
                ;v1str
                skip_v1str_commaDelim()
                argsArr.Push(v1str_to_expression(OutputVar_v1str.0))
            }
        }


        switch (OutputVar_varName.0), 0 {
            case "SetBatchLines":
            case "ListLines":
                switch (argsArr[1]), 0 {
                    case "`"On`"":
                        argsArr[1]:=1
                    case "`"Off`"":
                        argsArr[1]:=0
                }
                bruhArr.Push({_name:OutputVar_varName.0,args:argsArr})
            default:
                bruhArr.Push({_name:OutputVar_varName.0,args:argsArr})

        }

    }

    v1str_to_expression(str) {
        ; %v% -> v
        ; %v%aa -> v "aa"
        ; aa%v% -> "aa" v
        ; aa%v%aa -> "aa" v "aa"
        ; aa%v%aa%v%aa -> "aa" v "aa" v "aa"
        str:="`"" RegExReplace(str,"%(.*?)%", "`" $1 `"") "`""
        str:=RegExReplace(str,"^`"`" | `"`"$")
        return str
    }

    skip_v1str_commaDelim() {
        RegExMatch(str, "[^\s,]+(?:[ \t]+[^; \t,][^\s,]*)*", &OutputVar_v1str, c_)
        c_+=OutputVar_v1str.Len
    }

    skip_v1str_noNeedToEscapeComma() {
        RegExMatch(str, "\S+(?:[ \t]+[^; \t]\S*)*", &OutputVar_v1str, c_)
        c_+=OutputVar_v1str.Len
    }
}

; AHK_parse(FileRead("test.ahk"))
AHK_parse(FileRead("MsgBox.ahk"))
; d bruhArr

finalStr:=""
for v_ in bruhArr {
    if (v_.args.Length) {
        finalStr.=v_._name " " v_.args[1]
        i_:=2, len:=v_.args.Length + 1
        while (i_<len) {
            finalStr.=", " v_.args[i_]
            i_++
        }
        finalStr.="`n"
    } else {
        finalStr.=v_._name "`n"
    }
}
A_Clipboard:=finalStr

return

f3::Exitapp