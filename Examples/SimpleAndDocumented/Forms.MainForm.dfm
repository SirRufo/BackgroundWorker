object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'MainForm'
  ClientHeight = 200
  ClientWidth = 296
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object WorkerWorkProgressInfoLabel: TLabel
    AlignWithMargins = True
    Left = 3
    Top = 92
    Width = 290
    Height = 13
    Align = alTop
    ExplicitWidth = 3
  end
  object WorkerWorkProgressBar: TProgressBar
    AlignWithMargins = True
    Left = 3
    Top = 111
    Width = 290
    Height = 17
    Align = alTop
    TabOrder = 3
    ExplicitLeft = -2
    ExplicitTop = 131
  end
  object Button1: TButton
    AlignWithMargins = True
    Left = 3
    Top = 30
    Width = 290
    Height = 25
    Action = WorkerRunWorkerAsyncAction
    Align = alTop
    TabOrder = 1
    ExplicitLeft = -2
    ExplicitTop = 41
  end
  object Button2: TButton
    AlignWithMargins = True
    Left = 3
    Top = 61
    Width = 290
    Height = 25
    Action = WorkerCancelAsyncAction
    Align = alTop
    TabOrder = 2
    ExplicitLeft = -2
    ExplicitTop = 49
  end
  object WorkerRunArgumentComboBox: TComboBox
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 290
    Height = 21
    Align = alTop
    TabOrder = 0
    ExplicitLeft = 72
    ExplicitWidth = 145
  end
  object ActionList1: TActionList
    Left = 80
    Top = 144
    object WorkerCancelAsyncAction: TAction
      Caption = 'WorkerCancelAsyncAction'
      OnExecute = WorkerCancelAsyncActionExecute
      OnUpdate = WorkerCancelAsyncActionUpdate
    end
    object WorkerRunWorkerAsyncAction: TAction
      Caption = 'WorkerRunWorkerAsyncAction'
      OnExecute = WorkerRunWorkerAsyncActionExecute
      OnUpdate = WorkerRunWorkerAsyncActionUpdate
    end
  end
end
