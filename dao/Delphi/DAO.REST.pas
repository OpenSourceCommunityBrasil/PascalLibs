// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.6
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
  Classes, SysUtils, System.JSON, Math, System.RegularExpressions,
  REST.Client, REST.Types, REST.Response.Adapter, REST.Authenticator.Basic,
  Data.DB, Data.DBJson;

type
  TDAOClientREST = class
  private
    FAdapter: TRESTResponseDataSetAdapter;
    FBaseURL: string;
    FBasicAuth: THTTPBasicAuthenticator;
    FConnectTimeout: integer;
    FContentType: string;
    FGrid: TStringGrid;
    FInternalDataSets: array of TDataSet;
    FInternalJSONParts: array of string;
    FMemTable: TDataSet;
    FResponse: TRESTResponse;
    FResponseBytes: TBytes;
    FResponseJSON: TJSONValue;
    FResponseLength: Cardinal;
    FResponseStream: TStream;
    FResponseText: string;
    FResponseTimeout: integer;
    FRESTClient: TRESTClient;
    FRESTRequest: TRESTRequest;
    FRootElement: string;
    FStatusCode: integer;
    FUserAgent: string;
    isJSON: boolean;
    procedure SetBaseURL(const Value: string);
    procedure SetUserAgent(const Value: string);
    procedure doRequest;
    procedure doFillGrid;
    procedure doProcessPart;
    procedure GetResponseStream;
    procedure setRootElement(const Value: string);
    function FormatDateTimeFields(const Value: TJSONValue): TJSONValue;
    procedure SetConnectTimeout(const Value: integer);
    procedure SetResponseTimeout(const Value: integer);
  public
    constructor Create; overload;
    constructor Create(ABaseURL: string); overload;
    constructor Create(ABaseURL, AUserAgent: string); overload;
    constructor Create(ABaseURL, AUserName, APassword: string); overload;
    destructor Destroy; override;

    function AddBody(AName: string; AValue: string; AEncode: boolean = false): TDAOClientREST; overload;
    function AddBody(AName: string; AValue: integer; AEncode: boolean = false): TDAOClientREST; overload;
    function AddBody(AValue: TStream; AContentType: string): TDAOClientREST; overload;
    function AddBody(AName: string; AValue: TStream; AContentType: string): TDAOClientREST; overload;
    function AddBody(AValue: TJSONObject): TDAOClientREST; overload;
    function AddBody(ABodyContent: string; AContentType: TRESTContentType): TDAOClientREST; overload;
    function AddBody(AName: string; ADataSet: TDataSet): TDAOClientREST; overload;
    function AddHeader(AName: string; AValue: string; AEncode: boolean = false): TDAOClientREST; overload;
    function AddHeader(AName: string; AValue: integer; AEncode: boolean = false): TDAOClientREST; overload;
    procedure BasicAuth(AUserName: string; APassword: string);
    function Clear: TDAOClientREST;
    function ContentType(AValue: string): TDAOClientREST;
    function Grid(AGrid: TStringGrid): TDAOClientREST; overload;
    function Grid: TStringGrid; overload;
    function JSONPartToDataSet(AJSONPart: string; ADataSet: TDataSet): TDAOClientREST; overload;
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
    property ConnectTimeout: integer read FConnectTimeout write SetConnectTimeout;
    property Response: TRESTResponse read FResponse;
    property ResponseBytes: TBytes read FResponseBytes;
    property ResponseTimeout: integer read FResponseTimeout write SetResponseTimeout;
    property ResponseJSON: TJSONValue read FResponseJSON;
    property ResponseLength: Cardinal read FResponseLength;
    property ResponseStream: TStream read FResponseStream;
    property ResponseText: string read FResponseText;
    property RootElement: string read FRootElement write setRootElement;
    property StatusCode: integer read FStatusCode;
    property UserAgent: string read FUserAgent write SetUserAgent;
  end;

implementation

{ TDAOClientREST }

function TDAOClientREST.FormatDateTimeFields(const Value: TJSONValue): TJSONValue;
var
  Pair: TJSONPair;
  Item, NewValue, NewItem: TJSONValue;
  S: string;
  DT: TDateTime;
  Parsed: boolean;
  CustomFormatSettings: TFormatSettings;
  DateTimePattern, YearFirstPattern: string;
