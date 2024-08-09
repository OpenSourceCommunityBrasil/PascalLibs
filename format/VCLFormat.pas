// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.6
unit VCLFormat;

interface

uses
  StdCtrls,
  Classes, MaskUtils, DateUtils, Math, SysUtils, SysConst, TypInfo, StrUtils;

const
  csNumbers = ['0' .. '9'];
  csIntegers = ['0' .. '9', '-'];
  csCharacters = ['a' .. 'z', 'A' .. 'Z'];
  csCurrencyDigits = ['0' .. '1', '-', ','];
  csFormatIdentifier = ['#', 'L', 'l', '9'];
  csSymbols = ['\', '/', '-', '=', '+', '*', ',', '.', ';', ':', '|', '[', ']', '{', '}',
    '(', ')', '$', '%', '@', '#', '&', '!', '?', 'ª', 'º', '°', '₢', '£', '¢', '¬',
    '¨', '§'];
  csSpecialCharacters: array [0 .. 51] of string = ('á', 'à', 'ã', 'â', 'ä', 'é', 'è',
    'ê', 'ë', 'í', 'ì', 'ï', 'î', 'ó', 'ò', 'õ', 'ô', 'ö', 'ú', 'ù', 'ü', 'û', 'ç', 'ñ',
    'ý', 'ÿ', 'Á', 'À', 'Ã', 'Â', 'Ä', 'É', 'È', 'Ê', 'Ë', 'Í', 'Ì', 'Ï', 'Î', 'Ó', 'Ò',
    'Õ', 'Ô', 'Ö', 'Ú', 'Ù', 'Ü', 'Û', 'Ç', 'Ñ', 'Ý', 'Ÿ');
  csRegularCharacters: array [0 .. 51] of string = ('a', 'a', 'a', 'a', 'a', 'e', 'e',
    'e', 'e', 'i', 'i', 'i', 'i', 'o', 'o', 'o', 'o', 'o', 'u', 'u', 'u', 'u', 'c', 'n',
    'y', 'y', 'A', 'A', 'A', 'A', 'A', 'E', 'E', 'E', 'E', 'I', 'I', 'I', 'I', 'O', 'O',
    'O', 'O', 'O', 'U', 'U', 'U', 'U', 'C', 'N', 'Y', 'Y');

type
  TFormato = (None, &Date, Bits, CEP, CEST, CFOP, CNH, CNPJ, CNPJorCPF, CPF, CREA, CRM,
    Dinheiro, Hora, HoraCurta, InscricaoEstadual, NCM, OAB, Personalizado, Peso,
    Porcentagem, Telefone, TituloEleitor, Valor, VeiculoMercosul, VeiculoTradicional);

  // estados da federação 0..26 = 27 ok
  // TODO: acrescentar código IBGE como índice padrão das siglas para facilidade de acesso
  TUF = (AC, AL, AM, AP, BA, CE, DF, ES, GO, MA, MG, MT, MS, PA, PB, PE, PI, PR, RJ, RN,
    RO, RR, RS, SC, SE, SP, &TO);

  TFormatHelper = class
  private
    function FormataBits(aStr: string): string;
    function FormataCRM(aStr: integer; UF: TUF): string;
    function FormataData(aStr: string): string;
    function FormataDinheiro(aStr: string; aPrecisao: integer = 2): string;
    function FormataHora(aStr: string): string;
    function FormataHoraCurta(aStr: string): string;
    function FormataIE(aCod: string; UF: TUF): string;
    function FormataOAB(aStr: integer; UF: TUF): string;
    function FormataPeso(aStr: string; aSeparador: boolean = false): string;
    function FormataValor(aStr: string; aSeparador: boolean = false): string;
    function Mask(Mascara, aStr: string): string;
  public
    function AlfaNumerico(aStr: string): string;
    function Decimal(aStr: string): string; overload;
    function Decimal(aStr: string; aPrecisao: integer): Double; overload;
    function Formatar(Formato: TFormato; Texto: string): string; overload;
    function Formatar(Formato: TFormato; Texto: string; ExtraArg: Variant)
      : string; overload;
    function Inteiro(aStr: string): string;
    function Primeiros(aStr: string; aDigitos: integer): string;
    function RemoveAcentos(aStr: string): string;
    function SomenteNumero(aStr: string): string;
    function Ultimos(aStr: string; aDigitos: integer): string;
  end;

  TEditHelper = class helper for TEdit
  public
    function AlfaNumerico: string;
    function Decimal: string;
    procedure Formatar(aFormato: TFormato); overload;
    procedure Formatar(aFormato: TFormato; ExtraArg: Variant); overload;
    function Inteiro: string;
    function RemoveAcentos: string;
    function SomenteNumero: string;
  end;

  TLabelHelper = class helper for TLabel
  public
    function AlfaNumerico: string;
    function Decimal: string;
    procedure Formatar(aFormato: TFormato); overload;
    procedure Formatar(aFormato: TFormato; ExtraArg: Variant); overload;
    function Inteiro: string;
    function RemoveAcentos: string;
    function SomenteNumero: string;
  end;

