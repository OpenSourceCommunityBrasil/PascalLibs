// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.2
unit Config.SQLite.FireDAC;

interface

// Comment this directive below to make this unit handle VCL controls instead of FMX.
{$DEFINE HAS_FMX}

uses
  System.JSON, System.SysUtils, System.Generics.Collections, System.Classes,
  Data.DB,
  {$IF CompilerVersion > 33.0}
  FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.Intf, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Stan.Param, FireDAC.Stan.Def, FireDAC.DApt, FireDAC.Stan.Async,
  {$IFEND}
  {$IFDEF Android}
  System.IOUtils,
  {$ENDIF}
  FireDAC.Comp.Client
  {$IFNDEF CONSOLE}
    {$IFDEF HAS_FMX}
      , FMX.Forms, FMX.Edit, FMX.ComboEdit, FMX.StdCtrls, FMX.ExtCtrls,
    FMX.Controls, FMX.ListBox, FMX.DateTimeCtrls
    {$ELSE}
      , VCL.Forms, VCL.StdCtrls, VCL.ExtCtrls, VCL.ValEdit
    {$ENDIF}
  {$ENDIF}
    ;

type
  TSQLiteConfig = class
  private
    FConn: TFDConnection;
    FDataSet: TFDQuery;
    FDriver: TFDPhysSQLiteDriverLink;
    function Validate: boolean;
    function GetDefaultDir(aFileName: string): string;
    function isJSON(aJSON: string): boolean;
  public
    constructor Create(aFileName: string = 'config.db');
    destructor Destroy; override;
    procedure ClearDatabase;
    function getValue(pKey: string): string; overload;
      deprecated 'use getValue(string, string) instead';
    function getValue(pKey: string; ADefault: string): string; overload;
    function getValue(pKey: string; ADefault: integer): integer; overload;
    function getValue(pKey: string; ADefault: boolean): boolean; overload;
    function getValue(pKey: string; ADefault: double): double; overload;
    function isEmpty: boolean;
    function LoadConfig: TJSONObject;
    {$IFNDEF CONSOLE}
    procedure LoadForm(aForm: TForm);
    procedure SaveForm(aForm: TForm);
    {$ENDIF}
    procedure UpdateConfig(aJSON: TJSONObject); overload;
    procedure UpdateConfig(aKey, aValue: string); overload;
    function ValidaBanco: boolean;
  end;

var
  aCFG: TSQLiteConfig;

implementation

{ TSQLiteConfig }

procedure TSQLiteConfig.ClearDatabase;
begin
  FDataSet.ExecSQL('DROP TABLE IF EXISTS Config');
  Validate;
end;

constructor TSQLiteConfig.Create(aFileName: string = 'config.db');
begin
  {$IFDEF MSWINDOWS} // android já possui a dll instalada
  FDriver := TFDPhysSQLiteDriverLink.Create(nil);
  FDriver.DriverID := 'SQLite';
  FDriver.VendorLib := GetDefaultDir('sqlite3.dll');
  {$ENDIF}
  FConn := TFDConnection.Create(nil);
  FConn.Params.Clear;
  FConn.Params.Add('DriverID=SQLite');
  {$IFDEF Android}
  FConn.Params.Add('Database=' + TPath.Combine(TPath.GetDocumentsPath, aFileName));
  {$ENDIF}
  {$IFDEF MSWINDOWS}
  FConn.Params.Add('Database=' + ExtractFilePath(ParamStr(0)) + aFileName);
  {$ENDIF}
  FConn.Params.Add('LockingMode=normal');
  FDataSet := TFDQuery.Create(nil);
  FDataSet.Connection := FConn;
  FDataSet.ResourceOptions.SilentMode := true;
  if not Validate then
    raise Exception.Create
      ('sqlite3.dll precisa estar na raiz do projeto ou na pasta /lib');
end;

destructor TSQLiteConfig.Destroy;
begin
  FDataSet.Free;
  FConn.Free;
  {$IFDEF MSWINDOWS}
  FDriver.Free;
  {$ENDIF}
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

function TSQLiteConfig.getValue(pKey: string; ADefault: integer): integer;
begin
  Result := StrToIntDef(getValue(pKey), ADefault);
