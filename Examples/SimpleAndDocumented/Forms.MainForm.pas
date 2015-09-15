unit Forms.MainForm;

interface

uses
  BackgroundWorker,

  Winapi.Messages,
  Winapi.Windows,

  System.Actions,
  System.Classes,
  System.SysUtils,
  System.Variants,

  Vcl.ActnList,
  Vcl.ComCtrls,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.StdCtrls;

type
  TMainForm = class( TForm )
    WorkerWorkProgressBar: TProgressBar;
    WorkerWorkProgressInfoLabel: TLabel;
    ActionList1: TActionList;
    WorkerCancelAsyncAction: TAction;
    WorkerRunWorkerAsyncAction: TAction;
    Button1: TButton;
    Button2: TButton;
    WorkerRunArgumentComboBox: TComboBox;
    procedure WorkerCancelAsyncActionExecute( Sender: TObject );
    procedure WorkerCancelAsyncActionUpdate( Sender: TObject );
    procedure WorkerRunWorkerAsyncActionExecute( Sender: TObject );
    procedure WorkerRunWorkerAsyncActionUpdate( Sender: TObject );
  private
    FWorker: TBackgroundWorker;
    procedure WorkerDoWork( Sender: TObject; e: TDoWorkEventArgs );
    procedure WorkerProgressChanged( Sender: TObject; e: TProgressChangedEventArgs );
    procedure WorkerRunWorkerCompleted( Sender: TObject; e: TRunWorkerCompletedEventArgs );
  public
    procedure AfterConstruction; override;

  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}
{ TMainForm }

procedure TMainForm.AfterConstruction;
begin
  inherited;
  // create instance
  FWorker := TBackgroundWorker.Create( Self );
  // wireup events
  FWorker.OnDoWork             := WorkerDoWork;
  FWorker.OnProgressChanged    := WorkerProgressChanged;
  FWorker.OnRunWorkerCompleted := WorkerRunWorkerCompleted;
  // set properties
  FWorker.WorkerReportsProgress := True;
  // run arguments
  WorkerRunArgumentComboBox.Items.Add( 'pass' );
  WorkerRunArgumentComboBox.Items.Add( 'fail-pre' );
  WorkerRunArgumentComboBox.Items.Add( 'fail-50' );
  WorkerRunArgumentComboBox.Items.Add( 'fail-post' );
end;

procedure TMainForm.WorkerCancelAsyncActionExecute( Sender: TObject );
begin
  FWorker.CancelAsync( );
end;

procedure TMainForm.WorkerCancelAsyncActionUpdate( Sender: TObject );
begin
  TAction( Sender ).Enabled := FWorker.IsBusy
  {} and FWorker.WorkerSupportsCancellation
  {} and not FWorker.CancellationPending;
end;

procedure TMainForm.WorkerDoWork(
  Sender: TObject;
  e     : TDoWorkEventArgs );
var
  LWorker  : TBackgroundWorker absolute Sender;
  LArgument: string;
  LIdx     : Integer;
begin
  // we can cancel this work
  LWorker.WorkerSupportsCancellation := True;
  // reading the argument
  LArgument := e.Argument.AsString;
  // just take a nap
  Sleep( 500 );

  // simulate exception
  if LArgument = 'fail-pre'
  then
    raise Exception.Create( 'failed in pre processing' );

  // lets do some work
  for LIdx := 1 to 100 do
    begin
      // check for pending cancellation
      if LWorker.CancellationPending
      then
        begin
          // flag that we really have cancelled the work
          e.Cancel := True;
          // get out of here
          Exit;
        end;

      // simulate exception
      if LArgument = Format( 'fail-%d', [ LIdx ] )
      then
        raise Exception.Create( 'failed in processing' );

      Sleep( 10 );

      // report progress
      LWorker.ReportProgress(
        LIdx,
        Format( 'Processed: %d', [ LIdx ] ) );
    end;
  // now we do some post processing, that we can not cancel
  LWorker.WorkerSupportsCancellation := False;
  // well not very much work, just sleeping
  Sleep( 1000 );
  // simulate exception
  if LArgument = 'fail-post'
  then
    raise Exception.Create( 'failed in post processing' );
  // pass a result value
  e.Result := 'Result: ' + LArgument;
end;

procedure TMainForm.WorkerProgressChanged(
  Sender: TObject;
  e     : TProgressChangedEventArgs );
begin
  // present the PercentProgress value
  WorkerWorkProgressBar.Style    := TProgressBarStyle.pbstNormal;
  WorkerWorkProgressBar.Position := e.PercentProgress;
  // present the UserState value
  WorkerWorkProgressInfoLabel.Caption := e.UserState.ToString;
end;

procedure TMainForm.WorkerRunWorkerAsyncActionExecute( Sender: TObject );
begin
  // start the worker
  FWorker.RunWorkerAsync( WorkerRunArgumentComboBox.Text );
  // prepare progressbar
  WorkerWorkProgressBar.Position := 0;
  WorkerWorkProgressBar.Style    := TProgressBarStyle.pbstMarquee;
  // prepare progressinfo
  WorkerWorkProgressInfoLabel.Font.Color := clBlack;
  WorkerWorkProgressInfoLabel.Caption    := 'running';
end;

procedure TMainForm.WorkerRunWorkerAsyncActionUpdate( Sender: TObject );
begin
  // we can run the worker if it is not busy
  TAction( Sender ).Enabled := not FWorker.IsBusy
  // and we have an argument
  {} and ( WorkerRunArgumentComboBox.Text <> '' );
end;

procedure TMainForm.WorkerRunWorkerCompleted(
  Sender: TObject;
  e     : TRunWorkerCompletedEventArgs );
begin
  WorkerWorkProgressBar.Style := TProgressBarStyle.pbstNormal;
  if Assigned( e.Error ) // has the work raised an exception?
  then
    begin
      WorkerWorkProgressInfoLabel.Font.Color := clRed;
      WorkerWorkProgressInfoLabel.Caption    := e.Error.ToString;
    end
  else if e.Cancelled // was the work cancelled?
  then
    begin
      WorkerWorkProgressInfoLabel.Font.Color := clOlive;
      WorkerWorkProgressInfoLabel.Caption    := 'cancelled';
    end
  else // work has completed
    begin
      WorkerWorkProgressInfoLabel.Font.Color := clGreen;
      WorkerWorkProgressInfoLabel.Caption    := e.Result.ToString;
    end;
end;

end.
