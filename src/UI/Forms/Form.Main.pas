unit Form.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Math, System.Generics.Collections, System.Generics.Defaults, System.DateUtils,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation,
  FMX.Edit, FMX.TabControl, FMX.Platform, FMX.ListBox, FMX.Effects, FMX.Objects,
  FMX.Layouts, FMX.StdCtrls, FMX.Ani, FMX.Grid.Style, FMX.ScrollBox,
  FMX.Grid, FMX.Memo.Types, FMX.Memo,
  App.Exceptions,
  App.Logs,
  App.Intf,
  Blockchain.Data,
  Blockchain.Txn,
  Blockchain.Validation,
  Blockchain.Reward,
  Blockchain.Utils,
  Desktop.Controls,
  Styles,
  Frame.Explorer,
  Frame.History,
  Frame.Reward,
  Frame.Transaction,
  Frame.StakingTransaction,
  Frame.Navigation;

type
  TLayout = class(FMX.Layouts.TLayout, IContent)
  private
    FOnChanged: TNotifyEvent;
    procedure Changed;
  end;

  TMainForm = class(TForm)
    Tabs: TTabControl;
    TokensTabItem: TTabItem;
    ExplorerTabItem: TTabItem;
    ShadowEffect1: TShadowEffect;
    TokenNameEdit: TEdit;
    RecepientAddressEdit: TEdit;
    ShadowEffect4: TShadowEffect;
    AmountTokenEdit: TEdit;
    ShadowEffect5: TShadowEffect;
    SendTokenButton: TButton;
    HistoryTokenHeaderLayout: TLayout;
    ExplorerHeaderLayout: TLayout;
    ExplorerHorzScrollBox: THorzScrollBox;
    TectumTabItem: TTabItem;
    BalanceTETLabel: TLabel;
    BalanceTETValueLabel: TLabel;
    AddressTETLabel: TLabel;
    SendTETToEdit: TEdit;
    ShadowEffect6: TShadowEffect;
    AmountTETEdit: TEdit;
    ShadowEffect7: TShadowEffect;
    SendTETButton: TButton;
    HistoryTETLabel: TLabel;
    HistoryTETHeaderLayout: TLayout;
    DateTimeTETHeaderLabel: TLabel;
    BlockNumTETHeaderLabel: TLabel;
    AddressFromHeaderLabel: TLabel;
    HashTETHeaderLabel: TLabel;
    AmountTETHeaderLabel: TLabel;
    BalanceTETHeaderLayout: TLayout;
    SendTETDataLayout: TLayout;
    TokenHeaderLayout: TLayout;
    AddressTokenLabel: TLabel;
    BalanceTokenLabel: TLabel;
    BalanceTokenValueLabel: TLabel;
    SendTokenDataLayout: TLayout;
    HistoryTokenLabel: TLabel;
    AmountTokenHeaderLabel: TLabel;
    BlockNumTokenHeaderLabel: TLabel;
    DateTimeTokenHeaderLabel: TLabel;
    AddressTokenHeaderLabel: TLabel;
    HashTokenHeaderLabel: TLabel;
    TransferTokenStatusLabel: TLabel;
    FloatAnimation1: TFloatAnimation;
    AmountExplorerHeaderLabel: TLabel;
    BlockNumExplorerHeaderLabel: TLabel;
    DateTimeExplorerHeaderLabel: TLabel;
    FromExplorerHeaderLabel: TLabel;
    HashExplorerHeaderLabel: TLabel;
    ToExplorerHeaderLabel: TLabel;
    CreateTokenTabItem: TTabItem;
    CreateTokenLabel: TLabel;
    CreateTokenDataLayout: TLayout;
    CreateTokenShortNameEdit: TEdit;
    ShadowEffect8: TShadowEffect;
    CreateTokenNameLabel: TLabel;
    CreateTokenSymbolEdit: TEdit;
    ShadowEffect9: TShadowEffect;
    CreateTokenSymbolLabel: TLabel;
    CreateTokenAmountEdit: TEdit;
    ShadowEffect10: TShadowEffect;
    AmountLabel: TLabel;
    DecimalsEdit: TEdit;
    ShadowEffect11: TShadowEffect;
    DecimalsLabel: TLabel;
    CreateTokenInformationLabel: TLabel;
    CreateTokenInformationMemo: TMemo;
    ShadowEffect12: TShadowEffect;
    TokenCreationFeeLabel: TLabel;
    CreateTokenButton: TButton;
    NewTokenHelpInfoRectangle: TRectangle;
    NewTokenHelpInfoLabel1: TLabel;
    NewTokenHelpInfoLabel2: TLabel;
    NewTokenHelpInfoLabel3: TLabel;
    NewTokenHelpInfoLabel4: TLabel;
    NewTokenHelpInfoLabel5: TLabel;
    NewTokenHelpInfoLabel6: TLabel;
    NewTokenHelpInfoLabel7: TLabel;
    NewTokenHelpTokenNameLayout: TLayout;
    NewTokenHelpTokenSymbolLayout: TLayout;
    NewTokenHelpAmountLayout: TLayout;
    NewTokenHelpDecimalsLayout: TLayout;
    NewTokenHelpTokenNameLabel: TLabel;
    NewTokenHelpTokenNameLabel2: TLabel;
    NewTokenHelpTokenSymbolLabel: TLabel;
    NewTokenHelpTokenSymbolLabel2: TLabel;
    NewTokenHelpAmountLabel2: TLabel;
    NewTokenHelpAmountLabel: TLabel;
    NewTokenHelpDecimalsLabel: TLabel;
    NewTokenHelpDecimalsLabel2: TLabel;
    NewTokenHelpTokenInfoLayout: TLayout;
    NewTokenHelpTokenInfoLabel: TLabel;
    NewTokenHelpTokenInfoLabel2: TLabel;
    NewTokenHelpTokenInfoLabel3: TLabel;
    TokenCreatingStatusLabel: TLabel;
    FloatAnimation3: TFloatAnimation;
    ExplorerTabControl: TTabControl;
    ExporerTabItemData: TTabItem;
    ExplorerTransactionDataTabItem: TTabItem;
    NoTETHistoryLabel: TLabel;
    StatusTETHeaderLabel: TLabel;
    NoTokenHistoryLabel: TLabel;
    StatusTokenHeaderLabel: TLabel;
    TETTabControl: TTabControl;
    TETTabItemData: TTabItem;
    TETTransactionDataTabItem: TTabItem;
    TokenInfoRectangle: TRectangle;
    TokenShortNameEdit: TEdit;
    TokenInfoMemo: TMemo;
    ExplorerVertScrollBox: TVertScrollBox;
    HistoryTETVertScrollBox: TVertScrollBox;
    HistoryTokenVertScrollBox: TVertScrollBox;
    TokenTabControl: TTabControl;
    TokenTabItemData: TTabItem;
    TokenTransactionDataTabItem: TTabItem;
    TokenTransactionDetailsLayout: TLayout;
    TokenTransactionDetailsLabel: TLabel;
    TokenBackCircle: TCircle;
    TokenBackArrowPath: TPath;
    TokenTransactionDetailsRectangle: TRectangle;
    TokenHashDetailsLayout: TLayout;
    TokenHashDetailsLabel: TLabel;
    TokenHashDetailsText: TText;
    TokenCopyLoginLayout: TLayout;
    TokenCopyHashSvg: TPath;
    TokenBlockDetailsLayout: TLayout;
    TokenBlockDetailsLabel: TLabel;
    TokenBlockDetailsText: TText;
    TokenDateTimeDetailsLayout: TLayout;
    TokenDateTimeDetailsLabel: TLabel;
    TokenDateTimeDetailsText: TText;
    Line5: TLine;
    TokenAddressDetailsLayout: TLayout;
    TokenAddressDetailsLabel: TLabel;
    TokenAddressDetailsText: TText;
    TokenCopyAddressLayout: TLayout;
    TokenCopyAddressSvg: TPath;
    Line6: TLine;
    TokenAmountDetailsLayout: TLayout;
    TokenAmountDetailsLabel: TLabel;
    TokenAmountDetailsText: TText;
    TokenDetailsAdvLayout: TLayout;
    TokenDetailsAdvLabel: TLabel;
    TokenDetailsAdvText: TText;
    TokenInfoDetailsAdvLayout: TLayout;
    TokenInfoDetailsAdvLabel: TLabel;
    TokenInfoDetailsAdvLabelValue: TLabel;
    TokenFeeDetailsLayout: TLayout;
    TokenFeeDetailsLabel: TLabel;
    TokenFeeDetailsText: TText;
    InputPrKeyButton: TButton;
    ExplorerNavigationLayout: TLayout;
    SearchEdit: TEdit;
    SearchButton: TButton;
    TransactionNotFoundLabel: TLabel;
    FloatAnimation4: TFloatAnimation;
    SearchAniIndicator: TAniIndicator;
    TickerExplorerHeaderLabel: TLabel;
    CreateTokenAniIndicator: TAniIndicator;
    TransTokenAniIndicator: TAniIndicator;
    TETSendButtonLayout: TLayout;
    TETSendLayout: TLayout;
    StatusText: TEdit;
    FloatAnimation2: TFloatAnimation;
    TxMaxAmountButton: TEditButton;
    AddressToHeaderLabel: TLabel;
    StakingTabItem: TTabItem;
    StakingLayout: TLayout;
    StakeButton: TButton;
    StakingStatusText: TEdit;
    FloatAnimation5: TFloatAnimation;
    StakeLayout: TLayout;
    StakeAmountEdit: TEdit;
    StakeMaxButton: TEditButton;
    ShadowEffect15: TShadowEffect;
    UnstakeLayout: TLayout;
    UnstakeButtonLayout: TLayout;
    UnstakeButton: TButton;
    StakingInfoLabel: TLabel;
    StakingBalanceLabel: TLabel;
    StakeBalanceLabel: TLabel;
    UnstakeAmountEdit: TEdit;
    UnstakeMaxButton: TEditButton;
    ShadowEffect14: TShadowEffect;
    UnstakingStatusText: TEdit;
    FloatAnimation6: TFloatAnimation;
    StakeButtonLayout: TLayout;
    StakingMaxAmountLabel: TLabel;
    StakingSummaryLabel: TLabel;
    StakingPeriodLabel: TLabel;
    StakingRewardLabel1: TLabel;
    RewardDaysLabel: TLabel;
    StakingRewardAmountLabel: TLabel;
    UnstakingMaxAmountLabel: TLabel;
    CopiedRectangle: TRectangle;
    CopiedText: TText;
    FloatAnimation8: TFloatAnimation;
    CopiedAnimation: TFloatAnimation;
    TransactionFrame1: TTransactionFrame;
    TransactionFrame2: TTransactionFrame;
    StakingTabControl: TTabControl;
    StakingMainTabItem: TTabItem;
    StakingHeaderLayout: TLayout;
    HeaderStakingDateLabel: TLabel;
    HeaderStakingBlockLabel: TLabel;
    HeaderStakingAddressLabel: TLabel;
    HeaderStakingHashLabel: TLabel;
    HeaderStakingAmountLabel: TLabel;
    HeaderStakingStatusLabel: TLabel;
    StakingHistoryLabel: TLabel;
    NoStakingLabel: TLabel;
    StakingScrollBox: TVertScrollBox;
    StakingDetailTabItem: TTabItem;
    TransactionFrame3: TTransactionFrame;
    SettingsTab: TTabItem;
    SettingsLabel: TLabel;
    PrivateKeyLabel: TLabel;
    PrivateKeyEdit: TEdit;
    ShadowEffect13: TShadowEffect;
    ChangeKeyButton: TButton;
    PrivateKeyMessageBackground: TRectangle;
    PrivateKeyMessageLayout: TLayout;
    PrivateKeyButtonLayout: TLayout;
    AddressTETLayout: TLayout;
    TETCopyLoginLayout: TLayout;
    TETCopyHashSvg: TPath;
    StatusExplorerHeaderLabel: TLabel;
    SettingsLayout: TLayout;
    PrivateKeyStatusEdit: TEdit;
    FloatAnimation7: TFloatAnimation;
    PrivateKeyMessageLabel: TLabel;
    ExplorerNavigation: TNavigationFrame;
    TETInfoLabel: TLabel;
    StakingNavigationLayout: TLayout;
    StakingNavigation: TNavigationFrame;
    TransactionNavigationLayout: TLayout;
    TransactionNavigation: TNavigationFrame;
    WaitDataLayout: TRectangle;
    WaitDataLabel: TLabel;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SendTETButtonClick(Sender: TObject);
    procedure TETCopyLoginLayoutClick(Sender: TObject);
    procedure SearchEditChangeTracking(Sender: TObject);
    procedure SearchButtonClick(Sender: TObject);
    procedure SearchEditKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
    procedure ExplorerVertScrollBoxResized(Sender: TObject);
    procedure HistoryTETVertScrollBoxResized(Sender: TObject);
    procedure UnstakeButtonClick(Sender: TObject);
    procedure StakeButtonClick(Sender: TObject);
    procedure StakingLayoutResized(Sender: TObject);
    procedure CopiedAnimationFinish(Sender: TObject);
    procedure StakeAmountEditEnter(Sender: TObject);
    procedure UnstakeAmountEditEnter(Sender: TObject);
    procedure StakeMaxButtonClick(Sender: TObject);
    procedure UnstakeMaxButtonClick(Sender: TObject);
    procedure TxMaxAmountButtonClick(Sender: TObject);
    procedure TransactionFrame1TETBackCircleMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure TransactionFrame1TETCopyLoginLayoutClick(Sender: TObject);
    procedure TransactionFrame1TETCopyAddressLayoutClick(Sender: TObject);
    procedure TransactionFrame2TETBackCircleClick(Sender: TObject);
    procedure TransactionFrame2TETCopyLoginLayoutClick(Sender: TObject);
    procedure TransactionFrame2TETCopyAddressLayoutClick(Sender: TObject);
    procedure TransactionFrame1Layout2Click(Sender: TObject);
    procedure TransactionFrame3TETBackCircleClick(Sender: TObject);
    procedure TransactionFrame3TETCopyLoginLayoutClick(Sender: TObject);
    procedure TransactionFrame3TETCopyAddressLayoutClick(Sender: TObject);
    procedure StakingScrollBoxResized(Sender: TObject);
    procedure ChangeKeyButtonClick(Sender: TObject);
    procedure PrivateKeyMessageLabelResize(Sender: TObject);
    procedure PrivateKeyEditEnter(Sender: TObject);
    procedure TabsChange(Sender: TObject);
  private
    FBalance: UInt64;
    FStakingBalance: UInt64;
    FStakingMaxAmountText: string;
    FUnstakingMaxAmountText: string;
    procedure CopyTextToClipboard(const Text: string; Control: TControl);
    procedure RefreshBalances;
    procedure RefreshUserTransactions;
    procedure RefreshUserStaking;
    procedure RefreshExplorer;
    procedure RefreshExplorerRaw;
    procedure RefreshExplorerText(const Text: string);
    procedure ShowTETTransferStatus(const AMessage: string; AIsError: Boolean = False);
    procedure ShowStakeStatus(const AMessage: string; AIsError: Boolean = False);
    procedure ShowUnstakeStatus(const AMessage: string; AIsError: Boolean = False);
    procedure ShowKeyStatus(const AMessage: string; AIsError: Boolean = False);
    procedure onTETHistoryFrameClick(Sender: TObject);
    procedure onStakingHistoryFrameClick(Sender: TObject);
    procedure onExplorerFrameClick(Sender: TObject);
    procedure OnTransactionPageChange(Sender: TObject);
    procedure OnExplorerPageChange(Sender: TObject);
    procedure OnStakingPageChange(Sender: TObject);
    procedure StakingContentChanged(Sender: TObject);
  public
    procedure NewTETChainBlocksEvent;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
  Desktop;

