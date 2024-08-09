// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.0
unit Config.SQLite.SQLdb;

{$mode ObjFPC}{$H+}

interface

uses
  fpJSON, SysUtils, Classes, DB, Forms, StdCtrls, ExtCtrls, ValEdit,
  SQLDB, SQLite3Conn, SQLDBLib;

type

  { TSQLiteConfig }

  TSQLiteConfig = class
  private
    FConn: TSQLConnector;
    FDataSet: TSQLQuery;
    FDriver: TSQLDBLibraryLoader;
    FTransaction: TSQLTransaction;
    function Validate: boolean;
    function GetDefaultDir(aFileName: string): string;
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

constructor TSQLiteConfig.Create(aFileName: string);
begin
  FConn := TSQLConnector.Create(nil);
  FConn.Params.Add('LockingMode=normal');
  FConn.ConnectorType := 'SQLite3';
  FConn.DatabaseName := ExtractFilePath(ParamStr(0)) + aFileName;

  FTransaction := TSQLTransaction.Create(nil);
  FTransaction.DataBase := FConn;

  FDriver := TSQLDBLibraryLoader.Create(nil);
  FDriver.ConnectionType := 'SQLite3';
  FDriver.LibraryName := GetDefaultDir('sqlite3.dll');
  FDriver.Enabled := true;

  FDataSet := TSQLQuery.Create(nil);
  FDataSet.DataBase := FConn;

  if not Validate then
    raise Exception.Create(
      'sqlite3.dll precisa estar na raiz do projeto ou na pasta /lib');
end;

destructor TSQLiteConfig.Destroy;
begin
  FDataSet.Free;
  FTransaction.Free;
  FDriver.Free;
  FConn.Free;
  inherited;
end;

function TSQLiteConfig.GetDefaultDir(aFileName: string): string;
var
  DefaultDir, temp: string;
begin
  DefaultDir := ExtractFileDir(ParamStr(0));
  temp := DefaultDir + '\lib\' + aFileName;
  if FileExists(temp) then
    Result := DefaultDir + '\lib\' + aFileName
  else
    Result := DefaultDir + '\' + aFileName;
end;

function TSQLiteConfig.getValue(pKey: string): string;
var
  SQL: TStringList;
  Idx: integer;
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
        SQL.Text := SQL.Text.Replace(':CFG_Key',
          QuotedStr(Copy(pKey, 0, Idx - 1)))
      else
        SQL.Text := SQL.Text.Replace(':CFG_Key', QuotedStr(pKey));

      FDataSet.Close;
      FDataSet.SQL.Text := SQL.Text;
      FDataSet.Open;

      if (Idx > 0) and (not FDataSet.IsEmpty) then
      begin
        JSON := TJSONObject.Create;
        try
          JSON := TJSONObject(GetJSON(FDataSet.Fields.Fields[0].AsString));
          Result := JSON.Get(Copy(pKey, Idx + 1, length(pKey)), '');
        finally
          JSON.Free;
        end;
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
    while not EOF do
    begin
      Result.Add(Fields.Fields[0].AsString, Fields.Fields[1].AsString);
      Next;
    end;
    Close;
  end;
end;

procedure TSQLiteConfig.LoadForm(aForm: TForm);
var
  I, J: integer;
  JSONTela, JSONItem: TJSONObject;
  Component: TComponent;
begin
  JSONTela := LoadConfig;
  try
    for I := 0 to pred(aForm.ComponentCount) do
    begin
      Component := aForm.Components[I];
      if JSONTela.Get(Component.Name, '') <> '' then
        if Component is TEdit then
          TEdit(Component).Text := JSONTela.Get(Component.Name, '')
        else if Component is TComboBox then
          TComboBox(Component).ItemIndex := JSONTela.Get(Component.Name, 0)
        else if Component is TCheckBox then
          TCheckBox(Component).Checked := JSONTela.Get(Component.Name, False)
        else if Component is TLabeledEdit then
          TLabeledEdit(Component).Text := JSONTela.Get(Component.Name, '')
        else if Component is TValueListEditor then
        begin
          JSONItem := TJSONObject(
            GetJSON(JSONTela.Get(TValueListEditor(Component).Name, '')));
          if JSONItem <> nil then
            for J := 1 to pred(TValueListEditor(Component).RowCount) do
              TValueListEditor(Component).Cells[1, J] :=
                JSONItem.Get(TValueListEditor(Component).Keys[J], '');
          JSONItem.Free;
        end;
    end;
  finally
    JSONTela.Free;
  end;
end;

procedure TSQLiteConfig.SaveForm(aForm: TForm);
var
  I, J: integer;
  JSONTela, JSONItem: TJSONObject;
  component: TComponent;
begin
  JSONTela := TJSONObject.Create;
  try
    for I := 0 to pred(aForm.ComponentCount) do
    begin
      Component := aForm.Components[I];
      if component.InheritsFrom(TEdit) then
        JSONTela.Add(component.Name, TEdit(component).Text)
      else if component.InheritsFrom(TComboBox) then
        JSONTela.Add(component.Name, TComboBox(component).ItemIndex)
      else if component.InheritsFrom(TCheckBox) then
        JSONTela.Add(component.Name, TCheckBox(component).Checked)
      else if component.InheritsFrom(TLabeledEdit) then
        JSONTela.Add(component.Name, TLabeledEdit(component).Text)
      else if component.InheritsFrom(TValueListEditor) then
      begin
        JSONItem := TJSONObject.Create;
        for J := 1 to pred(TValueListEditor(component).RowCount) do
          JSONItem.Add(TValueListEditor(component).Keys[J],
            TValueListEditor(component).Cells[1, J]);
        JSONTela.Add(TValueListEditor(component).Name, GetJSON(JSONItem.AsJSON));
        JSONItem.Free;
      end;
    end;
    UpdateConfig(JSONTela);
  finally
    JSONTela.Free;
  end;
end;

procedure TSQLiteConfig.UpdateConfig(aJSON: TJSONObject);
var
  I: integer;
begin
  // exemplo entrada
  // {"key1":"value1", "key2":"value2", "key3":"value3", "key4":"value4", "key5":"value5"}
  // aJSON.Pairs[i].JSONString.Value = "key1",
  // aJSON.Pairs[i].JSONValue.Value = "value1";
  for I := 0 to pred(aJSON.Count) do
  begin
    if aJSON.Items[I] is TJSONObject then
      UpdateConfig(aJSON.Names[I], aJSON.Items[I].AsJSON)
    else
      UpdateConfig(aJSON.Names[I], aJSON.Items[I].Value);
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
