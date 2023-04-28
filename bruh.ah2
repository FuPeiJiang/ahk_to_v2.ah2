#SingleInstance force
ListLines 0
KeyHistory 0
SendMode "Input" ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir ; Ensures a consistent starting directory.

; #Include <Array>

aaa(str) {

currentArr:=[]
AHK_parse(str) {
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

    orderOfOperations:=Map(
        ":=", 11, "+=", 11, "-=", 11, "*=", 11, "/=", 11, "//=", 11, ".=", 11, "|=", 11, "&=", 11, "^=", 11, ">>=", 11, "<<=", 11, "||", 10, "or", 10, "&&", 9, "and", 9, "=", 8, "==", 8, "<>", 8, "!=", 8, ">", 7, "<", 7, ">=", 7, "<=", 7, "~=", 6, ".", 5, "&", 4, "^", 4, "|", 4, "<<", 3, ">>", 3, "+", 2, "-", 2, "*", 1, "/", 1, "//", 1, "**", 0,
    )

    toIsFunction:=Map("integer", "IsInteger", "float", "IsFloat", "number", "IsNumber", "digit", "IsDigit", "xdigit", "IsXDigit", "alpha", "IsAlpha", "upper", "IsUpper", "lower", "IsLower", "alnum", "IsAlnum", "space", "IsSpace", "time", "IsTime")

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
                if (currentArr.Length) {
                    switch currentArr[currentArr.Length].type {
                        case "function call":
                            currentArr[currentArr.Length].type:="function definition"
                            currentArr[currentArr.Length].body:={type:"block", statements:statements:=[]}
                            arrArr.Push(currentArr)
                            currentArr:=statements
                            skip_comments()
                            continue statements_loop
                        }
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
                if (arrArr.Length) {
                    lastArr:=arrArr[arrArr.Length]
                    if (lastArr.Length && lastArr[lastArr.Length].type == "switch") {
                        currentArr:=arrArr.Pop()
                    }
                }
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
                    } else if (toPush.type == "concat" && toPush.right.left.value = "is") {

                        maybeNot := toPush.right.right
                        if (maybeNot.type == "pre-unary" && maybeNot.op == "not") {
                            funcVar := maybeNot.right
                            funcVar.value := toIsFunction[StrLower(funcVar.value)]
                            toPush:={type: "group",value: {op: "!",right: {args: [toPush.left],func: funcVar,type: "function call"},type: "pre-unary"}}
                        } else {
                            funcVar := maybeNot
                            funcVar.value := toIsFunction[StrLower(funcVar.value)]
                            toPush:={type: "group",value: {args: [toPush.left],func: funcVar,type: "function call"}}
                        }

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
                commandStatement() {
                    if (InStr(",:=,+=,-=,*=,/=,//=,.=,|=,&=,^=,>>=,<<=,", "," OutputVar_operator.0 ",", true)) {
                        c_:=c1
                        skip_expression()
                    } else if (InStr(",++,--,", "," OutputVar_operator.0 ",", true)) {
                        if (InStr(OutputVar_comments.0, "`n", true)) {
                            ; MsgBox
                            ; ++2
                            add_command(OutputVar_varName.0, [])
                            return true ; continue statements_loop
                        } else {
                            ; MsgBox ++2
                            skip_commandArgs()
                        }
                    } else if (OutputVar_operator.0=="=") {
                        c_++
                        skip_comments()
                        out_v1str:=skip_v1str_noNeedToEscapeComma()
                        currentArr.Push({type:"binary",op:":=",left:{type:"variable",value: OutputVar_varName.0},right:v1str_to_expression(out_v1str)})
                    } else {
                        ; if it's unary plus, or *2, it's passed to MsgBox as v1str
                        skip_commandArgs()
                    }

                }
                switch char_ {
                    case "":
                        add_empty_command()
                        return
                    case ",":
                        if (char1=="#") {
                            ; directive
                            skip_directiveArgs()
                        } else {
                            skip_comments()
                            if (RegExMatch(str, "(*COMMIT)[&*+\-.\/:<=>^|]+", &OutputVar_operator, c_)) {
                                if (commandStatement()) {
                                    continue statements_loop
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
                    case "`n":
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
                                if (commandStatement()) {
                                    continue statements_loop
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
                    case " ", "`t":
                        if (char1=="#") {
                            ; directive
                            skip_directiveArgs()
                        } else if (OutputVar_varName.0="if") {
                            ifStatemement()
                        } else if (OutputVar_varName.0="class") {
                            skip_comments()
                            RegExMatch(str, "[a-zA-Z0-9_#@$\x80-\x{10ffff}]*", &OutputVar_className, c_)
                            c_+=OutputVar_className.Len
                            skip_comments()
                            char_:=SubStr(str, c_, 1)
                            if (char_=="{") {
                                currentArr.Push({type: "class",className:OutputVar_className.0})
                            } else {
                                MsgBox "class without {"
                            }
                        } else {
                            skip_comments()
                            if (RegExMatch(str, "(*COMMIT)[&*+\-.\/:<=>^|]+", &OutputVar_operator, c_)) {
                                if (commandStatement()) {
                                    continue statements_loop
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
                        ; RegExMatch(str, "(*COMMIT)[&*+\-.\/:<=>^|]+", &OutputVar_operator, c_)
                        RegExMatch(str, "(*COMMIT)[+\-*\/\.~^&|<!=>?:()\[\]{}]+", &OutputVar_operator, c_)
                        if (OutputVar_operator.0==":") {
                            ;label
                            c_++
                            labelName:=SubStr(str, c1, c_ - c1 - 1)
                            if (labelName = "default") {
                                switchStatements:=arrArr[arrArr.Length]
                                switchStatements.Push({type: "default", statements:statements:=[]})
                                currentArr:=statements
                                skip_comments()
                            } else {
                                currentArr.Push({type:"label", labelName:labelName})
                                labelBlockStart:=currentArr.Length + 1
                                skip_comments()
                            }
                        } else {
                            if (OutputVar_operator.0=="=") {
                                c_++
                                out_v1str:=skip_v1str_noNeedToEscapeComma()
                                currentArr.Push({type:"binary",op:":=",left:{type:"variable",value: OutputVar_varName.0},right:v1str_to_expression(out_v1str)})
                            } else {
                                ;assignment
                                c_:=c1
                                skip_expression()
                            }
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

        skip_comments()
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
                        out_v1str:=skip_v1str_commaDelim()
                        argsArr.Push({type: "directive arg", value: out_v1str})
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
            out_v1str:=skip_v1str_commaDelim()
            argsArr.Push({type: "directive arg", value: out_v1str})
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
                                OutputVar_comments_bak:="" ;SUPER WEIRD BUG WHERE OutputVar_comments.0 gets set to ""

                                ; expression only if followed by a \s, yes, \n works too
                                char_:=SubStr(str, c_ + 1, 1)
                                if (char_~="\s") {
                                    ; expression
                                    c_+=2
                                    toPush:=value_expression()
                                    OutputVar_comments_bak:=OutputVar_comments ;SUPER WEIRD BUG WHERE OutputVar_comments.0 gets set to ""
                                } else {
                                    ; v1str MsgBox %var%
                                    out_v1str:=skip_v1str_noNeedToEscapeComma()
                                    OutputVar_comments_bak:=OutputVar_comments ;SUPER WEIRD BUG WHERE OutputVar_comments.0 gets set to ""
                                    toPush:=v1str_to_expression(out_v1str)
                                }
                                if (aHotkeyWasFound) {
                                    break
                                }
                                if (InStr(OutputVar_comments_bak.0, "`n", true)) {
                                    break
                                }
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
                        out_v1str:=skip_v1str_commaDelim()
                        OutputVar_comments_bak:="" ;SUPER WEIRD BUG WHERE OutputVar_comments.0 gets set to ""
                        if (out_v1str~="^(?![.+]$)\+?\d*(?:\.\d*)?$") { ;regex: number
                            toPush:={type: "number", value: out_v1str}
                        } else if (argsArr.Length==1 || argsArr.Length==2) {
                            toPush:=v1str_to_expression(out_v1str)
                            cLoL:=cBak
                        } else if (argsArr.Length==3 && !(out_v1str~="^(?![.+]$)\+?\d*(?:\.\d*)?$")) {
                            c_:=cLoL
                            out_v1str:=skip_v1str_noNeedToEscapeComma()
                            OutputVar_comments_bak:=OutputVar_comments ;SUPER WEIRD BUG WHERE OutputVar_comments.0 gets set to ""
                            toPush:=v1str_to_expression(out_v1str)
                            argsArr.Pop()
                        } else {
                            c_:=cBak
                            out_v1str:=skip_v1str_noNeedToEscapeComma()
                            OutputVar_comments_bak:=OutputVar_comments ;SUPER WEIRD BUG WHERE OutputVar_comments.0 gets set to ""
                            toPush:=v1str_to_expression(out_v1str)
                        }
                        OutputVar_comments:=OutputVar_comments_bak ;SUPER WEIRD BUG WHERE OutputVar_comments.0 gets set to ""
                        if (aHotkeyWasFound) {
                            break
                        }
                        continue
                    }
                    argsArr.Push(toPush ? toPush : {type:"command empty arg"})
                    break bruh
                case "Sleep", "break"
                , "SetWinDelay", "SetControlDelay":
                    boolArr:=[0]
                case "Send","SendRaw","SendInput","SendPlay","SendEvent"
                ,"SendMode", "SetWorkingDir", "SetBatchLines", "ListLines"
                ,"Goto","Critical", "DetectHiddenWindows","SetTitleMatchMode","Click"
                ,"FileDelete":
                    boolArr:=[3]
                case "CoordMode","UrlDownloadToFile":
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
                    currentArrBak:=currentArr
                    toPush:=value_expression()
                    if (toPush) {
                        currentArrBak.Push(toPush)
                    } else {
                        MsgBox "var scope declaration but without expression??"
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
                case "loop":
                    char_:=SubStr(str, c_, 1)
                    switch char_ {
                        case "%":
                            ; expression only if followed by a \s, yes, \n works too
                            char_:=SubStr(str, c_ + 1, 1)
                            if (char_~="\s") {
                                ; expression
                                c_+=2
                                skip_comments()
                                toPush:=value_expression()
                            } else {
                                RegExMatch(str, "[^\s{,]+(?:[ \t]+[^; \t{,][^\s{,]*)*", &OutputVar_v1str, c_)
                                c_+=OutputVar_v1str.Len
                                toPush:=v1str_to_expression(OutputVar_v1str.0)
                                skip_comments()
                            }
                        case "{":
                            ; loop { forever

                            ;the label is a loop label, not a label: return pair
                            if (currentArr.Length && currentArr[currentArr.Length].type == "label") {
                                labelBlockStart:=0x7FFFFFFFFFFFFFFF ;largest int64
                            }
                            currentArr.Push({type:"loop with block1"})
                            return
                        ; no condition
                        default:
                            ; skip_v1str_commaBracketDelim()
                            RegExMatch(str, "[^\s{,]+(?:[ \t]+[^; \t{,][^\s{,]*)*", &OutputVar_v1str, c_)
                            c_+=OutputVar_v1str.Len
                            if (IsInteger(OutputVar_v1str.0)) {
                                toPush:={type: "number", value: Integer(OutputVar_v1str.0)}
                            } else {
                                toPush:={type: "number", value: 0}
                            }
                            skip_comments()

                    }
                    ;the label is a loop label, not a label: return pair
                    if (currentArr.Length && currentArr[currentArr.Length].type == "label") {
                        labelBlockStart:=0x7FFFFFFFFFFFFFFF ;largest int64
                    }
                    char_:=SubStr(str, c_, 1)
                    if (char_=="{") {
                        currentArr.Push({type:"loop with block2"})
                        currentArr.Push({type: "condition with block",expr:toPush})
                    } else {
                        currentArr.Push({type:"loop without block"})
                        currentArr.Push({type: "condition without block", expr: toPush})
                    }
                    return
                case "WinActivate", "WinHide"
                ,"Gui":
                    boolArr:=[2,2,2,3]
                case "WinGetTitle", "WinGetClass":
                    boolArr:=[0,2,2,2,3]
                case "WinGet":
                    boolArr:=[0,2,2,2,2,3]
                case "WinGetPos":
                    boolArr:=[1,1,1,1,2,2,2,3]
                case "WinWaitActive", "WinWaitNotActive":
                    boolArr:=[2,2,0,2,3]
                case "for":
                    var1:=value_expression()
                    char_:=SubStr(str, c_, 1)
                    switch char_ {
                        case ",":
                            c_++
                            skip_comments()
                            var2:=value_expression()
                            char2:=SubStr(str, c_, 1)
                            if (char2=="{") {
                                expression:=var2.right.right
                                currentArr.Push({type:"for with block", var1:var1, var2:var2.left, expression:expression})
                                return
                            } else {
                                expression:=var2.right.right
                                currentArr.Push({type:"for without block", var1:var1, var2:var2.left, expression:expression})
                                return
                            }
                        case "{":
                            expression:=var1.right.right
                            currentArr.Push({type:"for with block", var1:var1.left, var2:false, expression:expression})
                            return
                        default:
                            expression:=var1.right.right
                            currentArr.Push({type:"for without block", var1:var1.left, var2:false, expression:expression})
                            return
                    }
                case "switch":
                    SwitchValue:=value_expression()
                    if (SwitchValue.type !== "group") {
                        SwitchValue:={type: "group", value: SwitchValue}
                    }
                    ; ASSUME it is at "{"
                    c_++
                    ; arrArr.Push(currentArr, "consumable for first 'case'")
                    currentArr.Push({type:"switch", SwitchValue:SwitchValue, statements:statements:=[]})
                    arrArr.Push(currentArr, statements)
                    skip_comments()
                    return
                case "case":
                    CaseValues:=[]
                    loop {
                        CaseValues.Push(value_expression())
                        char_:=SubStr(str, c_, 1)
                        switch char_ {
                            case ":":
                                switchStatements:=arrArr[arrArr.Length]
                                switchStatements.Push({type: "case", CaseValues: CaseValues, statements:statements:=[]})
                                currentArr:=statements
                                c_++
                                skip_comments()
                                return
                            case ",":
                                c_++
                                skip_comments()
                        }
                    }
                case "SplitPath":
                    boolArr:=[0,1,1,1,1,1]
                case "Sort","FileRead":
                    boolArr:=[0,3]
                case "PostMessage":
                    boolArr:=[0,0,0,2,2,2,2,3]
                case "SendMessage":
                    boolArr:=[0,0,0,2,2,2,2,2,0]
                case "IfEqual","IfNotEqual","IfLess","IfLessOrEqual","IfGreater","IfGreaterOrEqual":
                    boolArr:=[0,2]
                case "StringSplit":
                    boolArr:=[0,0,2,3]
                case "ClipWait":
                    boolArr:=[0,0]
                case "StringReplace":
                    boolArr:=[0,0,2,2,3]
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
                                if (argNum == boolArr.Length) {
                                    break
                                }
                            } else {
                                ; v1str MsgBox %var%
                                if (argNum == boolArr.Length) {
                                    out_v1str:=skip_v1str_noNeedToEscapeComma()
                                    toPush:=v1str_to_expression(out_v1str)
                                    break
                                } else {
                                    out_v1str:=skip_v1str_commaDelim()
                                    OutputVar_comments_bak:=OutputVar_comments ;SUPER WEIRD BUG WHERE OutputVar_comments.0 gets set to ""
                                    toPush:=v1str_to_expression(out_v1str)
                                    OutputVar_comments:=OutputVar_comments_bak ;SUPER WEIRD BUG WHERE OutputVar_comments.0 gets set to ""
                                    if (InStr(OutputVar_comments.0, "`n", true)) {
                                        break
                                    }
                                    if (argNum == boolArr.Length) {
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
                    OutputVar_comments_bak:=OutputVar_comments ;SUPER WEIRD BUG WHERE OutputVar_comments.0 gets set to ""
                    switch boolArr[argNum] {
                        case 0:
                            toPush:=value_expression()
                            OutputVar_comments_bak:=OutputVar_comments ;SUPER WEIRD BUG WHERE OutputVar_comments.0 gets set to ""
                        case 1:
                            toPush:={type:"v2 pre-unary", op:"&", right:value_expression()}
                        case 2:
                            out_v1str:=skip_v1str_commaDelim()
                            OutputVar_comments_bak:=OutputVar_comments ;SUPER WEIRD BUG WHERE OutputVar_comments.0 gets set to ""
                            toPush:=v1str_to_expression(out_v1str)
                        case 3:
                            out_v1str:=skip_v1str_noNeedToEscapeComma()
                            OutputVar_comments_bak:=OutputVar_comments ;SUPER WEIRD BUG WHERE OutputVar_comments.0 gets set to ""
                            toPush:=v1str_to_expression(out_v1str)
                    }
                    OutputVar_comments:=OutputVar_comments_bak ;SUPER WEIRD BUG WHERE OutputVar_comments.0 gets set to ""
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
                add_command("MsgBox", argsArr)
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
                        currentArr.Push({type: "function call", func: {type:"double-deref", value:argsArr[1]}, args: []})
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
            case "WinGetTitle":
                currentArr.Push({type: "binary", op: ":=", left:argsArr.RemoveAt(1), right: {type: "function call", func: {type:"variable"
                , value:"WinGetTitle"}, args: argsArr}})
            case "WinGetClass":
                currentArr.Push({type: "binary", op: ":=", left:argsArr.RemoveAt(1), right: {type: "function call", func: {type:"variable"
                , value:"WinGetClass"}, args: argsArr}})
            case "WinGet":
                if (argsArr.Length == 1) {
                    winGetCommand:="WinGetID"
                } else if (argsArr[2].type == "command empty arg") {
                    argsArr.RemoveAt(2)
                    winGetCommand:="WinGetID"
                } else {
                    switch (argsArr.RemoveAt(2).value), 0 {
                        case "ID":
                            postFix:="ID"
                        case "IDLast":
                            postFix:="IDLast"
                        case "PID":
                            postFix:="PID"
                        case "ProcessName":
                            postFix:="ProcessName"
                        case "ProcessPath":
                            postFix:="ProcessPath"
                        case "Count":
                            postFix:="Count"
                        case "List":
                            postFix:="List"
                        case "MinMax":
                            postFix:="MinMax"
                        case "ControlList":
                            postFix:="ControlList"
                        case "ControlListHwnd":
                            postFix:="ControlListHwnd"
                        case "Transparent":
                            postFix:="Transparent"
                        case "TransColor":
                            postFix:="TransColor"
                        case "Style":
                            postFix:="Style"
                        case "ExStyle":
                            postFix:="ExStyle"
                    }
                    winGetCommand:="WinGet" postFix
                }
                currentArr.Push({type: "binary", op: ":=", left:argsArr.RemoveAt(1), right: {type: "function call", func: {type:"variable"
                , value:winGetCommand}, args: argsArr}})
            case "Sort":
                currentArr.Push({type: "binary", op: ":=", left:argsArr[1], right: {type: "function call", func: {type:"variable"
                , value:"Sort"}, args: argsArr}})
            case "FileRead":
                ; todo: *t -> `n
                ; todo: *m1024 -> m1024
                outVar := argsArr.RemoveAt(1)
                currentArr.Push({type: "binary", op: ":=", left:outVar, right: {type: "function call", func: {type:"variable"
                , value:"FileRead"}, args: argsArr}})
            case "StringReplace":
                outVar:=argsArr.RemoveAt(1)
                if (argsArr.Length >= 4) {
                    argsArr.RemoveAt(4)
                }
                currentArr.Push({type: "binary", op: ":=", left:outVar, right: {type: "function call", func: {type:"variable"
                , value:"StrReplace"}, args: argsArr}})
            case "IfEqual","IfNotEqual","IfLess","IfLessOrEqual","IfGreater","IfGreaterOrEqual":
                char3:=SubStr(str, c_, 1)
                switch char3 {
                    case ",":
                        add_command(OutputVar_varName.0, argsArr)
                        c_++
                        skip_comments()
                    case "{":
                        MsgBox "not implemented: block after IfEqual"
                    default:
                        MsgBox "not implemented: very unknown after IfEqual"
                }
            case "DetectHiddenWindows":
                if (argsArr[1].type == "string") {
                    switch (argsArr[1].value), 0 {
                        case "On":
                            argsArr[1]:={type:"variable",value:"true"}
                        case "Off":
                            argsArr[1]:={type:"variable",value:"false"}
                    }
                }
                add_command("DetectHiddenWindows", argsArr)
            case "UrlDownloadToFile":
                add_command("Download", argsArr)
            case "ClipWait":
                ; Specifying 0 is the same as specifying 0.5
                if (argsArr.Length >= 1 && argsArr[1].value == "0") {
                    argsArr[1].value:="0.5"
                }
                add_command("ClipWait", argsArr)
            default:
                add_command(OutputVar_varName.0, argsArr)

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
        aHotkeyWasFound:=backtrack_for_hotkey:=0

        ret_v1str:=""
        while (true) {
            RegExMatch(str, "(?:``,|[^\s,])+(?:[ \t]+[^; \t,](?:``,|[^\s,])*)*", &OutputVar_v1str, c_)
            if (A_Index > 1) {
                if (InStr(OutputVar_v1str.0, "::", true)) {
                    aHotkeyWasFound:=backtrack_for_hotkey:=c_
                    return ret_v1str
                }
                ret_v1str.=" "
            }
            ret_v1str.=OutputVar_v1str.0
            c_+=OutputVar_v1str.Len
            skip_comments()
            char_nl:=SubStr(str, c_, 1)
            switch char_nl {
                case "+", "-", "*", "/", ".", "~", "^", "&", "|", "<", "!", "=", ">", "?", ":":
                    continue
                default:
                    break
            }
        }
        unescaped:=StrReplace(ret_v1str, "``,", ",", true)
        return unescaped
    }

    skip_v1str_noNeedToEscapeComma() {
        aHotkeyWasFound:=backtrack_for_hotkey:=0

        ret_v1str:=""
        while (true) {
            RegExMatch(str, "[ \t]*([^\s\n]*([ \t]+[^; \t][^\s]*)*)", &OutputVar_v1str, c_)
            if (A_Index > 1) {
                if (InStr(OutputVar_v1str.1, "::", true)) {
                    aHotkeyWasFound:=backtrack_for_hotkey:=c_
                    return ret_v1str
                }
                ret_v1str.=" "
            }
            ret_v1str.=OutputVar_v1str.1
            c_+=OutputVar_v1str.Len[1]
            skip_comments()
            char_nl:=SubStr(str, c_, 1)
            switch char_nl {
                case ",", "+", "-", "*", "/", ".", "~", "^", "&", "|", "<", "!", "=", ">", "?", ":":
                    continue
                default:
                    break
            }
        }
        return ret_v1str
    }

    skip_expression() {
        currentArrBak:=currentArr
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
                currentArrBak.Push(toPush)
            }
            ; hotkey
        } else {
            currentArrBak.Push(toPush)
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
        ; hotkeys are values..
        RegExMatch(str, "(*COMMIT)[&*+\-.\/:<=>^|?()\[\]{}\.]+", &OutputVar_maybeHotkey, c_)
        if (OutputVar_maybeHotkey && SubStr(OutputVar_maybeHotkey.0, -2)=="::") {
            aHotkeyWasFound:=backtrack_for_hotkey:=c_ + OutputVar_maybeHotkey.Len
            return ""
        }

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
                    c_++
                    skip_comments()
                    elements:=[]
                    loop {
                        char_:=SubStr(str, c_, 1)
                        switch char_ {
                            case "]":
                                left:={type: "array", elements: elements}
                                c_++
                                break
                            case ",":
                                c_++
                                skip_comments()
                        }
                        elements.Push(value_expression())
                    }
                    break
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
                    twoChars:=SubStr(str, c_, 2)
                    switch twoChars {
                        case "++", "--":
                            c_+=2
                            op:=twoChars
                        default:
                            c_++
                            op:=char2
                    }
                    skip_comments()
                    bak_OutputVar_comments:=OutputVar_comments
                    right:=value_expression()
                    if (backtrack_for_hotkey) {
                        if (pos:=InStr(bak_OutputVar_comments.0, "`n", true)) {
                            backtrack_for_hotkey:=0
                            return left
                        } else {
                            return ""
                        }
                    }

                    ; unary should always take precedence over binary
                    if (right.type == "binary") {
                        left:={type:"pre-unary", op:op, right:right.left}
                        op:=right.op
                        right:=right.right

                        left:={type: "binary", op: op, left:left, right: right}
                        return left
                    } else {
                        left:={type: "pre-unary", op: op, right: right}
                    }
                    break
                case "n","N":
                    word_:=SubStr(str, c_, 3)
                    if (word_="not") {
                        c_+=3
                        skip_comments()
                        left:={type: "pre-unary", op: "not", right: value_expression()}
                        break
                    }
                }
            ; RegExMatch(str, "[a-zA-Z0-9_#@$\x80-\x{10ffff}]*", &OutputVar_variableName, c_)
            RegExMatch(str, "[%a-zA-Z0-9_#@$\x80-\x{10ffff}]*", &OutputVar_variableName, c_)
            ; left:=OutputVar_variableName.0
            if (OutputVar_variableName.0 ~= "(?i)^0x[0-9A-F]*$") {
                left:={type: "hex number", value: OutputVar_variableName.0}
            } else {
                if (OutputVar_variableName.0 ~= "^[0-9]*$") {
                    RegExMatch(str, "(?![.+]$)\+?\d*(?:\.\d*)?", &OutputVar_variableNameWhat, c_)
                    if (OutputVar_variableNameWhat.Len == 0) {
                        ; found nothing, attempt hotkey
                        RegExMatch(str, "(*COMMIT)[!&*+\-.\/:<=>^|?()\[\]{}\. a-zA-Z0-9_#@$]*?::", &OutputVar_attemptHotkey, c_)
                        if (OutputVar_attemptHotkey && SubStr(OutputVar_attemptHotkey.0, -2)=="::") {
                            aHotkeyWasFound:=backtrack_for_hotkey:=c_ + OutputVar_attemptHotkey.Len
                            return ""
                        } else {
                            MsgBox "what is this? parsing number here, c_:" c_
                        }
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
                                break
                            case ",":
                                args.push({type: "function call empty arg"})
                                c_++
                                skip_comments()
                            default:
                                args.Push(value_expression())
                                char_:=SubStr(str, c_, 1)
                                switch char_ {
                                    case ")":
                                        break
                                    case ",":
                                        c_++
                                        skip_comments()
                                }
                        }
                    }
                    left:={type: "function call", func: left, args: args}
                    c_++
                case "[":
                    ; array access or map access (same syntactically..)
                    c_++
                    skip_comments()
                    left:={type: "array access", parent: left, key: value_expression()}
                    c_++
                case ".":
                    ; property access
                    char_:=SubStr(str, c_ + 1, 1)
                    if (char_ == "=") { ; .=
                        left:=do_operator()
                    } else {
                        c_++
                        RegExMatch(str, "[a-zA-Z0-9_#@$\x80-\x{10ffff}]*", &OutputVar_variableName, c_)
                        c_+=OutputVar_variableName.Len
                        left:={type: "property access", parent: left, propName: OutputVar_variableName.0}
                    }
                default:
                    return do_operator()
            }
            do_operator() {
                cBakComments:=c_
                skip_comments()
                bak_OutputVar_comments:=OutputVar_comments
                char_:=SubStr(str, c_, 1)
                switch char_ {
                    case "+":
                        char2:=SubStr(str, c_ + 1, 1)
                        switch char2 {
                            case "+":
                                if (InStr(bak_OutputVar_comments.0, "`n", true)) {
                                    return left
                                }
                                c_+=2
                                skip_comments()
                                return {type:"post-unary assignment", left:left, op:"++"} ;post-increment
                            case "=":
                                return value_binary(left, "+=") ;add=>assign
                            default:
                                return value_binary(left, "+") ;add
                        }
                    case "-":
                        char2:=SubStr(str, c_ + 1, 1)
                        switch char2 {
                            case "-":
                                if (InStr(bak_OutputVar_comments.0, "`n", true)) {
                                    return left
                                }
                                c_+=2
                                skip_comments()
                                return {type:"post-unary assignment", left:left, op:"--"} ;post-decrement
                            case "=":
                                return value_binary(left, "-=") ;sub=>assign
                            default:
                                return value_binary(left, "-") ;sub
                        }
                    case "*":
                        char2:=SubStr(str, c_ + 1, 1)
                        switch char2 {
                            case "*":
                                return value_binary(left, "**") ;power
                            case "=":
                                return value_binary(left, "*=") ;mul=>assign
                            default:
                                return value_binary(left, "*") ;mul
                        }
                    case "/":
                        char2:=SubStr(str, c_ + 1, 1)
                        switch char2 {
                            case "/":
                                char3:=SubStr(str, c_ + 2, 1)
                                switch char3 {
                                    case "=":
                                        return value_binary(left, "//=") ;Floor divide=>assign
                                    default:
                                        return value_binary(left, "//") ;Floor divide
                                }
                            case "=":
                                return value_binary(left, "/=") ;True divide=>assign
                            default:
                                return value_binary(left, "/") ;True divide
                        }
                    case ".":
                        char2:=SubStr(str, c_ + 1, 1)
                        switch char2 {
                            case "=":
                                return value_binary(left, ".=") ;concat=>assign
                            default:
                                return value_binary(left, ".") ;concat
                        }
                    case "~":
                        char2:=SubStr(str, c_ + 1, 1)
                        switch char2 {
                            case "=":
                                return value_binary(left, "~=") ;regex match
                        }
                    case "^":
                        char2:=SubStr(str, c_ + 1, 1)
                        switch char2 {
                            case "=":
                                return value_binary(left, "^=") ;bitwise-exclusive-or=>assign
                            default:
                                return value_binary(left, "^") ;bitwise-exclusive-or
                        }
                    case "&":
                        char2:=SubStr(str, c_ + 1, 1)
                        switch char2 {
                            case "&":
                                return value_binary(left, "&&") ;logical-AND
                            case "=":
                                return value_binary(left, "&=") ;Bitwise-and=>assign
                            default:
                                return value_binary(left, "&") ;Bitwise-and
                        }
                    case "|":
                        char2:=SubStr(str, c_ + 1, 1)
                        switch char2 {
                            case "|":
                                return value_binary(left, "||") ;logical-OR
                            case "=":
                                return value_binary(left, "|=") ;bitwise-or=>assign
                            default:
                                return value_binary(left, "|") ;bitwise-or
                        }
                    case "<":
                        char2:=SubStr(str, c_ + 1, 1)
                        switch char2 {
                            case "<":
                                char3:=SubStr(str, c_ + 2, 1)
                                switch char3 {
                                    case "=":
                                        return value_binary(left, "<<=") ;Bit shift left=>assign
                                    default:
                                        return value_binary(left, "<<") ;Bit shift left
                                }
                            case ">":
                                return value_binary(left, "<>") ;not-equal
                            case "=":
                                return value_binary(left, "<=") ;less-or-equal
                            default:
                                return value_binary(left, "<") ;less
                        }
                    case "!":
                        char2:=SubStr(str, c_ + 1, 1)
                        switch char2 {
                            case "=":
                                return value_binary(left, "!=") ;not-equal
                        }
                        case "=":
                            char2:=SubStr(str, c_ + 1, 1)
                            switch char2 {
                                case "=":
                                    return value_binary(left, "==") ;case-sensitive-equal
                                default:
                                    return value_binary(left, "=") ;Equal
                            }
                        case ">":
                            char2:=SubStr(str, c_ + 1, 1)
                            switch char2 {
                                case ">":
                                    char3:=SubStr(str, c_ + 2, 1)
                                    switch char3 {
                                        case "=":
                                            return value_binary(left, ">>=") ;Bit shift right=>assign
                                        default:
                                            return value_binary(left, ">>") ;Bit shift right
                                    }
                                case "=":
                                    return value_binary(left, ">=") ;greater-or-equal
                                default:
                                    return value_binary(left, ">") ;greater
                            }
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
                    case ":":
                        char2:=SubStr(str, c_ + 1, 1)
                        switch char2 {
                            case ":":
                                aHotkeyWasFound:=backtrack_for_hotkey:=c_ + 2
                                return ""
                            case "=":
                                return value_binary(left, ":=") ;Assign
                            default:
                                return left ;ternary-colon, taken care of by "?"
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
                    ;new IObjectArray() -> IObjectArray()
                    if (left.type == "variable" && left.value = "new") {
                        return value_expression()
                    }
                    return {type: "concat", op: OutputVar_comments.0, left:left, right: value_expression()}
                }
                value_binary(left, op) {
                    c_+=StrLen(op)
                    skip_comments()

                    right:=value_expression()
                    if (backtrack_for_hotkey) {
                        if (pos:=InStr(bak_OutputVar_comments.0, "`n", true)) {
                            c1:=cBakComments + pos
                            backtrack_for_hotkey:=0
                            return left
                        } else {
                            return ""
                        }
                    }
                    if (right.type == "binary" && orderOfOperations[right.op] > orderOfOperations[op]) {
                        left:={type:"binary", op:op, left: left, right:right.left}
                        op:=right.op
                        right:=right.right
                    }
                    return {type: "binary", op: op, left:left, right: right}
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
            currentArr[currentArr.Length] := {type:"function definition",func:{type:"variable",value:currentArr[currentArr.Length].labelName},args:[],body:{type:"block",statements:blockArr}}
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
AHK_parse(str)

string_to_variable_or_prop(str) {
    loop parse str, "." {
        if (A_Index > 1) {
            parent:={type: "property access", parent: parent, propName: A_LoopField}
        } else {
            parent:={type:"variable", value:A_LoopField}
        }
    }
    return parent
}

HeaderCommands:=Map()
HeaderCommands.CaseSense:="Off"
HeaderCommands.Set("#SingleInstance",1,"ListLines",1,"SendMode",1,"SetWorkingDir",1,"KeyHistory",1)

superGlobalVarsMap:=Map()
superGlobalVarsMap.CaseSense:="Off"
superGlobalVarsMap.Set("A_ScriptDir", {vartype:"simply defined"}
    ,"A_Index",{vartype:"simply defined"}
    ,"A_MaxHotkeysPerInterval",{vartype:"simply defined"}
    ,"A_TimeSincePriorHotkey",{vartype:"simply defined"}
    ,"A_PriorHotkey",{vartype:"simply defined"}
    ,"A_ThisHotkey",{vartype:"simply defined"}
    ,"A_AhkPath",{vartype:"simply defined"}
    ,"A_IsAdmin",{vartype:"simply defined"}
    ,"A_IsCompiled",{vartype:"simply defined"}
    ,"A_LastError",{vartype:"simply defined"}
    ,"A_ScriptFullPath",{vartype:"simply defined"}
    ,"A_ScriptName",{vartype:"simply defined"}
    ,"A_Space",{vartype:"simply defined"}
    ,"A_Args",{vartype:"simply defined"}
    ,"A_PtrSize",{vartype:"simply defined"}
    ,"A_Clipboard",{vartype:"simply defined"}
    ,"ErrorLevel",{vartype:"simply defined"}
    ; bool
    ,"True",{vartype:"simply defined"}
    ,"False",{vartype:"simply defined"}
    ; functions
    ,"ComObject",{vartype:"simply defined"}
    ,"DllCall",{vartype:"simply defined"}
    ,"Buffer",{vartype:"simply defined"}
    ,"StrLen",{vartype:"simply defined"}
    ,"SubStr",{vartype:"simply defined"}
    ,"Floor",{vartype:"simply defined"}
    ,"FileOpen",{vartype:"simply defined"}
    ,"Format",{vartype:"simply defined"}
    ,"NumGet",{vartype:"simply defined"}
    ,"NumPut",{vartype:"simply defined"}
    ,"HasMethod",{vartype:"simply defined"}
    ,"StrPtr",{vartype:"simply defined"}
    ,"InStr",{vartype:"simply defined"}
    ,"StrGet",{vartype:"simply defined"}
    ,"ClipboardAll",{vartype:"simply defined"}
    ,"FileRead",{vartype:"simply defined"}
    ,"RegExMatch",{vartype:"simply defined"}
    ,"RegExReplace",{vartype:"simply defined"}
    ,"StrReplace",{vartype:"simply defined"}
)

walker_superGlobalVars() {
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
                    withNewline()
                case "class":
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
                        superGlobalVarsMap[v_.func.value]:={vartype:"simply defined"}
                    }
                    finalStr.=do(v_) " "
                    v_:=v_.body
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
                MsgBox "This Should Never Happen1: " t_
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
                case "array":
                    argsStr:=""
                    if (t_.elements.Length) {
                        argsStr.=do(t_.elements[1])
                        i_:=2, len:=t_.elements.Length + 1
                        while (i_<len) {
                            argsStr.=", " do(t_.elements[i_])
                            i_++
                        }
                    }
                    return "[" argsStr "]"
            }
        }
    }

}

walker_superGlobalVars()

globalVarsMap:=Map()
globalVarsMap.CaseSense:="Off"
globalFunctionIndices:=[]

walker_globalVars() {
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
                    finalStr.=v_.value " "
                    v_:=statements[++k_]
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
                    v_:=v_.body
                    withNewline()
                    if (indent=="") {
                        globalFunctionIndices.Push(k_)
                    }
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
                MsgBox "This Should Never Happen2: " t_
                return t_
            }
            switch t_.type {
                case "variable":
                    if (!superGlobalVarsMap.Has(t_.value)) {
                        globalVarsMap[t_.value]:={vartype:"simply defined"}
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
                case "array":
                    argsStr:=""
                    if (t_.elements.Length) {
                        argsStr.=do(t_.elements[1])
                        i_:=2, len:=t_.elements.Length + 1
                        while (i_<len) {
                            argsStr.=", " do(t_.elements[i_])
                            i_++
                        }
                    }
                    return "[" argsStr "]"
            }
        }
    }

}

walker_globalVars()

reservedVars := Map()
reservedVars.CaseSense := "Off"
reservedVars.Set(
    "in", "in_"
)

walker_replacer() {
    finalStr:=""
    indent:=""

    currentScope:=Map()
    currentScope.CaseSense:="Off"
    functionScopes:=[superGlobalVarsMap, currentScope]
    functionScopeNames:=["superGlobal", "normalGlobal"]

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

        addToScope(obj, key, varInfo) {
            t_:=Type(obj) == "Object" ? obj.%key% : obj[key]

            notVar:=t_
            if (notVar.type == "property access") {
                while (notVar.type == "property access") {
                    notVar:=notVar.parent
                }
                for _scope in functionScopes {
                    if (_scope.Has(notVar.value)) {
                        _scope[do(obj,key)]:=varInfo
                        break
                    }
                }
            } else {
                currentScope[t_.value]:=varInfo
            }

        }

        withNewline() {
            switch v_.type {
                case "command":
                    switch (v_._name), 0 {
                        case "Gui":
                            argsArr:=v_.args
                            arg1 := argsArr.RemoveAt(1).value
                            pos_colon := InStr(arg1, ":", true)
                            if (pos_colon) {
                                guiName:=SubStr(arg1, 1, pos_colon - 1)
                                guiCommand:=SubStr(arg1, pos_colon + 1)
                            } else {
                                guiName:="myGui"
                                guiCommand:=arg1
                            }

                            checkOptionsHwnd(optionsNode) {
                                if (optionsNode.type == "string") {
                                    RegExMatch(optionsNode.value, "i)\s*\+hwnd(\S*)", &OutputVar_hwnd:="")
                                    if (OutputVar_hwnd) {
                                        optionsNode.value:=SubStr(optionsNode.value, 1, OutputVar_hwnd.Pos - 1) SubStr(optionsNode.value, OutputVar_hwnd.Pos + OutputVar_hwnd.Len)
                                        return OutputVar_hwnd.1
                                    }
                                }
                                return false
                            }
                            if (!currentScope.Has(guiName)) {
                                if (guiCommand="New") {
                                    guiHwnd:=checkOptionsHwnd(argsArr[1])
                                    if (guiHwnd) {
                                        currentScope[guiHwnd]:={vartype:"Gui Hwnd",guiName:guiName}
                                    }
                                    newGuiArgs:=argsArr
                                } else {
                                    newGuiArgs:=[]
                                }
                                v_:={left:{type:"variable", value:guiName}, op:":=", right:{args:newGuiArgs, func:{type:"variable", value:"Gui"}, type:"function call"}, type:"binary"}
                                if (guiCommand="New") {
                                    statements[k_]:=v_
                                    withNewline()
                                } else {
                                    statements.InsertAt(k_, v_)
                                    withNewline()
                                    k_++, statements_len++
                                    v_:=statements[k_]
                                }
                            }
                            switch (guiCommand), 0 {
                                ; case "New":
                                    ; checkOptionsHwnd(argsArr[1])
                                case "Add":
                                    control_hwnd:=checkOptionsHwnd(argsArr[2])
                                    if (control_hwnd) {
                                        v_:=statements[k_]:={left:{type:"variable", value:control_hwnd}, op:":=", right:{args:argsArr, func:{parent:{type:"variable", value:guiName}, propName:"Add", type:"property access"}, type:"function call"}, type:"binary"}
                                        withNewline()
                                        currentScope[control_hwnd]:={vartype:"Gui Control Hwnd"}
                                        return
                                    }
                                    v_:=statements[k_]:={args:argsArr, func:{parent:{type:"variable", value:guiName}, propName:"Add", type:"property access"}, type:"function call"}
                                    withNewline()
                                case "Show":
                                    if (argsArr.Length == 2) {
                                        v_:={left:{parent:{type:"variable", value:guiName}, propName:"Title", type:"property access"}, op:":=", right:argsArr.Pop(), type:"binary"}
                                        statements.InsertAt(k_, v_)
                                        withNewline()
                                        k_++, statements_len++
                                    }
                                    v_:=statements[k_]:={args:argsArr, func:{parent:{type:"variable", value:guiName}, propName:"Show", type:"property access"}, type:"function call"}
                                    withNewline()
                                case "Submit":
                                case "Cancel":
                                case "Destroy":
                                    v_:=statements[k_]:={args:argsArr, func:{parent:{type:"variable", value:guiName}, propName:"Destroy", type:"property access"}, type:"function call"}
                                    withNewline()
                                case "Font":
                                    v_:=statements[k_]:={args:argsArr, func:{parent:{type:"variable", value:guiName}, propName:"SetFont", type:"property access"}, type:"function call"}
                                    withNewline()
                                case "Color":
                                case "Margin":
                                case "Options":
                                case "Menu":
                                case "Minimize":
                                case "Flash":
                                case "Default":
                            }
                            return
                        case "IfEqual","IfNotEqual","IfLess","IfLessOrEqual","IfGreater","IfGreaterOrEqual":
                            next:=statements[k_ + 1]
                            if (next.type == "command") {
                                statements[k_] := {type:"if without block"}
                                k_++
                                do(v_.args, 2) ;if there's a Line from File.ReadLine() -> Line "`n"
                                switch (v_._name), 0 {
                                    case "IfEqual":
                                        op:="=="
                                    case "IfNotEqual":
                                        op:="!=="
                                    case "IfLess":
                                        op:="<"
                                    case "IfLessOrEqual":
                                        op:="<="
                                    case "IfGreater":
                                        op:=">"
                                    case "IfGreaterOrEqual":
                                        op:=">="
                                }
                                statements.InsertAt(k_, {type:"group",value:{type:"binary",op:op,left:v_.args[1],right:v_.args[2]}})
                                k_++, statements_len++
                                v_:=statements[k_]
                                return
                            }
                        case "StringSplit":
                            statements[k_] := {type:"binary",op:":=",left:v_.args.RemoveAt(1),right:{type:"function call",func:{type:"variable",value:"StrSplit"},args:v_.args}}
                            outVarName:=statements[k_].left.value
                            currentScope[outVarName]:={vartype:"StringSplit root"}
                            currentScope[outVarName "%A_Index%"]:={vartype:"StringSplit Element"}
                    }
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
                    if (k_ + 1 <= statements.Length && statements[k_ + 1].type == "block") {
                        globalFunctionIndices.Push(k_ + 1)
                    }
                    finalStr.=v_.keyName
                case "property access","array access","group","pre-unary", "post-unary assignment", "binary","function call", "ternary"
                , "comma multi-statement", "concat":
                    finalStr.=do(statements, k_) "`n"
                case "var scope declaration":
                    finalStr.=v_.value " "
                    v_:=statements[++k_]
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
                case "class":
                    finalStr.="class " v_.className " "
                    currentScope:=Map()
                    currentScope.CaseSense:="Off"
                    currentScope["this"]:={vartype:"simply defined"} ;`this` isn't global, but should be defined in `class`
                    functionScopes.Push(currentScope)
                    functionScopeNames.Push(v_.className)

                    v_:=statements[++k_]

                    isStatic:=true
                    for possiblyFunc in v_.statements {
                        if (possiblyFunc.type == "function definition") {
                            currentScope[possiblyFunc.func.value] := {vartype:"function inside class"}
                            switch (possiblyFunc.func.value), 0 {
                                case "__New", "__Delete":
                                    isStatic:=false
                                    ; break ;do not break because `__Get`
                                case "__Get", "__Call":
                                    ; `__Get(a)` -> `__Set(a, Params)`
                                    ; `__Call(a)` -> `__Call(a, Params)`
                                    if (possiblyFunc.args.Length == 1) {
                                        possiblyFunc.args.Push({type:"variable",value:"Params"})
                                    }
                                case "__Set":
                                    ; `__Set(a, b)` -> `__Set(a, Params, b)`
                                    if (possiblyFunc.args.Length == 2) {
                                        possiblyFunc.args.InsertAt(2, {type:"variable",value:"Params"})
                                    }
                            }
                        }
                    }
                    if (isStatic) {
                        class_statements_len:=v_.statements.Length
                        class_statements_idx:=class_statements_len
                        while (class_statements_idx > 0) {
                            possiblyFunc:=v_.statements[class_statements_idx]
                            if (possiblyFunc.type == "function definition") {
                                v_.statements.InsertAt(class_statements_idx, {type:"var scope declaration", value: "static"})
                            }
                            class_statements_idx--
                        }
                    }
                    withNewline()

                    functionScopeNames.Pop()
                    currentScope:=functionScopes.Pop()
                case "function definition":
                    currentScope:=Map()
                    currentScope.CaseSense:="Off"
                    functionScopes.Push(currentScope)
                    functionScopeNames.Push(v_.func.value)

                    for argIdx, e_ in v_.args {
                        switch e_.type {
                            case "binary":
                                if (e_.op == "=") {
                                    e_.op := ":="
                                }
                                addToScope(e_, "left", {vartype:"simply defined"})
                            case "variable":
                                addToScope(v_.args, argIdx, {vartype:"simply defined"})
                            default:
                                MsgBox "Parameter not anything jitj430j043j"
                        }
                    }

                    finalStr.=do(statements, k_) " "

                    v_:=v_.body
                    withNewline()

                    functionScopeNames.Pop()
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

            checkVarInfoBothPropAcessAndVar(varInfo, obj, key) {
                switch varInfo.vartype {
                    case "ReadLine Line":
                        ; var -> var "`n"
                        replacement:={left:t_, op:" ", right:{type:"string", value:"``n"}, type:"concat"}
                        if (Type(obj) == "Object") {
                            obj.%key%:=replacement
                        } else {
                            obj[key]:=replacement
                        }
                    case "two param ComObject is Ptr", "ComObjQuery is Ptr":
                        ; var -> var.Ptr
                        replacement:={type: "property access", parent: t_, propName: "Ptr"}
                        if (Type(obj) == "Object") {
                            obj.%key%:=replacement
                        } else {
                            obj[key]:=replacement
                        }
                    default:
                        return false
                }
                return true
            }

            t_:=Type(obj) == "Object" ? obj.%key% : obj[key]
            if (Type(t_)=="String") {
                MsgBox "This Should Never Happen3: " t_
                return t_
            }
            switch t_.type {
                case "command empty arg", "function call empty arg":
                    return ""
                case "variable":
                    switch (t_.value), 0 {
                        case "A_LoopFileFullPath":
                            t_.value:="A_LoopFilePath"
                        case "A_LoopFileLongPath":
                            t_.value:="A_LoopFileFullPath"
                        case "Clipboard":
                            t_.value:="A_Clipboard"
                        case "ClipboardAll":
                            replacement:={args:[],func:{type:"variable",value:"ClipboardAll"},type:"function call"}
                            if (Type(obj) == "Object") {
                                obj.%key%:=replacement
                            } else {
                                obj[key]:=replacement
                            }
                        case "Comspec":
                            t_.value:="A_ComSpec"
                        default:
                            for _scope in functionScopes {
                                if (_scope.Has(t_.value)) {
                                    varInfo:=_scope[t_.value]
                                    switch varInfo.vartype {
                                        case "WinGetList Array":
                                            ; ids -> ids.Length
                                            replacement:={type: "property access", parent: t_, propName: "Length"}
                                            if (Type(obj) == "Object") {
                                                obj.%key%:=replacement
                                            } else {
                                                obj[key]:=replacement
                                            }
                                        case "WinGetList Element":
                                            ; ids%A_Index% -> ids[A_Index]
                                            replacement:={type: "array access", parent: {type: "variable", value: SubStr(t_.value, 1, -9)}, key: {type: "variable", value: "A_Index"}}
                                            if (Type(obj) == "Object") {
                                                obj.%key%:=replacement
                                            } else {
                                                obj[key]:=replacement
                                            }
                                        case "StringSplit Element":
                                            ; r%A_Index% -> r[A_Index]
                                            replacement:={type:"array access",parent:{type:"variable",value:SubStr(t_.value,1,-9)},key:{type:"variable",value:"A_Index"}}
                                            if (Type(obj) == "Object") {
                                                obj.%key%:=replacement
                                            } else {
                                                obj[key]:=replacement
                                            }
                                        case "Gui Hwnd":
                                            ; HWndExplanation_Gui -> myGui.Hwnd
                                            replacement:={type: "property access", parent: {type:"variable", value:varInfo.guiName}, propName: "Hwnd"}
                                            if (Type(obj) == "Object") {
                                                obj.%key%:=replacement
                                            } else {
                                                obj[key]:=replacement
                                            }
                                        case "Gui Control Hwnd":
                                            ; HWndExplanation_Edit -> HWndExplanation_Edit.Hwnd
                                            replacement:={type: "property access", parent: t_, propName: "Hwnd"}
                                            if (Type(obj) == "Object") {
                                                obj.%key%:=replacement
                                            } else {
                                                obj[key]:=replacement
                                            }
                                        case "rename":
                                            t_.value := varInfo.replaceWith_
                                        case "RegexMatch root uninitialized":
                                            varInfo.vartype := "RegexMatch root"
                                            break
                                        case "RegexMatch root":
                                            ; o -> o.0
                                            replacement:={type:"property access",parent:{type:"variable",value:rtrimmedIntegers},propName:"0"}
                                            if (Type(obj) == "Object") {
                                                obj.%key%:=replacement
                                            } else {
                                                obj[key]:=replacement
                                            }
                                            t_.value := t_.value ".0"
                                            break
                                        default:
                                            if (checkVarInfoBothPropAcessAndVar(varInfo, obj, key)) {
                                                break
                                            }
                                            if (reservedVars.Has(t_.value)) {
                                                replaceWith_:=defaultReplaceWith:=reservedVars[t_.value]
                                                iterator:=2
                                                ; doesn't take care of "future" variables...
                                                outer2:
                                                loop {
                                                    for _scope in functionScopes {
                                                        if (_scope.Has(replaceWith_)) {
                                                            replaceWith_:=defaultReplaceWith iterator
                                                            iterator++
                                                            continue outer2
                                                        }
                                                    }
                                                    ; it's fine, we can use this name
                                                    _scope[t_.value] := {varType:"rename",replaceWith_:replaceWith_} ;redirect to renamed
                                                    t_.value := replaceWith_
                                                    break outer2
                                                }
                                            }
                                    }
                                    break
                                }

                                ; RegExMatch(t_.value, "(?:[0-9]*[^0-9]+)*")
                                ; 32fjweo23423423ifjwe0323 -> 32fjweo23423423ifjwe
                                ; fjweo23423423ifjwe0323 -> fjweo23423423ifjwe
                                rtrimmedIntegers:=RTrim(t_.value, "0123456789")
                                if (_scope.Has(rtrimmedIntegers)) {
                                    switch _scope[rtrimmedIntegers].vartype {
                                        case "StringSplit root":
                                            integerOnTheRight:=SubStr(t_.value, StrLen(rtrimmedIntegers) + 1)
                                            if (integerOnTheRight=="0") {
                                                ; r0 -> r.Length
                                                replacement:={type:"property access",parent:{type:"variable",value:rtrimmedIntegers},propName:"Length"}
                                                if (Type(obj) == "Object") {
                                                    obj.%key%:=replacement
                                                } else {
                                                    obj[key]:=replacement
                                                }
                                            } else {
                                                ; r2 -> r[2]
                                                replacement:={type:"array access",parent:{type:"variable",value:rtrimmedIntegers},key:{type:"number",value:Integer(integerOnTheRight)}}
                                                if (Type(obj) == "Object") {
                                                    obj.%key%:=replacement
                                                } else {
                                                    obj[key]:=replacement
                                                }
                                            }
                                        case "RegexMatch root":
                                            integerOnTheRight:=SubStr(t_.value, StrLen(rtrimmedIntegers) + 1)
                                            ; o1 -> o.1
                                            replacement:={type:"property access",parent:{type:"variable",value:rtrimmedIntegers},propName:integerOnTheRight}
                                            if (Type(obj) == "Object") {
                                                obj.%key%:=replacement
                                            } else {
                                                obj[key]:=replacement
                                            }
                                            t_.value := t_.value "." integerOnTheRight
                                    }
                                }
                            }
                    }
                    return t_.value
                case "directive arg", "number", "hex number", "obj key":
                    return t_.value
                case "double-deref":
                    return "%" do(t_, "value") "%"
                case "string":
                    return "`"" t_.value "`""
                case "first var scope":
                    return do(t_, "value")
                case "property access":
                    notValueButString:=do(t_, "parent") "." t_.propName
                    for _scope in functionScopes {
                        if (_scope.Has(notValueButString)) {
                            varInfo:=_scope[notValueButString]
                            checkVarInfoBothPropAcessAndVar(varInfo, obj, key)
                            break
                        }
                    }
                    return notValueButString
                case "array access":
                    ;the order of this may cause problems
                    return do(t_, "parent") "[" do(t_, "key") "]"
                case "group":
                    return "(" do(t_, "value") ")"
                case "pre-unary":
                    if (t_.op == "&") {
                        _var:=t_.right
                        ; while (_var.type == "binary") {
                            ; obj:=_var, key:="left"
                            ; _var:=_var.left
                        ; }
                        ; needs order of operations ?
                        ; incorrect: unary(sum(buf, var))
                        ; correct: sum(unary(buf), var))
                        ; &buf + var
                        ; ->
                        ; buf.Ptr + var
                        for _scope in functionScopes {
                            if (_scope.Has(_var.value)) {
                                switch _scope[_var.value].vartype {
                                    case "string so StrPtr", "simply defined": ;Parameter defaults to string
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
                                            if (obj.type == "binary" && (obj.op == "+" || obj.op == "-")) {
                                                _var:={type: "property access", parent: _var, propName: "Ptr"}
                                            }
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
                    doNotTouchLeft:=do(t_, "left")
                    doNotTouchRight:=do(t_, "right")
                    if (t_.op == ":=") {
                        switch t_.right.type {
                            case "string", "concat":
                                currentScope[doNotTouchLeft]:={vartype:"string so StrPtr"}
                            case "function call":
                                loop 1 {
                                    switch t_.right.func.type {
                                        case "variable":
                                            switch t_.right.func.value, 0 {
                                                case "ComObjCreate":
                                                    if (t_.right.args.Length == 2) {
                                                        addToScope(t_, "left", {vartype:"two param ComObject is Ptr"})
                                                        break
                                                    }
                                                case "ComObjQuery":
                                                    addToScope(t_, "left", {vartype:"ComObjQuery is Ptr"})
                                                    break
                                                }
                                    }
                                    currentScope[doNotTouchLeft]:={vartype:"simply defined"}
                                }
                            default:
                                currentScope[doNotTouchLeft]:={vartype:"simply defined"}
                            ; SubStr too
                        }
                        switch t_.left.type {
                            case "property access":
                                if (t_.left.parent.type == "variable" && t_.left.parent.value = "this") {
                                    s_ := functionScopeNames.Length
                                    while (s_ > 2) {
                                        if (functionScopeNames[s_] == "__New" && (functionScopes[s_ - 1].Has("__Get") || functionScopes[s_ - 1].Has("__Set")) ) {
                                            replacement:={args:[{type:"string",value:t_.left.propName},{keys:[{type:"obj key",value:"value"}],type:"object",values:[t_.right]}],func:{parent:{type:"variable",value:"this"},propName:"DefineProp",type:"property access"},type:"function call"}
                                            if (Type(obj) == "Object") {
                                                obj.%key%:=replacement
                                            } else {
                                                obj[key]:=replacement
                                            }
                                            break
                                        }
                                        s_--
                                    }

                                }

                        }
                    }
                    return doNotTouchLeft " " t_.op " " doNotTouchRight
                case "comma multi-statement":
                    return do(t_, "left") ", " do(t_, "right")
                case "ternary":
                    ; A_PtrSize ? "UPtr" : "UInt" -> "Ptr"
                    ; A_PtrSize ? "UPtr*" : "UInt*" -> "Ptr*"
                    loop 1 {
                        if (t_.condition.type == "variable" && t_.condition.value = "A_PtrSize"
                        && t_.ifTrue.type == "string" && t_.ifFalse.type == "string") {
                            if (t_.ifTrue.value = "UPtr" && t_.ifFalse.value = "UInt") {
                                replacement:={type:"string",value:"Ptr"}
                            } else if ((t_.ifTrue.value = "UPtr*" || t_.ifTrue.value = "UPtrP")
                            && (t_.ifFalse.value = "UInt*" || t_.ifFalse.value = "UIntP")) {
                                replacement:={type:"string",value:"Ptr*"}
                            } else {
                                break
                            }
                            if (Type(obj) == "Object") {
                                obj.%key%:=replacement
                            } else {
                                obj[key]:=replacement
                            }
                        }
                    }
                    return do(t_, "condition") " ? " do(t_, "ifTrue") " : " do(t_, "ifFalse")
                case "concat":
                    return do(t_, "left") (t_.op == "" ? " " : t_.op) do(t_, "right")
                case "function call":
                    switch t_.func.type {
                        case "variable":
                            switch t_.func.value, 0 {
                                case "VarSetCapacity":
                                    var_:=t_.args.RemoveAt(1)
                                    currentScope[var_.value]:={vartype:"Buffer with Ptr"}
                                    replacement:={left:var_, op:":=", right:{args:t_.args, func:{type:"variable", value:"Buffer"}, type:"function call"}, type:"binary"}
                                    if (Type(obj) == "Object") {
                                        obj.%key%:=replacement
                                    } else {
                                        obj[key]:=replacement
                                    }
                                case "ComObjCreate":
                                    t_.func.value := "ComObject"
                                case "Func":
                                    switch t_.args[1].Type {
                                        case "string":
                                            ; `Func("foo")` -> `foo`
                                            replacement:=string_to_variable_or_prop(t_.args[1].value)
                                            default:
                                            ; `Func(strVar)` -> %strVar%
                                            replacement:={type:"double-deref",value:t_.args[1]}
                                    }
                                    if (Type(obj) == "Object") {
                                        obj.%key%:=replacement
                                    } else {
                                        obj[key]:=replacement
                                    }
                                case "IsFunc":
                                    ; https://www.autohotkey.com/boards/viewtopic.php?style=19&f=13&t=96863#p431844
                                    replacement:={args:[{type:"double-deref", value:t_.args[1]}], func:{type:"variable", value:"HasMethod"}, type:"function call"}
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
                                        case 1:
                                            replacementArr:=[t_.args[1], {type:"number", value:0}, {type:"string", value:"Ptr"}]
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

                                        do(t_.args, i_) ;do some replacements before checking...

                                        if (t_.args[i_].type == "variable") {
                                            t_.args[i_].type:="string"
                                        }
                                        ; like: A_PtrSize ? "UPtr" : "UInt"

                                        switch SubStr(t_.args[i_].value, -1), 0 {
                                            case "*", "P":
                                                switch t_.args[i_ + 1].type {
                                                    case "variable":
                                                        t_.args[i_ + 1]:={type:"v2 pre-unary",op:"&",right:{type:"binary",op:":=",left:t_.args[i_ + 1],right:{type:"number",value:0}}}
                                                    case "binary":
                                                        if (t_.args[i_ + 1].op == ":=") {
                                                            t_.args[i_+ 1]:={type:"v2 pre-unary", op:"&", right:t_.args[i_ + 1]}
                                                        }
                                                }
                                        }

                                        i_+=2
                                    }

                                case "RegisterCallback":
                                    t_.func.value:="CallbackCreate"
                                    t_.args[1]:=string_to_variable_or_prop(t_.args[1].value)
                                case "WinGetList":
                                    if (obj.type == "binary") {
                                        currentScope[obj.left.value]:={vartype:"WinGetList Array"}
                                        currentScope[obj.left.value "%A_Index%"]:={vartype:"WinGetList Element"}
                                    }
                                case "InStr":
                                    if (t_.args.Length >= 3 && t_.args[3].type == "function call empty arg") {
                                        t_.args[3]:={type:"variable", value:"false"}
                                    }
                                    ; `Instr("a","b")` -> `("b" == "" || Instr("a", "b"))`
                                    replacement:={type:"group",value:{left:{left:t_.args[2],op:"==",right:{type:"string",value:""},type:"binary"},op:"||",right:t_,type:"binary"}}
                                    if (Type(obj) == "Object") {
                                        obj.%key%:=replacement
                                    } else {
                                        obj[key]:=replacement
                                    }
                                case "RegexMatch":
                                    if (t_.args.Length >= 3) {
                                        outVarName:=t_.args[3].value
                                        currentScope[outVarName]:={vartype:"RegexMatch root uninitialized"}
                                        t_.args[3] := {type:"v2 pre-unary", op:"&", right:t_.args[3]}
                                    }
                            }
                        case "property access":
                            switch t_.func.propName, 0 {
                                case "ReadLine":
                                    if (obj.type == "binary") {
                                        addToScope(obj.left, "value", {vartype:"ReadLine Line"})
                                    }
                                case "Length", "Count":
                                    ; `.Length()` -> `.Length`
                                    ; `.Count()` -> `.Count`
                                    replacement:=t_.func
                                    if (Type(obj) == "Object") {
                                        obj.%key%:=replacement
                                    } else {
                                        obj[key]:=replacement
                                    }
                                case "HasKey":
                                    ; `.HasKey()` -> `.Has()`
                                    t_.func.propName:="Has"
                                case "SetCapacity":
                                    if (t_.args.Length > 1) {
                                        ; Object.SetCapacity(Key, ByteSize)
                                        ; `this.SetCapacity("a",7)` -> `this.a := Buffer(7)`
                                        ; replacement:={left:{type: "property access", parent: t_.func.parent, propName: t_.args[1].value}, op:":=", right:{args:[t_.args[2]], func:{type:"variable", value:"Buffer"}, type:"function call"}, type:"binary"}
                                        ; `this.SetCapacity("a",7)` -> `this.DefineProp("a", {value: Buffer(7)})`
                                        replacement:={args:[t_.args[1],{keys:[{type:"obj key",value:"value"}],type:"object",values:[{args:[t_.args[2]],func:{type:"variable",value:"Buffer"},type:"function call"}]}],func:{parent:{type:"variable",value:"this"},propName:"DefineProp",type:"property access"},type:"function call"}
                                        if (Type(obj) == "Object") {
                                            obj.%key%:=replacement
                                        } else {
                                            obj[key]:=replacement
                                        }
                                    } else {
                                        replacement:={left:{type: "property access", parent: t_.func.parent, propName: "Capacity"}, op:":=", right:t_.args[1], type:"binary"}
                                        if (Type(obj) == "Object") {
                                            obj.%key%:=replacement
                                        } else {
                                            obj[key]:=replacement
                                        }
                                    }
                                case "GetAddress":
                                    ; Ptr := Object.GetAddress(Key)
                                    ; `this.GetAddress("a")` -> `this.a.Ptr`
                                    ; replacement:={type: "property access", parent: {type: "property access", parent: t_.func.parent, propName: t_.args[1].value}, propName: "Ptr"}
                                    ; `this.GetAddress("a")` -> `(this.HasOwnProp("a") ? this.GetOwnPropDesc("a") : "")`
                                    ; replacement:={type:"group",value:{condition:{args:[t_.args[1]],func:{parent:{type:"variable",value:"this"},propName:"HasOwnProp",type:"property access"},type:"function call"},ifFalse:{type:"string",value:""},ifTrue:{args:[t_.args[1]],func:{parent:{type:"variable",value:"this"},propName:"GetOwnPropDesc",type:"property access"},type:"function call"},type:"ternary"}}
                                    replacement:={type:"group",value:{condition:{args:[t_.args[1]],func:{parent:{type:"variable",value:"this"},propName:"HasOwnProp",type:"property access"},type:"function call"},ifFalse:{type:"string",value:""},ifTrue:{parent:{parent:{args:[t_.args[1]],func:{parent:{type:"variable",value:"this"},propName:"GetOwnPropDesc",type:"property access"},type:"function call"},propName:"value",type:"property access"},propName:"Ptr",type:"property access"},type:"ternary"}}

                                    if (Type(obj) == "Object") {
                                        obj.%key%:=replacement
                                    } else {
                                        obj[key]:=replacement
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
                    } else {
                        ; {} -> Map()
                        replacement:={args:[],func:{type:"variable",value:"Map"},type:"function call"}
                        if (Type(obj) == "Object") {
                            obj.%key%:=replacement
                        } else {
                            obj[key]:=replacement
                        }
                        return do(obj,key)
                    }
                    return "{" argsStr "}"
                case "array":
                    argsStr:=""
                    if (t_.elements.Length) {
                        argsStr.=do(t_.elements, 1)
                        i_:=2, len:=t_.elements.Length + 1
                        while (i_<len) {
                            argsStr.=", " do(t_.elements, i_)
                            i_++
                        }
                    }
                    return "[" argsStr "]"
            }
            MsgBox "Switch .type not matched {okerihji325928} : " t_.type
        }
    }

}
walker_replacer()

walker_undefinedVars() {
    finalStr:=""
    indent:=""
    functionScopes:=[superGlobalVarsMap]
    _currentIndices:="" ;declare
    currentScope:="" ;declare
    undefinedVarsMap:="" ;declare

    takesIndices(globalFunctionIndices, currentArr)
    takesIndices(notCurrentIndices, notCurrentArr) {
        for i_ in notCurrentIndices {
            if (notCurrentArr[i_].type=="block") {
                blockObj:=notCurrentArr[i_]
            } else {
                blockObj:=notCurrentArr[i_].body
            }
            _currentIndices:=[]

            currentScope:=Map()
            currentScope.CaseSense:="Off"
            functionScopes.Push(currentScope)


            if (notCurrentArr[i_].type=="function definition") {
                ;parameters are also declared variables
                for param in notCurrentArr[i_].args {
                    switch param.type {
                        case "variable":
                            currentScope[param.value]:={vartype:"simply defined"}
                        case "binary":
                            currentScope[param.left.value]:={vartype:"simply defined"}
                    }
                }
            }

            undefinedVarsMap:=Map()
            undefinedVarsMap.CaseSense:="Off"

            for k_, v_ in blockObj.statements {
                if (v_.type=="function definition") {
                    _currentIndices.Push(k_)
                    if (v_.func.type=="variable") {
                        currentScope[v_.func.value]:={vartype:"simply defined"}
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

                toInsert:=[]
                for k_ in undefinedVarsMap {
                    if (!superGlobalVarsMap.Has(k_)) {
                        superGlobalVarsMap[k_]:=k_
                        toInsert.Push({left:{type:"variable",value:k_},op:":=",right:{type:"string",value:""},type:"binary"})
                    }
                }
                if (toInsert.Length) {
                    for insertIdx, obj in currentArr {
                        if (obj.type == "command" && HeaderCommands.Has(obj._name)) {
                        } else {
                            currentArr.InsertAt(insertIdx, toInsert*)
                            break
                        }
                    }
                }


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
                case "class":
                    ; currentScope["this"]:={vartype:"simply defined"} ;`this` isn't global, but should be defined in `class`
                    ; this:=3
                    ; MsgBox % this ;3
                case "function definition":
                    finalStr.=do(statements, k_) " "
                    v_:=v_.body
                    withNewline()
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
                MsgBox "This Should Never Happen4: " t_
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
                            currentScope[t_.value]:={vartype:"simply defined"}
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
                            currentScope[t_.right.value]:={vartype:"simply defined"}
                        case "binary":
                            left_:=t_.right.left
                            if (left_.type == "variable") {
                                currentScope[left_.value]:={vartype:"simply defined"}
                            }
                    }
                    return t_.op do(t_, "right")
                case "post-unary assignment":
                    return do(t_, "left") t_.op
                case "binary":
                    doNotTouchRight:=do(t_, "right")
                    if (t_.op==":=") {
                        if (t_.left.type=="variable") {
                            currentScope[t_.left.value]:={vartype:"simply defined"}
                        }
                    }
                    return do(t_, "left") " " t_.op " " doNotTouchRight
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
                case "array":
                    argsStr:=""
                    if (t_.elements.Length) {
                        argsStr.=do(t_.elements, 1)
                        i_:=2, len:=t_.elements.Length + 1
                        while (i_<len) {
                            argsStr.=", " do(t_.elements, i_)
                            i_++
                        }
                    }
                    return "[" argsStr "]"
            }
        }
    }


}
walker_undefinedVars()

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
                , "comma multi-statement", "concat", "variable":
                    finalStr.=do(v_) "`n"
                case "var scope declaration":
                    finalStr.=v_.value " "
                    v_:=statements[++k_]
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
                    v_:=statements[++k_]
                    withNewline()
                case "class":
                    finalStr.="class " v_.className " "
                    v_:=statements[++k_]
                    withNewline()
                case "function definition":
                    finalStr.=do(v_) " "
                    v_:=v_.body
                    withNewline()
                case "condition with block":
                    finalStr.=do(v_.expr) " "
                case "condition without block":
                    finalStr.=do(v_.expr) "`n"
                case "loop with block1":
                    finalStr.="loop "
                    v_:=statements[++k_]
                    withNewline()
                case "loop with block2":
                    finalStr.="loop "
                    v_:=statements[++k_]
                    withNewline()
                    v_:=statements[++k_]
                    withNewline()
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
                case "loop without block":
                    finalStr.="loop "
                    v_:=statements[++k_]
                    withNewline()

                    indent.="  "
                    finalStr.=indent
                    v_:=statements[++k_]
                    withNewline()
                    indent:=SubStr(indent, 3)
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
                case "for with block":
                    finalStr.="for " do(v_.var1)
                    if (v_.var2) {
                        finalStr.=", " do(v_.var2)
                    }
                    finalStr.=" in " do(v_.expression)

                    finalStr.=" " ;for the block
                    v_:=statements[++k_]
                    withNewline()
                case "for without block":
                    finalStr.="for " do(v_.var1)
                    if (v_.var2) {
                        finalStr.=", " do(v_.var2)
                    }
                    finalStr.=" in " do(v_.expression)

                    finalStr.="`n"
                    indent.="  "
                    finalStr.=indent
                    v_:=statements[++k_]
                    withNewline()
                    indent:=SubStr(indent, 3)
                case "label":
                    finalStr.=v_.labelName ":`n"
                case "switch":
                    finalStr.="switch " do(v_.SwitchValue) " {`n"
                    indent.="  "
                    do_statements(v_.statements)
                    indent:=SubStr(indent, 3)
                    finalStr.=indent
                    finalStr.="}`n"
                case "case":
                    CaseValues:=v_.CaseValues
                    finalStr.="case " do(CaseValues[1])
                    j_:=2
                    while (j_ <= CaseValues.Length) {
                        finalStr.=", " do(CaseValues[j_])
                        j_++
                    }
                    finalStr.=":"

                    do_statements_case()
                case "default":
                    finalStr.="default:"
                    do_statements_case()
            }
            do_statements_case() {
                statements_case:=v_.statements
                j_:=2
                if (statements_case.Length && statements_case[1].type=="block") {
                    v_:=statements_case[1]
                    withNewline()
                } else {
                    j_--
                    finalStr.="`n"
                }

                indent.="  "
                statements_case_len:=statements_case.Length + 1
                while (j_ < statements_case_len) {
                    v_:=statements_case[j_]
                    finalStr.=indent
                    withNewline()
                    j_++
                }
                indent:=SubStr(indent, 3)
            }

        }
        do(t_) {
            if (Type(t_)=="String") {
                MsgBox "This Should Never Happen5: " t_
                return t_
            }
            switch t_.type {
                case "command empty arg", "function call empty arg":
                    return ""
                case "variable", "directive arg", "number", "hex number", "obj key":
                    return t_.value
                case "double-deref":
                    return "%" do(t_.value) "%"
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
                case "array":
                    argsStr:=""
                    if (t_.elements.Length) {
                        argsStr.=do(t_.elements[1])
                        i_:=2, len:=t_.elements.Length + 1
                        while (i_<len) {
                            argsStr.=", " do(t_.elements[i_])
                            i_++
                        }
                    }
                    return "[" argsStr "]"
            }
            MsgBox "Switch .type not matched {ejf90u2349r8u3} : " t_.type
        }
    }

}

converted:=what()
return {currentArr:currentArr,converted:converted}
}

anti_JSON_stringify(obj, maxDepth := 21) {

    stringified := ""

    escape(str) {
        str:=StrReplace(str, "\", "\\", true)
        str:=StrReplace(str, "`t", "\t", true)
        str:=StrReplace(str, "`b", "\b", true)
        str:=StrReplace(str, "`n", "\n", true)
        str:=StrReplace(str, "`r", "\r", true)
        str:=StrReplace(str, "`f", "\f", true)
        str:=StrReplace(str, "`"", "\`"", true)
        return str
    }
    ok(obj, depth) {
        switch (Type(obj)) {
            case 'Map':
                if (depth > maxDepth) {
                    stringified.="`"[DEEP ...Map]`""
                } else {
                    stringified.="{"
                    for k, v in obj {
                        (A_Index > 1 && stringified.=",")
                        ;ESCAPE THIS, using java thingy
                        stringified.=escape(k) ":"
                        ok(v, depth+1)
                    }
                    stringified.="}"
                }
            case 'Object':
                if (depth > maxDepth) {
                    stringified.="`"[DEEP ...Object]`""
                } else {
                    stringified.="{"
                    for k, v in obj.OwnProps() {
                        (A_Index > 1 && stringified.=",")
                        ;ESCAPE THIS, using java thingy
                        stringified.=escape(k) ":"
                        ok(v, depth+1)
                    }
                    stringified.="}"
                }
            case 'Array':
                if (depth > maxDepth) {
                    stringified.="`"[DEEP ...Array]`""
                } else {
                    stringified.="["
                    for v in obj {
                        (A_Index > 1 && stringified.=",")
                        ok(v, depth+1)
                    }
                    stringified.="]"
                }
            case 'String':
                ; escape with java
                stringified.="`"" escape(obj) "`"" ;in order to escape \n and etc
            case "Integer", "Float":
                stringified.=obj
        }

    }
    ok(obj, 0)

    return stringified

}

JSON_stringify(obj, maxDepth := 21) {

    stringified := ""

    escape(str) {
        str:=StrReplace(str, "\", "\\", true)
        str:=StrReplace(str, "`t", "\t", true)
        str:=StrReplace(str, "`b", "\b", true)
        str:=StrReplace(str, "`n", "\n", true)
        str:=StrReplace(str, "`r", "\r", true)
        str:=StrReplace(str, "`f", "\f", true)
        str:=StrReplace(str, "`"", "\`"", true)
        return str
    }
    ok(obj, depth) {
        switch (Type(obj)) {
            case 'Map':
                if (depth > maxDepth) {
                    stringified.="`"[DEEP ...Map]`""
                } else {
                    stringified.="{"
                    for k, v in obj {
                        (A_Index > 1 && stringified.=",")
                        ;ESCAPE THIS, using java thingy
                        stringified.="`"" escape(k) "`": "
                        ok(v, depth+1)
                    }
                    stringified.="}"
                }
            case 'Object':
                if (depth > maxDepth) {
                    stringified.="`"[DEEP ...Object]`""
                } else {
                    stringified.="{"
                    for k, v in obj.OwnProps() {
                        (A_Index > 1 && stringified.=",")
                        ;ESCAPE THIS, using java thingy
                        stringified.="`"" escape(k) "`": "
                        ok(v, depth+1)
                    }
                    stringified.="}"
                }
            case 'Array':
                if (depth > maxDepth) {
                    stringified.="`"[DEEP ...Array]`""
                } else {
                    stringified.="["
                    for v in obj {
                        (A_Index > 1 && stringified.=",")
                        ok(v, depth+1)
                    }
                    stringified.="]"
                }
            case 'String':
                ; escape with java
                stringified.="`"" escape(obj) "`"" ;in order to escape \n and etc
            case "Integer", "Float":
                stringified.=obj
        }

    }
    ok(obj, 0)

    return stringified


}

loop 1 {
if (IsSet(__scintilla__)) {
    break
}

; bbb:=aaa(FileRead("test.ahk"))
; bbb:=aaa(FileRead("MsgBox.ahk"))
; bbb:=aaa(FileRead("MsgBox_Insane.ahk"))
; bbb:=aaa(FileRead("test2.ahk"))
; bbb:=aaa(FileRead("concat.ahk"))
; bbb:=aaa(FileRead("object.ahk"))
; bbb:=aaa(FileRead("basic.ahk"))
; bbb:=aaa(FileRead("hotkey.ahk"))
; bbb:=aaa(FileRead("!get colour_mid.ahk"))
; bbb:=aaa(FileRead("Accelerated Scrolling 1.3.ahk"))
; bbb:=aaa(FileRead("ifelse.ahk"))
; bbb:=aaa(FileRead("RunAsTask.ahk"))
; bbb:=aaa(FileRead("Return comma ErrorLevel assignment.ahk"))
; bbb:=aaa(FileRead("Return comma ErrorLevel assignment2.ahk"))
; bbb:=aaa(FileRead("string continuation section.ahk"))
; bbb:=aaa(FileRead("RunCMD.ahk"))
; bbb:=aaa(FileRead("File.ReadLine.ahk"))
; bbb:=aaa(FileRead("Clipboard A_Clipboard.ahk"))
; bbb:=aaa(FileRead("while.ahk"))
; bbb:=aaa("buildNumber:=splitByDot[3]")
; bbb:=aaa("buildNumber:=splitByDot[ComObjCreate()+1]")
; bbb:=aaa("if(true){}else{}")
; bbb:=aaa(FileRead("switch.ahk"))
; bbb:=aaa(FileRead("switch2.ahk"))
; bbb:=aaa(FileRead("_VD.ahk"))
; bbb:=aaa("VarSetCapacity(v,2)`na:=&v+2`na:=2+&v")
; bbb:=aaa("[::MsgBox hello")
; bbb:=aaa("* & a::MsgBox hello")
; bbb:=aaa("* & /::MsgBox hello")
; bbb:=aaa("* & /::MsgBox hello")
; bbb:=aaa("+ & a::MsgBox hello")
; bbb:=aaa("MsgBox % 2`n+ & a::MsgBox hello")
; bbb:=aaa("MsgBox 2`n+ & a::MsgBox hello")
; bbb:=aaa("MsgBox % 2`n+2`n+ & a::MsgBox hello")
; bbb:=aaa("MsgBox 2`n+2`n+ & a::MsgBox hello")
; bbb:=aaa(":::MsgBox hello")
; bbb:=aaa("Enter::MsgBox hello")
; bbb:=aaa('Postmessage,0xB1,0,0,, % "ahk_id " HWndExplanation_Edit')
; bbb:=aaa(FileRead("gui.ahk"))
; bbb:=aaa(FileRead("gui2.ahk"))
; bbb:=aaa(FileRead("IfEqual.ahk"))
; bbb:=aaa("IfEqual, Member, InterfaceLuid,               Return this.NET_LUID()")
; bbb:=aaa("IfEqual, Member, % ComObjCreate(),               Return this.NET_LUID()")
; bbb:=aaa(FileRead("reservedVar.ahk"))
; bbb:=aaa(FileRead("reservedVar2.ahk"))
; bbb:=aaa(FileRead("this.DefineProp if __Get or __Set is defined, in __New only.ahk"))
; bbb:=aaa(FileRead("A_PtrSize UPtr UInt ternary.ahk"))
; bbb:=aaa(FileRead("toIsFunction.ahk"))
; bbb:=aaa(FileRead("StringSplit.ahk"))
; bbb:=aaa(FileRead("two param ComObjCreate and ComObjQuery.ahk"))
; bbb:=aaa(FileRead("_fixCasingOfPath.ahk"))
; bbb:=aaa(FileRead("Func.ahk"))
; bbb:=aaa(FileRead("pre-increment.ahk"))
; bbb:=aaa(FileRead("askForHelp1.ahk"))
bbb:=aaa(FileRead("GooglePhraseFix.ahk"))
; bbb:=aaa(A_Clipboard)


; d currentArr
; MsgBox A_Clipboard:=anti_JSON_stringify(bbb.currentArr)
MsgBox A_Clipboard:=JSON_stringify(bbb.currentArr)
A_Clipboard:=bbb.converted



}

f3::Exitapp