// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.0
unit XMLPascal;

{$IFDEF FPC}
{$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  SysUtils, Classes;

type
  { TXMLAttribute }

  TXMLAttribute = class
  private
    FName: string;
    FValue: string;
  public
    constructor Create(const AName, AValue: string);

    property Name: string read FName write FName;
    property Value: string read FValue write FValue;
  end;

  { TXMLNode }

  TXMLNode = class
  private
    FNodeName: string;
    FAttributes: TList;
    FChildren: TList;
    FText: string;
    FParent: TXMLNode;

    function GetAttribute(const AName: string): string;
    procedure SetAttribute(const AName, AValue: string);
    function GetChild(const AName: string): TXMLNode;
  public
    constructor Create(const ANodeName: string = '');
    destructor Destroy; override;

    // Fluent creation
    function AddAttribute(const AName, AValue: string): TXMLNode;
    function AddChild(const AName: string): TXMLNode;
    function WithText(const AText: string): TXMLNode;
    function RemoveAttribute(const AName: string): TXMLNode;

    // Reading
    function Attribute(const AName: string): string;
    function Child(const AName: string): TXMLNode;
    function HasAttribute(const AName: string): boolean;
    function HasChild(const AName: string): boolean;

    // Manipulation
    procedure Clear;
    procedure RemoveChild(const AChild: TXMLNode);
    procedure DeleteAttribute(const AName: string);

    function ToXML(Indent: boolean = True; Level: integer = 0): string;

    property NodeName: string read FNodeName write FNodeName;
    property Text: string read FText write FText;
    property Attributes[const AName: string]: string
      read GetAttribute write SetAttribute;
    property Children: TList read FChildren; // for manual iteration if needed
  end;

  { TXMLNodes }

  TXMLNodes = class
  private
    FList: TList;
    function GetItem(Index: Integer): TXMLNode;
  public
    constructor Create;
    destructor Destroy; override;
    function Count: Integer;
    property Items[Index: Integer]: TXMLNode read GetItem; default;
    property List: TList read FList;
  end;

  { TXML }

  TXML = class
  private
    FRoot: TXMLNode;
    FVersion: string;
    FEncoding: string;
  public
    constructor Create;
    destructor Destroy; override;

    function CreateRoot(const RootName: string): TXMLNode;
    function GetNode(const APath: string): TXMLNode;
    function GetNodes(const APath: string): TXMLNodes;
    function GetText(const APath: string): string;
    function GetAttribute(const APath: string): string;

    // Loading (supports large files via stream)
    procedure LoadFromString(const XML: string);
    procedure LoadFromStream(Stream: TStream);
    procedure LoadFromFile(const FileName: string);

    // Saving
    function SaveToString(AllowHeader: boolean = True): string;
    procedure SaveToFile(const FileName: string);

    property Root: TXMLNode read FRoot;
    property Version: string read FVersion write FVersion;
    property Encoding: string read FEncoding write FEncoding;
  end;

function EscapeXML(const S: string): string;
function UnescapeXML(const S: string): string;
procedure ParseElement(var P: pchar; Parent: TXMLNode);

const
  sLineBreak = #13#10;

implementation

function IfThen(const ATest: boolean; ATrue: string; AFalse: string): string;
begin
  if ATest then
    Result := ATrue
  else
    Result := AFalse;
end;

function EscapeXML(const S: string): string;
begin
  Result := S;
  Result := StringReplace(Result, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&apos;', [rfReplaceAll]);
end;

function UnescapeXML(const S: string): string;
begin
  Result := S;
  Result := StringReplace(Result, '&lt;', '<', [rfReplaceAll]);
  Result := StringReplace(Result, '&gt;', '>', [rfReplaceAll]);
  Result := StringReplace(Result, '&quot;', '"', [rfReplaceAll]);
  Result := StringReplace(Result, '&apos;', '''', [rfReplaceAll]);
  Result := StringReplace(Result, '&amp;', '&', [rfReplaceAll]);
end;

procedure ParseElement(var P: pchar; Parent: TXMLNode);
var
  Node: TXMLNode;
  TagName, AttrName, AttrValue: string;
  Quote: char;
  Start: pchar;
  IsSelfClosing: boolean;
begin
  while P^ <> #0 do
  begin
    // Skip whitespace
    while (P^ <= ' ') and (P^ <> #0) do Inc(P);
    if P^ = #0 then Break;

    if P^ <> '<' then
    begin
      // Text content (raro nesse arquivo)
      Start := P;
      while (P^ <> '<') and (P^ <> #0) do Inc(P);
      if P > Start then
        Parent.Text := Parent.Text + Trim(UnescapeXML(Copy(Start, 1, P - Start)));
      Continue;
    end;

    Inc(P); // skip '<'

    // Closing tag
    if P^ = '/' then
    begin
      while (P^ <> '>') and (P^ <> #0) do Inc(P);
      if P^ = '>' then Inc(P);
      Break;
    end;

    // Tag name
    Start := P;
    while (P^ <> #0) and (P^ > ' ') and (P^ <> '>') and (P^ <> '/') do Inc(P);
    TagName := Copy(Start, 1, P - Start);

    if TagName = '' then Exit;

    Node := Parent.AddChild(TagName);

    // Skip whitespace after tag name
    while (P^ <= ' ') and (P^ <> #0) do Inc(P);

    // ==================== ATRIBUTOS (parte mais crítica) ====================
    while (P^ <> #0) and (P^ <> '>') and (P^ <> '/') do
    begin
      // Skip whitespace before attribute name
      while (P^ <= ' ') and (P^ <> #0) do Inc(P);
      if (P^ = '>') or (P^ = '/') or (P^ = #0) then Break;

      // Read attribute name
      Start := P;
      while (P^ <> #0) and (P^ <> '=') and (P^ > ' ') do Inc(P);
      AttrName := Trim(Copy(Start, 1, P - Start));

      if (AttrName = '') or (P^ <> '=') then
      begin
        // Se não encontrou '=', pula até o próximo espaço ou > /
        while (P^ <> #0) and (P^ > ' ') and (P^ <> '>') and (P^ <> '/') do Inc(P);
        Continue;
      end;

      Inc(P); // skip '='

      // Skip whitespace after =
      while (P^ <= ' ') and (P^ <> #0) do Inc(P);

      // Read value (quoted)
      AttrValue := '';
      if (P^ = '"') or (P^ = '''') then
      begin
        Quote := P^;
        Inc(P);
        Start := P;
        while (P^ <> #0) and (P^ <> Quote) do Inc(P);
        AttrValue := Copy(Start, 1, P - Start);
        if P^ = Quote then Inc(P);
      end
      else
      begin
        // valor sem aspas (raro)
        Start := P;
        while (P^ <> #0) and (P^ > ' ') and (P^ <> '>') and (P^ <> '/') do Inc(P);
        AttrValue := Copy(Start, 1, P - Start);
      end;

      if AttrName <> '' then
        Node.AddAttribute(AttrName, UnescapeXML(AttrValue));

      // Skip whitespace after attribute value
      while (P^ <= ' ') and (P^ <> #0) do Inc(P);
    end;

    // Self-closing tag?
    IsSelfClosing := (P^ = '/');
    if IsSelfClosing then
    begin
      Inc(P);
      while (P^ <= ' ') and (P^ <> #0) do Inc(P);
    end;

    if P^ = '>' then Inc(P);

    // Recurse only if not self-closing
    if not IsSelfClosing then
      ParseElement(P, Node);
  end;
end;

{ TXMLAttribute }

constructor TXMLAttribute.Create(const AName, AValue: string);
begin
  FName := AName;
  FValue := AValue;
end;

{ TXMLNode }

constructor TXMLNode.Create(const ANodeName: string);
begin
  FNodeName := ANodeName;
  FAttributes := TList.Create;
  FChildren := TList.Create;
end;

destructor TXMLNode.Destroy;
begin
  Clear;
  FAttributes.Free;
  FChildren.Free;
  inherited;
end;

procedure TXMLNode.Clear;
var
  i: integer;
begin
  for i := 0 to FAttributes.Count - 1 do
    TXMLAttribute(FAttributes[i]).Free;
  FAttributes.Clear;

  for i := 0 to FChildren.Count - 1 do
    TXMLNode(FChildren[i]).Free;
  FChildren.Clear;

  FText := '';
end;

function TXMLNode.AddAttribute(const AName, AValue: string): TXMLNode;
var
  Attr: TXMLAttribute;
begin
  Attr := TXMLAttribute.Create(AName, AValue);
  FAttributes.Add(Attr);
  Result := Self;
end;

function TXMLNode.AddChild(const AName: string): TXMLNode;
begin
  Result := TXMLNode.Create(AName);
  Result.FParent := Self;
  FChildren.Add(Result);
end;

function TXMLNode.WithText(const AText: string): TXMLNode;
begin
  FText := AText;
  Result := Self;
end;

function TXMLNode.RemoveAttribute(const AName: string): TXMLNode;
begin
  Result := Self;
  DeleteAttribute(AName);
end;

function TXMLNode.Attribute(const AName: string): string;
begin
  Result := GetAttribute(AName);
end;

function TXMLNode.GetAttribute(const AName: string): string;
var
  i: integer;
  Attr: TXMLAttribute;
begin
  for i := 0 to FAttributes.Count - 1 do
  begin
    Attr := TXMLAttribute(FAttributes[i]);
    if CompareText(Attr.Name, AName) = 0 then
    begin
      Result := Attr.Value;
      Exit;
    end;
  end;
  Result := '';
end;

procedure TXMLNode.SetAttribute(const AName, AValue: string);
begin
  DeleteAttribute(AName);
  AddAttribute(AName, AValue);
end;

function TXMLNode.GetChild(const AName: string): TXMLNode;
var
  i: integer;
begin
  Result := nil;
  for i := 0 to FChildren.Count - 1 do
  begin
    Result := TXMLNode(FChildren[i]);
    if CompareText(Result.NodeName, AName) = 0 then
      Exit;
  end;
end;

function TXMLNode.Child(const AName: string): TXMLNode;
begin
  Result := GetChild(AName);
end;

function TXMLNode.HasAttribute(const AName: string): boolean;
begin
  Result := Attribute(AName) <> '';
end;

function TXMLNode.HasChild(const AName: string): boolean;
begin
  Result := GetChild(AName) <> nil;
end;

procedure TXMLNode.RemoveChild(const AChild: TXMLNode);
begin
  FChildren.Remove(AChild);
  AChild.Free;
end;

procedure TXMLNode.DeleteAttribute(const AName: string);
var
  i: integer;
  Attr: TXMLAttribute;
begin
  for i := 0 to FAttributes.Count - 1 do
  begin
    Attr := TXMLAttribute(FAttributes[i]);
    if CompareText(Attr.Name, AName) = 0 then
    begin
      Attr.Free;
      FAttributes.Delete(i);
      Exit;
    end;
  end;
end;

function TXMLNode.ToXML(Indent: boolean = True; Level: integer = 0): string;
var
  i: integer;
  Ind, AttrStr: string;
  Attr: TXMLAttribute;
begin
  Ind := '';
  if Indent then
    Ind := StringOfChar(' ', Level * 2);

  AttrStr := '';
  for i := 0 to FAttributes.Count - 1 do
  begin
    Attr := TXMLAttribute(FAttributes[i]);
    AttrStr := Format('%s %s="%s"', [AttrStr, Attr.Name, EscapeXML(Attr.Value)]);
  end;

  if (FChildren.Count = 0) and (FText = '') then
    Result := Format('%s<%s%s/>%s', [Ind, FNodeName, AttrStr,
      IfThen(Indent = True, sLineBreak, '')])
  else
  begin
    Result := Format('%s<%s%s>', [Ind, FNodeName, AttrStr]);
    if FText <> '' then
      Result := Result + EscapeXML(FText);

    for i := 0 to FChildren.Count - 1 do
      Result := Result + TXMLNode(FChildren[i]).ToXML(Indent, Level + 1);

    Result := Format('%s</%s>%s', [Result, FNodeName,
      IfThen(Indent = True, sLineBreak, '')]);
  end;
end;

{ TXMLNodes }

function TXMLNodes.GetItem(Index: Integer): TXMLNode;
begin
  if (Index >= 0) and (Index < FList.Count) then
      Result := TXMLNode(FList[Index])
    else
      Result := nil;
end;

constructor TXMLNodes.Create;
begin
  FList := TList.Create;
end;

destructor TXMLNodes.Destroy;
begin
  FList.Free;
  inherited Destroy;
end;

function TXMLNodes.Count: Integer;
begin
  Result := FList.Count;
end;

{ TXML }

constructor TXML.Create;
begin
  FVersion := '1.0';
  FEncoding := 'utf-8';
  FRoot := TXMLNode.Create('root');
end;

destructor TXML.Destroy;
begin
  FRoot.Free;
  inherited;
end;

function TXML.CreateRoot(const RootName: string): TXMLNode;
begin
  FRoot.Free;
  FRoot := TXMLNode.Create(RootName);
  Result := FRoot;
end;

function TXML.GetNode(const APath: string): TXMLNode;
var
  SL: TStringList;
  i: integer;
  Current: TXMLNode;
begin
  Result := nil;
  if (APath = '') or (FRoot = nil) then Exit;

  SL := TStringList.Create;
  try
    SL.Delimiter := '.';
    SL.StrictDelimiter := True;
    SL.DelimitedText := APath;

    Current := FRoot;

    // Se o primeiro segmento for o nome da raiz, pulamos ele
    if (SL.Count > 0) and (CompareText(SL[0], Current.NodeName) = 0) then
      SL.Delete(0);

    for i := 0 to SL.Count - 1 do
    begin
      if SL[i] = '' then Continue;
      Current := Current.Child(SL[i]);
      if Current = nil then Exit;
    end;

    Result := Current;
  finally
    SL.Free;
  end;
end;

function TXML.GetNodes(const APath: string): TXMLNodes;
var
  SL: TStringList;
  i: Integer;
  Current: TXMLNode;
  TargetName: string;
  j: Integer;
begin
  if (APath = '') or (FRoot = nil) then Exit;

  Result := TXMLNodes.Create;

  SL := TStringList.Create;
  try
    SL.Delimiter := '.';
    SL.StrictDelimiter := True;
    SL.DelimitedText := APath;

    if SL.Count = 0 then Exit;

    Current := FRoot;

    // Pula o nome da raiz se estiver no caminho
    if (SL.Count > 0) and (CompareText(SL[0], Current.NodeName) = 0) then
      SL.Delete(0);

    // Navega até o penúltimo nível
    for i := 0 to SL.Count - 2 do
    begin
      if SL[i] = '' then Continue;
      Current := Current.Child(SL[i]);
      if Current = nil then Exit;
    end;

    // Último segmento = nome do nó que queremos coletar
    TargetName := SL[SL.Count - 1];

    // Coleta TODOS os filhos com esse nome
    for j := 0 to Current.Children.Count - 1 do
    begin
      if CompareText(TXMLNode(Current.Children[j]).NodeName, TargetName) = 0 then
        Result.FList.Add(Current.Children[j]);
    end;

  finally
    SL.Free;
  end;
end;

function TXML.GetText(const APath: string): string;
var
  Node: TXMLNode;
begin
  Node := GetNode(APath);
  if Node <> nil then
    Result := Node.Text
  else
    Result := '';
end;

function TXML.GetAttribute(const APath: string): string;
var
  DotPos: integer;
  NodePath, AttrName: string;
  Node: TXMLNode;
begin
  Result := '';

  if APath = '' then Exit;

  DotPos := LastDelimiter('.', APath);

  // Se não tem ponto → assume que é atributo direto da raiz
  if DotPos = 0 then
  begin
    Result := FRoot.Attribute(APath);
    Exit;
  end;

  NodePath := Copy(APath, 1, DotPos - 1);
  AttrName := Copy(APath, DotPos + 1, MaxInt);

  Node := GetNode(NodePath);
  if Node <> nil then
    Result := Node.Attribute(AttrName);
end;

function TXML.SaveToString(AllowHeader: boolean): string;
begin
  if AllowHeader then
    Result := Format('<?xml version="%s" encoding="%s"?>%s',
      [FVersion, FEncoding, sLineBreak])
  else
    Result := '';
  Result := Format('%s%s', [Result, FRoot.ToXML]).Trim;
end;

procedure TXML.SaveToFile(const FileName: string);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Text := SaveToString;
    SL.SaveToFile(FileName);
  finally
    SL.Free;
  end;
end;

procedure TXML.LoadFromFile(const FileName: string);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(FS);
  finally
    FS.Free;
  end;
end;

procedure TXML.LoadFromStream(Stream: TStream);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromStream(Stream);
    LoadFromString(SL.Text);
  finally
    SL.Free;
  end;
end;

procedure TXML.LoadFromString(const XML: string);
var
  P: pchar;
  DummyRoot: TXMLNode;
begin
  FRoot.Clear;
  if XML = '' then Exit;

  P := PChar(XML);

  // Skip BOM
  if (Ord(P^) = $FEFF) then Inc(P);

  // Skip prolog (caso exista)
  if (P^ = '<') and (P[1] = '?') then
  begin
    while (P^ <> #0) and not ((P^ = '?') and (P[1] = '>')) do Inc(P);
    if (P^ = '?') then Inc(P, 2);
  end;

  // Skip whitespace inicial
  while (P^ <= ' ') and (P^ <> #0) do Inc(P);

  // Dummy root para capturar o verdadeiro root (<configs>)
  DummyRoot := TXMLNode.Create('__dummy__');
  try
    ParseElement(P, DummyRoot);

    if DummyRoot.Children.Count > 0 then
    begin
      FRoot.Free;
      FRoot := TXMLNode(DummyRoot.Children[0]);
      FRoot.FParent := nil;
      DummyRoot.Children.Extract(FRoot);
    end;
  finally
    DummyRoot.Free;
  end;
end;

end.
