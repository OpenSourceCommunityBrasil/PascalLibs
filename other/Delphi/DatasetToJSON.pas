unit DatasetToJSON;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.NetEncoding,
  Data.DB;

type
  TDataSetToJSON = class
  private
    FInternalJSON: TJSONArray;
  public
    constructor Create;
    destructor Destroy; override;
    class function DatasetToJSON(const ADataSet: TDataSet): string;
    class function DataSetToJSONObject(const ADataSet: TDataSet): TJSONObject;
    class function DataSetToJSONArray(const ADataSet: TDataSet): TJSONArray;
  end;

  TDS2JHelper = class helper for TDataSet
  public
    function ToJSON: string;
    function ToJSONObject: TJSONObject;
    function ToJSONArray: TJSONArray;
    procedure SaveAsJSONToFile(AFileName: String);
  end;

implementation

{ TDataSetToJSON }

constructor TDataSetToJSON.Create;
begin

end;

class function TDataSetToJSON.DatasetToJSON(const ADataSet: TDataSet): string;
var
  field: TField;
  JSONDataSet: TJSONArray;
  JSONFields: TJSONObject;
  decimal, thousand: char;
  tempstr: TStringStream;
begin
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
    Result := JSONDataSet.ToJSON;
    FormatSettings.DecimalSeparator := decimal;
    FormatSettings.ThousandSeparator := thousand;
  finally
    JSONDataSet.Free;
  end;
end;

class function TDataSetToJSON.DataSetToJSONArray(const ADataSet: TDataSet): TJSONArray;
begin
  Result := TJSONObject.ParseJSONValue(DatasetToJSON(ADataSet)) as TJSONArray;
end;

class function TDataSetToJSON.DataSetToJSONObject(const ADataSet: TDataSet): TJSONObject;
begin
  Result := TJSONObject.ParseJSONValue(DatasetToJSON(ADataSet)) as TJSONObject;
end;

destructor TDataSetToJSON.Destroy;
begin

  inherited;
end;

{ TDS2JHelper }

procedure TDS2JHelper.SaveAsJSONToFile(AFileName: String);
begin
  with TStringStream.Create(Self.ToJSON, TEncoding.UTF8) do
    try
      SaveToFile(AFileName);
    finally
      Free;
    end;
end;

function TDS2JHelper.ToJSON: string;
begin
  Result := TDataSetToJSON.DatasetToJSON(Self);
end;

function TDS2JHelper.ToJSONArray: TJSONArray;
begin
  Result := TDataSetToJSON.DataSetToJSONArray(Self);
end;

function TDS2JHelper.ToJSONObject: TJSONObject;
begin
  Result := TDataSetToJSON.DataSetToJSONObject(Self);
end;

end.
