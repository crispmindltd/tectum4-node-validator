unit Frame.Explorer;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Objects, FMX.Layouts,
  Desktop.Controls, Blockchain.Types, Blockchain.Utils;

type
  TExplorerTransactionFrame = class(TFrame)
    DateTimeLabel: TLabel;
    BlockLabel: TLabel;
    AddressFromLabel: TLabel;
    AddressToLabel: TLabel;
    HashLabel: TLabel;
    AmountLabel: TLabel;
    Rectangle: TRectangle;
    IncomLayout: TLayout;
    IncomRectangle: TRectangle;
    IncomText: TText;
    TickerLabel: TLabel;
    procedure FrameMouseEnter(Sender: TObject);
    procedure FrameMouseLeave(Sender: TObject);
    procedure FrameResized(Sender: TObject);
  private
    FTrx: TTransactionInfo;
  public
    procedure UpdateTransaction;
    procedure SetData(const Trx: TTransactionInfo);
    property Transaction: TTransactionInfo read FTrx;
  end;

implementation

{$R *.fmx}

procedure TExplorerTransactionFrame.SetData(const Trx: TTransactionInfo);
begin

  Name := '';

  FTrx:=Trx;

  DateTimeLabel.Text := FormatDateTime('dd.mm.yyyy hh:nn:ss', Trx.DateTime.ToDateTime(False));
  BlockLabel.Text := Trx.Id.ToString;
  AddressFromLabel.Text := Trx.AddressFrom;
  AddressToLabel.Text := Trx.AddressTo;
  HashLabel.Text := Trx.Hash;
  TickerLabel.Text := Trx.Ticker;
  AmountLabel.Text := AmountToStr(Trx.Amount,'',Trx.Decimals);

  if Transaction.TxType='stake' then
  begin
    IncomRectangle.Fill.Color := $FF0F9A62;
    IncomText.Text := 'STAKE';
  end else
  if Transaction.TxType='unstake' then
  begin
    IncomRectangle.Fill.Color := $FFE85D42;
    IncomText.Text := 'UNSTAKE';
  end else
  if Transaction.TxType='migrate' then
  begin
    IncomRectangle.Fill.Color := $FFFF6900;
    IncomText.Text := 'MIGRATE';
  end else
  if Transaction.TxType='block' then
  begin
    IncomRectangle.Fill.Color := $FF555555;
    IncomText.Text := 'BLOCK';
  end else
  if Transaction.TxType='validate' then
  begin
    IncomRectangle.Fill.Color := $FF555555;
    IncomText.Text := 'VALIDATE';
  end else
  if Transaction.TxType='mint' then
  begin
    IncomRectangle.Fill.Color := $FF5B99FF;
    IncomText.Text := 'MINT';
  end else
  if Transaction.TxType='burn' then
  begin
    IncomRectangle.Fill.Color := $FFFF0606;
    IncomText.Text := 'BURN';
  end else
  begin
    IncomRectangle.Fill.Color := $FF0F9A62;
    IncomText.Text := 'TRANSFER';
  end;

  IncomText.TextSettings.FontColor := IncomRectangle.Fill.Color;

end;

procedure TExplorerTransactionFrame.FrameMouseEnter(Sender: TObject);
begin
  Rectangle.Fill.Kind := TBrushKind.Solid;
end;

procedure TExplorerTransactionFrame.FrameMouseLeave(Sender: TObject);
begin
  Rectangle.Fill.Kind := TBrushKind.None;
end;

procedure TExplorerTransactionFrame.FrameResized(Sender: TObject);
begin
  ControlsFlexWidth([DateTimeLabel,BlockLabel,AddressFromLabel,AddressToLabel,
    HashLabel,TickerLabel,AmountLabel,IncomLayout],[0.1,0.05,0.18,0.18,0.23,0.07,0.1,0.08],Self);
end;

procedure TExplorerTransactionFrame.UpdateTransaction;
begin
  if Length(FTrx.Rewards)=0 then
//    FTrx.Rewards:=GetRwd(FTrx.RewardId);
end;

end.
