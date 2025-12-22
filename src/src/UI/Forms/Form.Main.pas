unit Form.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Math, System.Generics.Collections, System.Generics.Defaults, System.DateUtils,
  System.StrUtils, System.Threading, System.Net.HttpClient,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation,
  FMX.Edit, FMX.TabControl, FMX.Platform, FMX.ListBox, FMX.Effects, FMX.Objects,
  FMX.Layouts, FMX.StdCtrls, FMX.Ani, FMX.Grid.Style, FMX.ScrollBox,
  FMX.Grid, FMX.Memo.Types, FMX.Memo,
  App.Exceptions,
  App.Logs,
  App.Intf,
  App.Types,
  Blockchain.Data,
  Blockchain.Types,
  Blockchain.Utils,
  Desktop.Controls,
  IconUtils,
  Net.Data,
  Styles,
  RegularExpressions,
  Frame.Explorer,
  Frame.History,
  Frame.Reward,
  Frame.Transaction,
  Frame.StakingTransaction,
  Frame.Navigation,
  Frame.Arc;

const
  URLRegEx = '^(https?|ftp):\/\/([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(?::\d+)?(?:\/[^\s?#]*(?:\?[^\s#]*)?(?:#[^\s]*)?)?';

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
    BalanceTECLabel: TLabel;
    BalanceTECValueLabel: TLabel;
    AddressTECLabel: TLabel;
    SendTECToEdit: TEdit;
    ShadowEffect6: TShadowEffect;
    AmountTECEdit: TEdit;
    ShadowEffect7: TShadowEffect;
    SendTECButton: TButton;
    HistoryTECLabel: TLabel;
    HistoryTECHeaderLayout: TLayout;
    DateTimeTECHeaderLabel: TLabel;
    BlockNumTECHeaderLabel: TLabel;
    TECAddressFromHeaderLabel: TLabel;
    HashTECHeaderLabel: TLabel;
    AmountTECHeaderLabel: TLabel;
    BalanceTECHeaderLayout: TLayout;
    SendTECDataLayout: TLayout;
    TokenHeaderLayout: TLayout;
    AddressTokenLabel: TLabel;
    BalanceTokenLabel: TLabel;
    BalanceTokenValueLabel: TLabel;
    SendTokenDataLayout: TLayout;
    HistoryTokenLabel: TLabel;
    AmountTokenHeaderLabel: TLabel;
    BlockNumTokenHeaderLabel: TLabel;
    DateTimeTokenHeaderLabel: TLabel;
    HashTokenHeaderLabel: TLabel;
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
    ExplorerTabControl: TTabControl;
    ExporerTabItemData: TTabItem;
    ExplorerTransactionDataTabItem: TTabItem;
    NoTECHistoryLabel: TLabel;
    TypeTECHeaderLabel: TLabel;
    NoTokenHistoryLabel: TLabel;
    TypeTokenHeaderLabel: TLabel;
    TECTabControl: TTabControl;
    TECTabItemData: TTabItem;
    TECTransactionDataTabItem: TTabItem;
    TokenInfoRectangle: TRectangle;
    TokenShortNameEdit: TEdit;
    TokenInfoMemo: TMemo;
    ExplorerVertScrollBox: TVertScrollBox;
    HistoryTECVertScrollBox: TVertScrollBox;
    HistoryTokenVertScrollBox: TVertScrollBox;
    TokenTabControl: TTabControl;
    TokenTabItemData: TTabItem;
    TokenTransactionDataTabItem: TTabItem;
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
    TECSendButtonLayout: TLayout;
    TECSendLayout: TLayout;
    TECTransferStatusEdit: TEdit;
    FloatAnimation2: TFloatAnimation;
    TxMaxAmountButton: TEditButton;
    TECAddressToHeaderLabel: TLabel;
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
    TransactionFrame3: TTransactionFrame;
    StakingTabControl: TTabControl;
    StakingMainTabItem: TTabItem;
    StakingHeaderLayout: TLayout;
    HeaderStakingDateLabel: TLabel;
    HeaderStakingBlockLabel: TLabel;
    HeaderStakingAddressLabel: TLabel;
    HeaderStakingHashLabel: TLabel;
    HeaderStakingAmountLabel: TLabel;
    HeaderStakingTypeLabel: TLabel;
    StakingHistoryLabel: TLabel;
    NoStakingLabel: TLabel;
    StakingScrollBox: TVertScrollBox;
    StakingDetailTabItem: TTabItem;
    SettingsTab: TTabItem;
    SettingsLabel: TLabel;
    PrivateKeyLabel: TLabel;
    PrivateKeyEdit: TEdit;
    ShadowEffect13: TShadowEffect;
    ChangeKeyButton: TButton;
    PrivateKeyMessageBackground: TRectangle;
    PrivateKeyMessageLayout: TLayout;
    PrivateKeyButtonLayout: TLayout;
    AddressTECLayout: TLayout;
    TECCopyLoginLayout: TLayout;
    TECCopyHashSvg: TPath;
    TypeExplorerHeaderLabel: TLabel;
    SettingsLayout: TLayout;
    PrivateKeyStatusEdit: TEdit;
    FloatAnimation7: TFloatAnimation;
    PrivateKeyMessageLabel: TLabel;
    ExplorerNavigation: TNavigationFrame;
    TECInfoLabel: TLabel;
    StakingNavigationLayout: TLayout;
    StakingNavigation: TNavigationFrame;
    TransactionNavigationLayout: TLayout;
    TransactionNavigation: TNavigationFrame;
    WaitDataLayout: TRectangle;
    WaitDataLabel: TLabel;
    WaitFrame: TArcFrame;
    IconURLLabel: TLabel;
    TokenIconPathEdit: TEdit;
    ShadowEffect2: TShadowEffect;
    CrTokenVertScrollBox: TVertScrollBox;
    MintStatusText: TEdit;
    FloatAnimation3: TFloatAnimation;
    CreateTokenButtonLayout: TLayout;
    MainRectangle: TRectangle;
    PopupRectangle: TRectangle;
    ShadowEffect3: TShadowEffect;
    SearchTokenEdit: TEdit;
    ShadowEffect16: TShadowEffect;
    TokensListBox: TListBox;
    TokenAddressToHeaderLabel: TLabel;
    TokenAddressFromHeaderLabel: TLabel;
    TransactionFrame4: TTransactionFrame;
    TokensTransNavigationLayout: TLayout;
    TokensTransNavigation: TNavigationFrame;
    IconImage: TImage;
    IconRectangle: TRectangle;
    OpenIconDialog: TOpenDialog;
    SelectIconButton: TButton;
    NewTokenHelpIconLayout: TLayout;
    NewTokenHelpIconLabel: TLabel;
    NewTokenHelpIconLabel2: TLabel;
    NewTokenHelpIconLabel3: TLabel;
    TokenTransferStatusEdit: TEdit;
    TokenIconImage: TImage;
    BalanceTokenValueLayout: TLayout;
    AddLiquidityLabel: TLabel;
    AddLiquidityLayout: TLayout;
    pthArrowDown: TPath;
    FloatAnimation9: TFloatAnimation;
    AddLiquidityRectangle: TRectangle;
    AddLiquidityDetailsLayout: TLayout;
    LiquidityMaxAmountLabel: TLabel;
    EnterTECAmountEdit: TEdit;
    ShadowEffect17: TShadowEffect;
    LiquidityMaxButton: TEditButton;
    CreateTokenRateLabel: TLabel;
    BurnTokenRateLabel: TLabel;
    BurnTokenLayout: TLayout;
    BurnTokenButton: TButton;
    BurnTokenAniIndicator: TAniIndicator;
    NewTokenLiquidityLayout: TLayout;
    NewTokenLiquidityInfoLabel: TLabel;
    NewTokenLiquidityLabel2: TLabel;
    NewTokenLiquidityLabel3: TLabel;
    NewTokenLiquidityLabel4: TLabel;
    TokenBurnTabItem: TTabItem;
    TokenBurnDetailsLayout: TLayout;
    TokenBurnDetailsLabel: TLabel;
    TokenBurnBackCircle: TCircle;
    TokenBurnBackArrowPath: TPath;
    TokenBurnAvailableLabel: TLabel;
    TokenBurnLabel: TLabel;
    TokenBurnAmountEdit: TEdit;
    TokenBurnAvailableMaxButton: TEditButton;
    ShadowEffect18: TShadowEffect;
    DoTokenBurnButtonLayout: TLayout;
    DoTokenBurnButton: TButton;
    TokenBurnAmountLayout: TLayout;
    BurnResultInfoLayout: TLayout;
    BurnResultInfoAmountLabel: TLabel;
    BurnResultInfoFeeLabel: TLabel;
    TokenBurnErrorLabel: TLabel;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SendTECButtonClick(Sender: TObject);
    procedure TECCopyLoginLayoutClick(Sender: TObject);
    procedure SearchEditChangeTracking(Sender: TObject);
    procedure SearchButtonClick(Sender: TObject);
    procedure SearchEditKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
    procedure ExplorerVertScrollBoxResized(Sender: TObject);
    procedure HistoryTECVertScrollBoxResized(Sender: TObject);
    procedure UnstakeButtonClick(Sender: TObject);
    procedure StakeButtonClick(Sender: TObject);
    procedure StakingLayoutResized(Sender: TObject);
    procedure CopiedAnimationFinish(Sender: TObject);
    procedure StakeAmountEditEnter(Sender: TObject);
    procedure UnstakeAmountEditEnter(Sender: TObject);
    procedure StakeMaxButtonClick(Sender: TObject);
    procedure UnstakeMaxButtonClick(Sender: TObject);
    procedure TxMaxAmountButtonClick(Sender: TObject);
    procedure TransactionFrame1TECBackCircleMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure TransactionFrame1TECCopyLoginLayoutClick(Sender: TObject);
    procedure TransactionFrame1TECCopyAddressLayoutClick(Sender: TObject);
    procedure TransactionFrame2TECBackCircleClick(Sender: TObject);
    procedure TransactionFrame2TECCopyLoginLayoutClick(Sender: TObject);
    procedure TransactionFrame2TECCopyAddressLayoutClick(Sender: TObject);
    procedure TransactionFrame1Layout2Click(Sender: TObject);
    procedure TransactionFrame3TECBackCircleClick(Sender: TObject);
    procedure TransactionFrame3TECCopyLoginLayoutClick(Sender: TObject);
    procedure TransactionFrame3TECCopyAddressLayoutClick(Sender: TObject);
    procedure StakingScrollBoxResized(Sender: TObject);
    procedure ChangeKeyButtonClick(Sender: TObject);
    procedure PrivateKeyMessageLabelResize(Sender: TObject);
    procedure PrivateKeyEditEnter(Sender: TObject);
    procedure TabsChange(Sender: TObject);
    procedure CreateTokenButtonClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TokenNameEditClick(Sender: TObject);
    procedure MainRectangleMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure SendTokenButtonClick(Sender: TObject);
    procedure RefreshTokenHistory(Sender: TObject);
    procedure TokenNameEditChangeTracking(Sender: TObject);
    procedure HistoryTokenVertScrollBoxResized(Sender: TObject);
    procedure TransactionFrame4TECBackCircleClick(Sender: TObject);
    procedure AmountTokenEditChangeTracking(Sender: TObject);
    procedure SelectIconButtonClick(Sender: TObject);
    procedure AddLiquidityRectangleClick(Sender: TObject);
    procedure FloatAnimation9Process(Sender: TObject);
    procedure LiquidityMaxButtonClick(Sender: TObject);
    procedure CreateTokenAmountEditChangeTracking(Sender: TObject);
    procedure BurnTokenButtonClick(Sender: TObject);
    procedure TokenBurnBackCircleClick(Sender: TObject);
    procedure TransactionFrame4TECBackCircleMouseEnter(Sender: TObject);
    procedure TransactionFrame4TECBackCircleMouseLeave(Sender: TObject);
    procedure TokenBurnBackCircleMouseEnter(Sender: TObject);
    procedure TokenBurnBackCircleMouseLeave(Sender: TObject);
    procedure TokenBurnAvailableMaxButtonClick(Sender: TObject);
    procedure TokenBurnAmountEditChangeTracking(Sender: TObject);
    procedure TokenTabControlChange(Sender: TObject);
    procedure DoTokenBurnButtonClick(Sender: TObject);
  private
    FFailedConnection: Boolean;
    FBalances: TDictionary<string, TTokenBalance>;
    FStakingBalance: UInt64;
    FRewardBalance: UInt64;
    FStakingMaxAmountText: string;
    FUnstakingMaxAmountText: string;
    FLiquidityMaxAmountText: string;
    FRateText: string;
    FTokenBurnText: string;
    FBurnResultTECAmountText: string;
    FBurnResultFeeText: string;

    procedure AddTokenItem(ATicker: string);
    procedure RefreshTokenBalance(ATicker: string);
    procedure CopyTextToClipboard(const Text: string; Control: TControl);
    procedure RefreshBalances;
    procedure RefreshUserTECTransactions;
    procedure RefreshUserTokenTransactions;
    procedure RefreshUserStaking;
    procedure RefreshExplorer;
    procedure RefreshExplorerRaw;
    procedure RefreshExplorerText(const Text: string);
    procedure ShowTECTransferStatus(const AMessage: string; AIsError: Boolean = False);
    procedure ShowTokenTransferStatus(AMessage: string; AIsError: Boolean = False);
    procedure ShowStakeStatus(const AMessage: string; AIsError: Boolean = False);
    procedure ShowUnstakeStatus(const AMessage: string; AIsError: Boolean = False);
    procedure ShowMintStatus(AMessage: string; AIsError: Boolean = False);
    procedure ShowKeyStatus(const AMessage: string; AIsError: Boolean = False);
    procedure LoadImageDesktop(Image: TImage; const Path: string);
    procedure LoadImageAsyncNetHTTP(Image: TImage; const URL: string);
    procedure ClearIconError(const ClearMsg: Boolean = True);
    procedure onTECHistoryFrameClick(Sender: TObject);
    procedure onTokenHistoryFrameClick(Sender: TObject);
    procedure TokenItemClick(Sender: TObject);
    procedure onStakingHistoryFrameClick(Sender: TObject);
    procedure onExplorerFrameClick(Sender: TObject);
    procedure OnTransactionPageChange(Sender: TObject);
    procedure OnExplorerPageChange(Sender: TObject);
    procedure OnStakingPageChange(Sender: TObject);
    procedure OnTokensTransPageChange(Sender: TObject);
    procedure StakingContentChanged(Sender: TObject);
  public
    procedure DataChange;
    procedure DoSynchronize(const Position, Count: UInt64);
    procedure DoConnectionFailed(const Address: string);

    property TokenBalances: TDictionary<string, TTokenBalance> read FBalances;
  end;

  function SortByBalance(Left, Right: TFmxObject): Integer;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
  Desktop;

