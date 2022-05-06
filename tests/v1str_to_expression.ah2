#SingleInstance force
ListLines 0
KeyHistory 0
SendMode "Input" ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir ; Ensures a consistent starting directory.

assert(got, want) {
    if (got!==want) {
        MsgBox want "`n" got
    }
}

assert(v1str_to_expression("%v%"), "v")
assert(v1str_to_expression("%v%aa"), "v `"aa`"")
assert(v1str_to_expression("aa%v%"), "`"aa`" v")
assert(v1str_to_expression("aa%v%aa"), "`"aa`" v `"aa`"")
assert(v1str_to_expression("aa%v%aa%v%aa"), "`"aa`" v `"aa`" v `"aa`"")
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

return

f3::Exitapp