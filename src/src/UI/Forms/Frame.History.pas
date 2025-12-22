unit Frame.History;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Objects, Desktop.Controls, Math,
  FMX.Layouts, App.Intf, Blockchain.Types, Blockchain.Utils;

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
    procedure SetData(const Trx: TTransactionInfo; Incom: Boolean; IsUserTEC: Boolean = False);
    property Transaction: TTransactionInfo read FTrx;
  end;

implementation

{$R *.fmx}

{ THistoryTransactionFrame }

procedure THistoryTransactionFrame.SetData(const Trx: TTransactionInfo; Incom: Boolean;
  IsUserTEC: Boolean);
begin

  Name := '';

  FTrx:=Trx;

  DateTimeLabel.Text := FormatDateTime('dd.mm.yyyy hh:nn:ss', Trx.DateTime.ToDateTime(False));
  BlockLabel.Text := Trx.Id.ToString;
  AddressFromLabel.Text := Trx.AddressFrom;
  AddressToLabel.Text := Trx.AddressTo;
  HashLabel.Text := Trx.Hash;
  ValueLabel.Text := AmountToStr(Trx.Amount, '', Trx.Decimals);

  if Trx.TxType = 'mint' then
    IncomRectangle.Fill.Color := $FF5B99FF
  else begin
    if not Incom then
      IncomRectangle.Fill.Color := $FFE85D42
    else
      IncomRectangle.Fill.Color := $FF0F9A62;

    if Trx.TxType = 'transfer' then
      IncomText.Text := 'TRX'
    else if Trx.TxType = 'burn' then
    begin
      var TokenData := AppCore.GetTokenData(Transaction.Ticker, True);
      if not IsUserTEC then
        ValueLabel.Text := AmountToStr(Trx.Amount, '', TokenData.Digits)
      else begin
        var TECAmount := Trunc(Transaction.Amount * Power(10, 8 - TokenData.Digits) * TokenData.ExRate);
        ValueLabel.Text := AmountToStr(TECAmount, 'TEC');
      end;
    end;
  end;

  if Trx.TxType <> 'transfer' then
    IncomText.Text := Trx.TxType.ToUpper;
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