function DecimalsCount(const AValue: string): Integer;
begin
  const TrimmedValue = AValue //
    .Trim //
    .Replace('.', FormatSettings.DecimalSeparator) //
    .Replace(',', FormatSettings.DecimalSeparator);
  const DecimalPos = Pos(FormatSettings.DecimalSeparator, TrimmedValue);
  if DecimalPos = 0 then begin
    Result := 0;
    Exit;
  end;
  Result := Length(TrimmedValue) - DecimalPos;
end;

function SortByBalance(Left, Right: TFmxObject): Integer;
begin
  var BalanceStr := TLabel(Left.TagObject).Text;
  var LBalance := StrToAmount(BalanceStr);
  BalanceStr := TLabel(Right.TagObject).Text;
  var RBalance := StrToAmount(BalanceStr);

  if LBalance < RBalance then
    Result := 1
  else if LBalance > RBalance then
    Result := -1
  else
    Result := 0;
end;

procedure TLayout.Changed;
begin
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

procedure TMainForm.FloatAnimation9Process(Sender: TObject);
begin
  AddLiquidityDetailsLayout.Height := AddLiquidityDetailsLayout.TagFloat * (1 - FloatAnimation9.NormalizedTime);
  CreateTokenDataLayout.Height := CreateTokenDataLayout.TagFloat + AddLiquidityDetailsLayout.Height;
  AddLiquidityDetailsLayout.Opacity := 1 - FloatAnimation9.NormalizedTime;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Caption := 'Tectum Node ' + AppCore.GetAppVersionText;

  FFailedConnection := False;
  FStakingMaxAmountText := StakingMaxAmountLabel.Text;
  FUnstakingMaxAmountText := UnstakingMaxAmountLabel.Text;
  FLiquidityMaxAmountText := LiquidityMaxAmountLabel.Text;
  FRateText := CreateTokenRateLabel.Text;
  FTokenBurnText := TokenBurnAvailableLabel.Text;
  FBurnResultTECAmountText := BurnResultInfoAmountLabel.Text;
  FBurnResultFeeText := BurnResultInfoFeeLabel.Text;

  CopiedRectangle.Visible := False;

  StakeLayout.FOnChanged := StakingContentChanged;
  UnstakeLayout.FOnChanged := StakingContentChanged;

  HistoryTECHeaderLayout.Visible := False;
  StakingHeaderLayout.Visible := False;

  AddLiquidityDetailsLayout.TagFloat := GetContentRect(AddLiquidityDetailsLayout).Bottom;
  CreateTokenDataLayout.TagFloat := CreateTokenDataLayout.Height;
  AddLiquidityDetailsLayout.Opacity := 0;
  AddLiquidityDetailsLayout.Height := 0;

  FBalances := TDictionary<string, TTokenBalance>.Create;
  BalanceTECValueLabel.Text := AmountToStr(0, 'TEC');
  StakeBalanceLabel.Text := AmountToStr(0, 'TEC');
  AddressTECLabel.Text := AppCore.Address;
  StakingRewardAmountLabel.Text := AmountToStr(0, 'TEC');
  RewardDaysLabel.Text := '0 Days';
  CreateTokenRateLabel.Text := FRateText + '-';
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FBalances.Free;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  Tabs.ActiveTab := TectumTabItem;
  TECTabControl.ActiveTab := TECTabItemData;
  StakingTabControl.ActiveTab := StakingMainTabItem;
  ExplorerTabControl.ActiveTab := ExporerTabItemData;

  ShowTECTransferStatus('', False);
  ShowStakeStatus('', False);
  ShowUnstakeStatus('', False);
  ShowKeyStatus('', False);

  ExplorerNavigation.OnChange := OnExplorerPageChange;
  ExplorerNavigation.PagesCount := 0;
  ExplorerNavigation.PageNum := 1;

  StakingNavigation.OnChange := OnStakingPageChange;
  StakingNavigation.PagesCount := 0;
  StakingNavigation.PageNum := 1;

  TokensTransNavigation.OnChange := OnTokensTransPageChange;
  TokensTransNavigation.PagesCount := 0;
  TokensTransNavigation.PageNum := 1;

  TransactionNavigation.OnChange := OnTransactionPageChange;
  TransactionNavigation.PagesCount := 0;
  TransactionNavigation.PageNum := 1;

  if not (TAppState.Synchronized in AppCore.States) then begin
    WaitFrame.Visible := True;
    WaitFrame.Reset;
    WaitFrame.StartAngle := 0;
    WaitFrame.EndAngle := 280;
    WaitFrame.AnimateStartAngle := True;
    WaitFrame.AnimateLoop := True;
    WaitDataLayout.Visible := True;
  end else
    DataChange;
