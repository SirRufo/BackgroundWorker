{************************************************************************
 Copyright 2015 Oliver Münzberg (aka Sir Rufo)

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 ************************************************************************}
unit BackgroundWorker;

interface

uses
  System.Classes,
  System.Rtti,
  System.SysUtils;

{$REGION 'EventArgs'}

type
  TProgressChangedEventArgs = class
  private
    FPercentProgress: Integer;
    FUserState      : TValue;
  public
    constructor Create( APercentProgress: Integer; AUserState: TValue );
    property PercentProgress: Integer read FPercentProgress;
    property UserState: TValue read FUserState;
  end;

  TDoWorkEventArgs = class
  private
    FArgument: TValue;
    FCancel  : Boolean;
    FResult  : TValue;
  public
    constructor Create( AArgument: TValue );
    property Argument: TValue read FArgument;
    property Cancel: Boolean read FCancel write FCancel;
    property Result: TValue read FResult write FResult;
  end;

  TRunWorkerCompletedEventArgs = class
  private
    FCancelled: Boolean;
    FError    : Exception;
    FResult   : TValue;
  public
    constructor Create( AResult: TValue; AError: Exception; ACancelled: Boolean );
    property Cancelled: Boolean read FCancelled;
    property Error: Exception read FError;
    property Result: TValue read FResult;
  end;

{$ENDREGION}
{$REGION 'Events'}

type
  TBackgroundWorkerProgressChangedEvent    = procedure( Sender: TObject; e: TProgressChangedEventArgs ) of object;
  TBackgroundWorkerDoWorkEvent             = procedure( Sender: TObject; e: TDoWorkEventArgs ) of object;
  TBackgroundWorkerRunWorkerCompletedEvent = procedure( Sender: TObject; e: TRunWorkerCompletedEventArgs ) of object;
{$ENDREGION}
{$REGION 'CustomBackgroundWorker'}

type
  TCustomBackgroundWorker = class( TComponent )
  private
    FThread                    : TThread;
    FDoWorkEventArg            : TDoWorkEventArgs;
    FCancellationPending       : Boolean;
    FWorkerReportsProgress     : Boolean;
    FWorkerSupportsCancellation: Boolean;
    FOnDoWork                  : TBackgroundWorkerDoWorkEvent;
    FOnProgressChanged         : TBackgroundWorkerProgressChangedEvent;
    FOnRunWorkerCompleted      : TBackgroundWorkerRunWorkerCompletedEvent;
    function GetCancellationPending: Boolean;
    procedure WorkerThreadTerminate( Sender: TObject );
    function GetIsBusy: Boolean;
  protected
    procedure NotifyDoWork( e: TDoWorkEventArgs ); virtual;
    procedure NotifyProgressChanged( e: TProgressChangedEventArgs; ADispose: Boolean = True ); virtual;
    procedure NotifyRunCompleted( e: TRunWorkerCompletedEventArgs; ADispose: Boolean = True ); virtual;
  public
    procedure CancelAsync;

    procedure ReportProgress( PercentProgress: Integer ); overload;
    procedure ReportProgress( PercentProgress: Integer; UserState: TValue ); overload;

    procedure RunWorkerAsync; overload;
    procedure RunWorkerAsync<T>( Argument: T ); overload;
    procedure RunWorkerAsync( Argument: TValue ); overload;

    property CancellationPending: Boolean read GetCancellationPending;
    property IsBusy: Boolean read GetIsBusy;
  protected
    property OnDoWork            : TBackgroundWorkerDoWorkEvent read FOnDoWork write FOnDoWork;
    property OnProgressChanged   : TBackgroundWorkerProgressChangedEvent read FOnProgressChanged write FOnProgressChanged;
    property OnRunWorkerCompleted: TBackgroundWorkerRunWorkerCompletedEvent read FOnRunWorkerCompleted write FOnRunWorkerCompleted;
  public
    property WorkerReportsProgress     : Boolean read FWorkerReportsProgress write FWorkerReportsProgress;
    property WorkerSupportsCancellation: Boolean read FWorkerSupportsCancellation write FWorkerSupportsCancellation;
  end;
{$ENDREGION}
{$REGION 'TBackgroundWorker'}

type
  TBackgroundWorker = class( TCustomBackgroundWorker )
  published
    property OnDoWork;
    property OnProgressChanged;
    property OnRunWorkerCompleted;
    property WorkerReportsProgress;
    property WorkerSupportsCancellation;
  end;
{$ENDREGION}

implementation

{$REGION 'Ressourcestrings'}

resourcestring
  SIntegerArgumentOutOfRange = '%s: value %d is out of range [%d..%d]';
  SWorkerDoesNotSupportsCancellation = 'Worker does not supports cancellation';
  SWorkerDoesNotReportsProgress = 'Worker does not reports progress';
  SWorkerIsBusy = 'Worker is busy';
{$ENDREGION}
{$REGION 'EventArgs'}
  { TProgressChangedEventArgs }

