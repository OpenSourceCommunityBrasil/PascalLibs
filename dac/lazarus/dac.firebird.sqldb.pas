// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.0.1
unit DAC.Firebird.SQLDB;

{$mode ObjFPC}{$H+}

interface

uses
  {$IFDEF Windows}windows,{$ENDIF}
  fpJSON, SysUtils, Classes,
  IBConnection, SQLDB;

type
  TConnection = TIBConnection;
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
      Transaction := FTransaction;
      LoginPrompt := False;
      CharSet := 'utf-8';
      HostName := aJSON.Get('dbserver', '');
      Port := aJSON.Get('dbport', 0);
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
