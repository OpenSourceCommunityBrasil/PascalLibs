/// //////////////////////////////////////////////////////////////////////////
{
  Unit Format
  Criação: 99 Coders (Heber Stein Mazutti - heber@99coders.com.br)
  Adaptação: Mobius One
  Versão: 1.7
}
/// //////////////////////////////////////////////////////////////////////////

unit uVCLFormat;

interface

uses
  VCL.StdCtrls,
  System.Classes, System.MaskUtils, System.DateUtils, System.Math,
  System.SysUtils, System.SysConst;

type
  TFormato = (CNPJ, CPF, InscricaoEstadual, CNPJorCPF, Telefone, Personalizado,
    Valor, Dinheiro, CEP, &Date, Peso, hhmm, Hora, CFOP, CEST, NCM, Porcentagem,
    VeiculoT, VeiculoM);

  // estados da federação 0..26 = 27 ok
  // TODO: acrescentar código IBGE como índice padrão das siglas para facilidade de acesso
  TUF = (AC, AL, AM, AP, BA, CE, DF, ES, GO, MA, MG, MT, MS, PA, PB, PE, PI, PR,
    RJ, RN, RO, RR, RS, SC, SE, SP, &TO, Null);

  TFormatHelper = class
  private
    function Mask(Mascara, aStr: string): string;
    function FormataData(aStr: string): string;
    function FormataDinheiro(aStr: string; aPrecisao: integer = 2): string;
    function FormataIE(aCod: string; UF: TUF): string;
    function FormataHora(aStr: string): string;
    function FormataHoraCurta(aStr: string): string;
    function FormataPeso(aStr: string): string;
    function FormataValor(aStr: string): string;
  public
    function AlfaNumerico(aStr: string): string;
    function Decimal(aStr: string): string; overload;
    function Decimal(aStr: string; aPrecisao: integer): Double; overload;
    function Formatar(Formato: TFormato; Texto: string; Extra: string = '')
      : string; overload;
    function Formatar(Formato: TFormato; Texto: string; UF: TUF)
      : string; overload;
    function Inteiro(aStr: string): string;
    function SomenteNumero(aStr: string): string;
  end;

  TEditHelper = class helper for TEdit
  public
    function AlfaNumerico: string;
    function Decimal: string;
    procedure Formatar(aFormato: TFormato; Extra: string = ''); overload;
    procedure Formatar(aFormato: TFormato; UF: TUF); overload;
    function Inteiro: string;
    function SomenteNumero: string;
  end;

  TLabelHelper = class helper for TLabel
  public
    function AlfaNumerico: string;
    function Decimal: string;
    procedure Formatar(aFormato: TFormato; Extra: string = ''); overload;
    procedure Formatar(aFormato: TFormato; UF: TUF); overload;
    function Inteiro: string;
    function SomenteNumero: string;
  end;

var
  Formato: TFormatHelper;

implementation

{ TFormatHelper }

/// <summary>
/// Devolve letras e números bem como caracteres acentuados
/// </summary>
function TFormatHelper.AlfaNumerico(aStr: string): string;
var
  x: integer;
begin
  Result := '';
  for x := 0 to pred(aStr.Length) do
    if (aStr.Chars[x] In ['0' .. '9', 'a' .. 'z', 'A' .. 'Z', 'ã', 'á', 'à',
      'â', 'é', 'ê', 'í', 'ó', 'ô', 'õ', 'ú', 'ç', 'Ã', 'Á', 'À', 'Â', 'É', 'Ê',
      'Í', 'Ó', 'Õ', 'Ô', 'Ú', 'Ç', ' ']) then
      Result := Result + aStr.Chars[x];
end;

/// <summary>
/// Devolve somente números mantendo a formatação com separador de milhar e decimais, removendo os demais caracteres
/// </summary>
function TFormatHelper.Decimal(aStr: string): string;
var
  x: integer;
begin
  Result := '';
  for x := 0 to pred(aStr.Length) do
    if (aStr.Chars[x] In ['0' .. '9', ',', '-']) then
      Result := Result + aStr.Chars[x];
end;

