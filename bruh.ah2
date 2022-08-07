#SingleInstance force
ListLines 0
KeyHistory 0
SendMode "Input" ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir ; Ensures a consistent starting directory.

#Include <Array>

currentArr:=[]
AHK_parse(str) {
    global currentArr

    str:=StrReplace(str, "`r`n", "`n", true)
    str:=StrReplace(str, "`r", "`n", true)
    strBak:=str

    c_:=1
    OutputVar_comments:="" ;scope it
    OutputVar_v1str:="" ;scope it

    backtrack_for_hotkey:=0
    aHotkeyWasFound:=false

    string_continuation_section_options:=false
    string_continuation_section_JoinWith:="``n"

    arrArr := []

    hotkeyBlockStart:=0x7FFFFFFFFFFFFFFF ;largest int64
    labelBlockStart:=0x7FFFFFFFFFFFFFFF ;largest int64

    skip_comments()

    statements_loop:
    loop {

        c1:=c_
        char1:=SubStr(str, c_ , 1)
        switch char1 {
            case "":
                return
            case "{":
                c_++
                switch currentArr[currentArr.Length].type {
                    case "function call":
                        currentArr[currentArr.Length].type:="function definition"
                }
                arrArr.Push(currentArr)
                currentArr.Push({type:"block", statements:statements:=[]})
                currentArr:=statements
                skip_comments()
                continue statements_loop
                ; block
            case "}":
                c_++
                currentArr:=arrArr.Pop()
                skip_comments()
                continue statements_loop
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
            case ",":
                ; a:=1,b:=2
                ; or the cursed: Return "", ErrorLevel := 1
                if (currentArr[currentArr.Length].type=="command") {
                    ; rip
                    if (currentArr.Length > 1) {
                        if (currentArr[currentArr.Length - 1].type == "else without block") {
                            currentArr[currentArr.Length - 1].type := "else with block"
                        } else if (currentArr[currentArr.Length - 1].type == "catch without block") {
                            currentArr[currentArr.Length - 1].type := "catch with block"
                        } else if (currentArr[currentArr.Length - 2].type == "if without block") {
                            currentArr[currentArr.Length - 2].type := "if with block"
                            currentArr[currentArr.Length - 1] := {type: "condition with block",expr:currentArr[currentArr.Length - 1]}
                        } else {
                            c_++
                            skip_comments()
                            toPush:=value_expression()
                            currentArr.InsertAt(currentArr.Length, toPush)
                            continue statements_loop
                        }
                        c_++
                        skip_comments()
                        toPush:=value_expression()
                        currentArr[currentArr.Length]:={type:"block", statements: [toPush, currentArr[currentArr.Length]]}
                    } else {
                        c_++
                        skip_comments()
                        toPush:=value_expression()
                        currentArr.InsertAt(1, toPush)
                    }
                } else {
                    c_++
                    skip_comments()
                    toPush:=value_expression()
                    currentArr[currentArr.Length]:={type:"comma multi-statement", left:currentArr[currentArr.Length], right:toPush}
                }
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
                ifStatemement() {
                    ; if statement
                    skip_comments()
                    toPush:=value_expression()
                    if (toPush.type == "variable") {
                        toPush:={type: "group", value: toPush}
                    }
                    char_:=SubStr(str, c_, 1)
                    if (char_=="{") {
                        currentArr.Push({type:"if with block"})
                        currentArr.Push({type: "condition with block",expr:toPush})
                    } else {
                        currentArr.Push({type:"if without block"})
                        currentArr.Push(toPush)
                    }
                }
                elseStatemement() {
                    if (currentArr[currentArr.Length].type == "block" && currentArr[currentArr.Length - 2].type == "if with block") {
                        currentArr[currentArr.Length].type:="block before else"
                    }
                    skip_comments()
                    char_:=SubStr(str, c_, 1)
                    if (char_=="{") {
                        currentArr.Push({type:"else with block"})
                    } else {
                        currentArr.Push({type:"else without block"})
                    }
                }
                _catchStatemement() {
                    if (currentArr[currentArr.Length].type == "block" && currentArr[currentArr.Length - 2].type == "try with block") {
                        currentArr[currentArr.Length].type:="block before catch"
                    }
                    skip_comments()
                    char_:=SubStr(str, c_, 1)
                    if (char_=="{") {
                        currentArr.Push({type:"catch with block"})
                    } else {
                        currentArr.Push({type:"catch without block"})
                    }
                }
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
                            ifStatemement()
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
                                } else if (OutputVar_operator.0=="=") {
                                    c_++
                                    skip_comments()
                                    skip_v1str_noNeedToEscapeComma()
                                    currentArr.Push({type: "binary", op: ":=", left:OutputVar_varName.0, right: v1str_to_expression(OutputVar_v1str.0)})

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
                                        if (OutputVar_varName.0="else") {
                                            elseStatemement()
                                        } else if (OutputVar_varName.0="catch") {
                                            _catchStatemement()
                                        } else {
                                            add_empty_command()
                                        }
                                        continue statements_loop
                                    }
                                } else {
                                    skip_commandArgs()
                                }
                            }
                        }
                    case "(":
                        ; function call
                        if (OutputVar_varName.0="if") {
                            ifStatemement()
                        } else {
                            c_:=c1
                            skip_expression()
                        }
                    case "[", ".":
                        ; array access, property
                        c_:=c1
                        skip_expression()
                    case "{":
                        if (OutputVar_varName.0="else") {
                            elseStatemement()
                        } else if (OutputVar_varName.0="catch") {
                            _catchStatemement()
                        } else {
                            MsgBox "`"{`" but not `"else`" nor `"catch`": " OutputVar_varName.0
                        }
                    default:
                        RegExMatch(str, "(*COMMIT)[&*+\-.\/:<=>^|]+", &OutputVar_operator, c_)
                        if (OutputVar_operator.0==":") {
                            ;label
                            c_++
                            currentArr.Push({type:"label", labelName:SubStr(str, c1, c_ - c1 - 1)})
                            labelBlockStart:=currentArr.Length + 1
                            skip_comments()
                        } else {
                            ;assignment
                            c_:=c1
                            skip_expression()
                        }

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
                        argsArr.Push({type: "directive arg", value: OutputVar_v1str.0})
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
            argsArr.Push({type: "directive arg", value: OutputVar_v1str.0})
        }

        switch (OutputVar_varName.0), 0 {
            case "#NoEnv":
            case "#KeyHistory":
                add_command("KeyHistory", argsArr)
            case "#MaxHotkeysPerInterval":
                currentArr.Push({type: "binary", op: ":=", left:{type:"variable", value:"A_MaxHotkeysPerInterval"}, right: argsArr[1]})
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
                                argsArr.Push(toPush ? toPush : {type:"command empty arg"})
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
                    argsArr.Push(toPush ? toPush : {type:"command empty arg"})
                    break bruh
                case "Sleep":
                    boolArr:=[0]
                case "Send","SendRaw","SendInput","SendPlay","SendEvent"
                ,"SendMode", "SetWorkingDir", "SetBatchLines", "ListLines"
                ,"Goto":
                    boolArr:=[3]
                case "CoordMode":
                    boolArr:=[2,3]
                case "ToolTip":
                    boolArr:=[2,0,0,0]
                case "MouseGetPos":
                    boolArr:=[1,1,1,1,0]
                case "MouseMove":
                    boolArr:=[0,0,0,3]
                case "PixelGetColor":
                    boolArr:=[0,0,0,3]
                case "PixelSearch":
                    boolArr:=[1,1,0,0,0,0,0,0,3]
                case "return":
                    if (hotkeyBlockStart <= currentArr.Length) {
                        blockArr:=[]
                        i_:=hotkeyBlockStart
                        while (i_ <= currentArr.Length) {
                            blockArr.Push(currentArr[i_])
                            i_++
                        }
                        currentArr.RemoveAt(currentArr.Length - blockArr.Length + 1, blockArr.Length)
                        hotkeyBlockStart:=0x7FFFFFFFFFFFFFFF ;largest int64
                        currentArr.Push({type:"block", statements:blockArr})
                        return
                    }
                    if (labelBlockStart <= currentArr.Length) {
                        blockArr:=[]
                        i_:=labelBlockStart
                        while (i_ <= currentArr.Length) {
                            blockArr.Push(currentArr[i_])
                            i_++
                        }
                        currentArr.RemoveAt(currentArr.Length - blockArr.Length + 1, blockArr.Length)
                        labelBlockStart:=0x7FFFFFFFFFFFFFFF ;largest int64
                        currentArr.Push({type:"block", statements:blockArr})
                        return
                    }

                    boolArr:=[0]
                case "Process":
                    ; boolArr:=[0,0,3]
                    boolArr:=[2,0,3]
                case "else":
                    if (currentArr[currentArr.Length].type == "block" && currentArr[currentArr.Length - 2].type == "if with block") {
                        currentArr[currentArr.Length].type:="block before else"
                    }
                    currentArr.Push({type:"else with block"})
                    skip_comments()
                    return
                case "MouseClick":
                    boolArr:=[2,0,0,0,0,2,3]
                case "SetTimer":
                    ; boolArr:=[2,2,0]
                    boolArr:=[0,2,0]
                case "try":
                    skip_comments()
                    char_:=SubStr(str, c_, 1)
                    if (char_=="{") {
                        currentArr.Push({type:"try with block"})
                    } else {
                        currentArr.Push({type:"try without block"})
                    }
                    return
                case "Run", "RunWait":
                    boolArr:=[2,2,2,1]
                case "local", "global", "static":
                    currentArr.Push({type:"var scope declaration", value: StrLower(OutputVar_varName.0)})
                    toPush:=value_expression()
                    if (toPush) {
                        currentArr.Push({type:"first var scope", value:toPush})
                    }
                    return
                case "while":
                    toPush:=value_expression()
                    if (toPush.type == "variable") {
                        toPush:={type: "group", value: toPush}
                    }
                    char_:=SubStr(str, c_, 1)
                    if (char_=="{") {
                        currentArr.Push({type:"while with block"})
                        currentArr.Push({type: "condition with block",expr:toPush})
                    } else {
                        currentArr.Push({type:"while without block"})
                        currentArr.Push(toPush)
                    }
                    return
                default:
                    if (pos:=InStr(OutputVar_comments.0, "`n", true)) {
                        c1:=c_ + pos - 1
                        add_empty_command()
                    }
                    c_:=InStr(str, "::", true, c_) + 2
                    add_hotkey()
                    return
                }
                argNum:=1
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
                                skip_comments()
                                toPush:=value_expression()
                                if (InStr(OutputVar_comments.0, "`n", true)) {
                                    break
                                }
                            } else {
                                ; v1str MsgBox %var%
                                if (argNum == boolArr.Length) {
                                    skip_v1str_noNeedToEscapeComma()
                                    toPush:=v1str_to_expression(OutputVar_v1str.0)
                                    skip_comments()
                                    break
                                } else {
                                    skip_v1str_commaDelim()
                                    toPush:=v1str_to_expression(OutputVar_v1str.0)
                                    skip_comments()
                                    if (InStr(OutputVar_comments.0, "`n", true)) {
                                        break
                                    }
                                }
                            }
                            continue
                        case ",":
                            c_++
                            argNum++
                            argsArr.Push(toPush ? toPush : {type:"command empty arg"})
                            toPush:=""
                            skip_comments()
                            continue
                    }
                    ;v1str
                    switch boolArr[argNum] {
                        case 0:
                            toPush:=value_expression()
                        case 1:
                            toPush:="&" value_expression()
                        case 2:
                            skip_v1str_commaDelim()
                            toPush:=v1str_to_expression(OutputVar_v1str.0)
                            skip_comments()
                        case 3:
                            skip_v1str_noNeedToEscapeComma()
                            toPush:=v1str_to_expression(OutputVar_v1str.0)
                            skip_comments()
                    }
                    if (InStr(OutputVar_comments.0, "`n", true)) {
                        break
                    }
                    if (argNum == boolArr.Length) {
                        break
                    }
                }
                argsArr.Push(toPush ? toPush : {type:"command empty arg"})
                break bruh

        }


        switch (OutputVar_varName.0), 0 {
            case "SetBatchLines":
            case "ListLines":
                if (argsArr[1].type == "string") {
                    switch (argsArr[1].value), 0 {
                        case "On":
                            argsArr[1]:={type: "number", value: 1}
                        case "Off":
                            argsArr[1]:={type: "number", value: 0}
                    }
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
            case "PixelGetColor":
                if (argsArr.Length>=4) {
                    argsArr[4]:=RegExReplace(argsArr[4], "(?i) *RGB *")
                }
                currentArr.Push({type: "binary", op: ":=", left:argsArr[1]
                , right: {type: "function call", func: "PixelGetColor", args: [argsArr[2],argsArr[3],argsArr[4]]}})
            case "PixelSearch":
                if (argsArr.Length==9) {
                    argsArr.Pop()
                }
                add_command(OutputVar_varName.0, argsArr)
            case "Process":
                if (argsArr[1].type=="string") {
                    switch (argsArr[1].value), 0 {
                        case "Priority":
                            tempArr:=[argsArr[3]]
                            if (argsArr[2].type!=="command empty arg") {
                                tempArr.Push(argsArr[2])
                            }
                            add_command("ProcessSetPriority", tempArr)
                    }
                }
            case "Goto":
                if (currentArr[currentArr.Length].type=="hotkey") {
                    if (argsArr[1].type=="string") {
                        argsArr[1].type := "variable"
                        currentArr.Push({type: "function call", func: argsArr[1], args: []})
                    } else {
                        currentArr.Push({type: "function call", func: {type:"variable", value:"%" argsArr[1].value "%"}, args: []})
                    }
                } else {
                    if (argsArr[1].type=="string") {
                        add_command("Goto", [SubStr(argsArr[1],2,-1)])
                    } else {
                        currentArr.Push({type: "function call", func: "Goto", args: [argsArr[1]]})
                    }
                }
            case "SetTimer":
                if (argsArr.Length >= 2) {
                    if (argsArr[2].type=="string" && argsArr[2].value=="Off") {
                        argsArr[2]:={type:"number", value:0}
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
        return parse_expression(str)
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
                currentArr.Push(toPush)
            }
            ; hotkey
        } else {
            currentArr.Push(toPush)
        }
    }

    parse_expression(toParse) {
        str:=toParse
        cBak:=c_
        c_:=1
        toPush:=value_expression()
        c_:=cBak
        str:=strBak
        return toPush
    }

    value_expression() {
        ; variable, string, number, function call, array access, property access
        ; object literal, array literal
        ; ++assignment
        ; -unary minus
        loop 1 {
            char2:=SubStr(str, c_, 1)
            switch char2 {
                case "(":
                    ; group
                    c_++
                    skip_comments()
                    left:={type: "group", value: value_expression()}
                    c_++
                    break
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
                        toPush:=value_expression()
                        if (toPush.type == "variable") {
                            toPush.type:="obj key"
                        }
                        keys.Push(toPush)

                    }
                    break
                case "[":
                    ; array literal
                    ; left:=OutputVar_variableName
                case "`"":
                    if (string_continuation_section_options==false) {
                        RegExMatch(str, "((?:[ \t]+(?=;)(*ACCEPT)|`"`"|[^`"\n]|\n(*ACCEPT))*)(`")", &OutputVar_stringLiteral, c_ + 1)
                        c_:=c_ + 1 + OutputVar_stringLiteral.Len


                        if (!OutputVar_stringLiteral.2) {
                            before:=RTrim(OutputVar_stringLiteral.1)
                            ; string continuation section
                            c_--
                            RegExMatch(str, "(?:(?:^|\s);.*|\/\*[\s\S]*?\n[ \t]*\*\/|\s)*", &OutputVar_innerComments, c_)
                            c_+=OutputVar_innerComments.Len
                            pos_newline:=InStr(str, "`n", true, c_)
                            string_continuation_section_options:=SubStr(str, c_ + 1, pos_newline - (c_ + 1))

                            RegExMatch(str, "((?:`"`"|[^`"])*)`"", &OutputVar_stringLiteral, pos_newline + 1)
                            c_:=pos_newline + 1 + OutputVar_stringLiteral.Len

                            OutputVar_stringLiteral.1:=before OutputVar_stringLiteral.1

                            if (InStr(string_continuation_section_options, "LTrim")) {
                                OutputVar_stringLiteral.1:=RegExReplace(OutputVar_stringLiteral.1, "^[ \t]*")
                            }
                            if (pos_join:=InStr(string_continuation_section_options, "Join")) {
                                pos_space:=InStr(string_continuation_section_options, " ", true, pos_join + 4) || StrLen(string_continuation_section_options)
                                string_continuation_section_JoinWith:=SubStr(string_continuation_section_options, pos_join + 4, pos_space - (pos_join + 4) + 1)
                                string_continuation_section_JoinWith:=StrReplace(string_continuation_section_JoinWith, "``s", " ", true)
                            } else {
                                string_continuation_section_JoinWith:="``n"
                            }
                        }
                    } else {
                        RegExMatch(str, "((?:`"`"|[^`"])*)`"", &OutputVar_stringLiteral, c_ + 1)
                        c_:=c_ + 1 + OutputVar_stringLiteral.Len

                    }
                    OutputVar_stringLiteral.1:=RegExReplace(OutputVar_stringLiteral.1, "(?<!``);", "```;")

                    if (string_continuation_section_options!==false) {
                        if (pos_newlineBefore:=RegExMatch(OutputVar_stringLiteral.1, "\n[ \t]*\)", &OutputVar_EndContinuationSection)) {
                            after:=SubStr(OutputVar_stringLiteral.1, pos_newlineBefore + OutputVar_EndContinuationSection.Len)
                            OutputVar_stringLiteral.1:=SubStr(OutputVar_stringLiteral.1, 1, pos_newlineBefore - 1)
                            string_continuation_section_options:=false
                        }
                        if (InStr(string_continuation_section_options, "LTrim")) {
                            OutputVar_stringLiteral.1:=RegExReplace(OutputVar_stringLiteral.1, "\n[ \t]*", "`n")
                        }
                        OutputVar_stringLiteral.1:=StrReplace(OutputVar_stringLiteral.1, "`n", string_continuation_section_JoinWith, true)

                        if (string_continuation_section_options==false) {
                            OutputVar_stringLiteral.1.=after
                        }
                    }
                    ; left:="`"" StrReplace(OutputVar_stringLiteral.1, "`"`"", "```"") "`""
                    left:={type: "string", value: StrReplace(OutputVar_stringLiteral.1, "`"`"", "```"") }
                    ; string literal
                    break
                case "+", "-", "!", "~", "&":
                    c_++
                    skip_comments()
                    left:={type: "pre-unary", op: char2, right: value_expression()}
                    break
                case "n":
                    word_:=SubStr(str, c_, 3)
                    if (word_=="not") {
                        c_+=3
                        skip_comments()
                        left:={type: "pre-unary", op: "not", right: value_expression()}
                        break
                    }
                }
            RegExMatch(str, "[a-zA-Z0-9_#@$\x80-\x{10ffff}]*", &OutputVar_variableName, c_)
            ; left:=OutputVar_variableName.0
            if (OutputVar_variableName.0 ~= "(?i)^0x[0-9A-F]*$") {
                left:={type: "hex number", value: OutputVar_variableName.0}
            } else {
                if (OutputVar_variableName.0 ~= "^[0-9]*$") {
                    RegExMatch(str, "(?![.+]$)\+?\d*(?:\.\d*)?", &OutputVar_variableNameWhat, c_)
                    if (OutputVar_variableNameWhat.Len == 0) {
                        MsgBox "what is this? parsing number here"
                    }
                    left:={type: "number", value: OutputVar_variableNameWhat.0}
                    OutputVar_variableName:=OutputVar_variableNameWhat
                } else {
                    left:={type: "variable", value: OutputVar_variableName.0}
                }
            }
            c_+=OutputVar_variableName.Len
        }

        loop {
            char_:=SubStr(str, c_, 1)
            switch char_ {
                case "(":
                    ; function call
                    c_++
                    skip_comments()
                    args:=[]
                    loop {
                        char_:=SubStr(str, c_, 1)
                        switch char_ {
                            case ")":
                                if (left.type=="variable") {
                                    switch left.value, 0 {
                                        case "ComObjCreate":
                                            left.value:="ComObject"
                                    }
                                }
                                left:={type: "function call", func: left, args: args}
                                c_++
                                break
                            case ",":
                                c_++
                                skip_comments()
                        }
                        args.Push(value_expression())
                    }
                case "[":
                    ; array access or map access (same syntactically..)
                    c_++
                    skip_comments()
                    left:={type: "array access", parent: left, key: value_expression()}
                    c_++
                case ".":
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
                            } else if (OutputVar_exprOperator.0=="++" || OutputVar_exprOperator.0=="--") {
                                c_+=OutputVar_exprOperator.Len
                                skip_comments()
                                return {type:"post-unary assignment", left:left, op:OutputVar_exprOperator.0}
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
                                ; if (OutputVar_exprOperator.0=="?") {
                                return {type: "binary", op: OutputVar_exprOperator.0, left:left, right: right}
                            ; }
                        case "?":
                            c_++
                            skip_comments()

                            right:=value_expression()
                            if (backtrack_for_hotkey) {
                                if (pos:=InStr(bak_OutputVar_comments.0, "`n", true)) {
                                    c1:=cBakComments + pos
                                    backtrack_for_hotkey:=0
                                    return left
                                }
                            }

                            char_:=SubStr(str, c_, 1)
                            if (char_==":") {
                                c_++
                                skip_comments()
                                ifFalse:=value_expression()
                                if (backtrack_for_hotkey) {
                                    if (pos:=InStr(bak_OutputVar_comments.0, "`n", true)) {
                                        c1:=cBakComments + pos
                                        backtrack_for_hotkey:=0
                                        return left
                                    }
                                }
                                return {type:"ternary",condition:left,ifTrue:right,ifFalse:ifFalse}
                            } else {
                                MsgBox "You Need a : to your ?"
                            }
                        case "``":
                            colonPos:=InStr(str, "::", true, c_ + 1)
                            if (colonPos) {
                                aHotkeyWasFound:=backtrack_for_hotkey:=colonPos + 2
                            }
                            return ""
                        case ",", "", "{", "}", ")":
                            return left
                        case "a":
                            word_:=SubStr(str, c_, 3)
                            if (word_="and") {
                                c_+=3
                                skip_comments() ;assuming not newline word
                                return {type: "binary", op: "and", left:left, right: value_expression()}
                            }
                        case "o":
                            word_:=SubStr(str, c_, 2)
                            if (word_="or") {
                                c_+=2
                                skip_comments() ;assuming not newline word
                                return {type: "binary", op: "or", left:left, right: value_expression()}
                            }
                    }
                    if (OutputVar_comments.0=="" && left.type!=="string") {
                        return left
                    } else if (InStr(OutputVar_comments.0, "`n", true)) {
                        return left
                    } else {
                        return {type: "concat", op: OutputVar_comments.0, left:left, right: value_expression()}
                    }

            }
        }
    }

    add_hotkey() {
        currentArr.Push(hotkeyToWatch:={type: "hotkey", keyName: SubStr(str, c1, c_ - c1)})
        hotkeyBlockStart:=currentArr.Length + 1
        skip_comments()
    }

    add_command(_name, args) {
        currentArr.Push({_name:_name,args:args,type:"command"})
    }

    add_empty_command() {
        if (labelBlockStart <= currentArr.Length && (OutputVar_varName.0="return" || OutputVar_varName.0="exitapp")) {
            if (OutputVar_varName.0="exitapp") {
                add_command("ExitApp", [])
            }
            blockArr:=[]
            i_:=labelBlockStart
            while (i_ <= currentArr.Length) {
                blockArr.Push(currentArr[i_])
                i_++
            }
            currentArr.RemoveAt(currentArr.Length - blockArr.Length + 1, blockArr.Length)
            labelBlockStart:=0x7FFFFFFFFFFFFFFF ;largest int64
            hotkeyBlockStart:=0x7FFFFFFFFFFFFFFF ;largest int64
            currentArr[currentArr.Length] := {type: "function definition", func: {type:"variable", value:currentArr[currentArr.Length].labelName}, args:[]}
            currentArr.Push({type:"block", statements:blockArr})
        } else if (hotkeyBlockStart <= currentArr.Length && (OutputVar_varName.0="return" || OutputVar_varName.0="exitapp")) {
            if (OutputVar_varName.0="exitapp") {
                add_command("ExitApp", [])
            }
            blockArr:=[]
            i_:=hotkeyBlockStart
            while (i_ <= currentArr.Length) {
                blockArr.Push(currentArr[i_])
                i_++
            }
            currentArr.RemoveAt(currentArr.Length - blockArr.Length + 1, blockArr.Length)
            hotkeyBlockStart:=0x7FFFFFFFFFFFFFFF ;largest int64
            currentArr.Push({type:"block", statements:blockArr})
        } else {
            lowered:=StrLower(OutputVar_varName.0)
            switch lowered {
                ; single local is an error, local is assumed ?
                case "local":
                case "global", "static":
                    add_command(lowered, [])
                default:
                    add_command(OutputVar_varName.0, [])
            }
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
; AHK_parse(FileRead("hotkey.ahk"))
; AHK_parse(FileRead("!get colour_mid.ahk"))
; AHK_parse(FileRead("Accelerated Scrolling 1.3.ahk"))
; AHK_parse(FileRead("ifelse.ahk"))
; AHK_parse(FileRead("RunAsTask.ahk"))
; AHK_parse(FileRead("Return comma ErrorLevel assignment.ahk"))
; AHK_parse(FileRead("Return comma ErrorLevel assignment2.ahk"))
; AHK_parse(FileRead("string continuation section.ahk"))
; AHK_parse(FileRead("RunCMD.ahk"))
; AHK_parse(FileRead("File.ReadLine.ahk"))
; AHK_parse(FileRead("Clipboard A_Clipboard.ahk"))
; AHK_parse(FileRead("while.ahk"))
; AHK_parse("buildNumber:=splitByDot[3]")
; AHK_parse("buildNumber:=splitByDot[ComObjCreate()+1]")
AHK_parse("if(true){}else{}")
; AHK_parse(A_Clipboard)


superGlobalVarsMap:=Map()
superGlobalVarsMap.CaseSense:="Off"
superGlobalVarsMap.Set("A_ScriptDir", "A_ScriptDir"
    ,"A_MaxHotkeysPerInterval","A_MaxHotkeysPerInterval"
    ,"A_TimeSincePriorHotkey","A_TimeSincePriorHotkey"
    ,"A_PriorHotkey","A_PriorHotkey"
    ,"A_ThisHotkey","A_ThisHotkey"
    ,"A_AhkPath","A_AhkPath"
    ,"A_IsAdmin","A_IsAdmin"
    ,"A_IsCompiled","A_IsCompiled"
    ,"A_LastError","A_LastError"
    ,"A_ScriptFullPath","A_ScriptFullPath"
    ,"A_ScriptName","A_ScriptName"
    ,"A_Space","A_Space"
    ,"A_Args","A_Args"
    ,"A_PtrSize","A_PtrSize"
    ,"ErrorLevel","ErrorLevel"
    ; functions
    ,"ComObject","ComObject"
    ,"DllCall","DllCall"
    ,"Buffer","Buffer"
    ,"StrLen","StrLen"
    ,"SubStr","SubStr"
    ,"Floor","Floor"
    ,"FileOpen","FileOpen"
    ,"Format","Format"
    ,"NumGet","NumGet"
    ,"NumPut","NumPut"
    ,"HasMethod","HasMethod"
    ,"StrPtr","StrPtr"
    ,"True","True"
    ,"False","False"
)

walker_superGlobalVars() {
    global superGlobalVarsMap
    finalStr:=""
    indent:=""

    do_statements(currentArr)
    return finalStr

    do_statements(statements) {

        statements_len:=statements.Length + 1
        k_:=1
        while (k_ < statements_len) {
            v_:=statements[k_]
            finalStr.=indent
            withNewline()
            k_++
        }

        withNewline() {
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
                case "property access","array access","group","pre-unary", "post-unary assignment", "binary","function call", "ternary"
                , "comma multi-statement":
                    finalStr.=do(v_) "`n"
                case "var scope declaration":
                    finalStr.=v_.value
                    v_:=statements[++k_]
                case "block":
                    finalStr.="{`n"
                    indent.="  "
                    do_statements(v_.statements)
                    indent:=SubStr(indent, 3)
                    finalStr.=indent
                    finalStr.="}`n"
                case "block before else":
                    finalStr.="{`n"
                    indent.="  "
                    do_statements(v_.statements)
                    indent:=SubStr(indent, 3)
                    finalStr.=indent
                    finalStr.="} "
                case "function definition":
                    if (v_.func.type=="variable") {
                        superGlobalVarsMap[v_.func.value]:=v_.func.value
                    }
                    finalStr.=do(v_) " "
                    v_:=statements[++k_]
                case "condition with block":
                    finalStr.=do(v_.expr) " "
                case "if with block":
                    finalStr.="if "
                    v_:=statements[++k_]
                    withNewline()
                    v_:=statements[++k_]
                    withNewline()
                case "if without block":
                    finalStr.="if "
                    v_:=statements[++k_]
                    withNewline()

                    indent.="  "
                    finalStr.=indent
                    v_:=statements[++k_]
                    withNewline()
                    indent:=SubStr(indent, 3)
                    if (k_ + 1 < statements_len && (statements[k_+1].type == "else without block" || statements[k_+1].type == "else with block")) {
                        finalStr.=indent
                        v_:=statements[++k_]
                        withNewline()
                    }
                case "while with block":
                    finalStr.="while "
                    v_:=statements[++k_]
                    withNewline()
                    v_:=statements[++k_]
                    withNewline()
                case "while without block":
                    finalStr.="while "
                    v_:=statements[++k_]
                    withNewline()

                    indent.="  "
                    finalStr.=indent
                    v_:=statements[++k_]
                    withNewline()
                    indent:=SubStr(indent, 3)
                case "else with block":
                    finalStr.="else "
                    v_:=statements[++k_]
                    withNewline()
                case "catch with block":
                    finalStr.="catch "
                    v_:=statements[++k_]
                    withNewline()
                case "else without block":
                    finalStr.="else"
                    finalStr.="`n"
                    indent.="  "
                    finalStr.=indent
                    v_:=statements[++k_]
                    withNewline()
                    indent:=SubStr(indent, 3)
                case "try without block":
                    finalStr.="try"
                    finalStr.="`n"
                    indent.="  "
                    finalStr.=indent
                    v_:=statements[++k_]
                    withNewline()
                    indent:=SubStr(indent, 3)
                case "label":
                    finalStr.=v_.labelName ":`n"
            }
        }
        do(t_) {
            if (Type(t_)=="String") {
                MsgBox "This Should Never Happen: " t_
                return t_
            }
            switch t_.type {
                case "first var scope":
                    return do(t_.value)
                case "property access":
                    return do(t_.parent) "." t_.propName
                case "array access":
                    ;the order of this may cause problems
                    return do(t_.parent) "[" do(t_.key) "]"
                case "group":
                    return "(" do(t_.value) ")"
                case "pre-unary":
                    return t_.op do(t_.right)
                case "post-unary assignment":
                    return do(t_.left) t_.op
                case "binary":
                    return do(t_.left) " " t_.op " " do(t_.right)
                case "comma multi-statement":
                    return do(t_.left) ", " do(t_.right)
                case "ternary":
                    return do(t_.condition) " ? " do(t_.ifTrue) " : " do(t_.ifFalse)
                case "concat":
                    return do(t_.left) (t_.op == "" ? " " : t_.op) do(t_.right)
                case "function call", "function definition":
                    argsStr:=""
                    if (t_.args.Length) {
                        argsStr.=do(t_.args[1])
                        i_:=2, len:=t_.args.Length + 1
                        while (i_<len) {
                            argsStr.=", " do(t_.args[i_])
                            i_++
                        }
                    }
                    return do(t_.func) "(" argsStr ")"
                case "object":
                    argsStr:=""
                    if (t_.keys.Length) {
                        argsStr.=do(t_.keys[1]) ":" do(t_.values[1])
                        i_:=2, len:=t_.keys.Length + 1
                        while (i_<len) {
                            argsStr.=", " do(t_.keys[i_]) ":" do(t_.values[i_])
                            i_++
                        }
                    }
                    return "{" argsStr "}"
            }
        }
    }

}

walker_superGlobalVars()
superGlobalVarsArr:=[]
for k_ in superGlobalVarsMap {
    superGlobalVarsArr.Push(k_)
}
; d superGlobalVarsArr

globalVarsMap:=Map()
globalVarsMap.CaseSense:="Off"
globalFunctionIndices:=[]

walker_globalVars() {
    global globalVarsMap
    global globalFunctionIndices
    finalStr:=""
    indent:=""

    do_statements(currentArr)
    return finalStr

    do_statements(statements) {

        statements_len:=statements.Length + 1
        k_:=1
        while (k_ < statements_len) {
            v_:=statements[k_]
            finalStr.=indent
            withNewline()
            k_++
        }

        withNewline() {
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
                case "property access","array access","group","pre-unary", "post-unary assignment", "binary","function call", "ternary"
                , "comma multi-statement":
                    finalStr.=do(v_) "`n"
                case "var scope declaration":
                    finalStr.=v_.value
                    v_:=statements[++k_]
                    finalStr.=" "
                    withNewline()
                case "block":
                    finalStr.="{`n"
                    indent.="  "
                    do_statements(v_.statements)
                    indent:=SubStr(indent, 3)
                    finalStr.=indent
                    finalStr.="}`n"
                case "block before else":
                    finalStr.="{`n"
                    indent.="  "
                    do_statements(v_.statements)
                    indent:=SubStr(indent, 3)
                    finalStr.=indent
                    finalStr.="} "
                case "function definition":
                    finalStr.=do(v_) " "
                    v_:=statements[++k_]
                    globalFunctionIndices.Push(k_)
                case "condition with block":
                    finalStr.=do(v_.expr) " "
                case "if with block":
                    finalStr.="if "
                    v_:=statements[++k_]
                    withNewline()
                    v_:=statements[++k_]
                    withNewline()
                case "if without block":
                    finalStr.="if "
                    v_:=statements[++k_]
                    withNewline()

                    indent.="  "
                    finalStr.=indent
                    v_:=statements[++k_]
                    withNewline()
                    indent:=SubStr(indent, 3)
                    if (k_ + 1 < statements_len && (statements[k_+1].type == "else without block" || statements[k_+1].type == "else with block")) {
                        finalStr.=indent
                        v_:=statements[++k_]
                        withNewline()
                    }
                case "while with block":
                    finalStr.="while "
                    v_:=statements[++k_]
                    withNewline()
                    v_:=statements[++k_]
                    withNewline()
                case "while without block":
                    finalStr.="while "
                    v_:=statements[++k_]
                    withNewline()

                    indent.="  "
                    finalStr.=indent
                    v_:=statements[++k_]
                    withNewline()
                    indent:=SubStr(indent, 3)
                case "else with block":
                    finalStr.="else "
                    v_:=statements[++k_]
                    withNewline()
                case "catch with block":
                    finalStr.="catch "
                    v_:=statements[++k_]
                    withNewline()
                case "else without block":
                    finalStr.="else"
                    finalStr.="`n"
                    indent.="  "
                    finalStr.=indent
                    v_:=statements[++k_]
                    withNewline()
                    indent:=SubStr(indent, 3)
                case "try without block":
                    finalStr.="try"
                    finalStr.="`n"
                    indent.="  "
                    finalStr.=indent
                    v_:=statements[++k_]
                    withNewline()
                    indent:=SubStr(indent, 3)
                case "label":
                    finalStr.=v_.labelName ":`n"
            }
        }
        do(t_) {
            if (Type(t_)=="String") {
                MsgBox "This Should Never Happen: " t_
                return t_
            }
            switch t_.type {
                case "variable":
                    if (!superGlobalVarsMap.Has(t_.value)) {
                        globalVarsMap[t_.value]:=t_.value
                    }
                case "first var scope":
                    return do(t_.value)
                case "property access":
                    return do(t_.parent) "." t_.propName
                case "array access":
                    ;the order of this may cause problems
                    return do(t_.parent) "[" do(t_.key) "]"
                case "group":
                    return "(" do(t_.value) ")"
                case "pre-unary":
                    return t_.op do(t_.right)
                case "post-unary assignment":
                    return do(t_.left) t_.op
                case "binary":
                    return do(t_.left) " " t_.op " " do(t_.right)
                case "comma multi-statement":
                    return do(t_.left) ", " do(t_.right)
                case "ternary":
                    return do(t_.condition) " ? " do(t_.ifTrue) " : " do(t_.ifFalse)
                case "concat":
                    return do(t_.left) (t_.op == "" ? " " : t_.op) do(t_.right)
                case "function call":
                    argsStr:=""
                    if (t_.args.Length) {
                        argsStr.=do(t_.args[1])
                        i_:=2, len:=t_.args.Length + 1
                        while (i_<len) {
                            argsStr.=", " do(t_.args[i_])
                            i_++
                        }
                    }
                    return do(t_.func) "(" argsStr ")"
                case "object":
                    argsStr:=""
                    if (t_.keys.Length) {
                        argsStr.=do(t_.keys[1]) ":" do(t_.values[1])
                        i_:=2, len:=t_.keys.Length + 1
                        while (i_<len) {
                            argsStr.=", " do(t_.keys[i_]) ":" do(t_.values[i_])
                            i_++
                        }
                    }
                    return "{" argsStr "}"
            }
        }
    }

}