procedure TLayout.Changed;
begin
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin

  Caption := 'Tectum Node ' + AppCore.GetAppVersionText;

  FStakingMaxAmountText := StakingMaxAmountLabel.Text;
  FUnstakingMaxAmountText := UnstakingMaxAmountLabel.Text;

  CopiedRectangle.Visible := False;

  StakeLayout.FOnChanged := StakingContentChanged;
  UnstakeLayout.FOnChanged := StakingContentChanged;

  WaitDataLayout.Visible := True;
  HistoryTETHeaderLayout.Visible := False;
  StakingHeaderLayout.Visible := False;

  BalanceTETValueLabel.Text:=AmountToStr(0,True);
  StakeBalanceLabel.Text:=AmountToStr(0,True);
  AddressTETLabel.Text := AppCore.Address;
  StakingRewardAmountLabel.Text := AmountToStr(0, True);
  RewardDaysLabel.Text := '0 Days';

end;

procedure TMainForm.FormShow(Sender: TObject);
begin

  Tabs.ActiveTab := TectumTabItem;
  TETTabControl.ActiveTab := TETTabItemData;
  StakingTabControl.ActiveTab := StakingMainTabItem;
  ExplorerTabControl.ActiveTab := ExporerTabItemData;

  ShowTETTransferStatus('', False);
  ShowStakeStatus('', False);
  ShowUnstakeStatus('', False);
  ShowKeyStatus('', False);

  ExplorerNavigation.OnChange := OnExplorerPageChange;
  ExplorerNavigation.PagesCount := 0;
  ExplorerNavigation.PageNum := 1;

  StakingNavigation.OnChange := OnStakingPageChange;
  StakingNavigation.PagesCount := 0;
  StakingNavigation.PageNum := 1;

  TransactionNavigation.OnChange := OnTransactionPageChange;
  TransactionNavigation.PagesCount := 0;
  TransactionNavigation.PageNum := 1;

