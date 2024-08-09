// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.0
unit RESTDAO;

interface

uses
  Classes, SysUtils, System.JSON,
  REST.Client, REST.Types, REST.Response.Adapter, REST.Authenticator.Basic,
  FireDAC.Comp.Client;

type
  TDAOClientREST = class
  private
    FAdapter: TRESTResponseDataSetAdapter;
    FBaseURL: string;
    FBasicAuth: THTTPBasicAuthenticator;
    FMemTable: TFDMemTable;
    FRESTClient: TRESTClient;
    FRESTRequest: TRESTRequest;
    FResponse: TRESTResponse;
    FStatusCode: integer;
    FUserAgent: string;
    procedure SetBaseURL(const Value: string);
    procedure SetUserAgent(const Value: string);
    procedure doRequest;
  public
    constructor Create; overload;
    constructor Create(ABaseURL: string); overload;
    constructor Create(ABaseURL, AUserAgent: string); overload;
    constructor Create(ABaseURL, AUserName, APassword: string); overload;
    destructor Destroy; override;

    function AddBody(AName: string; AValue: string;
      AOptions: TRESTRequestParameterOptions = []): TDAOClientREST; overload;
    function AddBody(AName: string; AValue: integer;
      AOptions: TRESTRequestParameterOptions = []): TDAOClientREST; overload;
    function AddBody(AValue: TStream; AContentType: string): TDAOClientREST; overload;
    function AddBody(AValue: TJSONObject): TDAOClientREST; overload;
    function AddHeader(AName: string; AValue: string;
      AOptions: TRESTRequestParameterOptions = []): TDAOClientREST; overload;
    function AddHeader(AName: string; AValue: integer;
      AOptions: TRESTRequestParameterOptions = []): TDAOClientREST; overload;
    procedure BasicAuth(AUserName: string; APassword: string);
    function Clear: TDAOClientREST;
    procedure Get;
    function MemTable(AMemTable: TFDMemTable): TDAOClientREST;
    procedure Post;
    procedure Put;
    procedure Patch;
    procedure Delete;
    function Resource(AEndpoint: string): TDAOClientREST;
    function SetHeader(AList: TStringList): TDAOClientREST; overload;
    function SetHeader(AObjects: TJSONObject): TDAOClientREST; overload;

    property BaseURL: string read FBaseURL write SetBaseURL;
    property Response: TRESTResponse read FResponse;
    property StatusCode: integer read FStatusCode;
    property UserAgent: string read FUserAgent write SetUserAgent;
  end;

implementation

{ TDAOClientREST }

function TDAOClientREST.AddBody(AValue: TJSONObject): TDAOClientREST;
begin
  Result := Self;
  FRESTRequest.AddBody(AValue, ooREST);
end;

function TDAOClientREST.AddBody(AName: string; AValue: integer;
  AOptions: TRESTRequestParameterOptions): TDAOClientREST;
begin
  Result := Self;
  FRESTRequest.AddParameter(AName, AValue.ToString, pkREQUESTBODY, AOptions);
end;

function TDAOClientREST.AddHeader(AName: string; AValue: integer;
  AOptions: TRESTRequestParameterOptions): TDAOClientREST;
begin
  Result := Self;
  AddHeader(AName, AValue.ToString, AOptions);
end;

function TDAOClientREST.AddBody(AValue: TStream; AContentType: string): TDAOClientREST;
begin
  Result := Self;
  FRESTRequest.AddBody(AValue, AContentType);
end;

function TDAOClientREST.AddBody(AName, AValue: string; AOptions: TRESTRequestParameterOptions)
  : TDAOClientREST;
begin
  Result := Self;
  FRESTRequest.AddParameter(AName, AValue, pkREQUESTBODY, AOptions);
end;

function TDAOClientREST.AddHeader(AName, AValue: string; AOptions: TRESTRequestParameterOptions)
  : TDAOClientREST;
begin
  Result := Self;
  FRESTRequest.AddParameter(AName, AValue, pkHTTPHEADER, AOptions);
end;

procedure TDAOClientREST.BasicAuth(AUserName, APassword: string);
begin
  FRESTClient.Authenticator := FBasicAuth;
  FBasicAuth.Username := AUserName;
  FBasicAuth.Password := APassword;
