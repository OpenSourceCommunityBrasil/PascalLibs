unit RESTDAO;

interface

uses
  Classes, SysUtils, Generics.Collections,
  REST.Types, REST.Client,
  System.JSON;

type
  TRESTDAO = class
  private
    FRESTClient: TRESTClient;
    FRESTRequest: TRESTRequest;

    procedure SetBaseURL(const Value: string);
    function GetBaseURL: string;
    procedure SetResource(const Value: string);
    function GetResource: string;
    procedure DefineParams(aMethod: TRESTRequestMethod;
      aHeaders: TJSONObject = nil; aBody: TJSONObject = nil); overload;
    procedure DefineFileParams(aMethod: TRESTRequestMethod;
      aHeaders: TJSONObject = nil; aBody: TStream = nil);
    function GetUserAgent: string;
    procedure SetUserAgent(const Value: string);
  public
    constructor Create; overload;
    constructor Create(aBaseURL: string); overload;
    constructor Create(aBaseURL, aUserAgent: string); overload;
    destructor Destroy; override;
    function Get(aParams: TJSONObject = nil): string;
    function GetFile(aParams: TJSONObject = nil): TStream;
    function Post(aHeaderParams: TJSONObject = nil; aBody: TJSONObject = nil)
      : string; overload;
    function Post(aHeaderParams: TJSONObject = nil; aBody: TStream = nil)
      : string; overload;
    function PostFile(aHeaderParams: TJSONObject = nil;
      aBody: TJSONObject = nil): TStream; overload;
    function PostFile(aHeaderParams: TJSONObject = nil; aBody: TStream = nil)
      : TStream; overload;
    function Delete(aParams: TJSONObject = nil): string;

    property BaseURL: string read GetBaseURL write SetBaseURL;
    property Endpoint: string read GetResource write SetResource;
    property UserAgent: string read GetUserAgent write SetUserAgent;
  end;

  THelper = class helper for TCustomRESTResponse
  public
    procedure SaveToStream(aStream: TStream);
  end;

implementation

{ TRESTDAO }

constructor TRESTDAO.Create;
begin
  FRESTClient := nil;
  FRESTRequest := nil;
  FRESTClient := TRESTClient.Create('');
  FRESTRequest := TRESTRequest.Create(nil);

  FRESTRequest.Client := FRESTClient;
end;

constructor TRESTDAO.Create(aBaseURL: string);
begin
  Create;
  BaseURL := aBaseURL;
end;

constructor TRESTDAO.Create(aBaseURL, aUserAgent: string);
begin
  Create;
  BaseURL := aBaseURL;
  UserAgent := aUserAgent;
end;

procedure TRESTDAO.DefineFileParams(aMethod: TRESTRequestMethod;
  aHeaders: TJSONObject; aBody: TStream);
var
  I: integer;
begin
  FRESTRequest.Method := aMethod;
  FRESTRequest.Params.Clear;
  if aHeaders <> nil then
    for I := 0 to pred(aHeaders.Count) do
      FRESTRequest.AddParameter(aHeaders.Pairs[I].JsonString.Value,
        aHeaders.Pairs[I].JsonValue.Value, pkQUERY);

  FRESTRequest.Body.ClearBody;
  if aBody <> nil then
    FRESTRequest.AddBody(aBody);
  FRESTRequest.Response := nil;
end;

procedure TRESTDAO.DefineParams(aMethod: TRESTRequestMethod;
  aHeaders, aBody: TJSONObject);
var
  I: integer;
begin
  FRESTRequest.Method := aMethod;
  FRESTRequest.Params.Clear;
  if aHeaders <> nil then
    for I := 0 to pred(aHeaders.Count) do
      FRESTRequest.AddParameter(aHeaders.Pairs[I].JsonString.Value,
        aHeaders.Pairs[I].JsonValue.Value, pkQUERY);

  FRESTRequest.Body.ClearBody;
  if aBody <> nil then
    FRESTRequest.AddBody(aBody);
  FRESTRequest.Response := nil;
end;

function TRESTDAO.Delete(aParams: TJSONObject): string;
begin
  Result := '';
  DefineParams(rmDELETE, aParams);
  FRESTRequest.Execute;
  Result := FRESTRequest.Response.Content;
end;

destructor TRESTDAO.Destroy;
begin
  if assigned(FRESTRequest) then
    FreeAndNil(FRESTRequest);

  if assigned(FRESTClient) then
    FreeAndNil(FRESTClient);

  inherited;
end;

function TRESTDAO.Get(aParams: TJSONObject): string;
begin
  Result := '';
  DefineParams(rmGET, aParams);
  FRESTRequest.Execute;
  Result := FRESTRequest.Response.Content;
end;

function TRESTDAO.GetFile(aParams: TJSONObject): TStream;
begin
  Result := nil;
  DefineFileParams(rmGET, aParams);
  FRESTRequest.Execute;
  FRESTRequest.Response.SaveToStream(Result);
end;

function TRESTDAO.PostFile(aHeaderParams, aBody: TJSONObject): TStream;
begin
  Result := nil;
  DefineParams(rmPOST, aHeaderParams, aBody);
  FRESTRequest.Execute;
  FRESTRequest.Response.SaveToStream(Result);
end;

function TRESTDAO.Post(aHeaderParams, aBody: TJSONObject): string;
begin
  Result := '';
  DefineParams(rmPOST, aHeaderParams, aBody);
  FRESTRequest.Execute;
  Result := FRESTRequest.Response.Content;
end;

function TRESTDAO.Post(aHeaderParams: TJSONObject; aBody: TStream): string;
begin
  Result := '';
  DefineFileParams(rmPOST, aHeaderParams, aBody);
  FRESTRequest.Execute;
  Result := FRESTRequest.Response.Content;
end;

function TRESTDAO.PostFile(aHeaderParams: TJSONObject; aBody: TStream): TStream;
begin
  Result := nil;
  DefineFileParams(rmPOST, aHeaderParams, aBody);
  FRESTRequest.Execute;
  FRESTRequest.Response.SaveToStream(Result);
end;

function TRESTDAO.GetBaseURL: string;
begin
  Result := FRESTClient.BaseURL;
end;

function TRESTDAO.GetResource: string;
begin
  Result := FRESTRequest.Resource;
end;

function TRESTDAO.GetUserAgent: string;
begin
  Result := FRESTClient.UserAgent;
end;

procedure TRESTDAO.SetBaseURL(const Value: string);
begin
  FRESTClient.BaseURL := Value;
end;

procedure TRESTDAO.SetResource(const Value: string);
begin
  FRESTRequest.Resource := Value;
end;

procedure TRESTDAO.SetUserAgent(const Value: string);
begin
  FRESTClient.UserAgent := Value;
end;

{ THelper }

procedure THelper.SaveToStream(aStream: TStream);
begin
  if aStream <> nil then
  begin
    aStream.Write(Self.RawBytes, length(Self.RawBytes));
    aStream.Position := 0;
  end;
end;

end.
