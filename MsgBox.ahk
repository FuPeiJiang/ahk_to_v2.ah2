; MsgBox, Hello, world!  ; old
MsgBox 48, Title
MsgBox 48, Title, Text, 00.11  ; all commas are delimiters
MsgBox 48, Title, Text, 0.  ; number
MsgBox 48, Title, Text, .1  ; number
MsgBox 48, Title, Text, .  ; text
MsgBox 48, Title, Text, 1..  ; text
; MsgBox, , Title, Text,  ; as above
; MsgBox % Options, Title, Text, % Timeout  ; as above
; MsgBox 16,, Hello, world!  ; only the first two commas delimit parameters
; MsgBox % Options,, Hello, world!  ; as above
; MsgBox Options, Title, Text, Timeout  ; ignore the words, this is all just one Text parameter