end;

procedure TMainForm.PrivateKeyEditEnter(Sender: TObject);
begin
  ShowKeyStatus('', False);
end;

procedure TMainForm.StakeMaxButtonClick(Sender: TObject);
begin
  StakeAmountEdit.Text := AmountToStr(CalculateMaxSendValue(FBalance));
end;

procedure TMainForm.UnstakeMaxButtonClick(Sender: TObject);
begin
  UnstakeAmountEdit.Text := AmountToStr(FStakingBalance);
end;

procedure TMainForm.ExplorerVertScrollBoxResized(Sender: TObject);
begin
  ControlsFlexWidth([DateTimeExplorerHeaderLabel,BlockNumExplorerHeaderLabel,FromExplorerHeaderLabel,
    ToExplorerHeaderLabel,HashExplorerHeaderLabel,AmountExplorerHeaderLabel,StatusExplorerHeaderLabel],
    [0.1,0.05,0.2,0.2,0.27,0.1,0.08], ExplorerVertScrollBox.Content);
end;

procedure TMainForm.TabsChange(Sender: TObject);
begin
  CopiedRectangle.Visible := False;
end;

procedure TMainForm.HistoryTETVertScrollBoxResized(Sender: TObject);
begin
  ControlsFlexWidth([DateTimeTETHeaderLabel,BlockNumTETHeaderLabel,AddressFromHeaderLabel,
    AddressToHeaderLabel,HashTETHeaderLabel,AmountTETHeaderLabel,StatusTETHeaderLabel],
    [0.1,0.05,0.2,0.2,0.3,0.1,0.05], HistoryTETVertScrollBox.Content);
