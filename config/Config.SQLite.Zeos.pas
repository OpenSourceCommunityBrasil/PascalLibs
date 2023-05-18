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
  System.JSON, System.SysUtils,
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
  public
    constructor Create;
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

constructor TSQLiteConfig.Create;
begin
  FConn := TZConnection.Create(nil);
  FConn.Protocol := 'sqlite-3';
  {$IFDEF Android}
  FConn.Database := TPath.Combine(TPath.GetDocumentsPath, 'config.db');
  {$ENDIF}
  {$IFDEF MSWINDOWS}
  FConn.Database := ExtractFilePath(ParamStr(0)) + 'config.db';
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
begin
  Result := '';
  try
    with FDataSet do
    begin
      Close;
      SQL.Clear;
      SQL.Add('SELECT CFG_Value');
      SQL.Add('  FROM Config');
      SQL.Add(' WHERE CFG_Key = :CFG_Key');
      ParamByName('CFG_Key').Value := pKey;
      Open;
      Result := Fields.Fields[0].AsString;
      Close;
    end;
  except
    Result := '';
  end;
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
      Result.AddPair(Fields.Fields[0].AsString, Fields.Fields[1].AsString);
      Next;
    end;
    Close;
  end;
end;

procedure TSQLiteConfig.LoadForm(aForm: TForm);
var
  I, J: integer;
  JSONTela: TJSONObject;
begin
  JSONTela := LoadConfig;
  try
    for I := 0 to pred(aForm.ComponentCount) do
      if JSONTela.getValue(TEdit(aForm.Components[I]).Name) <> nil then
        if (aForm.Components[I] is TEdit) then
          TEdit(aForm.Components[I]).Text :=
            JSONTela.getValue(TEdit(aForm.Components[I]).Name).Value
        else if (aForm.Components[I] is TComboBox) then
          TComboBox(aForm.Components[I]).ItemIndex :=
            JSONTela.getValue(TEdit(aForm.Components[I]).Name).Value.ToInteger
          {$IFDEF HAS_FMX}
        else if (aForm.Components[I] is TComboEdit) then
          TComboEdit(aForm.Components[I]).ItemIndex :=
            JSONTela.getValue(TEdit(aForm.Components[I]).Name).Value.ToInteger
        else if (aForm.Components[I] is TDateEdit) then
          TDateEdit(aForm.Components[I]).Text :=
            JSONTela.getValue(TEdit(aForm.Components[I]).Name).Value
        else if (aForm.Components[I] is TSwitch) then
          TSwitch(aForm.Components[I]).IsChecked :=
            JSONTela.getValue(TEdit(aForm.Components[I]).Name).Value.ToBoolean
          {$ENDIF}
        else if (aForm.Components[I] is TCheckBox) then
          TCheckBox(aForm.Components[I]).{$IFDEF HAS_FMX}IsChecked{$ELSE}Checked{$ENDIF} := JSONTela.Get(TEdit(aForm.Components[I]).Name).Value.ToBoolean
          {$IFNDEF HAS_FMX}
        else if aForm.Components[I] is TLabeledEdit then
          TLabeledEdit(aForm.Components[I]).Text :=
            JSONTela.getValue(TLabeledEdit(aForm.Components[I]).Name).Value
        else if aForm.Components[I] is TValueListEditor then
          for J := 1 to pred(TValueListEditor(aForm.Components[I]).RowCount) do
            TValueListEditor(aForm.Components[I]).Cells[1, J] :=
              JSONTela.getValue(TValueListEditor(aForm.Components[I])
              .Keys[J]).Value
            {$ENDIF}
              ;
  finally
    JSONTela.Free;
  end;
end;

procedure TSQLiteConfig.SaveForm(aForm: TForm);
var
  I, J: integer;
  JSONTela: TJSONObject;