begin
  // dd/mm/yyyy hh:nn:ss or mm/dd/yyyy hh:nn:ss
  DateTimePattern := '^\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2}$';
  // yyyy/mm/dd hh:nn:ss
  YearFirstPattern := '^\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}$';

  if Value is TJSONObject then
  begin
    Result := TJSONObject.Create;
    for Pair in TJSONObject(Value) do
    begin
      NewValue := FormatDateTimeFields(Pair.JsonValue);
      TJSONObject(Result).AddPair(Pair.JsonString.Value, NewValue);
    end;
  end
  else if Value is TJSONArray then
  begin
    Result := TJSONArray.Create;
    for Item in TJSONArray(Value) do
    begin
      NewItem := FormatDateTimeFields(Item);
      TJSONArray(Result).AddElement(NewItem);
    end;
  end
  else if Value is TJSONString then
  begin
    S := TJSONString(Value).Value;

    // Define padrões de timestamp
    CustomFormatSettings := TFormatSettings.Create;
    CustomFormatSettings.DateSeparator := '/';
    CustomFormatSettings.TimeSeparator := ':';
    CustomFormatSettings.LongTimeFormat := 'hh:nn:ss';

    if TRegEx.IsMatch(S, YearFirstPattern) then
    begin
      CustomFormatSettings.ShortDateFormat := 'yyyy/mm/dd';
      if TryStrToDateTime(S, DT, CustomFormatSettings) then
        Result := TJSONString.Create(FormatDateTime('yyyy/mm/dd hh:nn:ss', DT));
    end
    else if TRegEx.IsMatch(S, DateTimePattern) then
    begin
      Parsed := false;
      CustomFormatSettings.ShortDateFormat := 'dd/mm/yyyy';
      if TryStrToDateTime(S, DT, CustomFormatSettings) then
        Parsed := True
      else
      begin
        CustomFormatSettings.ShortDateFormat := 'mm/dd/yyyy';
        if TryStrToDateTime(S, DT, CustomFormatSettings) then
          Parsed := True;
      end;
      if Parsed then
        Result := TJSONString.Create(FormatDateTime('yyyy/mm/dd hh:nn:ss', DT));
    end
    else
      Result := TJSONString.Create(S);
  end
  else
    Result := Value.Clone as TJSONValue;
end;

function TDAOClientREST.AddBody(AValue: TJSONObject): TDAOClientREST;
begin
  Result := Self;
  FRESTRequest.AddBody(AValue, ooREST);
end;

function TDAOClientREST.AddBody(AName: string; AValue: integer; AEncode: boolean): TDAOClientREST;
begin
  Result := Self;
  AddBody(AName, AValue.ToString, AEncode);
end;

function TDAOClientREST.AddHeader(AName: string; AValue: integer; AEncode: boolean): TDAOClientREST;
begin
  Result := Self;
  AddHeader(AName, AValue.ToString, AEncode);
end;

function TDAOClientREST.AddBody(AValue: TStream; AContentType: string): TDAOClientREST;
begin
  Result := Self;
  {$IFDEF CompilerVersion > 32}
  FRESTRequest.AddBody(AValue, AContentType);
  {$ELSE}
  FRESTRequest.AddBody(AValue, ContentTypeFromString(AContentType));
  {$ENDIF}
end;

function TDAOClientREST.AddBody(AName, AValue: string; AEncode: boolean): TDAOClientREST;
begin
  Result := Self;
  if AEncode then
    FRESTRequest.AddParameter(AName, AValue, pkREQUESTBODY, [])
  else
    FRESTRequest.AddParameter(AName, AValue, pkREQUESTBODY, [poDoNotEncode]);
end;

function TDAOClientREST.AddHeader(AName, AValue: string; AEncode: boolean): TDAOClientREST;
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
  FRESTClient.RaiseExceptionOn500 := false;
  FAdapter := TRESTResponseDataSetAdapter.Create(nil);
  FAdapter.TypesMode := TJSONTypesMode.StringOnly;
  FAdapter.StringFieldSize := 32 * 1024 - 1;

  FRESTRequest.Client := FRESTClient;

  FRESTClient.SynchronizedEvents := false;
  FRESTRequest.SynchronizedEvents := false;
  ConnectTimeout := 10000;
  ResponseTimeout := 30000;
  //  FInternalDataSets := TList<TDataSet>.Create;
  //  FInternalJSONParts := TList<string>.Create;
  SetLength(FInternalDataSets, 0);
  SetLength(FInternalJSONParts, 0);
end;

function TDAOClientREST.Clear: TDAOClientREST;
begin
  Result := Self;
  FRESTRequest.Params.Clear;
  FAdapter.ClearDataSet;
  FMemTable := nil;
  FAdapter.Active := false;
end;

function TDAOClientREST.ContentType(AValue: string): TDAOClientREST;
begin
  Result := Self;
  FContentType := AValue;
  FRESTClient.ContentType := AValue;
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
  doRequest;
end;

