unit Frame.Transaction;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Ani, FMX.Objects, FMX.Controls.Presentation, FMX.Layouts, Math,
  App.Intf, Frame.Reward, Desktop.Controls, Blockchain.Types, Blockchain.Utils;

type
  TTransactionFrame = class(TFrame)
    TECTransactionDetailsLayout: TLayout;
    TECTransactionDetailsLabel: TLabel;
    TECBackCircle: TCircle;
    TECBackArrowPath: TPath;
    TypeLayout: TLayout;
    TypeRectangle: TRectangle;
    TypeText: TText;
    TECTransactionDetailsRectangle: TRectangle;
    TECHashDetailsLayout: TLayout;
    TECHashDetailsLabel: TLabel;
    TECHashDetailsText: TText;
    HashCopyLayout: TLayout;
    TECCopyHashSvg: TPath;
    TECBlockDetailsLayout: TLayout;
    TECBlockDetailsLabel: TLabel;
    TECBlockDetailsText: TText;
    TECDateTimeDetailsLayout: TLayout;
    TECDateTimeDetailsLabel: TLabel;
    TECDateTimeDetailsText: TText;
    Line3: TLine;
    TECAddressDetailsLayout: TLayout;
    AddressFromLabel: TLabel;
    AddressFromText: TText;
    AddressFromCopyLayout: TLayout;
    TECCopyAddressSvg: TPath;
    Line4: TLine;
    TECAmountDetailsLayout: TLayout;
    TECAmountDetailsLabel: TLabel;
    TECAmountDetailsText: TText;
    TECDetailsLayout: TLayout;
    TECDetailsLabel: TLabel;
    TECDetailsText: TText;
    TECInfoDetailsLayout: TLayout;
    TECInfoDetailsLabel: TLabel;
    TECInfoDetailsLabelValue: TLabel;
    TECFeeDetailsLayout: TLayout;
    TECFeeDetailsLabel: TLabel;
    TECFeeDetailsText: TText;
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
    BlockToIDLayout: TLayout;
    BlockToIDLabel: TLabel;
    BlockToIDText: TText;
    BlockFromIDLayout: TLayout;
    BlockFromIDLabel: TLabel;
    BlockFromIDText: TText;
    LiquidityAmountLayout: TLayout;
    LiquidityAmountLabel: TLabel;
    LiquidityAmountValueText: TText;
    TECReceivedLayout: TLayout;
    TECReceivedLabel: TLabel;
    TECReceivedValueText: TText;
    procedure TECBackCircleMouseEnter(Sender: TObject);
    procedure TECBackCircleMouseLeave(Sender: TObject);
    procedure FloatAnimation7Process(Sender: TObject);
    procedure RewardDetailLayoutClick(Sender: TObject);
  private
    procedure InitTrxDetailControls;
    procedure SetRewards(const Transaction: TTransactionInfo);
    procedure SetType(const Text: string; Color: TAlphaColor);
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetTrxAsUser(const Transaction: TTransactionInfo; const IsTEC: Boolean = True);
    procedure SetTrxAsStaking(const Transaction: TTransactionInfo);
    procedure SetTrx(const Transaction: TTransactionInfo);
  end;

implementation

{$R *.fmx}

constructor TTransactionFrame.Create(AOwner: TComponent);
begin
  inherited;

  TECDetailsLayout.Visible := False;
  TECInfoDetailsLayout.Visible := False;
  InitTrxDetailControls;
end;

procedure TTransactionFrame.FloatAnimation7Process(Sender: TObject);
begin
  FeeRewardLayout.Height := FeeRewardLayout.TagFloat * (1 - FloatAnimation7.NormalizedTime);
end;

procedure TTransactionFrame.TECBackCircleMouseEnter(Sender: TObject);
begin
  (Sender as TCircle).Fill.Kind := TBrushKind.Solid;
end;

procedure TTransactionFrame.TECBackCircleMouseLeave(Sender: TObject);
begin
  (Sender as TCircle).Fill.Kind := TBrushKind.None;
end;

procedure TTransactionFrame.RewardDetailLayoutClick(Sender: TObject);
begin
  if not FloatAnimation7.Running then
  begin
    if Assigned(Root) then Root.Focused := nil;
    FloatAnimation7.Inverse := not FloatAnimation7.Inverse;
    FloatAnimation7.Start;
  end;
end;

procedure TTransactionFrame.InitTrxDetailControls;
begin
  RewardValidatorsLayout.Height := GetContentRect(RewardValidatorsLayout).Bottom;
  RewardArchiverLayout.Height := GetContentRect(RewardArchiverLayout).Bottom;
  FeeRewardLayout.TagFloat := GetContentRect(RewardsLayout).Bottom;

  if FloatAnimation7.Inverse then
    FeeRewardLayout.Height := FeeRewardLayout.TagFloat
  else
    FeeRewardLayout.Height := 0;