var
  Formato: TFormatHelper;

implementation

{ TFormatHelper }

/// <param name="aStr">O texto de entrada</param>
/// <returns>Devolve letras e números bem como caracteres acentuados.</returns>
function TFormatHelper.AlfaNumerico(aStr: string): string;
var
  I: integer;
begin
  Result := '';
  for I := 0 to pred(aStr.Length) do
    if not CharInSet(aStr.Chars[I], csSymbols) then
      Result := Result + aStr.Chars[I];
end;

function TFormatHelper.Decimal(aStr: string): string;
var
  I: integer;
begin
  Result := '';
  for I := 0 to pred(aStr.Length) do
    if CharInSet(aStr.Chars[I], csCurrencyDigits) then
      Result := Result + aStr.Chars[I];
end;

/// <returns>
/// Devolve somente números mantendo a formatação com separador de milhar e decimais, removendo os demais caracteres
/// </returns>
/// <param name="aPrecisao"> Precisão de decimais ajustável. Valor padrão: 2 </param>
function TFormatHelper.Decimal(aStr: string; aPrecisao: integer): Double;
var
  I: integer;
  Valor: string;
begin
  if aPrecisao < 0 then
    aPrecisao := 2;

  Valor := '';
  for I := 0 to pred(aStr.Length) do
    if CharInSet(aStr.Chars[I], csCurrencyDigits) then
      Valor := Valor + aStr.Chars[I];

  Result := StrToFloatDef(Format('%.' + aPrecisao.ToString + 'f',
    [StrToFloatDef(Valor, 0)]), 0);
end;

/// <returns>
/// Formata o texto para bits de forma reduzida em 2 casas decimais
/// </returns>
function TFormatHelper.FormataBits(aStr: string): string;
var
  inputbyte: Extended;
  datasize: integer;

const
  kbsize = 1024;

begin
  if not aStr.IsEmpty then
    try
      datasize := 0;
      inputbyte := StrToUInt(aStr);
      while inputbyte > kbsize do
      begin
        inputbyte := inputbyte / kbsize;
        inc(datasize);
      end;
      case datasize of
        0:
          Result := Format('%.2f Bytes', [inputbyte]);
        1:
          Result := Format('%.2f KB', [inputbyte]);
        2:
          Result := Format('%.2f MB', [inputbyte]);
        3:
          Result := Format('%.2f GB', [inputbyte]);
        4:
          Result := Format('%.2f TB', [inputbyte]);
        5:
          Result := Format('%.2f PB', [inputbyte]);
        6:
          Result := Format('%.2f EB', [inputbyte]);
        // 7: Format('%.2f ZB', [inputbyte]);
        // 8: Format('%.2f YB', [inputbyte]);
        // 9: Format('%.2f RB', [inputbyte]);
        // 10: Format('%.2f QB', [inputbyte]);
      end;
    except
      Result := '0 Bytes';
    end;
end;

/// <returns>
/// Formata o texto para código do conselho regional de medicina, no padrão
/// CRM/<estado> + 6 dígitos
/// </returns>
function TFormatHelper.FormataCRM(aStr: integer; UF: TUF): string;
begin
  if not(aStr = 0) then
    try
      Result := Format('CRM/%s %.6d', [GetEnumName(TypeInfo(TUF), ord(UF)), aStr]);
      // Mask('CRM/LL ######', GetEnumName(TypeInfo(TUF), ord(UF)) +
      // Primeiros(aStr));
    except
      Result := 'CRM/BR 000000';
    end;
end;

/// <returns>
/// Formata o texto para datas no formato dia(2)/mês(2)/ano(4)
/// Converte data em UNIX para o padrão dd/mm/yyyy
/// </returns>
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
        Result := Mask('99/99/9999', aStr)
      else
        try
          aStr := Mask('99/99/9999', aStr);
          StrToDate(aStr);
          Result := aStr;
        except
          Result := '';
        end;
    end;
