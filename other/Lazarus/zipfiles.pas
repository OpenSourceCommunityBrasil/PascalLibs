uses
   Dialogs, FileUtil, paszlib, Zipper;

// ===============================================================================================
//  Amilton Maciel - amiltonsmaciel@gmail.com
//     Cria um arquivo compactado contendo os arquivos passados no parâmetro SourceFiles
//     Create a new compressed file, add the files included in SourceFiles to final compressed file.
// ===============================================================================================
Function Compress(DestinyFile: String; SourceFiles: TStringList) : String;
var
  Zip: TZipper;
  idx: Integer;
begin
  try
    Zip := TZipper.Create;
    Result := '';

    // Test if the filename for compressed file have a extension ".rar", if not ask user if confirm include the correct extension
	//      if true continues, if not return with do nothing
	// -------------------------------------------------------------
    if (lowercase(ExtractFileExt(DestinyFile)) <> '.rar') Then
       begin
       ChangeFileExt(DestinyFile, '.rar');
       if MessageDlg('Attention', 'The extension for compressed file has changed to .rar! Confirm?', mtWarning, [mbYes, mbNo],0) = mrNo Then
	  begin
	  Result := 'Operation canceled by user!';
	  exit;
	  end;
       end;

    if SourceFiles.Count < 1 Then
       begin
       Result := 'There are no files to be included in final compressed file!';
       exit;
       end;

    try
      Zip.FileName := DestinyFile;

      // First argument is the file to be included, the second is the name of the file as it appears in the compressed and later the in the filesystem
      for idx := 0 to SourceFiles.Count -1 do
          Zip.Entries.AddFileEntry(SourceFiles[idx], ExtractFileName(SourceFiles[idx]));

      Zip.ZipAllFiles;
      Result := '';
    except
    on E: Exception do
       Result := E.Message;
    end;
  finally
    Zip.Free;
  end;
end;


// =============================================================================================================
//  Amilton Maciel - amiltonsmaciel@gmail.com
// Descompacta um arquivo passado como parâmetro em ArqCompactado para o diretório chamado em DirDestino.
//    Esta é uma função que apenas efetua a extração do arquivo, é responsabilidade do chamador garantir que
//    o arquivo compactado exista e que o diretório de destino também exista e tenha as permissões necessárias.
// --------------------------------------------------------------------------------------------------------------
// Decompress the content of the file passed as first argument in the path passed as second argument.
//    This function only do a extract for file content of the compressed file, the caller had a responsability 
//         to check if the compressed file exists and it's the correct type and the destiny path must to be exists too.
// ==============================================================================================================
Function DeCompress(CompressedFile, TargetPath: String): String;
var
   Zip: TUnZipper;
begin
    Try
    Zip := TUnZipper.Create;
	Result := '';
    if not FileExists(CompressedFile) Then
       begin
       Result := Format('The file %s not found!', [CompressedFile]);
       exit;
       end;


    if not DirectoryExists(TargetPath) Then
       begin
       Result := Format('The destiny path in %s does not exists!', [TargetPath]);
       exit;
       end;
    Zip.FileName := CompressedFile;
    Zip.OutputPath := TargetPath;
    Zip.Examine;
    Zip.UnZipAllFiles;

    Finally
        Zip.Free;
    end;
end;
      