end;

procedure TMainForm.PrivateKeyMessageLabelResize(Sender: TObject);
begin
  PrivateKeyMessageLayout.Height := PrivateKeyMessageLabel.BoundsRect.Bottom+7;
end;

procedure TMainForm.ChangeKeyButtonClick(Sender: TObject);
begin

  try
    AppCore.ChangePrivateKey(PrivateKeyEdit.Text);
  except on E: EKeyException do
  begin
    case E.ErrorCode of
    EKeyException.INVALID_KEY: ShowKeyStatus('Invalid private key, please enter a different one', True);
    else
      ShowKeyStatus(E.Message, True);
    end;
    Exit
  end;
  on E: Exception do
  begin
    ShowKeyStatus(E.Message, True);
    Exit
  end;
  end;

  AppCore.Reset;

  ShowKeyStatus('Key changed', False);

end;

procedure TMainForm.CopyTextToClipboard(const Text: string; Control: TControl);
begin
  CopyToClipboard(Text);
  CopiedRectangle.Position.Point := Control.LocalToAbsolute(Control.LocalRect.BottomRight);
  CopiedRectangle.Opacity := 1;
  CopiedRectangle.Visible := True;
end;

procedure TMainForm.TETCopyLoginLayoutClick(Sender: TObject);
begin
  CopyTextToClipboard(AddressTETLabel.Text, TETCopyLoginLayout);
