_fixCasingOfPath(fullPath) {
    HRESULT:=DllCall("shell32\SHParseDisplayName", "Ptr", &fullPath, "Uint", 0, "Ptr*", pIDL, "Uint", 0, "Uint", 0)
    if (HRESULT) {
        return false
    }
    ; if (HRESULT==-2147024809) { ; input":"
        ; return false
    ; } else if (HRESULT!=0) {
        ; MsgBox % "_fixCasingOfPath HRESULT!=0 what error is this ?"
        ; MsgBox % Clipboard:=HRESULT
        ; -2147024894 ; input"joifjwoiejgweg"
        ; -2147024894 ; input"C:\doesnotexist"
    ; }
    VarSetCapacity(pszPath, 600) ;600 was a random number
    DllCall("shell32\SHGetPathFromIDListW", "Ptr", pIDL, "Ptr", &pszPath)
    DllCall("ole32\CoTaskMemFree", "Ptr", pIDL) ;free memory
    return StrGet(&pszPath+0)
}