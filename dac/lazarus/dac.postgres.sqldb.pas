// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.0
unit DAC.Postgres.SQLDB;

{$mode ObjFPC}{$H+}

interface

uses
  {$IFDEF Windows}windows,{$ENDIF}
  fpJSON, SysUtils, Classes, DB,
  PQConnection, SQLDB, SQLDBLib;

type
  TConnection = TSQLConnector;
  TQuery = TSQLQuery;

  { TDAC }

  TDAC = class
  private
    FConnection: TConnection;
    FQuery: TQuery;
    FTransaction: TSQLTransaction;
    FSchema: string;
    function GetDefaultLibDir: string;
    procedure SetEnvironmentPath;
  public
    constructor Create(aJSON: TJSONObject);
    destructor Destroy; override;
    function getConnection: TConnection;
    function getQuery: TQuery;
    function getConnectionStatus: string;
  end;

implementation

{ TDAC }

function TDAC.GetDefaultLibDir: string;
var
  DefaultDir: string;
begin
  Result := '';
  DefaultDir := ExtractFileDir(ParamStr(0));

  if FileExists(DefaultDir + '\lib\libpq.dll') then
    Result := DefaultDir + '\lib\libpq.dll'
  else if FileExists(DefaultDir + 'libpq.dll') then
    Result := DefaultDir + 'libpq.dll'
  else
    raise Exception.Create('libpq.dll' +
      ' precisa estar na raiz do executável ou na pasta \lib\');
end;

procedure TDAC.SetEnvironmentPath;
var
  envpath: TStringList;
  I: integer;
begin
  envpath := TStringList.Create;
  try
    // get environment path
    envpath.AddDelimitedText(GetEnvironmentVariable('path'), ';', True);
    envpath.Sorted := True;

    // detect if the dblib is defined on the path
    if not envpath.Find(GetDefaultLibDir, I) then
    begin
      envpath.Add(ExtractFileDir(GetDefaultLibDir));
      envpath.Delimiter := ';';

      // save new path
      {$IF Defined(Windows)}
      SetEnvironmentVariable(Pchar('Path'), PChar(envpath.DelimitedText));
      {$IFEND}
    end;
  finally
    envpath.Free;
  end;
end;

constructor TDAC.Create(aJSON: TJSONObject);
begin
  FConnection := nil;
  FQuery := nil;
  FSchema := '';
  FConnection := TConnection.Create(nil);
  FTransaction := TSQLTransaction.Create(nil);
  try
    SetEnvironmentPath;
    with FConnection do
    begin
      ConnectorType := 'PostgreSQL';
      Transaction := FTransaction;
      LoginPrompt := False;
      CharSet := 'utf-8';

      Params.Add('port=%d', [aJSON.Get('dbport', 5432)]);
      Params.Add('host=%s', [aJSON.Get('dbserver', '')]);
      DatabaseName := aJSON.Get('banco', '');
      UserName := aJSON.Get('dbuser', '');
      Password := aJSON.Get('dbpassword', '');
    end;
    FQuery := TQuery.Create(nil);
    FQuery.DataBase := FConnection;
    FSchema := aJSON.Get('schema', '');
    FConnection.Open;
  except
    // log
  end;
end;

destructor TDAC.Destroy;
begin
  if Assigned(FQuery) then
  begin
    FQuery.Close;
    FQuery.DataBase := nil;
    FreeAndNil(FQuery);
  end;

  if Assigned(FConnection)  then FreeAndNil(FConnection);
  if Assigned(FTransaction) then FreeAndNil(FTransaction);
  inherited Destroy;
end;

function TDAC.getConnection: TConnection;
begin
  Result := FConnection;
end;

function TDAC.getQuery: TQuery;
begin
  Result := FQuery;
end;

function TDAC.getConnectionStatus: string;
var
  JSONobj: TJSONObject;
  I: integer;
begin
  FQuery.SQL.Clear;
  FQuery.SQL.Add('SELECT ');
  FQuery.SQL.Add('  COUNT(*) AS TOTALCONNECTIONS');
  FQuery.SQL.Add(', (SELECT COUNT(*) FROM pg_stat_activity ' +
    'WHERE state = ''active'') AS TOTALACTIVE');
  FQuery.SQL.Add(', (SELECT COUNT(*) FROM pg_stat_activity ' +
    'WHERE state = ''idle'') AS TOTALIDLE');
  FQuery.SQL.Add('  FROM pg_stat_activity');
  FQuery.Open;
  JSONobj := TJSONObject.Create;
  try
    for I := 0 to pred(FQuery.FieldCount) do
      JSONobj.Add(FQuery.Fields.Fields[I].FieldName,
        FQuery.Fields.Fields[I].AsString);
    Result := JSONobj.AsJSON;
  finally
    JSONobj.Free;
  end;
end;

end.
