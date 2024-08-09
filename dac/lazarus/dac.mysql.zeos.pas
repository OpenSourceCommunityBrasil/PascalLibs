// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.0
unit DAC.MySQL.Zeos;

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
    FConnection: TZConnection;
    FQuery: TZQuery;
    function GetDefaultLibDir: string;
  public
    constructor Create(aJSON: TJSONObject);
    destructor Destroy; override;
    function getConnection: TZConnection;
    function getQuery: TZQuery;
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
      Protocol := 'mysql';
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
  // libmysql.dll, libmariadb or libmysqld.dll

  if FileExists(DefaultDir + '\lib\libmysql.dll') then
    Result := DefaultDir + '\lib\libmysql.dll'
  else if FileExists(DefaultDir + '\lib\libmariadb.dll') then
    Result := DefaultDir + '\lib\libmariadb.dll'
  else if FileExists(DefaultDir + '\lib\libmysqld.dll') then
    Result := DefaultDir + '\lib\libmysqld.dll'
  else if FileExists(DefaultDir + 'libmysql.dll') then
    Result := DefaultDir + 'libmysql.dll'
  else if FileExists(DefaultDir + 'libmariadb.dll') then
    Result := DefaultDir + 'libmariadb.dll'
  else if FileExists(DefaultDir + 'libmysqld.dll') then
    Result := DefaultDir + 'libmysqld.dll'
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
