# Arquivos com métodos ou funções sem uma estrutura geral de unit

## AutoFitDbGridCol.pas
By Wanderson S Fróes - Wandersobfroea@outlook.com

* Ajusta a coluna no grid passados como parâmetros para ter a propriedade de auto ajustar o tamanho da coluna.
* Turn the column in the grid passed as argument in a autofit column that self adjust it's size on Form resize.

Parameters: 
 - DBGrid = The TDbGrid that contains the column in second argument.
 - ColNumberToAutoFit: Col number that will be autofit on resize.
  
## sanitize.pas
By Amilton Maciel - amiltonsmaciel@gmail.com
- Limpa uma string de caracteres que podem causar problemas dentro de uma cláusua SQL
- Cleans a string erasing characters that may cause problems inside a SQL clause. To avoid SQL Injection more characters can be included in CharToClean array

## zipfiles.pas
By Amilton Maciel - amiltonsmaciel@gmail.com
- Cria um arquivo compactado contendo os arquivos passados no parâmetro SourceFiles
- Creates a new compressed file, add the files included in SourceFiles to final compressed file.
