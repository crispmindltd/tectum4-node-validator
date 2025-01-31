unit Frame.Explorer;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Objects, FMX.Layouts,
  Desktop.Controls, Blockchain.Txn, Blockchain.Reward, Blockchain.Utils;

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

  DateTimeLabel.Text := FormatDateTime('dd.mm.yyyy hh:mm:ss', Trx.DateTime);
  BlockLabel.Text := Trx.TxId.ToString;
  AddressFromLabel.Text := Trx.AddressFrom;
  AddressToLabel.Text := Trx.AddressTo;
  HashLabel.Text := Trx.Hash;
  AmountLabel.Text := AmountToStr(Trx.Amount);

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
  end else begin
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
    HashLabel,AmountLabel,IncomLayout],[0.1,0.05,0.2,0.2,0.27,0.1,0.08],Self);
end;

procedure TExplorerTransactionFrame.UpdateTransaction;
begin
  if Length(FTrx.Rewards)=0 then
    FTrx.Rewards:=GetRwd(FTrx.RewardId);
end;

end.
