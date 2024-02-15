// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki

unit DAC.MySQL.FireDAC;

interface

uses
  JSON, SysUtils,
  FireDAC.Comp.Client, FireDAC.Phys.MySQL;

type
  TDAC = class
  private
    FDriver: TFDPhysMySQLDriverLink;
    FConnection: TFDConnection;
    FQuery: TFDQuery;
    function GetDefaultLibDir: string;
  public
    constructor Create(aJSON: TJSONObject);
    destructor Destroy; override;
    function getConnection: TFDConnection;
    function getQuery: TFDQuery;
  end;

implementation

constructor TDAC.Create(aJSON: TJSONObject);
begin
  FDriver := TFDPhysMySQLDriverLink.Create(nil);
  FDriver.DriverID := 'MySQL';
  FDriver.VendorLib := GetDefaultLibDir;

  FConnection := TFDConnection.Create(nil);
  try
    with FConnection do
    begin
      LoginPrompt := false;
      Params.Add('DriverID=FB');
      Params.Add('Server=' + aJSON.GetValue('dbserver').Value);
      Params.Add('User_Name=' + aJSON.GetValue('dbuser').Value);
      Params.Add('Password=' + aJSON.GetValue('dbpassword').Value);
      Params.Add('Port=' + aJSON.GetValue('dbport').Value);
      if aJSON.GetValue('banco') <> nil then
        Params.Add('Database=' + aJSON.GetValue('banco').Value);

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

function TDAC.GetDefaultLibDir: string;
var
  DefaultDir: string;
begin
  Result := '';
  DefaultDir := ExtractFileDir(ParamStr(0));
  // libmysql.dll, libmariadb or libmysqld.dll
  // procurando no diretório do exe primeiro, depois no diretório \lib\

  if FileExists(DefaultDir + 'libmysql.dll') then
    Result := DefaultDir + 'libmysql.dll'
  else if FileExists(DefaultDir + 'libmariadb.dll') then
    Result := DefaultDir + 'libmariadb.dll'
  else if FileExists(DefaultDir + 'libmysqld.dll') then
    Result := DefaultDir + 'libmysqld.dll'
  else if FileExists(DefaultDir + '\lib\libmysql.dll') then
    Result := DefaultDir + '\lib\libmysql.dll'
  else if FileExists(DefaultDir + '\lib\libmariadb.dll') then
    Result := DefaultDir + '\lib\libmariadb.dll'
  else if FileExists(DefaultDir + '\lib\libmysqld.dll') then
    Result := DefaultDir + '\lib\libmysqld.dll'
  else
    raise Exception.Create('libmysql.dll, libmariadb.dll ou libmysqld.dll' +
      ' precisam estar na raiz do executável ou na pasta \lib\');
end;

function TDAC.getQuery: TFDQuery;
begin
  if not Assigned(FQuery) then
    FQuery := TFDQuery.Create(nil);
  Result := FQuery;
end;

end.
