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

    backtrack_for_hotkey:=0
    aHotkeyWasFound:=false

    currentArr:=bruhArr

    hotkeyBlockStart:=0x7FFFFFFFFFFFFFFF ;largest int64

    skip_comments()

    statements_loop:
    loop {

        c1:=c_
        char1:=SubStr(str, c_ , 1)
        switch char1 {
            case "":
                return
            case "{":
                ; block
            case "``", "\":
                c_:=InStr(str, "::", true, c_ + 1) + 2
                add_hotkey()
            case "+", "-", "!", "~", "(":
                ; assignment ++v++
                ; unary minus -2
                ; at THIS point, you can just start the expression branch
                ; in a function of course

                ; "(" group
                skip_expression()
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
                        add_empty_command()
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
                            if (RegExMatch(str, "(*COMMIT)[&*+\-.\/:<=>^|]+", &OutputVar_operator, c_)) {
                                if (InStr(",:=,+=,-=,*=,/=,//=,.=,|=,&=,^=,>>=,<<=,", "," OutputVar_operator.0 ",", true)) {
                                    c_:=c1
                                    skip_expression()
                                } else if (InStr(",++,--,", "," OutputVar_operator.0 ",", true)) {
                                    if (InStr(OutputVar_comments.0, "`n", true)) {
                                        ; MsgBox
                                        ; ++2
                                        add_command(OutputVar_varName.0, [])
                                        continue statements_loop
                                    } else {
                                        ; MsgBox ++2
                                        skip_commandArgs()
                                    }
                                } else {
                                    ; if it's unary plus, or *2, it's passed to MsgBox as v1str
                                    skip_commandArgs()
                                }

                            } else {
                                ; command
                                ; if skipped a line, it's another statement now
                                ; if didn't skip a line, it's args...
                                if (InStr(OutputVar_comments.0, "`n", true)) {
                                    if (RegExMatch(str, "(*COMMIT)(?i)(?:or|and)", &OutputVar_operator, c_)) {
                                        skip_commandArgs()
                                    } else {
                                        add_empty_command()
                                        continue statements_loop
                                    }
                                } else {
                                    skip_commandArgs()
                                }
                            }
                        }
                    case "(", "[", '.':
                        ; function call, array access, property
                        c_:=c1
                        skip_expression()
                    default:
                        ;assignment
                        c_:=c1
                        skip_expression()

                }
        }
    }

    return

    skip_s() {
        RegExMatch(str, "[ \t]*", &OutputVar, c_)
        c_+=OutputVar.Len
    }

    skip_comments() {
        RegExMatch(str, "(?:(?:^|\s);.*|\/\*[\s\S]*?\n[ \t]*\*\/|\s)*", &OutputVar_comments, c_)
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
                add_command("KeyHistory", argsArr)
            default:
                add_command(OutputVar_varName.0, argsArr)

        }

    }

    skip_commandArgs() {
        argsArr:=[]
        toPush:=""

        char_:=SubStr(str, c_, 1)
        if (char_==",") {
            c_++
            skip_comments()
        }

        bruh:
        loop 1 {
            switch (OutputVar_varName.0), 0 {
                case "MsgBox":
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
                                    c_+=2
                                    toPush:=value_expression()
                                    if (aHotkeyWasFound) {
                                        break
                                    }
                                    if (InStr(OutputVar_comments.0, "`n", true)) {
                                        break
                                    }
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
                        if (OutputVar_v1str.0~="^(?![.+]$)\+?\d*(?:\.\d*)?$") {
                            toPush:=OutputVar_v1str.0
                        } else if (argsArr.Length==1 || argsArr.Length==2) {
                            toPush:=v1str_to_expression(OutputVar_v1str.0)
                            cLoL:=cBak
                        } else if (argsArr.Length==3 && !(OutputVar_v1str.0~="^(?![.+]$)\+?\d*(?:\.\d*)?$")) {
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
                    break bruh
                case "Sleep":
                    boolArr:=[0]
                case "Send","SendRaw","SendInput","SendPlay","SendEvent":
                    boolArr:=[2]
                case "ToolTip":
                    boolArr:=[1,0,0,0]
                ; case "Return":
                    ; special
                default:
                    if (pos:=InStr(OutputVar_comments.0, "`n", true)) {
                        c1:=c_ + pos - 1
                        add_empty_command()
                    }
                    c_:=InStr(str, "::", true, c_) + 2
                    add_hotkey()
                    return
                }
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
                                c_+=2
                                toPush:=value_expression()
                                if (InStr(OutputVar_comments.0, "`n", true)) {
                                    break
                                }
                            } else {
                                ; v1str MsgBox %var%
                                skip_v1str_commaDelim()
                                argsArr.Push(v1str_to_expression(OutputVar_v1str.0))
                            }
                            skip_comments()
                            continue
                        case ",":
                            c_++
                            skip_comments()
                            continue
                    }
                    ;v1str
                    if (A_Index <= boolArr.Length) {
                        switch boolArr[A_Index] {
                            case 0:
                                toPush:=value_expression()
                            case 1:
                                skip_v1str_commaDelim()
                                toPush:=v1str_to_expression(OutputVar_v1str.0)
                                skip_comments()
                            case 2:
                                skip_v1str_noNeedToEscapeComma()
                                toPush:=v1str_to_expression(OutputVar_v1str.0)
                                skip_comments()
                        }
                        if (InStr(OutputVar_comments.0, "`n", true)) {
                            break
                        }
                    }
                }
                argsArr.Push(toPush)
                break bruh

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
                add_command(OutputVar_varName.0, argsArr)
            case "MsgBox":
                switch (argsArr.Length) {
                    case 2:
                        argsArr:=["`"`"", argsArr[2], "`"" argsArr[1] "`""]
                    case 3:
                        argsArr:=[argsArr[3], argsArr[2], "`"" argsArr[1] "`""]
                    case 4:
                        if (argsArr[1]~="^(?![.+]$)\+?\d*(?:\.\d*)?$") {
                            if (argsArr[4]~="^(?![.+]$)\+?\d*(?:\.\d*)?$") {
                                argsArr:=[argsArr[3], argsArr[2], "`"" argsArr[1] " T" argsArr[4] "`""]
                            } else {
                                argsArr:=[argsArr[3], argsArr[2], "`"" argsArr[1] " T`" " argsArr[4]]
                            }
                        } else {
                            if (argsArr[4]~="^(?![.+]$)\+?\d*(?:\.\d*)?$") {
                                argsArr:=[argsArr[3], argsArr[2], argsArr[1] " `" T " argsArr[4] "`""]
                            } else {
                                argsArr:=[argsArr[3], argsArr[2], argsArr[1] " `" T`" " argsArr[4]]
                            }
                        }
                }
                add_command(OutputVar_varName.0, argsArr)
            default:
                add_command(OutputVar_varName.0, argsArr)

        }
        if (aHotkeyWasFound) {
            c_:=aHotkeyWasFound
            aHotkeyWasFound:=0
            add_hotkey()
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

    skip_expression() {
        toPush:=value_expression()
        if (aHotkeyWasFound) {
            if (backtrack_for_hotkey) {
                c_:=backtrack_for_hotkey
                aHotkeyWasFound:=backtrack_for_hotkey:=0
                add_hotkey()
            } else {
                c_:=aHotkeyWasFound
                aHotkeyWasFound:=0
                add_hotkey()
                bruhArr.Push(toPush)
            }
            ; hotkey
        } else {
            bruhArr.Push(toPush)
        }
    }

    value_expression() {
        ; variable, string, number, function call, array access, property access
        ; object literal, array literal
        ; ++assignment
        ; -unary minus

        char2:=SubStr(str, c_, 1)
        switch char2 {
            case "(":
                ; group
                c_++
                skip_comments()
                left:={type: "group", value: value_expression()}
                c_++
            case "{":
                ; object literal
                c_++
                skip_comments()
                keys:=[]
                values:=[]
                loop {
                    char_:=SubStr(str, c_, 1)
                        switch char_ {
                            case "}":
                                left:={type: "object", keys: keys, values: values}
                                c_++
                                break
                            case ":":
                                c_++
                                skip_comments()
                                values.Push(value_expression())
                                continue
                            case ",":
                                c_++
                                skip_comments()
                        }
                    keys.Push(value_expression())
                }
            case "[":
                ; array literal
                ; left:=OutputVar_variableName
            case "`"":
                RegExMatch(str, "`"(?:`"`"|[^`"])*`"", &OutputVar_stringLiteral, c_)
                c_+=OutputVar_stringLiteral.Len
                left:=RegExReplace(OutputVar_stringLiteral.0, "`"`"", "```"")
                ; string literal
            case "+", "-", "!", "~":
                c_++
                skip_comments()
                left:={type: "unary", op: char2, right: value_expression()}
            default:
                RegExMatch(str, "[a-zA-Z0-9_#@$\x80-\x{10ffff}]*", &OutputVar_variableName, c_)
                c_+=OutputVar_variableName.Len
                left:=OutputVar_variableName.0
        }
        loop {
            char_:=SubStr(str, c_, 1)
            switch char_ {
                case '(':
                    ; function call
                    c_++
                    skip_comments()
                    args:=[]
                    loop {
                        char_:=SubStr(str, c_, 1)
                        switch char_ {
                            case ")":
                                left:={type: "function call", func: left, args: args}
                                c_++
                                break
                            case ",":
                                c_++
                                skip_comments()
                        }
                        args.Push(value_expression())
                    }
                case '[':
                    ; array access
                case '.':
                    ; property access
                    c_++
                    RegExMatch(str, "[a-zA-Z0-9_#@$\x80-\x{10ffff}]*", &OutputVar_variableName, c_)
                    c_+=OutputVar_variableName.Len
                    left:={type: "property access", parent: left, propName: OutputVar_variableName.0}
                default:
                    cBakComments:=c_
                    skip_comments()
                    bak_OutputVar_comments:=OutputVar_comments
                    char_:=SubStr(str, c_, 1)
                    switch char_ {
                        case "+", "-", ":", "&", "*", ".", "<", ">", "=", "^", "/", "|":
                            RegExMatch(str, "(*COMMIT)[&*+\-.\/:<=>^|]+", &OutputVar_exprOperator, c_)
                            if (OutputVar_exprOperator.0==":") {
                                return left
                            } else if (SubStr(OutputVar_exprOperator.0, -2)=="::") {
                                aHotkeyWasFound:=backtrack_for_hotkey:=c_ + OutputVar_exprOperator.Len
                                return ""
                            }
                            c_+=OutputVar_exprOperator.Len
                            skip_comments()
                            ; binary operation
                            ; if (InStr(",:=,+=,-=,*=,/=,//=,.=,|=,&=,^=,>>=,<<=,", "," OutputVar_exprOperator.0 ",", true)) {
                                ; return {type: "assignment", op: OutputVar_exprOperator.0, left:left, right: value_expression()}
                            ; } else {
                                right:=value_expression()
                                if (backtrack_for_hotkey) {
                                    if (pos:=InStr(bak_OutputVar_comments.0, "`n", true)) {
                                        c1:=cBakComments + pos
                                        backtrack_for_hotkey:=0
                                        return left
                                    }
                                }
                                return {type: "binary", op: OutputVar_exprOperator.0, left:left, right: right}
                            ; }
                        case "``":
                            colonPos:=InStr(str, "::", true, c_ + 1)
                            if (colonPos) {
                                aHotkeyWasFound:=backtrack_for_hotkey:=colonPos + 2
                            }
                            return ""
                        case ",", "":
                            return left
                        default:
                            if (!OutputVar_comments.0) {
                                return left
                            } else if (InStr(OutputVar_comments.0, "`n", true)) {
                                return left
                            } else {
                                return {type: "concat", op: OutputVar_comments.0, left:left, right: value_expression()}
                            }
                    }

            }
        }
    }

    add_hotkey() {
        bruhArr.Push(hotkeyToWatch:={type: "hotkey", keyName: SubStr(str, c1, c_ - c1)})
        hotkeyBlockStart:=bruhArr.Length + 1
        skip_comments()
    }

    add_command(_name, args) {
        bruhArr.Push({_name:_name,args:args,type:"command"})
    }

    add_empty_command() {
        if (hotkeyBlockStart <= bruhArr.Length && OutputVar_varName.0="return") {
            blockArr:=[]
            i_:=hotkeyBlockStart
            while (i_ <= bruhArr.Length) {
                blockArr.Push(bruhArr[i_])
                i_++
            }
            bruhArr.RemoveAt(bruhArr.Length - blockArr.Length + 1, blockArr.Length)
            hotkeyBlockStart:=0x7FFFFFFFFFFFFFFF ;largest int64
            bruhArr.Push({type:"block", statements:blockArr})
        } else {
            add_command(OutputVar_varName.0, [])
        }
    }

}