end;

procedure TMainForm.PrivateKeyEditEnter(Sender: TObject);
begin
  ShowKeyStatus('', False);
end;

procedure TMainForm.StakeMaxButtonClick(Sender: TObject);
begin
  StakeAmountEdit.Text := AmountToStr(AppCore.CalculateMaxSendValue(FBalances['TEC'].Balance));
end;

procedure TMainForm.UnstakeMaxButtonClick(Sender: TObject);
begin
  UnstakeAmountEdit.Text := AmountToStr(FStakingBalance);
end;

procedure TMainForm.LiquidityMaxButtonClick(Sender: TObject);
begin
  EnterTECAmountEdit.Text := AmountToStr(Max(FBalances['TEC'].Balance - 10 * _1_TEC, 0), 'TEC');
end;

procedure TMainForm.ExplorerVertScrollBoxResized(Sender: TObject);
begin
  ControlsFlexWidth([DateTimeExplorerHeaderLabel,BlockNumExplorerHeaderLabel,FromExplorerHeaderLabel,
    ToExplorerHeaderLabel,HashExplorerHeaderLabel,TickerExplorerHeaderLabel,AmountExplorerHeaderLabel,
    TypeExplorerHeaderLabel],
    [0.1,0.05,0.18,0.18,0.225,0.07,0.1,0.08], ExplorerVertScrollBox.Content);
end;

procedure TMainForm.TabsChange(Sender: TObject);
begin
  CopiedRectangle.Visible := False;
end;