end;

function TSQLiteConfig.getValue(pKey: string; ADefault: boolean): boolean;
begin
  Result := StrToBoolDef(getValue(pKey), ADefault);
end;

function TSQLiteConfig.getValue(pKey: string; ADefault: double): double;
begin
  Result := StrToFloatDef(getValue(pKey), ADefault);
end;

function TSQLiteConfig.getValue(pKey, ADefault: string): string;
var
  Idx: integer;
  JSON: TJSONObject;
begin
  Result := ADefault;
  Idx := pos('.', pKey);

  try
    FDataSet.Close;
    FDataSet.SQL.Clear;
    FDataSet.SQL.Add('SELECT CFG_Value');
    FDataSet.SQL.Add('  FROM Config');
    FDataSet.SQL.Add(' WHERE CFG_Key = :CFG_Key');
    if Idx > 0 then
      FDataSet.ParamByName('CFG_Key').AsString := Copy(pKey, 0, Idx - 1)
    else
      FDataSet.ParamByName('CFG_Key').AsString := pKey;
    FDataSet.Open;
    if (Idx > 0) and (not FDataSet.isEmpty) then
    begin
      JSON := TJSONObject(TJSONObject.ParseJSONValue(FDataSet.Fields.Fields[0].AsString));
      Result := JSON.getValue(Copy(pKey, Idx + 1, length(pKey))).Value;
      JSON.Free;
    end
    else
      Result := FDataSet.Fields.Fields[0].AsString.Replace('"', '');
    FDataSet.Close;
  except
    Result := ADefault;
  end;
end;

function TSQLiteConfig.getValue(pKey: string): string;
begin
  Result := getValue(pKey, '');
end;

function TSQLiteConfig.isEmpty: boolean;
begin
  with LoadConfig do
  begin
    Result := ToJSON = '{}';
    Free;
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
    SQL.Add(' FROM Config');
    Open;
    while not Eof do
    begin
      if isJSON(Fields.Fields[1].AsString) then
        Result.AddPair(Fields.Fields[0].AsString,
          TJSONObject.ParseJSONValue(Fields.Fields[1].AsString))
      else
        Result.AddPair(Fields.Fields[0].AsString, Fields.Fields[1].AsString);
      Next;
    end;
    Close;
  end;
end;

{$IFNDEF CONSOLE}
procedure TSQLiteConfig.LoadForm(aForm: TForm);
var
  {$IFNDEF HAS_FMX}
  J: integer;
  {$ENDIF}
  I: integer;
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

procedure TSQLiteConfig.SaveForm(aForm: TForm);
var
  {$IFNDEF HAS_FMX}
  J: integer;
  {$ENDIF}
  I: integer;
  JSONTela, JSONItem: TJSONObject;
  component: TComponent;
begin
  JSONTela := TJSONObject.Create;
  try
    for I := 0 to pred(aForm.ComponentCount) do
    begin
      component := aForm.Components[I];
      if component is TEdit then
        JSONTela.AddPair(TEdit(component).Name, TEdit(component).Text)
      else if component is TComboBox then
        JSONTela.AddPair(TComboBox(component).Name,
          TComboBox(component).ItemIndex.ToString)
        {$IFDEF HAS_FMX}
      else if component is TComboEdit then
        JSONTela.AddPair(TComboEdit(component).Name,
          TComboEdit(component).ItemIndex.ToString)
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
{$ENDIF}
procedure TSQLiteConfig.UpdateConfig(aJSON: TJSONObject);
var
  I: integer;
begin
  // exemplo entrada
  // {"key1":"value1", "key2":"value2", "key3":"value3", "key4":"value4", "key5":"value5"}
  // aJSON.Pairs[i].JSONString.tostring = "key1",
  // aJSON.Pairs[i].JSONValue.tostring = "value1";
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
    SQL.Add(Format('VALUES (%s, %s)', [QuotedStr(aKey), QuotedStr(aValue)]));
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
      Result := true;
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
      Open('PRAGMA table_info(Config)');
      if isEmpty then
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
    Result := true;
  except
    Result := False;
  end;
end;

end.