; AHK_parse(FileRead("test.ahk"))
; AHK_parse(FileRead("MsgBox.ahk"))
; AHK_parse(FileRead("MsgBox_Insane.ahk"))
; AHK_parse(FileRead("test2.ahk"))
; AHK_parse(FileRead("concat.ahk"))
; AHK_parse(FileRead("object.ahk"))
; AHK_parse(FileRead("basic.ahk"))
AHK_parse(FileRead("hotkey.ahk"))
; d bruhArr

what() {
    finalStr:=""
    indent:=""
    for v_ in bruhArr {
        withNewline(v_)
    }
    return finalStr

    withNewline(v_) {
        switch v_.type {
            case "command":
                if (v_.args.Length) {
                    finalStr.=v_._name " " do(v_.args[1])
                    i_:=2, len:=v_.args.Length + 1
                    while (i_<len) {
                        finalStr.=", " do(v_.args[i_])
                        i_++
                    }
                } else {
                    finalStr.=v_._name
                }
                finalStr.="`n"
            case "hotkey":
                finalStr.=v_.keyName
            case "property access","group","unary","binary","function call":
                finalStr.=do(v_) "`n"
            case "block":
                indent.="  "
                finalStr.="{`n"
                for s_ in v_.statements {
                    finalStr.=indent
                    withNewline(s_)
                }
                indent:=SubStr(indent, 3)
                finalStr.="}`n"
        }
    }

    do(v_) {
        if (Type(v_)=="String") {
            return v_
        }
        switch v_.type {
            case "property access":
                return do(v_.parent) "." v_.propName
            case "group":
                return "(" do(v_.value) ")"
            case "unary":
                return v_.op do(v_.right)
            case "binary":
                return do(v_.left) " " v_.op " " do(v_.right)
            case "function call":
                argsStr:=""
                if (v_.args.Length) {
                    argsStr.=v_._name " " do(v_.args[1])
                    i_:=2, len:=v_.args.Length + 1
                    while (i_<len) {
                        argsStr.=", " do(v_.args[i_])
                        i_++
                    }
                }
                return do(v_.func) "(" argsStr ")"
            case "object":
                argsStr:=""
                if (v_.keys.Length) {
                    argsStr.=do(v_.keys[1]) ":" do(v_.values[1])
                    i_:=2, len:=v_.keys.Length + 1
                    while (i_<len) {
                        argsStr.=", " do(v_.keys[i_]) ":" do(v_.values[i_])
                        i_++
                    }
                }
                return "{" argsStr "}"
        }
    }
}

A_Clipboard:=what()

return

f3::Exitapp