procedure TMainForm.HistoryTECVertScrollBoxResized(Sender: TObject);
begin
  ControlsFlexWidth([DateTimeTECHeaderLabel,BlockNumTECHeaderLabel,TECAddressFromHeaderLabel,
    TECAddressToHeaderLabel,HashTECHeaderLabel,AmountTECHeaderLabel,TypeTECHeaderLabel],
    [0.1,0.05,0.2,0.2,0.3,0.1,0.05], HistoryTECVertScrollBox.Content);
end;

procedure TMainForm.HistoryTokenVertScrollBoxResized(Sender: TObject);
begin
  ControlsFlexWidth([DateTimeTokenHeaderLabel,BlockNumTokenHeaderLabel,TokenAddressFromHeaderLabel,
    TokenAddressToHeaderLabel,HashTokenHeaderLabel,AmountTokenHeaderLabel,TypeTokenHeaderLabel],
    [0.1,0.05,0.2,0.2,0.3,0.1,0.05], HistoryTokenVertScrollBox.Content);
end;

procedure TMainForm.MainRectangleMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  MainRectangle.Visible := False;
end;

procedure TMainForm.PrivateKeyMessageLabelResize(Sender: TObject);
begin
  PrivateKeyMessageLayout.Height := PrivateKeyMessageLabel.BoundsRect.Bottom+7;
end;

procedure TMainForm.AddLiquidityRectangleClick(Sender: TObject);
begin
  if not FloatAnimation9.Running then
  begin
    if Assigned(Root) then Root.Focused := nil;
    FloatAnimation9.Inverse := not FloatAnimation9.Inverse;
    FloatAnimation9.Start;
  end;
end;

procedure TMainForm.AddTokenItem(ATicker: string);
var
  NewItem: TListBoxItem;
  BalanceLabel: TLabel;
begin
  NewItem := TListBoxItem.Create(TokensListBox);
  NewItem.BeginUpdate;
  try
    with NewItem do begin
      Name := 'Token' + ATicker + 'Item';
      Margins.Top := 5;
      Margins.Right := 7;
      Height := 38;
      Text := ATicker;
      Cursor := crHandPoint;
      TextSettings.Font.Family := 'Inter';
      TextSettings.Font.Size := 14;
      TextSettings.FontColor := $FF323130;
      HitTest := True;

      StyleLookup := 'TokenItemStyle';
      onMouseEnter := StylesForm.OnTokenItemMouseEnter;
      onMouseLeave := StylesForm.OnTokenItemMouseLeave;
      onMouseDown := StylesForm.OnTokenItemMouseDown;
      onMouseUp := StylesForm.OnTokenItemMouseUp;
      onClick := TokenItemClick;
    end;

    BalanceLabel := TLabel.Create(NewItem);
    NewItem.TagObject := BalanceLabel;
    with BalanceLabel do begin
      Name := 'TokenBalanceText' + ATicker;
      Align := TAlignLayout.Contents;
      Margins.Right := 10;
      HitTest := False;
      StyledSettings := [TStyledSetting.Style, TStyledSetting.FontColor];
      TextSettings.Font.Family := 'Inter';
      TextSettings.Font.Size := 14;
      TextSettings.FontColor := TAlphaColorRec.Black;
      TextSettings.HorzAlign := TTextAlign.Trailing;
      Text := AmountToStr(FBalances[ATicker].Balance, '', FBalances[ATicker].Token.Digits);
      AutoSize := False;
      Parent := NewItem;
    end;
  finally
    NewItem.EndUpdate;
  end;

  TokensListBox.AddObject(NewItem);
  TokenNameEdit.Enabled := True;
  PopupRectangle.Height := SearchTokenEdit.Height +
    40 * (Min(TokensListBox.Count, 3)) + 36;
end;

procedure TMainForm.AmountTokenEditChangeTracking(Sender: TObject);
begin
  var val: Double;
  var isNumber: Boolean := TryStrToFloat(AmountTokenEdit.Text, val);
  var decVal: UInt64;
  if isNumber then
    decVal := Round(val * Power(10, FBalances[TokenNameEdit.Text].Token.Digits));
  const Decimals = DecimalsCount(AmountTokenEdit.Text);

  SendTokenButton.Enabled := (Length(RecepientAddressEdit.Text) = 42) and
    isNumber and (decVal > 0) and (decVal <= FBalances[TokenNameEdit.Text].Balance) and
    (Decimals <= FBalances[TokenNameEdit.Text].Token.Digits);

  with TokenTransferStatusEdit do begin
    if isNumber and (val > FBalances[TokenNameEdit.Text].Balance) then begin
      Text := 'Insufficient funds';
      TextSettings.FontColor := ERROR_TEXT_COLOR;
      Opacity := 1;
    end else
      if (Decimals > FBalances[TokenNameEdit.Text].Token.Digits) then begin
        Text := 'Too much digits';
        TextSettings.FontColor := ERROR_TEXT_COLOR;
        Opacity := 1;
      end else
        Opacity := 0;
  end;
end;

procedure TMainForm.BurnTokenButtonClick(Sender: TObject);
begin
  TokenBurnAvailableLabel.Text := FTokenBurnText + BalanceTokenValueLabel.Text;
  TokenTabControl.SetActiveTabWithTransition(TokenBurnTabItem, TTabTransition.Slide);
end;

procedure TMainForm.ChangeKeyButtonClick(Sender: TObject);
begin
  try
    AppCore.ChangePrivateKey(PrivateKeyEdit.Text);
  except on E: EKeyException do begin
    case E.ErrorCode of
      EKeyException.INVALID_KEY: ShowKeyStatus('Invalid private key, please enter a different one', True);
    else
      ShowKeyStatus(E.Message, True);
    end;
    Exit
    end;
    on E: Exception do begin
      ShowKeyStatus(E.Message, True);
      Exit
    end;
  end;

  AppCore.Reset;
  ShowKeyStatus('Key changed', False);
end;

procedure TMainForm.ClearIconError(const ClearMsg: Boolean);
begin
  IconImage.Bitmap.Clear(0);
  IconRectangle.Stroke.Kind := TBrushKind.Solid;
  if ClearMsg then
    ShowMintStatus('', False);
end;

procedure TMainForm.CopyTextToClipboard(const Text: string; Control: TControl);
begin
  CopyToClipboard(Text);
  CopiedRectangle.Position.Point := Control.LocalToAbsolute(Control.LocalRect.BottomRight);
  CopiedRectangle.Opacity := 1;
  CopiedRectangle.Visible := True;
end;

procedure TMainForm.CreateTokenAmountEditChangeTracking(Sender: TObject);
var
  Amount, Liq: TAmount;
  Rate: Double;
begin
  try
    Amount := StrToAmount(CreateTokenAmountEdit.Text, 8);
    Liq := StrToAmount(EnterTECAmountEdit.Text, 8);
    Rate := Amount / Liq;
    CreateTokenRateLabel.Text := FRateText + Format(' 1 TEC = %s %s',
      [FormatFloat('0.########', Rate), CreateTokenSymbolEdit.Text]);
  except
    on E:Exception do
      CreateTokenRateLabel.Text := FRateText + ' -';
  end;
end;

