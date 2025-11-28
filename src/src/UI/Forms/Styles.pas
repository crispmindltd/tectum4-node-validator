unit Styles;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.ListBox, FMX.Layouts, FMX.Graphics,
  FMX.Dialogs, FMX.Objects, FMX.StdCtrls;

const
  MOUSE_ENTER_COLOR = $FF323232;
  MOUSE_LEAVE_COLOR = $FF5A6773;
  MOUSE_DOWN_COLOR = $FF4285F4;
  SUCCESS_TEXT_COLOR = $FF2E9806;
  ERROR_TEXT_COLOR = $FFFC4949;

type
  TStylesForm = class(TForm)
    LNodeStyleBook: TStyleBook;
  private
    { Private declarations }
  public
    procedure OnCopyLayoutMouseEnter(Sender: TObject);
    procedure OnCopyLayoutMouseLeave(Sender: TObject);
    procedure OnCopyLayoutMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure OnCopyLayoutMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);

    procedure OnTokenItemMouseEnter(Sender: TObject);
    procedure OnTokenItemMouseLeave(Sender: TObject);
    procedure OnTokenItemMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure OnTokenItemMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
  end;

  procedure SetText(ATextComponent: TText; const AText: string); overload;
  procedure SetText(ATextComponent: TLabel; const AText: string); overload;

var
  StylesForm: TStylesForm;

implementation

{$R *.fmx}

procedure SetText(ATextComponent: TText; const AText: string);
begin
  ATextComponent.AutoSize := False;
  ATextComponent.Text := AText;
  ATextComponent.AutoSize := True;
end;

procedure SetText(ATextComponent: TLabel; const AText: string);
begin
  ATextComponent.AutoSize := False;
  ATextComponent.Text := AText;
  ATextComponent.AutoSize := True;
end;

{ TStylesForm }

procedure TStylesForm.OnCopyLayoutMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var
  Layout: TLayout;
  Svg: TPath;
  i: Integer;
begin
  if not (Sender is TLayout) then
    exit;

  Layout := Sender as TLayout;
  Svg := nil;
  for i := 0 to Layout.ChildrenCount - 1 do
    if Layout.Children[i] is TPath then
    begin
      Svg := Layout.Children[i] as TPath;
      break;
    end;
  if Assigned(Svg) then
  begin
    Svg.Fill.Color := MOUSE_DOWN_COLOR;
    Svg.Stroke.Color := MOUSE_DOWN_COLOR;
  end;
end;

procedure TStylesForm.OnCopyLayoutMouseEnter(Sender: TObject);
var
  Layout: TLayout;
  Svg: TPath;
  i: Integer;
begin
  if not (Sender is TLayout) then
    exit;

  Layout := Sender as TLayout;
  Svg := nil;
  for i := 0 to Layout.ChildrenCount - 1 do
    if Layout.Children[i] is TPath then
    begin
      Svg := Layout.Children[i] as TPath;
      break;
    end;
  if Assigned(Svg) then
  begin
    Svg.Fill.Color := MOUSE_ENTER_COLOR;
    Svg.Stroke.Color := MOUSE_ENTER_COLOR;
  end;
end;

procedure TStylesForm.OnCopyLayoutMouseLeave(Sender: TObject);
var
  Layout: TLayout;
  Svg: TPath;
  i: Integer;
begin
  if not (Sender is TLayout) then
    exit;

  Layout := Sender as TLayout;
  Svg := nil;
  for i := 0 to Layout.ChildrenCount - 1 do
    if Layout.Children[i] is TPath then
    begin
      Svg := Layout.Children[i] as TPath;
      break;
    end;
  if Assigned(Svg) then
  begin
    Svg.Fill.Color := MOUSE_LEAVE_COLOR;
    Svg.Stroke.Color := MOUSE_LEAVE_COLOR;
  end;
end;

procedure TStylesForm.OnCopyLayoutMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  OnCopyLayoutMouseEnter(Sender);
end;

procedure TStylesForm.OnTokenItemMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  Obj: TRectangle;
begin
  if not (Sender is TListBoxItem) then
    exit;
  Obj := nil;
  Obj := (Sender as TListBoxItem).FindStyleResource('RectangleStyle') as TRectangle;
  if Assigned(Obj) then
    Obj.Fill.Color := $994285F4;
end;

procedure TStylesForm.OnTokenItemMouseEnter(Sender: TObject);
var
  Obj: TRectangle;
begin
  if not (Sender is TListBoxItem) then
    exit;
  Obj := nil;
  Obj := (Sender as TListBoxItem).FindStyleResource('RectangleStyle') as TRectangle;
  if Assigned(Obj) then
    Obj.Fill.Color := $99E0E0E0;
end;

procedure TStylesForm.OnTokenItemMouseLeave(Sender: TObject);
var
  Obj: TRectangle;
begin
  if not (Sender is TListBoxItem) then
    exit;
  Obj := nil;
  Obj := (Sender as TListBoxItem).FindStyleResource('RectangleStyle') as TRectangle;
  if Assigned(Obj) then
    Obj.Fill.Color := $FFFFFFFF;
end;

procedure TStylesForm.OnTokenItemMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  OnTokenItemMouseEnter(Sender);
end;

end.