end;

/// <returns>
/// Formata o texto para Dinheiro com precisão de decimais
/// </returns>
function TFormatHelper.FormataDinheiro(aStr: string; aPrecisao: integer): string;
begin
  try
    Result := Format('%.' + aPrecisao.ToString + 'm',
      [StrToFloatDef(Inteiro(aStr), 0) / Power(10, aPrecisao)]);
  except
    Result := Format('%.2m', [0]);
  end;
end;

/// <returns>
/// Formata o texto para hora com horas e minutos
/// </returns>
function TFormatHelper.FormataHoraCurta(aStr: string): string;
begin
  try
    if (aStr.IsEmpty) or ((aStr.Length > 1) and (strtoint(Copy(aStr, 0, 2)) > 23)) or
      ((aStr.Length > 3) and (strtoint(Copy(aStr, 3, 2)) > 59)) then
      Result := ''
    else
      Result := Mask('99:99', aStr);
  except
    Result := '';
  end;
end;

/// <returns>
/// Formata o texto para hora com horas, minutos e segundos
/// </returns>
function TFormatHelper.FormataHora(aStr: string): string;
begin
  try
    if (aStr.IsEmpty) or ((aStr.Length > 1) and (strtoint(Copy(aStr, 0, 2)) > 23)) or
      ((aStr.Length > 3) and (strtoint(Copy(aStr, 3, 2)) > 59)) or
      ((aStr.Length > 5) and (strtoint(Copy(aStr, 5, 2)) > 59)) then
      Result := ''
    else
      Result := Mask('99:99:99', aStr);
  except
    Result := '';
  end;
end;

/// <returns>
/// Formata o texto para inscrição estadual baseado no valor de 'UF'
/// </returns>
function TFormatHelper.FormataIE(aCod: string; UF: TUF): string;
var
  Mascara: string;
begin
  Mascara := '';
  case UF of
    AC:
      Mascara := '99.999.999/999-99';
    AL:
      Mascara := '999999999';
    AM:
      Mascara := '99.999.999-9';
    AP:
      Mascara := '999999999';
    BA:
      Mascara := '999999-99';
    CE:
      Mascara := '99999999-9';
    DF:
      Mascara := '99999999999-99';
    ES:
      Mascara := '999999999';
    GO:
      Mascara := '99.999.999-9';
    MA:
      Mascara := '999999999';
    MG:
      Mascara := '999.999.999/9999';
    MT:
      Mascara := '9999999999-9';
    MS:
      Mascara := '999999999';
    PA:
      Mascara := '99-999999-9';
    PB:
      Mascara := '99999999-9';
    PE:
      Mascara := '99.9.999.9999999-9';
    PI:
      Mascara := '999999999';
    PR:
      Mascara := '99999999-99';
    RJ:
      Mascara := '99.999.99-9';
    RN:
      Mascara := '99.999.999-9';
    RO:
      Mascara := '999.99999-9';
    RR:
      Mascara := '99999999-9';
    RS:
      Mascara := '999/9999999';
    SC:
      Mascara := '999.999.999';
    SE:
      Mascara := '999999999-9';
    SP:
      Mascara := '999.999.999.999';
    &TO:
      Mascara := '99999999999';
  end;
  Result := Mask(Mascara, aCod);
end;

/// <returns>
/// Formata o texto no padrão OAB: UF + 6 dígitos
/// </returns>
function TFormatHelper.FormataOAB(aStr: integer; UF: TUF): string;
begin
  if not(aStr = 0) then
    try
      Result := Format('%s%.6d', [GetEnumName(TypeInfo(TUF), ord(UF)), aStr]);
      // Mask('CRM/LL ######', GetEnumName(TypeInfo(TUF), ord(UF)) +
      // Primeiros(aStr));
    except
      Result := 'BR000000';
    end;
end;

/// <returns>
/// Formata o texto em um número com 3 casas decimais
/// </returns>
function TFormatHelper.FormataPeso(aStr: string; aSeparador: boolean = false): string;
begin
  try
    if aSeparador then
      Result := Format('%.3n', [SomenteNumero(aStr).ToInteger / 1000])
    else
      Result := Format('%.3f', [SomenteNumero(aStr).ToInteger / 1000]);
  except
    Result := Format('%.3f', [0]);
  end;