procedure TMainForm.CreateTokenButtonClick(Sender: TObject);
begin
  try
    try
      var TokenAmount: UInt64 := StrToAmount(CreateTokenAmountEdit.Text,
        DecimalsEdit.Text.ToInteger);
      var LiquidityAmount: UInt64 := StrToAmount(EnterTECAmountEdit.Text);
      ShowMintStatus(AppCore.DoTokenMint(CreateTokenShortNameEdit.Text,
        CreateTokenSymbolEdit.Text, CreateTokenInformationMemo.Text,
        DecimalsEdit.Text.ToInteger, TokenAmount, LiquidityAmount,
        IconToBytes(TokenIconPathEdit.Text), AppCore.PrKey), False);

      CreateTokenShortNameEdit.Text := '';
      CreateTokenSymbolEdit.Text := '';
      CreateTokenAmountEdit.Text := '';
      EnterTECAmountEdit.Text := '';
      DecimalsEdit.Text := '';
      TokenIconPathEdit.Text := '';
      CreateTokenInformationMemo.Text := '';
      ClearIconError(False);
    except
      on E:EConvertError do
      begin
        E.Message := 'fields are not filled';
        raise;
      end;
    end;
  except
    on E:Exception do
    begin
      Logs.DoLog('Mint error: ' + E.Message, ERROR);
      ShowMintStatus(E.Message, True);
    end;
  end;
end;

procedure TMainForm.TokenBurnAmountEditChangeTracking(Sender: TObject);
var
  Amount, Fee: TAmount;
begin
  var TokenData: TToken := AppCore.GetTokenData(TokenNameEdit.Text);
  Amount := StrToAmount(TokenBurnAmountEdit.Text, TokenData.Digits);
  Amount := Trunc(Amount * Power(10, 8 - TokenData.Digits) * TokenData.ExRate);
  Fee := AppCore.CalculateFee(Amount);

  try
    if Amount = 0 then Fee := 0;
    try
      if FBalances['TEC'].Balance <= Fee then
      begin
        TokenBurnErrorLabel.Text := 'Not enough TEC for fee';
        raise EIntOverflow.Create('');
      end;

      TokenBurnErrorLabel.Opacity := 0;
      DoTokenBurnButton.Enabled := Amount > 0;
    except
      TokenBurnErrorLabel.Opacity := 1;
      DoTokenBurnButton.Enabled := False;
    end;
  finally
    BurnResultInfoAmountLabel.Text := FBurnResultTECAmountText + AmountToStr(Amount, 'TEC');
    BurnResultInfoFeeLabel.Text := FBurnResultFeeText + AmountToStr(Fee, 'TEC');
  end;
end;

procedure TMainForm.TokenBurnAvailableMaxButtonClick(Sender: TObject);
begin
  var TokenData: TToken := AppCore.GetTokenData(TokenNameEdit.Text);
  TokenBurnAmountEdit.Text := AmountToStr(FBalances[TokenData.Ticker].Balance,
    TokenData.Ticker, TokenData.Digits);
end;

procedure TMainForm.TokenBurnBackCircleClick(Sender: TObject);
begin
  TokenBurnAmountEdit.Text := '';
  TokenTabControl.SetActiveTabWithTransition(TokenTabItemData, TTabTransition.Slide,
    TTabTransitionDirection.Reversed);
end;

procedure TMainForm.TokenBurnBackCircleMouseEnter(Sender: TObject);
begin
  TransactionFrame4.TECBackCircle.OnMouseEnter(Sender);
end;

procedure TMainForm.TokenBurnBackCircleMouseLeave(Sender: TObject);
begin
  TransactionFrame4.TECBackCircle.OnMouseLeave(Sender);
end;

procedure TMainForm.DoTokenBurnButtonClick(Sender: TObject);
begin
  try
    TokenTabControl.SetActiveTabWithTransition(TokenTabItemData, TTabTransition.Slide, TTabTransitionDirection.Reversed);
    ShowTokenTransferStatus(AppCore.DoTokenBurn(StrToAmount(TokenBurnAmountEdit.Text,
      FBalances[TokenNameEdit.Text].Token.Digits), TokenNameEdit.Text, AppCore.PrKey), False);
  except on E:Exception do begin
      Logs.DoLog('Burn error: ' + E.Message, ERROR);
      ShowTokenTransferStatus(E.Message, True);
    end;
  end;
end;

procedure TMainForm.TECCopyLoginLayoutClick(Sender: TObject);
begin
  CopyTextToClipboard(AddressTECLabel.Text, TECCopyLoginLayout);
end;

procedure TMainForm.TokenItemClick(Sender: TObject);
begin
  var ChosenToken := FBalances[TListBoxItem(Sender).Text];
  TokenNameEdit.Text := TListBoxItem(Sender).Text;
  BalanceTokenValueLabel.Text := AmountToStr(ChosenToken.Balance,
    ChosenToken.Token.Ticker, ChosenToken.Token.Digits);
  BurnTokenLayout.Visible := ChosenToken.Token.ExRate > 0;
  if BurnTokenLayout.Visible then
  begin
    BurnTokenRateLabel.Text := FRateText + Format(' 1 TEC = %s %s',
      [FormatFloat('0.########', 1 / ChosenToken.Token.ExRate), ChosenToken.Token.Ticker]);
    TokenBurnLabel.Text := BurnTokenRateLabel.Text;
  end;

  LoadImageAsyncNetHTTP(TokenIconImage, AppCore.GetTokenData(ChosenToken.Token.Ticker).IconURL);
  MainRectangleMouseDown(nil, TMouseButton.mbLeft, [], 0, 0);

  TokenShortNameEdit.Text := ChosenToken.Token.Name;
  TokenInfoMemo.Text := ChosenToken.Token.Description;
end;

procedure TMainForm.TokenNameEditChangeTracking(Sender: TObject);
begin
  NoTokenHistoryLabel.Text := Format('No %s transactions yet', [TokenNameEdit.Text]);
end;

procedure TMainForm.TokenNameEditClick(Sender: TObject);
begin
  MainRectangle.Visible := True;
end;

procedure TMainForm.TokenTabControlChange(Sender: TObject);
begin
  if TokenTabControl.TabIndex = 2 then
    TokenBurnAmountEditChangeTracking(TokenBurnAmountEdit);
end;

procedure TMainForm.TransactionFrame1TECBackCircleMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  ExplorerTabControl.Previous;
end;

procedure TMainForm.TransactionFrame1TECCopyAddressLayoutClick(Sender: TObject);
begin
  CopyTextToClipboard(TransactionFrame1.AddressFromText.Text, TransactionFrame1.AddressFromCopyLayout);
end;

procedure TMainForm.TransactionFrame1Layout2Click(Sender: TObject);
begin
  CopyTextToClipboard(TransactionFrame1.AddressToText.Text, TransactionFrame1.AddressToCopyLayout);
end;

procedure TMainForm.TransactionFrame1TECCopyLoginLayoutClick(Sender: TObject);
begin
  CopyTextToClipboard(TransactionFrame1.TECHashDetailsText.Text, TransactionFrame1.HashCopyLayout);
end;

procedure TMainForm.TransactionFrame2TECBackCircleClick(Sender: TObject);
begin
  TECTabControl.Previous;