destructor TDAOClientREST.Destroy;
begin
  FreeAndNil(FAdapter);
  if assigned(FResponse) then
    FreeAndNil(FResponse);
  if assigned(FResponseStream) then
    FreeAndNil(FResponseStream);
  FreeAndNil(FRESTRequest);
  FreeAndNil(FBasicAuth);
  FreeAndNil(FRESTClient);
  if assigned(FResponseJSON) then
    FreeAndNil(FResponseJSON);
  inherited;
end;

procedure TDAOClientREST.doFillGrid;
var
  I, J: integer;
  ResponseArray: TJSONArray;
  ResponseItem: TJSONObject;
  {$IFDEF HAS_FMX}
  Column: TStringColumn;
  {$ENDIF}
begin
  {$IFDEF HAS_FMX}
  FGrid.BeginUpdate;
  try
    try
      FGrid.ClearColumns;
      ResponseArray := TJSONArray(FResponseJSON);
      FGrid.RowCount := ResponseArray.Count;
      for I := 0 to pred(ResponseArray.Count) do
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
          FGrid.Cells[J, I] := ResponseItem.Pairs[J].JsonValue.Value;
          FGrid.Columns[J].Width := Max(FGrid.Columns[J].Width,
            ResponseItem.Pairs[J].JsonValue.Value.Trim.Length * 6.4);
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

procedure TDAOClientREST.doProcessPart;
var
  I: Integer;
begin
  for I := 0 to pred(Length(FInternalDataSets)) do
    if assigned(FInternalDataSets[I]) then
    begin
      FInternalDataSets[I].Close;
      FAdapter.Dataset := FInternalDataSets[I];
      FAdapter.UpdateDataSet(FResponseJSON.GetValue<TJSONValue>(FInternalJSONParts[I]));

      FInternalDataSets[I].Filter := '';
      FInternalDataSets[I].Filtered := False;
    end;
end;

procedure TDAOClientREST.doRequest;
var
  OriginalJSON: TJSONValue;
begin
  try
    FRESTRequest.Execute;
    FResponse := TRESTResponse(FRESTRequest.Response);
    FStatusCode := FRESTRequest.Response.StatusCode;
    FResponseText := FResponse.Content;
    FContentType := FResponse.ContentType;
    isJSON := FContentType = CONTENTTYPE_APPLICATION_JSON;
    if isJSON then
    begin
      OriginalJSON := TJSONObject.ParseJSONValue(FResponseText);
      if assigned(OriginalJSON) then
        try
          if assigned(FResponseJSON) then
            FreeAndNil(FResponseJSON);
          FResponseJSON := FormatDateTimeFields(OriginalJSON);
        finally
          OriginalJSON.Free;
        end
      else
        FResponseJSON := nil;
    end
    else if assigned(FResponseJSON) then
      FreeAndNil(FResponseJSON);
    FResponseBytes := FResponse.RawBytes;
    FResponseLength := FResponse.ContentLength;
    GetResponseStream;
    if not assigned(FMemtable) and (Length(FInternalDataSets) > 0) then
      doProcessPart
    else if assigned(FMemTable) and assigned(FResponseJSON) then
    begin
      FMemTable.Close;
      FAdapter.Dataset := FMemTable;
      FAdapter.UpdateDataSet(FResponseJSON);

      FMemTable.Filter := '';
      FMemTable.Filtered := False;
    end;
    if assigned(FGrid) and isJSON then
      doFillGrid;
  except
    on E: Exception do
    begin
      FStatusCode := 500;
      FResponseText := E.Message;
    end;
  end;
end;

procedure TDAOClientREST.Get;
begin
  FRESTRequest.Method := rmGET;
  doRequest;
end;

procedure TDAOClientREST.GetResponseStream;
begin
  if FResponse <> nil then
  begin
    FResponseStream := TStringStream.Create('', TEncoding.UTF8);
    try
      TStringStream(FResponseStream).Write(Response.RawBytes,
        Response.ContentLength);
      FResponseStream.Position := 0;
    except
      FreeAndNil(FResponseStream);
    end;
  end;
end;

function TDAOClientREST.Grid: TStringGrid;
begin
  Result := FGrid;
end;

function TDAOClientREST.JSONPartToDataSet(AJSONPart: string; ADataSet: TDataSet): TDAOClientREST;
begin
  Result := Self;
  // alimenta um vetor interno com os datasets e os jsonparts pra ser executado
  // logo após o request
  //  FInternalJSONParts.Add(AJSONPart);
  //  FInternalDataSets.Add(ADataSet);

  SetLength(FInternalJSONParts, Length(FInternalJSONParts) + 1);
  FInternalJSONParts[High(FInternalJSONParts)] := AJSONPart;

  SetLength(FInternalDataSets, Length(FInternalDataSets) + 1);
  FInternalDataSets[High(FInternalDataSets)] := ADataSet;
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

procedure TDAOClientREST.SetConnectTimeout(const Value: integer);
begin
  FConnectTimeout := Value;
  FRESTClient.ConnectTimeout := Value;