end;

function TFormatHelper.Formatar(Formato: TFormato; Texto: string): string;
begin
  Result := Formatar(Formato, Texto, varNull);
end;

/// <returns> Formata o valor do "Texto" baseado no tipo de "Formato" definido.</returns>
/// <param name="ExtraArg">serve para usar uma máscara própria quando utilizar o formato 'TFormato.Personalizado' ou
/// se tiver valor, formata o texto na inscrição estadual referente àquele estado, ou
/// é utilizado em alguns tipos de formatação para definir precisão de dígitos</param>
function TFormatHelper.Formatar(Formato: TFormato; Texto: string;
  ExtraArg: Variant): string;
begin
  case Formato of
    None:
      Texto := AlfaNumerico(Texto);

    &Date:
      Texto := FormataData(SomenteNumero(Texto));

    Bits:
      Texto := FormataBits(Decimal(Texto));

    CEP:
      Texto := Mask('99.999-999', SomenteNumero(Texto));

    CEST:
      Texto := Mask('99.999.99', SomenteNumero(Texto));

    CFOP:
      Texto := Mask('9.999', SomenteNumero(Texto));

    CNH:
      Texto := Mask('###########', AlfaNumerico(Texto));

    CNPJ:
      Texto := Mask('99.999.999/9999-99', SomenteNumero(Texto));

    CNPJorCPF:
      if Length(SomenteNumero(Texto)) <= 11 then
        Texto := Mask('999.999.999-99', SomenteNumero(Texto))
      else
        Texto := Mask('99.999.999/9999-99', SomenteNumero(Texto));

    CPF:
      Texto := Mask('999.999.999-99', SomenteNumero(Texto));

    CREA:
      Texto := Mask('999999999-9', SomenteNumero(Texto));

    CRM:
      Texto := FormataCRM(StrToIntDef(Ultimos(SomenteNumero(Texto), 6), 0), ExtraArg);

    Dinheiro:
      if ExtraArg <> varNull then
        Texto := FormataDinheiro(Texto, ExtraArg)
      else
        Texto := FormataDinheiro(Texto);

    Hora:
      Texto := FormataHora(SomenteNumero(Texto));

    HoraCurta:
      Texto := FormataHoraCurta(SomenteNumero(Texto));

    InscricaoEstadual:
      Texto := FormataIE(SomenteNumero(Texto), ExtraArg);

    NCM:
      Texto := Mask('9999.99.99', SomenteNumero(Texto));

    OAB:
      Texto := FormataOAB(StrToIntDef(Ultimos(SomenteNumero(Texto), 6), 0), ExtraArg);

    Personalizado:
      Texto := Mask(ExtraArg, SomenteNumero(Texto));

    Peso:
      Texto := FormataPeso(SomenteNumero(Texto));

    Porcentagem:
      Texto := Format('%.2f %%', [Decimal(Texto, 2)]);

    Telefone:
      if Length(SomenteNumero(Texto)) <= 10 then
        Texto := Mask('(99) 9999-9999', SomenteNumero(Texto))
      else
        Texto := Mask('(99) 99999-9999', SomenteNumero(Texto));

    TituloEleitor:
      Texto := Mask('9999 9999 9999 99', SomenteNumero(Texto));

    Valor:
      Texto := FormataValor(Texto, ExtraArg);

    VeiculoMercosul:
      Texto := Mask('#######', AlfaNumerico(Texto));

    VeiculoTradicional:
      Texto := Mask('LLL-9999', AlfaNumerico(Texto));
  end;

  Result := Texto;
end;

/// <returns>
/// Retorna valor formatado com 2 casas decimais
/// </returns>
function TFormatHelper.FormataValor(aStr: string; aSeparador: boolean): string;
begin
  try
    if aSeparador then
      Result := Format('%.2n', [StrToFloatDef(SomenteNumero(aStr), 0) / 100])
    else
      Result := Format('%.2f', [StrToFloatDef(SomenteNumero(aStr), 0) / 100]);
  except
    Result := Format('%.2f', [0]);
  end;
end;

/// <returns>
/// Retorna valor formatado como inteiro positivo ou negativo
/// </returns>
function TFormatHelper.Inteiro(aStr: string): string;
var
  I: integer;
begin
  Result := '';
  for I := 0 to Length(aStr) - 1 do
    if (aStr.Chars[I] In ['0' .. '9', '-']) then
      Result := Result + aStr.Chars[I];