/// <summary>
/// Devolve somente números mantendo a formatação com separador de milhar e decimais, removendo os demais caracteres
/// Precisão de decimais ajustável pelo parâmetro aPrecisão. Valor padrão: 2
/// </summary>
function TFormatHelper.Decimal(aStr: string; aPrecisao: integer): Double;
var
  x: integer;
  Valor: string;
begin
  if aPrecisao < 0 then
    aPrecisao := 2;

  try
    Valor := '';
    for x := 0 to pred(aStr.Length) do
      if (aStr.Chars[x] In ['0' .. '9', ',', '-']) then
        Valor := Valor + aStr.Chars[x];

    Result := Format('%.' + aPrecisao.ToString + 'f', [StrToFloatDef(Valor, 0)]
      ).ToDouble;
  except
    Result := Format('%.' + aPrecisao.ToString + 'f', [0]).ToDouble;
  end;
end;

/// <summary>
/// Formata o texto para datas no formato dia(2)/mês(2)/ano(4)
/// Converte data em UNIX para o padrão dd/mm/yyyy
/// </summary>
function TFormatHelper.FormataData(aStr: string): string;
begin
  // -24871190400
  // 2236291200
  // 10/10/2000 = 10102000
  if not aStr.IsEmpty then
    if aStr.Length > 8 then
    begin
      try
        Result := FormatDateTime('dd/mm/yyyy', UnixToDateTime(aStr.ToInt64));
      except
        Result := '';
      end;
    end
    else
    begin
      aStr := Copy(aStr, 1, 8);

      if Length(aStr) < 8 then
        Result := Mask('##/##/####', aStr)
      else
        try
          aStr := Mask('##/##/####', aStr);
          strtodate(aStr);
          Result := aStr;
        except
          Result := '';
        end;
    end;
end;

/// <summary>
/// Formata o texto para Dinheiro com precisão de decimais
/// </summary>
function TFormatHelper.FormataDinheiro(aStr: string;
  aPrecisao: integer): string;
begin
  try
    Result := Format('%.' + aPrecisao.ToString + 'm',
      [StrToFloatDef(Inteiro(aStr), 0) / Power(10, aPrecisao)]);
  except
    Result := Format('%.2m', [0]);
  end;
end;

/// <summary>
/// Formata o texto para hora com horas e minutos
/// </summary>
function TFormatHelper.FormataHoraCurta(aStr: string): string;
begin
  try
    if (aStr.IsEmpty) or
      ((aStr.Length > 1) and (strtoint(Copy(aStr, 0, 2)) > 23)) or
      ((aStr.Length > 3) and (strtoint(Copy(aStr, 3, 2)) > 59)) then
      Result := ''
    else
      Result := Mask('##:##', aStr);
  except
    Result := '';
  end;
end;

/// <summary>
/// Formata o texto para hora com horas, minutos e segundos
/// </summary>
function TFormatHelper.FormataHora(aStr: string): string;
begin
  try
    if (aStr.IsEmpty) or
      ((aStr.Length > 1) and (strtoint(Copy(aStr, 0, 2)) > 23)) or
      ((aStr.Length > 3) and (strtoint(Copy(aStr, 3, 2)) > 59)) or
      ((aStr.Length > 5) and (strtoint(Copy(aStr, 5, 2)) > 59)) then
      Result := ''
    else
      Result := Mask('##:##:##', aStr);
  except
    Result := '';
  end;
end;

/// <summary>
/// Formata o texto para inscrição estadual baseado no valor de 'UF'
/// </summary>
function TFormatHelper.FormataIE(aCod: string; UF: TUF): string;
var
  Mascara: string;
begin
  Mascara := '';
  case UF of
    AC:
      Mascara := '##.###.###/###-##';
    AL:
      Mascara := '#########';
    AM:
      Mascara := '##.###.###-#';
    AP:
      Mascara := '#########';
    BA:
      Mascara := '######-##';
    CE:
      Mascara := '########-#';
    DF:
      Mascara := '###########-##';
    ES:
      Mascara := '#########';
    GO:
      Mascara := '##.###.###-#';
    MA:
      Mascara := '#########';
    MG:
      Mascara := '###.###.###/####';
    MT:
      Mascara := '##########-#';
    MS:
      Mascara := '#########';
    PA:
      Mascara := '##-######-#';
    PB:
      Mascara := '########-#';
    PE:
      Mascara := '##.#.###.#######-#';
    PI:
      Mascara := '#########';
    PR:
      Mascara := '########-##';
    RJ:
      Mascara := '##.###.##-#';
    RN:
      Mascara := '##.###.###-#';
    RO:
      Mascara := '###.#####-#';
    RR:
      Mascara := '########-#';
    RS:
      Mascara := '###/#######';
    SC:
      Mascara := '###.###.###';
    SE:
      Mascara := '#########-#';
    SP:
      Mascara := '###.###.###.###';
    &TO:
      Mascara := '###########';
  end;
  Result := Mask(Mascara, aCod);