end;

procedure TMainForm.TransactionFrame1TETBackCircleMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  ExplorerTabControl.Previous;
end;

procedure TMainForm.TransactionFrame1TETCopyAddressLayoutClick(Sender: TObject);
begin
  CopyTextToClipboard(TransactionFrame1.AddressFromText.Text, TransactionFrame1.AddressFromCopyLayout);
end;

procedure TMainForm.TransactionFrame1Layout2Click(Sender: TObject);
begin
  CopyTextToClipboard(TransactionFrame1.AddressToText.Text, TransactionFrame1.AddressToCopyLayout);
end;

procedure TMainForm.TransactionFrame1TETCopyLoginLayoutClick(Sender: TObject);
begin
  CopyTextToClipboard(TransactionFrame1.TETHashDetailsText.Text, TransactionFrame1.HashCopyLayout);
end;

procedure TMainForm.TransactionFrame2TETBackCircleClick(Sender: TObject);
begin
  TETTabControl.Previous;
end;

procedure TMainForm.TransactionFrame2TETCopyAddressLayoutClick(Sender: TObject);
begin
  CopyTextToClipboard(TransactionFrame2.AddressFromText.Text, TransactionFrame2.AddressFromCopyLayout);
end;

procedure TMainForm.TransactionFrame2TETCopyLoginLayoutClick(Sender: TObject);
begin
  CopyTextToClipboard(TransactionFrame2.TETHashDetailsText.Text, TransactionFrame2.HashCopyLayout);
end;

procedure TMainForm.TransactionFrame3TETBackCircleClick(Sender: TObject);
begin
  StakingTabControl.Previous;
end;

procedure TMainForm.TransactionFrame3TETCopyAddressLayoutClick(Sender: TObject);
begin
  CopyTextToClipboard(TransactionFrame3.AddressFromText.Text, TransactionFrame3.AddressFromCopyLayout);
end;

procedure TMainForm.TransactionFrame3TETCopyLoginLayoutClick(Sender: TObject);
begin
  CopyTextToClipboard(TransactionFrame3.TETHashDetailsText.Text, TransactionFrame3.HashCopyLayout);
end;

procedure TMainForm.TxMaxAmountButtonClick(Sender: TObject);
begin
  AmountTETEdit.Text := AmountToStr(CalculateMaxSendValue(FBalance));
end;