end;

procedure TTransactionFrame.SetRewards(const Transaction: TTransactionInfo);
begin
  RewardValidatorsLayout.DeleteChildren;
  RewardArchiverLayout.DeleteChildren;

  for var R in Transaction.Rewards do
  begin
    var F := TRewardFrame.Create(RewardsLayout);
    F.AddressText.Text := R.Address;
    F.AddressText.AutoSize := True;
    F.AddressText.AutoSize := False;
    F.AmountText.Text := AmountToStr(R.Amount, 'TEC');
    F.AmountText.AutoSize := True;
    F.BackRectangle.Width := F.AmountText.Width + 4;
    F.AmountText.AutoSize := False;

    if R.TypeName = 'a' then F.Parent := RewardArchiverLayout;
    if R.TypeName = 'v' then F.Parent := RewardValidatorsLayout;
  end;
end;

procedure TTransactionFrame.SetType(const Text: string; Color: TAlphaColor);
begin
  TypeText.AutoSize := False;
  TypeText.Text := Text;
  TypeText.AutoSize := True;
  TypeText.TextSettings.FontColor := Color;
  TypeRectangle.Fill.Color := Color;
  TypeLayout.Width := TypeText.Width + 10;
end;

procedure TTransactionFrame.SetTrxAsUser(const Transaction: TTransactionInfo;
  const IsTEC: Boolean);
begin
  TECDetailsLayout.Visible := False;
  TECInfoDetailsLayout.Visible := False;
  TECHashDetailsText.Text:=Transaction.Hash;
  BlockFromIDLayout.Visible := False;
  BlockToIDLayout.Visible := False;
  AddressToLayout.Visible := False;
  LiquidityAmountLayout.Visible := Transaction.TxType = 'mint';
  TECReceivedLayout.Visible := Transaction.TxType = 'burn';
  RewardDetailLayout.Visible := Length(Transaction.Rewards) > 0;
  TECBlockDetailsText.Text := Transaction.Id.ToString;
  TECDateTimeDetailsText.Text := FormatDateTime('ddddd tt.zzz',
    Transaction.DateTime.ToDateTime(False));
  AddressFromLabel.Text := 'Address';

  if Transaction.TxType = 'burn' then
  begin
    TECAmountDetailsText.Text := AmountToStr(Transaction.Amount, Transaction.Ticker,
      Transaction.Decimals);
    var TokenData := AppCore.GetTokenData(Transaction.Ticker, True);
    var TECAmount := Trunc(Transaction.Amount * Power(10, 8 - TokenData.Digits) * TokenData.ExRate);
    AddressFromText.Text := Transaction.AddressTo;
    TECReceivedValueText.Text := AmountToStr(TECAmount, 'TEC');
    if IsTEC then
      SetType('BURN', $FF0F9A62)
    else
      SetType('BURN', $FFE85D42);
  end else
  if Transaction.TxType = 'mint' then
  begin
    SetType('MINT', $FF5B99FF);
    TECAmountDetailsText.Text := AmountToStr(Transaction.Amount, Transaction.Ticker,
      Transaction.Decimals);
    TECDetailsText.Text := Format('%s(%s)',[Transaction.Ticker, Transaction.Name]);
    TECInfoDetailsLabelValue.Text := Trim(Transaction.Description);
    AddressFromText.Text := Transaction.AddressTo;
    LiquidityAmountValueText.Text := AmountToStr(Transaction.IndexFrom, 'TEC');
  end else
  if Transaction.TxType = 'migrate' then
  begin
    AddressFromText.Text := Transaction.AddressFrom;
    SetType('MIGRATE', $FFFF6900);
  end else
  if Transaction.TxType = 'block' then
  begin
    AddressFromText.Text := Transaction.AddressFrom;
    SetType('BLOCK', $FF555555);
  end else
  if Transaction.TxType = 'transfer' then
  begin
    if Transaction.AddressTo = AppCore.Address then
    begin
      SetType('TRANSFER', $FF0F9A62);
      AddressFromText.Text := Transaction.AddressFrom;
    end else begin
      SetType('TRANSFER', $FFE85D42);
      AddressFromText.Text := Transaction.AddressTo;
    end;
  end;

  AddressToText.Text := Transaction.AddressTo;
  TECAmountDetailsText.Text := AmountToStr(Transaction.Amount, Transaction.Ticker,
    Transaction.Decimals);
  TECFeeDetailsText.Text := AmountToStr(Transaction.Fee, 'TEC');

  SetRewards(Transaction);
  InitTrxDetailControls;
end;

