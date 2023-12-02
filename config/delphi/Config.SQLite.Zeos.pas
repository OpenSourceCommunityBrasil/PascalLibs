// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki

unit Config.SQLite.Zeos;

interface

{$IF Declared(FireMonkeyVersion) or Defined(FRAMEWORK_FMX)
or Declared(FMX.Types.TFmxObject) or Defined(LINUX64)}
{$DEFINE HAS_FMX}
{$ENDIF}

uses
  {$IFDEF Android}
  System.IOUtils,
  {$ENDIF}
  System.JSON, System.SysUtils, System.Generics.Collections, Classes,
  Data.DB,
  ZConnection, ZDataSet

  {$IFDEF HAS_FMX}
    , FMX.Forms, FMX.Edit, FMX.ComboEdit, FMX.StdCtrls, FMX.ExtCtrls,
  FMX.Controls, FMX.ListBox, FMX.DateTimeCtrls
  {$ELSE}
    , VCL.Forms, VCL.StdCtrls, VCL.ExtCtrls, VCL.ValEdit
  {$IFEND}
    ;

type
  TSQLiteConfig = class
  private
    FConn: TZConnection;
    FDataSet: TZQuery;
    function Validate: boolean;
    function GetDefaultDir(aFileName: string): string;
	function isJSON(aJSON: string): boolean;
  public
    constructor Create(aFileName: string = 'config.db');
    destructor Destroy; override;
    function getValue(pKey: string): string;
    procedure UpdateConfig(aJSON: TJSONObject); overload;
    procedure UpdateConfig(aKey, aValue: string); overload;
    function LoadConfig: TJSONObject;
    procedure SaveForm(aForm: TForm);
    procedure LoadForm(aForm: TForm);
    function ValidaBanco: boolean;
  end;

implementation

{ TSQLiteConfig }

constructor TSQLiteConfig.Create(aFileName: string = 'config.db');
begin
  FConn := TZConnection.Create(nil);
  FConn.Protocol := 'sqlite-3';
  {$IFDEF Android}
  FConn.Database := TPath.Combine(TPath.GetDocumentsPath, aFileName);
  {$ENDIF}
  {$IFDEF MSWINDOWS}
  FConn.Database := ExtractFilePath(ParamStr(0)) + aFileName;
  {$ENDIF}
  FConn.Properties.Add('LockingMode=normal');

  FDataSet := TZQuery.Create(nil);
  FDataSet.Connection := FConn;

  FConn.LibraryLocation := GetDefaultDir('sqlite3.dll');
  if not Validate then
    raise Exception.Create
      ('sqlite3.dll precisa estar na raiz do projeto ou na pasta /lib');
end;

destructor TSQLiteConfig.Destroy;
begin
  FDataSet.Free;
  FConn.Free;
  inherited;
end;

function TSQLiteConfig.GetDefaultDir(aFileName: string): string;
var
  DefaultDir: string;