walker_globalVars()
globalVarsArr:=[]
for k_ in globalVarsMap {
    globalVarsArr.Push(k_)
}
; d globalVarsArr

walker_replacer() {
    global superGlobalVarsMap
    finalStr:=""
    indent:=""

    currentScope:=Map()
    currentScope.CaseSense:="Off"
    functionScopes:=[superGlobalVarsMap, currentScope]

    do_statements(currentArr)
    return finalStr

    do_statements(statements) {

        statements_len:=statements.Length + 1
        k_:=1
        while (k_ < statements_len) {
            v_:=statements[k_]
            finalStr.=indent
            withNewline()
            k_++
        }

        withNewline() {
            switch v_.type {
                case "command":
                    if (v_.args.Length) {
                        finalStr.=v_._name " " do(v_.args, 1)
                        i_:=2, len:=v_.args.Length + 1
                        while (i_<len) {
                            finalStr.=", " do(v_.args, i_)
                            i_++
                        }
                    } else {
                        finalStr.=v_._name
                    }
                    finalStr.="`n"
                case "hotkey":
                    finalStr.=v_.keyName
                case "property access","array access","group","pre-unary", "post-unary assignment", "binary","function call", "ternary"
                , "comma multi-statement", "concat":
                    finalStr.=do(statements, k_) "`n"
                case "var scope declaration":
                    finalStr.=v_.value
                    v_:=statements[++k_]
                    finalStr.=" " do(statements, k_) "`n"
                case "block":
                    finalStr.="{`n"
                    indent.="  "
                    do_statements(v_.statements)
                    indent:=SubStr(indent, 3)
                    finalStr.=indent
                    finalStr.="}`n"
                case "block before else":
                    finalStr.="{`n"
                    indent.="  "
                    do_statements(v_.statements)
                    indent:=SubStr(indent, 3)
                    finalStr.=indent
                    finalStr.="} "
                case "function definition":
                    finalStr.=do(statements, k_) " "

                    currentScope:=Map()
                    currentScope.CaseSense:="Off"
                    functionScopes.Push(currentScope)

                    v_:=statements[++k_]
                    withNewline()

                    currentScope:=functionScopes.Pop()
                case "condition with block":
                    finalStr.=do(v_, "expr") " "
                case "if with block":
                    finalStr.="if "
                    v_:=statements[++k_]
                    withNewline()
                    v_:=statements[++k_]
                    withNewline()
                case "if without block":
                    finalStr.="if "
                    v_:=statements[++k_]
                    withNewline()

                    indent.="  "
                    finalStr.=indent
                    v_:=statements[++k_]
                    withNewline()
                    indent:=SubStr(indent, 3)
                    if (k_ + 1 < statements_len && (statements[k_+1].type == "else without block" || statements[k_+1].type == "else with block")) {
                        finalStr.=indent
                        v_:=statements[++k_]
                        withNewline()
                    }
                case "while with block":
                    finalStr.="while "
                    v_:=statements[++k_]
                    withNewline()
                    v_:=statements[++k_]
                    withNewline()
                case "while without block":
                    finalStr.="while "
                    v_:=statements[++k_]
                    withNewline()

                    indent.="  "
                    finalStr.=indent
                    v_:=statements[++k_]
                    withNewline()
                    indent:=SubStr(indent, 3)
                case "else with block":
                    finalStr.="else "
                    v_:=statements[++k_]
                    withNewline()
                case "catch with block":
                    finalStr.="catch "
                    v_:=statements[++k_]
                    withNewline()
                case "else without block":
                    finalStr.="else"
                    finalStr.="`n"
                    indent.="  "
                    finalStr.=indent
                    v_:=statements[++k_]
                    withNewline()
                    indent:=SubStr(indent, 3)
                case "try without block":
                    finalStr.="try"
                    finalStr.="`n"
                    indent.="  "
                    finalStr.=indent
                    v_:=statements[++k_]
                    withNewline()
                    indent:=SubStr(indent, 3)
                case "label":
                    finalStr.=v_.labelName ":`n"
            }
        }
        do(obj, key) {
            t_:=Type(obj) == "Object" ? obj.%key% : obj[key]
            if (Type(t_)=="String") {
                MsgBox "This Should Never Happen: " t_
                return t_
            }
            switch t_.type {
                case "command empty arg":
                    return ""
                case "variable":
                    switch (t_.value), 0 {
                        case "A_LoopFileFullPath":
                            t_.value:="A_LoopFilePath"
                        case "A_LoopFileLongPath":
                            t_.value:="A_LoopFileFullPath"
                        case "Clipboard":
                            t_.value:="A_Clipboard"
                        case "Comspec":
                            t_.value:="A_ComSpec"
                        default:
                            for _scope in functionScopes {
                                if (_scope.Has(t_.value)) {
                                    switch _scope[t_.value] {
                                        case "ReadLine Line":
                                            ; var -> var "`n"
                                            replacement:={left:{type:"variable", value:t_.value}, op:" ", right:{type:"string", value:"``n"}, type:"concat"}
                                            if (Type(obj) == "Object") {
                                                obj.%key%:=replacement
                                            } else {
                                                obj[key]:=replacement
                                            }
                                    }
                                    break
                                }
                            }
                    }
                    return
                case "directive arg", "number", "hex number", "obj key", "double-deref":
                    return t_.value
                case "string":
                    return "`"" t_.value "`""
                case "first var scope":
                    return do(t_, "value")
                case "property access":
                    return do(t_, "parent") "." t_.propName
                case "array access":
                    ;the order of this may cause problems
                    return do(t_, "parent") "[" do(t_, "key") "]"
                case "group":
                    return "(" do(t_, "value") ")"
                case "pre-unary":
                    if (t_.op == "&") {
                       _var:=t_.right
                        for _scope in functionScopes {
                            if (_scope.Has(_var.value)) {
                                switch _scope[_var.value] {
                                    case "string so StrPtr":
                                        ; &var -> StrPtr(var)
                                        replacement:={args:[_var], func:{type:"variable", value:"StrPtr"}, type:"function call"}
                                        if (Type(obj) == "Object") {
                                            obj.%key%:=replacement
                                        } else {
                                            obj[key]:=replacement
                                        }
                                        return do(obj, key)
                                    case "Buffer with Ptr":
                                        ; &var -> var
                                        if (Type(obj) == "Object") {
                                            obj.%key%:=_var
                                        } else {
                                            obj[key]:=_var
                                        }
                                        return do(obj, key)
                                }
                            }
                        }
                        MsgBox "not anything 23534539uwjegi"
                    }
                    return t_.op do(t_, "right")
                case "v2 pre-unary":
                    return t_.op do(t_, "right")
                case "post-unary assignment":
                    return do(t_, "left") t_.op
                case "binary":
                    if (t_.op == ":=") {
                        switch t_.right.type {
                            case "string", "concat":
                                currentScope[t_.left.value]:="string so StrPtr"
                            ; SubStr too
                        }
                    }
                    return do(t_, "left") " " t_.op " " do(t_, "right")
                case "comma multi-statement":
                    return do(t_, "left") ", " do(t_, "right")
                case "ternary":
                    return do(t_, "condition") " ? " do(t_, "ifTrue") " : " do(t_, "ifFalse")
                case "concat":
                    return do(t_, "left") (t_.op == "" ? " " : t_.op) do(t_, "right")
                case "function call":
                    switch t_.func.type {
                        case "variable":
                            switch t_.func.value, 0 {
                                case "VarSetCapacity":
                                    var_:=t_.args.RemoveAt(1)
                                    currentScope[var_.value]:="Buffer with Ptr"
                                    replacement:={left:var_, op:":=", right:{args:t_.args, func:{type:"variable", value:"Buffer"}, type:"function call"}, type:"binary"}
                                    if (Type(obj) == "Object") {
                                        obj.%key%:=replacement
                                    } else {
                                        obj[key]:=replacement
                                    }
                                case "Func":
                                    var_:=t_.args[1]
                                    var_.value:="%" var_.value "%"
                                    var_.type:="double-deref"
                                    if (Type(obj) == "Object") {
                                        obj.%key%:=var_
                                    } else {
                                        obj[key]:=var_
                                    }
                                case "IsFunc":
                                    ; https://www.autohotkey.com/boards/viewtopic.php?style=19&f=13&t=96863#p431844
                                    var_:=t_.args[1]
                                    replacement:={args:[{type:"double-deref", value:"%" var_.value "%"}], func:{type:"variable", value:"HasMethod"}, type:"function call"}
                                    ; replacement:={args:[var_], func:{type:"variable", value:"IsSet"}, type:"function call"}
                                    ; {type:"group", value:{}}
                                    if (Type(obj) == "Object") {
                                        obj.%key%:=replacement
                                    } else {
                                        obj[key]:=replacement
                                    }
                                case "NumPut":
                                    switch t_.args.length {
                                        case 2:
                                            replacementArr:=[{type:"string", value:"Ptr"}, t_.args[1], t_.args[2]]
                                        case 3:
                                            if (t_.args[2].type == "string") {
                                                replacementArr:=[t_.args[3], t_.args[1], t_.args[2]]
                                            } else {
                                                replacementArr:=[{type:"string", value:"Ptr"}, t_.args[1], t_.args[2], t_.args[3]]
                                            }
                                        case 4:
                                            replacementArr:=[t_.args[4], t_.args[1], t_.args[2], t_.args[3]]
                                        default:
                                            MsgBox "fnwioehfoiwehfoi"
                                    }
                                    t_.args:=replacementArr
                                case "NumGet":
                                    switch t_.args.length {
                                        case 2:
                                            replacementArr:=[t_.args[1], t_.args[2], {type:"string", value:"Ptr"}]
                                        case 3:
                                            replacementArr:=t_.args
                                        default:
                                            MsgBox "jhoerkhojeroihji"
                                    }
                                    t_.args:=replacementArr
                                case "DllCall":
                                    i_:=2
                                    while (i_ < t_.args.length) {
                                        ; last character == "*" or "P"
                                        switch SubStr(t_.args[i_].value, -1), 0 {
                                            case "*", "P":
                                                switch t_.args[i_ + 1].type {
                                                    case "variable":
                                                        t_.args[i_ + 1]:={type:"v2 pre-unary", op:"&", right:t_.args[i_ + 1]}
                                                    case "binary":
                                                        t_.args[i_ + 1]:={type:"v2 pre-unary", op:"&", right:t_.args[i_ + 1]}
                                                }
                                        }

                                        i_+=2
                                    }
                            }
                        case "property access":
                            switch t_.func.propName, 0 {
                                case "ReadLine":
                                    if (obj.type == "binary") {
                                        currentScope[obj.left.value]:="ReadLine Line"
                                    }

                            }
                    }
                    argsStr:=""
                    if (t_.args.Length) {
                        argsStr.=do(t_.args, 1)
                        i_:=2, len:=t_.args.Length + 1
                        while (i_<len) {
                            argsStr.=", " do(t_.args, i_)
                            i_++
                        }
                    }
                    return do(t_, "func") "(" argsStr ")"
                case "function definition":
                    argsStr:=""
                    if (t_.args.Length) {
                        argsStr.=do(t_.args, 1)
                        i_:=2, len:=t_.args.Length + 1
                        while (i_<len) {
                            argsStr.=", " do(t_.args, i_)
                            i_++
                        }
                    }
                    return do(t_, "func") "(" argsStr ")"
                case "object":
                    argsStr:=""
                    for i_, e_ in t_.keys {
                        if (e_.type == "string") {
                            e_.type:="obj key"
                        }
                    }
                    if (t_.keys.Length) {
                        argsStr.=do(t_.keys, 1) ":" do(t_.values, 1)
                        i_:=2, len:=t_.keys.Length + 1
                        while (i_<len) {
                            argsStr.=", " do(t_.keys, i_) ":" do(t_.values, i_)
                            i_++
                        }
                    }
                    return "{" argsStr "}"
            }
            MsgBox "Switch .type not matched {okerihji325928} : " t_.type
        }
    }

}
walker_replacer()

walker_undefinedVars() {
    global superGlobalVarsMap
    global globalFunctionIndices
    finalStr:=""
    indent:=""
    functionScopes:=[superGlobalVarsMap]
    _currentIndices:="" ;declare
    currentScope:="" ;declare
    undefinedVarsMap:="" ;declare

    takesIndices(globalFunctionIndices, currentArr)
    takesIndices(notCurrentIndices, notCurrentArr) {
        for i_ in notCurrentIndices {
            blockObj:=notCurrentArr[i_]
            _currentIndices:=[]

            currentScope:=Map()
            currentScope.CaseSense:="Off"
            functionScopes.Push(currentScope)

            ;parameters are also declared variables
            for param in notCurrentArr[i_-1].args {
                switch param.type {
                    case "variable":
                        currentScope[param.value]:=param.value
                    case "binary":
                        currentScope[param.left.value]:=param.left.value
                }
            }

            undefinedVarsMap:=Map()
            undefinedVarsMap.CaseSense:="Off"

            for k_, v_ in blockObj.statements {
                if (v_.type=="function definition") {
                    _currentIndices.Push(k_+1)
                    if (v_.func.type=="variable") {
                        currentScope[v_.func.value]:=v_.func.value
                    }
                }
            }

            do_statements(blockObj.statements) ;block after
            ; d undefinedVarsMap

            if (_currentIndices.Length) {
                takesIndices(_currentIndices, blockObj.statements)
            }
            if (undefinedVarsMap.Count) {
                for k_ in undefinedVarsMap {
                    right:={type:"variable", value:k_}
                    if (A_Index==1) {
                        left:=right
                    } else {
                        left:={type:"comma multi-statement", left:left, right:right}
                    }
                }
                blockObj.statements.InsertAt(1, {type:"var scope declaration", value: "global"}, left)

            }
            currentScope:=functionScopes.Pop()
        }
    }

    do_statements(statements) {
        enumNothingLocalGlobal:=0

        statements_len:=statements.Length + 1
        k_:=1
        while (k_ < statements_len) {
            v_:=statements[k_]
            finalStr.=indent
            withNewline()
            k_++
        }

        withNewline() {
            switch v_.type {
                case "command":
                    if (v_.args.Length) {
                        finalStr.=v_._name " " do(v_.args, 1)
                        i_:=2, len:=v_.args.Length + 1
                        while (i_<len) {
                            finalStr.=", " do(v_.args, i_)
                            i_++
                        }
                    } else {
                        finalStr.=v_._name
                    }
                    finalStr.="`n"
                case "hotkey":
                    finalStr.=v_.keyName
                case "property access","array access","group","pre-unary", "post-unary assignment", "binary","function call", "ternary"
                , "comma multi-statement":
                    finalStr.=do(statements, k_) "`n"
                case "var scope declaration":
                    ; global`n
                    ; is a command with args: []
                    finalStr.=v_.value
                    switch v_.value {
                        case "local":
                            enumNothingLocalGlobal:=1
                        case "global":
                            enumNothingLocalGlobal:=2
                    }
                    v_:=statements[++k_]
                    finalStr.=" "
                    withNewline()
                    enumNothingLocalGlobal:=0
                case "block":
                    finalStr.="{`n"
                    indent.="  "
                    do_statements(v_.statements)
                    indent:=SubStr(indent, 3)
                    finalStr.=indent
                    finalStr.="}`n"
                case "block before else":
                    finalStr.="{`n"
                    indent.="  "
                    do_statements(v_.statements)
                    indent:=SubStr(indent, 3)
                    finalStr.=indent
                    finalStr.="} "
                case "function definition":
                    finalStr.=do(statements, k_) " "
                    v_:=statements[++k_]
                case "condition with block":
                    finalStr.=do(v_, "expr") " "
                case "if with block":
                    finalStr.="if "
                    v_:=statements[++k_]
                    withNewline()
                    v_:=statements[++k_]
                    withNewline()
                case "if without block":
                    finalStr.="if "
                    v_:=statements[++k_]
                    withNewline()

                    indent.="  "
                    finalStr.=indent
                    v_:=statements[++k_]
                    withNewline()
                    indent:=SubStr(indent, 3)
                    if (k_ + 1 < statements_len && (statements[k_+1].type == "else without block" || statements[k_+1].type == "else with block")) {
                        finalStr.=indent
                        v_:=statements[++k_]
                        withNewline()
                    }
                case "while with block":
                    finalStr.="while "
                    v_:=statements[++k_]
                    withNewline()
                    v_:=statements[++k_]
                    withNewline()
                case "while without block":
                    finalStr.="while "
                    v_:=statements[++k_]
                    withNewline()

                    indent.="  "
                    finalStr.=indent
                    v_:=statements[++k_]
                    withNewline()
                    indent:=SubStr(indent, 3)
                case "else with block":
                    finalStr.="else "
                    v_:=statements[++k_]
                    withNewline()
                case "catch with block":
                    finalStr.="catch "
                    v_:=statements[++k_]
                    withNewline()
                case "else without block":
                    finalStr.="else"
                    finalStr.="`n"
                    indent.="  "
                    finalStr.=indent
                    v_:=statements[++k_]
                    withNewline()
                    indent:=SubStr(indent, 3)
                case "try without block":
                    finalStr.="try"
                    finalStr.="`n"
                    indent.="  "
                    finalStr.=indent
                    v_:=statements[++k_]
                    withNewline()
                    indent:=SubStr(indent, 3)
                case "label":
                    finalStr.=v_.labelName ":`n"
            }
        }

        do(obj, key) {
            t_:=Type(obj) == "Object" ? obj.%key% : obj[key]
            if (Type(t_)=="String") {
                MsgBox "This Should Never Happen: " t_
                return t_
            }
            switch t_.type {
                case "variable":
                    switch (enumNothingLocalGlobal) {
                        case 0:
                            outer:
                            loop 1 {
                                for _scope in functionScopes {
                                    if (_scope.Has(t_.value)) {
                                        break outer
                                    }
                                }
                                undefinedVarsMap[t_.value]:=t_.value
                                break outer
                            }
                        case 2:
                            currentScope[t_.value]:=t_.value
                    }
                    ; currentScope[t_.value]:=t_.value
                case "first var scope":
                    return do(t_, "value")
                case "property access":
                    return do(t_, "parent") "." t_.propName
                case "array access":
                    ;the order of this may cause problems
                    return do(t_, "parent") "[" do(t_, "key") "]"
                case "group":
                    return "(" do(t_, "value") ")"
                case "pre-unary":
                    return t_.op do(t_, "right")
                case "v2 pre-unary": ;assume only &
                    switch t_.right.type {
                        case "variable":
                            currentScope[t_.right.value]:=t_.right.value
                        case "binary":
                            currentScope[t_.right.left.value]:=t_.right.left.value
                    }
                    return t_.op do(t_, "right")
                case "post-unary assignment":
                    return do(t_, "left") t_.op
                case "binary":
                    if (t_.op==":=") {
                        if (t_.left.type=="variable") {
                            currentScope[t_.left.value]:=t_.left.value
                        }
                    }
                    return do(t_, "left") " " t_.op " " do(t_, "right")
                case "comma multi-statement":
                    return do(t_, "left") ", " do(t_, "right")
                case "ternary":
                    return do(t_, "condition") " ? " do(t_, "ifTrue") " : " do(t_, "ifFalse")
                case "concat":
                    return do(t_, "left") (t_.op == "" ? " " : t_.op) do(t_, "right")
                case "function call":
                    argsStr:=""
                    if (t_.args.Length) {
                        argsStr.=do(t_.args, 1)
                        i_:=2, len:=t_.args.Length + 1
                        while (i_<len) {
                            argsStr.=", " do(t_.args, i_)
                            i_++
                        }
                    }
                    return do(t_, "func") "(" argsStr ")"
                case "object":
                    argsStr:=""
                    if (t_.keys.Length) {
                        argsStr.=do(t_.keys, 1) ":" do(t_.values, 1)
                        i_:=2, len:=t_.keys.Length + 1
                        while (i_<len) {
                            argsStr.=", " do(t_.keys, i_) ":" do(t_.values, i_)
                            i_++
                        }
                    }
                    return "{" argsStr "}"
            }
        }
    }


}
walker_undefinedVars()

