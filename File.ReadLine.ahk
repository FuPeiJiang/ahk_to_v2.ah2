File := FileOpen(hPipeR, "h", Codepage)
Line := File.ReadLine()
sOutput .= Fn ? Fn.Call(Line, LineNum++) : Line