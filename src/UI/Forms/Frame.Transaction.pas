unit Frame.Transaction;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Ani, FMX.Objects, FMX.Controls.Presentation, FMX.Layouts,
  Blockchain.Txn, App.Intf, Frame.Reward, Desktop.Controls;

type
  TTransactionFrame = class(TFrame)
    TETTransactionDetailsLayout: TLayout;
    TETTransactionDetailsLabel: TLabel;
    TETBackCircle: TCircle;
    TETBackArrowPath: TPath;
    Layout6: TLayout;
    IncomRectangle: TRectangle;
    IncomText: TText;
    TETTransactionDetailsRectangle: TRectangle;
    TETHashDetailsLayout: TLayout;
    TETHashDetailsLabel: TLabel;
    TETHashDetailsText: TText;
    TETCopyLoginLayout: TLayout;
    TETCopyHashSvg: TPath;
    TETBlockDetailsLayout: TLayout;
    TETBlockDetailsLabel: TLabel;
    TETBlockDetailsText: TText;
    TETDateTimeDetailsLayout: TLayout;
    TETDateTimeDetailsLabel: TLabel;
    TETDateTimeDetailsText: TText;
    Line3: TLine;
    TETAddressDetailsLayout: TLayout;
    AddressFromLabel: TLabel;
    AddressFromText: TText;
    TETCopyAddressLayout: TLayout;
    TETCopyAddressSvg: TPath;
    Line4: TLine;
    TETAmountDetailsLayout: TLayout;
    TETAmountDetailsLabel: TLabel;
    TETAmountDetailsText: TText;
    TETDetailsLayout: TLayout;
    TETDetailsLabel: TLabel;
    TETDetailsText: TText;
    TETInfoDetailsLayout: TLayout;
    TETInfoDetailsLabel: TLabel;
    TETInfoDetailsLabelValue: TLabel;
    TETFeeDetailsLayout: TLayout;
    TETFeeDetailsLabel: TLabel;
    TETFeeDetailsText: TText;
    Layout11: TLayout;
    pthArrowDown: TPath;
    FloatAnimation7: TFloatAnimation;
    Layout12: TLayout;
    Layout13: TLayout;
    RewardsLayout: TLayout;
    Label4: TLabel;
    RewardValidatorsLayout: TLayout;
    RewardArchiverLayout: TLayout;
    Label5: TLabel;
    Layout1: TLayout;
    AddressToLabel: TLabel;
    AddressToText: TText;
    Layout2: TLayout;
    Path1: TPath;
    procedure TETBackCircleMouseEnter(Sender: TObject);
    procedure TETBackCircleMouseLeave(Sender: TObject);
    procedure FloatAnimation7Process(Sender: TObject);
    procedure Layout11Click(Sender: TObject);
  private
    procedure InitTrxDetailControls;
    procedure SetRewards(const Transaction: TTransactionInfo);
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetTrxAsUser(const Transaction: TTransactionInfo);
    procedure SetTrxAsStaking(const Transaction: TTransactionInfo);
    procedure SetTrx(const Transaction: TTransactionInfo);
  end;

implementation

{$R *.fmx}

constructor TTransactionFrame.Create(AOwner: TComponent);
begin
  inherited;
  TETDetailsLayout.Visible:=False;
  TETInfoDetailsLayout.Visible:=False;
  InitTrxDetailControls;
end;

procedure TTransactionFrame.FloatAnimation7Process(Sender: TObject);
begin
  Layout12.Height:=Layout12.TagFloat*(1-FloatAnimation7.NormalizedTime);
end;

procedure TTransactionFrame.TETBackCircleMouseEnter(Sender: TObject);
begin
  (Sender as TCircle).Fill.Kind := TBrushKind.Solid;
end;

procedure TTransactionFrame.TETBackCircleMouseLeave(Sender: TObject);
begin
  (Sender as TCircle).Fill.Kind := TBrushKind.None;
end;

procedure TTransactionFrame.Layout11Click(Sender: TObject);
begin
  if not FloatAnimation7.Running then
  begin
    if Assigned(Root) then Root.Focused:=nil;
    FloatAnimation7.Inverse:=not FloatAnimation7.Inverse;
    FloatAnimation7.Start;
  end;
end;

procedure TTransactionFrame.InitTrxDetailControls;
begin


  RewardValidatorsLayout.Height:=GetContentRect(RewardValidatorsLayout).Bottom;
  RewardArchiverLayout.Height:=GetContentRect(RewardArchiverLayout).Bottom;

  Layout12.TagFloat:=GetContentRect(RewardsLayout).Bottom;

  if FloatAnimation7.Inverse then
    Layout12.Height:=Layout12.TagFloat
  else
    Layout12.Height:=0;

  Layout11.OnClick:=Layout11Click;

