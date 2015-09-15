unit BackgroundWorker.Tests.ProgressEventArgsFixture;

interface

uses
  DUnitX.TestFramework,
  System.Rtti,
  System.SysUtils,
  BackgroundWorker;

type

  [ TestFixture ]
  TProgressEventArgsFixture = class( TObject )
  public
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
    procedure WhenCreating_ThenPercentProgressPropertyContainsTheValueFromConstructor( const PercentProgress: Integer );
    [ Test ]
    [ TestCase( 'Below Zero', '-1' ) ]
    [ TestCase( 'Above 100', '101' ) ]
    procedure WhenCreatingWithInvalidPercentProgressValue_ThenEArgumentOutOfRangeExceptionIsRaised( const PercentProgress: Integer );
  end;

implementation

{ TProgressEventArgsFixture }

procedure TProgressEventArgsFixture.WhenCreatingWithInvalidPercentProgressValue_ThenEArgumentOutOfRangeExceptionIsRaised( const PercentProgress: Integer );
begin
  Assert.WillRaise(
    procedure
    var
      LArgs: TProgressChangedEventArgs;
    begin
      LArgs := TProgressChangedEventArgs.Create(
        PercentProgress,
        TValue.Empty );
      try

      finally
        LArgs.Free;
      end;
    end, EArgumentOutOfRangeException );
end;

procedure TProgressEventArgsFixture.WhenCreating_ThenPercentProgressPropertyContainsTheValueFromConstructor( const PercentProgress: Integer );
var
  LArgs: TProgressChangedEventArgs;
begin
  LArgs := TProgressChangedEventArgs.Create( PercentProgress, TValue.Empty );
  try
    Assert.AreEqual( PercentProgress, LArgs.PercentProgress );
  finally
    LArgs.Free;
  end;
end;

initialization

TDUnitX.RegisterTestFixture( TProgressEventArgsFixture );

end.
