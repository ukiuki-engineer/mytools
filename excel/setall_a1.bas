Attribute VB_Name = "SetAllA1"
Sub SetAllA1()
  Dim ws As Worksheet
  
  ' ���ׂẴV�[�g�ŃA�N�e�B�u�Z����A1�ɐݒ�
  For Each ws In ActiveWorkbook.Sheets
      ws.Activate
      ws.Cells(1, 1).Select
  Next ws
  
  ' �ŏ��̃V�[�g��I�����AA1���A�N�e�B�u�ɂ���
  Sheets(1).Activate
  Sheets(1).Cells(1, 1).Select
End Sub