procedure TMainForm.NewTETChainBlocksEvent;
begin
  WaitDataLayout.Visible := False;
  AddressTETLabel.Text := AppCore.Address;
  RefreshBalances;
  if TransactionNavigation.PageNum = 1 then
    RefreshUserTransactions;
  if StakingNavigation.PageNum = 1 then
    RefreshUserStaking;
  if ExplorerNavigation.PageNum = 1 then
    RefreshExplorer;
end;

procedure TMainForm.onExplorerFrameClick(Sender: TObject);
begin
  var F := TExplorerTransactionFrame(Sender);
  F.UpdateTransaction;
  TransactionFrame1.SetTrx(F.Transaction);
  ExplorerTabControl.Next;
end;

procedure TMainForm.onTETHistoryFrameClick(Sender: TObject);
begin
  var F := THistoryTransactionFrame(Sender);
  F.UpdateTransaction;
  TransactionFrame2.SetTrxAsUser(F.Transaction);
  TETTabControl.Next;
end;

procedure TMainForm.onStakingHistoryFrameClick(Sender: TObject);
begin
  var F := TStakingTransactionFrame(Sender);
  F.UpdateTransaction;
  TransactionFrame3.SetTrxAsStaking(F.Transaction);
  StakingTabControl.Next;
end;

procedure TMainForm.CopiedAnimationFinish(Sender: TObject);
begin
  CopiedRectangle.Visible := False;
end;

procedure TMainForm.RefreshBalances;
begin

  FBalance := AppCore.GetTokenBalance(AppCore.Address);
  FStakingBalance := AppCore.GetStakingBalance(AppCore.Address);

  StakingMaxAmountLabel.Text := FStakingMaxAmountText+' '+AmountToStr(FBalance, True);
  UnstakingMaxAmountLabel.Text := FUnstakingMaxAmountText+' '+AmountToStr(FStakingBalance, True);

  BalanceTETValueLabel.Text := AmountToStr(FBalance,True);
  StakeBalanceLabel.Text := AmountToStr(FStakingBalance,True);

  var R:=AppCore.GetStakingReward(AppCore.Address);

  StakingRewardAmountLabel.Text := AmountToStr(R.Amount, True);
  RewardDaysLabel.Text := R.Days.ToString + ' Days';

end;

procedure TMainForm.RefreshUserTransactions;
const
  MaxTransactionsNumber = 20;
begin

  var Transactions := AppCore.GetUserLastTransactions(AppCore.Address, 0, Int64.MaxValue);
  var RecordCount: UInt64 := 0;

  HistoryTETVertScrollBox.BeginUpdate;
  try

    HistoryTETVertScrollBox.Content.DeleteChildren;

    for var Trx in Transactions do
    if Trx.TxType = 'transfer' then
    begin
      Inc(RecordCount);
      if InRange(RecordCount, (TransactionNavigation.PageNum-1)*MaxTransactionsNumber+1,
                (TransactionNavigation.PageNum)*MaxTransactionsNumber-1) then
      begin
        var F := THistoryTransactionFrame.Create(HistoryTETVertScrollBox);
        F.SetData(Trx, Trx.AddressTo=AppCore.Address);
        F.OnClick := onTETHistoryFrameClick;
        F.Parent := HistoryTETVertScrollBox;
      end;
    end;

    TransactionNavigation.PagesCount := Ceil(RecordCount/MaxTransactionsNumber);

  finally
    HistoryTETVertScrollBox.EndUpdate;
    HistoryTETVertScrollBox.RealignContent;
    HistoryTETVertScrollBox.RecalcSize;
  end;

  NoTETHistoryLabel.Visible := HistoryTETVertScrollBox.Content.ChildrenCount=0;
  HistoryTETHeaderLayout.Visible := not NoTETHistoryLabel.Visible;
  HistoryTETVertScrollBox.Visible := not NoTETHistoryLabel.Visible;

end;

procedure TMainForm.RefreshUserStaking;
const
  MaxTransactionsNumber = 20;
begin

  var RecordCount: UInt64 := 0;
  var Transactions: TArray<TTransactionInfo>;

  EnumUserTxns(AppCore.Address,procedure (const Txn: TTransactionInfo)
  begin
    if InArray(Txn.TxType,['stake','unstake','reward']) then
    begin
      Inc(RecordCount);
      if InRange(RecordCount, (StakingNavigation.PageNum-1)*MaxTransactionsNumber+1,
                (StakingNavigation.PageNum)*MaxTransactionsNumber) then
        Transactions := Transactions+[Txn];
    end;
  end);

  var PagesCount := Ceil(RecordCount/MaxTransactionsNumber);

  StakingNavigation.PagesCount := PagesCount;

  StakingScrollBox.BeginUpdate;
  try

    StakingScrollBox.Content.DeleteChildren;

    for var Trx in Transactions do
    begin
      var F := TStakingTransactionFrame.Create(StakingScrollBox);
      F.SetData(Trx);
      F.OnClick := onStakingHistoryFrameClick;
      F.Parent := StakingScrollBox;
    end;

  finally
    StakingScrollBox.EndUpdate;
    StakingScrollBox.RealignContent;
    StakingScrollBox.RecalcSize;
  end;

  NoStakingLabel.Visible := StakingScrollBox.Content.ChildrenCount=0;
  StakingHeaderLayout.Visible := not NoStakingLabel.Visible;
  StakingScrollBox.Visible := not NoStakingLabel.Visible;