procedure TTransactionFrame.SetTrxAsStaking(const Transaction: TTransactionInfo);
begin
  BlockFromIDLayout.Visible := False;
  BlockToIDLayout.Visible := False;
  AddressToLayout.Visible := False;
  LiquidityAmountLayout.Visible := Transaction.TxType = 'mint';
  TECReceivedLayout.Visible := Transaction.TxType = 'burn';
  RewardDetailLayout.Visible := Length(Transaction.Rewards) > 0;
  TECDetailsLayout.Visible := False;
  TECInfoDetailsLayout.Visible := False;
  TECHashDetailsText.Text := Transaction.Hash;
  TECBlockDetailsText.Text := Transaction.Id.ToString;
  TECDateTimeDetailsText.Text := FormatDateTime('ddddd tt.zzz', Transaction.DateTime.ToDateTime(False));
  AddressFromLabel.Text := 'Address';

  if Transaction.TxType = 'validate4' then
  begin
    SetType('REWARD', $FFFF6900);
    AddressFromText.Text := Transaction.AddressFrom;
  end else
  if Transaction.TxType = 'stake' then
  begin
    SetType('STAKE', $FF0F9A62);
    AddressFromText.Text := Transaction.AddressFrom;
  end else begin
    SetType('UNSTAKE', $FFE85D42);
    AddressFromText.Text := Transaction.AddressFrom;
  end;

  TECAmountDetailsText.Text := AmountToStr(Transaction.Amount, Transaction.Ticker,
    Transaction.Decimals);
  TECFeeDetailsText.Text := AmountToStr(Transaction.Fee, 'TEC');

  SetRewards(Transaction);
  InitTrxDetailControls;
end;

procedure TTransactionFrame.SetTrx(const Transaction: TTransactionInfo);
begin
  TECReceivedLayout.Visible := Transaction.TxType = 'burn';
  BlockFromIDLayout.Visible := Transaction.TxType = 'block';
  BlockToIDLayout.Visible := Transaction.TxType = 'block';
  RewardDetailLayout.Visible := Length(Transaction.Rewards) > 0;
  AddressToLayout.Visible := True;
  LiquidityAmountLayout.Visible := Transaction.TxType = 'mint';
  TECDetailsLayout.Visible := Transaction.TxType = 'mint';
  TECInfoDetailsLayout.Visible := Transaction.TxType = 'mint';
  TECHashDetailsText.Text := Transaction.Hash;
  TECBlockDetailsText.Text := Transaction.Id.ToString;
  TECDateTimeDetailsText.Text := FormatDateTime('ddddd tt.zzz', Transaction.DateTime.ToDateTime(False));
  AddressFromLabel.Text := 'Address From';
  TECAmountDetailsText.Text := AmountToStr(Transaction.Amount, Transaction.Ticker,
    Transaction.Decimals);

  if Transaction.TxType = 'stake' then
    SetType('STAKE', $FF0F9A62)
  else
  if Transaction.TxType = 'unstake' then
    SetType('UNSTAKE', $FFE85D42)
  else
  if Transaction.TxType = 'migrate' then
    SetType('MIGRATE', $FFFF6900)
  else
  if Transaction.TxType = 'block' then
  begin
    BlockFromIDText.Text := Transaction.IndexFrom.ToString;
    BlockFromIDLayout.Position.Y := Line4.Position.Y + 1;
    BlockToIDText.Text := Transaction.IndexTo.ToString;
    BlockToIDLayout.Position.Y := BlockFromIDLayout.Position.Y + 1;
    SetType('BLOCK', $FF555555);
  end else
  if Transaction.TxType = 'validate' then
    SetType('VALIDATE', $FF555555)
  else
  if Transaction.TxType = 'mint' then
  begin
    TECAmountDetailsText.Text := AmountToStr(Transaction.Amount, Transaction.Ticker,
      Transaction.Decimals);
    TECDetailsText.Text := Format('%s(%s)',[Transaction.Ticker, Transaction.Name]);
    TECInfoDetailsLabelValue.Text := Trim(Transaction.Description);
    LiquidityAmountValueText.Text := AmountToStr(Transaction.IndexFrom, 'TEC');
    SetType('MINT', $FF5B99FF);
  end else
  if Transaction.TxType = 'burn' then
  begin
    TECAmountDetailsText.Text := AmountToStr(Transaction.Amount, Transaction.Ticker,
      Transaction.Decimals);
    var TokenData := AppCore.GetTokenData(Transaction.Ticker, True);
    var TECAmount := Trunc(Transaction.Amount * Power(10, 8 - TokenData.Digits) * TokenData.ExRate);
    TECReceivedValueText.Text := AmountToStr(TECAmount, 'TEC');
    SetType('BURN', $FFFF0606);
  end else
    SetType('TRANSFER', $FF0F9A62);

  AddressFromText.Text := Transaction.AddressFrom;
  AddressToText.Text := Transaction.AddressTo;
  TECFeeDetailsText.Text := AmountToStr(Transaction.Fee, 'TEC');

  SetRewards(Transaction);
  InitTrxDetailControls;
end;

end.
