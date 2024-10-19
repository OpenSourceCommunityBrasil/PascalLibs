//====================================================================================================
//  Wanderson S Fróes - Wandersobfroea@outlook.com
//  Ajusta a coluna no grid passados como parâmetros para ter a propriedade de auto ajustar o tamanho 
//         da coluna.
//----------------------------------------------------------------------------------------------------
//  Turn the column in the grid passed as argument in a autofit column that self adjust it's size 
//       on Form resize.
//====================================================================================================
//
//Parameters: 
//  DBGrid = The TDbGrid that contains the column in second argument.
//  ColNumberToAutoFit: Col number that will be autofit on resize.
//====================================================================================================
//
procedure AutoFitDbGridCol(DBGrid: TDBGrid; ColNumberToAutoFit: Integer);
var
  idx,  
  ColsWidth,  
  DBGridWidth: Integer;
begin
  ColsWidth          :=0;
  DBGridWidth        :=DBGrid.Width;
  
  for idx := 0 to Pred(DBGrid.Columns.Count) do begin
      if (DBGrid.Columns.Items[idx].Visible) then
          if (DBGrid.Columns.Items[idx].Tag = 0) then
            if (i <> ColNumberToAutoFit) then
              Inc(ColsWidth, DBGrid.Columns.Items[idx].Width);
  end;
  if (ColNumberToAutoFit = -1) then
      ColNumberToAutoFit := 1;

  DBGrid.Columns.Items[ColNumberToAutoFit].Width := DBGridWidth - ColsWidth;
end;
