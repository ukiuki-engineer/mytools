Attribute VB_Name = "SetAllA1"
Sub SetAllA1()
  Dim ws As Worksheet
  
  ' ���ׂẴV�[�g�ŃA�N�e�B�u�Z����A1�ɐݒ肵�A�X�N���[�������Z�b�g
  For Each ws In ActiveWorkbook.Sheets
    ws.Activate
    ws.Cells(1, 1).Select
    ActiveWindow.ScrollColumn = 1
    ActiveWindow.ScrollRow = 1
  Next ws
  
  ' �ŏ��̃V�[�g��I�����AA1���A�N�e�B�u�ɂ���
  Sheets(1).Activate
  Sheets(1).Cells(1, 1).Select
  ActiveWindow.ScrollColumn = 1
  ActiveWindow.ScrollRow = 1
End Sub

