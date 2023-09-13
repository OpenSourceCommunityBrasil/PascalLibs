// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki

unit DAC.Postgres.Zeos;

{$mode ObjFPC}{$H+}
interface

uses
  fpJSON, SysUtils, Classes,
  ZConnection, ZDataset;

type
  TConnection = TZConnection;
  TQuery = TZQuery;

  TDAC = class
  private
    FConnection: TZConnection;
    FQuery: TZQuery;
    FSchema: string;
    function GetDefaultDir(aFileName: string): string;
  public
    constructor Create(aJSON: TJSONObject);
    destructor Destroy; override;
    function getConnection: TConnection;
    function getQuery: TQuery;
    function getConnectionStatus: string;
    function getDataBases: TZQuery;
    function getTables(aDataBaseName: string): TZQuery;
  end;

implementation

{ TDAC }

constructor TDAC.Create(aJSON: TJSONObject);
begin
  FConnection := nil;
  FQuery := nil;
  FSchema := '';
  FConnection := TZConnection.Create(nil);
  try
    with FConnection do
    begin
      LoginPrompt := False;
      HostName := aJSON.Get('dbserver', '');
      Port := aJSON.Get('dbport', 0);
      User := aJSON.Get('dbuser', '');
      Password := aJSON.Get('dbpassword', '');
      Protocol := 'postgresql';
      LibraryLocation := GetDefaultDir('libpq.dll');

      if aJSON.Get('banco', '') <> '' then
        Database := aJSON.Get('banco', '');
    end;
    FQuery := TZQuery.Create(nil);
    FQuery.Connection := FConnection;

    if aJSON.Get('schema', '') <> '' then
      FSchema := aJSON.Get('schema', '');
  except
    // log
  end;
end;

destructor TDAC.Destroy;
begin
  FQuery.Connection := nil;
  if Assigned(FQuery) then
    FreeAndNil(FQuery);
  if Assigned(FConnection) then
    FreeAndNil(FConnection);
  inherited;
end;

function TDAC.getConnection: TConnection;
begin
  Result := FConnection;
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

function TDAC.getDataBases: TZQuery;
begin

end;

function TDAC.GetDefaultDir(aFileName: string): string;
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

function TDAC.getQuery: TQuery;
begin
  Result := FQuery;
end;

function TDAC.getTables(aDataBaseName: string): TZQuery;
begin

end;

end.
