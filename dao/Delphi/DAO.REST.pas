// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.1
unit DAO.REST;

// comment this line to make this unit handle VCL controls instead of FMX.
{$DEFINE HAS_FMX}

interface

uses
  {$IFDEF HAS_FMX}
  FMX.Grid,
  {$ELSE}
  Vcl.Grids,
  {$ENDIF}
  Classes, SysUtils, System.JSON,
  REST.Client, REST.Types, REST.Response.Adapter, REST.Authenticator.Basic,
  Data.DB, Data.DBJson;

type
  TDAOClientREST = class
  private
    FAdapter: TRESTResponseDataSetAdapter;
    FBaseURL: string;
    FBasicAuth: THTTPBasicAuthenticator;
    FMemTable: TDataSet;
    FRESTClient: TRESTClient;
    FRESTRequest: TRESTRequest;
    FResponse: TRESTResponse;
    FStatusCode: integer;
    FUserAgent: string;
    FGrid: TStringGrid;
    procedure SetBaseURL(const Value: string);
    procedure SetUserAgent(const Value: string);
    procedure doRequest;
    procedure doFillGrid;
  public
    constructor Create; overload;
    constructor Create(ABaseURL: string); overload;
    constructor Create(ABaseURL, AUserAgent: string); overload;
    constructor Create(ABaseURL, AUserName, APassword: string); overload;
    destructor Destroy; override;

    function AddBody(AName: string; AValue: string; AEncode: boolean = false)
      : TDAOClientREST; overload;
    function AddBody(AName: string; AValue: integer; AEncode: boolean = false)
      : TDAOClientREST; overload;
    function AddBody(AValue: TStream; AContentType: string): TDAOClientREST; overload;
    function AddBody(AName: string; AValue: TStream; AContentType: string): TDAOClientREST; overload;
    function AddBody(AValue: TJSONObject): TDAOClientREST; overload;
    function AddBody(ABodyContent: string; AContentType: TRESTContentType)
      : TDAOClientREST; overload;
    function AddHeader(AName: string; AValue: string; AEncode: boolean = false)
      : TDAOClientREST; overload;
    function AddHeader(AName: string; AValue: integer; AEncode: boolean = false)
      : TDAOClientREST; overload;
    procedure BasicAuth(AUserName: string; APassword: string);
    function Clear: TDAOClientREST;
    function Grid(AGrid: TStringGrid): TDAOClientREST; overload;
    function Grid: TStringGrid; overload;
    function MemTable(AMemTable: TDataSet): TDAOClientREST;
    function Resource(AEndpoint: string): TDAOClientREST;
    function SetHeader(AList: TStringList): TDAOClientREST; overload;
    function SetHeader(AObjects: TJSONObject): TDAOClientREST; overload;
    procedure Delete;
    procedure Get;
    procedure Post;
    procedure Put;
    procedure Patch;

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

function TDAOClientREST.AddBody(AName: string; AValue: integer; AEncode: boolean)
  : TDAOClientREST;
begin
  Result := Self;
  AddBody(AName, AValue.ToString, AEncode);
end;

function TDAOClientREST.AddHeader(AName: string; AValue: integer; AEncode: boolean)
  : TDAOClientREST;
begin
  Result := Self;
  AddHeader(AName, AValue.ToString, AEncode);
end;

function TDAOClientREST.AddBody(AValue: TStream; AContentType: string): TDAOClientREST;
begin
  Result := Self;
  FRESTRequest.AddBody(AValue, AContentType);
end;

function TDAOClientREST.AddBody(AName, AValue: string; AEncode: boolean): TDAOClientREST;
begin
  Result := Self;
  if AEncode then
    FRESTRequest.AddParameter(AName, AValue, pkREQUESTBODY, [])
  else
    FRESTRequest.AddParameter(AName, AValue, pkREQUESTBODY, [poDoNotEncode]);
end;

function TDAOClientREST.AddHeader(AName, AValue: string; AEncode: boolean)
  : TDAOClientREST;
begin
  Result := Self;
  if AEncode then
    FRESTRequest.AddParameter(AName, AValue, pkQUERY, [])
  else
    FRESTRequest.AddParameter(AName, AValue, pkQUERY, [poDoNotEncode]);
end;

