// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.0.1
unit DAC.MySQL.FireDAC;

interface

uses
  JSON, SysUtils,
  FireDAC.Comp.Client, FireDAC.Phys.MySQL;

type
  TConnection = TFDConnection;
  TQuery = TFDQuery;

  TDAC = class
  private
    FDriver: TFDPhysMySQLDriverLink;
    FConnection: TConnection;
    FQuery: TQuery;
    function GetDefaultLibDir: string;
  public
    constructor Create(aJSON: TJSONObject);
    destructor Destroy; override;
    function getConnection: TConnection;
    function getQuery: TQuery;
  end;

implementation

constructor TDAC.Create(aJSON: TJSONObject);
begin
  FDriver := TFDPhysMySQLDriverLink.Create(nil);
  FDriver.DriverID := 'MySQL';
  FDriver.VendorLib := GetDefaultLibDir;

  FConnection := TConnection.Create(nil);
  try
    with FConnection do
    begin
      LoginPrompt := false;
      Params.Add('DriverID=MySQL');
      Params.Add('Server=' + aJSON.GetValue('dbserver').Value);
      Params.Add('User_Name=' + aJSON.GetValue('dbuser').Value);
      Params.Add('Password=' + aJSON.GetValue('dbpassword').Value);
      Params.Add('Port=' + aJSON.GetValue('dbport').Value);
      if aJSON.GetValue('banco') <> nil then
        Params.Add('Database=' + aJSON.GetValue('banco').Value);

      FQuery := TQuery.Create(nil);
      FQuery.Connection := FConnection;
      FQuery.ResourceOptions.SilentMode := true;
    end;
  except
    // log
  end;
end;

destructor TDAC.Destroy;
begin
  if Assigned(FDriver)     then FreeAndNil(FDriver);
  if Assigned(FQuery)      then FreeAndNil(FQuery);
  if Assigned(FConnection) then FreeAndNil(FConnection);
  inherited;
end;

function TDAC.getConnection: TConnection;
begin
  Result := FConnection;
end;

function TDAC.GetDefaultLibDir: string;
var
  DefaultDir: string;
begin
  Result := '';
  DefaultDir := ExtractFileDir(ParamStr(0));
  // libmysql.dll, libmariadb or libmysqld.dll

  if FileExists(DefaultDir + '\lib\libmysql.dll') then
    Result := DefaultDir + '\lib\libmysql.dll'
  else if FileExists(DefaultDir + '\lib\libmariadb.dll') then
    Result := DefaultDir + '\lib\libmariadb.dll'
  else if FileExists(DefaultDir + '\lib\libmysqld.dll') then
    Result := DefaultDir + '\lib\libmysqld.dll'
  else if FileExists(DefaultDir + '\libmysql.dll') then
    Result := DefaultDir + '\libmysql.dll'
  else if FileExists(DefaultDir + '\libmariadb.dll') then
    Result := DefaultDir + '\libmariadb.dll'
  else if FileExists(DefaultDir + '\libmysqld.dll') then
    Result := DefaultDir + '\libmysqld.dll'
  else
    raise Exception.Create('libmysql.dll, libmariadb.dll ou libmysqld.dll' +
      ' precisam estar na raiz do executável ou na pasta \lib\');
end;

function TDAC.getQuery: TQuery;
begin
  if not Assigned(FQuery) then
    FQuery := TQuery.Create(nil);
  Result := FQuery;
end;

end.