d currentArr

what() {
    finalStr:=""
    indent:=""

    do_statements(currentArr)
    return finalStr

    do_statements(statements) {

        statements_len:=statements.Length + 1
        k_:=1
        while (k_ < statements_len) {
            v_:=statements[k_]
            finalStr.=indent
            withNewline()
            k_++
        }

        withNewline() {
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
                case "property access","array access","group","pre-unary", "post-unary assignment", "binary","function call", "ternary"
                , "comma multi-statement", "concat":
                    finalStr.=do(v_) "`n"
                case "var scope declaration":
                    finalStr.=v_.value
                    v_:=statements[++k_]
                    finalStr.=" " do(v_) "`n"
                case "block":
                    finalStr.="{`n"
                    indent.="  "
                    do_statements(v_.statements)
                    indent:=SubStr(indent, 3)
                    finalStr.=indent
                    finalStr.="}`n"
                case "block before else":
                    finalStr.="{`n"
                    indent.="  "
                    do_statements(v_.statements)
                    indent:=SubStr(indent, 3)
                    finalStr.=indent
                    finalStr.="} "
                case "function definition":
                    finalStr.=do(v_) " "
                    v_:=statements[++k_]
                    withNewline()
                case "condition with block":
                    finalStr.=do(v_.expr) " "
                case "if with block":
                    finalStr.="if "
                    v_:=statements[++k_]
                    withNewline()
                    v_:=statements[++k_]
                    withNewline()
                case "if without block":
                    finalStr.="if "
                    v_:=statements[++k_]
                    withNewline()

                    indent.="  "
                    finalStr.=indent
                    v_:=statements[++k_]
                    withNewline()
                    indent:=SubStr(indent, 3)
                    if (k_ + 1 < statements_len && (statements[k_+1].type == "else without block" || statements[k_+1].type == "else with block")) {
                        finalStr.=indent
                        v_:=statements[++k_]
                        withNewline()
                    }
                case "while with block":
                    finalStr.="while "
                    v_:=statements[++k_]
                    withNewline()
                    v_:=statements[++k_]
                    withNewline()
                case "while without block":
                    finalStr.="while "
                    v_:=statements[++k_]
                    withNewline()

                    indent.="  "
                    finalStr.=indent
                    v_:=statements[++k_]
                    withNewline()
                    indent:=SubStr(indent, 3)
                case "else with block":
                    finalStr.="else "
                    v_:=statements[++k_]
                    withNewline()
                case "catch with block":
                    finalStr.="catch "
                    v_:=statements[++k_]
                    withNewline()
                case "else without block":
                    finalStr.="else"
                    finalStr.="`n"
                    indent.="  "
                    finalStr.=indent
                    v_:=statements[++k_]
                    withNewline()
                    indent:=SubStr(indent, 3)
                case "try without block":
                    finalStr.="try"
                    finalStr.="`n"
                    indent.="  "
                    finalStr.=indent
                    v_:=statements[++k_]
                    withNewline()
                    indent:=SubStr(indent, 3)
                case "label":
                    finalStr.=v_.labelName ":`n"
            }
        }
        do(t_) {
            if (Type(t_)=="String") {
                MsgBox "This Should Never Happen: " t_
                return t_
            }
            switch t_.type {
                case "command empty arg":
                    return ""
                case "variable", "directive arg", "number", "hex number", "obj key", "double-deref":
                    return t_.value
                case "string":
                    return "`"" t_.value "`""
                case "first var scope":
                    return do(t_.value)
                case "property access":
                    return do(t_.parent) "." t_.propName
                case "array access":
                    ;the order of this may cause problems
                    return do(t_.parent) "[" do(t_.key) "]"
                case "group":
                    return "(" do(t_.value) ")"
                case "pre-unary", "v2 pre-unary":
                    if (t_.op == "not") {
                        return t_.op " " do(t_.right)
                    } else {
                        return t_.op do(t_.right)
                    }
                case "post-unary assignment":
                    return do(t_.left) t_.op
                case "binary":
                    return do(t_.left) " " t_.op " " do(t_.right)
                case "comma multi-statement":
                    return do(t_.left) ", " do(t_.right)
                case "ternary":
                    return do(t_.condition) " ? " do(t_.ifTrue) " : " do(t_.ifFalse)
                case "concat":
                    return do(t_.left) (t_.op == "" ? " " : t_.op) do(t_.right)
                case "function call", "function definition":
                    argsStr:=""
                    if (t_.args.Length) {
                        argsStr.=do(t_.args[1])
                        i_:=2, len:=t_.args.Length + 1
                        while (i_<len) {
                            argsStr.=", " do(t_.args[i_])
                            i_++
                        }
                    }
                    return do(t_.func) "(" argsStr ")"
                case "object":
                    argsStr:=""
                    if (t_.keys.Length) {
                        argsStr.=do(t_.keys[1]) ":" do(t_.values[1])
                        i_:=2, len:=t_.keys.Length + 1
                        while (i_<len) {
                            argsStr.=", " do(t_.keys[i_]) ":" do(t_.values[i_])
                            i_++
                        }
                    }
                    return "{" argsStr "}"
            }
            MsgBox "Switch .type not matched {ejf90u2349r8u3} : " t_.type
        }
    }

}

A_Clipboard:=what()

return

f3::Exitapp