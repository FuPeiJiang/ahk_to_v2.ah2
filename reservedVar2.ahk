class wow {
    gello() {

    }
    hello() {

    }
     SetDataOffsets(In := 1256, Out := 1320) {
          local pData := this.MIB_IF_ROW2.Ptr
          NumPut("Ptr", pData + In, pData + 1352), NumPut("Ptr", pData + Out, pData + 1360)
    }
}
