//=============================================================================
// Amilton Maciel - amiltonsmaciel@gmail.com
//   Conjunto de funções para cálculo de digito de CNPJ e CPF e também para
//     validar se os números informados são válidos.
//-----------------------------------------------------------------------------
//   Set of functions to calculate the digits of brazilian comercial number and
//     personal tax id, this set of functions also validate this numbers.
//=============================================================================

unit cpf_cnpj;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils;


{ Verifica se a string do argumento é um número, considera como válidos
  além dos caracteres numéricos, os separadores de milhares e decimais,
  sinais + e -. Esta função não considera como válido o símbolo monetário
  utilizado, para isto deverá ser utilizada a função StrToCurrency, que
  sempre retorna um número float, mesmo para uma string inválida}
function IsNumeric(StrArg1: String): Boolean;

// Calcula os digitos de controle do CNPJ, deve ser informado o número de CNPJ sem
//    formatação, o número pode ser informado com ou seu os digitos, e retorna o
//    digito válido do CNPJ
function DigitoCNPJ(NroCNPJ: String): String;

// Calcula os digitos de controle do CPF, deve ser informado o número sem formatação,
//     os mesmos princípios da função DigitoCNPJ se aplicam aqui.
function DigitoCPF(NroCPF: String): String;

// Verifica a validade do número de CNPJ informado
//     O número pode ser passado tanto como número sem nenhuma formatação, como pode ser
//       passado como um número de CNPJ formatado no formato 99.999.999/9999-99
function ValidateCNPJ(NroCNPJ: String): Boolean;

// Verifica se o CPF informado é válido
//    Os mesmos princípios da função ValidateCNPJ são aplicados a esta função.
function ValidateCPF(NroCPF: String): Boolean;



implementation


function IsNumeric(StrArg1: String): Boolean;
var
   ind : integer;
begin
     result := True;
     if Length(StrArg1) < 1 then
        result := False
     else
         begin
         for ind := 1 to Length(StrArg1) do
             begin
             if not (StrArg1[ind] in ['0'..'9', '+', '-', DefaultFormatSettings.DecimalSeparator,
                                       DefaultFormatSettings.ThousandSeparator,' ']) then
                 result:= False;
             end;
         end;
end;


function DigitoCNPJ(NroCNPJ: String): String;
var
   ind, dig1, dig2 , acumulado: Integer;
   NumCNPJ: array [1..14] of integer;
const
   Calculo: array [1..14] of Integer = (6,5,4,3,2,9,8,7,6,5,4,3,2,0);
begin
   if Length(NroCNPJ) = 12 Then
       NroCNPJ := NroCNPJ + '00';

   if Length(NroCNPJ) <> 14 then
        begin
        DigitoCNPJ := '';
        exit;
        end;
   for ind := 1 to 14 do
       begin
       if IsNumeric(NroCNPJ[ind]) then
          NumCNPJ[ind] := StrToInt(NroCNPJ[ind]);
       end;

   acumulado := 0;
   for ind := 1 to 4 do
       acumulado := acumulado + NumCNPJ[ind] * (6 - ind);
   for ind := 1 to 8 do
       acumulado := acumulado + NumCNPJ[ind + 4] * (10 - ind);
   acumulado := 11 - acumulado mod 11;
   if acumulado in [10,11] then
      acumulado := 0;
   dig1 := acumulado;

   NumCNPJ[13] := dig1;

   acumulado := 0;
   for ind := 1 to 5 do
       acumulado := acumulado + NumCNPJ[ind] * (7 - ind);
   for ind := 1 to 8 do
       acumulado := acumulado + NumCNPJ[ind + 5] * (10 - ind);
   acumulado := 11 - acumulado mod 11;
   if acumulado in [10,11] then
      acumulado := 0;
   dig2 := acumulado;

   result := InttoStr(dig1) + IntToStr(dig2);

end;

function DigitoCPF(NroCPF: String): String;
var
   ind, dig1, dig2 , acumulado: Integer;
   NumCPF: array [1..11] of integer;
begin
   if Length(NroCPF) = 9 Then
      NroCPF := NroCPF + '00';

   if Length(NroCPF) <> 11 then
        begin
        DigitoCPF := '';
        exit;
        end;
   for ind := 1 to 11 do
       begin
       if IsNumeric(NroCPF[ind]) then
          NumCPF[ind] := StrToInt(NroCPF[ind]);
       end;

   acumulado := 0;

   for ind := 1 to 9 do
       acumulado := acumulado + NumCPF[ind] * (11 - ind);
   acumulado := 11 - acumulado mod 11;
   if acumulado in [10,11] then
      acumulado := 0;
   dig1 := acumulado;

   NumCPF[10] := dig1;

   acumulado := 0;
   for ind := 1 to 10 do
       acumulado := acumulado + NumCPF[ind] * (12 - ind);
   acumulado := 11 - acumulado mod 11;
   if acumulado in [10,11] then
      acumulado := 0;
   dig2 := acumulado;

   DigitoCPF := InttoStr(dig1) + IntToStr(dig2);

end;

function ValidateCNPJ(NroCNPJ: String): Boolean;
var
   NumCNPJ,dig1, dig2: String;
   ind: integer;
begin
     result := false;
     if (Length(NroCNPJ) <> 14) And (Length(NroCNPJ) <> 18) then
        exit;

     NumCNPJ := '';

     for ind := 1 to (Length(NroCNPJ)) do
         begin
         if NroCNPJ[ind] in ['0'..'9'] then
            NumCNPJ := NumCNPJ + NroCNPJ[ind];
         end;
     if Length(NumCNPJ) <> 14 then
        exit;

     dig1 := NumCNPJ[13] + NumCNPJ[14];
     dig2 := DigitoCNPJ(NumCNPJ);
     result :=  (dig1 = dig2);

end;

function ValidateCPF(NroCPF: String): Boolean;
var
   dig1, dig2, NumCPF: String;
   ind: integer;
begin
     result := false;
     if (Length(NroCPF) <> 11) And (Length(NroCPF) <> 14) then
        exit;

     NumCPF := '';

     for ind := 1 to Length(NroCPF) do
         begin
         if NroCPF[ind] in ['0'..'9'] then
            NumCPF := NumCPF + NroCPF[ind];
         end;

     if Length(NumCPF) <> 11 then
        exit;

     dig1 := NumCPF[10] + NumCPF[11];
     dig2 := DigitoCPF(NumCPF);
     result := (dig1 = dig2);

end;


end.

