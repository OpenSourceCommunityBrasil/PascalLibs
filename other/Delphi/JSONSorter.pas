// Maiores Informações
// https://github.com/OpenSourceCommunityBrasil/PascalLibs/wiki
// version 1.0
unit JSONSorter;

interface

uses
  System.JSON, System.Classes, System.SysUtils, System.Generics.Collections,
  System.Generics.Defaults;

type
  TSortOrder = (soAscending, soDescending);

  TJSONArraySorter = class helper for TJSONArray
  public
    procedure Sort(AKeyElement: string; AOrder: TSortOrder = soAscending);
  end;

implementation

{ TJSONArraySorter }

procedure TJSONArraySorter.Sort(AKeyElement: string; AOrder: TSortOrder);
var
  cntr: Integer;
  elementList: TList<TJSONValue>;
begin
  // Sort the elements. We have to sort them because they change constantly
  elementList := TList<TJSONValue>.Create;
  try
    // Get the elements
    for cntr := 0 to self.Count - 1 do
      elementList.Add(self.Items[cntr]);
    elementList.Sort(TComparer<TJSONValue>.Construct(
      function(const Left, Right: TJSONValue): Integer
      var
        leftObject: TJSONObject;
        rightObject: TJSONObject;
      begin
        // You should do some error checking here and not just cast blindly
        leftObject := TJSONObject(Left);
        rightObject := TJSONObject(Right);
        // Compare here. I am just comparing the ToStrings but you will probably
        // want to compare something else.
        if AOrder = soAscending then
          Result := TComparer<string>.Default.Compare(leftObject.Get(AKeyElement)
            .JsonValue.Value, rightObject.Get(AKeyElement).JsonValue.Value)
        else
          Result := TComparer<string>.Default.Compare(rightObject.Get(AKeyElement)
            .JsonValue.Value, leftObject.Get(AKeyElement).JsonValue.Value);
      end));
    self.SetElements(elementList);
  except
    on E: Exception do
    begin
      // We only free the element list when there is an exception because SetElements
      // takes ownership of the list.
      elementList.Free;
      raise;
    end;
  end;
end;

end.
