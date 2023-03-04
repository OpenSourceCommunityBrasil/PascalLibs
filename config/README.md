# Config
### units de criação de banco de dados de valores de configuração no padrão `chave:valor`

### Exemplo de uso para leitura:
```Delphi
procedure TfConfig.CarregaConfig;
var
  cfg: TSQLiteConfig;
  JSONObj: TJSONObject;
  I, J: Integer;
begin
  cfg := TSQLiteConfig.Create;
  JSONObj := cfg.LoadConfig;
  try
    if JSONObj.Count > 0 then
      with Self do
        for I := 0 to pred(ComponentCount) do
        begin
          if (Components[I] is TLabeledEdit) then
            (Components[I] as TLabeledEdit).Text :=
              JSONObj.GetValue((Components[I] as TLabeledEdit).Name)
              .ToString.Replace('"', '');

          if (Components[I] is TValueListEditor) then
            for J := 1 to pred((Components[I] as TValueListEditor).RowCount) do
              (Components[I] as TValueListEditor).Cells[1, J] :=
                JSONObj.GetValue((Components[I] as TValueListEditor).Keys[J])
                .ToString.Replace('"', '');
        end;
  finally
    JSONObj.Free;
    cfg.Free;
  end;
end;
```

### Exemplo de uso para gravação:
```Delphi
procedure TfConfig.SalvaConfig;
var
  cfg: TSQLiteConfig;
  JSONObj: TJSONObject;
  I, J: Integer;
begin
  cfg := TSQLiteConfig.Create;
  JSONObj := TJSONObject.Create;
  try
    with Self do
      for I := 0 to pred(ComponentCount) do
      begin
        if Components[I] is TLabeledEdit then
          JSONObj.AddPair((Components[I] as TLabeledEdit).Name,
            (Components[I] as TLabeledEdit).Text);

        if (Components[I] is TValueListEditor) then
          for J := 1 to pred((Components[I] as TValueListEditor).RowCount) do
            JSONObj.AddPair((Components[I] as TValueListEditor).Keys[J],
              (Components[I] as TValueListEditor).Cells[1, J]);
      end;
    cfg.UpdateConfig(JSONObj);
  finally
    JSONObj.Free;
    cfg.Free;
  end;
end;
```