end;

/// <summary>
/// Formata o texto em um número com 3 casas decimais
/// </summary>
function TFormatHelper.FormataPeso(aStr: string): string;
begin
  try
    Result := Format('%.3f', [SomenteNumero(aStr).ToInteger / 1000]);
    // FormatFloat('#,##0.000', StrToFloat(aStr) / 1000);
  except
    Result := Format('%.3f', [0]);
  end;
end;

function TFormatHelper.Formatar(Formato: TFormato; Texto: string;
  UF: TUF): string;
begin
  Result := FormataIE(SomenteNumero(Texto), UF);
end;

/// <summary>
/// Formata o valor do 'Texto' baseado no tipo de 'Formato' definido.
/// 'Extra' serve para usar uma máscara própria quando utilizar o formato 'TFormato.Personalizado'
/// 'UF' se tiver valor, formata o texto na inscrição estadual referente àquele estado
/// </summary>
function TFormatHelper.Formatar(Formato: TFormato;
  Texto, Extra: string): string;
begin
  case Formato of
    CNPJ:
      Texto := Mask('##.###.###/####-##', SomenteNumero(Texto));

    CPF:
      Texto := Mask('###.###.###-##', SomenteNumero(Texto));

    CNPJorCPF:
      if Length(SomenteNumero(Texto)) <= 11 then
        Texto := Mask('###.###.###-##', SomenteNumero(Texto))
      else
        Texto := Mask('##.###.###/####-##', SomenteNumero(Texto));

    Telefone:
      if Length(SomenteNumero(Texto)) <= 10 then
        Texto := Mask('(##) ####-####', SomenteNumero(Texto))
      else
        Texto := Mask('(##) #####-####', SomenteNumero(Texto));

    Personalizado:
      Texto := Mask(Extra, SomenteNumero(Texto));

    Valor:
      Texto := FormataValor(Texto);

    Dinheiro:
      if Extra <> '' then
        Texto := FormataDinheiro(Texto, Extra.ToInteger)
      else
        Texto := FormataDinheiro(Texto);

    CEP:
      Texto := Mask('##.###-###', SomenteNumero(Texto));

    &Date:
      Texto := FormataData(SomenteNumero(Texto));

    Peso:
      Texto := FormataPeso(SomenteNumero(Texto));

    CFOP:
      Texto := Mask('#.###', SomenteNumero(Texto));

    CEST:
      Texto := Mask('##.###.##', SomenteNumero(Texto));

    NCM:
      Texto := Mask('####.##.##', SomenteNumero(Texto));

    hhmm:
      Texto := FormataHoraCurta(SomenteNumero(Texto));

    Hora:
      Texto := FormataHora(SomenteNumero(Texto));

    Porcentagem:
      Texto := Format('%.2f %s', [Decimal(Texto, 2), '%']);

    VeiculoT:
      Texto := Mask('LLL-9999', AlfaNumerico(Texto));

    VeiculoM:
      Texto := Mask('#######', AlfaNumerico(Texto));
  end;

  Result := Texto;
end;

/// <summary>
/// Retorna valor formatado com 2 casas decimais
/// </summary>
function TFormatHelper.FormataValor(aStr: string): string;
begin
  try
    Result := Format('%.2f', [StrToFloatDef(SomenteNumero(aStr), 0) / 100]);
    // Result := FormatFloat('#,##0.00', Decimal(aStr));
  except
    Result := Format('%.2f', [0]);
  end;
end;

/// <summary>
/// Retorna valor formatado como inteiro positivo ou negativo
/// </summary>
function TFormatHelper.Inteiro(aStr: string): string;
var
  x: integer;
