unit ConnectionPooler.FireDAC.Singleton;

interface

uses
  System.SyncObjs, System.SysUtils, FireDAC.Comp.Client

    ;

type
  TConnection = TFDConnection;

  { TConnectionPooler }

  TConnectionPooler = class
  private
    class var FInstance: TConnectionPooler; // Variável estática para a instância única
    class var FCreateLock: TCriticalSection; // Lock para criação thread-safe
    FDBPool: array of TConnection;
    FMaxConnections: Integer;
    FBaseConnection: TConnection;
    FPoolEvent: TEvent;
    function TestConnection: Boolean;
    constructor Create(MaxConnections: Integer; BaseConnector: TConnection);
    function CopyConnection(Input: TConnection): TConnection;
  public
    class function GetInstance(MaxConnections: Integer; BaseConnector: TConnection): TConnectionPooler; overload;
    class function GetInstance: TConnectionPooler; overload;
    class procedure ReleaseInstance;
    destructor Destroy; override;
    function Fetch: TConnection;
    procedure Dismiss(AConnection: TConnection);
  end;

implementation

{ TConnectionPooler }

class function TConnectionPooler.GetInstance(MaxConnections: Integer;
  BaseConnector: TConnection): TConnectionPooler;
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
  FPoolEvent := TEvent.Create(nil, True, False, '');

  FBaseConnection := BaseConnector;
  FMaxConnections := MaxConnections;
  if not TestConnection then
    exit;

  SetLength(FDBPool, FMaxConnections);

  FCreateLock.Acquire;
  try
    for I := 0 to Pred(FMaxConnections) do
    begin
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
    end;
  finally
    FCreateLock.Release;
  end;
end;

function TConnectionPooler.CopyConnection(Input: TConnection): TConnection;
begin
  TFDCustomConnection(Result) := TFDConnection(Input).CloneConnection;
end;

destructor TConnectionPooler.Destroy;
var
  I: Integer;
begin
  FCreateLock.Acquire;
  try
    // Desconectar e liberar conexões do pool
    for I := Pred(Length(FDBPool)) downto 0 do
    begin
      if Assigned(FDBPool[I]) then
      begin
        try
          FDBPool[I].Connected := False;
          FreeAndNil(FDBPool[I]);
        except
        end;
      end;
    end;
    SetLength(FDBPool, 0); // Esvaziar o array

    // Não liberar FBaseConnection, pois é externo
    FBaseConnection := nil;
  finally
    FCreateLock.Release;
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
    Result := False;
  end;
end;

function TConnectionPooler.Fetch: TConnection;
begin
  FCreateLock.Acquire;
  try
    if Length(FDBPool) > 0 then
    begin
      Result := FDBPool[High(FDBPool)];
      FDBPool[High(FDBPool)] := nil;
      SetLength(FDBPool, Length(FDBPool) - 1);
      FPoolEvent.ResetEvent;
    end;
  finally
    FCreateLock.Release;
  end;
end;

procedure TConnectionPooler.Dismiss(AConnection: TConnection);
begin
  if not Assigned(AConnection) then
    exit;

  FCreateLock.Acquire;
  try
    if Length(FDBPool) < FMaxConnections then
    begin
      SetLength(FDBPool, Length(FDBPool) + 1);
      FDBPool[High(FDBPool)] := AConnection;
      FPoolEvent.SetEvent;
    end
    else
      AConnection.Free; // Pool cheio, liberar conexão

  finally
    FCreateLock.Release;
  end;
end;

initialization

TConnectionPooler.FCreateLock := TCriticalSection.Create;

finalization

TConnectionPooler.ReleaseInstance;
FreeAndNil(TConnectionPooler.FCreateLock);

end.
