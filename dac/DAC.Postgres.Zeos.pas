unit DAC.Postgres.Zeos;

interface

uses
  JSON, SysUtils,
  ZConnection, ZDataset;

type
  TDAC = class
  private
    FConnection: TZConnection;
    FQuery: TZQuery;
  public
    constructor Create(aJSON: TJSONObject);
    destructor Destroy; override;
    function getConnection: TZConnection;
    function getQuery: TZQuery;
    function getConnectionStatus: string;
    function getDataBases: TZQuery;
    function getTables(aDataBaseName: string): TZQuery;
  end;

implementation

{ TDAC }

constructor TDAC.Create(aJSON: TJSONObject);
var
  DefaultDir: string;
begin
  if DirectoryExists(ExtractFileDir(ParamStr(0)) + '\lib\') then
    DefaultDir := ExtractFileDir(ParamStr(0)) + '\lib\'
  else
    DefaultDir := ExtractFileDir(ParamStr(0));

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
      LibraryLocation := DefaultDir + 'libpq.dll';

      if aJSON.GetValue('banco') <> nil then
        Database := aJSON.GetValue('banco').Value;
    end;
    FQuery := TZQuery.Create(nil);
    FQuery.Connection := FConnection;

    if aJSON.GetValue('schema') <> nil then
    begin
      FQuery.SQL.Add('SET search_path = ' + aJSON.GetValue('schema').Value);
      FQuery.ExecSQL;
    end;
  except
    // log
  end;
end;

destructor TDAC.Destroy;
begin
  if FQuery <> nil then
    FQuery.Free;
  if FConnection <> nil then
    FConnection.Free;
  inherited;
end;

function TDAC.getConnection: TZConnection;
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

function TDAC.getQuery: TZQuery;
begin
  Result := FQuery;
end;

function TDAC.getTables(aDataBaseName: string): TZQuery;
begin

end;

end.
