// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.0
unit JSONUtils;

interface

// Comment this directive below to make this unit handle VCL controls instead of FMX.
{$DEFINE FMX}

uses
  {$IFDEF FMX}
  FMX.Forms, FMX.Edit, FMX.ComboEdit, FMX.StdCtrls, FMX.ExtCtrls,
  FMX.Controls, FMX.ListBox, FMX.DateTimeCtrls,
  {$ELSE}
  VCL.Forms, VCL.StdCtrls, VCL.ExtCtrls, VCL.ValEdit,
  {$ENDIF}
  System.JSON, System.Classes, System.SysUtils, System.Generics.Collections,
  System.Generics.Defaults, Data.DB;

type
  TSortOrder = (soAscending, soDescending);

  TJSONArraySorter = class helper for TJSONArray
  public
    procedure Sort(AKeyElement: string; AOrder: TSortOrder = soAscending);
  end;

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

function FormToJSONObject(const AForm: TForm): TJSONObject;
function FormToJSONString(const AForm: TForm): string;
procedure LoadFormFromJSON(const AJSON: TJSONObject; AForm: TForm);

implementation

{ TJSONArraySorter }

procedure TJSONArraySorter.Sort(AKeyElement: string; AOrder: TSortOrder);
var
  cntr: Integer;
  elementList: TList<TJSONValue>;
begin
  // Sort the elements. We have to sort them because they change constantly
  elementList := TList<TJSONValue>.Create;
  try
    // Get the elements
    for cntr := 0 to self.Count - 1 do
      elementList.Add(self.Items[cntr]);
    elementList.Sort(TComparer<TJSONValue>.Construct(
      function(const Left, Right: TJSONValue): Integer
      var
        leftObject: TJSONObject;
        rightObject: TJSONObject;
      begin
        // You should do some error checking here and not just cast blindly
        leftObject := TJSONObject(Left);
        rightObject := TJSONObject(Right);
        // Compare here. I am just comparing the ToStrings but you will probably
        // want to compare something else.
        if AOrder = soAscending then
          Result := TComparer<string>.Default.Compare(leftObject.Get(AKeyElement)
            .JsonValue.Value, rightObject.Get(AKeyElement).JsonValue.Value)
        else
          Result := TComparer<string>.Default.Compare(rightObject.Get(AKeyElement)
            .JsonValue.Value, leftObject.Get(AKeyElement).JsonValue.Value);
      end));
    self.SetElements(elementList);
  except
    on E: Exception do
    begin
      // We only free the element list when there is an exception because SetElements
      // takes ownership of the list.
      elementList.Free;
      raise;
    end;
  end;
end;

function FormToJSONObject(const AForm: TForm): TJSONObject;
var
  {$IFNDEF HAS_FMX}
  J: Integer;
  {$ENDIF}
  I: Integer;
  JSONTela, JSONItem: TJSONObject;
  component: TComponent;
begin
  JSONTela := TJSONObject.Create;
  for I := 0 to pred(AForm.ComponentCount) do
  begin
    component := AForm.Components[I];
    if component is TEdit then
      JSONTela.AddPair(TEdit(component).Name, TEdit(component).Text)
    else if component is TComboBox then
      JSONTela.AddPair(TComboBox(component).Name, TComboBox(component).ItemIndex.ToString)
      {$IFDEF HAS_FMX}
    else if component is TComboEdit then
      JSONTela.AddPair(TComboEdit(component).Name, TComboEdit(component)
        .ItemIndex.ToString)
    else if component is TDateEdit then
      JSONTela.AddPair(TDateEdit(component).Name, TDateEdit(component).Text)
    else if component is TSwitch then
      JSONTela.AddPair(TSwitch(component).Name,
      {$IF CompilerVersion < 35}BoolToStr({$ENDIF}
      TSwitch(component).IsChecked
      {$IF CompilerVersion < 35}, true){$ENDIF}
        )
      {$ENDIF}
    else if component is TCheckBox then
      JSONTela.AddPair(TCheckBox(component).Name,
      {$IF CompilerVersion < 35}BoolToStr({$ENDIF}
      TCheckBox(component).{$IFDEF HAS_FMX}IsChecked{$ELSE}Checked{$ENDIF}
      {$IF CompilerVersion < 35}, true){$ENDIF}
        )
      {$IFNDEF HAS_FMX}
    else if component is TLabeledEdit then
      JSONTela.AddPair(TLabeledEdit(component).Name, TLabeledEdit(component).Text)
    else if component is TValueListEditor then
    begin
      JSONItem := TJSONObject.Create;
      for J := 1 to pred(TValueListEditor(component).RowCount) do
        JSONItem.AddPair(TValueListEditor(component).Keys[J], TValueListEditor(component)
          .Cells[1, J]);
      JSONTela.AddPair(TValueListEditor(component).Name,
        TJSONObject.ParseJSONValue(JSONItem.ToJSON));
      JSONItem.Free;
    end
    {$ENDIF}
      ;
  end;
  Result := JSONTela;
