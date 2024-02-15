// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki

unit DAC.Postgres.Zeos;

interface

uses
  JSON, SysUtils, Classes,
  ZConnection, ZDataset;

type
  TConnection = TZConnection;
  TQuery = TZQuery;

  TDAC = class
  private
    FConnection: TZConnection;
    FQuery: TZQuery;
    FSchema: string;
    function GetDefaultLibDir: string;
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
      LoginPrompt := false;
      HostName := aJSON.GetValue('dbserver').Value;
      Port := aJSON.GetValue('dbport').Value.ToInteger;
      User := aJSON.GetValue('dbuser').Value;
      Password := aJSON.GetValue('dbpassword').Value;
      Protocol := 'postgresql';
      LibraryLocation := GetDefaultLibDir;

      if aJSON.GetValue('banco') <> nil then
        Database := aJSON.GetValue('banco').Value;
    end;
    FQuery := TZQuery.Create(nil);
    FQuery.Connection := FConnection;

    if aJSON.GetValue('schema') <> nil then
      FSchema := aJSON.GetValue('schema').Value;
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
      JSONobj.AddPair(FQuery.Fields.Fields[I].FieldName,
        FQuery.Fields.Fields[I].AsString);
    Result := JSONobj.ToJSON;
  finally
    JSONobj.Free;
  end;
end;

function TDAC.getDataBases: TZQuery;
begin

end;

function TDAC.GetDefaultLibDir(aFileName: string): string;
var
  DefaultDir: string;
begin
  Result := '';
  DefaultDir := ExtractFileDir(ParamStr(0));
  if FileExists(DefaultDir + '\lib\libpq.dll') then
    Result := DefaultDir + '\lib\libpq.dll'
  else if FileExists(DefaultDir + 'libpq.dll') then
    Result := DefaultDir + 'libpq.dll';
end;

function TDAC.getQuery: TQuery;
begin
  if not FSchema.IsEmpty then
    FQuery.SQL.Add('SET search_path = ' + QuotedStr(FSchema) + ';');
  Result := FQuery;
end;

function TDAC.getTables(aDataBaseName: string): TZQuery;
begin

end;

end.
