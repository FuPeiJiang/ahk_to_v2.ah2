Array_Indent(arr) {
; |1
; |    1
; |        1
; |        2
; |        3
; [1, children]
; [1, [[1, children],[1, children],[1, children]]]
; optimal: [1, [1, [1, 2, 3]]]
; what I have: [1, [1, [[1], [2], [3]]]]
; (empty children)
    depth:=0

    parentArr_save:=[]
    idx_save:=[]


    idx:=1

    finalStr:=""

    parentArr:=[]
    outer:
    while (true) {
        Loop Parse arr[1], "`n" {
            finalStr.=StrReplace(Format("{:0" depth "}", ""), 0, "    ") A_LoopField "`n"
        }

        if (arr.Length==2) {
            parentArr_save.push(parentArr)
            parentArr:=arr[2]

            arr:=parentArr[1]
            depth++

            idx_save.push(idx)

            idx:=1
        } else {
        ; if no child, get next
        ; how do I get next ?

            while (true) {
                if (idx < parentArr.Length) {
                    idx++
                    arr:=parentArr[idx]
                    continue outer

                } else {
                    ;if no next, get next sibling that's up
                    ; just touch the idx

                    if (idx_save.Length) {
                        idx:=idx_save.Pop()
                        parentArr:=parentArr_save.Pop()

                        depth--
                    } else {
                        return finalStr
                    }


                }
            }


        }
    }

}

array_isNotEqual(a1, a2) {
    type1:=Type(a1)
    type2:=Type(a2)
    if (type1!==type2) {
        return true
    }
    ; p type1
    switch (type1) {
        case "String", "Integer", "Float":
            return a1==a2 ? false : true
        case "Array":
            if (a1.Length!==a2.Length) {
                return true
            }
            loop a1.Length {
                if array_isNotEqual(a1[A_Index], a2[A_Index]) {
                    return true
                }
            }
            return false
        case "Map":
            if (a1.Count!==a2.Count) {
                return true
            }
            ;has, equal -> continue
            ;has, neq -> true
            ;no has, equal -> true
            ;no has, neq -> true
            for k in a1 {
                if (!a2.Has(k) || array_isNotEqual(a1[k], a2[k])) {
                    return true
                }
            }
            return false
        case "Object":
            if (ObjOwnPropCount(a1)!==ObjOwnPropCount(a2)) {
                return true
            }
            for k in a1.OwnProps() {
                ; Object key access is case insensitive
                if (!a2.HasOwnProp(k) || array_isNotEqual(a1[k], a2[k])) {
                    return true
                }
            }
            return false
        case "Enumerator":
            ;Enumerator has no length, so it's oof
            a1Map := Map() ;case sensitive by default
            for k, v in a1 {
                a1Map[k]:=v
            }
            ; every k in v2, check if in a1's equivalent Map
            count:=0
            for k, v in a2 {
                count++
                if (!a1Map.Has(k) || array_isNotEqual(a1Map[k], v)) {
                    return true
                }
            }
            if (count!==a1Map.Count) {
                return true
            }
            return false
    }
}

array_ToVerticleBarString(oArray)
{
    finalStr:=""
    length:=oArray.Length
    for k, v in oArray {
        finalStr.=(k=length) ? v : v "|"
    }
    return finalStr
}

keysOnly(obj) {
    finalStr:=""
    for k, v in obj {
        finalStr.=Type(k)=="String" ? '`n"' k '"' : "`n" k
    }
    finalStr:=SubStr(finalStr, 2)
    return finalStr
}

array_ToNewLineString(oArray) {
    finalStr:=""
    for k, v in oArray {
        finalStr.="`n" array_p(v)
    }
    return SubStr(finalStr, 2) ;remove the first "`n"
}


array_ToSpacedString(oArray)
{
    finalStr:=""
    length:=oArray.Length
    for k, v in oArray {
        if (Type(v)=="String")
            finalStr.=(k=length) ? "`"" v "`"" : "`"" v "`" "
        else
            finalStr.=(k=length) ? v : v " "
    }
    return finalStr
}

Array_Same(array1, array2)
{
    global arrayEqual:=true
    a(array1, array2)
    return arrayEqual

}

a(arrayOrString1, arrayOrString2)
{
    global arrayEqual
    maxIndex1:=arrayOrString1.MaxIndex()
    maxIndex2:=arrayOrString2.MaxIndex()
    if (maxIndex1 != maxIndex2)
    {
        arrayEqual:=false
    }
    Else
    {
        if (maxIndex1>0)
        {
            for Key23, Value24 in arrayOrString1
            {
                if !arrayEqual
                    return
                a(Value24, arrayOrString2[Key23])
            }
        }
        Else if (arrayOrString1!=arrayOrString2)
        {
            arrayEqual:=false
        }
    }
}