end;

procedure TMainForm.TransactionFrame2TECCopyAddressLayoutClick(Sender: TObject);
begin
  CopyTextToClipboard(TransactionFrame2.AddressFromText.Text, TransactionFrame2.AddressFromCopyLayout);
end;

procedure TMainForm.TransactionFrame2TECCopyLoginLayoutClick(Sender: TObject);
begin
  CopyTextToClipboard(TransactionFrame2.TECHashDetailsText.Text, TransactionFrame2.HashCopyLayout);
end;

procedure TMainForm.TransactionFrame3TECBackCircleClick(Sender: TObject);
begin
  StakingTabControl.Previous;
end;

procedure TMainForm.TransactionFrame3TECCopyAddressLayoutClick(Sender: TObject);
begin
  CopyTextToClipboard(TransactionFrame3.AddressFromText.Text, TransactionFrame3.AddressFromCopyLayout);
end;

procedure TMainForm.TransactionFrame3TECCopyLoginLayoutClick(Sender: TObject);
begin
  CopyTextToClipboard(TransactionFrame3.TECHashDetailsText.Text, TransactionFrame3.HashCopyLayout);
end;

procedure TMainForm.TransactionFrame4TECBackCircleClick(Sender: TObject);
begin
  TokenTabControl.Previous;
end;

procedure TMainForm.TransactionFrame4TECBackCircleMouseEnter(Sender: TObject);
begin
  TransactionFrame4.TECBackCircleMouseEnter(Sender);
end;

procedure TMainForm.TransactionFrame4TECBackCircleMouseLeave(Sender: TObject);
begin
  TransactionFrame4.TECBackCircleMouseLeave(Sender);
end;

procedure TMainForm.TxMaxAmountButtonClick(Sender: TObject);
begin
  AmountTECEdit.Text := AmountToStr(AppCore.CalculateMaxSendValue(FBalances['TEC'].Balance));
end;

procedure TMainForm.DataChange;
begin
  WaitFrame.Visible := False;
  WaitFrame.AnimateLoop := False;
  WaitDataLayout.Visible := False;
  AddressTECLabel.Text := AppCore.Address;
  RefreshBalances;
  if TransactionNavigation.PageNum = 1 then begin
    RefreshUserTECTransactions;
    RefreshUserTokenTransactions;
  end;
  if StakingNavigation.PageNum = 1 then
    RefreshUserStaking;
  if ExplorerNavigation.PageNum = 1 then
    RefreshExplorer;
end;

procedure TMainForm.DoSynchronize(const Position, Count: UInt64);
begin
  WaitFrame.AnimateEndAngleTo(Max(30, 360*Min(0.95, Position/Count)));
end;

procedure TMainForm.DoConnectionFailed(const Address: string);
begin
  if not FFailedConnection then begin
    FFailedConnection := True;
    UI.ShowWarning('Not connected to ' + Address, nil);
  end;
end;

procedure TMainForm.onExplorerFrameClick(Sender: TObject);
begin
  var F := TExplorerTransactionFrame(Sender);
  F.UpdateTransaction;
  TransactionFrame1.SetTrx(F.Transaction);
  ExplorerTabControl.Next;
end;

procedure TMainForm.onTECHistoryFrameClick(Sender: TObject);
begin
  var F := THistoryTransactionFrame(Sender);
  F.UpdateTransaction;
  TransactionFrame2.SetTrxAsUser(F.Transaction);
  TECTabControl.Next;
end;

procedure TMainForm.onStakingHistoryFrameClick(Sender: TObject);
begin
  var F := TStakingTransactionFrame(Sender);
  F.UpdateTransaction;
  TransactionFrame3.SetTrxAsStaking(F.Transaction);
  StakingTabControl.Next;
end;

procedure TMainForm.onTokenHistoryFrameClick(Sender: TObject);
begin
  var F := THistoryTransactionFrame(Sender);
  F.UpdateTransaction;
  TransactionFrame4.SetTrxAsUser(F.Transaction, False);
  TokenTabControl.Next;
end;

procedure TMainForm.CopiedAnimationFinish(Sender: TObject);
begin
  CopiedRectangle.Visible := False;
end;

procedure TMainForm.RefreshBalances;
begin
  for var token in AppCore.GetTokensData do begin
    var TokenBalance: TTokenBalance;
    TokenBalance.Token := token;
    TokenBalance.Balance := AppCore.GetTokenBalance(AppCore.Address, token.Id);
    if token.Id = 0 then
      Dec(TokenBalance.Balance, AppCore.GetStakingBalance(AppCore.Address));
    FBalances.AddOrSetValue(token.Ticker, TokenBalance);
    RefreshTokenBalance(token.Ticker);
  end;

  TokensTabItem.Visible := FBalances.Count > 1;
  if TokenNameEdit.Text.IsEmpty and TokensTabItem.Visible then
    TokensListBox.ItemByIndex(0).OnClick(TokensListBox.ItemByIndex(0));

  FStakingBalance := AppCore.GetStakingBalance(AppCore.Address);
  FRewardBalance := AppCore.GetRewardBalance(AppCore.Address);

  StakingMaxAmountLabel.Text := FStakingMaxAmountText+' '+AmountToStr(FBalances['TEC'].Balance, 'TEC');
  UnstakingMaxAmountLabel.Text := FUnstakingMaxAmountText+' '+AmountToStr(FStakingBalance, 'TEC');
  LiquidityMaxAmountLabel.Text := FLiquidityMaxAmountText + ' ' +
    AmountToStr(Max(FBalances['TEC'].Balance,  10 * _1_TEC) - 10 * _1_TEC, 'TEC');

  BalanceTECValueLabel.Text := AmountToStr(FBalances['TEC'].Balance,'TEC');
  StakeBalanceLabel.Text := AmountToStr(FStakingBalance,'TEC');

  var R := AppCore.GetStakingInfo(AppCore.Address);

  StakingRewardAmountLabel.Text := AmountToStr(FRewardBalance, 'TEC');
  RewardDaysLabel.Text := R.Days.ToString + ' Days';
end;

procedure TMainForm.RefreshUserTECTransactions;
const
  MaxTransactionsNumber = 20;
begin
  var Transactions := AppCore.GetUserLastTransactions(AppCore.Address, 0, Int64.MaxValue);
  var RecordsCount: UInt64 := 0;

  HistoryTECVertScrollBox.BeginUpdate;
  try
    HistoryTECVertScrollBox.Content.DeleteChildren;

    for var Trx in Transactions do
      if (Trx.TxType = 'transfer') or (Trx.TxType = 'burn') or (Trx.TxType = 'migrate') or
        (Trx.TxType = 'block') then
      begin
        Inc(RecordsCount);
        if InRange(RecordsCount, (TransactionNavigation.PageNum-1)*MaxTransactionsNumber+1,
                  (TransactionNavigation.PageNum)*MaxTransactionsNumber-1) then
        begin
          var F := THistoryTransactionFrame.Create(HistoryTECVertScrollBox);
          F.SetData(Trx, (Trx.TxType = 'burn') or (Trx.TxType = 'migrate') or
            (Trx.TxType = 'block') or (Trx.AddressTo=AppCore.Address), True);
          F.OnClick := onTECHistoryFrameClick;
          F.Parent := HistoryTECVertScrollBox;
        end;
      end;

    TransactionNavigation.PagesCount := Ceil(RecordsCount/MaxTransactionsNumber);

  finally
    HistoryTECVertScrollBox.EndUpdate;
    HistoryTECVertScrollBox.RealignContent;
    HistoryTECVertScrollBox.RecalcSize;
  end;

  NoTECHistoryLabel.Visible := HistoryTECVertScrollBox.Content.ChildrenCount=0;
  TransactionNavigationLayout.Visible := not NoTECHistoryLabel.Visible;
  HistoryTECHeaderLayout.Visible := not NoTECHistoryLabel.Visible;
  HistoryTECVertScrollBox.Visible := not NoTECHistoryLabel.Visible;