begin
  Result := '';
  for x := 0 to Length(aStr) - 1 do
    if (aStr.Chars[x] In ['0' .. '9', '-']) then
      Result := Result + aStr.Chars[x];
end;

/// <summary>
/// Define uma máscara para ser utilizada para a formatação. Aceita os seguintes valores:
/// #: para qualquer caractere
/// L: somente letras e vai devolver o texto em maiúsculas
/// l: somente letras e vai devolver o texto em minúsculas
/// 9: somente número
/// </summary>
function TFormatHelper.Mask(Mascara, aStr: string): string;
var
  x, p: integer;
begin
  p := 0;
  Result := '';

  if not aStr.IsEmpty then
    for x := 0 to Length(Mascara) - 1 do
    begin
      if Mascara.Chars[x] = '#' then
      begin
        Result := Result + aStr.Chars[p];
        inc(p);
      end
      else if (Mascara.Chars[x] = 'L') and
        (aStr.Chars[p] in ['a' .. 'z', 'A' .. 'Z']) then
      begin
        Result := Result + UpperCase(aStr.Chars[p]);
        inc(p);
      end
      else if (Mascara.Chars[x] = 'l') and
        (aStr.Chars[p] in ['a' .. 'z', 'A' .. 'Z']) then
      begin
        Result := Result + LowerCase(aStr.Chars[p]);
        inc(p);
      end
      else if (Mascara.Chars[x] = '9') and (aStr.Chars[p] in ['0' .. '9']) then
      begin
        Result := Result + aStr.Chars[p];
        inc(p);
      end
      else if not(Mascara.Chars[x] in ['#', 'L', 'l', '9']) then
        Result := Result + Mascara.Chars[x];

      if p = Length(aStr) then
        break;
    end;
end;

/// <summary>
/// Devolve somente os números contidos no texto
/// </summary>
function TFormatHelper.SomenteNumero(aStr: string): string;
var
  x: integer;
begin
  Result := '';
  for x := 0 to Length(aStr) - 1 do
    if (aStr.Chars[x] In ['0' .. '9']) then
      Result := Result + aStr.Chars[x];
end;

{ TEditHelper }

function TEditHelper.AlfaNumerico: string;
begin
  Result := Formato.AlfaNumerico(Self.Text);
  Self.SelStart := Length(Self.Text);
end;

function TEditHelper.Decimal: string;
begin
  Result := Formato.Decimal(Self.Text, 2).ToString;
  Self.SelStart := Length(Self.Text);
end;

procedure TEditHelper.Formatar(aFormato: TFormato; UF: TUF);
begin
  Self.Text := Formato.Formatar(aFormato, Self.Text, UF);
  Self.SelStart := Length(Self.Text);
end;

function TEditHelper.Inteiro: string;
begin
  Result := Formato.Inteiro(Self.Text);
  Self.SelStart := Length(Self.Text);
end;

procedure TEditHelper.Formatar(aFormato: TFormato; Extra: string);
begin
  Self.Text := Formato.Formatar(aFormato, Self.Text, Extra);
  Self.SelStart := Length(Self.Text);
end;

function TEditHelper.SomenteNumero: string;
begin
  Result := Formato.SomenteNumero(Self.Text);
  Self.SelStart := Length(Self.Text);
end;

{ TLabelHelper }

function TLabelHelper.AlfaNumerico: string;
begin
  Result := Formato.AlfaNumerico(Self.Caption);
end;

function TLabelHelper.Decimal: string;
begin
  Result := Formato.Decimal(Self.Caption);
end;

procedure TLabelHelper.Formatar(aFormato: TFormato; Extra: string);
begin
  Self.Text := Formato.Formatar(aFormato, Self.Caption, Extra);
end;

procedure TLabelHelper.Formatar(aFormato: TFormato; UF: TUF);
begin
  Self.Text := Formato.Formatar(aFormato, Self.Caption, UF);
end;

function TLabelHelper.Inteiro: string;
begin
  Result := Formato.Inteiro(Self.Caption);
end;

function TLabelHelper.SomenteNumero: string;
begin
  Result := Formato.SomenteNumero(Self.Caption);
end;

end.
