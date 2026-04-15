unit ConnectionPooler.Zeos.Singleton;

{$mode Delphi}

interface

uses
  SyncObjs, SysUtils, ZConnection;

type
  TConnection = TZConnection;

  { TConnectionPooler }

  TConnectionPooler = class
  private
    class var FInstance: TConnectionPooler;
    class var FCreateLock: TCriticalSection;
    FDBPool: array of TConnection;
    FLock: TCriticalSection;
    FMaxConnections: Integer;
    FBaseConnection: TConnection;
    FPoolEvent: TEvent;
    function CopyConnection(Input: TConnection): TConnection;
    function TestConnection: Boolean;

    constructor Create(MaxConnections: Integer; BaseConnector: TConnection);
  public
    class function GetInstance(MaxConnections: Integer; BaseConnector: TConnection): TConnectionPooler; overload;
    class function GetInstance: TConnectionPooler; overload;
    class procedure ReleaseInstance;
    destructor Destroy; override;
    function Fetch: TConnection;
    procedure Dismiss(AConnection: TConnection);
    function GetPoolSize: Integer;
  end;

implementation

uses
  Classes;

{ TConnectionPooler }

class function TConnectionPooler.GetInstance(MaxConnections: Integer; BaseConnector: TConnection): TConnectionPooler;
begin
  FCreateLock.Acquire;
  try
    if FInstance = nil then
      FInstance := TConnectionPooler.Create(MaxConnections, BaseConnector);
    Result := FInstance;
  finally
    FCreateLock.Release;
  end;
end;

class function TConnectionPooler.GetInstance: TConnectionPooler;
begin
  Result := FInstance;
end;

class procedure TConnectionPooler.ReleaseInstance;
begin
  FCreateLock.Acquire;
  try
    FreeAndNil(FInstance);
  finally
    FCreateLock.Release;
  end;
end;

constructor TConnectionPooler.Create(MaxConnections: Integer; BaseConnector: TConnection);
var
  I: Integer;
begin
  inherited Create;

  FLock := TCriticalSection.Create;
  FPoolEvent := TEvent.Create(nil, True, False, '');

  FBaseConnection := BaseConnector;
  FMaxConnections := MaxConnections;
  if not TestConnection then exit;

  SetLength(FDBPool, FMaxConnections);
  for I := 0 to Pred(FMaxConnections) do
  try
    FLock.Acquire;
    FDBPool[I] := CopyConnection(FBaseConnection);
    try
      FDBPool[I].Connected := True;
    except
      on E: Exception do
      begin
        FDBPool[I].Free;
        FDBPool[I] := nil;
      end;
    end;
  finally
    FLock.Release;
  end;
end;

function TConnectionPooler.CopyConnection(Input: TConnection): TConnection;
begin
  Result := TZConnection.Create(nil);
  TZConnection(Result).Catalog := TZConnection(Input).Catalog;
  TZConnection(Result).Database := TZConnection(Input).Database;
  TZConnection(Result).HostName := TZConnection(Input).HostName;
  TZConnection(Result).LibraryLocation := TZConnection(Input).LibraryLocation;
  TZConnection(Result).Password := TZConnection(Input).Password;
  TZConnection(Result).Port := TZConnection(Input).Port;
  TZConnection(Result).Protocol := TZConnection(Input).Protocol;
  TZConnection(Result).User := TZConnection(Input).User;
  TZConnection(Result).Properties.AddText(TZConnection(Input).Properties.text);
end;

destructor TConnectionPooler.Destroy;
var
  I: Integer;
begin
  FLock.Acquire;
  try
    // Desconectar e liberar conexões do pool
    for I := Pred(Length(FDBPool)) downto 0 do
    begin
      if Assigned(FDBPool[I]) then
      begin
        FDBPool[I].Connected := False;
        FreeAndNil(FDBPool[I]);
      end;
    end;
    SetLength(FDBPool, 0); // Esvaziar o array

    // Não liberar FBaseConnection, pois é externo
    FBaseConnection := nil;
  finally
    FLock.Release;
    FLock.Free;
  end;
  FPoolEvent.Free;
  inherited;
end;

function TConnectionPooler.TestConnection: Boolean;
begin
  Result := False;
  try
    FBaseConnection.Connected := True;
    Result := FBaseConnection.Connected;
  except
    on E: Exception do
    begin
      Result := False;
    end;
  end;
end;

function TConnectionPooler.Fetch: TConnection;
begin
  Result := nil;
  while True do
  begin
    FLock.Acquire;
    try
      if Length(FDBPool) > 0 then
      begin
        Result := FDBPool[High(FDBPool)];
        FDBPool[High(FDBPool)] := nil;
        SetLength(FDBPool, Length(FDBPool) - 1);
        FPoolEvent.ResetEvent;
        Exit;
      end;
    finally
      FLock.Release;
    end;
  end;
end;

procedure TConnectionPooler.Dismiss(AConnection: TConnection);
begin
  if not Assigned(AConnection) then Exit;

  FLock.Acquire;
  try
    if Length(FDBPool) < FMaxConnections then
    begin
      SetLength(FDBPool, Length(FDBPool) + 1);
      FDBPool[High(FDBPool)] := AConnection;
      FPoolEvent.SetEvent;          // ← acorda quem está esperando
    end
    else
      AConnection.Free; // pool cheio (não deve acontecer mais)
  finally
    FLock.Release;
  end;
end;

function TConnectionPooler.GetPoolSize: Integer;
begin
  FLock.Acquire;
  try
    Result := Length(FDBPool);
  finally
    FLock.Release;
  end;
end;

initialization
  TConnectionPooler.FCreateLock := TCriticalSection.Create;

finalization
  TConnectionPooler.ReleaseInstance;
  FreeAndNil(TConnectionPooler.FCreateLock);

end.
