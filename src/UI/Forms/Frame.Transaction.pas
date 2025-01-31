unit Frame.Transaction;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Ani, FMX.Objects, FMX.Controls.Presentation, FMX.Layouts,
  App.Intf, Frame.Reward, Desktop.Controls, Blockchain.Txn, Blockchain.Utils;

type
  TTransactionFrame = class(TFrame)
    TETTransactionDetailsLayout: TLayout;
    TETTransactionDetailsLabel: TLabel;
    TETBackCircle: TCircle;
    TETBackArrowPath: TPath;
    TypeLayout: TLayout;
    TypeRectangle: TRectangle;
    TypeText: TText;
    TETTransactionDetailsRectangle: TRectangle;
    TETHashDetailsLayout: TLayout;
    TETHashDetailsLabel: TLabel;
    TETHashDetailsText: TText;
    HashCopyLayout: TLayout;
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
    AddressFromCopyLayout: TLayout;
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
    RewardDetailLayout: TLayout;
    pthArrowDown: TPath;
    FloatAnimation7: TFloatAnimation;
    FeeRewardLayout: TLayout;
    RewardLeftLayout: TLayout;
    RewardsLayout: TLayout;
    ValidatorsLabel: TLabel;
    RewardValidatorsLayout: TLayout;
    RewardArchiverLayout: TLayout;
    ArchiverLabel: TLabel;
    AddressToLayout: TLayout;
    AddressToLabel: TLabel;
    AddressToText: TText;
    AddressToCopyLayout: TLayout;
    AddressToCopyPath: TPath;
    procedure TETBackCircleMouseEnter(Sender: TObject);
    procedure TETBackCircleMouseLeave(Sender: TObject);
    procedure FloatAnimation7Process(Sender: TObject);
    procedure RewardDetailLayoutClick(Sender: TObject);
  private
    procedure InitTrxDetailControls;
    procedure SetRewards(const Transaction: TTransactionInfo);
    procedure SetType(const Text: string; Color: TAlphaColor);
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
  FeeRewardLayout.Height:=FeeRewardLayout.TagFloat*(1-FloatAnimation7.NormalizedTime);
end;

procedure TTransactionFrame.TETBackCircleMouseEnter(Sender: TObject);
begin
  (Sender as TCircle).Fill.Kind := TBrushKind.Solid;
end;

procedure TTransactionFrame.TETBackCircleMouseLeave(Sender: TObject);
begin
  (Sender as TCircle).Fill.Kind := TBrushKind.None;
end;

procedure TTransactionFrame.RewardDetailLayoutClick(Sender: TObject);
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

  FeeRewardLayout.TagFloat:=GetContentRect(RewardsLayout).Bottom;

  if FloatAnimation7.Inverse then
    FeeRewardLayout.Height:=FeeRewardLayout.TagFloat
  else
    FeeRewardLayout.Height:=0;

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

procedure TTransactionFrame.SetType(const Text: string; Color: TAlphaColor);
begin
  TypeText.Text:=Text;
  TypeText.TextSettings.FontColor:=Color;
  TypeRectangle.Fill.Color:=Color;
end;

procedure TTransactionFrame.SetTrxAsUser(const Transaction: TTransactionInfo);
begin

  TETHashDetailsText.Text:=Transaction.Hash;
  TETBlockDetailsText.Text:=Transaction.TxId.ToString;
  TETDateTimeDetailsText.Text:=Transaction.DateTime.ToString;

  AddressToLayout.Visible:=False;

  AddressFromLabel.Text:='Address';

  if Transaction.AddressTo=AppCore.Address then
  begin
    SetType('IN', $FF0F9A62);
    AddressFromText.Text:=Transaction.AddressFrom;
  end else begin
    SetType('OUT', $FFE85D42);
    AddressFromText.Text:=Transaction.AddressTo;
  end;

  AddressToText.Text:=Transaction.AddressTo;

  TETAmountDetailsText.Text:=AmountToStr(Transaction.Amount, True);
  TETFeeDetailsText.Text:=AmountToStr(Transaction.Fee, True);

  SetRewards(Transaction);

  InitTrxDetailControls;

end;

procedure TTransactionFrame.SetTrxAsStaking(const Transaction: TTransactionInfo);
begin

  TETHashDetailsText.Text:=Transaction.Hash;
  TETBlockDetailsText.Text:=Transaction.TxId.ToString;
  TETDateTimeDetailsText.Text:=Transaction.DateTime.ToString;

  AddressToLayout.Visible:=False;

  AddressFromLabel.Text:='Address';

  if Transaction.TxType='stake' then
  begin
    SetType('STAKE', $FF0F9A62);
    AddressFromText.Text:=Transaction.AddressFrom;
  end else begin
    SetType('UNSTAKE', $FFE85D42);
    AddressFromText.Text:=Transaction.AddressFrom;
  end;

  TETAmountDetailsText.Text:=AmountToStr(Transaction.Amount, True);
  TETFeeDetailsText.Text:=AmountToStr(Transaction.Fee, True);

  SetRewards(Transaction);

  InitTrxDetailControls;

end;

procedure TTransactionFrame.SetTrx(const Transaction: TTransactionInfo);
begin

  TETHashDetailsText.Text:=Transaction.Hash;
  TETBlockDetailsText.Text:=Transaction.TxId.ToString;
  TETDateTimeDetailsText.Text:=Transaction.DateTime.ToString;

  AddressToLayout.Visible:=True;

  AddressFromLabel.Text:='Address From';

  if Transaction.TxType='stake' then
    SetType('STAKE', $FF0F9A62)
  else
  if Transaction.TxType='unstake' then
    SetType('UNSTAKE', $FFE85D42)
  else
  if Transaction.TxType='migrate' then
    SetType('MIGRATE', $FFFF6900)
  else
    SetType('TRANSFER', $FF0F9A62);

  AddressFromText.Text:=Transaction.AddressFrom;
  AddressToText.Text:=Transaction.AddressTo;

  TETAmountDetailsText.Text:=AmountToStr(Transaction.Amount, True);
  TETFeeDetailsText.Text:=AmountToStr(Transaction.Fee, True);

  SetRewards(Transaction);

  InitTrxDetailControls;

end;

end.
