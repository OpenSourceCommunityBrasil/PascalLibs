// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.0
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
    procedure ClearDatabase;
  end;

implementation

{ TSQLiteConfig }

procedure TSQLiteConfig.ClearDatabase;
begin
  with FDataSet do
  begin
    SQL.Clear;
    SQL.Add('DROP TABLE IF EXISTS Config');  
    ExecSQL;
  end;
  Validate;
end;

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
  component: TComponent;  
begin
  JSONTela := LoadConfig;
  try
    for I := 0 to pred(aForm.ComponentCount) do
    begin
      component := aForm.Components[I];
      if JSONTela.getValue(component.Name) <> nil then
      if (component.Name <> EmptyStr) and (component.Tag <> -1) then
        if (component is TEdit) then
          TEdit(component).Text :=
            JSONTela.getValue(TEdit(component).Name).Value
        else if (component is TComboBox) then
          TComboBox(component).ItemIndex :=
            JSONTela.getValue(TComboBox(component).Name).Value.ToInteger
          {$IFDEF HAS_FMX}
        else if (component is TComboEdit) then
          TComboEdit(component).ItemIndex :=
            JSONTela.getValue(TComboEdit(component).Name).Value.ToInteger
        else if (component is TDateEdit) then
          TDateEdit(component).Text :=
            JSONTela.getValue(TDateEdit(component).Name).Value
        else if (component is TSwitch) then
          TSwitch(component).IsChecked :=
            JSONTela.getValue(TSwitch(component).Name).Value.ToBoolean
          {$ENDIF}
        else if (component is TCheckBox) then
          TCheckBox(component).{$IFDEF HAS_FMX}IsChecked{$ELSE}Checked{$ENDIF} := JSONTela.GetValue(TCheckBox(component).Name).Value.ToBoolean
          {$IFNDEF HAS_FMX}
        else if component is TLabeledEdit then
          TLabeledEdit(aForm.Components[I]).Text :=
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
  component: TComponent;
begin
  JSONTela := TJSONObject.Create;
  try
    for I := 0 to pred(aForm.ComponentCount) do
    begin
      component := aForm.Components[I] 
      if component is TEdit then
        JSONTela.AddPair(TEdit(component).Name, TEdit(component).Text)
      else if component is TComboBox then
        JSONTela.AddPair(TComboBox(component).Name,
          TComboBox(component).ItemIndex)
        {$IFDEF HAS_FMX}
      else if component is TComboEdit then
        JSONTela.AddPair(TComboEdit(component).Name,
          TComboEdit(component).ItemIndex)
      else if component is TDateEdit then
        JSONTela.AddPair(TDateEdit(component).Name,
          TDateEdit(component).Text)
      else if component is TSwitch then
        JSONTela.AddPair(TSwitch(component).Name, TSwitch(component)
          .IsChecked)
        {$ENDIF}
      else if component is TCheckBox then
        JSONTela.AddPair(TCheckBox(component).Name,
          TCheckBox(component).{$IFDEF HAS_FMX}IsChecked{$ELSE}Checked{$ENDIF})
        {$IFNDEF HAS_FMX}
      else if component is TLabeledEdit then
        JSONTela.AddPair(TLabeledEdit(component).Name,
          TLabeledEdit(component).Text)
      else if component is TValueListEditor then
      begin
        JSONItem := TJSONObject.Create;
        for J := 1 to pred(TValueListEditor(component).RowCount) do
          JSONItem.AddPair(TValueListEditor(component).Keys[J],
            TValueListEditor(component).Cells[1, J]);
        JSONTela.AddPair(TValueListEditor(component).Name,
          TJSONObject.ParseJSONValue(JSONItem.ToJSON));
        JSONItem.Free;
      end
      {$ENDIF}
        ;
    end;
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