begin
  JSONTela := TJSONObject.Create;
  try
    for I := 0 to pred(aForm.ComponentCount) do
      if aForm.Components[I] is TEdit then
        JSONTela.AddPair(TEdit(aForm.Components[I]).Name,
          TEdit(aForm.Components[I]).Text)
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
        JSONTela.AddPair(TSwitch(aForm.Components[I]).Name,
          TSwitch(aForm.Components[I]).IsChecked)
        {$ENDIF}
      else if aForm.Components[I] is TCheckBox then
        JSONTela.AddPair(TCheckBox(aForm.Components[I]).Name,
          TCheckBox(aForm.Components[I]).{$IFDEF HAS_FMX}IsChecked{$ELSE}Checked{$ENDIF})
        {$IFNDEF HAS_FMX}
      else if aForm.Components[I] is TLabeledEdit then
        JSONTela.AddPair(TLabeledEdit(aForm.Components[I]).Name,
          TLabeledEdit(aForm.Components[I]).Text)
      else if aForm.Components[I] is TValueListEditor then
        for J := 1 to pred(TValueListEditor(aForm.Components[I]).RowCount) do
          JSONTela.AddPair(TValueListEditor(aForm.Components[I]).Keys[J],
            TValueListEditor(aForm.Components[I]).Cells[1, J]);
    {$ENDIF}
    ;

    UpdateConfig(JSONTela);
  finally
    JSONTela.Free;
  end;
end;

procedure TSQLiteConfig.UpdateConfig(aJSON: TJSONObject);
var
  JSONVal: TJSONValue;
  I: integer;
begin
  // exemplo entrada
  // {"key1":"value1", "key2":"value2", "key3":"value3", "key4":"value4", "key5":"value5"}
  // aJSON.Pairs[i].JSONString.tostring = "key1",
  // aJSON.Pairs[i].JSONValue.tostring = "value1";
  for I := 0 to aJSON.Count - 1 do
    with FDataSet do
    begin
      Close;
      SQL.Clear;
      SQL.Add('SELECT CFG_Key, CFG_Value');
      SQL.Add('  FROM Config');
      SQL.Add(' WHERE CFG_Key = :CFG_Key');
      ParamByName('CFG_Key').Value := aJSON.Pairs[I].JsonString.ToString.Replace
        ('"', '', [rfReplaceAll]);
      Open;
      Edit;
      Fields.Fields[0].Value := aJSON.Pairs[I].JsonString.ToString.Replace('"',
        '', [rfReplaceAll]);
      Fields.Fields[1].Value := aJSON.Pairs[I].JsonValue.ToString.Replace('"',
        '', [rfReplaceAll]);
      Post;
      if FDataSet.CachedUpdates then
        ApplyUpdates;
      Close;
    end;
end;

procedure TSQLiteConfig.UpdateConfig(aKey, aValue: string);
begin
  with FDataSet do
  begin
    Close;
    SQL.Clear;
    SQL.Add('SELECT CFG_Key, CFG_Value');
    SQL.Add('  FROM Config');
    SQL.Add(' WHERE CFG_Key = :CFG_Key');
    ParamByName('CFG_Key').Value := aKey;
    Open;
    Edit;
    Fields.Fields[0].Value := aKey;
    Fields.Fields[1].Value := aValue;
    Post;
    if FDataSet.CachedUpdates then
      ApplyUpdates;
    Close;
  end;
end;

function TSQLiteConfig.ValidaBanco: boolean;
begin
  Result := False;
  try
    FDataSet.SQL.Text := 'select count(*) from config';
    FDataSet.Open;
    FDataSet.Close;
    Result := true;
  except
    Result := False;
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
      if isEmpty then
      begin
        Close;
        SQL.Clear;
        SQL.Add('CREATE TABLE Config(');
        SQL.Add('  CFG_ID integer primary key');
        SQL.Add(', CFG_Key varchar');
        SQL.Add(', CFG_Value varchar');
        SQL.Add(');');
        ExecSQL;
      end;
    end;
    Result := true;
  except
    Result := False;
  end;
end;

end.
