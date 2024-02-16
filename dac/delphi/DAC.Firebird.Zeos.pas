// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki

unit DAC.Firebird.Zeos;

interface

uses
  JSON, SysUtils,
  ZConnection, ZDataset;

type
  TConnection = TZConnection;
  TQuery = TZQuery;

  TDAC = class
  private
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
  FConnection := nil;
  FQuery := nil;
  FConnection := TConnection.Create(nil);
  try
    with FConnection do
    begin
      LoginPrompt := False;
      HostName := aJSON.GetValue('dbserver').Value;
      Port := aJSON.GetValue('dbport').Value.ToInteger;
      User := aJSON.GetValue('dbuser').Value;
      Password := aJSON.GetValue('dbpassword').Value;
      Protocol := 'firebird';
      LibraryLocation := GetDefaultLibDir;

      if aJSON.GetValue('banco') <> nil then
        Database := aJSON.GetValue('banco').Value;
    end;
    FQuery := TQuery.Create(nil);
    FQuery.Connection := FConnection;
  except
    // log
  end;
end;

destructor TDAC.Destroy;
begin
  if Assigned(FQuery) then  FreeAndNil(FQuery);
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
  if FileExists(DefaultDir + 'fbclient.dll') then
    Result := DefaultDir + 'fbclient.dll'
  else if FileExists(DefaultDir + 'fbembed.dll') then
    Result := DefaultDir + 'fbembed.dll'
  else if FileExists(DefaultDir + '\lib\fbclient.dll') then
    Result := DefaultDir + '\lib\fbclient.dll'
  else if FileExists(DefaultDir + '\lib\fbembed.dll') then
    Result := DefaultDir + '\lib\fbembed.dll';
end;

function TDAC.getQuery: TQuery;
begin
  if not Assigned(FQuery) then
    FQuery := TQuery.Create(nil);
  Result := FQuery;
end;

end.