end;

procedure TTransactionFrame.SetRewards(const Transaction: TTransactionInfo);
begin

  RewardValidatorsLayout.DeleteChildren;
  RewardArchiverLayout.DeleteChildren;

  for var R in Transaction.Rewards do
  begin
    var F:=TRewardFrame.Create(RewardsLayout);
    F.AddressLabel.Text:=R.Address;
    F.AmountLabel.Text:=AmountToStr(R.Amount, True);
    if R.TypeName='a' then F.Parent:=RewardArchiverLayout;
    if R.TypeName='v' then F.Parent:=RewardValidatorsLayout;
  end;

end;

procedure TTransactionFrame.SetTrxAsUser(const Transaction: TTransactionInfo);
begin

  TETHashDetailsText.Text:=Transaction.Hash;
  TETBlockDetailsText.Text:=Transaction.TxId.ToString;
  TETDateTimeDetailsText.Text:=Transaction.DateTime.ToString;

  Layout1.Visible:=False;

  AddressFromLabel.Text:='Address';

  if Transaction.AddressTo=AppCore.Address then
  begin
    IncomText.Text:='IN';
    IncomText.TextSettings.FontColor:=$FF0F9A62;
    AddressFromText.Text:=Transaction.AddressFrom;
  end else begin
    IncomText.Text:='OUT';
    IncomText.TextSettings.FontColor:=$FFE85D42;
    AddressFromText.Text:=Transaction.AddressTo;
  end;

  AddressToText.Text:=Transaction.AddressTo;

  IncomRectangle.Fill.Color:=IncomText.TextSettings.FontColor;
  TETAmountDetailsText.Text:=AmountToStr(Transaction.Amount, True);
  TETFeeDetailsText.Text:=AmountToStr(Transaction.Fee, True);

  SetRewards(Transaction);

  InitTrxDetailControls;

  Layout11.OnClick:=Layout11Click;

end;

procedure TTransactionFrame.SetTrxAsStaking(const Transaction: TTransactionInfo);
begin

  TETHashDetailsText.Text:=Transaction.Hash;
  TETBlockDetailsText.Text:=Transaction.TxId.ToString;
  TETDateTimeDetailsText.Text:=Transaction.DateTime.ToString;

  Layout1.Visible:=False;

  AddressFromLabel.Text:='Address';

  if Transaction.TxType='stake' then
  begin
    IncomText.Text:='STAKE';
    IncomText.TextSettings.FontColor:=$FF0F9A62;
    AddressFromText.Text:=Transaction.AddressFrom;
  end else begin
    IncomText.Text:='UNSTAKE';
    IncomText.TextSettings.FontColor:=$FFE85D42;
    AddressFromText.Text:=Transaction.AddressFrom;
  end;

  IncomRectangle.Fill.Color:=IncomText.TextSettings.FontColor;
  TETAmountDetailsText.Text:=AmountToStr(Transaction.Amount, True);
  TETFeeDetailsText.Text:=AmountToStr(Transaction.Fee, True);

  SetRewards(Transaction);

  InitTrxDetailControls;

  Layout11.OnClick:=Layout11Click;

end;

procedure TTransactionFrame.SetTrx(const Transaction: TTransactionInfo);
begin

  TETHashDetailsText.Text:=Transaction.Hash;
  TETBlockDetailsText.Text:=Transaction.TxId.ToString;
  TETDateTimeDetailsText.Text:=Transaction.DateTime.ToString;

  Layout1.Visible:=True;

  AddressFromLabel.Text:='Address From';

  if Transaction.TxType='stake' then
  begin
    IncomText.Text:='STAKE';
    IncomText.TextSettings.FontColor:=$FF0F9A62;
  end else
  if Transaction.TxType='unstake' then
  begin
    IncomText.Text:='UNSTAKE';
    IncomText.TextSettings.FontColor:=$FFE85D42;
  end else
  if Transaction.TxType='migrate' then
  begin
    IncomText.Text:='MIGRATE';
    IncomText.TextSettings.FontColor:=$FFFF6900;
  end else begin
    IncomText.Text:='TRANSFER';
    IncomText.TextSettings.FontColor:=$FF0F9A62;
  end;

  AddressFromText.Text:=Transaction.AddressFrom;
  AddressToText.Text:=Transaction.AddressTo;

  IncomRectangle.Fill.Color:=IncomText.TextSettings.FontColor;
  TETAmountDetailsText.Text:=AmountToStr(Transaction.Amount, True);
  TETFeeDetailsText.Text:=AmountToStr(Transaction.Fee, True);

  SetRewards(Transaction);

  InitTrxDetailControls;

end;

end.
