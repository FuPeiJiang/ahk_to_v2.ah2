class biga {
  static throwExceptions := true
  static limit := -1
  static _guardedMethods := ["ary", "chunk", "every", "fill", "invert", "parseInt", "random", "trim", "reverse"]
  static _guardedCallWithOne := ["random"]
  static _pathRegex := "/[.\[\]]/"
  _uniqueId := 0
  static chunk(param_array, param_size := 1) {
    if (!isObject(param_array) || !this.isNumber(param_size)) {
      this._internal_ThrowException()
    }
    l_array := []
    param_array := this.clone(param_array)
    while ((Type(temp := param_array) == "Array" ? temp.Length : temp.Count) > 0) {
      l_innerArr := []
      loop param_size {
        if ((Type(temp2 := param_array) == "Array" ? temp2.Length : temp2.Count) == 0) {
          break
        }
        l_innerArr.push(param_array.removeAt(1))
      }
      l_array.push(l_innerArr)
    }
    return l_array
  }
  static compact(param_array) {
    if (!isObject(param_array)) {
      this._internal_ThrowException()
    }
    l_array := []
    for key, value in param_array {
      if (value == "" || value == 0) {
        continue
      }
      l_array.push(value)
    }
    return l_array
  }
  static concat(param_array, param_values*) {
    if (!isObject(param_array)) {
      this._internal_ThrowException()
    }
    l_array := this.cloneDeep(param_array)
    for index, object in param_values {
      if (!isObject(object)) {
        l_array.push(object)
      } else {
        for index2, object2 in object {
          l_array.push(object2)
        }
      }
    }
    return l_array
  }
  static depthOf(param_array, param_depth := 1) {
    if (!isObject(param_array)) {
      this._internal_ThrowException()
    }
    for key, value in param_array {
      if (isObject(value)) {
        param_depth++
        param_depth := this.depthOf(value, param_depth)
      }
    }
    return param_depth
  }
  static difference(param_array, param_values*) {
    if (!isObject(param_array)) {
      this._internal_ThrowException()
    }
    l_array := this.clone(param_array)
    for key, value in param_values {
      for key2, value2 in value {
        while ((foundIndex := this.indexOf(l_array, value2)) != -1) {
          l_array.removeAt(foundIndex)
        }
      }
    }
    return l_array
  }
  static drop(param_array, param_n := 1) {
    if (!this.isNumber(param_n)) {
      this._internal_ThrowException()
    }
    if (isObject(param_array)) {
      l_array := this.clone(param_array)
    }
    if (this.isStringLike(param_array)) {
      l_array := strSplit(param_array)
    }
    l_array.removeAt(1, param_n)
    if ((Type(temp := l_array) == "Array" ? temp.Length : temp.Count) == 0) {
      return []
    }
    return l_array
  }
  static dropRight(param_array, param_n := 1) {
    if (!this.isNumber(param_n)) {
      this._internal_ThrowException()
    }
    if (isObject(param_array)) {
      l_array := this.clone(param_array)
    }
    if (this.isStringLike(param_array)) {
      l_array := strSplit(param_array)
    }
    loop param_n {
      l_array.removeAt((Type(temp := l_array) == "Array" ? temp.Length : temp.Count))
    }
    if ((Type(temp2 := l_array) == "Array" ? temp2.Length : temp2.Count) == 0) {
      return []
    }
    return l_array
  }
  static dropRightWhile(param_array, param_predicate := "__identity") {
    if (!isObject(param_array)) {
      this._internal_ThrowException()
    }
    if ((Type(temp := param_array) == "Array" ? temp.Length : temp.Count) == 0) {
      return []
    }
    l_array := this.reverse(this.cloneDeep(param_array))
    return this.reverse(this.dropWhile(l_array, param_predicate))
  }
  static dropWhile(param_array, param_predicate := "__identity") {
    if (!isObject(param_array)) {
      this._internal_ThrowException()
    }
    if ((Type(temp := param_array) == "Array" ? temp.Length : temp.Count) == 0) {
      return []
    }
    shorthand := this._internal_detectShorthand(param_predicate, param_array)
    if (shorthand != false) {
      param_predicate := this._internal_createShorthandfn(param_predicate, param_array)
    }
    l_array := this.cloneDeep(param_array)
    l_droppableElements := 0
    for key, value in l_array {
      if (this.isFunction(param_predicate)) {
        if (param_predicate.call(value, key, l_array)) {
          l_droppableElements++
        } else {
          break
        }
      }
    }
    if (l_droppableElements >= 1) {
      l_array.removeAt(1, l_droppableElements)
    }
    return l_array
  }
  static fill(param_array, param_value := "", param_start := 1, param_end := -1) {
    if (!isObject(param_array)) {
      this._internal_ThrowException()
    }
    l_array := this.clone(param_array)
    if (param_end == -1) {
      param_end := this.size(param_array)
    }
    for key, value in l_array {
      if (key >= param_start && key <= param_end) {
        l_array[key] := param_value
      }
    }
    return l_array
  }
  static findIndex(param_array, param_predicate := "__identity", param_fromindex := 1) {
    if (!isObject(param_array) || !this.isNumber(param_fromindex)) {
      this._internal_ThrowException()
    }
    l_array := []
    shorthand := this._internal_detectShorthand(param_predicate, param_array)
    if (shorthand != false) {
      param_predicate := this._internal_createShorthandfn(param_predicate, param_array)
    }
    for key, value in param_array {
      if (param_fromIndex > A_Index) {
        continue
      }
      if (this.isFunction(param_predicate)) {
        if (param_predicate.call(value, key, param_array)) {
          return key
        }
      }
    }
    return -1
  }
  static findLastIndex(param_array, param_value := "__identity", param_fromIndex := 1) {
    if (!isObject(param_array)) {
      this._internal_ThrowException()
    }
    l_array := this.reverse(this.cloneDeep(param_array))
    l_count := this.size(l_array)
    l_foundIndex := this.findIndex(l_array, param_value, param_fromIndex)
    if (l_foundIndex < 0) {
      return -1
    } else {
      finalIndex := l_count + 1
      finalIndex := finalIndex - l_foundIndex
    }
    return finalIndex
  }
  static flatten(param_array) {
    if (!isObject(param_array)) {
      this._internal_ThrowException()
    }
    l_obj := []
    for index, object in param_array {
      if (isObject(object)) {
        for index2, object2 in object {
          l_obj.push(object2)
        }
      } else {
        l_obj.push(object)
      }
    }
    return l_obj
  }
  static flattenDeep(param_array) {
    if (!isObject(param_array)) {
      this._internal_ThrowException()
    }
    l_depth := this.depthOf(param_array)
    return this.flattenDepth(param_array, l_depth)
  }
  static flattenDepth(param_array, param_depth := 1) {
    if (!isObject(param_array)) {
      this._internal_ThrowException()
    }
    l_obj := this.cloneDeep(param_array)
    loop param_depth {
      l_obj := this.flatten(l_obj)
    }
    return l_obj
  }
  static fromPairs(param_pairs) {
    if (!isObject(param_pairs)) {
      this._internal_ThrowException()
    }
    l_obj := Map()
    for key, value in param_pairs {
      l_obj[value[1]] := value[2]
    }
    return l_obj
  }
  static head(param_array) {
    return this.take(param_array)[1]
  }
  static indexOf(param_array, param_value, fromIndex := 1) {
    if (!isObject(param_array)) {
      this._internal_ThrowException()
    }
    if (isObject(param_value)) {
      param_value := this._internal_MD5(param_value)
      param_array := this.map(param_array, this._internal_MD5)
    }
    for index, value in param_array {
      if (A_Index < fromIndex) {
        continue
      }
      if (value != param_value) {
        continue
      } else {
        return index
      }
    }
    return -1
  }
  static initial(param_array) {
    if (isObject(param_array)) {
      l_array := this.clone(param_array)
    }
    if (this.isStringLike(param_array)) {
      l_array := strSplit(param_array)
    }
    if ((Type(temp := l_array) == "Array" ? temp.Length : temp.Count) == 0) {
      return []
    }
    return this.dropRight(l_array)
  }
  static intersection(param_arrays*) {
    if (!isObject(param_arrays[1])) {
      this._internal_ThrowException()
    }
    tempArray := this.cloneDeep(param_arrays[1])
    param_arrays.removeAt(1)
    l_array := []
    for key, value in tempArray {
      for key2, value2 in param_arrays {
        if (this.indexOf(value2, value) != -1) {
          found := true
        } else {
          found := false
          break
        }
      }
      if (found && this.indexOf(l_array, value) == -1) {
        l_array.push(value)
      }
    }
    return l_array
  }
  static join(param_array, param_sepatator := ",") {
    if (!isObject(param_array) || isObject(param_sepatator)) {
      this._internal_ThrowException()
    }
    enum := param_array.__Enum()
    enum(&_, &result)
    while enum(&_, &item) {
      result .= param_sepatator item
    }
    return result
  }
  static last(param_array) {
    if (isObject(param_array)) {
      param_array := this.clone(param_array)
    }
    if (this.isStringLike(param_array)) {
      param_array := strSplit(param_array)
    }
    return param_array.pop()
  }
  static lastIndexOf(param_array, param_value, param_fromIndex := 0) {
    if (param_fromIndex == 0) {
      param_fromIndex := (Type(temp := param_array) == "Array" ? temp.Length : temp.Count)
    }
    for index, value in param_array {
      Index -= 1
      l_negativeIndex := (Type(temp2 := param_array) == "Array" ? temp2.Length : temp2.Count) - index
      if (l_negativeIndex > param_fromIndex) {
        continue
      }
      if (this.isEqual(param_array[l_negativeIndex], param_value)) {
        return l_negativeIndex
      }
    }
    return -1
  }
  static nth(param_array, param_n := 1) {
    if (!this.isNumber(param_n)) {
      this._internal_ThrowException()
    }
    if (isObject(param_array)) {
      l_array := this.clone(param_array)
    }
    if (this.isStringLike(param_array)) {
      l_array := strSplit(param_array)
    }
    if (param_n == 0) {
      param_n := 1
    }
    if ((Type(temp := l_array) == "Array" ? temp.Length : temp.Count) < param_n) {
      return ""
    }
    if (param_n > 0) {
      return l_array[param_n]
    }
    if ((Type(temp2 := l_array) == "Array" ? temp2.Length : temp2.Count) == 0) {
      return ""
    }
    l_array := this.reverse(l_array)
    param_n := 0 - param_n
    return this.nth(l_array, param_n)
  }
  static reverse(param_collection) {
    if (!isObject(param_collection)) {
      this._internal_ThrowException()
    }
    l_collection := this.cloneDeep(param_collection)
    l_array := []
    while ((Type(temp := l_collection) == "Array" ? temp.Length : temp.Count) != 0) {
      l_array.push(l_collection.pop())
    }
    return l_array
  }
  static slice(param_array, param_start := 1, param_end := 0) {
    if (!this.isNumber(param_start)) {
      this._internal_ThrowException()
    }
    if (!this.isNumber(param_end)) {
      this._internal_ThrowException()
    }
    if (this.isStringLike(param_array)) {
      param_array := strSplit(param_array)
    }
    if (param_end == 0) {
      param_end := (Type(temp := param_array) == "Array" ? temp.Length : temp.Count)
    }
    l_array := []
    for key, value in param_array {
      if (A_Index >= param_start && A_Index <= param_end) {
        l_array.push(value)
      }
    }
    return l_array
  }
  static sortedIndex(param_array, param_value) {
    if (param_value < param_array[1]) {
      return 1
    }
    loop (Type(temp := param_array) == "Array" ? temp.Length : temp.Count) {
      if (param_array[A_Index] < param_value && param_value < param_array[A_Index + 1]) {
        return A_Index + 1
      }
    }
    return (Type(temp2 := param_array) == "Array" ? temp2.Length : temp2.Count) + 1
  }
  static sortedUniq(param_collection) {
    l_temp := ""
    if (!isObject(param_collection)) {
      this._internal_ThrowException()
    }
    l_array := []
    for key, value in param_collection {
      printedelement := this._internal_stringify(param_collection[key])
      if (l_temp != printedelement) {
        l_temp := printedelement
        l_array.push(value)
      }
    }
    return l_array
  }
  static tail(param_array) {
    return this.drop(param_array)
  }
  static take(param_array, param_n := 1) {
    if (!this.isNumber(param_n)) {
      this._internal_ThrowException()
    }
    if (isObject(param_array)) {
      param_array := this.clone(param_array)
    }
    if (this.isStringLike(param_array)) {
      param_array := strSplit(param_array)
    }
    l_array := []
    for key, value in param_array {
      if (param_n < A_Index) {
        break
      }
      l_array.push(value)
    }
    if ((Type(temp := l_array) == "Array" ? temp.Length : temp.Count) == 0 || param_n == 0) {
      return []
    }
    return l_array
  }
  static takeRight(param_array, param_n := 1) {
    if (!this.isNumber(param_n)) {
      this._internal_ThrowException()
    }
    if (isObject(param_array)) {
      param_array := this.clone(param_array)
    }
    if (this.isStringLike(param_array)) {
      param_array := strSplit(param_array)
    }
    l_array := []
    loop param_n {
      if ((Type(temp := param_array) == "Array" ? temp.Length : temp.Count) == 0) {
        break
      }
      vvalue := param_array.pop()
      l_array.push(vvalue)
    }
    if ((Type(temp2 := l_array) == "Array" ? temp2.Length : temp2.Count) == 0 || param_n == 0) {
      return []
    }
    return this.reverse(l_array)
  }
  static union(param_arrays*) {
    l_array := []
    for key, array in param_arrays {
      if (isObject(array)) {
        l_array := this.concat(l_array, array)
      } else {
        l_array.push(array)
      }
    }
    return this.uniq(l_array)
  }
  static uniq(param_collection) {
    if (!isObject(param_collection)) {
      this._internal_ThrowException()
    }
    tempArray := []
    l_array := []
    for key, value in param_collection {
      l_printedElement := this._internal_MD5(param_collection[key])
      if (this.indexOf(tempArray, l_printedElement) == -1) {
        tempArray.push(l_printedElement)
        l_array.push(value)
      }
    }
    return l_array
  }
  static unzip(param_array) {
    if (!isObject(param_array)) {
      this._internal_ThrowException()
    }
    l_array := []
    for key, value in param_array[1] {
      l_array[key] := this.map(param_array, key)
    }
    return l_array
  }
  static without(param_array, param_values*) {
    if (!isObject(param_array)) {
      this._internal_ThrowException()
    }
    l_array := this.clone(param_array)
    for i, val in param_values {
      while (foundindex := this.indexOf(l_array, val) != -1) {
        l_array.removeAt(foundindex)
      }
    }
    return l_array
  }
  static zip(param_arrays*) {
    if (!isObject(param_arrays)) {
      this._internal_ThrowException()
    }
    l_array := []
    for key, value in param_arrays {
      for key2, value2 in value {
        loop (Type(temp := value) == "Array" ? temp.Length : temp.Count) {
          if (key2 == A_Index) {
            if (isObject(l_array[A_Index]) == false) {
              l_array[A_Index] := []
            }
            l_array[A_Index].push(value2)
          }
        }
      }
    }
    return l_array
  }
  static zipObject(param_props, param_values) {
    if (!isObject(param_props)) {
      param_props := []
    }
    if (!isObject(param_values)) {
      param_values := []
    }
    l_obj := Map()
    for key, value in param_props {
      l_obj[value] := param_values[A_Index]
    }
    return l_obj
  }
  static count(param_collection, param_predicate, param_fromIndex := 1) {
    shorthand := this._internal_detectShorthand(param_predicate, param_collection)
    if (shorthand != false) {
      param_predicate := this._internal_createShorthandfn(param_predicate, param_collection)
    }
    l_count := 0
    if (this.isAlnum(param_collection) || this.isString(param_collection)) {
      if (param_fromIndex > 1) {
        param_collection := subStr(param_collection, param_fromIndex, strLen(param_collection))
      }
      strReplace(param_collection, param_predicate, "", l_count)
      return l_count
    }
    for key, value in param_collection {
      if (param_fromIndex > A_Index) {
        continue
      }
      if (this.isFunction(param_predicate)) {
        if (param_predicate.call(value, key, param_collection) == true) {
          l_count++
          continue
        }
      }
      if (this.isEqual(value, param_predicate)) {
        l_count++
      }
    }
    return l_count
  }
  static countBy(param_collection, param_predicate := "__identity") {
    shorthand := this._internal_detectShorthand(param_predicate, param_collection)
    if (shorthand) {
      param_predicate := this._internal_createShorthandfn(param_predicate, param_collection)
    }
    l_array := []
    for key, value in param_collection {
      vItaree := param_predicate.call(value)
      if (!l_array.Has(vItaree)) {
        l_array[vItaree] := 1
      } else {
        l_array[vItaree]++
      }
    }
    return l_array
  }
  static every(param_collection, param_predicate := "__identity") {
    if (!isObject(param_collection)) {
      this._internal_ThrowException()
    }
    shorthand := this._internal_detectShorthand(param_predicate, param_collection)
    if (shorthand != false) {
      param_predicate := this._internal_createShorthandfn(param_predicate, param_collection)
    }
    for key, value in param_collection {
      if (this.isFunction(param_predicate)) {
        if (param_predicate.call(value, key, param_collection) == true) {
          continue
        }
        return false
      }
    }
    return true
  }
  static filter(param_collection, param_predicate := "__identity") {
    if (!isObject(param_collection)) {
      this._internal_ThrowException()
    }
    shorthand := this._internal_detectShorthand(param_predicate, param_collection)
    if (shorthand != false) {
      param_predicate := this._internal_createShorthandfn(param_predicate, param_collection)
    }
    collectionClone := []
    l_array := []
    l_paramAmmount := param_predicate.maxParams
    if (l_paramAmmount == 3) {
      collectionClone := this.cloneDeep(param_collection)
    }
    for key, value in param_collection {
      if (this.isFunction(param_predicate)) {
        if (param_predicate.call(value, key, collectionClone)) {
          l_array.push(value)
        }
      }
    }
    return l_array
  }
  static find(param_collection, param_predicate, param_fromindex := 1) {
    if (!isObject(param_collection) || !this.isNumber(param_fromindex)) {
      this._internal_ThrowException()
    }
    foundIndex := this.findIndex(param_collection, param_predicate, param_fromindex)
    if (foundIndex != -1) {
      return param_collection[foundIndex]
    }
    return false
  }
  static findLast(param_collection, param_predicate) {
    if (!isObject(param_collection)) {
      this._internal_ThrowException()
    }
    return this.find(this.reverse(param_collection), param_predicate)
  }
  static forEach(param_collection, param_iteratee := "__identity") {
    if (!isObject(param_collection)) {
      this._internal_ThrowException()
    }
    shorthand := this._internal_detectShorthand(param_iteratee, param_collection)
    if (shorthand != false) {
      param_iteratee := this._internal_createShorthandfn(param_iteratee, param_collection)
    }
    param_collection := this.cloneDeep(param_collection)
    for key, value in param_collection {
      if (this.isFunction(param_iteratee)) {
        vIteratee := param_iteratee.call(value, key, param_collection)
      }
      if (vIteratee == false) {
        return param_collection
      }
    }
    return param_collection
  }
  static forEachRight(param_collection, param_iteratee := "__identity") {
    if (!isObject(param_collection)) {
      this._internal_ThrowException()
    }
    shorthand := this._internal_detectShorthand(param_iteratee, param_collection)
    if (shorthand != false) {
      param_iteratee := this._internal_createShorthandfn(param_iteratee, param_collection)
    }
    collectionClone := this.reverse(this.cloneDeep(param_collection))
    for key, value in collectionClone {
      if (this.isFunction(param_iteratee)) {
        vIteratee := param_iteratee.call(value, key, collectionClone)
      }
      if (vIteratee == false) {
        return collectionClone
      }
    }
    return param_collection
  }
  static groupBy(param_collection, param_iteratee := "__identity") {
    if (!isObject(param_collection)) {
      this._internal_ThrowException()
    }
    shorthand := this._internal_detectShorthand(param_iteratee, param_collection)
    if (shorthand != false) {
      param_iteratee := this._internal_createShorthandfn(param_iteratee, param_collection)
    }
    l_array := []
    for key, value in param_collection {
      vIteratee := 0
      if (this.isFunction(param_iteratee) || !vIteratee) {
        vIteratee := param_iteratee.call(value)
      }
      if (!l_array.Has(vIteratee)) {
        l_array[vIteratee] := []
      }
      l_array[vIteratee].push(value)
    }
    return l_array
  }
  static includes(param_collection, param_value, param_fromIndex := 1) {
    global A_StringCaseSense
    if (!this.isNumber(param_fromIndex)) {
      this._internal_ThrowException()
    }
    if (isObject(param_value)) {
      param_value := this._internal_MD5(param_value)
      param_collection := this.map(param_collection, this._internal_MD5)
    }
    if (isObject(param_collection)) {
      for key, value in param_collection {
        if (param_fromIndex > A_Index) {
          continue
        }
        if (this.isEqual(value, param_value)) {
          return true
        }
      }
      return false
    } else {
      if (RegEx_value := this._internal_JSRegEx(param_value)) {
        return regExMatch(param_collection, RegEx_value, &RE, param_fromIndex)
      }
      if ((IsSet(A_StringCaseSense) ? A_StringCaseSense : A_StringCaseSense := "Off") == "On") {
        StringCaseSense := 1
      } else {
        StringCaseSense := 0
      }
      if ((param_value == "" || inStr(param_collection, param_value, StringCaseSense, param_fromIndex))) {
        return true
      } else {
        return false
      }
    }
  }
  static keyBy(param_collection, param_iteratee := "__identity") {
    if (!isObject(param_collection)) {
      this._internal_ThrowException()
    }
    shorthand := this._internal_detectShorthand(param_iteratee, param_collection)
    if (shorthand) {
      param_iteratee := this._internal_createShorthandfn(param_iteratee, param_collection)
    }
    l_obj := Map()
    for key, value in param_collection {
      if (this.isFunction(param_iteratee)) {
        vIteratee := param_iteratee.call(value, key, param_collection)
        l_obj[vIteratee] := value
      }
    }
    return l_obj
  }
  static map(param_collection, param_iteratee := "__identity") {
    if (!isObject(param_collection)) {
      this._internal_ThrowException()
    }
    if (this._internal_detectOwnMethods(param_iteratee)) {
      detailObj := this._internal_iterateeDetails(param_iteratee)
    }
    shorthand := this._internal_detectShorthand(param_iteratee, param_collection)
    if (this.includes([".property", "__identity", "_classMethod"], shorthand)) {
      param_iteratee := this._internal_createShorthandfn(param_iteratee, param_collection)
    }
    l_collection := this.cloneDeep(param_collection)
    l_array := []
    if (detailObj.guarded) {
      for key, value in param_collection {
        l_array.push(detailObj.iteratee.call(value))
      }
      return l_array
    }
    for key, value in param_collection {
      l_array.push(param_iteratee.call(value, key, l_collection))
    }
    return l_array
  }
  static partition(param_collection, param_predicate := "__identity") {
    if (!isObject(param_collection)) {
      this._internal_ThrowException()
    }
    trueArray := []
    falseArray := []
    shorthand := this._internal_detectShorthand(param_predicate, param_collection)
    if (shorthand) {
      param_predicate := this._internal_createShorthandfn(param_predicate, param_collection)
    }
    for key, value in param_collection {
      if (this.isFalsey(param_predicate.call(value))) {
        falseArray.push(value)
      } else {
        trueArray.push(value)
      }
    }
    return [trueArray, falseArray]
  }
  static reject(param_collection, param_predicate := "__identity") {
    if (!isObject(param_collection)) {
      this._internal_ThrowException()
    }
    shorthand := this._internal_detectShorthand(param_predicate, param_collection)
    if (shorthand) {
      param_predicate := this._internal_createShorthandfn(param_predicate, param_collection)
    }
    l_array := []
    for key, value in param_collection {
      if (this.isFunction(param_predicate)) {
        if (!param_predicate.call(value)) {
          l_array.push(value)
        }
        continue
      }
    }
    return l_array
  }
  static sample(param_collection) {
    if (!this.isStringLike(param_collection) && !isObject(param_collection)) {
      this._internal_ThrowException()
    }
    if (this.isStringLike(param_collection)) {
      param_collection := strSplit(param_collection)
    }
    if ((Type(temp := param_collection) == "Array" ? temp.Length : temp.Count) != param_collection.length) {
      l_array := this.map(param_collection)
    } else {
      l_array := param_collection.clone()
    }
    randomIndex := this.random(1, (Type(temp2 := l_array) == "Array" ? temp2.Length : temp2.Count))
    return l_array[randomIndex]
  }
  static sampleSize(param_collection, param_sampleSize := 1) {
    if (!isObject(param_collection)) {
      this._internal_ThrowException()
    }
    if (param_sampleSize > (Type(temp := param_collection) == "Array" ? temp.Length : temp.Count)) {
      return param_collection
    }
    if (this.isStringLike(param_collection)) {
      param_collection := strSplit(param_collection)
    }
    l_order := this.shuffle(this.keys(param_collection))
    l_array := []
    loop param_sampleSize {
      ordervalue := l_order.pop()
      l_array.push(param_collection[ordervalue])
    }
    return l_array
  }
  static shuffle(param_collection) {
    if (!isObject(param_collection)) {
      this._internal_ThrowException()
    }
    l_array := this.clone(param_collection)
    l_index := (Type(temp := l_array) == "Array" ? temp.Length : temp.Count)
    loop l_index - 1 {
      randomIndex := Random(1, l_index)
      l_tempVar := l_array[l_index]
      l_array[l_index] := l_array[randomIndex]
      l_array[randomIndex] := l_tempVar
      l_index--
    }
    return l_array
  }
  static size(param_collection) {
    if (isObject(param_collection)) {
      return (Type(temp := param_collection) == "Array" ? temp.Length : temp.Count)
    }
    return strLen(param_collection)
  }
  static some(param_collection, param_predicate := "__identity") {
    if (!isObject(param_collection)) {
      this._internal_ThrowException()
    }
    shorthand := this._internal_detectShorthand(param_predicate, param_collection)
    if (shorthand != false) {
      param_predicate := this._internal_createShorthandfn(param_predicate, param_collection)
    }
    for key, value in param_collection {
      if (this.isFunction(param_predicate)) {
        if (param_predicate.call(value, key, param_collection) = true) {
          return true
        }
      }
    }
    return false
  }
  static sortBy(param_collection, param_iteratees := "__identity") {
    if (!isObject(param_collection)) {
      this._internal_ThrowException()
    }
    if (this.startsWith(param_iteratees.name, this.__Class ".")) {
      param_iteratees := param_iteratees.bind(this)
    }
    l_array := []
    if (param_iteratees == "__identity") {
      return this._internal_sort(param_collection)
    }
    if (this.isAlnum(param_iteratees)) {
      return this._internal_sort(param_collection, param_iteratees)
    }
    if (this.isFunction(param_iteratees)) {
      for key, value in param_collection {
        l_array[A_Index] := Map()
        l_array[A_Index].value := value
        l_array[A_Index].key := param_iteratees.call(value)
      }
      l_array := this._internal_sort(l_array, "key")
      return this.map(l_array, "value")
    }
    if (isObject(param_iteratees)) {
      l_array := this.cloneDeep(param_collection)
      for key, value in param_iteratees {
        l_array := this._internal_sort(l_array, value)
      }
      return l_array
    }
    return -1
  }
  static _internal_sort(param_collection, param_iteratees := "") {
    out := ""
    l_array := this.cloneDeep(param_collection)
    if (param_iteratees != "") {
      for index, obj in l_array {
        out .= obj[param_iteratees] "+" index "|"
      }
      lastvalue := l_array[index][param_iteratees]
    } else {
      for index, obj in l_array {
        out .= obj "+" index "|"
      }
      lastvalue := l_array[(Type(temp := l_array) == "Array" ? temp.Length : temp.Count)]
    }
    if (this.isNumber(lastvalue)) {
      sortType := "N"
    }
    out := SubStr(out, 1, -1)
    out := Sort(out, "D| " sortType)
    arrStorage := []
    Loop Parse out, "|" {
      arrStorage.push(l_array[subStr(A_LoopField, ("+" == "" || inStr(A_LoopField, "+")) + 1)])
    }
    return arrStorage
  }
  static now() {
    nowUTC := A_NowUTC
    nowUTC := DateDiff(nowUTC, 19700101000000, "s")
    return nowUTC "000"
  }
  static ary(param_func, param_n := "") {
    if (!this.isFunction(param_func)) {
      this._internal_ThrowException()
    }
    if (param_n == "") {
      param_n := param_func.maxParams
    }
    boundFunc := objBindMethod(this, "_internal_ary", param_func, param_n)
    return boundFunc
  }
  static _internal_ary(param_func, param_n, param_args*) {
    param_args := this.slice(param_args, 1, param_n)
    return param_func.call(param_args*)
  }
  static delay(param_func, param_wait, param_args*) {
    if (!this.isFunction(param_func) || !this.isNumber(param_wait)) {
      this._internal_ThrowException()
    }
    if ((Type(temp := param_args) == "Array" ? temp.Length : temp.Count) == 0) {
      boundFunc := param_func
    } else {
      boundFunc := param_func.bind(param_args*)
    }
    setTimer boundFunc, -1 * param_wait
    return true
  }
  static flip(param_func) {
    if (!this.isFunction(param_func)) {
      this._internal_ThrowException()
    }
    boundFunc := objBindMethod(this, "_internal_flip", param_func)
    return boundFunc
  }
  static _internal_flip(param_func, param_args*) {
    param_args := this.reverse(param_args)
    return param_func.call(param_args*)
  }
  static _internal_MD5(param_string, case_ := 0) {
    o := ""
    if (isObject(param_string)) {
      param_string := this._internal_stringify(param_string)
    }
    digestLength := 16
    hModule := dllCall("loadlibrary", "str", "advapi32.dll", "ptr"), MD5_CTX := Buffer(104, 0), dllCall("advapi32\MD5Init", "ptr", MD5_CTX), dllCall("advapi32\MD5Update", "ptr", MD5_CTX, "AStr", param_string, "UInt", strLen(param_string)), dllCall("advapi32\MD5Final", "ptr", MD5_CTX)
    loop digestLength {
      o .= format("{:02" (case_ ? "X" : "x") "}", numGet(MD5_CTX, 87 + A_Index, "UChar"))
    }
    dllCall("freelibrary", "ptr", hModule)
    return o
  }
  static _internal_JSRegEx(param_string) {
    if (!this.isString(param_string) && !this.isAlnum(param_string)) {
      this._internal_ThrowException()
    }
    if (this.startsWith(param_string, "/") && this.endsWith(param_string, "/")) {
      return subStr(param_string, 2, strLen(param_string) - 2)
    }
    return false
  }
  static _internal_detectShorthand(param_shorthand, param_objects := "") {
    if (this._internal_detectOwnMethods(param_shorthand)) {
      return "_classMethod"
    }
    if (isObject(param_shorthand) && !this.isFunction(param_shorthand)) {
      if (param_shorthand.maxIndex() != (Type(temp := param_shorthand) == "Array" ? temp.Length : temp.Count)) {
        return ".matches"
      }
      return ".matchesProperty"
    }
    if (this.isStringLike(param_shorthand) && isObject(param_objects)) {
      for key, value in param_objects {
        if (value.Has(param_shorthand)) {
          return ".property"
        }
      }
    }
    if (param_shorthand == "__identity") {
      return param_shorthand
    }
    return false
  }
  static _internal_createShorthandfn(param_shorthand, param_objects := "") {
    shorthand := this._internal_detectShorthand(param_shorthand, param_objects)
    if (shorthand == "_classMethod") {
      return param_shorthand.bind(this)
    }
    if (shorthand == ".matches") {
      return this.matches(param_shorthand)
    }
    if (shorthand == ".matchesProperty") {
      return this.matchesProperty(param_shorthand[1], param_shorthand[2])
    }
    if (shorthand == ".property") {
      return this.property(param_shorthand)
    }
    if (param_shorthand == "__identity") {
      boundFunc := objBindMethod(this, "identity")
      return boundFunc
    }
  }
  static _internal_detectOwnMethods(param_iteratee) {
    if (this.startsWith(param_iteratee.name, this.__Class ".") && isObject(param_iteratee)) {
      return true
    }
    return false
  }
  static _internal_iterateeDetails(param_iteratee) {
    returnObj := Map()
    returnObj.methodName := strSplit(param_iteratee.name, ".").2
    returnObj.guarded := this.includes(this._guardedMethods, returnObj.methodName)
    if (this.includes(this._guardedCallWithOne, returnObj.methodName)) {
      returnObj.iteratee := param_iteratee.bind(this, 1)
    } else if (this.includes(this._guardedMethods, returnObj.methodName)) {
      returnObj.iteratee := param_iteratee.bind(this)
    }
    return returnObj
  }
  static _internal_ThrowException() {
    if (this.throwExceptions == true) {
      throw Error("Type Error", -2)
    }
  }
  static _internal_inStr(param_haystack, param_needle, param_fromIndex := 1, param_occurance := 1) {
    global A_StringCaseSense
    param_collection := ""
    param_value := ""
    if ((IsSet(A_StringCaseSense) ? A_StringCaseSense : A_StringCaseSense := "Off") == "On") {
      StringCaseSense := 1
    } else {
      StringCaseSense := 0
    }
    if (position := (param_value == "" || inStr(param_collection, param_value, StringCaseSense, param_fromIndex, param_occurance))) {
      return position
    } else {
      return false
    }
  }
  static isFalsey(param) {
    if (isObject(param)) {
      return false
    }
    if (param == "" || param == 0) {
      return true
    }
    return false
  }
  static isStringLike(param) {
    if (this.isString(param) || this.isAlnum(param)) {
      return true
    }
    return false
  }
  static castArray(param_value := "__default") {
    if (this.isArray(param_value)) {
      return param_value.clone()
    } else if (param_value == "__default") {
      return []
    }
    return [param_value]
  }
  static clone(param_value) {
    if (isObject(param_value)) {
      return param_value.clone()
    } else {
      return param_value
    }
  }
  static cloneDeep(param_array) {
    objs := Map()
    obj := param_array.clone()
    objs[(IsObject(temp := param_array) ? ObjPtr(temp) : StrPtr(temp))] := obj
    for key, value in obj {
      if (isObject(value))
        obj[key] := objs.Has((IsObject(temp2 := value) ? ObjPtr(temp2) : StrPtr(temp2))) ? objs[(IsObject(temp3 := value) ? ObjPtr(temp3) : StrPtr(temp3))] : this.clone(value)
    }
    return obj
  }
  static conformsTo(param_object, param_source) {
    if (!isObject(param_object) || !isObject(param_source)) {
      this._internal_ThrowException()
    }
    for key, value in param_source {
      if (!value.call(param_object[key])) {
        return false
      }
    }
    return true
  }
  static eq(param_value, param_other) {
    if (isObject(param_value)) {
      param_value := this._internal_stringify(param_value)
      param_other := this._internal_stringify(param_other)
    }
    if (param_value == param_other) {
      return true
    }
    return false
  }
  static gt(param_value, param_other) {
    if (!this.isNumber(param_value) || !this.isNumber(param_other)) {
      this._internal_ThrowException()
    }
    if (param_value > param_other) {
      return true
    }
    return false
  }
  static gte(param_value, param_other) {
    if (!this.isNumber(param_value) || !this.isNumber(param_other)) {
      this._internal_ThrowException()
    }
    if (param_value >= param_other) {
      return true
    }
    return false
  }
  static isAlnum(param) {
    if (isObject(param)) {
      return false
    }
    if (IsAlnum(param)) {
      return true
    }
    return false
  }
  static isArray(param) {
    if (((Type(temp := param) == "Array" && temp.Length))) {
      return true
    }
    return false
  }
  static isBoolean(param) {
    if (param == 1) {
      return true
    }
    if (param == 0) {
      return true
    }
    return false
  }
  static isEqual(param_value, param_other*) {
    if (isObject(param_value)) {
      l_array := []
      param_value := this._internal_stringify(param_value)
      loop (Type(temp := param_other) == "Array" ? temp.Length : temp.Count) {
        l_array.push(this._internal_stringify(param_other[A_Index]))
      }
    } else {
      l_array := this.cloneDeep(param_other)
    }
    loop (Type(temp2 := l_array) == "Array" ? temp2.Length : temp2.Count) {
      if (param_value != l_array[A_Index]) {
        return false
      }
    }
    return true
  }
  static isError(param_value) {
    if (param_value.Has("message") && param_value.Has("what") && param_value.Has("file") && param_value.Has("line")) {
      return true
    }
    return false
  }
  static isFloat(param) {
    if (IsFloat(param)) {
      return true
    }
    return false
  }
  static isFunction(param) {
    funcRefrence := numGet((IsObject(temp := (_ := inStr.bind())) ? ObjPtr(temp) : StrPtr(temp)), "ptr")
    return ((IsSet(%param%) && HasMethod(%param%)) || (isObject(param) && (numGet((IsObject(temp2 := param) ? ObjPtr(temp2) : StrPtr(temp2)), "ptr") = funcRefrence)))
  }
  static isInteger(param) {
    if (IsInteger(param)) {
      if (!this.isString(param)) {
        return true
      }
    }
    return false
  }
  static isMatch(param_object, param_source) {
    for key, value in param_source {
      if (param_object[key] == value) {
        continue
      } else {
        return false
      }
    }
    return true
  }
  static isNumber(param) {
    if (IsNumber(param)) {
      return true
    }
    return false
  }
  static isObject(param) {
    if (isObject(param)) {
      return true
    }
    return false
  }
  static isString(param) {
    if (Type(param) == "String") {
      return false
    }
    return true
  }
  static isUndefined(param_value) {
    if (param_value == "") {
      return true
    }
    return false
  }
  static lt(param_value, param_other) {
    if (!this.isNumber(param_value) || !this.isNumber(param_other)) {
      this._internal_ThrowException()
    }
    if (param_value < param_other) {
      return true
    }
    return false
  }
  static lte(param_value, param_other) {
    if (!this.isNumber(param_value) || !this.isNumber(param_other)) {
      this._internal_ThrowException()
    }
    if (param_value <= param_other) {
      return true
    }
    return false
  }
  static toArray(param_value) {
    if (isObject(param_value)) {
      return this.map(param_value)
    } else if (this.isString(param_value)) {
      return strSplit(param_value)
    }
    return []
  }
  static toLength(param_value) {
    return this.floor(param_value)
  }
  static toString(param_value) {
    if (isObject(param_value)) {
      return this.join(param_value, ",")
    } else {
      return "" param_value
    }
  }
  static typeOf(param_value := "__default") {
    if (isObject(param_value)) {
      return "object"
    }
    if (param_value == "") {
      return "undefined"
    }
    if this.isFloat(param_value) {
      return "float"
    }
    return param_value := "" || (Type(param_value) == "String" || "") ? "string" : "integer"
  }
  static add(param_augend, param_addend) {
    if (!this.isNumber(param_augend) || !this.isNumber(param_addend)) {
      this._internal_ThrowException()
    }
    return param_augend + param_addend
  }
  static ceil(param_number, param_precision := 0) {
    if (!this.isNumber(param_number) || !this.isNumber(param_precision)) {
      this._internal_ThrowException()
    }
    if (param_precision == 0) {
      return ceil(param_number)
    }
    l_offset := 0.5 / (10 ** param_precision)
    if (param_number < 0 && param_precision >= 1) {
      l_offset /= 10
    }
    if (param_precision >= 1) {
      l_decChar := strLen(substr(param_number, ("." == "" || inStr(param_number, ".")) + 1))
      l_sum := format("{:." this.max([l_decChar, param_precision]) + 1 "f}", param_number + l_offset)
    } else {
      l_sum := param_number + l_offset
    }
    l_sum := trim(l_sum, "0")
    l_value := (subStr(l_sum, 0) = "5") && param_number != l_sum ? subStr(l_sum, 1, -1) : l_sum
    return round(l_value, param_precision)
  }
  static divide(param_dividend, param_divisor) {
    if (!this.isNumber(param_dividend) || !this.isNumber(param_divisor)) {
      this._internal_ThrowException()
    }
    return param_dividend / param_divisor
  }
  static floor(param_number, param_precision := 0) {
    if (!this.isNumber(param_number) || !this.isNumber(param_precision)) {
      this._internal_ThrowException()
    }
    if (param_precision == 0) {
      return floor(param_number)
    }
    l_offset := -0.5 / (10 ** param_precision)
    if (param_number < 0 && param_precision >= 1) {
      l_offset /= 10
    }
    if (param_precision >= 1) {
      l_decChar := strLen(substr(param_number, ("." == "" || inStr(param_number, ".")) + 1))
      l_sum := format("{:." this.max([l_decChar, param_precision]) + 1 "f}", param_number + l_offset)
    } else {
      l_sum := param_number + l_offset
    }
    l_sum := trim(l_sum, "0")
    l_value := (subStr(l_sum, 0) = "5") && param_number != l_sum ? subStr(l_sum, 1, -1) : l_sum
    return round(l_value, param_precision)
  }
  static max(param_array) {
    if (!isObject(param_array)) {
      this._internal_ThrowException()
    }
    l_max := ""
    for key, value in param_array {
      if (l_max < value || this.isUndefined(l_max)) {
        l_max := value
      }
    }
    return l_max
  }
  static maxBy(param_array, param_iteratee := "__identity") {
    if (!isObject(param_array)) {
      this._internal_ThrowException()
    }
    shorthand := this._internal_detectShorthand(param_iteratee, param_array)
    if (shorthand) {
      param_iteratee := this._internal_createShorthandfn(param_iteratee, param_array)
    }
    l_max := 0
    for key, value in param_array {
      if (this.isFunction(param_iteratee)) {
        l_iteratee := param_iteratee.call(value)
      }
      if (l_iteratee > l_max) {
        l_max := l_iteratee
        l_return := value
      }
    }
    return l_return
  }
  static mean(param_array) {
    if (!isObject(param_array)) {
      this._internal_ThrowException()
    }
    return this.sum(param_array) / param_array.maxIndex()
  }
  static meanBy(param_array, param_iteratee := "__identity") {
    if (!isObject(param_array)) {
      this._internal_ThrowException()
    }
    shorthand := this._internal_detectShorthand(param_iteratee, param_array)
    if (shorthand) {
      param_iteratee := this._internal_createShorthandfn(param_iteratee, param_array)
    }
    l_total := 0
    for key, value in param_array {
      if (this.isFunction(param_iteratee)) {
        l_iteratee := param_iteratee.call(value)
      }
      l_total += l_iteratee
    }
    return l_total / (Type(temp := param_array) == "Array" ? temp.Length : temp.Count)
  }
  static min(param_array) {
    if (!isObject(param_array)) {
      this._internal_ThrowException()
    }
    l_min := ""
    for key, value in param_array {
      if (value < l_min || this.isUndefined(l_min)) {
        l_min := value
      }
    }
    return l_min
  }
  static minBy(param_array, param_iteratee := "__identity") {
    if (!isObject(param_array)) {
      this._internal_ThrowException()
    }
    shorthand := this._internal_detectShorthand(param_iteratee, param_array)
    if (shorthand) {
      param_iteratee := this._internal_createShorthandfn(param_iteratee, param_array)
    }
    l_min := ""
    for key, value in param_array {
      if (this.isFunction(param_iteratee)) {
        l_iteratee := param_iteratee.call(value)
      }
      if (l_iteratee < l_min || this.isUndefined(l_min)) {
        l_min := l_iteratee
        l_return := value
      }
    }
    return l_return
  }
  static multiply(param_multiplier, param_multiplicand) {
    if (!this.isNumber(param_multiplier) || !this.isNumber(param_multiplicand)) {
      this._internal_ThrowException()
    }
    return param_multiplier * param_multiplicand
  }
  static round(param_number, param_precision := 0) {
    if (!this.isNumber(param_number) || !this.isNumber(param_precision)) {
      this._internal_ThrowException()
    }
    return round(param_number, param_precision)
  }
  static subtract(param_minuend, param_subtrahend) {
    if (!this.isNumber(param_minuend) || !this.isNumber(param_subtrahend)) {
      this._internal_ThrowException()
    }
    param_minuend -= param_subtrahend
    return param_minuend
  }
  static sum(param_array) {
    if (!isObject(param_array)) {
      this._internal_ThrowException()
    }
    vSum := 0
    for key, value in param_array {
      vSum += value
    }
    return vSum
  }
  static sumBy(param_array, param_iteratee := "__identity") {
    if (!isObject(param_array)) {
      this._internal_ThrowException()
    }
    shorthand := this._internal_detectShorthand(param_iteratee, param_array)
    if (shorthand) {
      param_iteratee := this._internal_createShorthandfn(param_iteratee, param_array)
    }
    l_total := 0
    for key, value in param_array {
      if (this.isFunction(param_iteratee)) {
        l_iteratee := param_iteratee.call(value)
      }
      l_total += l_iteratee
    }
    return l_total
  }
  static clamp(param_number, param_lower, param_upper) {
    if (!this.isNumber(param_number) || !this.isNumber(param_lower) || !this.isNumber(param_upper)) {
      this._internal_ThrowException()
    }
    if (param_number < param_lower) {
      param_number := param_lower
    }
    if (param_number > param_upper) {
      param_number := param_upper
    }
    return param_number
  }
  static inRange(param_number, param_start := 0, param_end := "") {
    if (!this.isNumber(param_number) || !this.isNumber(param_start) || isObject(param_end)) {
      this._internal_ThrowException()
    }
    if (param_end == "") {
      param_end := param_start
      param_start := 0
    }
    if (param_start > param_end) {
      l_temp := param_start
      param_start := param_end
      param_end := l_temp
    }
    if (param_number > param_start && param_number < param_end) {
      return true
    }
    return false
  }
  static random(param_lower := 0, param_upper := 1, param_floating := false) {
    if (!this.isNumber(param_lower) || !this.isNumber(param_upper) || !this.isNumber(param_floating)) {
      this._internal_ThrowException()
    }
    if (param_lower > param_upper) {
      l_temp := param_lower
      param_lower := param_upper
      param_upper := l_temp
    }
    if (param_floating) {
      param_lower += 0.0
      param_upper += 0.0
    }
    vRandom := Random(param_lower, param_upper)
    return vRandom
  }
  static at(param_object, param_paths, param_defaultValue := "") {
    if (!isObject(param_object)) {
      this._internal_ThrowException()
    }
    l_array := []
    for key, value in param_paths {
      l_array.push(this.get(param_object, value))
    }
    return l_array
  }
  static defaults(param_object, param_sources*) {
    if (!isObject(param_object)) {
      this._internal_ThrowException()
    }
    l_obj := this.clone(param_object)
    param_sources := this.reverse(param_sources)
    for index, object in param_sources {
      for key, value in object {
        if (!l_obj.Has(key)) {
          l_obj[key] := value
        }
      }
    }
    return l_obj
  }
  static findKey(param_collection, param_predicate, param_fromindex := 1) {
    if (!isObject(param_collection)) {
      this._internal_ThrowException()
    }
    shorthand := this._internal_detectShorthand(param_predicate, param_collection)
    if (shorthand != false) {
      param_predicate := this._internal_createShorthandfn(param_predicate, param_collection)
    }
    for key, value in param_collection {
      if (param_fromindex > A_Index) {
        continue
      }
      if (this.isFunction(param_predicate)) {
        if (param_predicate.call(value)) {
          return key
        }
      }
    }
    return false
  }
  static forIn(param_object, param_iteratee := "__identity") {
    if (!isObject(param_object)) {
      this._internal_ThrowException()
    }
    l_object := this.cloneDeep(param_object)
    if (param_iteratee == "__identity") {
      param_iteratee := this.identity().bind(param_object)
    }
    for key, value in param_object {
      if (this.isFunction(param_iteratee)) {
        if (param_iteratee.call(value, key, l_object) == false) {
          break
        }
      }
    }
    return param_object
  }
  static forInRight(param_object, param_iteratee := "__identity") {
    if (!isObject(param_object)) {
      this._internal_ThrowException()
    }
    l_object := this.reverse(param_object)
    this.forIn(l_object, param_iteratee)
    return param_object
  }
  static get(param_object, param_path, param_defaultValue := "") {
    if (!isObject(param_object)) {
      this._internal_ThrowException()
    }
    if (!isObject(param_path)) {
      param_path := this.compact(this.split(param_path, this._pathRegex))
    }
    returnValue := param_object[param_path*]
    if (returnValue == "") {
      returnValue := param_defaultValue
    }
    return returnValue
  }
  static has(param_object, param_path) {
    if (!isObject(param_object)) {
      this._internal_ThrowException()
    }
    if (this.isStringLike(param_path)) {
      l_path := this.toPath(param_path)
    } else {
      l_path := this.cloneDeep(param_path)
    }
    for key, value in l_path {
      if (!param_object.Has(value)) {
        return false
      }
      param_object := param_object[value]
    }
    return true
  }
  static invert(param_object) {
    if (!isObject(param_object)) {
      this._internal_ThrowException()
    }
    l_obj := this.cloneDeep(param_object)
    l_newObj := Map()
    for key, value in l_obj {
      l_newObj[value] := key
    }
    return l_newObj
  }
  static invertBy(param_object, param_iteratee := "__identity") {
    if (!isObject(param_object)) {
      this._internal_ThrowException()
    }
    shorthand := this._internal_detectShorthand(param_iteratee, param_object)
    if (shorthand) {
      param_iteratee := this._internal_createShorthandfn(param_iteratee, param_object)
    }
    l_obj := this.cloneDeep(param_object)
    l_newObj := Map()
    for key, value in l_obj {
      if (this.isFunction(param_iteratee)) {
        vkey := param_iteratee.call(value)
      }
      if (!l_newObj.Has(vkey)) {
        l_newObj[vkey] := []
      }
      l_newObj[vkey].push(key)
    }
    return l_newObj
  }
  static keys(param_object) {
    if (!isObject(param_object)) {
      param_object := strSplit(param_object)
    }
    l_returnkeys := []
    for key, _ in param_object {
      l_returnkeys.push(key)
    }
    return l_returnkeys
  }
  static mapKeys(param_object, param_iteratee := "__identity") {
    if (!isObject(param_object)) {
      this._internal_ThrowException()
    }
    shorthand := this._internal_detectShorthand(param_iteratee, param_object)
    if (shorthand) {
      param_iteratee := this._internal_createShorthandfn(param_iteratee, param_object)
    }
    l_object := this.cloneDeep(param_object)
    l_array := Map()
    if (this.isFunction(param_iteratee)) {
      for key, value in l_object {
        l_array[param_iteratee.call(value, key, l_object)] := A_Index
      }
    }
    return l_array
  }
  static mapValues(param_object, param_iteratee := "__identity") {
    if (!isObject(param_object)) {
      this._internal_ThrowException()
    }
    shorthand := this._internal_detectShorthand(param_iteratee, param_object)
    if (shorthand) {
      param_iteratee := this._internal_createShorthandfn(param_iteratee, param_object)
    }
    l_object := this.cloneDeep(param_object)
    l_array := Map()
    if (this.isFunction(param_iteratee)) {
      for key, value in l_object {
        l_array[key] := param_iteratee.call(value, key, l_object)
      }
    }
    return l_array
  }
  static merge(param_collections*) {
    if (!isObject(param_collections)) {
      this._internal_ThrowException()
    }
    result := param_collections[1]
    for index, obj in param_collections {
      if (A_Index == 1) {
        continue
      }
      result := this.internal_Merge(result, obj)
    }
    return result
  }
  static internal_Merge(param_value1, param_value2) {
    combined := Map()
    if (!isObject(param_value1) && !isObject(param_value2)) {
      if (this.isUndefined(param_value1) && this.isUndefined(param_value2)) {
        return param_value2
      }
      if (!this.isUndefined(param_value1) && this.isUndefined(param_value2)) {
        return param_value1
      }
      return param_value2
    }
    for key, value in param_value1 {
      combined[key] := this.internal_Merge(value, param_value2[key])
    }
    for key, value in param_value2 {
      if (!combined.Has(key)) {
        combined[key] := value
      }
    }
    return combined
  }
  static omit(param_object, param_paths) {
    if (!isObject(param_object)) {
      this._internal_ThrowException()
    }
    l_obj := this.cloneDeep(param_object)
    if (isObject(param_paths)) {
      for key, value in param_paths {
        l_obj.delete(value)
      }
    } else {
      l_obj.delete(param_paths)
    }
    return l_obj
  }
  static pick(param_object, param_paths) {
    if (!isObject(param_object)) {
      this._internal_ThrowException()
    }
    l_obj := Map()
    if (isObject(param_paths)) {
      for key, value in param_paths {
        l_obj[value] := this.get(param_object, value)
      }
    } else {
      l_deepPath := this.toPath(param_paths)
      l_obj[l_deepPath*] := param_object[l_deepPath*]
    }
    return l_obj
  }
  static pickBy(param_object, param_predicate := "__identity") {
    param_collection := ""
    if (!isObject(param_object)) {
      this._internal_ThrowException()
    }
    shorthand := this._internal_detectShorthand(param_predicate, param_collection)
    if (shorthand) {
      param_predicate := this._internal_createShorthandfn(param_predicate, param_collection)
    }
    l_obj := Map()
    for key, value in param_object {
      if (this.isFunction(param_predicate)) {
        if (!this.isFalsey(param_predicate.call(value, key))) {
          l_obj[key] := value
        }
      }
    }
    return l_obj
  }
  static toPairs(param_object) {
    if (!isObject(param_object)) {
      this._internal_ThrowException()
    }
    l_array := []
    for key, value in param_object {
      l_array.push([key, value])
    }
    return l_array
  }
  static camelCase(param_string := "") {
    if (!this.isStringLike(param_string)) {
      this._internal_ThrowException()
    }
    l_parseChr := "/[_ -]+/"
    l_arr := this.compact(this.split(param_string, l_parseChr))
    if ((Type(temp := l_arr) == "Array" ? temp.Length : temp.Count) > 1) {
      l_head := this.toLower(this.head(l_arr))
      l_tail := this.join(this.map(this.tail(l_arr), this.startCase), "")
    } else {
      l_head := this.toLower(this.head(param_string))
      l_tail := this.join(this.tail(param_string), "")
    }
    return l_head l_tail
  }
  static endsWith(param_string, param_needle, param_fromIndex := 0) {
    if (!this.isString(param_string) || !this.isString(param_needle) || !this.isNumber(param_fromIndex)) {
      this._internal_ThrowException()
    }
    if (param_fromIndex == 0) {
      param_fromIndex := strLen(param_string)
    }
    if (strLen(param_needle) > 1) {
      param_fromIndex := strLen(param_string) - strLen(param_needle) + 1
    }
    l_endChar := subStr(param_string, param_fromIndex, strLen(param_needle))
    if (this.isEqual(l_endChar, param_needle)) {
      return true
    }
    return false
  }
  static escape(param_string := "") {
    if (!this.isStringLike(param_string)) {
      this._internal_ThrowException()
    }
    HTMLmap := [["&", "&amp`;"], ["<", "&lt`;"], [">", "&gt`;"], ["`"", "&quot`;"], ["'", "&#39`;"]]
    for key, value in HTMLmap {
      element := value
      param_string := strReplace(param_string, element.1, element.2, , -1)
    }
    return param_string
  }
  static kebabCase(param_string := "") {
    RE_Match.0 := ""
    if (!this.isStringLike(param_string)) {
      this._internal_ThrowException()
    }
    l_string := this.trim(param_string, "- _")
    regExMatch(l_string, "O)([A-Z])", &RE_Match)
    if ((Type(temp := RE_Match.0) == "Array" ? temp.Length : temp.Count)) {
      loop (Type(temp2 := RE_Match.0) == "Array" ? temp2.Length : temp2.Count) {
        l_string := subStr(l_string, 1, RE_Match.Pos(A_Index) - 1) " " subStr(l_string, RE_Match.Pos(A_Index))
      }
    }
    l_arr := this.split(l_string, "/\s/")
    if ((Type(temp3 := l_arr) == "Array" ? temp3.Length : temp3.Count) > 1) {
      l_string := this.join(this.compact(l_arr), "-")
    }
    l_string := this.toLower(l_string)
    l_string := strReplace(l_string, "_", "-")
    return l_string
  }
  static lowerCase(param_string := "") {
    if (!this.isStringLike(param_string)) {
      this._internal_ThrowException()
    }
    l_string := this.startCase(param_string)
    l_string := this.toLower(this.trim(l_string))
    return l_string
  }
  static lowerFirst(param_string := "") {
    if (!this.isStringLike(param_string)) {
      this._internal_ThrowException()
    }
    return this.tolower(subStr(param_string, 1, 1)) subStr(param_string, 2)
  }
  static pad(param_string := "", param_length := 0, param_chars := " ") {
    if (!this.isStringLike(param_string) || !this.isNumber(param_length) || !this.isStringLike(param_chars)) {
      this._internal_ThrowException()
    }
    if (param_length <= strLen(param_string)) {
      return param_string
    }
    param_length := param_length - strLen(param_string)
    l_start := this.floor(param_length / 2)
    l_end := this.ceil(param_length / 2)
    l_start := this.padStart("", l_start, param_chars)
    l_end := this.padEnd("", l_end, param_chars)
    return l_start param_string l_end
  }
  static padEnd(param_string := "", param_length := 0, param_chars := " ") {
    l_pos := 0
    if (!this.isStringLike(param_string) || !this.isNumber(param_length) || !this.isStringLike(param_chars)) {
      this._internal_ThrowException()
    }
    if (param_length <= strLen(param_string)) {
      return param_string
    }
    l_pad := this.slice(param_chars)
    l_string := param_string
    while (strLen(l_string) < param_length) {
      l_pos++
      if (l_pos > (Type(temp := l_pad) == "Array" ? temp.Length : temp.Count)) {
        l_pos := 1
      }
      l_string .= l_pad[l_pos]
    }
    return l_string
  }
  static padStart(param_string := "", param_length := 0, param_chars := " ") {
    l_padding := ""
    l_pos := 0
    if (!this.isStringLike(param_string) || !this.isNumber(param_length) || !this.isStringLike(param_chars)) {
      this._internal_ThrowException()
    }
    if (param_length <= strLen(param_string)) {
      return param_string
    }
    l_pad := this.slice(param_chars)
    while (strLen(param_string) + strLen(l_padding) < param_length) {
      l_pos++
      if (l_pos > (Type(temp := l_pad) == "Array" ? temp.Length : temp.Count)) {
        l_pos := 1
      }
      l_padding .= l_pad[l_pos]
    }
    return l_padding . param_string
  }
  static parseInt(param_string := "0") {
    if (!this.isStringLike(param_string)) {
      this._internal_ThrowException()
    }
    l_int := this.trimStart(param_string, " 0_")
    if (this.size(l_int) == 0 && ("0" == "" || inStr(param_string, "0"))) {
      return 0
    }
    if (this.isNumber(l_int)) {
      return l_int
    }
    l_int := this.replace(l_int, "/\D+/")
    if (this.isNumber(l_int)) {
      return l_int
    }
    return ""
  }
  static repeat(param_string, param_number := 1) {
    if (!this.isString(param_string) || (!this.isNumber(param_number))) {
      this._internal_ThrowException()
    }
    if (param_number == 0) {
      return ""
    }
    return strReplace(format("{:0" param_number "}", 0), "0", param_string)
  }
  static replace(param_string := "", param_needle := "", param_replacement := "") {
    if (!this.isStringLike(param_string) || !this.isStringLike(param_needle) || !this.isStringLike(param_replacement)) {
      this._internal_ThrowException()
    }
    l_string := param_string
    if (l_needle := this._internal_JSRegEx(param_needle)) {
      return regexReplace(param_string, l_needle, param_replacement, , this.limit)
    }
    output := strReplace(l_string, param_needle, param_replacement, , this.limit)
    return output
  }
  static snakeCase(param_string := "") {
    if (!this.isStringLike(param_string)) {
      this._internal_ThrowException()
    }
    l_string := this.trim(param_string, "-_")
    l_string := this.kebabCase(l_string)
    l_string := strReplace(l_string, "-", "_")
    return l_string
  }
  static split(param_string := "", param_separator := ",", param_limit := 0) {
    if (!this.isStringLike(param_string) || !this.isStringLike(param_separator) || !this.isNumber(param_limit)) {
      this._internal_ThrowException()
    }
    if (this._internal_JSRegEx(param_separator)) {
      param_string := this.replace(param_string, param_separator, ",")
      param_separator := ","
    }
    oSplitArray := strSplit(param_string, param_separator)
    if (!param_limit) {
      return oSplitArray
    } else {
      oReducedArray := []
      loop param_limit {
        if (A_Index <= (Type(temp := oSplitArray) == "Array" ? temp.Length : temp.Count)) {
          oReducedArray.push(oSplitArray[A_Index])
        }
      }
    }
    return oReducedArray
  }
  static startCase(param_string := "") {
    RE_Match.0 := ""
    if (!this.isStringLike(param_string)) {
      this._internal_ThrowException()
    }
    l_string := this.replace(param_string, "/[_ -]/", " ")
    regExMatch(l_string, "O)([A-Z])", &RE_Match)
    if ((Type(temp := RE_Match.0) == "Array" ? temp.Length : temp.Count)) {
      loop (Type(temp2 := RE_Match.0) == "Array" ? temp2.Length : temp2.Count) {
        l_string := subStr(l_string, 1, RE_Match.Pos(A_Index) - 1) " " subStr(l_string, RE_Match.Pos(A_Index))
      }
    }
    l_array := strSplit(l_string, " ")
    loop (Type(temp3 := l_array) == "Array" ? temp3.Length : temp3.Count) {
      l_string := l_array[A_Index]
      l_string := StrTitle(l_string)
      l_array[A_Index] := l_string
    }
    l_string := this.join(l_array, " ")
    l_string := trim(l_string)
    return l_string
  }
  static startsWith(param_string, param_needle, param_fromIndex := 1) {
    if (!this.isStringLike(param_string) || !this.isStringLike(param_needle) || !this.isNumber(param_fromIndex)) {
      this._internal_ThrowException()
    }
    l_startString := subStr(param_string, param_fromIndex, strLen(param_needle))
    if (this.isEqual(l_startString, param_needle)) {
      return true
    }
    return false
  }
  static toLower(param_string) {
    if (!this.isString(param_string)) {
      this._internal_ThrowException()
    }
    out := StrTitle(param_string)
    return out
  }
  static toUpper(param_string) {
    if (!this.isString(param_string)) {
      this._internal_ThrowException()
    }
    out := StrTitle(param_string)
    return out
  }
  static trim(param_string, param_chars := "") {
    if (!this.isStringLike(param_string) || !this.isStringLike(param_chars)) {
      this._internal_ThrowException()
    }
    if (param_chars == "") {
      return this.trim(param_string, "`r`n" A_space A_tab)
    } else {
      l_string := this.trimStart(param_string, param_chars)
      l_string := this.trimEnd(l_string, param_chars)
      return l_string
    }
  }
  static trimEnd(param_string, param_chars := "") {
    l_removechars := ""
    if (!this.isStringLike(param_string) || !this.isStringLike(param_chars)) {
      this._internal_ThrowException()
    }
    if (param_chars = "") {
      l_string := param_string
      return regexreplace(l_string, "(\s+)$")
    } else {
      l_array := strSplit(param_chars, "")
      for key, value in l_array {
        if (this.includes(value, "/[a-zA-Z0-9]/")) {
          l_removechars .= value
        } else {
          l_removechars .= "\" value
        }
      }
      l_string := this.replace(param_string, "/([" l_removechars "]+)$/", "")
      return l_string
    }
  }
  static trimStart(param_string, param_chars := "") {
    l_removechars := ""
    if (!this.isStringLike(param_string) || !this.isStringLike(param_chars)) {
      this._internal_ThrowException()
    }
    if (param_chars = "") {
      return regexReplace(param_string, "^(\s+)")
    } else {
      l_array := strSplit(param_chars, "")
      for key, value in l_array {
        if (this.includes(value, "/[a-zA-Z0-9]/")) {
          l_removechars .= value
        } else {
          l_removechars .= "\" value
        }
      }
      l_string := this.replace(param_string, "/^([" l_removechars "]+)/", "")
      return l_string
    }
  }
  static truncate(param_string, param_options := "") {
    if (!this.isString(param_string)) {
      this._internal_ThrowException()
    }
    if (!isObject(param_options)) {
      param_options := Map()
      param_options.length := 30
    }
    if (!param_options.Has("omission")) {
      param_options.omission := "..."
    }
    if (strLen(param_string) < param_options.length && !param_options.separator) {
      return param_string
    }
    l_string := subStr(param_string, 1, param_options.length)
    if (this._internal_JSRegEx(param_options.separator)) {
      param_options.separator := this._internal_JSRegEx(param_options.separator)
    }
    if (param_options.separator) {
      return regexReplace(l_string, "^(.{1," param_options.length "})" param_options.separator ".*$", "$1") param_options.omission
    }
    if (strLen(l_string) < strLen(param_string)) {
      l_string := subStr(l_string, 1, (strLen(l_string) - strLen(param_options.omission) + 1))
      l_string := l_string . param_options.omission
    }
    return l_string
  }
  static unescape(param_string := "") {
    if (!this.isStringLike(param_string)) {
      this._internal_ThrowException()
    }
    HTMLmap := [["&", "&amp`;"], ["<", "&lt`;"], [">", "&gt`;"], ["`"", "&quot`;"], ["'", "&#39`;"]]
    for key, value in HTMLmap {
      element := value
      param_string := strReplace(param_string, element.2, element.1, , -1)
    }
    return param_string
  }
  static upperCase(param_string := "") {
    if (!this.isStringLike(param_string)) {
      this._internal_ThrowException()
    }
    l_string := this.startCase(param_string)
    l_string := this.toUpper(this.trim(l_string))
    return l_string
  }
  static upperFirst(param_string := "") {
    if (!this.isStringLike(param_string)) {
      this._internal_ThrowException()
    }
    return this.toUpper(subStr(param_string, 1, 1)) subStr(param_string, 2)
  }
  static words(param_string, param_pattern := "/\b\w+(?:'\w+)?\b/") {
    if (!this.isString(param_string) || !this.isString(param_pattern)) {
      this._internal_ThrowException()
    }
    l_string := param_string
    l_array := []
    if (l_needle := this._internal_JSRegEx(param_pattern)) {
      param_pattern := l_needle
    }
    l_needle := "O)" param_pattern
    while (regExMatch(l_string, l_needle, &RE_Match)) {
      tempString := RE_Match.0
      l_array.push(tempString)
      l_string := subStr(l_string, RE_Match.Pos(0) + RE_Match.Len(0))
    }
    return l_array
  }
  static conforms(param_value) {
    if (!isObject(param_value)) {
      this._internal_ThrowException()
    }
    boundFunc := objBindMethod(this, "_internal_conforms", param_value)
    return boundFunc
  }
  static _internal_conforms(param_value, param_object) {
    for key, value in param_value {
      if (!value.call(param_object[key])) {
        return false
      }
    }
    return true
  }
  static constant(param_value) {
    boundFunc := objBindMethod(this, "_internal_constant", param_value)
    return boundFunc
  }
  static _internal_constant(param_value) {
    return param_value
  }
  static identity(param_value) {
    return param_value
  }
  static matches(param_source) {
    if (!isObject(param_source)) {
      this._internal_ThrowException()
    }
    boundFunc := objBindMethod(this, "internal_matches", param_source)
    return boundFunc
  }
  static internal_matches(param_matches, param_itaree) {
    for key, value in param_matches {
      if (param_matches[key] != param_itaree[key]) {
        return false
      }
    }
    return true
  }
  static matchesProperty(param_path, param_srcvalue) {
    if (!this.isStringLike(param_srcvalue)) {
      this._internal_ThrowException()
    }
    fnProperty := this.property(param_path)
    boundFunc := objBindMethod(this, "_internal_matchesProperty", fnProperty, param_srcvalue)
    return boundFunc
  }
  static _internal_matchesProperty(param_property, param_matchvalue, param_itaree) {
    itareevalue := param_property.call(param_itaree)
    if (!this.isUndefined(itareevalue)) {
      if (itareevalue = param_matchvalue) {
        return true
      }
    }
    return false
  }
  static noop() {
    return ""
  }
  static nthArg(param_n := 1) {
    if (!this.isNumber(param_n)) {
      this._internal_ThrowException()
    }
    if (param_n == 0) {
      param_n := 1
    }
    if (param_n > 0) {
      boundFunc := objBindMethod(this, "internal_nthArg", param_n)
    } else {
      boundFunc := objBindMethod(this, "internal_nthArgReverse", abs(param_n))
    }
    return boundFunc
  }
  static internal_nthArg(param_n, args*) {
    return args[param_n]
  }
  static internal_nthArgReverse(param_n, args*) {
    args := this.reverse(args)
    return args[param_n]
  }
  static over(param_iteratees := "__identity") {
    if (param_iteratees == "__identity") {
      param_iteratees := [this.identity]
    }
    if (this.isFunction(param_iteratees)) {
      param_iteratees := [param_iteratees]
    }
    for key, value in param_iteratees {
      if (this.isUndefined(value)) {
        param_iteratees[key] := this.identity.bind(this)
      }
      if (this.startsWith(value.name, this.__Class ".")) {
        param_iteratees[key] := value.bind(this)
      }
    }
    boundFunc := this._internal_over.bind(this, param_iteratees)
    return boundFunc
  }
  static _internal_over(param_func, param_args*) {
    l_output := []
    for key, value in param_func {
      l_output[key] := value.call(param_args*)
    }
    return l_output
  }
  static print(values*) {
    out := ""
    for key, value in values {
      out .= (isObject(value) ? this._internal_stringify(value) : value)
    }
    try {
      dllCall("AttachConsole", "int", -1)
      fileAppend "`n" out, "CONOUT$"
      dllCall("FreeConsole")
    } catch {
    }
    return out
  }
  static _internal_stringify(param_value) {
    output := ""
    if (!isObject(param_value)) {
      return "`"" param_value "`""
    }
    for key, value in param_value {
      if (!IsNumber(key)) {
        output .= "`"" . key . "`":"
      } else {
        output .= key . ":"
      }
      if (isObject(value)) {
        output .= "[" . this._internal_stringify(value) . "]"
      } else if (!IsNumber(value)) {
        output .= "`"" . value . "`""
      } else {
        output .= value
      }
      output .= ", "
    }
    return subStr(output, 1, -2)
  }
  static property(param_source) {
    param_source := this.toPath(param_source)
    if (isObject(param_source)) {
      keyArray := []
      for key, value in param_source {
        keyArray.push(value)
      }
      boundFunc := objBindMethod(this, "internal_property", keyArray)
      return boundFunc
    } else {
      boundFunc := objBindMethod(this, "internal_property", param_source)
      return boundFunc
    }
  }
  static internal_property(param_property, param_itaree) {
    if (isObject(param_property)) {
      for key, value in param_property {
        if ((Type(temp := param_property) == "Array" ? temp.Length : temp.Count) == 1) {
          return param_itaree[value]
        } else if (param_itaree.Has(value)) {
          rvalue := this.internal_property(this.tail(param_property), param_itaree[value])
        }
      }
      return rvalue
    }
    return param_itaree[param_property]
  }
  static propertyOf(param_object) {
    if (!isObject(param_object)) {
      this._internal_ThrowException()
    }
    boundFunc := objBindMethod(this, "internal_propertyOf", param_object)
    return boundFunc
  }
  static internal_propertyOf(param_object, param_path) {
    return this.property(param_path).call(param_object)
  }
  static range(param_start := 0, param_end := 0, param_step := 1) {
    if (!this.isNumber(param_start) || !this.isNumber(param_end) || !this.isNumber(param_step)) {
      this._internal_ThrowException()
    }
    l_array := []
    if (param_start < 0 && param_end == 0 && param_step == 1) {
      param_step := -1
    }
    if (param_start == 0 && param_end == 0) {
      return l_array
    }
    if (param_end == 0) {
      param_end := param_start
      param_start := 0
    }
    l_currentStep := param_start
    if (param_end > param_start) {
      l_negativeFlag := true
    }
    if (param_step == 0) {
      zeroStepFlag := true
    }
    if (zeroStepFlag == true) {
      loop param_end - 1 {
        l_array.push(l_currentStep)
        l_currentStep += param_step
      }
    } else {
      while (l_currentStep != param_end) {
        l_array.push(l_currentStep)
        l_currentStep += param_step
      }
    }
    return l_array
  }
  static stubArray() {
    return []
  }
  static stubFalse() {
    return false
  }
  static stubObject() {
    return Map()
  }
  static stubString() {
    return ""
  }
  static stubTrue() {
    return true
  }
  static times(param_n, param_iteratee := "__identity") {
    if (!this.isNumber(param_n)) {
      this._internal_ThrowException()
    }
    if (this.startsWith(param_iteratee.name, this.__Class ".")) {
      guarded := this.includes(this._guardedMethods, strSplit(param_iteratee.name, ".").2)
      param_iteratee := param_iteratee.bind(this)
    }
    shorthand := this._internal_detectShorthand(param_iteratee)
    if (shorthand) {
      param_iteratee := this._internal_createShorthandfn(param_iteratee)
    }
    l_array := []
    loop param_n {
      l_array.push(param_iteratee.call(A_Index))
    }
    return l_array
  }
  static toPath(param_value) {
    if (!isObject(param_value)) {
      return this.compact(this.split(param_value, this._pathRegex))
    }
    return param_value
  }
  static uniqueId(param_prefix := "") {
    this._uniqueId++
    return param_prefix this._uniqueId
  }
  static first(param_array) {
    return this.take(param_array)[1]
  }
  static each(param_collection, param_iteratee := "__identity") {
    if (!isObject(param_collection)) {
      this._internal_ThrowException()
    }
    shorthand := this._internal_detectShorthand(param_iteratee, param_collection)
    if (shorthand != false) {
      param_iteratee := this._internal_createShorthandfn(param_iteratee, param_collection)
    }
    param_collection := this.cloneDeep(param_collection)
    for key, value in param_collection {
      if (this.isFunction(param_iteratee)) {
        vIteratee := param_iteratee.call(value, key, param_collection)
      }
      if (vIteratee == false) {
        return param_collection
      }
    }
    return param_collection
  }
  static eachRight(param_collection, param_iteratee := "__identity") {
    if (!isObject(param_collection)) {
      this._internal_ThrowException()
    }
    shorthand := this._internal_detectShorthand(param_iteratee, param_collection)
    if (shorthand != false) {
      param_iteratee := this._internal_createShorthandfn(param_iteratee, param_collection)
    }
    collectionClone := this.reverse(this.cloneDeep(param_collection))
    for key, value in collectionClone {
      if (this.isFunction(param_iteratee)) {
        vIteratee := param_iteratee.call(value, key, collectionClone)
      }
      if (vIteratee == false) {
        return collectionClone
      }
    }
    return param_collection
  }
  static entries(param_object) {
    if (!isObject(param_object)) {
      this._internal_ThrowException()
    }
    l_array := []
    for key, value in param_object {
      l_array.push([key, value])
    }
    return l_array
  }
}
