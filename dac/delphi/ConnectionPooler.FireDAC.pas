unit ConnectionPooler.FireDAC;

interface

uses
  System.SyncObjs, FireDAC.Comp.Client, System.SysUtils;

type
  TConnection = TFDConnection;

  TConnectionPooler = class
  private
    FDBPool: array of TConnection;
    FLock: TCriticalSection;
    FMaxConnections: Integer;
    FBaseConnection: TConnection;
    FPoolEvent: TEvent;
    function TestConnection: Boolean;
  public
    constructor Create(MaxConnections: Integer; BaseConnector: TConnection);
    destructor Destroy; override;
    function Fetch(TimeoutMS: Cardinal = 30000): TConnection; // Timeout padrão de 30s
    procedure Dismiss(AConnection: TConnection);
  end;

implementation

uses
  System.Classes;

{ TConnectionPooler }

constructor TConnectionPooler.Create(MaxConnections: Integer; BaseConnector: TConnection);
var
  I: Integer;
begin
  FLock := TCriticalSection.Create;
  FPoolEvent := TEvent.Create(nil, True, False, '');

  FBaseConnection := BaseConnector;
  FMaxConnections := MaxConnections;
  if not TestConnection then
    exit;

  SetLength(FDBPool, FMaxConnections);
  FLock.Acquire;
  try
    for I := 0 to Pred(FMaxConnections) do
    begin
      FDBPool[I] := TConnection(FBaseConnection.CloneConnection);
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
    FLock.Release;
  end;
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
    Result := False;
  end;
end;

function TConnectionPooler.Fetch(TimeoutMS: Cardinal = 30000): TConnection;
begin
  FLock.Acquire;
  try
    if Length(FDBPool) > 0 then
    begin
      Result := FDBPool[High(FDBPool)];
      FDBPool[High(FDBPool)] := nil;
      SetLength(FDBPool, Length(FDBPool) - 1);
    end
    else
      Result := nil;
  finally
    FLock.Release;
  end;
end;

procedure TConnectionPooler.Dismiss(AConnection: TConnection);
begin
  if not Assigned(AConnection) then
    exit;

  FLock.Acquire;
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
    FLock.Release;
  end;
end;

end.