constructor TProgressChangedEventArgs.Create( APercentProgress: Integer; AUserState: TValue );
begin
  inherited Create;
  if ( APercentProgress < 0 ) or ( APercentProgress > 100 )
  then
    raise EArgumentOutOfRangeException.CreateFmt( SIntegerArgumentOutOfRange, [ 'APercentProgress', APercentProgress, 0, 100 ] );
  FPercentProgress := APercentProgress;
  FUserState       := AUserState;
end;

{ TDoWorkEventArgs }

constructor TDoWorkEventArgs.Create( AArgument: TValue );
begin
  inherited Create;
  FArgument := AArgument;
end;

{ TRunWorkerCompletedEventArgs }

constructor TRunWorkerCompletedEventArgs.Create( AResult: TValue; AError: Exception; ACancelled: Boolean );
begin
  inherited Create;
  FCancelled := ACancelled;
  FError     := AError;
  FResult    := AResult;
end;

{$ENDREGION}
{$REGION 'TCustomBackgroundWorker'}
{ TCustomBackgroundWorker }

procedure TCustomBackgroundWorker.CancelAsync;
begin
  if not WorkerSupportsCancellation
  then
    raise EInvalidOpException.Create( SWorkerDoesNotSupportsCancellation );

  FCancellationPending := True;
end;

procedure TCustomBackgroundWorker.ReportProgress( PercentProgress: Integer );
begin
  ReportProgress( PercentProgress, TValue.Empty );
end;

function TCustomBackgroundWorker.GetCancellationPending: Boolean;
begin
  Result := ( csDestroying in ComponentState ) or FCancellationPending;
end;

function TCustomBackgroundWorker.GetIsBusy: Boolean;
begin
  Result := Assigned( FThread );
end;

procedure TCustomBackgroundWorker.NotifyDoWork( e: TDoWorkEventArgs );
begin
  if Assigned( FOnDoWork )
  then
    FOnDoWork( Self, e );
end;

procedure TCustomBackgroundWorker.NotifyProgressChanged( e: TProgressChangedEventArgs; ADispose: Boolean );
begin
  if not( csDestroying in ComponentState )
  then
    TThread.Queue( nil,
      procedure
      begin
        try
          if Assigned( FOnProgressChanged )
          then
            FOnProgressChanged( Self, e );
        finally
          if ADispose
          then
            e.Free;
        end;
      end )
  else
    begin
      if ADispose
      then
        e.Free;
    end;
end;

procedure TCustomBackgroundWorker.NotifyRunCompleted( e: TRunWorkerCompletedEventArgs; ADispose: Boolean );
begin
  try
    if not( csDestroying in ComponentState )
    then
      if Assigned( FOnRunWorkerCompleted )
      then
        FOnRunWorkerCompleted( Self, e );
  finally
    if ADispose
    then
      e.Free;
  end;
end;

procedure TCustomBackgroundWorker.ReportProgress( PercentProgress: Integer; UserState: TValue );
begin
  if not WorkerReportsProgress
  then
    raise EInvalidOpException.Create( SWorkerDoesNotReportsProgress );

  NotifyProgressChanged( TProgressChangedEventArgs.Create( PercentProgress, UserState ) );
end;

procedure TCustomBackgroundWorker.RunWorkerAsync;
begin
  RunWorkerAsync( TValue.Empty );
end;

procedure TCustomBackgroundWorker.RunWorkerAsync( Argument: TValue );
begin
  if IsBusy
  then
    raise EInvalidOpException.Create( SWorkerIsBusy );

  FCancellationPending := False;
  FDoWorkEventArg      := TDoWorkEventArgs.Create( Argument );

  FThread := TThread.CreateAnonymousThread(
    procedure
    begin
      NotifyDoWork( FDoWorkEventArg );
    end );
  FThread.OnTerminate := WorkerThreadTerminate;
  FThread.Start;
end;

procedure TCustomBackgroundWorker.RunWorkerAsync<T>( Argument: T );
begin
  RunWorkerAsync( TValue.From<T>( Argument ) );
end;

procedure TCustomBackgroundWorker.WorkerThreadTerminate( Sender: TObject );
var
  LThread        : TThread;
  LDoWorkEventArg: TDoWorkEventArgs;
begin
  LThread         := FThread;
  LDoWorkEventArg := FDoWorkEventArg;
  FThread         := nil;
  FDoWorkEventArg := nil;
  try
    if Assigned( LThread.FatalException )
    then
      NotifyRunCompleted( TRunWorkerCompletedEventArgs.Create( TValue.Empty, LThread.FatalException as Exception, False ) )
    else
      NotifyRunCompleted( TRunWorkerCompletedEventArgs.Create( LDoWorkEventArg.Result, nil, LDoWorkEventArg.Cancel ) );
  finally
    FreeAndNil( LDoWorkEventArg );
  end;
end;

{$ENDREGION}

end.