end;

/// <returns>
/// Define uma "mascara" para ser utilizada para a formatação.
/// </returns>
/// <param name="Mascara">Aceita os seguintes valores:
/// #: para qualquer caractere
/// L: somente letras e vai devolver o texto em maiúsculas
/// l: somente letras e vai devolver o texto em minúsculas
/// 9: somente número </param>
function TFormatHelper.Mask(Mascara, aStr: string): string;
var
  maskidx, textidx: integer;
begin
  textidx := 0;
  Result := '';

  if not aStr.IsEmpty then
    for maskidx := 0 to Length(Mascara) - 1 do
    begin
      if Mascara.Chars[maskidx] = '#' then
      begin
        Result := Result + aStr.Chars[textidx];
        inc(textidx);
      end
      else if (Mascara.Chars[maskidx] = 'L') and CharInSet(aStr.Chars[textidx],
        csCharacters) then
      begin
        Result := Result + UpperCase(aStr.Chars[textidx]);
        inc(textidx);
      end
      else if (Mascara.Chars[maskidx] = 'l') and CharInSet(aStr.Chars[textidx],
        csCharacters) then
      begin
        Result := Result + LowerCase(aStr.Chars[textidx]);
        inc(textidx);
      end
      else if (Mascara.Chars[maskidx] = '9') and CharInSet(aStr.Chars[textidx], csNumbers)
      then
      begin
        Result := Result + aStr.Chars[textidx];
        inc(textidx);
      end
      else if not CharInSet(Mascara.Chars[maskidx], csFormatIdentifier) then
        Result := Result + Mascara.Chars[maskidx];

      if textidx = Length(aStr) then
        break;
    end;
end;

/// <returns>
/// Devolve os primeiros 'aDigitos' contidos no texto
/// </returns>
function TFormatHelper.Primeiros(aStr: string; aDigitos: integer): string;
begin
  if not(aStr = '') then
    Result := Copy(aStr, 1, aDigitos);
end;

function TFormatHelper.RemoveAcentos(aStr: string): string;
var
  I: integer;
begin
  Result := aStr;
  for I := 0 to pred(Length(csSpecialCharacters)) do
    Result := StringReplace(Result, csSpecialCharacters[I], csRegularCharacters[I],
      [rfReplaceAll]);
end;

/// <returns>
/// Devolve somente os números contidos no texto
/// </returns>
function TFormatHelper.SomenteNumero(aStr: string): string;
var
  I: integer;
begin
  Result := '';
  for I := 0 to Length(aStr) - 1 do
    if (aStr.Chars[I] In ['0' .. '9']) then
      Result := Result + aStr.Chars[I];
end;

/// <returns>
/// Devolve os últimos 'aDigitos' contidos no texto
/// </returns>
function TFormatHelper.Ultimos(aStr: string; aDigitos: integer): string;
begin
  if not(aStr = '') then
    Result := RightStr(aStr, aDigitos);
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

procedure TEditHelper.Formatar(aFormato: TFormato);
begin
  Self.Text := Formato.Formatar(aFormato, Self.Text, varNull);
  Self.SelStart := Length(Self.Text);
end;

function TEditHelper.Inteiro: string;
begin
  Result := Formato.Inteiro(Self.Text);
  Self.SelStart := Length(Self.Text);
end;

function TEditHelper.RemoveAcentos: string;
begin
  Result := Formato.RemoveAcentos(Self.Text);
end;

procedure TEditHelper.Formatar(aFormato: TFormato; ExtraArg: Variant);
begin
  Self.Text := Formato.Formatar(aFormato, Self.Text, ExtraArg);
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

procedure TLabelHelper.Formatar(aFormato: TFormato);
begin
  Self.Text := Formato.Formatar(aFormato, Self.Caption, varNull);
end;

procedure TLabelHelper.Formatar(aFormato: TFormato; ExtraArg: Variant);
begin
  Self.Text := Formato.Formatar(aFormato, Self.Caption, ExtraArg);
end;

function TLabelHelper.Inteiro: string;
begin
  Result := Formato.Inteiro(Self.Caption);
end;

function TLabelHelper.RemoveAcentos: string;
begin
  Result := Formato.RemoveAcentos(Self.Caption);
end;

function TLabelHelper.SomenteNumero: string;
begin
  Result := Formato.SomenteNumero(Self.Caption);
end;

end.