begin
  DefaultDir := ExtractFileDir(ParamStr(0));
  if FileExists(DefaultDir + '\lib\' + aFileName) then
    Result := DefaultDir + '\lib\' + aFileName
  else
    Result := DefaultDir + aFileName;
end;

function TSQLiteConfig.getValue(pKey: string): string;
var
  SQL: TStringList;
  Idx: Integer;
  JSON: TJSONObject;
begin
  Result := '';
  Idx := 0;
  if pos('.', pKey) > 0 then
    Idx := pos('.', pKey);

  SQL := TStringList.Create;
  try
    try
      SQL.Add('SELECT CFG_Value');
      SQL.Add('  FROM Config');
      SQL.Add(' WHERE CFG_Key = :CFG_Key');
      if Idx > 0 then
        SQL.Text := SQL.Text.Replace(':CFG_Key', QuotedStr(Copy(pKey, 0, Idx - 1)))
      else
        SQL.Text := SQL.Text.Replace(':CFG_Key', QuotedStr(pKey));

      FDataSet.Close;
      FDataSet.SQL.Text := SQL.Text;
      FDataSet.Open;

      if (Idx > 0) and (not FDataSet.IsEmpty) then
      begin
        JSON := TJSONObject(TJSONObject.ParseJSONValue(FDataSet.Fields.Fields[0]
          .AsString));
        Result := JSON.getValue(Copy(pKey, Idx + 1, length(pKey))).Value;
        JSON.Free;
      end
      else
        Result := FDataSet.Fields.Fields[0].AsString.Replace('"', '');
      FDataSet.Close;
    except
      Result := '';
    end;
  finally
    SQL.Free;
  end;
end;

function TSQLiteConfig.isJSON(aJSON: string): boolean;
begin
  Result := ((pos('{', aJSON) > 0) or (pos('[', aJSON) > 0)) and (pos('"', aJSON) > 0);
end;

function TSQLiteConfig.LoadConfig: TJSONObject;
begin
  Result := TJSONObject.Create;
  with FDataSet do
  begin
    Close;
    SQL.Clear;
    SQL.Add('SELECT CFG_Key, CFG_Value');
    SQL.Add('  FROM Config');
    Open;
    while not Eof do
    begin
      if isJSON(Fields.Fields[1].AsString) then
        Result.AddPair(Fields.Fields[0].AsString, TJSONObject.ParseJSONValue(Fields.Fields[1].AsString))
      else
        Result.AddPair(Fields.Fields[0].AsString, Fields.Fields[1].AsString);
      Next;
    end;
    Close;
  end;
end;

procedure TSQLiteConfig.LoadForm(aForm: TForm);
var
  {$IFNDEF HAS_FMX}
  J: Integer;
  {$ENDIF}
  I: Integer;
  JSONTela, JSONItem: TJSONObject;
begin
  JSONTela := LoadConfig;
  try
    for I := 0 to pred(aForm.ComponentCount) do
      if JSONTela.getValue(aForm.Components[I].Name) <> nil then
        if (aForm.Components[I] is TEdit) then
          TEdit(aForm.Components[I]).Text :=
            JSONTela.getValue(TEdit(aForm.Components[I]).Name).Value
        else if (aForm.Components[I] is TComboBox) then
          TComboBox(aForm.Components[I]).ItemIndex :=
            JSONTela.getValue(TComboBox(aForm.Components[I]).Name).Value.ToInteger
          {$IFDEF HAS_FMX}
        else if (aForm.Components[I] is TComboEdit) then
          TComboEdit(aForm.Components[I]).ItemIndex :=
            JSONTela.getValue(TComboEdit(aForm.Components[I]).Name).Value.ToInteger
        else if (aForm.Components[I] is TDateEdit) then
          TDateEdit(aForm.Components[I]).Text :=
            JSONTela.getValue(TDateEdit(aForm.Components[I]).Name).Value
        else if (aForm.Components[I] is TSwitch) then
          TSwitch(aForm.Components[I]).IsChecked :=
            JSONTela.getValue(TSwitch(aForm.Components[I]).Name).Value.ToBoolean
          {$ENDIF}
        else if (aForm.Components[I] is TCheckBox) then
          TCheckBox(aForm.Components[I]).{$IFDEF HAS_FMX}IsChecked{$ELSE}Checked{$ENDIF} := JSONTela.Get(TCheckBox(aForm.Components[I]).Name).Value.ToBoolean
          {$IFNDEF HAS_FMX}
        else if aForm.Components[I] is TLabeledEdit then
          TLabeledEdit(aForm.Components[I]).Text :=
            JSONTela.getValue(TLabeledEdit(aForm.Components[I]).Name).Value
        else if (aForm.Components[I] is TValueListEditor) then
        begin
          JSONItem :=
            TJSONObject(TJSONObject.ParseJSONValue
            (JSONTela.getValue(TValueListEditor(aForm.Components[I]).Name).ToJSON));
          if JSONItem <> nil then
            for J := 1 to pred(TValueListEditor(aForm.Components[I]).RowCount) do
              TValueListEditor(aForm.Components[I]).Cells[1, J] :=
                JSONItem.getValue(TValueListEditor(aForm.Components[I]).Keys[J]).Value;
          JSONItem.Free;
        end
        {$ENDIF}
          ;
  finally
    JSONTela.Free;
  end;
end;

procedure TSQLiteConfig.SaveForm(aForm: TForm);
var
  {$IFNDEF HAS_FMX}
  J: Integer;
  {$ENDIF}
  I: Integer;
  JSONTela, JSONItem: TJSONObject;
begin
  JSONTela := TJSONObject.Create;
  try
    for I := 0 to pred(aForm.ComponentCount) do
      if aForm.Components[I] is TEdit then
        JSONTela.AddPair(TEdit(aForm.Components[I]).Name, TEdit(aForm.Components[I]).Text)
      else if aForm.Components[I] is TComboBox then
        JSONTela.AddPair(TComboBox(aForm.Components[I]).Name,
          TComboBox(aForm.Components[I]).ItemIndex)
        {$IFDEF HAS_FMX}
      else if aForm.Components[I] is TComboEdit then
        JSONTela.AddPair(TComboEdit(aForm.Components[I]).Name,
          TComboEdit(aForm.Components[I]).ItemIndex)
      else if aForm.Components[I] is TDateEdit then
        JSONTela.AddPair(TDateEdit(aForm.Components[I]).Name,
          TDateEdit(aForm.Components[I]).Text)
      else if aForm.Components[I] is TSwitch then
        JSONTela.AddPair(TSwitch(aForm.Components[I]).Name, TSwitch(aForm.Components[I])
          .IsChecked)
        {$ENDIF}
      else if aForm.Components[I] is TCheckBox then
        JSONTela.AddPair(TCheckBox(aForm.Components[I]).Name,
          TCheckBox(aForm.Components[I]).{$IFDEF HAS_FMX}IsChecked{$ELSE}Checked{$ENDIF})
        {$IFNDEF HAS_FMX}
      else if aForm.Components[I] is TLabeledEdit then
        JSONTela.AddPair(TLabeledEdit(aForm.Components[I]).Name,
          TLabeledEdit(aForm.Components[I]).Text)
      else if aForm.Components[I] is TValueListEditor then
      begin
        JSONItem := TJSONObject.Create;
        for J := 1 to pred(TValueListEditor(aForm.Components[I]).RowCount) do
          JSONItem.AddPair(TValueListEditor(aForm.Components[I]).Keys[J],
            TValueListEditor(aForm.Components[I]).Cells[1, J]);
        JSONTela.AddPair(TValueListEditor(aForm.Components[I]).Name,
          TJSONObject.ParseJSONValue(JSONItem.ToJSON));
        JSONItem.Free;
      end
      {$ENDIF}
        ;

    UpdateConfig(JSONTela);
  finally
    JSONTela.Free;
  end;
end;

procedure TSQLiteConfig.UpdateConfig(aJSON: TJSONObject);
var
  I: Integer;
begin
  // exemplo entrada
  // {"key1":"value1", "key2":"value2", "key3":"value3", "key4":"value4", "key5":"value5"}
  // aJSON.Pairs[i].JSONString.Value = "key1",
  // aJSON.Pairs[i].JSONValue.Value = "value1";

  for I := 0 to pred(aJSON.Count) do
  begin
    if aJSON.Pairs[I].JsonValue is TJSONObject then
      UpdateConfig(aJSON.Pairs[I].JsonString.Value, aJSON.Pairs[I].JsonValue.ToJSON)
    else
      UpdateConfig(aJSON.Pairs[I].JsonString.Value, aJSON.Pairs[I].JsonValue.Value);
  end;
end;

procedure TSQLiteConfig.UpdateConfig(aKey, aValue: string);
begin
  with FDataSet do
  begin
    Close;
    SQL.Clear;
    SQL.Add('INSERT INTO Config (CFG_KEY, CFG_VALUE) ');
    SQL.Add('VALUES (' + QuotedStr(aKey) + ', ' + QuotedStr(aValue) + ') ');
    SQL.Add('ON CONFLICT (CFG_KEY) DO UPDATE ');
    SQL.Add('SET CFG_VALUE = excluded.CFG_VALUE;');
    ExecSQL;
    Close;
  end;
end;

function TSQLiteConfig.ValidaBanco: boolean;
begin
  Result := False;
  try
    try
      FDataSet.SQL.Text := 'PRAGMA table_info("Config")';
      FDataSet.ExecSQL;
      Result := True;
    except
      Result := False;
    end;
  finally
    FDataSet.Close;
  end;
end;

function TSQLiteConfig.Validate: boolean;
begin
  Result := False;
  try
    with FDataSet do
    begin
      Close;
      SQL.Text := 'PRAGMA table_info("Config")';
      Open;
      if IsEmpty then
      begin
        Close;
        SQL.Clear;
        SQL.Add('CREATE TABLE Config(');
        SQL.Add('  CFG_Key varchar not null primary key');
        SQL.Add(', CFG_Value varchar');
        SQL.Add(');');
        ExecSQL;
      end;
    end;
    Result := True;
  except
    Result := False;
  end;
end;

end.