end;

procedure TMainForm.RefreshExplorer;
begin
  if SearchEdit.TagString.IsEmpty then
    RefreshExplorerRaw
  else
    RefreshExplorerText(SearchEdit.TagString.ToLower);
end;

procedure TMainForm.RefreshExplorerRaw;
const
  MaxTransactionsNumber = 20;
begin

  var RecordCount := TMemBlock<TTxn>.RecordsCount(TTxn.Filename);
  var PagesCount := Ceil(RecordCount/MaxTransactionsNumber);

  ExplorerNavigation.PagesCount:=PagesCount;

  var Transactions := AppCore.GetLastTransactions((ExplorerNavigation.PageNum-1)*MaxTransactionsNumber, MaxTransactionsNumber);

  ExplorerVertScrollBox.BeginUpdate;
  try

    ExplorerVertScrollBox.Content.DeleteChildren;

    for var Trx in Transactions do
    begin
      var F := TExplorerTransactionFrame.Create(ExplorerVertScrollBox);
      F.SetData(Trx);
      F.OnClick := onExplorerFrameClick;
      F.Parent := ExplorerVertScrollBox;
    end;

  finally
    ExplorerVertScrollBox.EndUpdate;
    ExplorerVertScrollBox.RealignContent;
    ExplorerVertScrollBox.RecalcSize;
  end;

end;

procedure TMainForm.RefreshExplorerText(const Text: string);
const
  MaxTransactionsNumber = 20;
begin

  var RecordCount: UInt64 := 0;
  var Transactions: TArray<TTransactionInfo>;

  EnumTxns(procedure (const Txn: TTransactionInfo)
  begin
    if Txn.AddressFrom.Contains(Text) or
       Txn.AddressTo.Contains(Text) or
       Txn.Hash.Contains(Text) then
    begin
      Inc(RecordCount);
      if InRange(RecordCount, (ExplorerNavigation.PageNum-1)*MaxTransactionsNumber+1,
                (ExplorerNavigation.PageNum)*MaxTransactionsNumber) then
        Transactions := Transactions+[Txn];
    end;

  end);

  var PagesCount := Ceil(RecordCount/MaxTransactionsNumber);

  ExplorerNavigation.PagesCount := PagesCount;

  ExplorerVertScrollBox.BeginUpdate;
  try

    ExplorerVertScrollBox.Content.DeleteChildren;

    for var Trx in Transactions do
    begin
      var F := TExplorerTransactionFrame.Create(ExplorerVertScrollBox);
      F.SetData(Trx);
      F.OnClick := onExplorerFrameClick;
      F.Parent := ExplorerVertScrollBox;
    end;

  finally
    ExplorerVertScrollBox.EndUpdate;
    ExplorerVertScrollBox.RealignContent;
    ExplorerVertScrollBox.RecalcSize;
  end;

end;

procedure TMainForm.SearchButtonClick(Sender: TObject);
begin
  ExplorerNavigation.PageNum := 1;
  SearchEdit.TagString := SearchEdit.Text;
  RefreshExplorer;
  SearchEdit.SetFocus;
end;

procedure TMainForm.SearchEditChangeTracking(Sender: TObject);
begin
  SearchButton.Enabled := not SearchEdit.Text.IsEmpty;
  if SearchEdit.Text.IsEmpty then
  begin
    SearchEdit.TagString := '';
    ExplorerNavigation.PageNum := 1;
    RefreshExplorer;
  end;
end;

procedure TMainForm.SearchEditKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
begin
  if not SearchEdit.Text.IsEmpty and (Key = vkReturn) then
  begin
    SearchEdit.TagString := SearchEdit.Text;
    ExplorerNavigation.PageNum := 1;
    RefreshExplorer;
  end;
end;

procedure TMainForm.SendTETButtonClick(Sender: TObject);
begin

  try
    ShowTETTransferStatus(AppCore.DoTokenTransfer(AppCore.Address, SendTETToEdit.Text,
      StrToAmount(AmountTETEdit.Text), AppCore.PrKey), False);
  except on E:Exception do
    begin
      Logs.DoLog('Transfer error: ' + E.Message, CmnLvlLogs, ltError);
      ShowTETTransferStatus(E.Message, True);
    end;
  end;

