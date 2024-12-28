unit Frame.PageNum;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, Styles;

type
  TPageNumFrame = class(TFrame)
    PageNumText: TText;
    procedure FrameMouseEnter(Sender: TObject);
    procedure FrameMouseLeave(Sender: TObject);
  private
  public
    constructor Create(AOwner: TComponent; ANumber: Integer;
      AIsSelected: Boolean = False);
    destructor Destroy; override;
  end;

implementation

{$R *.fmx}

{ TPageNumFrame }

constructor TPageNumFrame.Create(AOwner: TComponent; ANumber: Integer;
  AIsSelected: Boolean);
begin
  inherited Create(AOwner);

  if ANumber > 0 then
  begin
    Name := 'TickerItem' + ANumber.ToString;
    PageNumText.Text := ANumber.ToString;
    if AIsSelected then
      PageNumText.TextSettings.FontColor := $FF4285F4;
  end else
  begin
    Name := 'Ellipsis' + AOwner.ComponentCount.ToString;
    PageNumText.Text := '...';
    Self.Cursor := crDefault;
    Self.OnMouseEnter := nil;
    Self.OnMouseLeave := nil;
  end;

  PageNumText.AutoSize := True;
  Self.Width := PageNumText.Width + 10;
  Self.Tag := ANumber;
end;

destructor TPageNumFrame.Destroy;
begin

  inherited;
end;

procedure TPageNumFrame.FrameMouseEnter(Sender: TObject);
begin
  if PageNumText.TextSettings.FontColor = MOUSE_LEAVE_COLOR then
    PageNumText.TextSettings.FontColor := MOUSE_ENTER_COLOR;
end;

procedure TPageNumFrame.FrameMouseLeave(Sender: TObject);
begin
  if PageNumText.TextSettings.FontColor = MOUSE_ENTER_COLOR then
    PageNumText.TextSettings.FontColor := MOUSE_LEAVE_COLOR;
end;

end.
