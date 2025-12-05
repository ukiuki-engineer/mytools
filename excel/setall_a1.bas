' 
' すべてのシートでアクティブセルをA1にして、最初のシートのA1をアクティブにする
' 
Attribute VB_Name = "SetAllA1"
Sub SetAllA1()
  Dim ws As Worksheet
  
  ' すべてのシートでアクティブセルをA1にして、スクロールをリセット
  For Each ws In ActiveWorkbook.Sheets
    ws.Activate
    ws.Cells(1, 1).Select
    ActiveWindow.ScrollColumn = 1
    ActiveWindow.ScrollRow = 1
  Next ws
  
  ' 最初のシートのA1をアクティブに
  Sheets(1).Activate
  Sheets(1).Cells(1, 1).Select
  ActiveWindow.ScrollColumn = 1
  ActiveWindow.ScrollRow = 1
End Sub

