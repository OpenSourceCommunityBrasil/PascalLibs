// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.7
unit FMXFormat;

interface

uses
  FMX.Edit, FMX.Text, FMX.StdCtrls, FMX.Objects,
  Classes, MaskUtils, DateUtils, Math, SysUtils, SysConst, TypInfo, StrUtils;

const
  csNumbers = ['0' .. '9'];
  csIntegers = ['0' .. '9', '-'];
  csCharacters = ['a' .. 'z', 'A' .. 'Z'];
  csCurrencyDigits = ['0' .. '9', '-', ','];
  csFormatIdentifier = ['#', 'L', 'l', '9', 'A'];
  csAlphaNum = ['a' .. 'z', 'A' .. 'Z', '0' .. '9'];  
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
  TTipoFormato = (tfNenhum, tfBits, tfCartao, tfCEP, tfCEST, tfCFOP, tfCNH, tfCNPJ,
    tfCPF, tfCPFCNPJ, tfCREA, tfCRM, tfData, tfDinheiro, tfHora, tfHoraCurta,
    tfInscricaoEstadual, tfNCM, tfOAB, tfPersonalizado, tfPeso, tfPorcentagem,
    tfTelefone, tfTituloEleitor, tfValor, tfVeiculoMercosul, tfVeiculoTradicional);

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
    function FormataPeso(aStr: string; aSeparador: boolean = False): string;
    function FormataValor(aStr: string; aSeparador: boolean = False): string;
    function Mask(Mascara, aStr: string): string;
  public
    function AlfaNumerico(aStr: string): string;
    function Decimal(aStr: string): string; overload;
    function Decimal(aStr: string; aPrecisao: integer): double; overload;
    function Formatar(Formato: TFormato; Texto: string): string;
      overload; deprecated 'essa funcao vai ser removida, substitua o tipo TFormato por TTipoFormato';
    function Formatar(Formato: TFormato; Texto: string; ExtraArg: variant): string;
      overload; deprecated 'essa funcao vai ser removida, substitua o tipo TFormato por TTipoFormato';
    function Formatar(Formato: TTipoFormato; Texto: string): string; overload;
    function Formatar(Formato: TTipoFormato; Texto: string; ExtraArg: variant): string; overload;
    function Inteiro(aStr: string): string;
    function Primeiros(aStr: string; aDigitos: integer): string;
    function RemoveAcentos(aStr: string): string;
    function SomenteNumero(aStr: string): string;
    function Ultimos(aStr: string; aDigitos: integer): string;

    function ValidaCPF(aCPF: string): boolean;
    function ValidaCNPJ(aCPNJ: string): boolean;
    function BandeiraCartao(aCartao: string): string;
  end;

  TEditHelper = class helper for TEdit
  public
    function AlfaNumerico: string;
    function Decimal: string;
    procedure Formatar(aFormato: TFormato); overload;
      deprecated 'essa funcao vai ser removida, substitua o tipo TFormato por TTipoFormato';
    procedure Formatar(aFormato: TFormato; ExtraArg: variant); overload;
      deprecated 'essa funcao vai ser removida, substitua o tipo TFormato por TTipoFormato';
    procedure Formatar(aFormato: TTipoFormato); overload;
    procedure Formatar(aFormato: TTipoFormato; ExtraArg: variant); overload;
    function Inteiro: string;
    function RemoveAcentos: string;
    function SomenteNumero: string;
  end;

  TLabelHelper = class helper for TLabel
  public
    function AlfaNumerico: string;
    function Decimal: string;
    procedure Formatar(aFormato: TFormato); overload;
      deprecated 'essa funcao vai ser removida, substitua o tipo TFormato por TTipoFormato';
    procedure Formatar(aFormato: TFormato; ExtraArg: variant);
      overload; deprecated 'essa funcao vai ser removida, substitua o tipo TFormato por TTipoFormato';
    procedure Formatar(aFormato: TTipoFormato); overload;
    procedure Formatar(aFormato: TTipoFormato; ExtraArg: variant); overload;
    function Inteiro: string;
    function RemoveAcentos: string;
    function SomenteNumero: string;
  end;

  TTextHelper = class helper for TText
  public
    function AlfaNumerico: string;
    function Decimal: string;
    procedure Formatar(aFormato: TFormato); overload;
      deprecated 'essa funcao vai ser removida, substitua o tipo TFormato por TTipoFormato';
    procedure Formatar(aFormato: TFormato; ExtraArg: variant);
      overload; deprecated 'essa funcao vai ser removida, substitua o tipo TFormato por TTipoFormato';
    procedure Formatar(aFormato: TTipoFormato); overload;
    procedure Formatar(aFormato: TTipoFormato; ExtraArg: variant); overload;
    function Inteiro: string;
    function RemoveAcentos(aStr: string): string;
    function SomenteNumero: string;
  end;

