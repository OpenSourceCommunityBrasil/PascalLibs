// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki

unit DAC.Postgres.FireDAC;

interface

uses
  JSON, SysUtils,
  FireDAC.Comp.Client, FireDAC.Phys.PG;

type
  TDAC = class
  private
    FDriver: TFDPhysPgDriverLink;
    FConnection: TFDConnection;
    FQuery: TFDQuery;
    function GetDefaultLibDir: string;
  public
    constructor Create(aJSON: TJSONObject);
    destructor Destroy; override;
    function getConnection: TFDConnection;
    function getQuery: TFDQuery;
    function getConnectionStatus: string;
    function getDataBases: TFDQuery;
    function getTables(aDataBaseName: string): TFDQuery;
  end;

implementation

{ TDAC }

constructor TDAC.Create(aJSON: TJSONObject);
begin
  FDriver := TFDPhysPgDriverLink.Create(nil);
  FDriver.DriverID := 'PG';
  FDriver.VendorLib := GetDefaultLibDir;

  FConnection := TFDConnection.Create(nil);
  try
    with FConnection do
    begin
      LoginPrompt := false;
      Params.Add('DriverID=PG');
      Params.Add('Server=' + aJSON.GetValue('dbserver').Value);
      Params.Add('User_Name=' + aJSON.GetValue('dbuser').Value);
      Params.Add('Password=' + aJSON.GetValue('dbpassword').Value);
      Params.Add('Port=' + aJSON.GetValue('dbport').Value);

      if aJSON.GetValue('banco') <> nil then
        Params.Add('Database=' + aJSON.GetValue('banco').Value);

      if aJSON.GetValue('schema') <> nil then
        ExecSQL('SET search_path = ' + aJSON.GetValue('schema').Value);

      FQuery := TFDQuery.Create(nil);
      FQuery.Connection := FConnection;
      FQuery.ResourceOptions.SilentMode := true;
    end;
  except
    // log
  end;
end;

destructor TDAC.Destroy;
begin
  if FDriver <> nil then
    FDriver.Free;
  if FQuery <> nil then
    FQuery.Free;
  if FConnection <> nil then
    FConnection.Free;
  inherited;
end;

function TDAC.getConnection: TFDConnection;
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
  FQuery.OpenOrExecute;
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

function TDAC.getDataBases: TFDQuery;
begin

end;

function TDAC.GetDefaultLibDir: string;
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

function TDAC.getQuery: TFDQuery;
begin
  Result := FQuery;
end;

function TDAC.getTables(aDataBaseName: string): TFDQuery;
begin

end;

end.
