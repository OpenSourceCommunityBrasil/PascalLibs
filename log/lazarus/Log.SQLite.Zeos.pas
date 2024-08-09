// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.0
unit Log.SQLite.Zeos;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpJSON, DB,
  ZConnection, ZDataSet, ZSqlProcessor;

type

  TLog = class;

  { TThreadedLog }

  TThreadedLog = class(TThread)
  private
    FFileName: string;
    FLogObject: TJSONObject;
    FLog: TLog;
    procedure SetFileName(AValue: string);
    procedure SetLogObject(AValue: TJSONObject);
  protected
    procedure Execute; override;
    property FileName: string read FFileName write SetFileName;
    property LogObject: TJSONObject read FLogObject write SetLogObject;
  public
    constructor Create(AFileName: string; ALogObject: TJSONObject = nil); overload;
    constructor Create(AFileName: string; ASection, AValue: string); overload;
    destructor Destroy; override;
  end;

  { TLog }

  TLog = class
  private
    FQuery: TZQuery;
    FConn: TZConnection;
    FThread: TThreadedLog;
    function ValidaBanco: boolean;
    function GetDefaultDir(aFileName: string): string;
  public
    constructor Create(aFileName: string = 'log.db');
    destructor Destroy; override;
    procedure Log(aJSON: TJSONObject); overload;
    procedure Log(aEvent, aValue: string); overload;
    function getLog: string;
  end;

  TDataSetJSONHelper = class helper for TDataSet
  public
    function ToJSON: string;
  end;

implementation

{ TThreadedLog }

procedure TThreadedLog.SetFileName(AValue: string);
begin
  if FFileName = AValue then Exit;
  FFileName := AValue;
end;

procedure TThreadedLog.SetLogObject(AValue: TJSONObject);
begin
  if FLogObject = AValue then Exit;
  FLogObject := AValue;
end;

constructor TThreadedLog.Create(AFileName: string; ALogObject: TJSONObject);
begin
  inherited Create(False);
  FreeOnTerminate := True;
  FileName := AFileName;
  if not Assigned(FLog) then
    FLog := TLog.Create(AFileName);

  if ALogObject <> nil then
    LogObject := ALogObject;
end;

constructor TThreadedLog.Create(AFileName: string; ASection, AValue: string);
begin
  inherited Create(False);
  FreeOnTerminate := True;
  FileName := AFileName;
  if not Assigned(FLog) then
    FLog := TLog.Create(AFileName);

  if not Assigned(LogObject) then
    LogObject := TJSONObject.Create;
  LogObject.Add('LOG_Data', DateTimeToStr(now));
  LogObject.Add('LOG_Evento', ASection);
  LogObject.Add('LOG_Conteudo', AValue);
end;

destructor TThreadedLog.Destroy;
begin
  if Assigned(FLog) then FLog.Free;
  inherited Destroy;
end;

procedure TThreadedLog.Execute;
begin
  FLog.Log(LogObject);
end;

{ TLog }

constructor TLog.Create(aFileName: string);
var
  zsqlproc: TZSQLProcessor;
begin
  FConn := TZConnection.Create(nil);
  FConn.Protocol := 'sqlite-3';
  FConn.Database := ExtractFilePath(ParamStr(0)) + aFileName;
  FConn.LibraryLocation := GetDefaultDir('sqlite3.dll');
  FConn.Connect;
  FConn.ExecuteDirect('PRAGMA locking_mode=NORMAL');
  FConn.ExecuteDirect('PRAGMA journal_mode=OFF');

  FQuery := TZQuery.Create(nil);
  FQuery.Connection := FConn;

  if not ValidaBanco then
    raise Exception.Create(
      'sqlite3.dll precisa estar na raiz do projeto ou na pasta /lib');
end;

destructor TLog.Destroy;
begin
  if Assigned(FQuery) then FQuery.Free;
  if Assigned(FConn) then FConn.Free;
  inherited;
end;

function TLog.GetDefaultDir(aFileName: string): string;
var
  DefaultDir, temp: string;
begin
  DefaultDir := ExtractFileDir(ParamStr(0));
  temp := DefaultDir + '\lib\' + aFileName;
  if FileExists(temp) then
    Result := DefaultDir + '\lib\' + aFileName
  else
    Result := DefaultDir + '\' + aFileName;
end;

procedure TLog.Log(aEvent, aValue: string);
var
  aJSON: TJSONObject;
begin
  aJSON := TJSONObject.Create;
  try
    aJSON.Add('LOG_Data', DateTimeToStr(now));
    aJSON.Add('LOG_Evento', aEvent);
    aJSON.Add('LOG_Conteudo', aValue);
    Log(aJSON);
  finally
    aJSON.Free;
  end;
end;

function TLog.getLog: string;
begin
  with FQuery do
  begin
    ReadOnly := True;
    Close;
    SQL.Clear;
    SQL.Add('SELECT ');
    SQL.Add('  LOG_ID ');
    SQL.Add(', CAST(LOG_Data AS VARCHAR) LOG_Data');
    SQL.Add(', LOG_Evento');
    SQL.Add(', LOG_Conteudo');
    SQL.Add('  FROM Log');
    Open;
    Result := FQuery.ToJSON;
    Close;
    ReadOnly := False;
  end;
end;

procedure TLog.Log(aJSON: TJSONObject);
var
  I: integer;
begin
  if aJSON.Count > 0 then
    try
      with FQuery do
      begin
        Close;
        SQL.Clear;
        SQL.Add('INSERT INTO Log (LOG_Data, LOG_Evento, LOG_Conteudo)');
        SQL.Add(' VALUES ');
        SQL.Add(' (');
        for I := 0 to pred(aJSON.Count) do
          if I = 0 then
            SQL.Add(QuotedStr(aJSON.Items[I].AsString))
          else
            SQL.Add(', ' + QuotedStr(aJSON.Items[I].AsString));
        SQL.Add(')');
        ExecSQL;
        Close;
      end;
    except
    end;
end;

function TLog.ValidaBanco: boolean;
begin
  Result := False;
  try
    with FQuery do
    begin
      Close;
      SQL.Text := 'PRAGMA table_info(Log)';
      Open;
      if isEmpty then
      begin
        Close;
        SQL.Clear;
        SQL.Add('CREATE TABLE Log(');
        SQL.Add('  LOG_ID integer primary key');
        SQL.Add(', LOG_Data varchar');
        SQL.Add(', LOG_Evento varchar');
        SQL.Add(', LOG_Conteudo varchar');
        SQL.Add(');');
        ExecSQL;
      end;
    end;
    Result := True;
  except
    Result := False;
  end;
end;

{ TDataSetJSONHelper }

function TDataSetJSONHelper.ToJSON: string;
var
  I: integer;
  JSONArr: TJSONArray;
  JSONObj: TJSONObject;
begin
  JSONArr := TJSONArray.Create;
  try
    while not EOF do
    begin
      JSONObj := TJSONObject.Create;
      for I := 0 to pred(FieldCount) do
      begin
        if not Fields.Fields[I].AsString.IsEmpty then
          JSONObj.Add(Fields.Fields[I].FieldName, Fields.Fields[I].AsString);

      end;
      JSONArr.Add(JSONObj);
      Next;
    end;
    Result := JSONArr.AsJSON;
  finally
    JSONArr.Free;
  end;
end;

end.
