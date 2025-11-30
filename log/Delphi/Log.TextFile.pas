// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.0
unit Log.TextFile;

interface

uses
  System.SysUtils, System.SyncObjs, System.DateUtils;

type
  TLogLevel = (llCritical, llError, llWarning, llInfo, llVerbose, llDebug);

  TLog = class
  private
    FInternalDate: TDateTime;
    FFileName: string;
    FDefaultFileName: string;
    FCriticalSession: TCriticalSection;
    FDefaultLogLevel: TLogLevel;
    procedure SetFileName(const Value: string);
    function LevelFromIdentifier(AIdentifier: TLogLevel): string;
  public
    constructor Create(AFileName: string = 'log.txt');
    destructor Destroy; override;
    procedure Log(ALevel: TLogLevel; AMessage: string); overload;
    procedure Log(ALevel: TLogLevel; AMessageFmt: string; AArgs: array of const); overload;

    property FileName: string read FFileName write SetFileName;
    property DefaultLoggingLevel: TLogLevel read FDefaultLogLevel write FDefaultLogLevel;
  end;

implementation

{ TLog }

constructor TLog.Create(AFileName: string);
begin
  FInternalDate := now;
  SetFileName(AFileName);
  FCriticalSession := TCriticalSection.Create;
  DefaultLoggingLevel := llInfo;
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
    llVerbose: Result := '[VERBOSE]';
  end;
end;

procedure TLog.Log(ALevel: TLogLevel; AMessageFmt: string;
  AArgs: array of const);
begin
  Log(ALevel, Format(AMessageFmt, AArgs));
end;

procedure TLog.Log(ALevel: TLogLevel; AMessage: string);
var
  LogFile: Text;
begin
  if ALevel <= FDefaultLogLevel then
  begin
    FCriticalSession.Enter;
    try
      if DaysBetween(now, FInternalDate) > 0 then
      begin
        FInternalDate := now;
        SetFileName(FDefaultFileName);
      end;

      AssignFile(LogFile, FFileName);
      try
        if FileExists(FFileName) then
          Append(LogFile)
        else
        begin
          ForceDirectories(ExtractFileDir(FFileName));
          Rewrite(LogFile);
        end;

        Writeln(LogFile, Format('%s %s %s', [FormatDateTime('dd/mm/yyyy hh:nn:ss', Now), LevelFromIdentifier(ALevel), AMessage]));
      finally
        CloseFile(LogFile);
      end;
    except
    end;
    FCriticalSession.Leave;
  end;
end;

procedure TLog.SetFileName(const Value: string);
var
  temp: string;
begin
  FDefaultFileName := Value;
  temp := ExtractFileName(Value);
  FFileName := ExtractFileDir(Value) + '\';
  FFileName := FFileName + Copy(temp, 1, pos('.', temp)-1)
    + FormatDateTime('yyyymmdd', FInternalDate) + ExtractFileExt(Value);
end;

end.