// Função auxiliar geral temporária. Será removida juntamente das funções depreciadas.
function FormatoToTipo(AFormato: TFormato): TTipoFormato;

var
  Formato: TFormatHelper;

implementation

function FormatoToTipo(AFormato: TFormato): TTipoFormato;
begin
  case AFormato of
    None: Result := tfNenhum;
    &Date: Result := tfData;
    Bits: Result := tfBits;
    CEP: Result := tfCEP;
    CEST: Result := tfCEST;
    CFOP: Result := tfCFOP;
    CNH: Result := tfCNH;
    CNPJ: Result := tfCNPJ;
    CNPJorCPF: Result := tfCPFCNPJ;
    CPF: Result := tfCPF;
    CREA: Result := tfCREA;
    CRM: Result := tfCRM;
    Dinheiro: Result := tfDinheiro;
    Hora: Result := tfHora;
    HoraCurta: Result := tfHoraCurta;
    InscricaoEstadual: Result := tfInscricaoEstadual;
    NCM: Result := tfNCM;
    OAB: Result := tfOAB;
    Personalizado: Result := tfPersonalizado;
    Peso: Result := tfPeso;
    Porcentagem: Result := tfPorcentagem;
    Telefone: Result := tfTelefone;
    TituloEleitor: Result := tfTituloEleitor;
    Valor: Result := tfValor;
    VeiculoMercosul: Result := tfVeiculoMercosul;
    VeiculoTradicional: Result := tfVeiculoTradicional;
  end;
end;

{ TFormatHelper }

/// <param name="aStr">O texto de entrada</param>
/// <returns>Devolve letras e números bem como caracteres acentuados.</returns>
function TFormatHelper.AlfaNumerico(aStr: string): string;
var
  I: integer;
begin
  Result := '';
  for I := 1 to aStr.Length do
    if CharInSet(aStr[I], csAlphaNum) then
      Result := Result + aStr[I];
end;

function TFormatHelper.Decimal(aStr: string): string;
var
  I: integer;