end;

procedure TMainForm.RefreshUserTokenTransactions;
const
  MaxTransactionsNumber = 20;
begin
  var Transactions := AppCore.GetUserLastTransactions(AppCore.Address, 0, Int64.MaxValue, TokenNameEdit.Text);
  var RecordsCount: UInt64 := 0;

  HistoryTokenVertScrollBox.BeginUpdate;
  try
    HistoryTokenVertScrollBox.Content.DeleteChildren;

    for var Trx in Transactions do
      if (Trx.TxType = 'transfer') or (Trx.TxType = 'mint') or (Trx.TxType = 'burn') then begin
        Inc(RecordsCount);
        if InRange(RecordsCount, (TokensTransNavigation.PageNum-1)*MaxTransactionsNumber+1,
                  (TokensTransNavigation.PageNum)*MaxTransactionsNumber-1) then
        begin
          var F := THistoryTransactionFrame.Create(HistoryTokenVertScrollBox);
          F.SetData(Trx, (Trx.TxType <> 'burn') and (Trx.AddressTo=AppCore.Address));
          F.OnClick := onTokenHistoryFrameClick;
          F.Parent := HistoryTokenVertScrollBox;
        end;
      end;

    TokensTransNavigation.PagesCount := Ceil(RecordsCount/MaxTransactionsNumber);
  finally
    HistoryTokenVertScrollBox.EndUpdate;
    HistoryTokenVertScrollBox.RealignContent;
    HistoryTokenVertScrollBox.RecalcSize;
  end;

  NoTokenHistoryLabel.Visible := HistoryTokenVertScrollBox.Content.ChildrenCount=0;
  TokensTransNavigationLayout.Visible := not NoTokenHistoryLabel.Visible;
  HistoryTokenHeaderLayout.Visible := not NoTokenHistoryLabel.Visible;
  HistoryTokenVertScrollBox.Visible := not NoTokenHistoryLabel.Visible;
end;

procedure TMainForm.RefreshUserStaking;
const
  MaxTransactionsNumber = 20;
begin
  var RecordsCount: UInt64 := 0;
  var Transactions: TArray<TTransactionInfo>;
  var PrevCommandType: string := '';
  var PrevAddrFrom: string := '';

  AppCore.EnumTxns(procedure (const Txn: TTransactionInfo; var Continued: Boolean)
  begin
    if MatchText(Txn.TxType, ['transfer']) then
      PrevAddrFrom := Txn.AddressFrom
    else if MatchText(Txn.TxType, ['stake', 'unstake']) then begin
      if (Txn.AddressFrom = AppCore.Address) or
         (Txn.AddressFrom = Copy(AppCore.Address, 3, Length(AppCore.Address))) or
         (Txn.AddressTo = AppCore.Address) or
         (Txn.AddressTo = Copy(AppCore.Address, 3, Length(AppCore.Address))) then
      begin
         Inc(RecordsCount);
        if InRange(RecordsCount, (StakingNavigation.PageNum-1)*MaxTransactionsNumber+1,
                  (StakingNavigation.PageNum)*MaxTransactionsNumber) then
          Transactions := Transactions + [Txn];
      end;
    end else
    if MatchText(Txn.TxType, ['validate4']) then begin
      if (Length(Transactions) > 0) and MatchText(PrevCommandType, ['stake', 'unstake']) and
        (Length(Transactions[Length(Transactions) - 1].Rewards) = 0) then
        Transactions[Length(Transactions) - 1].Rewards := Txn.Rewards;

      for var RewardInfo in Txn.Rewards do begin
        if (RewardInfo.Address = AppCore.Address) or
           (RewardInfo.Address = Copy(AppCore.Address, 3, Length(AppCore.Address))) then
        begin
          Inc(RecordsCount);
          if InRange(RecordsCount, (StakingNavigation.PageNum-1)*MaxTransactionsNumber+1,
                    (StakingNavigation.PageNum)*MaxTransactionsNumber) then
          begin
            Transactions := Transactions + [Txn];

            if MatchText(PrevCommandType, ['stake', 'unstake', 'transfer']) then
              Transactions[Length(Transactions) - 1].Amount := RewardInfo.Amount;
            if MatchText(PrevCommandType, ['transfer']) then
              Transactions[Length(Transactions) - 1].AddressFrom := PrevAddrFrom;
          end;
        end;
      end;
    end;

    PrevCommandType := Txn.TxType;
  end);

  var PagesCount := Ceil(RecordsCount/MaxTransactionsNumber);

  StakingNavigation.PagesCount := PagesCount;

  StakingScrollBox.BeginUpdate;
  try
    StakingScrollBox.Content.DeleteChildren;

    for var Trx in Transactions do begin
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
  StakingNavigationLayout.Visible := not NoStakingLabel.Visible;
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
  const RecordsCount = Max(AppCore.RecordsCount - AppCore.Valid4RecordsCount, 0);
  const PagesCount = Ceil(RecordsCount/MaxTransactionsNumber);

  ExplorerNavigation.PagesCount := PagesCount;

  const Transactions = AppCore.GetLastTransactions((ExplorerNavigation.PageNum-1)*MaxTransactionsNumber, MaxTransactionsNumber);

  ExplorerVertScrollBox.BeginUpdate;
  try
    ExplorerVertScrollBox.Content.DeleteChildren;

    for var Trx in Transactions do begin
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
  var RecordsCount: UInt64 := 0;
  var Transactions: TArray<TTransactionInfo>;

  AppCore.EnumTxns(procedure (const Txn: TTransactionInfo; var Continued: Boolean)
  begin
    if Txn.AddressFrom.Contains(Text) or
       Txn.AddressTo.Contains(Text) or
       Txn.Hash.Contains(Text) then
    begin
      Inc(RecordsCount);
      if InRange(RecordsCount, (ExplorerNavigation.PageNum-1)*MaxTransactionsNumber+1,
                (ExplorerNavigation.PageNum)*MaxTransactionsNumber) then
        Transactions := Transactions+[Txn];
    end;
  end);

  var PagesCount := Ceil(RecordsCount/MaxTransactionsNumber);
  ExplorerNavigation.PagesCount := PagesCount;

  ExplorerVertScrollBox.BeginUpdate;
  try
    ExplorerVertScrollBox.Content.DeleteChildren;

    for var Trx in Transactions do begin
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

