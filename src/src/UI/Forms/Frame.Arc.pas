unit Frame.Arc;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  System.Math,
  FMX.Types,
  FMX.Graphics,
  FMX.Controls,
  FMX.Forms,
  FMX.Objects,
  FMX.Ani;

type
  TArcFrame = class(TFrame)
    Circle: TCircle;
    Arc: TArc;
    StartAngleAnimation: TFloatAnimation;
    CancelImage: TImage;
    EndAngleAnimation: TFloatAnimation;
    LoopAnimation: TFloatAnimation;
    procedure CirclePaint(Sender: TObject; Canvas: TCanvas;
      const ARect: TRectF);
    procedure CircleClick(Sender: TObject);
  private
    FOnCancel: TNotifyEvent;
    function GetEndAngle: Single;
    function GetStartAngle: Single;
    procedure SetEndAngle(const Value: Single);
    procedure SetStartAngle(const Value: Single);
    function GetAnimateStartAngle: Boolean;
    function GetCanCancel: Boolean;
    procedure SetAnimateStartAngle(const Value: Boolean);
    procedure SetAnimateLoop(const Value: Boolean);
    procedure SetCanCancel(const Value: Boolean);
  public
    procedure Reset;
    procedure DoCancel;
    procedure AfterConstruction; override;
    procedure AnimateEndAngleTo(Value: Single);
    property StartAngle: Single read GetStartAngle write SetStartAngle;
    property EndAngle: Single read GetEndAngle write SetEndAngle;
    property AnimateStartAngle: Boolean read GetAnimateStartAngle write SetAnimateStartAngle;
    property AnimateLoop: Boolean read GetAnimateStartAngle write SetAnimateLoop;
    property CanCancel: Boolean read GetCanCancel write SetCanCancel;
    property OnCancel: TNotifyEvent read FOnCancel write FOnCancel;
  end;

implementation

{$R *.fmx}

procedure TArcFrame.Reset;
begin
  AnimateStartAngle:=False;
  StartAngle:=-90;
end;

procedure TArcFrame.AfterConstruction;
begin
  Arc.Visible:=False;
  Reset;
end;

function TArcFrame.GetAnimateStartAngle: Boolean;
begin
  Result:=StartAngleAnimation.Running;
end;

function TArcFrame.GetCanCancel: Boolean;
begin
  Result:=CancelImage.Visible;
end;

function TArcFrame.GetEndAngle: Single;
begin
  Result:=Arc.EndAngle;
end;

function TArcFrame.GetStartAngle: Single;
begin
  Result:=Arc.StartAngle;
end;

procedure TArcFrame.SetAnimateStartAngle(const Value: Boolean);
begin
  if Value<>AnimateStartAngle then
  if Value then
  begin
    StartAngleAnimation.StartValue:=StartAngle;
    StartAngleAnimation.StopValue:=StartAngleAnimation.StartValue+360;
    StartAngleAnimation.Start;
  end else
    StartAngleAnimation.StopAtCurrent;
end;

procedure TArcFrame.SetAnimateLoop(const Value: Boolean);
begin
  if Value<>AnimateLoop then
  begin
    AnimateStartAngle:=Value;
    if Value then
      LoopAnimation.Start
    else
      LoopAnimation.StopAtCurrent;
  end;
end;

procedure TArcFrame.SetCanCancel(const Value: Boolean);
begin
  CancelImage.Visible:=Value;
end;

procedure TArcFrame.SetEndAngle(const Value: Single);
begin
  Arc.EndAngle:=Value;
  Circle.Repaint;
end;

procedure TArcFrame.SetStartAngle(const Value: Single);
begin
  Arc.StartAngle:=Value;
  Circle.Repaint;
end;

procedure TArcFrame.CircleClick(Sender: TObject);
begin
  DoCancel;
end;

procedure TArcFrame.DoCancel;
begin
  if CanCancel and Assigned(FOnCancel) then FOnCancel(Self);
end;

procedure TArcFrame.AnimateEndAngleTo(Value: Single);
begin
  EndAngleAnimation.StopValue:=Value;
  EndAngleAnimation.Start;
end;

procedure TArcFrame.CirclePaint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
var
  R1,R2: Single;
  P: TPathData;
  AEndAngle: Single;
begin

  AEndAngle:=EnsureRange(EndAngle,-360,360);

  if AEndAngle=0 then Exit;

  R1:=Min(ARect.Height,ARect.Width)/2;
  R2:=R1-Arc.Stroke.Thickness;

  P:=TPathData.Create;

  P.AddArc(ARect.CenterPoint,PointF(R1,R1),StartAngle,AEndAngle);
  P.AddArc(ARect.CenterPoint,PointF(R2,R2),AEndAngle+StartAngle,-AEndAngle);
  P.ClosePath;

  Canvas.FillPath(P,Arc.Opacity,Arc.Stroke);

  P.Free;

end;

end.
