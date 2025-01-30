unit Desktop.Controls;

interface

uses
  System.Types,
  System.SysUtils,
  System.Math,
  FMX.Types,
  FMX.Graphics,
  FMX.Controls,
  FMX.Layouts,
  FMX.ListBox,
  FMX.InertialMovement;

function ControlMoved(ScrollBox: TCustomScrollBox): Boolean;
procedure StopControlMoved(ScrollBox: TCustomScrollBox);
procedure ControlScrollTo(ScrollBox: TCustomScrollBox; X,Y: Single; Animated: Boolean=True);
procedure ShowControl(Control: TControl; ScrollBox: TCustomScrollBox; const Padding: TRectF; Animated: Boolean=True); overload;
procedure ShowControl(Control: IControl; ScrollBox: TCustomScrollBox; const Padding: TRectF; Animated: Boolean=True); overload;
procedure ControlScale(Control: TControl; PositionScale,WidthScale: Single; const AlignedRect: TRectF); overload;
procedure ControlScale(Control: TControl; PositionScale,WidthScale: Single; AlignedControl: TControl); overload;
procedure ControlsScale(const Controls: array of TControl; const WidthScales: array of Single; AlignedControl: TControl);
procedure ControlsFlexWidth(const Controls: array of TControl; const Weights: array of Single; AlignedControl: TControl);
procedure ControlClick(Control: TControl);
procedure ControlToFront(Control: TControl);
function GetContentRect(Control: TControl): TRectF;
procedure ControlDisableDisappear(const Control: TControl);
procedure FixedTopAlign(Control: TControl);
procedure ControlRealign(Control: TControl);
procedure SetFontWeight(TextSettings: ITextSettings; Weight: TFontWeight);
procedure SetMediumFont(TextSettings: ITextSettings); overload;
procedure SetMediumFont(const TextsSettings: array of ITextSettings); overload;

implementation

type
  TAniCalculationsAccess = class(TAniCalculations);

function ControlMoved(ScrollBox: TCustomScrollBox): Boolean;
begin
  Result:=False;
  if Assigned(ScrollBox) then Result:=ScrollBox.AniCalculations.Moved and
    TAniCalculationsAccess(ScrollBox.AniCalculations).Enabled and
   (ScrollBox.AniCalculations.LastTimeCalc>0);
end;

procedure StopControlMoved(ScrollBox: TCustomScrollBox);
begin
  ScrollBox.AniCalculations.Animation:=False;
  ScrollBox.AniCalculations.Animation:=True;
end;

procedure ControlScrollTo(ScrollBox: TCustomScrollBox; X,Y: Single; Animated: Boolean);
var A: TAniCalculations.TTarget;
begin

  A.TargetType:=TAniCalculations.TTargetType.Other;
  A.Point:=PointF(X,Y);

  if Animated then
  begin
    StopControlMoved(ScrollBox);
    TAniCalculationsAccess(ScrollBox.AniCalculations).MouseTarget:=A;
  end else
    ScrollBox.AniCalculations.ViewportPosition:=A.Point;

end;

procedure ShowControl(Control: TControl; ScrollBox: TCustomScrollBox; const Padding: TRectF; Animated: Boolean);
begin

  var R:=ScrollBox.AbsoluteToLocal(Control.AbsoluteRect);

  var L:=ScrollBox.LocalRect;

  L.Inflate(-Padding.Left,-Padding.Top,-Padding.Right,-Padding.Bottom);

  if R.Top<L.Top then
    ControlScrollTo(ScrollBox,0,ScrollBox.ViewportPosition.Y-(L.Top-R.Top),Animated)
  else if R.Bottom>L.Bottom then
    ControlScrollTo(ScrollBox,0,ScrollBox.ViewportPosition.Y-(L.Bottom-R.Bottom),Animated);

end;

procedure ShowControl(Control: IControl; ScrollBox: TCustomScrollBox; const Padding: TRectF; Animated: Boolean=True);
begin
  if Assigned(Control) then ShowControl(TControl(Control.GetObject),ScrollBox,Padding,Animated)
end;

procedure ControlScale(Control: TControl; PositionScale,WidthScale: Single;
  const AlignedRect: TRectF);
begin
  if Assigned(Control) then
  begin
    Control.Width:=Round(AlignedRect.Width*WidthScale);
    Control.Position.X:=AlignedRect.Left+Trunc(AlignedRect.Width*PositionScale);
  end;
end;

procedure ControlScale(Control: TControl; PositionScale,WidthScale: Single;
  AlignedControl: TControl);
begin
  ControlScale(Control,PositionScale,WidthScale,AlignedControl.Padding.
    PaddingRect(AlignedControl.LocalRect));
end;

procedure ControlsScale(const Controls: array of TControl; const WidthScales: array of Single;
  AlignedControl: TControl);
var
  R: TRectF;
  S,M: Single;
begin

  R:=AlignedControl.Padding.PaddingRect(AlignedControl.LocalRect);

  M:=0;
  for var I:=0 to High(WidthScales) do M:=M+WidthScales[I];
  M:=(1-M)/High(WidthScales);

  S:=0;
  for var I:=0 to Min(High(Controls),High(WidthScales)) do
  begin
    ControlScale(Controls[I],S,WidthScales[I],R);
    S:=S+WidthScales[I]+M;
  end;

end;

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

type
  TControlAccess = class(TControl);

procedure ControlClick(Control: TControl);
begin
  TControlAccess(Control).Click;
end;

procedure ControlToFront(Control: TControl);
begin
  Control.BringToFront;
  Control.Repaint;
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

procedure ControlDisableDisappear(const Control: TControl);
begin
  Control.DisableDisappear := True;
  for var I:=0 to Control.ControlsCount-1 do
    ControlDisableDisappear(Control.Controls[I]);
end;

procedure FixedTopAlign(Control: TControl);
begin

  Control.BeginUpdate;

  var Y: Single:=10000;

  for var C in Control.Controls do
  begin
    C.Position.Y:=Y;
    Y:=Y+10;
  end;

  Control.EndUpdate;

end;

procedure ControlRealign(Control: TControl);
begin
  TControlAccess(Control).DoRealign;
end;

function SetStyleWeight(const Style: TFontStyleExt; Weight: TFontWeight): TFontStyleExt; inline;
begin
  Result:=Style;
  Result.Weight:=Weight;
end;

procedure SetFontWeight(TextSettings: ITextSettings; Weight: TFontWeight);
begin
  TextSettings.TextSettings.Font.StyleExt:=SetStyleWeight(TextSettings.TextSettings.Font.StyleExt,Weight);
end;

procedure SetMediumFont(TextSettings: ITextSettings);
begin
  SetFontWeight(TextSettings,TFontWeight.Medium);
end;

procedure SetMediumFont(const TextsSettings: array of ITextSettings);
begin
  for var TextSettings in TextsSettings do SetMediumFont(TextSettings);
end;

end.