procedure TDAOClientREST.BasicAuth(AUserName, APassword: string);
begin
  if not assigned(FBasicAuth) then
    FBasicAuth := THTTPBasicAuthenticator.Create(AUserName, APassword);
  FRESTClient.Authenticator := FBasicAuth;
end;

constructor TDAOClientREST.Create;
begin
  FRESTClient := TRESTClient.Create(nil);
  FRESTRequest := TRESTRequest.Create(nil);
  FAdapter := TRESTResponseDataSetAdapter.Create(nil);
  FAdapter.TypesMode := TJSONTypesMode.JSONOnly;
  FRESTRequest.Client := FRESTClient;

  FRESTClient.ConnectTimeout := 10000;
  FRESTClient.ReadTimeout := 30000;
end;

function TDAOClientREST.Clear: TDAOClientREST;
begin
  Result := Self;
  FRESTRequest.Params.Clear;
  FMemTable := nil;
  FAdapter.Active := false;
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
  FreeAndNil(FAdapter);
  FreeAndNil(FResponse);
  FreeAndNil(FRESTRequest);
  FreeAndNil(FBasicAuth);
  FreeAndNil(FRESTClient);
  inherited;
end;

procedure TDAOClientREST.doFillGrid;
var
  I, J: integer;
  ResponseArray: TJSONArray;
  ResponseItem: TJSONObject;
  Column: TStringColumn;
begin
  {$IFDEF HAS_FMX}
  FGrid.BeginUpdate;
  try
    try
      FGrid.ClearColumns;
      ResponseArray := TJSONArray(FResponse.JSONValue);
      FGrid.RowCount := ResponseArray.Count;
      For I := 0 to pred(ResponseArray.Count) do
      begin
        ResponseItem := TJSONObject(ResponseArray.Items[I]);
        for J := 0 to pred(ResponseItem.Count) do
        begin
          if I = 0 then
          begin
            Column := TStringColumn.Create(FGrid);
            Column.Header := ResponseItem.Pairs[J].JsonString.Value;
            FGrid.Model.InsertColumn(J, Column);
          end;
          FGrid.Cells[J, I] := ResponseItem.Pairs[J].JSONValue.Value;
        end;
      end;
    except
      raise;
    end;
  finally
    FGrid.EndUpdate;
  end;
  {$ENDIF}
end;

procedure TDAOClientREST.doRequest;
begin
  FRESTRequest.Execute;
  FResponse := TRESTResponse(FRESTRequest.Response);
  FStatusCode := FRESTRequest.Response.StatusCode;
  if assigned(FMemTable) then
  begin
    FAdapter.Dataset := FMemTable;
    FAdapter.Response := FResponse;
    FAdapter.Active := true;
  end;
  if assigned(FGrid) then
    doFillGrid;
end;

procedure TDAOClientREST.Get;
begin
  FRESTRequest.Method := rmGET;
  doRequest;
end;

function TDAOClientREST.Grid: TStringGrid;
begin
  Result := FGrid;
end;

function TDAOClientREST.Grid(AGrid: TStringGrid): TDAOClientREST;
begin
  Result := Self;
  FGrid := AGrid;
end;

function TDAOClientREST.MemTable(AMemTable: TDataSet): TDAOClientREST;
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
      FRESTRequest.Params.Items[I].Free;

  for I := 0 to pred(AObjects.Count) do
    FRESTRequest.Params.AddItem(AObjects.Pairs[I].JsonString.Value,
      AObjects.Pairs[I].JSONValue.Value, pkHTTPHEADER);
end;

function TDAOClientREST.SetHeader(AList: TStringList): TDAOClientREST;
var
  I: integer;
begin
  Result := Self;
  for I := pred(FRESTRequest.Params.Count) downto 0 do
    if not(FRESTRequest.Params.Items[I].Kind in [pkFILE, pkREQUESTBODY]) then
      FRESTRequest.Params.Items[I].Free;

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
  BasicAuth(AUserName, APassword);
end;

function TDAOClientREST.AddBody(ABodyContent: string; AContentType: TRESTContentType)
  : TDAOClientREST;
begin
  Result := Self;
  FRESTRequest.AddBody(ABodyContent, AContentType);
end;

function TDAOClientREST.AddBody(AName: string; AValue: TStream;
  AContentType: string): TDAOClientREST;
begin
  Result := Self;
  FRESTRequest.AddParameter(AName, TStringStream(AValue).DataString, pkREQUESTBODY);
end;

end.
