unit Frame.Ticker;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation;

type
  TTickerFrame = class(TFrame)
    RoundRect: TRoundRect;
    TickerText: TText;
    procedure RoundRectMouseEnter(Sender: TObject);
    procedure RoundRectMouseLeave(Sender: TObject);
  private
    FIsSelected: Boolean;

    function GetTicker: string;
    procedure SetSelected(AIsSelected: Boolean);
  public
    constructor Create(AOwner: TComponent; AName: string; ATokenID: Integer);
    destructor Destroy; override;

    property Selected: Boolean write SetSelected;
    property Ticker: string read GetTicker;
  end;

implementation

{$R *.fmx}

{ TTickerFrame }

constructor TTickerFrame.Create(AOwner: TComponent; AName: string;
  ATokenID: Integer);
begin
  inherited Create(AOwner);

  TickerText.Text := AName;
  TickerText.AutoSize := True;
  Self.Width := TickerText.Width + 20;
  Name := 'TickerItem' + AName.Replace(' ', '');
  Tag := ATokenID;
  if (AName = 'Search results') or (AName = 'Tectum') then
    Align := TAlignLayout.MostLeft;
  SetSelected(False);
end;

destructor TTickerFrame.Destroy;
begin

  inherited;
end;

function TTickerFrame.GetTicker: string;
begin
  Result := TickerText.Text;
end;

procedure TTickerFrame.RoundRectMouseEnter(Sender: TObject);
begin
  TickerText.TextSettings.FontColor := $FFFFFFFF;
  if not FIsSelected then
    RoundRect.Fill.Color := $FF489FE5;
end;

procedure TTickerFrame.RoundRectMouseLeave(Sender: TObject);
begin
  if not FIsSelected then
  begin
    TickerText.TextSettings.FontColor := $FD000000;
    RoundRect.Fill.Color := $FFF3F3F3;
  end;
end;

procedure TTickerFrame.SetSelected(AIsSelected: Boolean);
begin
  FIsSelected := AIsSelected;
  if AIsSelected then
  begin
    RoundRect.Fill.Color := $FF0072D5;
    TickerText.TextSettings.FontColor := $FFFFFFFF;
  end else
  begin
    TickerText.TextSettings.FontColor := $FD000000;
    RoundRect.Fill.Color := $FFF3F3F3;
  end;

  if TickerText.Text = 'Search results' then
    Visible := FIsSelected;
end;

end.