end;

constructor TDAOClientREST.Create;
begin
  FRESTClient := TRESTClient.Create(nil);
  FRESTRequest := TRESTRequest.Create(nil);
  FAdapter := TRESTResponseDataSetAdapter.Create(nil);
  FRESTRequest.Client := FRESTClient;

  FRESTClient.ConnectTimeout := 10000;
  FRESTClient.ReadTimeout := 30000;
end;

function TDAOClientREST.Clear: TDAOClientREST;
begin
  Result := Self;
  FRESTRequest.Params.Clear;
end;

constructor TDAOClientREST.Create(ABaseURL, AUserAgent: string);
begin
  Create;
  BaseURL := ABaseURL;
  UserAgent := AUserAgent;
end;

procedure TDAOClientREST.Delete;
begin
  FRESTRequest.Method := rmDELETE;
  FRESTRequest.Execute;
end;

destructor TDAOClientREST.Destroy;
begin
  FreeAndNil(FRESTClient);
  FreeAndNil(FRESTRequest);
  FreeAndNil(FAdapter);
  inherited;
end;

procedure TDAOClientREST.doRequest;
begin
  FRESTRequest.Execute;
  FResponse := TRESTResponse(FRESTRequest.Response);
  FStatusCode := FRESTRequest.Response.StatusCode;
  if Assigned(FMemTable) then
  begin
    FAdapter.Dataset := FMemTable;
    FAdapter.Response := FResponse;
    FAdapter.Active := true;
  end;
end;

procedure TDAOClientREST.Get;
begin
  FRESTRequest.Method := rmGET;
  doRequest;
end;

function TDAOClientREST.MemTable(AMemTable: TFDMemTable): TDAOClientREST;
begin
  Result := Self;
  FMemTable := AMemTable;
end;

procedure TDAOClientREST.Patch;
begin
  FRESTRequest.Method := rmPATCH;
  doRequest;
end;

procedure TDAOClientREST.Post;
begin
  FRESTRequest.Method := rmPOST;
  doRequest;
end;

procedure TDAOClientREST.Put;
begin
  FRESTRequest.Method := rmPUT;
  doRequest;
end;

function TDAOClientREST.Resource(AEndpoint: string): TDAOClientREST;
begin
  Result := Self;
  FRESTRequest.Resource := AEndpoint;
end;

constructor TDAOClientREST.Create(ABaseURL: string);
begin
  Create;
  BaseURL := ABaseURL;
end;

procedure TDAOClientREST.SetBaseURL(const Value: string);
begin
  FBaseURL := Value;
  FRESTClient.BaseURL := FBaseURL;
end;

function TDAOClientREST.SetHeader(AObjects: TJSONObject): TDAOClientREST;
var
  I: integer;
begin
  Result := Self;
  for I := pred(FRESTRequest.Params.Count) downto 0 do
    if not(FRESTRequest.Params.Items[I].Kind in [pkFILE, pkREQUESTBODY]) then
      FRESTRequest.Params.Items[I].Clear;

  for I := 0 to pred(AObjects.Count) do
    FRESTRequest.Params.AddItem(AObjects.Pairs[I].JsonString.Value,
      AObjects.Pairs[I].JsonValue.Value, pkHTTPHEADER);
end;

function TDAOClientREST.SetHeader(AList: TStringList): TDAOClientREST;
var
  I: integer;
begin
  Result := Self;
  for I := pred(FRESTRequest.Params.Count) downto 0 do
    if not(FRESTRequest.Params.Items[I].Kind in [pkFILE, pkREQUESTBODY]) then
      FRESTRequest.Params.Items[I].Clear;

  for I := 0 to pred(AList.Count) do
    FRESTRequest.Params.AddItem(AList.KeyNames[I], AList.ValueFromIndex[I], pkHTTPHEADER);
end;

procedure TDAOClientREST.SetUserAgent(const Value: string);
begin
  FUserAgent := Value;
  FRESTClient.UserAgent := FUserAgent;
end;

constructor TDAOClientREST.Create(ABaseURL, AUserName, APassword: string);
begin
  Create;
  BaseURL := ABaseURL;

end;

end.