begin
  Result := '';
  for I := 1 to aStr.Length do
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
  for I := 1 to aStr.Length do
    if CharInSet(aStr.Chars[I], csCurrencyDigits) then
      Valor := Valor + aStr.Chars[I];

  Result := StrToFloatDef(Format('%.' + IntToStr(aPrecisao) + 'f',
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

// <returns> Formata o valor do "Texto" baseado no tipo de "Formato" definido.</returns>
// <param name="ExtraArg">serve para usar uma máscara própria quando utilizar o formato 'TFormato.Personalizado' ou
// se tiver valor, formata o texto na inscrição estadual referente àquele estado, ou
// é utilizado em alguns tipos de formatação para definir precisão de dígitos</param>
function TFormatHelper.Formatar(Formato: TFormato; Texto: string; ExtraArg: variant): string;
begin
  Result := Formatar(FormatoToTipo(Formato), Texto, ExtraArg);
end;

function TFormatHelper.Formatar(Formato: TTipoFormato; Texto: string): string;
begin
  Result := Formatar(Formato, Texto, varNull);
end;

/// <returns> Formata o valor do "Texto" baseado no tipo de "Formato" definido.</returns>
/// <param name="ExtraArg">serve para usar uma máscara própria quando utilizar o formato 'TFormato.Personalizado' ou
/// se tiver valor, formata o texto na inscrição estadual referente àquele estado, ou
/// é utilizado em alguns tipos de formatação para definir precisão de dígitos</param>
function TFormatHelper.Formatar(Formato: TTipoFormato; Texto: string; ExtraArg: variant): string;
begin
  case Formato of
    tfNenhum:
      Texto := AlfaNumerico(Texto);

    tfBits:
      //raise Exception.Create('Recurso em implementação');
      Texto := FormataBits(Decimal(Texto));

    tfCartao:
      Texto := Mask('9999 9999 9999 9999', SomenteNumero(Texto));

    tfCEP:
      Texto := Mask('99.999-999', SomenteNumero(Texto));

    tfCEST:
      Texto := Mask('99.999.99', SomenteNumero(Texto));

    tfCFOP:
      Texto := Mask('9.999', SomenteNumero(Texto));

    tfCNH:
      Texto := Mask('###########', AlfaNumerico(Texto));

    tfCNPJ:
      Texto := Mask('AA.AAA.AAA/AAAA-99', AlfaNumerico(Texto));

    tfCPF:
      Texto := Mask('999.999.999-99', SomenteNumero(Texto));

    tfCPFCNPJ:
      if Length(SomenteNumero(Texto)) <= 11 then
        Texto := Mask('999.999.999-99', SomenteNumero(Texto))
      else
        Texto := Mask('AA.AAA.AAA/AAAA-99', AlfaNumerico(Texto));

    tfCREA:
      Texto := Mask('999999999-9', SomenteNumero(Texto));

    tfCRM:
      Texto := FormataCRM(StrToIntDef(Ultimos(SomenteNumero(Texto), 6), 0), ExtraArg);

    tfData:
      Texto := FormataData(SomenteNumero(Texto));

    tfDinheiro:
      if ExtraArg <> varNull then
        Texto := FormataDinheiro(Texto, ExtraArg)
      else
        Texto := FormataDinheiro(Texto);

    tfHora:
      Texto := FormataHora(SomenteNumero(Texto));

    tfHoraCurta:
      Texto := FormataHoraCurta(SomenteNumero(Texto));

    tfInscricaoEstadual:
      Texto := FormataIE(SomenteNumero(Texto), ExtraArg);

    tfNCM:
      Texto := Mask('9999.99.99', SomenteNumero(Texto));

    tfOAB:
      Texto := FormataOAB(StrToIntDef(Ultimos(SomenteNumero(Texto), 6), 0), ExtraArg);

    tfPersonalizado:
      Texto := Mask(ExtraArg, SomenteNumero(Texto));

    tfPeso:
      Texto := FormataPeso(SomenteNumero(Texto));

    tfPorcentagem:
      Texto := Format('%.2f %%', [Decimal(Texto, 2)]);

    tfTelefone:
      if Length(SomenteNumero(Texto)) <= 10 then
        Texto := Mask('(99) 9999-9999', SomenteNumero(Texto))
      else
        Texto := Mask('(99) 99999-9999', SomenteNumero(Texto));

    tfTituloEleitor:
      Texto := Mask('9999 9999 9999 99', SomenteNumero(Texto));

    tfValor:
      Texto := FormataValor(Texto, ExtraArg);

    tfVeiculoMercosul:
      Texto := Mask('#######', AlfaNumerico(Texto));

    tfVeiculoTradicional:
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
  for I := 1 to Length(aStr) do
    if CharInSet(aStr.Chars[I], csIntegers) then
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
      else if (Mascara.Chars[maskidx] = 'A') and CharInSet(aStr.Chars[textidx],
        csAlphaNum) then
      begin
        Result := Result + aStr.Chars[textidx];
        Inc(textidx);
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
  x: integer;
begin
  Result := '';
  for x := 1 to Length(aStr) do
    if CharInSet(aStr.Chars[x], csNumbers) then
      Result := Result + aStr.Chars[x];
end;

/// <returns>
/// Devolve os últimos 'aDigitos' contidos no texto
/// </returns>
function TFormatHelper.Ultimos(aStr: string; aDigitos: integer): string;
begin
  if not(aStr = '') then
    Result := RightStr(aStr, aDigitos);
end;

function TFormatHelper.ValidaCPF(aCPF: string): boolean;
var
  dig10, dig11: string;
  dv, i, r, peso: integer;
begin
  // tratamento da entrada de dados
  aCPF := SomenteNumero(aCPF);

  // tratamento de valores inválidos
  if ((aCPF = '00000000000') or (aCPF = '11111111111') or (aCPF = '22222222222') or
    (aCPF = '33333333333') or (aCPF = '44444444444') or (aCPF = '55555555555') or
    (aCPF = '66666666666') or (aCPF = '77777777777') or (aCPF = '88888888888') or
    (aCPF = '99999999999') or (length(aCPF) <> 11)) then
    Result := False
  else
  begin
    try
      { *-- Cálculo do 1o. Digito Verificador --* }
      dv := 0;
      peso := 10;
      for i := 1 to 9 do
      begin
        dv := dv + (StrToInt(aCPF[i]) * peso);
        Dec(peso);
      end;

      r := 11 - (dv mod 11);
      if ((r = 10) or (r = 11)) then dig10 := '0'
      else
        str(r: 1, dig10); // converte um número no respectivo caractere numérico

      { *-- Cálculo do 2o. Digito Verificador --* }
      dv := 0;
      peso := 11;
      for i := 1 to 10 do
      begin
        dv := dv + (StrToInt(aCPF[i]) * peso);
        Dec(peso);
      end;
      r := 11 - (dv mod 11);
      if ((r = 10) or (r = 11)) then dig11 := '0'
      else
        str(r: 1, dig11);

      { Verifica se os digitos calculados conferem com os digitos informados. }
      if ((dig10 = aCPF[10]) and (dig11 = aCPF[11])) then Result := True
      else
        Result := False;
    except
      Result := False
    end;
  end;
end;

function TFormatHelper.ValidaCNPJ(aCPNJ: string): boolean;
var
  dig13, dig14: string;
  soma, i, r, peso: integer;
begin
  // tratamento da entrada de dados
  aCPNJ := AlfaNumerico(aCPNJ);

  // validação dos valores
  if ((aCPNJ = '00000000000000') or (aCPNJ = '11111111111111') or
    (aCPNJ = '22222222222222') or (aCPNJ = '33333333333333') or (aCPNJ = '44444444444444') or
    (aCPNJ = '55555555555555') or (aCPNJ = '66666666666666') or (aCPNJ = '77777777777777') or
    (aCPNJ = '88888888888888') or (aCPNJ = '99999999999999') or (length(aCPNJ) <> 14)) then
    Result := False
  else
  begin
    try
      { *-- Cálculo do 1o. Digito Verificador --* }
      soma := 0;
      peso := 2;
      for i := 12 downto 1 do
      begin
        soma := soma + (StrToInt(aCPNJ[i]) * peso);
        Inc(peso);
        if (peso = 10) then peso := 2;
      end;
      r := soma mod 11;
      if ((r = 0) or (r = 1)) then dig13 := '0'
      else
        str((11 - r): 1, dig13); // converte um número no respectivo caractere numérico

      { *-- Cálculo do 2o. Digito Verificador --* }
      soma := 0;
      peso := 2;
      for i := 13 downto 1 do
      begin
        soma := soma + (StrToInt(aCPNJ[i]) * peso);
        Inc(peso);
        if (peso = 10) then peso := 2;
      end;
      r := soma mod 11;
      if ((r = 0) or (r = 1)) then dig14 := '0'
      else
        str((11 - r): 1, dig14);

      { Verifica se os digitos calculados conferem com os digitos informados. }
      if ((dig13 = aCPNJ[13]) and (dig14 = aCPNJ[14])) then Result := True
      else
        Result := False;
    except
      Result := False
    end;
  end;
end;

function TFormatHelper.BandeiraCartao(aCartao: string): string;
var
  digitos: string;
  p1, p2, p3, p4, p6: integer;
begin
  // validação de entrada
  digitos := SomenteNumero(aCartao);

  p1 := StrToIntDef(primeiros(digitos, 1), 0);
  p2 := StrToIntDef(primeiros(digitos, 2), 0);
  p3 := StrToIntDef(primeiros(digitos, 3), 0);
  p4 := StrToIntDef(primeiros(digitos, 4), 0);
  p6 := StrToIntDef(primeiros(digitos, 6), 0);

  // validar os dígitos:
  {Visa: Começa com o dígito 4 (BIN de 400000 a 499999)
   Mastercard: Começa com os dígitos 51 a 55, e mais recentemente com 2221 a 2720
   American Express: Começa com os dígitos 34 ou 37
   Elo: Varia, mas inclui faixas como 438935, 451416, 5067, 4576, 4011, 504175 e 506699
   Diners Club: Começa com 301, 305, 36 ou 38
   Discover: Começa com 6011, 622126 a 622925, 644 a 649, 65
   Discover: 6011, 622, 64 e 65
   JCB: Começa com 3528 a 3589
   Hipercard: Começa com 606282 ou 384100 a 384199
   Aura: 50
   }

  if p1 = 4 then
    Result := 'Visa'
  else if (p2 = 34) or (p2 = 37) then
    Result := 'American Express'
  else if (p2 = 36) or (p2 = 38) or (p3 = 301) or (p3 = 305) then
    Result := 'Diners Club'
  else if (p4 >= 3528) and (p4 <= 3589) then
    Result := 'JCB'
  else if (p2 = 65) or ((p3 >= 644) and (p3 <= 649)) or (p4 = 6011) or
    ((p6 >= 622126) and (p6 <= 622925)) then
    Result := 'Discover'
  else if ((p2 >= 51) and (p2 <= 55)) or ((p4 >= 2221) and (p4 <= 2720)) then
    Result := 'Mastercard'
  else if (p4 = 4011) or (p6 = 438935) or (p6 = 451416) or (p4 = 4576) or
    (p4 = 5067) or ((p6 >= 504175) and (p6 <= 506699)) then
    Result := 'Elo'
  else if (p6 = 606282) or ((p6 >= 384100) and (p6 <= 384199)) then
    Result := 'Hipercard'
  else if (p2 = 50) and (p3 <> 506) then
    Result := 'Aura'
  else
    Result := '';
end;

{ TEditHelper }

function TEditHelper.AlfaNumerico: string;
begin
  Result := Formato.AlfaNumerico(Self.Text);
  Self.GoToTextEnd;
end;

function TEditHelper.Decimal: string;
begin
  Result := Formato.Decimal(Self.Text, 2).ToString;
  Self.GoToTextEnd;
end;

procedure TEditHelper.Formatar(aFormato: TFormato);
begin
  Self.Text := Formato.Formatar(FormatoToTipo(aFormato), Self.Text, varNull);
  Self.GoToTextEnd;
end;

function TEditHelper.Inteiro: string;
begin
  Result := Formato.Inteiro(Self.Text);
  Self.GoToTextEnd;
end;

function TEditHelper.RemoveAcentos: string;
begin
  Result := Formato.RemoveAcentos(Self.Text);
end;

procedure TEditHelper.Formatar(aFormato: TFormato; ExtraArg: variant);
begin
  Self.Text := Formato.Formatar(FormatoToTipo(aFormato), Self.Text, ExtraArg);
  Self.GoToTextEnd;
end;

procedure TEditHelper.Formatar(aFormato: TTipoFormato);
begin
  Self.Text := Formato.Formatar(aFormato, Self.Text, varNull);
  Self.GoToTextEnd;
end;

procedure TEditHelper.Formatar(aFormato: TTipoFormato; ExtraArg: variant);
begin
  Self.Text := Formato.Formatar(aFormato, Self.Text, ExtraArg);
  Self.GoToTextEnd;
end;

function TEditHelper.SomenteNumero: string;
begin
  Result := Formato.SomenteNumero(Self.Text);
  Self.GoToTextEnd;
end;

{ TTextHelper }

function TTextHelper.AlfaNumerico: string;
begin
  Result := Formato.AlfaNumerico(Self.Text);
end;

function TTextHelper.Decimal: string;
begin
  Result := Formato.Decimal(Self.Text);
end;

procedure TTextHelper.Formatar(aFormato: TFormato);
begin
  Self.Text := Formato.Formatar(FormatoToTipo(aFormato), Self.Text, varNull);
end;

procedure TTextHelper.Formatar(aFormato: TFormato; ExtraArg: variant);
begin
  Self.Text := Formato.Formatar(FormatoToTipo(aFormato), Self.Text, ExtraArg);
end;

procedure TTextHelper.Formatar(aFormato: TTipoFormato);
begin
  Self.Text := Formato.Formatar(aFormato, Self.Text, varNull);
end;

procedure TTextHelper.Formatar(aFormato: TTipoFormato; ExtraArg: variant);
begin
  Self.Text := Formato.Formatar(aFormato, Self.Text, ExtraArg);
end;

function TTextHelper.Inteiro: string;
begin
  Result := Formato.Inteiro(Self.Text);
end;

function TTextHelper.RemoveAcentos(aStr: string): string;
begin
  Result := Formato.RemoveAcentos(Self.Text);
end;

function TTextHelper.SomenteNumero: string;
begin
  Result := Formato.SomenteNumero(Self.Text);
end;

{ TLabelHelper }

function TLabelHelper.AlfaNumerico: string;
begin
  Result := Formato.AlfaNumerico(Self.Text);
end;

function TLabelHelper.Decimal: string;
begin
  Result := Formato.Decimal(Self.Text);
end;

procedure TLabelHelper.Formatar(aFormato: TTipoFormato);
begin
  Self.Text := Formato.Formatar(aFormato, Self.Text, varNull);
end;

procedure TLabelHelper.Formatar(aFormato: TTipoFormato; ExtraArg: Variant);
begin
  Self.Text := Formato.Formatar(aFormato, Self.Text, ExtraArg);
end;

procedure TLabelHelper.Formatar(aFormato: TFormato);
begin
  Self.Text := Formato.Formatar(FormatoToTipo(aFormato), Self.Text, varNull);
end;

procedure TLabelHelper.Formatar(aFormato: TFormato; ExtraArg: Variant);
begin
  Self.Text := Formato.Formatar(FormatoToTipo(aFormato), Self.Text, ExtraArg);
end;

function TLabelHelper.Inteiro: string;
begin
  Result := Formato.Inteiro(Self.Text);
end;

function TLabelHelper.RemoveAcentos: string;
begin
  Result := Formato.RemoveAcentos(Self.Text);
end;

function TLabelHelper.SomenteNumero: string;
begin
  Result := Formato.SomenteNumero(Self.Text);
end;

end.
