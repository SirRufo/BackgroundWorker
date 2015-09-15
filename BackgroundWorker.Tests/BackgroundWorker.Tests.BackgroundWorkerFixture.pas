unit BackgroundWorker.Tests.BackgroundWorkerFixture;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  BackgroundWorker;

type

  [ TestFixture ]
  TBackgroundWorkerFixture = class( TObject )
  private
    FBackgroundWorker    : TBackgroundWorker;
    FOnDoWork            : TProc<TObject, TDoWorkEventArgs>;
    FOnProgressChanged   : TProc<TObject, TProgressChangedEventArgs>;
    FOnRunWorkerCompleted: TProc<TObject, TRunWorkerCompletedEventArgs>;
    procedure BackgroundWorkerDoWork( Sender: TObject; e: TDoWorkEventArgs );
    procedure BackgroundWorkerProgressChanged( Sender: TObject; e: TProgressChangedEventArgs );
    procedure BackgroundWorkerRunWorkerCompleted( Sender: TObject; e: TRunWorkerCompletedEventArgs );
  public
    [ Setup ]
    procedure Setup;
    [ TearDown ]
    procedure TearDown;

    [ Test ]
    procedure GivenWorkerSupportsCancellation_WhenCallingCancelAsync_ThenCancellationPendingIsTrue( );
    [ Test ]
    procedure GivenWorkerNotSupportsCancellation_WhenCallingCancelAsync_ThenEInvalidOpExceptionIsRaised( );
    [ Test ]
    procedure GivenWorkerReportsProgress_WhenCallingReportProgress_ThenOnProgressChangedIsCalled( );
    [ Test ]
    [ TestCase( '  0%', '000' ) ]
    [ TestCase( ' 10%', '010' ) ]
    [ TestCase( ' 20%', '020' ) ]
    [ TestCase( ' 30%', '030' ) ]
    [ TestCase( ' 40%', '040' ) ]
    [ TestCase( ' 50%', '050' ) ]
    [ TestCase( ' 60%', '060' ) ]
    [ TestCase( ' 70%', '070' ) ]
    [ TestCase( ' 80%', '080' ) ]
    [ TestCase( ' 90%', '090' ) ]
    [ TestCase( '100%', '100' ) ]
    procedure GivenWorkerReportsProgress_WhenCallingReportProgressWithPercentageProgress_ThenProgressChangedEventArgsPercentProgressIsEqual
      ( const GivenPercentProgress: Integer );
    [ Test ]
    procedure GivenWorkerNotReportsProgress_WhenCallingReportProgress_ThenEInvalidOpExceptionIsRaised( );
    [ Test ]
    procedure GivenIsNotBusy_WhenCallingRunWorkerAsync_ThenIsBusyIsTrue( );
    [ Test ]
    procedure GivenIsBusy_WhenCallingRunWorkerAsync_ThenEInvalidOpExceptionIsRaised( );
  end;

implementation

procedure TBackgroundWorkerFixture.BackgroundWorkerDoWork(
  Sender: TObject;
  e     : TDoWorkEventArgs );
begin
  if Assigned( FOnDoWork )
  then
    FOnDoWork( Sender, e );
end;

procedure TBackgroundWorkerFixture.BackgroundWorkerProgressChanged(
  Sender: TObject;
  e     : TProgressChangedEventArgs );
begin
  if Assigned( FOnProgressChanged )
  then
    FOnProgressChanged( Sender, e );
end;

procedure TBackgroundWorkerFixture.BackgroundWorkerRunWorkerCompleted(
  Sender: TObject;
  e     : TRunWorkerCompletedEventArgs );
begin
  if Assigned( FOnRunWorkerCompleted )
  then
    FOnRunWorkerCompleted( Sender, e );
end;

procedure TBackgroundWorkerFixture.Setup;
begin
  FBackgroundWorker                      := TBackgroundWorker.Create( nil );
  FBackgroundWorker.OnDoWork             := BackgroundWorkerDoWork;
  FBackgroundWorker.OnProgressChanged    := BackgroundWorkerProgressChanged;
  FBackgroundWorker.OnRunWorkerCompleted := BackgroundWorkerRunWorkerCompleted;
