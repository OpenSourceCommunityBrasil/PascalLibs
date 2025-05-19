unit Log.TextFile;

interface

uses
  System.SysUtils, System.SyncObjs;

type
  TLogLevel = (llCritical, llDebug, llError, llInfo, llWarning);

  TLog = class
  private
    FFileName: string;
    FCriticalSession: TCriticalSection;
    procedure SetFileName(const Value: string);
    function LevelFromIdentifier(AIdentifier: TLogLevel): string;
  public
    constructor Create(AFileName: string = 'log.txt');
    destructor Destroy; override;
    procedure Log(ALevel: TLogLevel; AMessage: string);

    property FileName: string read FFileName write SetFileName;
  end;

implementation

{ TLog }

constructor TLog.Create(AFileName: string);
begin
  SetFileName(AFileName);
  FCriticalSession := TCriticalSection.Create;
end;

destructor TLog.Destroy;
begin
  FreeAndNil(FCriticalSession);
  inherited;
end;

function TLog.LevelFromIdentifier(AIdentifier: TLogLevel): string;
begin
  case AIdentifier of
    llCritical: Result := '[CRITICAL]';
    llDebug: Result := '[DEBUG]';
    llError: Result := '[ERROR]';
    llInfo: Result := '[INFO]';
    llWarning: Result := '[WARNING]';
  end;
end;

procedure TLog.Log(ALevel: TLogLevel; AMessage: string);
var
  LogFile: Text;
begin
  FCriticalSession.Enter;
  try
    AssignFile(LogFile, FFileName);
    try
      if FileExists(FFileName) then
        Append(LogFile)
      else
        Rewrite(LogFile);

      Writeln(LogFile, Format('%s %s %s', [FormatDateTime('dd/mm/yyyy hh:nn:ss', Now), LevelFromIdentifier(ALevel), AMessage]));
    finally
      CloseFile(LogFile);
    end;
  except
  end;
  FCriticalSession.Leave;
end;

procedure TLog.SetFileName(const Value: string);
begin
  FFileName := Value;
end;

end.