end;

function TDAOClientREST.SetHeader(AObjects: TJSONObject): TDAOClientREST;
var
  I: integer;
begin
  Result := Self;
  for I := pred(FRESTRequest.Params.Count) downto 0 do
    if not (FRESTRequest.Params.Items[I].Kind in [pkFILE, pkREQUESTBODY]) then
      FRESTRequest.Params.Items[I].Free;

  for I := 0 to pred(AObjects.Count) do
    FRESTRequest.Params.AddItem(AObjects.Pairs[I].JsonString.Value,
      AObjects.Pairs[I].JsonValue.Value, pkHTTPHEADER);
end;

procedure TDAOClientREST.SetResponseTimeout(const Value: integer);
begin
  FResponseTimeout := Value;
  FRESTClient.ReadTimeout := Value;
end;

procedure TDAOClientREST.setRootElement(const Value: string);
begin
  if assigned(FResponse) then
  begin
    FRootElement := Value;
    FResponse.RootElement := Value;
    if isJSON then
      FResponseJSON := FResponse.JsonValue;
    FResponseText := FResponse.Content;
  end;
end;

function TDAOClientREST.SetHeader(AList: TStringList): TDAOClientREST;
var
  I: integer;
begin
  Result := Self;
  for I := pred(FRESTRequest.Params.Count) downto 0 do
    if not (FRESTRequest.Params.Items[I].Kind in [pkFILE, pkREQUESTBODY]) then
      FRESTRequest.Params.Items[I].Free;

  for I := 0 to pred(AList.Count) do
    FRESTRequest.Params.AddItem(AList.KeyNames[I], AList.ValueFromIndex[I],
      pkHTTPHEADER);
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

function TDAOClientREST.AddBody(ABodyContent: string; AContentType: TRESTContentType): TDAOClientREST;
begin
  Result := Self;
  FRESTRequest.AddBody(ABodyContent, AContentType);
end;

function TDAOClientREST.AddBody(AName: string; AValue: TStream; AContentType: string): TDAOClientREST;
begin
  Result := Self;
  FRESTRequest.AddParameter(AName, TStringStream(AValue).DataString,
    pkREQUESTBODY);
end;

function TDAOClientREST.AddBody(AName: string; ADataSet: TDataSet): TDAOClientREST;
var
  field: TField;
  JSONDataSet: TJSONArray;
  JSONFields: TJSONObject;
  decimal, thousand: char;
  tempstr: TStringStream;
begin
  Result := Self;
  if not Assigned(ADataSet) then exit;

  decimal := FormatSettings.DecimalSeparator;
  thousand := FormatSettings.ThousandSeparator;
  FormatSettings.DecimalSeparator := '.';
  FormatSettings.ThousandSeparator := ',';
  JSONDataSet := TJSONArray.Create;
  try
    ADataSet.First;
    while not ADataSet.Eof do
    begin
      JSONFields := TJSONObject.Create;
      for field in ADataSet.Fields do
        if field.IsNull then
          JSONFields.AddPair(field.DisplayName, TJSONNull.Create)
        else
          case field.DataType of
            ftMemo, ftWideMemo, ftStream, ftOraBlob, ftOraClob, ftWideString:
              JSONFields.AddPair(field.DisplayName, field.AsString);

            ftUnknown, ftString, ftDate, ftTime, ftDateTime, ftBoolean, ftBytes,
              ftVarBytes, ftAutoInc, ftBlob, ftGraphic, ftFmtMemo, ftParadoxOle,
              ftDBaseOle, ftTypedBinary, ftCursor, ftFixedChar, ftADT, ftArray,
              ftReference, ftDataSet, ftVariant, ftInterface, ftIDispatch, ftGuid,
              ftTimeStamp, ftFixedWideChar, ftOraTimeStamp, ftOraInterval, ftConnection,
              ftParams, ftTimeStampOffset, ftObject:
              JSONFields.AddPair(field.DisplayName, field.DisplayText);

            ftSmallint, ftInteger, ftWord, ftFloat, ftCurrency, ftBCD, ftLargeint,
              ftFMTBcd, ftLongWord, ftShortint, ftByte, ftExtended, ftSingle:
              JSONFields.AddPair(field.DisplayName,
                TJSONNumber.Create(field.DisplayText));
          end;
      JSONDataSet.Add(JSONFields);
      ADataSet.Next;
    end;
    ADataSet.First;
    FRESTRequest.AddParameter(AName, JSONDataSet.ToJSON, pkREQUESTBODY);
    FormatSettings.DecimalSeparator := decimal;
    FormatSettings.ThousandSeparator := thousand;
  finally
    JSONDataSet.Free;
  end;
end;

end.