end;

procedure TBackgroundWorkerFixture.TearDown;
begin
  FreeAndNil( FBackgroundWorker );
  FOnDoWork             := nil;
  FOnProgressChanged    := nil;
  FOnRunWorkerCompleted := nil;
end;

procedure TBackgroundWorkerFixture.GivenIsBusy_WhenCallingRunWorkerAsync_ThenEInvalidOpExceptionIsRaised;
var
  DoWait: Boolean;
begin
  FOnDoWork :=
    procedure( s: TObject; e: TDoWorkEventArgs )
    begin
      while DoWait do;
    end;
  DoWait := True;
  try
    FBackgroundWorker.RunWorkerAsync;
    Assert.IsTrue( FBackgroundWorker.IsBusy );

    Assert.WillRaise(
      procedure
      begin
        FBackgroundWorker.RunWorkerAsync;
      end, EInvalidOpException );

  finally
    DoWait := False;
  end;
end;

procedure TBackgroundWorkerFixture.GivenIsNotBusy_WhenCallingRunWorkerAsync_ThenIsBusyIsTrue;
var
  DoWait: Boolean;
begin
  FOnDoWork :=
    procedure( s: TObject; e: TDoWorkEventArgs )
    begin
      while DoWait do;
    end;
  DoWait := True;
  try
    Assert.IsFalse( FBackgroundWorker.IsBusy );
    FBackgroundWorker.RunWorkerAsync;
    Assert.IsTrue( FBackgroundWorker.IsBusy );
  finally
    DoWait := False;
  end;
end;

procedure TBackgroundWorkerFixture.GivenWorkerNotReportsProgress_WhenCallingReportProgress_ThenEInvalidOpExceptionIsRaised;
begin
  FBackgroundWorker.WorkerReportsProgress := False;
  Assert.WillRaise(
    procedure
    begin
      FBackgroundWorker.ReportProgress( 0 );
    end, EInvalidOpException );
end;

procedure TBackgroundWorkerFixture.GivenWorkerNotSupportsCancellation_WhenCallingCancelAsync_ThenEInvalidOpExceptionIsRaised;
begin
  FBackgroundWorker.WorkerSupportsCancellation := False;
  Assert.WillRaise(
    procedure
    begin
      FBackgroundWorker.CancelAsync( );
    end, EInvalidOpException );
end;

procedure TBackgroundWorkerFixture.GivenWorkerReportsProgress_WhenCallingReportProgress_ThenOnProgressChangedIsCalled;
var
  executed: Boolean;
begin
  FBackgroundWorker.WorkerReportsProgress := True;
  executed                                := False;
  FOnProgressChanged                      :=
    procedure( s: TObject; e: TProgressChangedEventArgs )
    begin
      executed := True;
    end;
  FBackgroundWorker.ReportProgress( 1 );
  Assert.IsTrue( executed );
end;

procedure TBackgroundWorkerFixture.GivenWorkerReportsProgress_WhenCallingReportProgressWithPercentageProgress_ThenProgressChangedEventArgsPercentProgressIsEqual
  ( const GivenPercentProgress: Integer );
var
  actual: Integer;
begin
  FBackgroundWorker.WorkerReportsProgress := True;
  actual                                  := -1;
  FOnProgressChanged                      :=
    procedure( s: TObject; e: TProgressChangedEventArgs )
    begin
      actual := e.PercentProgress;
    end;
  FBackgroundWorker.ReportProgress( GivenPercentProgress );
  Assert.AreEqual( GivenPercentProgress, actual );
end;

procedure TBackgroundWorkerFixture.GivenWorkerSupportsCancellation_WhenCallingCancelAsync_ThenCancellationPendingIsTrue;
begin
  FBackgroundWorker.WorkerSupportsCancellation := True;
  FBackgroundWorker.CancelAsync( );
  Assert.IsTrue( FBackgroundWorker.CancellationPending );
end;

initialization

TDUnitX.RegisterTestFixture( TBackgroundWorkerFixture );

end.