procedure TMainForm.RefreshTokenBalance(ATicker: string);
begin
  if ATicker = 'TEC' then
    exit;

  try
    var id := TokensListBox.Items.IndexOf(ATicker);
    if id = -1 then begin
      AddTokenItem(ATicker);
      exit;
    end else begin
      var ValText := TokensListBox.ItemByIndex(id).FindComponent('TokenBalanceText' + ATicker);
      if Assigned(ValText) then
        TLabel(ValText).Text := AmountToStr(FBalances[ATicker].Balance,
          '', FBalances[ATicker].Token.Digits);
      if BalanceTokenValueLabel.Text.EndsWith(ATicker) then
      begin
        BalanceTokenValueLabel.Text := AmountToStr(FBalances[ATicker].Balance,
          FBalances[ATicker].Token.Ticker, FBalances[ATicker].Token.Digits);
        TokenBurnAvailableLabel.Text := FTokenBurnText + BalanceTokenValueLabel.Text;
      end;
    end;
  finally
    TokensListBox.Sort(SortByBalance);
  end;
end;

procedure TMainForm.RefreshTokenHistory(Sender: TObject);
begin
  RefreshUserTokenTransactions;
  AmountTokenEdit.Text := '';
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
  if SearchEdit.Text.IsEmpty then begin
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

procedure TMainForm.SelectIconButtonClick(Sender: TObject);
begin
  if OpenIconDialog.Execute then
  begin
    TokenIconPathEdit.Text := OpenIconDialog.FileName;
    var IsIconValid := TokenIconPathEdit.Text.IsEmpty or ((Length(TokenIconPathEdit.Text) >= 10) and
        (Length(TokenIconPathEdit.Text) <= 128) and FileExists(TokenIconPathEdit.Text));
    if not TokenIconPathEdit.Text.IsEmpty then
    begin
      if IsIconValid then
        LoadImageDesktop(IconImage, TokenIconPathEdit.Text)
      else begin
        ClearIconError;
        ShowMintStatus('Invalid icon', True);
      end;
    end else
    begin
      ClearIconError;
      ShowMintStatus('Invalid icon', True);
    end;
  end;

  TokenIconPathEdit.SetFocus;
end;

procedure TMainForm.SendTECButtonClick(Sender: TObject);
begin
  try
    ShowTECTransferStatus(AppCore.DoTokenTransfer(AppCore.Address, SendTECToEdit.Text,
      StrToAmount(AmountTECEdit.Text), AppCore.PrKey, 0 {TEC id}), False);
  except on E:Exception do begin
      Logs.DoLog('Transfer error: ' + E.Message, ERROR);
      ShowTECTransferStatus(E.Message, True);
    end;
  end;
end;

procedure TMainForm.SendTokenButtonClick(Sender: TObject);
begin
  try
    ShowTokenTransferStatus(AppCore.DoTokenTransfer(AppCore.Address, RecepientAddressEdit.Text,
      StrToAmount(AmountTokenEdit.Text, FBalances[TokenNameEdit.Text].Token.Digits),
      AppCore.PrKey, FBalances[TokenNameEdit.Text].Token.Id), False);
  except on E:Exception do begin
      Logs.DoLog('Transfer error: ' + E.Message, ERROR);
      ShowTokenTransferStatus(E.Message, True);
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

procedure TMainForm.ShowTECTransferStatus(const AMessage: string; AIsError: Boolean);
begin
  TECTransferStatusEdit.Visible := not AMessage.IsEmpty;
  ShowStatus(AMessage, AIsError, TECTransferStatusEdit, FloatAnimation2);
end;

procedure TMainForm.ShowTokenTransferStatus(AMessage: string; AIsError: Boolean);
begin
  TokenTransferStatusEdit.Visible := not AMessage.IsEmpty;
  if not AIsError then
    AMessage := 'Hash: ' + AMessage
  else
    AMessage := 'Error: ' + AMessage;

  ShowStatus(AMessage, AIsError, TokenTransferStatusEdit, FloatAnimation1);
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

procedure TMainForm.ShowMintStatus(AMessage: string; AIsError: Boolean = False);
begin
  MintStatusText.Visible := not AMessage.IsEmpty;
  if not AIsError then
    AMessage := 'Token created. Hash: ' + AMessage
  else
    AMessage := 'Error: ' + AMessage;

  ShowStatus(AMessage, AIsError, MintStatusText, FloatAnimation3);
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
  except on E:Exception do begin
      Logs.DoLog('Stake error: ' + E.Message, ERROR);
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
  except on E:Exception do begin
      Logs.DoLog('Unstake error: ' + E.Message, ERROR);
      ShowUnstakeStatus(E.Message, True);
    end;
  end;
end;

procedure TMainForm.StakingScrollBoxResized(Sender: TObject);
begin
  ControlsFlexWidth([HeaderStakingDateLabel,HeaderStakingBlockLabel,HeaderStakingAddressLabel,
    HeaderStakingHashLabel,HeaderStakingAmountLabel,HeaderStakingTypeLabel],
    [0.13,0.05,0.3,0.35,0.1,0.07], StakingScrollBox.Content);
end;

procedure TMainForm.OnTokensTransPageChange(Sender: TObject);
begin
  RefreshUserTokenTransactions;
end;

procedure TMainForm.OnTransactionPageChange(Sender: TObject);
begin
  RefreshUserTECTransactions;
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

procedure TMainForm.LoadImageDesktop(Image: TImage; const Path: string);
begin
  try
    const stream = TFileStream.Create(Path, fmOpenRead or fmShareDenyNone);
    AddRelease(stream);
    DoCheckPNG(stream);
    stream.Position := 0;
    Image.BitMap.LoadFromStream(Stream);

    IconRectangle.Stroke.Kind := TBrushKind.None;
    ShowMintStatus('', False);
  except
    on E: Exception do
    begin
      ShowMintStatus(E.Message, True);
      Image.Bitmap.Clear(0);
      IconRectangle.Stroke.Kind := TBrushKind.Solid;
    end;
  end;
end;

procedure TMainForm.LoadImageAsyncNetHTTP(Image: TImage; const URL: string);
begin
  TTask.Run(procedure
  var
    HTTPClient: THTTPClient;
    Response: IHTTPResponse;
    Stream: TMemoryStream;
  begin
    HTTPClient := THTTPClient.Create;
    Stream := TMemoryStream.Create;
    try
      try
        Response := HTTPClient.Get(URL, Stream);
        if Response.StatusCode = 200 then
        begin
          TThread.Synchronize(nil, procedure
          begin
            TokenIconImage.Bitmap.LoadFromStream(Stream);
          end);
        end else
          raise Exception.Create('');
      except
        on E: Exception do
        begin
          Response := HTTPClient.Get(IconURLDomain + '/default.png', Stream);
          TThread.Synchronize(nil, procedure
          begin
            TokenIconImage.Bitmap.LoadFromStream(Stream);
          end);
        end;
      end;
    finally
      Stream.Free;
      HTTPClient.Free;
    end;
  end);
end;

end.
