// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki

unit Log.TextFile;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes;

type

  { TLog }

  TLog = class(TThread)
  private
    FFileName: string;
    FSection: string;
    FValue: string;
  protected
    procedure Execute; override;
  public
    constructor Create(ASection, AValue, AFileName: string);
    class procedure Log(ASection, AValue: string; AFileName: string = 'log.txt');
    destructor Destroy; override;
  end;

implementation

{ TLog }

constructor TLog.Create(ASection, AValue, AFileName: string);
begin
  inherited Create(False);
  FreeOnTerminate := True;
  FFileName := AFileName;
  FSection := ASection;
  FValue := AValue;
end;

destructor TLog.Destroy;
begin

  inherited Destroy;
end;

procedure TLog.Execute;
var
  FLogFile: Text;
  logdata: string;
  Confirma: boolean;
begin
  logdata := FormatDateTime('dd/mm/yyyy hh:nn:ss', Now) + ' | ' +
    FSection + ' | ' + FValue;

  Confirma := False;
  while not Confirma do
  try
    try
      AssignFile(FLogFile, FFileName);
      if FileExists(FFileName) then
        Append(FLogFile)
      else
        Rewrite(FLogFile);

      Writeln(FlogFile, logdata);
      Confirma := True;
    except
      Confirma := False;
    end;
  finally
    CloseFile(FlogFile);
  end;
end;

class procedure TLog.Log(ASection, AValue: string; AFileName: string);
begin
  Create(ASection, AValue, AFileName);
end;

end.
