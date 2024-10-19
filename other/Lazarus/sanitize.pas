//==================================================================================================
// Amilton Maciel - amiltonsmaciel@gmail.com
// sobrecarga do operador in para utilizar na comparação na função SanitizeString.
//--------------------------------------------------------------------------------------------------
// Operator "in" overloaded for use in SanitizeString function 
//==================================================================================================
operator in (const AString: String; const AArray: array of String): Boolean; inline;
var
  Item: String;
begin
  for Item in AArray do
    if Item = AString then
       Exit(True);
  Result := False;
end;

//==================================================================================================
// Amilton Maciel - amiltonsmaciel@gmail.com
// Limpa uma string de caracteres que podem causar problemas dentro de uma cláusua SQL
//--------------------------------------------------------------------------------------------------
//  Clean a string, erase characteres that may cause problems inside a SQL clause, avoid SQL Injection
//     more characters can be included in CharToClean array
//==================================================================================================
function SanitizeString(Value: String): String;
var
  Return, strChar : String;
  idx : integer;
const
  CharToClean: array of String = ('"', '\', '/', '%');
begin
  try
    Return := '';
    for idx := 1 to Length(Value) do
        begin
        if (Value[idx] in CharToClean) Then
           strChar := ' '
        else
            strChar := Value[idx];
        Return := Return + strChar;
        end;
  finally
    Result := Return;
  end;
end;
