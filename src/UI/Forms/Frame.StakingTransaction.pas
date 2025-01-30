unit Frame.StakingTransaction;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Objects, Blockchain.Txn, Desktop.Controls,
  FMX.Layouts, Blockchain.Reward;

const
  DateTimeLabelWidth = 150;
  BlockLabelWidth = 72;
  ValueLabelWidth = 110;
  IncomRectWidth = 70;
  TickerLabelWidth = 80;

type
  TStakingTransactionFrame = class(TFrame)
    Rectangle: TRectangle;
    DateTimeLabel: TLabel;
    BlockLabel: TLabel;
    AddressFromLabel: TLabel;
    HashLabel: TLabel;
    ValueLabel: TLabel;
    IncomRectangle: TRectangle;
    IncomText: TText;
    IncomLayout: TLayout;
    procedure FrameMouseLeave(Sender: TObject);
    procedure FrameMouseEnter(Sender: TObject);
    procedure RectangleResized(Sender: TObject);
  private
    FTrx: TTransactionInfo;
  public
    procedure UpdateTransaction;
    procedure SetData(const Trx: TTransactionInfo);
    property Transaction: TTransactionInfo read FTrx;
  end;

implementation

{$R *.fmx}

{ THistoryTransactionFrame }

procedure TStakingTransactionFrame.SetData(const Trx: TTransactionInfo);
begin

  Name := '';

  FTrx:=Trx;

  DateTimeLabel.Text := FormatDateTime('dd.mm.yyyy hh:mm:ss', Trx.DateTime);
  BlockLabel.Text := Trx.TxId.ToString;
  AddressFromLabel.Text := Trx.AddressFrom;
  HashLabel.Text := Trx.Hash;
  ValueLabel.Text := AmountToStr(Trx.Amount);

  if Trx.TxType='unstake' then
  begin
    IncomRectangle.Fill.Color := $FFE85D42;
    IncomText.Text := 'UNSTAKE';
  end else begin
    IncomRectangle.Fill.Color := $FF0F9A62;
    IncomText.Text := 'STAKE';
  end;

  IncomText.TextSettings.FontColor := IncomRectangle.Fill.Color;

end;

procedure TStakingTransactionFrame.FrameMouseEnter(Sender: TObject);
begin
  Rectangle.Fill.Kind := TBrushKind.Solid;
end;

procedure TStakingTransactionFrame.FrameMouseLeave(Sender: TObject);
begin
  Rectangle.Fill.Kind := TBrushKind.None;
end;

procedure TStakingTransactionFrame.RectangleResized(Sender: TObject);
begin
  ControlsFlexWidth([DateTimeLabel,BlockLabel,AddressFromLabel,
    HashLabel,ValueLabel,IncomLayout],[0.13,0.05,0.3,0.35,0.1,0.07],Self);
end;

procedure TStakingTransactionFrame.UpdateTransaction;
begin
  if Length(FTrx.Rewards)=0 then
    FTrx.Rewards:=GetRwd(FTrx.RewardId);
end;

end.
