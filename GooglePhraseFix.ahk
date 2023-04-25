; https://www.computoredge.com/AutoHotkey/Downloads/GooglePhraseFix.ahk
; June 6, 2021 Made changes to respond to Google search changes

; Ctrl+Alt+g autocorrect selected text
^!g::
clipback := ClipboardAll
clipboard=

Send ^c
ClipWait, 0
UrlDownloadToFile % "https://www.google.com/search?q=" . clipboard, temp
FileRead, contents, temp

FileDelete temp
if (RegExMatch(contents, "(Including results for|Showing results for|Did you mean:)(.*?)</a>", match)) {
   match2 := RegExReplace(match2,"<.+?>")
   StringReplace, match2, match2, &#39;,', All
}
msgbox %match2%
SendInput %match2%
Sleep 500
clipboard := clipback
return