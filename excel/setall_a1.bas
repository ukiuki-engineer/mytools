Attribute VB_Name = "SetAllA1"
Sub SetAllA1()
  Dim ws As Worksheet
  
  ' すべてのシートでアクティブセルをA1に設定
  For Each ws In ActiveWorkbook.Sheets
      ws.Activate
      ws.Cells(1, 1).Select
  Next ws
  
  ' 最初のシートを選択し、A1をアクティブにする
  Sheets(1).Activate
  Sheets(1).Cells(1, 1).Select
End Sub

