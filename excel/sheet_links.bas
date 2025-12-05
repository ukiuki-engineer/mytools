' 
' 新しいシートを追加して、シート一覧を作成する
' 
Attribute VB_Name = "MakeLinkSheet"
Sub MakeLinkSheet()
  Const SHEET_NAME As String = "シート一覧_tmp"
  Dim ws As Worksheet
  Dim i As Integer
  i = 1

  ' シート追加
  Sheets.Add
  ActiveSheet.Name = SHEET_NAME
  ' シート一覧を出力
  For Each ws In ActiveWorkbook.Sheets
    If ws.Name <> SHEET_NAME Then
      ActiveSheet.Cells(i, 1).Value = ws.Name
      ActiveSheet.Hyperlinks.Add Anchor:=ActiveSheet.Cells(i, 1), _
      Address:="", SubAddress:="'" & ws.Name & "'!A1", _
      TextToDisplay:=ws.Name
      i = i + 1
    End If
  Next ws
End Sub

