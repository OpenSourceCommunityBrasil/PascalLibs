// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.0.2
unit DAC.Firebird.Zeos;

{$mode ObjFPC}{$H+}

interface

uses
  fpJSON, SysUtils, Classes,
  ZConnection, ZDataset;

type
  TConnection = TZConnection;
  TQuery = TZQuery;

  { TDAC }

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
      HostName := aJSON.Get('dbserver', '');
      Port := aJSON.Get('dbport', 0);
      User := aJSON.Get('dbuser', '');
      Password := aJSON.Get('dbpassword', '');
      Protocol := 'firebird';
      LibraryLocation := GetDefaultLibDir;

      if aJSON.Get('banco', '') <> '' then
        Database := aJSON.Get('banco', '');
    end;
    FQuery := TQuery.Create(nil);
    FQuery.Connection := FConnection;
  except
    // log
  end;
end;

destructor TDAC.Destroy;
begin
  if FQuery <> nil then FQuery.Free;
  if FConnection <> nil then FConnection.Free;
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
  else if FileExists(DefaultDir + '\fbclient.dll') then
    Result := DefaultDir + '\fbclient.dll'
  else if FileExists(DefaultDir + '\fbembed.dll') then
    Result := DefaultDir + '\fbembed.dll'
  else
    raise Exception.Create('fbclient.dll ou fbembed.dll' +
      ' precisa estar na raiz do executável ou na pasta \lib\');
end;

function TDAC.getQuery: TQuery;
begin
  if not Assigned(FQuery) then
    FQuery := TQuery.Create(nil);
  Result := FQuery;
end;

end.
