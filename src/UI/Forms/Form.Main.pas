unit Form.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Math, System.Generics.Collections, System.Generics.Defaults, System.DateUtils,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation,
  FMX.Edit, FMX.TabControl, FMX.Platform, FMX.ListBox, FMX.Effects, FMX.Objects,
  FMX.Layouts, FMX.StdCtrls, FMX.Ani, System.Rtti, FMX.Grid.Style, FMX.ScrollBox,
  FMX.Grid, FMX.Memo.Types, FMX.Memo,
  App.Exceptions,
  App.Logs,
  App.Intf,
  Blockchain.Data,
  Blockchain.Txn,
  Blockchain.Validation,
  Blockchain.Reward,
  Desktop.Controls,
  Styles,
  Frame.Explorer,
  Frame.History,
  Frame.Reward,
  Frame.Transaction,
  Frame.StakingTransaction, Frame.Navigation;

type
  TMainForm = class(TForm)
    Tabs: TTabControl;
    TokensTabItem: TTabItem;
    ExplorerTabItem: TTabItem;
    PopupRectangle: TRectangle;
    ShadowEffect2: TShadowEffect;
    ShadowEffect1: TShadowEffect;
    SearchTokenEdit: TEdit;
    ShadowEffect3: TShadowEffect;
    TokensListBox: TListBox;
    MainRectangle: TRectangle;
    TokenNameEdit: TEdit;
    RecepientAddressEdit: TEdit;
    ShadowEffect4: TShadowEffect;
    AmountTokenEdit: TEdit;
    ShadowEffect5: TShadowEffect;
    SendTokenButton: TButton;
    HideTokenMessageTimer: TTimer;
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
    HideTETMessageTimer: TTimer;
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
    HideCreatingMessageTimer: TTimer;
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
    PaginationBottomLayout: TLayout;
    SearchEdit: TEdit;
    SearchButton: TButton;
    TransactionNotFoundLabel: TLabel;
    FloatAnimation4: TFloatAnimation;
    HideTransactionNotFoundTimer: TTimer;
    SearchAniIndicator: TAniIndicator;
    TickerExplorerHeaderLabel: TLabel;
    CreateTokenAniIndicator: TAniIndicator;
    TransTokenAniIndicator: TAniIndicator;
    Layout1: TLayout;
    Layout2: TLayout;
    StatusText: TEdit;
    FloatAnimation2: TFloatAnimation;
    TxMaxAmountButton: TEditButton;
    AddressToHeaderLabel: TLabel;
    StakingTabItem: TTabItem;
    Layout5: TLayout;
    StakeButton1: TButton;
    StakingStatusText: TEdit;
    FloatAnimation5: TFloatAnimation;
    Layout7: TLayout;
    StakeAmountEdit: TEdit;
    EditButton1: TEditButton;
    ShadowEffect15: TShadowEffect;
    Layout8: TLayout;
    Layout9: TLayout;
    UnstakeButton: TButton;
    Label1: TLabel;
    Label2: TLabel;
    StakeBalanceLabel: TLabel;
    UnstakeAmountEdit: TEdit;
    EditButton2: TEditButton;
    ShadowEffect14: TShadowEffect;
    UnstakingStatusText: TEdit;
    FloatAnimation6: TFloatAnimation;
    Layout3: TLayout;
    StakingMaxAmountLabel: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    RewardDaysLabel: TLabel;
    StakingRewardLabel: TLabel;
    UnstakingMaxAmountLabel: TLabel;
    CopiedRectangle: TRectangle;
    Text1: TText;
    FloatAnimation8: TFloatAnimation;
    FloatAnimation9: TFloatAnimation;
    TransactionFrame1: TTransactionFrame;
    TransactionFrame2: TTransactionFrame;
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    Layout6: TLayout;
    Label6: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    VertScrollBox1: TVertScrollBox;
    TabItem2: TTabItem;
    TransactionFrame3: TTransactionFrame;
    SettingsTab: TTabItem;
    Label3: TLabel;
    Label4: TLabel;
    Edit1: TEdit;
    ShadowEffect13: TShadowEffect;
    Button1: TButton;
    Rectangle1: TRectangle;
    Layout10: TLayout;
    Layout4: TLayout;
    Layout12: TLayout;
    TETCopyLoginLayout: TLayout;
    TETCopyHashSvg: TPath;
    Label15: TLabel;
    Layout11: TLayout;
    Edit2: TEdit;
    FloatAnimation7: TFloatAnimation;
    Label5: TLabel;
    NavigationFrame1: TNavigationFrame;
    procedure SearchTokenEditChangeTracking(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure RecepientAddressEditChangeTracking(Sender: TObject);
    procedure SendTokenButtonClick(Sender: TObject);
    procedure RoundRectTickerMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure AmountTETEditChangeTracking(Sender: TObject);
    procedure SendTETButtonClick(Sender: TObject);
    procedure ExplorerBackCircleMouseEnter(Sender: TObject);
    procedure ExplorerBackCircleMouseLeave(Sender: TObject);
    procedure TETBackCircleMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure TETCopyLoginLayoutClick(Sender: TObject);
    procedure TETCopyAddressLayoutClick(Sender: TObject);
    procedure PrevPageLayoutMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure SearchEditChangeTracking(Sender: TObject);
    procedure SearchButtonClick(Sender: TObject);
    procedure SearchEditKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
    procedure SendTETToEditKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
    procedure ExplorerVertScrollBoxResized(Sender: TObject);
    procedure HistoryTETVertScrollBoxResized(Sender: TObject);
    procedure UnstakeButtonClick(Sender: TObject);
    procedure StakeButton1Click(Sender: TObject);
    procedure Layout5Resized(Sender: TObject);
    procedure Layout11Click(Sender: TObject);
    procedure FloatAnimation9Finish(Sender: TObject);
    procedure StakeAmountEditEnter(Sender: TObject);
    procedure UnstakeAmountEditEnter(Sender: TObject);
    procedure ExplorerBackCircleMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure EditButton1Click(Sender: TObject);
    procedure EditButton2Click(Sender: TObject);
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
    procedure VertScrollBox1Resized(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Label5Resize(Sender: TObject);
    procedure Edit1Enter(Sender: TObject);
    procedure TabsChange(Sender: TObject);
//  const
//    TransToDrawNumber = 18;
  private
//    FBalances: TDictionary<string, Double>;
//    FTickersFrames: TList<TTickerFrame>;
//    FSelectedFrame: TTickerFrame;
//    FChosenToken: TListBoxItem;
//    FSearchResultTrans: TArray<TExplorerTransactionInfo>;
//    FTotalPagesAmount, FPageNum: Integer;

//    FDynTETBlockNum: Integer;
//    FDynTET: TTokenBase;
    FBalance: UInt64;
    FStakingBalance: UInt64;
    FRewardTotal: TRewardTotalInfo;
    FStakingMaxAmountText: string;
    FUnstakingMaxAmountText: string;
    procedure CopyTextToClipboard(const Text: string; Control: TControl);
    procedure RefreshBalances;
    procedure RefreshUserHistory;
    procedure RefreshExplorer;
    procedure RefreshExplorerRaw;
    procedure RefreshExplorerText(const Text: string);
//    procedure AlignTETHeaders;
//    procedure RefreshHeaderBalance(ATicker: string);
//    procedure RefreshTokensBalances;
//    procedure AddOrRefreshBalance(ASmartKey: TCSmartKey);
//    procedure RefreshTokenHistory;
//    procedure AlignTokensHeaders;
//    procedure RefreshPagesLayout;
//    procedure OnPageSelected;
//    procedure AlignExplorerHeaders(AShowTicker: Boolean);
//    procedure CleanScrollBox(Control: TControl; FrameClass: TFmxObjectClass);

//    procedure AddTickerFrame(const ATicker: string; ATokenID: Integer = -1);
//    procedure AddTokenItem(ATokenID: Integer; AName: string; AValue: Double);
//    procedure AddPageNum(APageNum: Integer);
    procedure ShowTETTransferStatus(const AMessage: string; AIsError: Boolean = False);
    procedure ShowStakeStatus(const AMessage: string; AIsError: Boolean = False);
    procedure ShowUnstakeStatus(const AMessage: string; AIsError: Boolean = False);
    procedure ShowKeyStatus(const AMessage: string; AIsError: Boolean = False);
//    procedure ShowTokenTransferStatus(const AMessage: string; AIsError: Boolean = False);
//    procedure ShowTokenCreatingStatus(const AMessage: string; AIsError: Boolean = False);
    procedure ShowExplorerTransactionDetails(ATicker, ADateTime, ABlockNum,
      AHash, ATransFrom, ATransTo, AAmount: string); overload;
//    procedure ShowExplorerTransactionDetails(ATransaction: TExplorerTransactionInfo); overload;
//    procedure SearchByBlockNumber(const ABlockNumber: Integer);
//    procedure SearchByHash;
//    procedure SearchByAddress;

    procedure onTETHistoryFrameClick(Sender: TObject);
    procedure onStakingHistoryFrameClick(Sender: TObject);
//    procedure onTokenHistoryFrameClick(Sender: TObject);
    procedure onExplorerFrameClick(Sender: TObject);
    procedure OnExplorerPageChange(Sender: TObject);
//    procedure onPageNumFrameClick(Sender: TObject; Button: TMouseButton;
//      Shift: TShiftState; X, Y: Single);
//    procedure onTransactionSearchingDone(AIsFound: Boolean);

//    procedure TETTransferCallBack(const AResponse: string);
//    procedure TokenCreatingCallBack(const AResponse: string);
//    procedure TokenTransferCallBack(const AResponse: string);
  public
    procedure NewTETChainBlocksEvent;
//    procedure NewTokenEvent(ASmartKey: TCSmartKey);
//    procedure NewTokenBlocksEvent(ASmartKey: TCSmartKey;
//      ANeedRefreshBalance: Boolean);
//    procedure onKeysSaved;
//    procedure onKeysSavingError;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
  Desktop;

procedure TMainForm.FormCreate(Sender: TObject);
begin

  Caption := 'LNode ' + AppCore.GetAppVersionText;

  FStakingMaxAmountText := StakingMaxAmountLabel.Text;
  FUnstakingMaxAmountText := UnstakingMaxAmountLabel.Text;

  CopiedRectangle.Visible := False;

end;

procedure TMainForm.FormShow(Sender: TObject);
begin

  Tabs.ActiveTab := TectumTabItem;
  TETTabControl.ActiveTab:=TETTabItemData;
  TabControl1.ActiveTab:=TabItem1;
  ExplorerTabControl.ActiveTab:=ExporerTabItemData;

  ShowTETTransferStatus('',False);
  ShowStakeStatus('',False);
  ShowUnstakeStatus('',False);
  ShowKeyStatus('',False);

  NavigationFrame1.OnChange := OnExplorerPageChange;

  NavigationFrame1.PagesCount:=1;
  NavigationFrame1.PageNum:=1;

  NewTETChainBlocksEvent;

end;

procedure TMainForm.Edit1Enter(Sender: TObject);
begin
  ShowKeyStatus('',False);
end;

procedure TMainForm.EditButton1Click(Sender: TObject);
begin
  StakeAmountEdit.Text := AmountToStr(FBalance);
end;

procedure TMainForm.EditButton2Click(Sender: TObject);
begin
  UnstakeAmountEdit.Text := AmountToStr(FStakingBalance);
end;

procedure TMainForm.ExplorerBackCircleMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
//  ExplorerTabControl.Previous;
end;

procedure TMainForm.ExplorerBackCircleMouseEnter(Sender: TObject);
begin
//  (Sender as TCircle).Fill.Kind := TBrushKind.Solid;
end;

procedure TMainForm.ExplorerBackCircleMouseLeave(Sender: TObject);
begin
//  (Sender as TCircle).Fill.Kind := TBrushKind.None;
end;

procedure TMainForm.ExplorerVertScrollBoxResized(Sender: TObject);
begin
  ControlsFlexWidth([DateTimeExplorerHeaderLabel,BlockNumExplorerHeaderLabel,FromExplorerHeaderLabel,
    ToExplorerHeaderLabel,HashExplorerHeaderLabel,AmountExplorerHeaderLabel,Label15],
    [0.1,0.05,0.2,0.2,0.27,0.1,0.08],ExplorerVertScrollBox.Content);
end;

procedure TMainForm.TabsChange(Sender: TObject);
begin
  CopiedRectangle.Visible := False;
end;

procedure TMainForm.TETBackCircleMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
//  TETTabControl.Previous;
end;

procedure TMainForm.HistoryTETVertScrollBoxResized(Sender: TObject);
begin
  ControlsFlexWidth([DateTimeTETHeaderLabel,BlockNumTETHeaderLabel,AddressFromHeaderLabel,
    AddressToHeaderLabel,HashTETHeaderLabel,AmountTETHeaderLabel,StatusTETHeaderLabel],
    [0.1,0.05,0.2,0.2,0.3,0.1,0.05],HistoryTETVertScrollBox.Content);
end;

procedure TMainForm.Label5Resize(Sender: TObject);
begin
  Layout10.Height := Label5.BoundsRect.Bottom+7;
end;

procedure TMainForm.Layout11Click(Sender: TObject);
begin

//  if not FloatAnimation7.Running then
//  begin
//    if Assigned(Root) then Root.Focused:=nil;
//    FloatAnimation7.Inverse:=not FloatAnimation7.Inverse;
//    FloatAnimation7.Start;
//  end;

end;

procedure TMainForm.Layout5Resized(Sender: TObject);
begin
  ControlsFlexWidth([Layout7,Layout8],[0.45,0.45],Layout5);
  UnstakingMaxAmountLabel.Margins.Top:=StakingMaxAmountLabel.Position.Y-Label9.BoundsRect.Bottom;
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin

  try
    AppCore.ChangePrivateKey(Edit1.Text);
  except on E: EKeyException do
  begin
    case E.ErrorCode of
    EKeyException.INVALID_KEY: ShowKeyStatus('Invalid private key, please enter a different one',True);
    else
      ShowKeyStatus(E.Message,True);
    end;
    Exit
  end;
  on E: Exception do
  begin
    ShowKeyStatus(E.Message,True);
    Exit
  end;
  end;

  AppCore.Reset;

  ShowKeyStatus('Key changed',False);

end;

procedure TMainForm.CopyTextToClipboard(const Text: string; Control: TControl);
begin
  CopyToClipboard(Text);
  CopiedRectangle.Position.Point:=Control.LocalToAbsolute(Control.LocalRect.BottomRight);
  CopiedRectangle.Opacity:=1;
  CopiedRectangle.Visible := True;
end;

procedure TMainForm.TETCopyAddressLayoutClick(Sender: TObject);
begin
//  CopyTextToClipboard(TETAddressDetailsText.Text,TETCopyAddressLayout);
end;

procedure TMainForm.TETCopyLoginLayoutClick(Sender: TObject);
begin
  CopyTextToClipboard(AddressTETLabel.Text,TETCopyLoginLayout);
end;

procedure TMainForm.TransactionFrame1TETBackCircleMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  ExplorerTabControl.Previous;
end;

procedure TMainForm.TransactionFrame1TETCopyAddressLayoutClick(Sender: TObject);
begin
  CopyTextToClipboard(TransactionFrame1.AddressFromText.Text,TransactionFrame1.TETCopyAddressLayout);
end;

procedure TMainForm.TransactionFrame1Layout2Click(Sender: TObject);
begin
  CopyTextToClipboard(TransactionFrame1.AddressToText.Text,TransactionFrame1.Layout2);
end;

procedure TMainForm.TransactionFrame1TETCopyLoginLayoutClick(Sender: TObject);
begin
  CopyTextToClipboard(TransactionFrame1.TETHashDetailsText.Text,TransactionFrame1.TETCopyLoginLayout);
end;

procedure TMainForm.TransactionFrame2TETBackCircleClick(Sender: TObject);
begin
  TETTabControl.Previous;
end;

procedure TMainForm.TransactionFrame2TETCopyAddressLayoutClick(Sender: TObject);
begin
  CopyTextToClipboard(TransactionFrame2.AddressFromText.Text,TransactionFrame2.TETCopyAddressLayout);
end;

procedure TMainForm.TransactionFrame2TETCopyLoginLayoutClick(Sender: TObject);
begin
  CopyTextToClipboard(TransactionFrame2.TETHashDetailsText.Text,TransactionFrame2.TETCopyLoginLayout);
end;

procedure TMainForm.TransactionFrame3TETBackCircleClick(Sender: TObject);
begin
  TabControl1.Previous;
end;

procedure TMainForm.TransactionFrame3TETCopyAddressLayoutClick(Sender: TObject);
begin
  CopyTextToClipboard(TransactionFrame3.AddressFromText.Text,TransactionFrame3.TETCopyAddressLayout);
end;

procedure TMainForm.TransactionFrame3TETCopyLoginLayoutClick(Sender: TObject);
begin
  CopyTextToClipboard(TransactionFrame3.TETHashDetailsText.Text,TransactionFrame3.TETCopyLoginLayout);
end;

procedure TMainForm.TxMaxAmountButtonClick(Sender: TObject);
begin
  AmountTETEdit.Text := AmountToStr(FBalance);
end;

procedure TMainForm.NewTETChainBlocksEvent;
begin
  AddressTETLabel.Text := AppCore.Address;
  RefreshBalances;
  RefreshUserHistory;
  RefreshExplorer;
end;

procedure TMainForm.onExplorerFrameClick(Sender: TObject);
begin
  var F:=TExplorerTransactionFrame(Sender);
  F.UpdateTransaction;
  TransactionFrame1.SetTrx(F.Transaction);
  ExplorerTabControl.Next;
end;

//procedure TMainForm.onKeysSaved;
//begin
//  InputPrKeyButton.Visible := False;
//  ShowTokenTransferStatus('Keys saved successfully');
//end;

//procedure TMainForm.onKeysSavingError;
//begin
//  ShowTokenTransferStatus('Error saving keys: invalid private key',True);
//end;

//procedure TMainForm.onPageNumFrameClick(Sender: TObject; Button: TMouseButton;
//  Shift: TShiftState; X, Y: Single);
//begin
//  if FPageNum = (Sender as TPageNumFrame).Tag then
//    exit;
//  FPageNum := (Sender as TPageNumFrame).Tag;
//  RefreshPagesLayout;
//end;

procedure TMainForm.onTETHistoryFrameClick(Sender: TObject);
begin
  var F:=THistoryTransactionFrame(Sender);
  F.UpdateTransaction;
  TransactionFrame2.SetTrxAsUser(F.Transaction);
  TETTabControl.Next;
end;

procedure TMainForm.onStakingHistoryFrameClick(Sender: TObject);
begin
  var F:=TStakingTransactionFrame(Sender);
  F.UpdateTransaction;
  TransactionFrame3.SetTrxAsStaking(F.Transaction);
  TabControl1.Next;
end;

procedure TMainForm.FloatAnimation9Finish(Sender: TObject);
begin
  CopiedRectangle.Visible := False;
end;

//procedure TMainForm.onTokenHistoryFrameClick(Sender: TObject);
//var
//  TokenICO: TTokenICODat;
//begin
//  if not AppCore.TryGetTokenICO(TokenNameEdit.Text, TokenICO) then
//    exit;
//
//  with (Sender as THistoryTransactionFrame) do
//  begin
//    TokenDateTimeDetailsText.AutoSize := False;
//    TokenDateTimeDetailsText.Text := DateTimeLabel.Text;
//    TokenDateTimeDetailsText.AutoSize := True;
//
//    TokenBlockDetailsText.AutoSize := False;
//    TokenBlockDetailsText.Text := BlockLabel.Text;
//    TokenBlockDetailsText.AutoSize := True;
//
//    if IncomText.Text = 'OUT' then
//      TokenAddressDetailsLabel.Text := 'To'
//    else
//      TokenAddressDetailsLabel.Text := 'From';
//
//    TokenAddressDetailsText.AutoSize := False;
//    TokenAddressDetailsText.Text := AddressLabel.Text;
//    TokenAddressDetailsText.AutoSize := True;
//
//    TokenHashDetailsText.AutoSize := False;
//    TokenHashDetailsText.Text := HashLabel.Text;
//    TokenHashDetailsText.AutoSize := True;
//
//    TokenAmountDetailsText.AutoSize := False;
//    TokenAmountDetailsText.Text := AmountLabel.Text;
//    TokenAmountDetailsText.AutoSize := True;
//
//    TokenDetailsAdvText.AutoSize := False;
//    TokenDetailsAdvText.Text := Format('%s (%s)',
//      [TokenICO.Abreviature, TokenICO.ShortName]);
//    TokenDetailsAdvText.AutoSize := True;
//
//    TokenInfoDetailsAdvLabelValue.AutoSize := False;
//    TokenInfoDetailsAdvLabelValue.Text := TokenICO.FullName;
//    TokenInfoDetailsAdvLabelValue.AutoSize := True;
//  end;
//  TokenTransactionDetailsRectangle.Height := TokenInfoDetailsAdvLabelValue.Height + 381;
//
//  TokenTabControl.Next;
//end;

//procedure TMainForm.onTransactionSearchingDone(AIsFound: Boolean);
//begin
//  FloatAnimation4.Enabled := not AIsFound;
//end;

procedure TMainForm.PrevPageLayoutMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
//  Dec(FPageNum);
//  RefreshPagesLayout;
end;

procedure TMainForm.RecepientAddressEditChangeTracking(Sender: TObject);
begin
//  if Length(RecepientAddressEdit.Text) = 42 then
//    TokenNameEditChangeTracking(nil)
//  else
//    SendTokenButton.Enabled := False;
end;

//procedure TMainForm.RefreshHeaderBalance(ATicker: string);
//var
//  Value: Double;
//begin
//  if FBalances.TryGetValue(ATicker, Value) then
//    BalanceTokenValueLabel.Text :=
//      Format('%s %s', [FormatFloat('0.########', Value), ATicker]);
//end;

//procedure TMainForm.RefreshPagesLayout;
//const
//  AtTheEdges = 5;
//var
//  Transactions: TArray<TExplorerTransactionInfo>;
//  i, PageNumToDraw, PagesToDraw, TotalBlocksNumber: Integer;
//begin
//  if FSelectedFrame.Ticker = 'Tectum' then
//  begin
//    TotalBlocksNumber := AppCore.GetTETChainBlocksCount;
//    FTotalPagesAmount := TotalBlocksNumber div TransToDrawNumber;
//    if TotalBlocksNumber mod TransToDrawNumber > 0 then
//      Inc(FTotalPagesAmount);
//
//    Transactions := AppCore.GetTETTransactions(TransToDrawNumber * (FPageNum - 1),
//      TransToDrawNumber);
//  end else
//  if Length(FSearchResultTrans) > 0 then
//  begin
//    TotalBlocksNumber := Length(FSearchResultTrans);
//    FTotalPagesAmount := TotalBlocksNumber div TransToDrawNumber;
//    if TotalBlocksNumber mod TransToDrawNumber > 0 then
//      Inc(FTotalPagesAmount);
//
//    Transactions := Copy(FSearchResultTrans, TransToDrawNumber * (FPageNum - 1), TransToDrawNumber);
//  end else
//  begin
//    TotalBlocksNumber := AppCore.GetTokenChainBlocksCount(FSelectedFrame.Tag);
//    FTotalPagesAmount := TotalBlocksNumber div TransToDrawNumber;
//    if TotalBlocksNumber mod TransToDrawNumber > 0 then
//      Inc(FTotalPagesAmount);
//
//    Transactions := AppCore.GetTokenTransactions(FSelectedFrame.Tag,
//      TransToDrawNumber * (FPageNum - 1), TransToDrawNumber);
//  end;
//
//
//  PaginationBottomLayout.BeginUpdate;
//  PagesPanelLayout.BeginUpdate;
//  try
//    PagesPanelLayout.DestroyComponents;
//    PagesPanelLayout.Width := 48;
//    PaginationBottomLayout.Visible := FTotalPagesAmount > 1;
//    if not PaginationBottomLayout.Visible then
//      exit;
//
//    PagesToDraw := 3 + AtTheEdges * 2;
//    AddPageNum(1);
//    if (FPageNum - AtTheEdges > 3) and (FTotalPagesAmount > PagesToDraw + 2) then
//    begin
//      AddPageNum(-1);
//      Dec(PagesToDraw);
//    end;
//    if (FPageNum + AtTheEdges < FTotalPagesAmount - 2) and
//      (FTotalPagesAmount > PagesToDraw + 2) then
//      Dec(PagesToDraw);
//    PageNumToDraw := Max(2, Min(FTotalPagesAmount - PagesToDraw,
//      FPageNum - AtTheEdges));
//    if (FPageNum - AtTheEdges = 3) then
//      Dec(PageNumToDraw);
//    for i := PageNumToDraw to FPageNum do
//    begin
//      if (i = 1) or (i = FTotalPagesAmount) then
//        continue;
//      AddPageNum(i);
//    end;
//    PageNumToDraw := Min(FTotalPagesAmount - 1, Max(PagesToDraw + 1,
//      FPageNum + AtTheEdges));
//    if (FPageNum + AtTheEdges = FTotalPagesAmount - 2) then
//      Inc(PageNumToDraw);
//    for i := FPageNum + 1 to PageNumToDraw do
//    begin
//      if (i = 1) or (i = FTotalPagesAmount) then
//        continue;
//      AddPageNum(i);
//    end;
//    if (FPageNum + AtTheEdges < FTotalPagesAmount - 2) and
//      (FTotalPagesAmount > PagesToDraw + 2) then
//      AddPageNum(-1);
//    AddPageNum(FTotalPagesAmount);
//    OnPageSelected;
//  finally
//    PagesPanelLayout.EndUpdate;
//    PaginationBottomLayout.EndUpdate;
//    RefreshExplorer(Transactions, Length(FSearchResultTrans) > 0);
//    AlignExplorerHeaders(Length(FSearchResultTrans) > 0);
//  end;
//end;

procedure TMainForm.RefreshBalances;
begin

  FBalance := AppCore.GetTokenBalance(AppCore.Address);
  FStakingBalance := AppCore.GetStakingBalance(AppCore.Address);

  StakingMaxAmountLabel.Text := FStakingMaxAmountText+' '+AmountToStr(FBalance,True);
  UnstakingMaxAmountLabel.Text := FUnstakingMaxAmountText+' '+AmountToStr(FStakingBalance,True);

  BalanceTETValueLabel.Text := AmountToStr(FBalance,True);
  StakeBalanceLabel.Text := AmountToStr(FStakingBalance,True);

  var R:=AppCore.GetStakingReward(FRewardTotal.EndBlockIndex,AppCore.Address);

  Inc(FRewardTotal.Amount,R.Amount);

  if FRewardTotal.FirstTxnId=0 then FRewardTotal.FirstTxnId:=R.FirstTxnId;

  FRewardTotal.EndBlockIndex:=R.EndBlockIndex;

  var D := NowUTC;

  if FRewardTotal.FirstTxnId>0 then
    D := TMemBlock<TTxn>.ReadFromFile(TTxn.Filename,FRewardTotal.FirstTxnId).Data.CreatedAt;

  StakingRewardLabel.Text := AmountToStr(FRewardTotal.Amount,True);
  RewardDaysLabel.Text := DaysBetween(D,NowUTC).ToString + ' Days';

end;

procedure TMainForm.RefreshUserHistory;
const
  MaxTransactionsNumber = 20;
begin

  var Transactions := AppCore.GetUserLastTransactions(AppCore.Address,0,MaxTransactionsNumber);

  HistoryTETVertScrollBox.BeginUpdate;
  try

    HistoryTETVertScrollBox.Content.DeleteChildren;

    for var Trx in Transactions do
    if Trx.TxType='transfer' then
    begin
      var F := THistoryTransactionFrame.Create(HistoryTETVertScrollBox);
      F.SetData(Trx,Trx.AddressTo=AppCore.Address);
      F.OnClick := onTETHistoryFrameClick;
      F.Parent := HistoryTETVertScrollBox;
    end;

  finally
    HistoryTETVertScrollBox.EndUpdate;
    HistoryTETVertScrollBox.RecalcSize;
  end;

  NoTETHistoryLabel.Visible := HistoryTETVertScrollBox.Content.ChildrenCount=0;
  HistoryTETHeaderLayout.Visible := not NoTETHistoryLabel.Visible;
  HistoryTETVertScrollBox.Visible := not NoTETHistoryLabel.Visible;

  VertScrollBox1.BeginUpdate;
  try

    VertScrollBox1.Content.DeleteChildren;

    for var Trx in Transactions do
    if (Trx.TxType='stake') or (Trx.TxType='unstake') then
    begin
      var F := TStakingTransactionFrame.Create(VertScrollBox1);
      F.SetData(Trx);
      F.OnClick := onStakingHistoryFrameClick;
      F.Parent := VertScrollBox1;
    end;

  finally
    VertScrollBox1.EndUpdate;
    VertScrollBox1.RecalcSize;
  end;

  Label17.Visible := VertScrollBox1.Content.ChildrenCount=0;
  Layout6.Visible := not Label17.Visible;
  VertScrollBox1.Visible := not Label17.Visible;

end;

procedure TMainForm.RefreshExplorer;
begin
  if SearchEdit.Text.IsEmpty then
    RefreshExplorerRaw
  else
    RefreshExplorerText(SearchEdit.Text);
end;

procedure TMainForm.RefreshExplorerRaw;
const
  MaxTransactionsNumber = 20;
begin

  var RecordCount := TMemBlock<TTxn>.RecordsCount(TTxn.Filename);
  var PagesCount := Ceil(RecordCount/MaxTransactionsNumber);

  NavigationFrame1.PagesCount:=PagesCount;

  var Transactions := AppCore.GetLastTransactions((NavigationFrame1.PageNum-1)*MaxTransactionsNumber,MaxTransactionsNumber);

  ExplorerVertScrollBox.BeginUpdate;
  try

    ExplorerVertScrollBox.Content.DeleteChildren;

    for var Trx in Transactions do
    begin
      var NewTransFrame := TExplorerTransactionFrame.Create(ExplorerVertScrollBox);
      NewTransFrame.SetData(Trx);
      NewTransFrame.OnClick := onExplorerFrameClick;
      NewTransFrame.Parent := ExplorerVertScrollBox;
    end;

  finally
    ExplorerVertScrollBox.EndUpdate;
    ExplorerVertScrollBox.RecalcSize;
  end;

end;

procedure TMainForm.RefreshExplorerText(const Text: string);
const
  MaxTransactionsNumber = 20;
begin

//  var RecordCount := TMemBlock<TTxn>.RecordsCount(TTxn.Filename);
//  var PagesCount := Ceil(RecordCount/MaxTransactionsNumber);
//
//  NavigationFrame1.PagesCount:=PagesCount;
//
//  var Transactions := AppCore.GetLastTransactions(
//
//  procedure (const Txn: TTransactionInfo)
//  begin
//
//    (NavigationFrame1.PageNum-1)*MaxTransactionsNumber,MaxTransactionsNumber);
//
//  end);
//
//
//  ExplorerVertScrollBox.BeginUpdate;
//  try
//
//    ExplorerVertScrollBox.Content.DeleteChildren;
//
//    for var Trx in Transactions do
//    begin
//      var NewTransFrame := TExplorerTransactionFrame.Create(ExplorerVertScrollBox);
//      NewTransFrame.SetData(Trx);
//      NewTransFrame.OnClick := onExplorerFrameClick;
//      NewTransFrame.Parent := ExplorerVertScrollBox;
//    end;
//
//  finally
//    ExplorerVertScrollBox.EndUpdate;
//    ExplorerVertScrollBox.RecalcSize;
//  end;

end;

//procedure TMainForm.RefreshTokenHistory;
//const
//  MaxTransactionsNumber = 20;
//var
//  TokenTransactions: TArray<THistoryTransactionInfo>;
//  TokenTransactionFrame: THistoryTransactionFrame;
//  i: Integer;
//  Format: string;
//  TokenICO: TTokenICODat;
//begin
//  if not Assigned(FChosenToken) then
//    exit;
//
//  TokenTransactions := AppCore.GetTokenUserTransactions(FChosenToken.Tag,
//    AppCore.UserID, 0, MaxTransactionsNumber, True);
//
//  NoTokenHistoryLabel.Visible := Length(TokenTransactions) = 0;
//
//  HistoryTokenVertScrollBox.Visible := not NoTokenHistoryLabel.Visible;
//  HistoryTokenHeaderLayout.Visible := not NoTokenHistoryLabel.Visible;
//  if NoTokenHistoryLabel.Visible then
//    exit;
//  AppCore.TryGetTokenICO(FChosenToken.Text, TokenICO);
//  HistoryTokenVertScrollBox.BeginUpdate;
//  CleanScrollBox(HistoryTokenVertScrollBox);
//  try
//    Format := '0.' + string.Create('0', TokenICO.FloatSize);
//    for i := 0 to Length(TokenTransactions) - 1 do
//    begin
//      with TokenTransactions[i] do
//        TokenTransactionFrame := THistoryTransactionFrame.Create(
//          HistoryTokenVertScrollBox, DateTime, BlockNum, Address, Hash,
//          FormatFloat(Format, Value), Incom);
//      TokenTransactionFrame.OnClick := onTokenHistoryFrameClick;
//      TokenTransactionFrame.Parent := HistoryTokenVertScrollBox;
//    end;
//  finally
//    HistoryTokenVertScrollBox.EndUpdate;
//  end;
//end;

//procedure TMainForm.RefreshTokensBalances;
//var
//  SmartKeyBlock: TCSmartKey;
//begin
//  for SmartKeyBlock in AppCore.GetAllSmartKeyBlocks do
//    AddOrRefreshBalance(SmartKeyBlock);
//
//  if TokensListBox.Count > 0 then
//  begin
//    BalanceTokenLabel.Opacity := 1;
//    TokenNameEdit.Enabled := True;
//    RecepientAddressEdit.Enabled := True;
//    AmountTokenEdit.Enabled := True;
//    if not Assigned(FChosenToken) then
//      FChosenToken := TokensListBox.ListItems[0];
//    FChosenToken.OnClick(FChosenToken);
//  end else
//  begin
//    BalanceTokenLabel.Opacity := 0;
//    BalanceTokenValueLabel.Text := 'No custom tokens yet';
//  end;
//end;

procedure TMainForm.RoundRectTickerMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
//var
//  ParentFrame: TTickerFrame;
begin
//  ParentFrame := (Sender as TRoundRect).Parent as TTickerFrame;
//  if ParentFrame.Equals(FSelectedFrame) then
//    exit;
//
//  if Assigned(FSelectedFrame) then
//    FSelectedFrame.Selected := False;
//  ParentFrame.Selected := True;
//  FSelectedFrame := ParentFrame;
//  SetLength(FSearchResultTrans, 0);
//
//  FPageNum := 1;
//  RefreshPagesLayout;
end;

//procedure TMainForm.AddOrRefreshBalance(ASmartKey: TCSmartKey);
//var
//  Value: Double;
//  Index: Integer;
//begin
//  Value := AppCore.GetTokenBalance(ASmartKey.SmartID, FDynTETBlockNum, FDynTET);
//  FBalances.AddOrSetValue(ASmartKey.Abreviature, Value);
//  TokensListBox.BeginUpdate;
//  try
//    Index := TokensListBox.Items.IndexOf(ASmartKey.Abreviature);
//    if Index >= 0 then
//    begin
//      TokensListBox.Items.Delete(Index);
//      if BalanceTokenValueLabel.Text.Contains(ASmartKey.Abreviature) then
//        RefreshHeaderBalance(ASmartKey.Abreviature);
//    end;
//  finally
//    AddTokenItem(ASmartKey.SmartID, ASmartKey.Abreviature, Value);
//    TokensListBox.Sort(CustomSortCompareStrings);
//    TokensListBox.EndUpdate;
//  end;
//end;

procedure TMainForm.SearchButtonClick(Sender: TObject);
begin
  RefreshExplorer;
end;

//procedure TMainForm.SearchByAddress;
//begin
//  SearchAniIndicator.Visible := True;
//  SearchAniIndicator.Enabled := True;
//  SearchEdit.Enabled := True;
//
//  TThread.CreateAnonymousThread(
//  procedure
//  begin
//    FSearchResultTrans := AppCore.SearchTransactionsByAddress(SearchEdit.Text);
//    SearchAniIndicator.Enabled := False;
//    SearchAniIndicator.Visible := False;
//    TThread.Synchronize(nil,
//    procedure
//    begin
//      onTransactionSearchingDone(Length(FSearchResultTrans) > 0);
//      if Length(FSearchResultTrans) > 0 then
//      begin
//        SearchEdit.Text := '';
//        if not FTickersFrames.Items[0].Visible then
//        begin
//          FSelectedFrame.Selected := False;
//          FSelectedFrame := FTickersFrames.Items[0];
//          FSelectedFrame.Selected := True;
//          FTickersFrames.Items[0].Visible := True;
//        end;
//        FPageNum := 1;
//        RefreshPagesLayout;
//      end;
//    end);
//  end).Start;
//end;

//procedure TMainForm.SearchByBlockNumber(const ABlockNumber: Integer);
//begin
//  SearchAniIndicator.Visible := True;
//  SearchAniIndicator.Enabled := True;
//  SearchEdit.Enabled := True;
//
//  TThread.CreateAnonymousThread(
//  procedure
//  begin
//    FSearchResultTrans := AppCore.SearchTransactionsByBlockNum(ABlockNumber);
//    SearchAniIndicator.Enabled := False;
//    SearchAniIndicator.Visible := False;
//    TThread.Synchronize(nil,
//    procedure
//    begin
//      onTransactionSearchingDone(Length(FSearchResultTrans) > 0);
//      if Length(FSearchResultTrans) > 0 then
//      begin
//        SearchEdit.Text := '';
//        if not FTickersFrames.Items[0].Visible then
//        begin
//          FSelectedFrame.Selected := False;
//          FSelectedFrame := FTickersFrames.Items[0];
//          FSelectedFrame.Selected := True;
//          FTickersFrames.Items[0].Visible := True;
//        end;
//        FPageNum := 1;
//        RefreshPagesLayout;
//      end;
//    end);
//  end).Start;
//end;

//procedure TMainForm.SearchByHash;
//var
//  Hash: string;
//begin
//  Hash := SearchEdit.Text;
//  SearchAniIndicator.Visible := True;
//  SearchAniIndicator.Enabled := True;
//  SearchEdit.Enabled := True;
//
//  TThread.CreateAnonymousThread(
//  procedure
//  var
//    TransInfo: TExplorerTransactionInfo;
//    Success: Boolean;
//  begin
//    Success := AppCore.SearchTransactionByHash(Hash, TransInfo);
//    SearchAniIndicator.Enabled := False;
//    SearchAniIndicator.Visible := False;
//    TThread.Synchronize(nil,
//    procedure
//    begin
//      onTransactionSearchingDone(Success);
//      if Success then
//      begin
//        SearchEdit.Text := '';
//        ShowExplorerTransactionDetails(TransInfo);
//      end;
//    end);
//  end).Start;
//end;

procedure TMainForm.SearchEditChangeTracking(Sender: TObject);
begin
//  SearchButton.Enabled := not SearchEdit.Text.IsEmpty;
end;

procedure TMainForm.SearchEditKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
begin
//  if SearchButton.Enabled and (Key = 13) then
//    SearchButtonClick(Self);
end;

procedure TMainForm.SearchTokenEditChangeTracking(Sender: TObject);
//var
//  i, MatchCount: Integer;
begin
//  TokensListBox.BeginUpdate;
//  try
//    MatchCount := 0;
//    for i := 0 to TokensListBox.Count-1 do
//    begin
//      TokensListBox.ListItems[i].Visible :=
//        TokensListBox.Items[i].StartsWith(SearchTokenEdit.Text);
//
//      if TokensListBox.ListItems[i].Visible then
//        Inc(MatchCount);
//    end;
//    PopupRectangle.Height := SearchTokenEdit.Height +
//        40 * (Min(MatchCount, 3)) + 36;
//  finally
//    TokensListBox.EndUpdate;
//  end;
end;

procedure TMainForm.AmountTETEditChangeTracking(Sender: TObject);
//var
//  isNumber: Boolean;
//  val,balance: Double;
begin
//  FBalances.TryGetValue('TET', balance);
//  isNumber := TryStrToFloat(AmountTETEdit.Text, val);
//
//  const Decimals = DecimalsCount(AmountTETEdit.Text);
//
//  SendTETButton.Enabled := (Length(SendTETToEdit.Text) >= 10) and
//    isNumber and (val > 0) and (val <= balance) and (Decimals <= 8);
//
//  with TransferTETStatusLabel do
//  begin
//    if isNumber and (val > balance) then
//    begin
//      Text := 'Insufficient funds';
//      TextSettings.FontColor := ERROR_TEXT_COLOR;
//      Opacity := 1;
//    end
//    else if Decimals > 8 then
//    begin
//      Text := 'Too much digits';
//      TextSettings.FontColor := ERROR_TEXT_COLOR;
//      Opacity := 1;
//    end
//     else
//      Opacity := 0;
//  end;
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

procedure TMainForm.SendTETToEditKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
begin
//  if SendTETButton.Enabled and (Key = 13) then
//    SendTETButtonClick(Self);
end;

procedure TMainForm.SendTokenButtonClick(Sender: TObject);
//var
//  SmartKey: TCSmartKey;
//  PrKey, PubKey: string;
begin
//  try
//    if AppCore.TryGetSmartKey(FChosenToken.Text, SmartKey) then
//    begin
//      AppCore.TryExtractPrivateKeyFromFile(PrKey, PubKey);
//      SendTokenButton.Enabled := False;
//      TransTokenAniIndicator.Visible := True;
//      TransTokenAniIndicator.Enabled := True;
//
//      AppCore.DoTokenTransfer('*', AppCore.TETAddress,
//        RecepientAddressEdit.Text, SmartKey.key1,
//        AmountTokenEdit.Text.ToDouble, PrKey, PubKey, TokenTransferCallBack);
//    end;
//  except
//    on E:EValidError do
//      ShowTokenTransferStatus(E.Message, True);
//    on E:EFileNotExistsError do
//    begin
//      ShowTokenTransferStatus('Unable to send transaction: keys not found', True);
//      InputPrKeyButton.Visible := True;
//    end;
//    on E:ESameAddressesError do
//      ShowTokenTransferStatus('Unable to send to yourself', True);
//    on E:Exception do
//    begin
//      ShowTokenTransferStatus('Unknown error', True);
//      Logs.DoLog('Unknown error during token transfer with message: ' + E.Message, ERROR, tcp);
//    end;
//  end;
end;

//procedure TMainForm.ShowExplorerTransactionDetails(ATransaction:
//  TExplorerTransactionInfo);
//begin
//  ShowExplorerTransactionDetails(ATransaction.Ticker,
//                                 FormatDateTime('dd.mm.yyyy hh:mm:ss', ATransaction.DateTime),
//                                 ATransaction.BlockNum.ToString,
//                                 ATransaction.Hash,
//                                 ATransaction.TransFrom,
//                                 ATransaction.TransTo,
//                                 ATransaction.Amount.ToString);
//end;

procedure TMainForm.ShowExplorerTransactionDetails(ATicker, ADateTime,
  ABlockNum, AHash, ATransFrom, ATransTo, AAmount: string);
//var
//  TokenICO: TTokenICODat;
begin
//  if not AppCore.TryGetTokenICO(ATicker, TokenICO) then
//    exit;
//
//  DateTimeDetailsText.AutoSize := False;
//  DateTimeDetailsText.Text := ADateTime;
//  DateTimeDetailsText.AutoSize := True;
//
//  BlockDetailsText.AutoSize := False;
//  BlockDetailsText.Text := ABlockNum;
//  BlockDetailsText.AutoSize := True;
//
//  FromDetailsText.AutoSize := False;
//  FromDetailsText.Text := ATransFrom;
//  FromDetailsText.AutoSize := True;
//
//  ToDetailsText.AutoSize := False;
//  ToDetailsText.Text := ATransTo;
//  ToDetailsText.AutoSize := True;
//
//  HashDetailsText.AutoSize := False;
//  HashDetailsText.Text := AHash;
//  HashDetailsText.AutoSize := True;
//
//  AmountDetailsText.AutoSize := False;
//  AmountDetailsText.Text := AAmount;
//  AmountDetailsText.AutoSize := True;
//
//  TokenDetailsText.AutoSize := False;
//  TokenDetailsText.Text := Format('%s (%s)',[ATicker,
//    TokenICO.ShortName]);
//  TokenDetailsText.AutoSize := True;
//
//  TokenInfoDetailsLabelValue.AutoSize := False;
//  TokenInfoDetailsLabelValue.Text := TokenICO.FullName;
//  TokenInfoDetailsLabelValue.AutoSize := True;
//
//  TransactionDetailsRectangle.Height := TokenInfoDetailsLabelValue.Height + 424;

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
  ShowStatus(AMessage,AIsError,StatusText,FloatAnimation2);
end;

procedure TMainForm.ShowStakeStatus(const AMessage: string; AIsError: Boolean = False);
begin
  StakingStatusText.Visible:=not AMessage.IsEmpty;
  ShowStatus(AMessage,AIsError,StakingStatusText,FloatAnimation5);
end;

procedure TMainForm.ShowUnstakeStatus(const AMessage: string; AIsError: Boolean = False);
begin
  UnstakingStatusText.Visible:=not AMessage.IsEmpty;
  ShowStatus(AMessage,AIsError,UnstakingStatusText,FloatAnimation6);
end;

procedure TMainForm.ShowKeyStatus(const AMessage: string; AIsError: Boolean = False);
begin
  Edit2.Visible:=not AMessage.IsEmpty;
  ShowStatus(AMessage,AIsError,Edit2,FloatAnimation7);
end;

procedure TMainForm.StakeAmountEditEnter(Sender: TObject);
begin
  ShowStakeStatus('');
end;

procedure TMainForm.StakeButton1Click(Sender: TObject);
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

procedure TMainForm.VertScrollBox1Resized(Sender: TObject);
begin
  ControlsFlexWidth([Label6,Label10,Label11,
    Label12,Label13,Label14],
    [0.13,0.05,0.3,0.35,0.1,0.07],VertScrollBox1.Content);
end;

procedure TMainForm.OnExplorerPageChange(Sender: TObject);
begin
  RefreshExplorer;
end;

end.
