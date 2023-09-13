// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki

unit DAC.Firebird.FireDAC;

interface

uses
  JSON, SysUtils,
  FireDAC.Comp.Client, FireDAC.Phys.FB;

type
  TDAC = class
  private
    FDriver: TFDPhysFBDriverLink;
    FConnection: TFDConnection;
    FQuery: TFDQuery;
  public
    constructor Create(aJSON: TJSONObject);
    destructor Destroy; override;
    function getConnection: TFDConnection;
    function getQuery: TFDQuery;
  end;

implementation

constructor TDAC.Create(aJSON: TJSONObject);
var
  DefaultDir: string;
begin
  if DirectoryExists(ExtractFileDir(ParamStr(0)) + '\lib\') then
    DefaultDir := ExtractFileDir(ParamStr(0)) + '\lib\'
  else
    DefaultDir := ExtractFileDir(ParamStr(0));

  FDriver := TFDPhysFBDriverLink.Create(nil);
  FDriver.DriverID := 'FB';
  FDriver.VendorLib := DefaultDir + 'fbclient.dll';

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

function TDAC.getQuery: TFDQuery;
begin
  if not Assigned(FQuery) then
    FQuery := TFDQuery.Create(nil);
  Result := FQuery;
end;

end.
