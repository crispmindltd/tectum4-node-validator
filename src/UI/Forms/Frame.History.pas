unit Frame.History;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Objects;

const
  DateTimeLabelWidth = 150;
  BlockLabelWidth = 72;
  ValueLabelWidth = 110;
  IncomRectWidth = 70;
  TickerLabelWidth = 80;

type
  THistoryTransactionFrame = class(TFrame)
    Rectangle: TRectangle;
    DateTimeLabel: TLabel;
    BlockLabel: TLabel;
    AddressLabel: TLabel;
    HashLabel: TLabel;
    ValueLabel: TLabel;
    IncomRectangle: TRectangle;
    IncomText: TText;
    procedure FrameMouseLeave(Sender: TObject);
    procedure FrameMouseEnter(Sender: TObject);
    procedure FrameResize(Sender: TObject);
  private
    { Private declarations }
  public
    constructor Create(AOwner: TComponent; ADateTime: TDateTime; ABlock: Integer;
      AAddress, AHash, AValue: string; AIncom: Boolean);
    destructor Destroy; override;
  end;

implementation

{$R *.fmx}

{ THistoryTransactionFrame }

constructor THistoryTransactionFrame.Create(AOwner: TComponent; ADateTime: TDateTime;
  ABlock: Integer; AAddress, AHash, AValue: string; AIncom: Boolean);
begin
  inherited Create(AOwner);

  DateTimeLabel.Text := FormatDateTime('dd.mm.yyyy hh:mm:ss', ADateTime);
  BlockLabel.Text := ABlock.ToString;
  AddressLabel.Text := AAddress;
  HashLabel.Text := AHash;
  ValueLabel.Text := AValue;
  Name := AOwner.Name + AOwner.ComponentCount.ToString;
  if not AIncom then
  begin
    IncomRectangle.Fill.Color := $FFE85D42;
    IncomText.Text := 'OUT';
  end;
end;

destructor THistoryTransactionFrame.Destroy;
begin

  inherited;
end;

procedure THistoryTransactionFrame.FrameMouseEnter(Sender: TObject);
begin
  Rectangle.Fill.Kind := TBrushKind.Solid;
end;

procedure THistoryTransactionFrame.FrameMouseLeave(Sender: TObject);
begin
  Rectangle.Fill.Kind := TBrushKind.None;
end;

procedure THistoryTransactionFrame.FrameResize(Sender: TObject);
var
  Width: Single;
begin
  Width := Self.Width - DateTimeLabelWidth - BlockLabelWidth -
    ValueLabelWidth - IncomRectWidth - 80;
  AddressLabel.Width := Width * 0.4;
  HashLabel.Width := Width * 0.6;
end;

end.
