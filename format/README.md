Classes para auxiliar a formatação de valores em campos de texto e rótulos para o usuário. Testado no Delphi 10.3.3, 10.4.2 e 11.2, outras versões podem funcionar.

# VCLFormat
Exemplo de uso:
- Formatar um edit para mostrar valor monetário de acordo com o sistema operacional:
```Delphi
uses
  VCLFormat;
  
procedure TForm1.Edit1Change(Sender: TObject);
begin
  Edit1.Formatar(Dinheiro);
end;
```

- Pegar um valor monetário formatado em um campo edit para salvar no banco de dados sem os caracteres especiais:
```Delphi
uses
  VCLFormat;
  
procedure TForm1.Edit1Change(Sender: TObject);
begin
  Edit1.Formatar(Dinheiro);
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  valorpago: Float;
begin
  valorpago := StrToFloatDef(Edit1.Decimal, 0);
end;
```

# FMXFormat
Exemplo de uso:
- Formatar um edit para mostrar valor monetário de acordo com o sistema operacional:
```Delphi
uses
  FMXFormat;
  
procedure TForm1.Edit1Typing(Sender: TObject);
begin
  Edit1.Formatar(Dinheiro);
end;
```

- Pegar um valor monetário formatado em um campo edit para salvar no banco de dados sem os caracteres especiais:
```Delphi
uses
  FMXFormat;
  
procedure TForm1.Edit1Typing(Sender: TObject);
begin
  Edit1.Formatar(Dinheiro);
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  valorpago: Float;
begin
  valorpago := StrToFloatDef(Edit1.Decimal, 0);
end;
```