Array_SortByIndex1(arr, ascending:=true, sortType:="")
{
    str:=""
    for k,v in arr {
        str.=v[1] "+" k "|"
    }
    length:=arr.Length
    firstValue:=arr[1][1]
    if firstValue is number
    {
        sortType := "N"
    }
    str:=Sort(str, "D|" sortType (ascending ? "" : "R"))
    finalAr:=[]
    finalAr.Capacity:=length
    barPos:=1

    loop length {
        plusPos:=InStr(str, "+",, barPos)
        barPos:=InStr(str, "|",, plusPos)

        num:=SubStr(str, plusPos + 1, barPos - plusPos - 1)
        finalAr.Push(arr[num])
    }
return finalAr
}

Array_Sort(array)
{
    for K1, V1 in array
    {
        string23.=V1 ";"
    }
    string23:= Sort777(string23, ";")[1]
    array := StrSplit(string23 , ";")
    return array
}

Sort777(x, delim:="") { ; LOGIC SORT, x IS terminated with delimiter!
    count1:=0

    if (delim=="")
        delim:="`n"

    x := Sort(x , "D" delim)

    Loop Parse, x, %delim%
    {
        count1++
        If (p = PreText777(A_LoopField))

        y := y delim A_LoopField

        Else {

            y := Sort(y , "N D" delim " P" StrLen(p)+1)

            z := z y delim

            p := PreText777(A_LoopField)

            y := A_LoopField

        }

    }

    z:=SubStr(z, 2)

    Return [z, count1]

}

PreText777(x) {

    Loop Parse, x, 0123456789

    Return A_LoopField

}

;https://autohotkey.com/board/topic/85201-array-deep-copy-treeview-viewer-and-more/ by GeekDude

Array_Join(strOrArr, delim:="`n") {
    Output:=""
    varType := Type(strOrArr)
    Obj26:=false

    switch (varType) {
        case "Array", "Map", "Enumerator":
            Obj26:=strOrArr
        case "Object":
            Obj26:=strOrArr.OwnProps()
        default:
            Output.=array_p(strOrArr)
    }

    if (Obj26) {
        For Key23, Value24 in Obj26 {
            Output .= array_p(Value24) delim
        }
    }
    return Output
}

; dontQuoteString(stringOrArray) {
    ; return Type(stringOrArray) == "String" ? stringOrArray :
; }

d_hex(num) {
    hexNum:=Format("0x{:08X}", num)
    A_Clipboard:=hexNum
    MsgBox hexNum
}

d(params*) {
    finalStr:=""
    if (params.Length > 0) {
        finalStr.=Type(params[1]) == "String" ? params[1] : Array_Join(params[1], "`n")

        k:=2, lenPlusOne:=params.Length + 1
        while (k < lenPlusOne) {
            finalStr.="`n" (Type(params[1]) == "String" ? params[1] : Array_Join(params[1], "`n"))
            k++
        }
    }
    A_Clipboard:=finalStr
    p(params*)
}

p(params*) {
    finalStr:=""
    if (params.Length > 0) {
        finalStr.=Array_p(params[1])

        k:=2, lenPlusOne:=params.Length + 1
        while (k < lenPlusOne) {
            finalStr.=" " Array_p(params[k])
            k++
        }
    }
    MsgBox finalStr
}

Array_p(Arr21, delim:=", ") {
  return delimDoesntChange(Arr21)
  delimDoesntChange(Arr21) {
    varType := Type(Arr21)
    OutPut:=""
    Obj26:=false
    switch varType {
        case "Array":
            For Key23, Value24 in Arr21 {
              Output .= delim delimDoesntChange(Value24)
            }
            OutPut := "[" SubStr(OutPut, StrLen(delim)+1) "]" ;remove the first ", "
        case "Map", "Enumerator":
            Obj26:=Arr21
        case "Object":
            Obj26:=Arr21.OwnProps()
        case "Buffer":
            offset:=0
            Size:=Arr21.Size
            OutPut.="< "
            while (offset < Size) {
                OutPut.=NumGet(Arr21, offset, "UChar") " "
                offset++
            }
            OutPut.=">"
            case "String":
            Output .= "`"" Arr21 "`""
        default:
            Output .= Arr21

    }

    if (Obj26) {
      For Key23, Value24 in Obj26 {
        Output .= delim delimDoesntChange(Key23) ":" delimDoesntChange(Value24)
      }
      OutPut := "{" SubStr(OutPut, StrLen(delim)+1) "}" ;remove the first ", "
    }

    Return OutPut
  }
}

Array_DeepClone(Array, Objs:=0)
{
    if !Objs
        Objs := {}
    Obj := Array.Clone()
    Objs[StrPtr(Array)] := Obj ; Save this new array
    For Key23, Val in Obj
        if (IsObject(Val)) ; If it is a subarray
        Obj[Key23] := Objs[StrPtr(Val)] ; If we already know of a refrence to this array
    ? Objs[StrPtr(Val)] ; Then point it to the new array
    : Array_DeepClone(Val,Objs) ; Otherwise, clone this sub-array
    return Obj
}

Array_IsCircle(Obj, Objs:=0)
{
    if !Objs
        Objs := {}
    For Key23, Val in Obj
        if (IsObject(Val)&&(Objs[StrPtr(Val)]||Array_IsCircle(Val,(Objs,Objs[StrPtr(Val)]:=1))))
        return 1
    return 0
}

