// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.0
unit FMXHelpers;

interface

uses
  FMX.Layouts, FMX.Grid, FMX.Types, System.SysUtils;

type
  TVertScrollBoxHelper = class helper for TVertScrollBox
  public
    procedure Clear;
  end;

  THorzScrollBoxHelper = class helper for THorzScrollBox
  public
    procedure Clear;
  end;

  TStringGridHelper = class helper for TStringGrid
  public
    function ColumnByName(value: string): TColumn;
    function ColumnIndexByName(value: string): integer;
  end;
  
  function isEmptyJSON(aJSON: string): boolean;

implementation

{ TStringGridHelper }

function TStringGridHelper.ColumnByName(value: string): TColumn;
var
  I: integer;
begin
  Result := nil;
  for I := 0 to pred(self.ColumnCount) do
    if UpperCase(self.Columns[I].Name) = UpperCase(value) then
    begin
      Result := self.Columns[I];
      break;
    end;
end;

function TStringGridHelper.ColumnIndexByName(value: string): integer;
var
  I: integer;
begin
  Result := 0;
  for I := 0 to pred(self.ColumnCount) do
    if UpperCase(self.Columns[I].Name) = UpperCase(value) then
    begin
      Result := I;
      break;
    end;
end;

{ TVertScrollBoxHelper }

procedure TVertScrollBoxHelper.Clear;
var
  I: integer;
begin
  for I := pred(self.Content.ChildrenCount) downto 0 do
    self.Content.Children.Items[I].DisposeOf;
end;

{ THorzScrollBoxHelper }

procedure THorzScrollBoxHelper.Clear;
var
  I: integer;
begin
  for I := pred(self.Content.ChildrenCount) downto 0 do
    self.Content.Children.Items[I].DisposeOf;
end;

function isEmptyJSON(aJSON: string): boolean;
begin
  Result := (aJSON = '[]') or (aJSON = '{}') or (aJSON = '');
end;

end.
