unit Desktop.Controls;

interface

uses
  System.Types,
  System.SysUtils,
  System.Math,
  FMX.Types,
  FMX.Graphics,
  FMX.Controls;

procedure ControlsFlexWidth(const Controls: array of TControl; const Weights: array of Single; AlignedControl: TControl);
function GetContentRect(Control: TControl): TRectF;

implementation

procedure ControlsFlexWidth(const Controls: array of TControl; const Weights: array of Single; AlignedControl: TControl);
begin

  var R:=AlignedControl.Padding.PaddingRect(AlignedControl.LocalRect);

  var M: Single:=0;

  for var C in Controls do if Assigned(C) then M:=M+C.Margins.Left+C.Margins.Right;

  var L: Single:=R.Left;

  for var I:=0 to Min(High(Controls),High(Weights)) do
  begin

    var B:=TRectF.Empty;

    if Assigned(Controls[I]) then
    begin
      L:=L+Controls[I].Margins.Left;
      B:=Controls[I].BoundsRect;
    end;

    var W:=Round(Weights[I]*(R.Width-M));

    if Assigned(Controls[I]) then
    begin
      Controls[I].SetBounds(L,B.Top,W,B.Height);
      L:=L+Controls[I].Margins.Right;
    end;

    L:=L+W;

  end;

end;

function GetContentRect(Control: TControl): TRectF;
begin

  Result:=TRectF.Empty;

  for var C in Control.Controls do
  if C.Visible then
  if Result.IsEmpty then
    Result:=C.BoundsRect
  else
    Result:=UnionRect(Result,C.BoundsRect);

  Result.Height:=Result.Height+Control.Padding.Bottom;

end;

end.
