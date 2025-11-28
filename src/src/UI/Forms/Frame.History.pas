unit Frame.History;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Objects, Desktop.Controls,
  FMX.Layouts, Blockchain.Types, Blockchain.Utils;

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
    AddressFromLabel: TLabel;
    HashLabel: TLabel;
    ValueLabel: TLabel;
    IncomRectangle: TRectangle;
    IncomText: TText;
    AddressToLabel: TLabel;
    IncomLayout: TLayout;
    procedure FrameMouseLeave(Sender: TObject);
    procedure FrameMouseEnter(Sender: TObject);
    procedure RectangleResized(Sender: TObject);
  private
    FTrx: TTransactionInfo;
  public
    procedure UpdateTransaction;
    procedure SetData(const Trx: TTransactionInfo; Incom: Boolean);
    property Transaction: TTransactionInfo read FTrx;
  end;

implementation

{$R *.fmx}

{ THistoryTransactionFrame }

procedure THistoryTransactionFrame.SetData(const Trx: TTransactionInfo; Incom: Boolean);
begin

  Name := '';

  FTrx:=Trx;

  DateTimeLabel.Text := FormatDateTime('dd.mm.yyyy hh:nn:ss', Trx.DateTime.ToDateTime(False));
  BlockLabel.Text := Trx.Id.ToString;
  AddressFromLabel.Text := Trx.AddressFrom;
  AddressToLabel.Text := Trx.AddressTo;
  HashLabel.Text := Trx.Hash;
  ValueLabel.Text := AmountToStr(Trx.Amount, '', Trx.Decimals);

  if not Incom then
  begin
    IncomRectangle.Fill.Color := $FFE85D42;
    IncomText.Text := 'OUT';
  end else begin
    IncomRectangle.Fill.Color := $FF0F9A62;
    IncomText.Text := 'IN';
  end;

  IncomText.TextSettings.FontColor := IncomRectangle.Fill.Color;

end;

procedure THistoryTransactionFrame.FrameMouseEnter(Sender: TObject);
begin
  Rectangle.Fill.Kind := TBrushKind.Solid;
end;

procedure THistoryTransactionFrame.FrameMouseLeave(Sender: TObject);
begin
  Rectangle.Fill.Kind := TBrushKind.None;
end;

procedure THistoryTransactionFrame.RectangleResized(Sender: TObject);
begin
  ControlsFlexWidth([DateTimeLabel,BlockLabel,AddressFromLabel,AddressToLabel,
    HashLabel,ValueLabel,IncomLayout],[0.1,0.05,0.2,0.2,0.3,0.1,0.05],Self);
end;

procedure THistoryTransactionFrame.UpdateTransaction;
begin
  if Length(FTrx.Rewards)=0 then
//    FTrx.Rewards:=GetRwd(FTrx.RewardId);
end;

end.
