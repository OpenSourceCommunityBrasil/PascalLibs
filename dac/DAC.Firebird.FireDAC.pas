unit DAC.Firebird.FireDAC;

interface

uses
  System.Classes, System.SysUtils, System.JSON,
  FireDAC.Comp.Client,

    ;

type
  TDAC = class
  private
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
begin
  FConnection := TFDConnection.Create(nil);
  FConnection.LoginPrompt := false;
  FConnection.DriverName := 'FB';

  if aJSON.GetValue('dbserver') <> nil then
    FConnection.Params.Add('Server=' + aJSON.GetValue('dbserver').Value);

  FConnection.Params.Add('DriverID=FB');
  FConnection.Params.Add('User_Name=' + aJSON.GetValue('dbuser').Value);
  FConnection.Params.Add('Password=' + aJSON.GetValue('dbpassword').Value);

  if aJSON.GetValue('dbport') <> nil then
    FConnection.Params.Add('Port=' + aJSON.GetValue('dbport').Value);

  if aJSON.GetValue('banco') <> nil then
    FConnection.Params.Add('Database=' + aJSON.GetValue('banco').Value);

  FQuery := TFDQuery.Create(nil);
  FQuery.Connection := FConnection;
  FQuery.ResourceOptions.SilentMode := true;
end;

destructor TDAC.Destroy;
begin
  if Assigned(FConnection) then
    FConnection.Free;
  if Assigned(FQuery) then
    FQuery.Free;
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