end;

procedure ShowStatus(const AMessage: string; AIsError: Boolean; Control: TEdit; Animation: TAnimation);
begin

  Control.Text := AMessage;
  Control.Repaint;

  if AIsError then
    Control.TextSettings.FontColor := ERROR_TEXT_COLOR
  else
    Control.TextSettings.FontColor := SUCCESS_TEXT_COLOR;

  Animation.Start;

end;

procedure TMainForm.ShowTETTransferStatus(const AMessage: string; AIsError: Boolean);
begin
  ShowStatus(AMessage, AIsError, StatusText, FloatAnimation2);
end;

procedure TMainForm.ShowStakeStatus(const AMessage: string; AIsError: Boolean = False);
begin
  StakingStatusText.Visible := not AMessage.IsEmpty;
  ShowStatus(AMessage, AIsError, StakingStatusText, FloatAnimation5);
end;

procedure TMainForm.ShowUnstakeStatus(const AMessage: string; AIsError: Boolean = False);
begin
  UnstakingStatusText.Visible := not AMessage.IsEmpty;
  ShowStatus(AMessage, AIsError, UnstakingStatusText, FloatAnimation6);
end;

procedure TMainForm.ShowKeyStatus(const AMessage: string; AIsError: Boolean = False);
begin
  PrivateKeyStatusEdit.Visible := not AMessage.IsEmpty;
  ShowStatus(AMessage, AIsError, PrivateKeyStatusEdit, FloatAnimation7);
end;

procedure TMainForm.StakeAmountEditEnter(Sender: TObject);
begin
  ShowStakeStatus('');
end;

procedure TMainForm.StakeButtonClick(Sender: TObject);
begin

  try
    ShowStakeStatus(AppCore.DoTokenStake(AppCore.Address, StrToAmount(StakeAmountEdit.Text),
      AppCore.PrKey), False);
  except on E:Exception do
    begin
      Logs.DoLog('Stake error: ' + E.Message, CmnLvlLogs, ltError);
      ShowStakeStatus(E.Message, True);
    end;
  end;

end;

procedure TMainForm.UnstakeAmountEditEnter(Sender: TObject);
begin
  ShowUnstakeStatus('');
end;

procedure TMainForm.UnstakeButtonClick(Sender: TObject);
begin

  try
    ShowUnstakeStatus(AppCore.DoTokenUnstake(AppCore.Address, StrToAmount(UnstakeAmountEdit.Text),
      AppCore.PrKey), False);
  except on E:Exception do
    begin
      Logs.DoLog('Unstake error: ' + E.Message, CmnLvlLogs, ltError);
      ShowUnstakeStatus(E.Message, True);
    end;
  end;

end;

procedure TMainForm.StakingScrollBoxResized(Sender: TObject);
begin
  ControlsFlexWidth([HeaderStakingDateLabel,HeaderStakingBlockLabel,HeaderStakingAddressLabel,
    HeaderStakingHashLabel,HeaderStakingAmountLabel,HeaderStakingStatusLabel],
    [0.13,0.05,0.3,0.35,0.1,0.07], StakingScrollBox.Content);
end;

procedure TMainForm.OnTransactionPageChange(Sender: TObject);
begin
  RefreshUserTransactions;
end;

procedure TMainForm.OnExplorerPageChange(Sender: TObject);
begin
  RefreshExplorer;
end;

procedure TMainForm.OnStakingPageChange(Sender: TObject);
begin
  RefreshUserStaking;
end;

procedure TMainForm.StakingLayoutResized(Sender: TObject);
begin
  ControlsFlexWidth([StakeLayout,UnstakeLayout], [0.45,0.45], StakingLayout);
  UnstakingMaxAmountLabel.Margins.Top := StakingMaxAmountLabel.Position.Y-StakingRewardLabel1.BoundsRect.Bottom;
  StakeLayout.Realign;
end;

procedure TMainForm.StakingContentChanged(Sender: TObject);
begin
  StakingLayout.Height := Max(StakeButtonLayout.BoundsRect.Bottom, UnstakeButtonLayout.BoundsRect.Bottom);
  UnstakingMaxAmountLabel.Margins.Top := StakingMaxAmountLabel.Position.Y-StakingRewardLabel1.BoundsRect.Bottom;
  if not StakingStatusText.Visible then
    StakingStatusText.Position.Point:=StakeAmountEdit.BoundsRect.TopLeft+Point(0,10);
  if not UnstakingStatusText.Visible then
    UnstakingStatusText.Position.Point:=UnstakeAmountEdit.BoundsRect.TopLeft+Point(0,10);
end;

end.
