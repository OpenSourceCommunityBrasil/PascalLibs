// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.0
unit DAC.Firebird.FireDAC;

interface

uses
  JSON, SysUtils,
  FireDAC.Comp.Client, FireDAC.Phys.FB;

type
  TConnection = TFDConnection;
  TQuery = TFDQuery;

  TDAC = class
  private
    FDriver: TFDPhysFBDriverLink;
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
  FDriver := TFDPhysFBDriverLink.Create(nil);
  FDriver.DriverID := 'FB';
  FDriver.VendorLib := GetDefaultLibDir;

  FConnection := TConnection.Create(nil);
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
  // Firebird depende de fbembed.dll ou fbclient.dll

  if FileExists(DefaultDir + '\lib\fbclient.dll') then
    Result := DefaultDir + '\lib\fbclient.dll'
  else if FileExists(DefaultDir + '\lib\fbembed.dll') then
    Result := DefaultDir + '\lib\fbembed.dll'
  else if FileExists(DefaultDir + 'fbclient.dll') then
    Result := DefaultDir + 'fbclient.dll'
  else if FileExists(DefaultDir + 'fbembed.dll') then
    Result := DefaultDir + 'fbembed.dll'
  else
    raise Exception.Create('fbclient.dll ou fbembed.dll' +
      ' precisam estar na raiz do executável ou na pasta \lib\');
end;

function TDAC.getQuery: TQuery;
begin
  if not Assigned(FQuery) then
    FQuery := TQuery.Create(nil);
  Result := FQuery;
end;

end.