end;

procedure LoadFormFromJSON(const AJSON: TJSONObject; AForm: TForm);
var
  {$IFNDEF HAS_FMX}
  J: Integer;
  {$ENDIF}
  I: Integer;
  JSONTela, JSONItem: TJSONObject;
  component: TComponent;
begin
  JSONTela := AJSON;
  try
    for I := 0 to pred(AForm.ComponentCount) do
    begin
      component := AForm.Components[I];
      if JSONTela.getValue(component.Name) <> nil then
        if (component.Name <> EmptyStr) and (component.Tag <> -1) then
          if (component is TEdit) then
            TEdit(component).Text := JSONTela.getValue(TEdit(component).Name).Value
          else if (component is TComboBox) then
            TComboBox(component).ItemIndex := JSONTela.getValue(TComboBox(component).Name)
              .Value.ToInteger
            {$IFDEF HAS_FMX}
          else if (component is TComboEdit) then
            TComboEdit(component).ItemIndex :=
              JSONTela.getValue(TComboEdit(component).Name).Value.ToInteger
          else if (component is TDateEdit) then
            TDateEdit(component).Text :=
              JSONTela.getValue(TDateEdit(component).Name).Value
          else if (component is TSwitch) then
            TSwitch(component).IsChecked := JSONTela.getValue(TSwitch(component).Name)
              .Value.ToBoolean
            {$ENDIF}
          else if (component is TCheckBox) then
            TCheckBox(component).{$IFDEF HAS_FMX}IsChecked{$ELSE}Checked{$ENDIF} :=
              JSONTela.getValue(TCheckBox(component).Name).Value.ToBoolean
            {$IFNDEF HAS_FMX}
          else if component is TLabeledEdit then
            TLabeledEdit(component).Text :=
              JSONTela.getValue(TLabeledEdit(component).Name).Value
          else if (component is TValueListEditor) then
          begin
            JSONItem :=
              TJSONObject(TJSONObject.ParseJSONValue
              (JSONTela.getValue(TValueListEditor(component).Name).ToJSON));
            if JSONItem <> nil then
              for J := 1 to pred(TValueListEditor(component).RowCount) do
                TValueListEditor(component).Cells[1, J] :=
                  JSONItem.getValue(TValueListEditor(component).Keys[J]).Value;
            JSONItem.Free;
          end
          {$ENDIF}
            ;
    end;
  finally
    JSONTela.Free;
  end;
end;

function FormToJSONString(const AForm: TForm): string;
var
  JSON: TJSONObject;
begin
  Result := '';
  try
    JSON := FormToJSONObject(AForm);
    Result := JSON.ToJSON;
  finally
    if assigned(JSON) then
      JSON.Free;
  end;
end;

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
  with TStringStream.Create(self.ToJSON, TEncoding.UTF8) do
    try
      SaveToFile(AFileName);
    finally
      Free;
    end;
end;

function TDS2JHelper.ToJSON: string;
begin
  Result := TDataSetToJSON.DatasetToJSON(self);
end;

function TDS2JHelper.ToJSONArray: TJSONArray;
begin
  Result := TDataSetToJSON.DataSetToJSONArray(self);
end;

function TDS2JHelper.ToJSONObject: TJSONObject;
begin
  Result := TDataSetToJSON.DataSetToJSONObject(self);
end;

end.
