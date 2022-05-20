#SingleInstance force
ListLines 0
KeyHistory 0
SendMode "Input" ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir ; Ensures a consistent starting directory.

#Include <Array>

currentArr:=[]
AHK_parse(str) {
    global currentArr

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
                            skip_comments()
                            toPush:=value_expression()
                            if (Type(toPush)=="String") {
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
                                        } else if (OutputVar_varName.0="catch") {
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
                    case "(", "[", '.':
                        ; function call, array access, property
                        c_:=c1
                        skip_expression()
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
            case "#MaxHotkeysPerInterval":
                currentArr.Push({type: "binary", op: ":=", left:"A_MaxHotkeysPerInterval", right: argsArr[1]})
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
                    boolArr:=[0,0,3]
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
                            argsArr.Push(toPush)
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
                argsArr.Push(toPush)
                break bruh

        }


        switch (OutputVar_varName.0), 0 {
            case "SetBatchLines":
            case "ListLines":
                switch (argsArr[1]), 0 {
                    case "`"On`"":
                        argsArr[1]:="1"
                    case "`"Off`"":
                        argsArr[1]:="0"
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
                switch (argsArr[1]), 0 {
                    case "Priority":
                        tempArr:=[argsArr[3]]
                        if (argsArr[2]!=="") {
                            tempArr.Push(argsArr[2])
                        }
                        add_command("ProcessSetPriority", tempArr)
                }
            case "Goto":
                if (currentArr[currentArr.Length].type=="hotkey") {
                    if (SubStr(argsArr[1],1,1)=="`"") {
                        currentArr.Push({type: "function call", func: SubStr(argsArr[1],2,-1), args: []})
                    } else {
                        currentArr.Push({type: "function call", func: "%" argsArr[1] "%", args: []})
                    }
                } else {
                    if (SubStr(argsArr[1],1,1)=="`"") {
                        add_command("Goto", [SubStr(argsArr[1],2,-1)])
                    } else {
                        currentArr.Push({type: "function call", func: "Goto", args: [argsArr[1]]})
                    }
                }
            case "SetTimer":
                if (argsArr.Length >= 2) {
                    if (argsArr[2]=="`"Off`"") {
                        argsArr[2]:="0"
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
                currentArr.Push(toPush)
            }
            ; hotkey
        } else {
            currentArr.Push(toPush)
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
                left:="`"" StrReplace(OutputVar_stringLiteral.1, "`"`"", "```"") "`""
                ; string literal
            case "+", "-", "!", "~":
                c_++
                skip_comments()
                left:={type: "pre-unary", op: char2, right: value_expression()}
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
                                if (Type(left)=="String") {
                                    switch left, 0 {
                                        case "ComObjCreate":
                                            left:="ComObject"
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
                        case ",", "", "{", ")":
                            return left
                        default:
                            if (OutputVar_comments.0=="" && SubStr(left,1,1)!=="`"") {
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
            currentArr[currentArr.Length] := {type: "function definition", func: currentArr[currentArr.Length].labelName, args:[]}
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
                case "local", "global", "static":
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
AHK_parse(FileRead("Accelerated Scrolling 1.3.ahk"))
; AHK_parse(FileRead("ifelse.ahk"))
; AHK_parse(FileRead("RunAsTask.ahk"))
; AHK_parse(FileRead("Return comma ErrorLevel assignment.ahk"))
; AHK_parse(FileRead("Return comma ErrorLevel assignment2.ahk"))
; AHK_parse(FileRead("string continuation section.ahk"))
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
                case "property access","group","unary", "post-unary assignment", "binary","function call", "ternary"
                , "comma multi-statement":
                    finalStr.=do(v_) "`n"
                case "var scope declaration":
                    finalStr.=v_.value
                    v_:=statements[++k_]
                    if (v_.type == "comma multi-statement") {
                        finalStr.=" "
                    } else {
                        finalStr.="\n"
                    }
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
    }

    do(v_) {
        if (Type(v_)=="String") {
            return v_
        }
        switch v_.type {
            case "first var scope":
                return do(v_.value)
            case "property access":
                return do(v_.parent) "." v_.propName
            case "group":
                return "(" do(v_.value) ")"
            case "pre-unary":
                return v_.op do(v_.right)
            case "post-unary assignment":
                return do(v_.left) v_.op
            case "binary":
                return do(v_.left) " " v_.op " " do(v_.right)
            case "comma multi-statement":
                return do(v_.left) ", " do(v_.right)
            case "ternary":
                return do(v_.condition) " ? " do(v_.ifTrue) " : " do(v_.ifFalse)
            case "concat":
                return do(v_.left) (v_.op == "" ? " " : v_.op) do(v_.right)
            case "function call", "function definition":
                argsStr:=""
                if (v_.args.Length) {
                    argsStr.=do(v_.args[1])
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