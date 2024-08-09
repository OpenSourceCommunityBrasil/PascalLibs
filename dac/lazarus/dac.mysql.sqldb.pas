// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.0
unit DAC.MySQL.SQLDB;

{$mode ObjFPC}{$H+}

interface

uses
  {$IFDEF Windows}windows,{$ENDIF}
  fpJSON, SysUtils, Classes,
  mysql80conn, SQLDB;

type
  TConnection = TSQLConnector;
  TQuery = TSQLQuery;

  { TDAC }

  TDAC = class
  private
    FConnection: TConnection;
    FQuery: TQuery;
    FTransaction: TSQLTransaction;
    function GetDefaultLibDir: string;
    procedure SetEnvironmentPath;
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
  FTransaction := TSQLTransaction.Create(nil);
  try
    SetEnvironmentPath;
    with FConnection do
    begin
      ConnectorType := 'MySQL 8.0';
      Transaction := FTransaction;
      LoginPrompt := False;
      CharSet := 'utf-8';

      Params.Add('port=%d', [aJSON.Get('dbport', 3306)]);
      HostName := aJSON.Get('dbserver', '');
      DatabaseName := aJSON.Get('banco', '');
      UserName := aJSON.Get('dbuser', '');
      Password := aJSON.Get('dbpassword', '');
    end;
    FQuery := TQuery.Create(nil);
    FQuery.DataBase := FConnection;
    FConnection.Open;
  except
    // log
  end;
end;

destructor TDAC.Destroy;
begin
  if Assigned(FQuery) then
  begin
    FQuery.DataBase := nil;
    FreeAndNil(FQuery);
  end;

  if Assigned(FConnection)  then FreeAndNil(FConnection);
  if Assigned(FTransaction) then FreeAndNil(FTransaction);
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

procedure TDAC.SetEnvironmentPath;
var
  envpath: TStringList;
  I: integer;
begin
  envpath := TStringList.Create;
  try
    // get environment path
    envpath.AddDelimitedText(GetEnvironmentVariable('path'), ';', True);
    envpath.Sorted := True;

    // detect if the dblib is defined on the path
    if not envpath.Find(GetDefaultLibDir, I) then
    begin
      envpath.Add(ExtractFileDir(GetDefaultLibDir));
      envpath.Delimiter := ';';

      // save new path
      {$IF Defined(Windows)}
      SetEnvironmentVariable(Pchar('Path'), PChar(envpath.DelimitedText));
      {$IFEND}
    end;
  finally
    envpath.Free;
  end;
end;

function TDAC.getQuery: TQuery;
begin
  if not Assigned(FQuery) then
    FQuery := TFDQuery.Create(nil);
  Result := FQuery;
end;

end.
