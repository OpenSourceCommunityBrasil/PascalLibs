// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.0 (adaptada para Singleton)
unit Log.TextFile.Singleton;

{$DEFINE IOUtils}

interface

uses
  SysUtils, SyncObjs, DateUtils;

type
  TLogLevel = (llCritical, llError, llWarning, llInfo, llVerbose, llDebug);

  TLog = class
  private
    FInternalDate: TDateTime;
    FFileName: string;
    FDefaultFileName: string;
    FCriticalSession: TCriticalSection;
    FDefaultLogLevel: TLogLevel;

    class var FInstance: TLog;  // Instância única do Singleton

    constructor Create(AFileName: string);
    procedure SetFileName(const Value: string);
    function LevelFromIdentifier(AIdentifier: TLogLevel): string;
  public
    class function GetInstance(const AFileName: string = 'log.txt'): TLog;
    destructor Destroy; override;

    procedure Log(ALevel: TLogLevel; AMessage: string); overload;
    procedure Log(ALevel: TLogLevel; AMessageFmt: string; AArgs: array of const);
      overload;

    property FileName: string read FFileName write SetFileName;
    property DefaultLoggingLevel: TLogLevel read FDefaultLogLevel write FDefaultLogLevel;
  end;

implementation

{$IFDEF IOUtils}
uses
  System.IOUtils;
{$ENDIF}

{ TLog }

class function TLog.GetInstance(const AFileName: string): TLog;
begin
  if not Assigned(FInstance) then
    FInstance := TLog.Create(AFileName);

  Result := FInstance;
end;

constructor TLog.Create(AFileName: string);
begin
  FInternalDate := now;
  SetFileName(AFileName);
  FCriticalSession := TCriticalSection.Create;
  DefaultLoggingLevel := llInfo;
end;

destructor TLog.Destroy;
begin
  // Se for a instância do Singleton, limpa a referência
  if Self = FInstance then
    FInstance := nil;

  if Assigned(FCriticalSession) then
  begin
    FCriticalSession.Leave;  // Ensure we're not holding the lock
    FCriticalSession.Free;
    FCriticalSession := nil;
  end;
  inherited;
end;

function TLog.LevelFromIdentifier(AIdentifier: TLogLevel): string;
begin
  case AIdentifier of
    llCritical: Result := '[CRITICAL]';
    llDebug   : Result := '[   DEBUG]';
    llError   : Result := '[   ERROR]';
    llInfo    : Result := '[    INFO]';
    llVerbose : Result := '[ VERBOSE]';
    llWarning : Result := '[ WARNING]';
  end;
end;

procedure TLog.Log(ALevel: TLogLevel; AMessageFmt: string; AArgs: array of const);
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

        Writeln(LogFile, Format('%s %s %s',
          [FormatDateTime('dd/mm/yyyy hh:nn:ss', Now), LevelFromIdentifier(ALevel),
          AMessage]));
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
  {$IFDEF IOUtils}
  FFileName := Format('%s%s%s', [Copy(temp, 1, pos('.', temp) - 1),
    FormatDateTime('yyyymmdd', FInternalDate), ExtractFileExt(Value)]);
  FFileName := TPath.Combine(ExtractFileDir(Value), FFileName);
  {$ELSE}
  FFileName := ExtractFileDir(Value) + '\';
  FFileName := FFileName + Copy(temp, 1, pos('.', temp) - 1) +
    FormatDateTime('yyyymmdd', FInternalDate) + ExtractFileExt(Value);
  {$ENDIF}
end;

finalization
  // Limpeza automática do Singleton quando a unit for descarregada
  if Assigned(TLog.FInstance) then
    TLog.FInstance.Free;

end.
