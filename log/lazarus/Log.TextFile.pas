// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.0
unit Log.TextFile;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, syncobjs;

type

  { TInfoLog }

  TInfoLog = class
  private
    FFileName: string;
    FSection: string;
    FValue: string;
  public
    function WriteLog : boolean;
  published
    property FileName: string read FFileName write FFileName;
    property Section: string  read FSection write FSection;
    property Value: string  read FValue write FValue;
  end;

  { TLog }

  TLog = class(TThread)
  private
    FInfo : TList;
    FCritical : TCriticalSection;
    FEvent : TSimpleEvent;
  protected
    procedure Execute; override;
    procedure Clear;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Terminar;

    procedure AddLog(AInfo : TInfoLog);

    class procedure Log(ASection, AValue: string; AFileName: string = 'log.txt');
  end;

implementation

var
  vLogger : TLog;

{ TInfoLog }

function TInfoLog.WriteLog: boolean;
var
  vLogFile: Text;
  vLogData: String;
begin
  vLogData := FormatDateTime('dd/mm/yyyy hh:nn:ss', Now) + ' | ' +
              FSection + ' | ' + FValue;

  Result := False;
  try
    AssignFile(vLogFile, FFileName);
    try
      if FileExists(FFileName) then
        Append(vLogFile)
      else
        Rewrite(vLogFile);

      Writeln(vLogFile, vLogData);
      Result := True;
    finally
      CloseFile(vLogFile);
    end;
  except
    Result := False;
  end;
end;

{ TLog }

constructor TLog.Create;
begin
  FreeOnTerminate := True;
  FInfo := TList.Create;
  FCritical := TCriticalSection.Create;
  FEvent := TSimpleEvent.Create;

  inherited Create(False);
end;

destructor TLog.Destroy;
begin
  Clear;
  FreeAndNil(FInfo);
  FreeAndNil(FCritical);
  FreeAndNil(FEvent);
  inherited Destroy;
end;

procedure TLog.Terminar;
begin
  Terminate;
  FEvent.SetEvent;
end;

procedure TLog.AddLog(AInfo: TInfoLog);
begin
  FCritical.Enter;
  FInfo.Add(AInfo);
  FCritical.Leave;

  FEvent.SetEvent;
end;

procedure TLog.Execute;
var
  vInfo : TInfoLog;
begin
  while not Terminated do
  begin
    FEvent.WaitFor(INFINITE);

    if FInfo.Count > 0 then
    begin
      FCritical.Enter;
      vInfo := TInfoLog(FInfo.Items[0]);
      if vInfo.WriteLog then
      begin
        FreeAndNil(vInfo);
        FInfo.Delete(0);
      end;
      FCritical.Leave;
    end
    else
    begin
      FEvent.ResetEvent;
    end;
  end;
end;

procedure TLog.Clear;
var
  vInfo : TInfoLog;
begin
  while FInfo.Count > 0 do
  begin
    vInfo := TInfoLog(FInfo.Items[FInfo.Count - 1]);
    FreeAndNil(vInfo);
    FInfo.Delete(FInfo.Count - 1);
  end;
end;

class procedure TLog.Log(ASection, AValue: string; AFileName: string);
var
  vInfo : TInfoLog;
begin
  if vLogger = nil then
    vLogger := TLog.Create;

  vInfo := TInfoLog.Create;
  vInfo.Section := ASection;
  vInfo.Value := AValue;
  vInfo.FileName := AFileName;

  vLogger.AddLog(vInfo);
end;

initialization
  vLogger := nil;

finalization
  if vLogger <> nil then
    vLogger.Terminar;

end.
