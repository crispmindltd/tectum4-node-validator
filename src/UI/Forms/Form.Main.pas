unit Form.Main;

interface

uses
  App.Exceptions,
  App.Logs,
  App.Intf,
  App.Updater,
//  Blockchain.BaseTypes,
//  Blockchain.Intf,
//  Frame.Explorer,
//  Frame.History,
//  Frame.PageNum,
//  Frame.Ticker,
  Generics.Collections,
  Generics.Defaults,
  Math,
  Net.Data,
  Net.Socket,
  Styles,
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.Edit, FMX.TabControl, FMX.Platform,
  FMX.ListBox, FMX.Effects, FMX.Objects, FMX.Layouts, FMX.StdCtrls, FMX.Ani,
  System.Rtti, FMX.Grid.Style, FMX.ScrollBox, FMX.Grid, FMX.Memo.Types, FMX.Memo;

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
    AddressTETHeaderLabel: TLabel;
    HashTETHeaderLabel: TLabel;
    AmountTETHeaderLabel: TLabel;
    BalanceTETHeaderLayout: TLayout;
    SendTETDataLayout: TLayout;
    TransferTETStatusLabel: TLabel;
    FloatAnimation2: TFloatAnimation;
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
    ExpTransactionDetailsLabel: TLabel;
    ExpTransactionDetailsLayout: TLayout;
    TransactionDetailsRectangle: TRectangle;
    HashDetailsLayout: TLayout;
    HashDetailsLabel: TLabel;
    BlockDetailsLayout: TLayout;
    BlockDetailsLabel: TLabel;
    DateTimeDetailsLayout: TLayout;
    DateTimeDetailsLabel: TLabel;
    BlockDetailsText: TText;
    HashDetailsText: TText;
    DateTimeDetailsText: TText;
    Line1: TLine;
    FromDetailsLayout: TLayout;
    FromDetailsLabel: TLabel;
    FromDetailsText: TText;
    ToDetailsLayout: TLayout;
    ToDetalisLabel: TLabel;
    ToDetailsText: TText;
    Line2: TLine;
    AmountDetailsLayout: TLayout;
    AmountDetailsLabel: TLabel;
    AmountDetailsText: TText;
    TokenDetailsLayout: TLayout;
    TokenDetailsLabel: TLabel;
    TokenDetailsText: TText;
    TokenInfoDetailsLayout: TLayout;
    TokenInfoDetailsLabel: TLabel;
    TokenInfoDetailsLabelValue: TLabel;
    ExplorerBackArrowPath: TPath;
    ExplorerBackCircle: TCircle;
    FeeDetailsLayout: TLayout;
    FeeDetailsLabel: TLabel;
    FeeDetailsText: TText;
    CopyLoginLayout: TLayout;
    CopyHashSvg: TPath;
    CopyFromLayout: TLayout;
    CopyFromSvg: TPath;
    CopyToLayout: TLayout;
    CopyToSvg: TPath;
    NoTETHistoryLabel: TLabel;
    StatusTETHeaderLabel: TLabel;
    NoTokenHistoryLabel: TLabel;
    StatusTokenHeaderLabel: TLabel;
    TETTabControl: TTabControl;
    TETTabItemData: TTabItem;
    TETTransactionDataTabItem: TTabItem;
    TETTransactionDetailsLayout: TLayout;
    TETTransactionDetailsLabel: TLabel;
    TETBackCircle: TCircle;
    TETBackArrowPath: TPath;
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
    TETAddressDetailsLabel: TLabel;
    TETAddressDetailsText: TText;
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
    PagesPanelLayout: TLayout;
    NextPageLayout: TLayout;
    NextPagePath: TPath;
    PrevPageLayout: TLayout;
    PrevPagePath: TPath;
    SearchEdit: TEdit;
    SearchButton: TButton;
    TransactionNotFoundLabel: TLabel;
    FloatAnimation4: TFloatAnimation;
    HideTransactionNotFoundTimer: TTimer;
    SearchAniIndicator: TAniIndicator;
    TickerExplorerHeaderLabel: TLabel;
    TransTETAniIndicator: TAniIndicator;
    CreateTokenAniIndicator: TAniIndicator;
    TransTokenAniIndicator: TAniIndicator;
    procedure MainRectangleMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure TokenItemClick(Sender: TObject);
    procedure TokenNameEditClick(Sender: TObject);
    procedure SearchTokenEditChangeTracking(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure RecepientAddressEditChangeTracking(Sender: TObject);
    procedure AmountTokenEditChangeTracking(Sender: TObject);
    procedure SendTokenButtonClick(Sender: TObject);
    procedure FloatAnimation1Finish(Sender: TObject);
    procedure HideTokenMessageTimerTimer(Sender: TObject);
    procedure RoundRectTickerMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure AmountTETEditChangeTracking(Sender: TObject);
    procedure SendTETButtonClick(Sender: TObject);
    procedure FloatAnimation2Finish(Sender: TObject);
    procedure HideTETMessageTimerTimer(Sender: TObject);
    procedure CreateTokenAmountEditChange(Sender: TObject);
    procedure CreateTokenButtonClick(Sender: TObject);
    procedure CreateTokenEditChangeTracking(Sender: TObject);
    procedure HideCreatingMessageTimerTimer(Sender: TObject);
    procedure FloatAnimation3Finish(Sender: TObject);
    procedure ExplorerBackCircleMouseEnter(Sender: TObject);
    procedure ExplorerBackCircleMouseLeave(Sender: TObject);
    procedure ExplorerBackCircleMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure CopyLoginLayoutClick(Sender: TObject);
    procedure CopyFromLayoutClick(Sender: TObject);
    procedure CopyToLayoutClick(Sender: TObject);
    procedure CreateTokenSymbolEditChangeTracking(Sender: TObject);
    procedure TETBackCircleMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure TETCopyLoginLayoutClick(Sender: TObject);
    procedure TETCopyAddressLayoutClick(Sender: TObject);
    procedure TokenBackCircleMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure TokenCopyLoginLayoutClick(Sender: TObject);
    procedure TokenCopyAddressLayoutClick(Sender: TObject);
    procedure InputPrKeyButtonClick(Sender: TObject);
    procedure PrevPageLayoutMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure NextPageLayoutMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure SearchEditChangeTracking(Sender: TObject);
    procedure SearchButtonClick(Sender: TObject);
    procedure SearchEditKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
    procedure FloatAnimation4Finish(Sender: TObject);
    procedure HideTransactionNotFoundTimerTimer(Sender: TObject);
    procedure TabsChange(Sender: TObject);
    procedure SendTETToEditKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
    procedure CreateTokenShortNameEditKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
    procedure TokenNameEditChangeTracking(Sender: TObject);
    procedure TokenNameEditChange(Sender: TObject);
    procedure ExplorerVertScrollBoxResized(Sender: TObject);
    procedure HistoryTETVertScrollBoxResized(Sender: TObject);
    procedure HistoryTokenVertScrollBoxResized(Sender: TObject);
//  const
//    TransToDrawNumber = 18;
  private
    FBalances: TDictionary<string, Double>;
//    FTickersFrames: TList<TTickerFrame>;
//    FSelectedFrame: TTickerFrame;
//    FChosenToken: TListBoxItem;
//    FSearchResultTrans: TArray<TExplorerTransactionInfo>;
//    FTotalPagesAmount, FPageNum: Integer;

//    FDynTETBlockNum: Integer;
//    FDynTET: TTokenBase;
    function DecimalsCount(const AValue: string): Integer;
    procedure RefreshTETBalance;
    procedure RefreshTETHistory;
    procedure AlignTETHeaders;
    procedure RefreshHeaderBalance(ATicker: string);
//    procedure RefreshTokensBalances;
//    procedure AddOrRefreshBalance(ASmartKey: TCSmartKey);
//    procedure RefreshTokenHistory;
//    procedure AlignTokensHeaders;
//    procedure RefreshPagesLayout;
//    procedure OnPageSelected;
//    procedure RefreshExplorer(ATransactions: TArray<TExplorerTransactionInfo>;
//      AShowTicker: Boolean);
//    procedure AlignExplorerHeaders(AShowTicker: Boolean);
//    procedure CleanScrollBox(AVertScrollBox: TVertScrollBox);

//    procedure AddTickerFrame(const ATicker: string; ATokenID: Integer = -1);
//    procedure AddTokenItem(ATokenID: Integer; AName: string; AValue: Double);
//    procedure AddPageNum(APageNum: Integer);
//    procedure ShowTETTransferStatus(const AMessage: string; AIsError: Boolean = False);
//    procedure ShowTokenTransferStatus(const AMessage: string; AIsError: Boolean = False);
//    procedure ShowTokenCreatingStatus(const AMessage: string; AIsError: Boolean = False);
//    procedure ShowExplorerTransactionDetails(ATicker, ADateTime, ABlockNum,
//      AHash, ATransFrom, ATransTo, AAmount: string); overload;
//    procedure ShowExplorerTransactionDetails(ATransaction: TExplorerTransactionInfo); overload;
//    procedure SearchByBlockNumber(const ABlockNumber: Integer);
//    procedure SearchByHash;
//    procedure SearchByAddress;

//    procedure onTETHistoryFrameClick(Sender: TObject);
//    procedure onTokenHistoryFrameClick(Sender: TObject);
//    procedure onExplorerFrameClick(Sender: TObject);
//    procedure onPageNumFrameClick(Sender: TObject; Button: TMouseButton;
//      Shift: TShiftState; X, Y: Single);
//    procedure onTransactionSearchingDone(AIsFound: Boolean);

//    procedure TETTransferCallBack(const AResponse: string);
//    procedure TokenCreatingCallBack(const AResponse: string);
//    procedure TokenTransferCallBack(const AResponse: string);
  public
    procedure NewTETChainBlocksEvent(ANeedRefreshBalance: Boolean);
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

function CustomSortCompareStrings(Left, Right: TFmxObject): Integer;
var
  LeftLabel, RightLabel: TLabel;
begin
  LeftLabel := (Left as TListBoxItem).TagObject as TLabel;
  RightLabel := (Right as TListBoxItem).TagObject as TLabel;
  Result := CompareValue(RightLabel.Text.ToDouble, LeftLabel.Text.ToDouble);
  if Result = 0 then
    Result := CompareStr((Left as TListBoxItem).Text, (Right as TListBoxItem).Text);
end;

//function CustomSortCompareTickers(Left, Right: TFmxObject): Integer;
//var
//  LeftTicker, RightTicker: TTickerFrame;
//begin
//  LeftTicker := Left as TTickerFrame;
//  RightTicker := Right as TTickerFrame;
//  Result := CompareStr(LeftTicker.Ticker, RightTicker.Ticker);
//end;

procedure TMainForm.TokenNameEditChange(Sender: TObject);
begin
//  RefreshTokenHistory;
end;

procedure TMainForm.TokenNameEditChangeTracking(Sender: TObject);
begin
//  AmountTokenEditChangeTracking(nil);
//  NoTokenHistoryLabel.Text := Format('No %s transactions yet', [TokenNameEdit.Text]);
end;

procedure TMainForm.TokenNameEditClick(Sender: TObject);
begin
//  MainRectangle.Visible := True;
end;

//procedure TMainForm.TokenTransferCallBack(const AResponse: string);
//var
//  Splitted: TArray<string>;
//begin
//  if not AResponse.StartsWith('URKError') then
//  begin
//    RecepientAddressEdit.Text := '';
//    AmountTokenEdit.Text := '';
//    ShowTokenTransferStatus('Transaction accepted for processing');
//  end else
//  begin
//    Splitted := AResponse.Split([' ']);
//    case Splitted[3].ToInteger of
//      110: ShowTokenTransferStatus(InsufficientFundsErrorText, True);
//      41502: ShowTokenTransferStatus(InvalidSignErrorText, True);
//      41500: ShowTokenTransferStatus(ServerDidNotRespondErrorText, True);
//      41501: ShowTokenTransferStatus(ValidatorFailedErrorText, True);
//      41503: ShowTokenTransferStatus(ValidatorDidNotRespondErrorText, True);
//      41505: ShowTokenTransferStatus(TransactionInProgressErrorText, True);
//      else
//        begin
//          Logs.DoLog('Unknown error during token transfer with code ' +
//            Splitted[3], TLogType.ERROR, tcp);
//          ShowTokenTransferStatus('Unknown error with code ' + Splitted[3], True);
//        end;
//    end;
//  end;
//end;

//procedure TMainForm.AddPageNum(APageNum: Integer);
//var
//  PageNumFrame: TPageNumFrame;
//begin
//  PageNumFrame := TPageNumFrame.Create(PagesPanelLayout, APageNum,
//    APageNum = FPageNum);
//  PageNumFrame.Parent := PagesPanelLayout;
//  PagesPanelLayout.Width := PagesPanelLayout.Width + PageNumFrame.Width;
//  PageNumFrame.Position.Y := -2;
//  PageNumFrame.Position.X := PagesPanelLayout.Width - NextPageLayout.Width -
//    PageNumFrame.Width;
//  if APageNum > 0 then
//    PageNumFrame.OnMouseDown := onPageNumFrameClick;
//end;

//procedure TMainForm.AddTickerFrame(const ATicker: string; ATokenID: Integer);
//var
//  NewTickerFrame: TTickerFrame;
//begin
//  ExplorerHorzScrollBox.BeginUpdate;
//  try
//    NewTickerFrame := TTickerFrame.Create(ExplorerHorzScrollBox,
//      ATicker, ATokenID);
//    NewTickerFrame.Parent := ExplorerHorzScrollBox;
//
//    if ATicker <> 'Search results' then
//      NewTickerFrame.RoundRect.OnMouseDown := RoundRectTickerMouseDown;
//
//    FTickersFrames.Add(NewTickerFrame);
//    ExplorerHorzScrollBox.Sort(CustomSortCompareTickers);
//  finally
//    ExplorerHorzScrollBox.EndUpdate;
//  end;
//end;

//procedure TMainForm.AddTokenItem(ATokenID: Integer; AName: string;
//  AValue: Double);
//var
//  NewItem: TListBoxItem;
//  BalanceLabel: TLabel;
//begin
//  NewItem := TListBoxItem.Create(TokensListBox);
//  NewItem.BeginUpdate;
//  try
//    with NewItem do
//    begin
//      Name := AName + 'TokenItem';
//      Margins.Top := 5;
//      Margins.Right := 7;
//      Height := 38;
//      Text := AName;
//      Tag := ATokenID;
//      Cursor := crHandPoint;
//      TextSettings.Font.Family := 'Inter';
//      TextSettings.Font.Size := 14;
//      TextSettings.FontColor := $FF323130;
//      HitTest := True;
//
//      StyleLookup := 'TokenItemStyle';
//      onMouseEnter := StylesForm.OnTokenItemMouseEnter;
//      onMouseLeave := StylesForm.OnTokenItemMouseLeave;
//      onMouseDown := StylesForm.OnTokenItemMouseDown;
//      onMouseUp := StylesForm.OnTokenItemMouseUp;
//      onClick := TokenItemClick;
//    end;
//
//    BalanceLabel := TLabel.Create(NewItem);
//    NewItem.TagObject := BalanceLabel;
//    with BalanceLabel do
//    begin
//      Name := 'TokenBalanceText' + TokensListBox.Count.ToString;
//      Align := TAlignLayout.Contents;
//      Margins.Right := 10;
//      HitTest := False;
//      StyledSettings := [TStyledSetting.Style, TStyledSetting.FontColor];
//      TextSettings.Font.Family := 'Inter';
//      TextSettings.Font.Size := 14;
//      TextSettings.FontColor := TAlphaColorRec.Black;
//      TextSettings.HorzAlign := TTextAlign.Trailing;
//      Text := FormatFloat('0.########', AValue);
//      AutoSize := False;
//      Parent := NewItem;
//    end;
//  finally
//    NewItem.EndUpdate;
//  end;
//
//  TokensListBox.AddObject(NewItem);
//  PopupRectangle.Height := SearchTokenEdit.Height +
//    40 * (Min(TokensListBox.Count, 3)) + 36;
//end;

//procedure TMainForm.AlignExplorerHeaders(AShowTicker: Boolean);
//var
//  Width, ContentWidth: Single;
//begin
//  ExplorerHeaderLayout.BeginUpdate;
//  try
//    if ExplorerVertScrollBox.ContentBounds.Width <= 0 then
//      ContentWidth := 1094
//    else
//      ContentWidth := ExplorerVertScrollBox.ContentBounds.Width;
//
//    TickerExplorerHeaderLabel.Visible := AShowTicker;
//    Width := ContentWidth - DateTimeLabelWidth -
//        BlockLabelWidth - ValueLabelWidth - 75;
//    if AShowTicker then
//    begin
//      Width := Width - TickerLabelWidth - 15;
//      TickerExplorerHeaderLabel.Position.X := FromExplorerHeaderLabel.Position.X - 1;
//    end;
//
//    FromExplorerHeaderLabel.Width := Width * 0.25;
//    ToExplorerHeaderLabel.Width := Width * 0.25;
//    HashExplorerHeaderLabel.Width := Width * 0.5;
//    AmountExplorerHeaderLabel.Position.X := HashExplorerHeaderLabel.Position.X +
//      HashExplorerHeaderLabel.Width + 1;
//  finally
//    ExplorerHeaderLayout.EndUpdate;
//  end;
//end;

procedure TMainForm.AlignTETHeaders;
var
  Width, ContentWidth: Single;
begin
  HistoryTETVertScrollBox.BeginUpdate;
  try
    if HistoryTETVertScrollBox.ContentBounds.Width <= 0 then
      ContentWidth := 1078
    else
      ContentWidth := HistoryTETVertScrollBox.ContentBounds.Width;

//    Width := ContentWidth - DateTimeLabelWidth -
//      BlockLabelWidth - ValueLabelWidth - IncomRectWidth - 85;
    AddressTETHeaderLabel.Width := Width * 0.4;
    HashTETHeaderLabel.Width := Width * 0.6;
  finally
    HistoryTETVertScrollBox.EndUpdate;
  end;
end;

//procedure TMainForm.AlignTokensHeaders;
//var
//  Width, ContentWidth: Single;
//begin
//  HistoryTokenVertScrollBox.BeginUpdate;
//  try
//    if HistoryTokenVertScrollBox.ContentBounds.Width = 0 then
//      ContentWidth := 1094
//    else
//      ContentWidth := HistoryTokenVertScrollBox.ContentBounds.Width;
//
//    Width := ContentWidth - DateTimeLabelWidth -
//      BlockLabelWidth - ValueLabelWidth - IncomRectWidth - 85;
//    AddressTokenHeaderLabel.Width := Width * 0.4;
//    HashTokenHeaderLabel.Width := Width * 0.6;
//  finally
//    HistoryTokenVertScrollBox.EndUpdate;
//  end;
//end;

procedure TMainForm.AmountTokenEditChangeTracking(Sender: TObject);
//var
//  isNumber: Boolean;
//  val,balance: Double;
//  tICO:TTokenICODat;
begin
//  const isGetTokenSuccess = AppCore.TryGetTokenICO(TokenNameEdit.Text, tICO);
//  FBalances.TryGetValue(TokenNameEdit.Text, balance);
//  isNumber := TryStrToFloat(AmountTokenEdit.Text, val);
//
//  const Decimals = DecimalsCount(AmountTokenEdit.Text);
//
//  SendTokenButton.Enabled := isGetTokenSuccess and (Length(RecepientAddressEdit.Text) >= 10) and
//    isNumber and (val > 0) and (val <= balance) and (Decimals <= tICO.FloatSize);
//
//  with TransferTokenStatusLabel do
//  begin
//    if isNumber and (val > balance) then
//    begin
//      Text := 'Insufficient funds';
//      TextSettings.FontColor := ERROR_TEXT_COLOR;
//      Opacity := 1;
//    end
//    else if (Decimals > tICO.FloatSize) then
//    begin
//      Text := 'Too much digits';
//      TextSettings.FontColor := ERROR_TEXT_COLOR;
//      Opacity := 1;
//    end else
//      Opacity := 0;
//  end;
end;

procedure TMainForm.ExplorerBackCircleMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
//  ExplorerTabControl.Previous;
//  SearchEdit.SetFocus;
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
//  AlignExplorerHeaders(TickerExplorerHeaderLabel.Visible);
end;

procedure TMainForm.TETBackCircleMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
//  TETTabControl.Previous;
end;

//procedure TMainForm.CleanScrollBox(AVertScrollBox: TVertScrollBox);
//var
//  Frame: TComponent;
//  i: Integer;
//begin
//  i := 0;
//  while i < AVertScrollBox.ComponentCount do
//  begin
//    Frame := AVertScrollBox.Components[i];
//    if (AVertScrollBox.Components[i] is THistoryTransactionFrame) or
//       (AVertScrollBox.Components[i] is TExplorerTransactionFrame) then
//      Frame.Free
//    else
//      Inc(i);
//  end;
//end;

procedure TMainForm.CopyFromLayoutClick(Sender: TObject);
//var
//  Service: IFMXClipBoardService;
begin
//  if TPlatformServices.Current.SupportsPlatformService(IFMXClipBoardService, Service) then
//    Service.SetClipboard(FromDetailsText.Text);
end;

procedure TMainForm.CopyLoginLayoutClick(Sender: TObject);
//var
//  Service: IFMXClipBoardService;
begin
//  if TPlatformServices.Current.SupportsPlatformService(IFMXClipBoardService, Service) then
//    Service.SetClipboard(HashDetailsText.Text);
end;

procedure TMainForm.CopyToLayoutClick(Sender: TObject);
//var
//  Service: IFMXClipBoardService;
begin
//  if TPlatformServices.Current.SupportsPlatformService(IFMXClipBoardService, Service) then
//    Service.SetClipboard(ToDetailsText.Text);
end;

procedure TMainForm.CreateTokenAmountEditChange(Sender: TObject);
//var
//  value: Int64;
begin
//  if TryStrToInt64(CreateTokenAmountEdit.Text,value) then
//    CreateTokenAmountEdit.Text := Max(value,1).ToString;
end;

procedure TMainForm.CreateTokenButtonClick(Sender: TObject);
begin
//  CreateTokenButton.Enabled := False;
//  CreateTokenAniIndicator.Visible := True;
//  CreateTokenAniIndicator.Enabled := True;
//
//  try
//    AppCore.DoNewToken('*', AppCore.SessionKey,
//      CreateTokenInformationMemo.Text, CreateTokenShortNameEdit.Text,
//      CreateTokenSymbolEdit.Text, CreateTokenAmountEdit.Text.ToInt64,
//      DecimalsEdit.Text.ToInteger, TokenCreatingCallBack);
//  except
//    on E:EValidError do
//      ShowTokenCreatingStatus(E.Message, True);
//    on E:Exception do
//    begin
//      ShowTokenCreatingStatus('Unknown error', True);
//      Logs.DoLog('Unknown error during token creating with message: '
//        + E.Message, ERROR, tcp);
//    end;
//  end;
end;

//procedure TMainForm.TokenCreatingCallBack(const AResponse: string);
//var
//  Splitted: TArray<string>;
//begin
//  if not AResponse.StartsWith('URKError') then
//  begin
//    CreateTokenShortNameEdit.Text := '';
//    CreateTokenSymbolEdit.Text := '';
//    CreateTokenAmountEdit.Text := '';
//    DecimalsEdit.Text := '';
//    CreateTokenInformationMemo.Text := '';
//    ShowTokenCreatingStatus('Token successfully created');
//  end else
//  begin
//    Splitted := AResponse.Split([' ']);
//    case Splitted[3].ToInteger of
//      20: ShowTokenCreatingStatus(KeyExpiredErrorText, True);
//      44: ShowTokenCreatingStatus(TokenAlreadyExistsErrorText, True);
//      3203: ShowTokenCreatingStatus(InsufficientFundsErrorText, True);
//      43444: ShowTokenCreatingStatus(TickerIsProhibitedErrorText, True);
//      else
//        begin
//          Logs.DoLog('Unknown error during token creating with code ' +
//            Splitted[3], TLogType.ERROR, tcp);
//          ShowTokenCreatingStatus('Unknown error with code ' + Splitted[3], True);
//        end;
//    end;
//  end;
//end;

procedure TMainForm.CreateTokenEditChangeTracking(Sender: TObject);
//var
//  k: Integer;
//  l: Int64;
begin
//  with TokenCreatingStatusLabel do
//  begin
//    if TryStrToInt(DecimalsEdit.Text,k) and
//      (k + Length(CreateTokenAmountEdit.Text) > 18) then
//    begin
//      Text := 'The sum of the digits of the quantity and ' +
//        'the value of the "Decimal" field must not be greater than 18';
//      TextSettings.FontColor := ERROR_TEXT_COLOR;
//      Opacity := 1;
//    end else
//      Opacity := 0;
//  end;
//
//  CreateTokenButton.Enabled := (Length(CreateTokenShortNameEdit.Text) >= 3) and
//    (Length(CreateTokenSymbolEdit.Text) >= 3) and
//    TryStrToInt64(CreateTokenAmountEdit.Text,l) and (l >= 1000) and
//    (l <= 9999999999999999) and TryStrToInt(DecimalsEdit.Text,k) and
//    (Length(CreateTokenInformationMemo.Text) >= 10) and
//    (TokenCreatingStatusLabel.Opacity = 0);
//
//  if CreateTokenButton.Enabled and TryStrToInt64(CreateTokenAmountEdit.Text,l) and
//    TryStrToInt(DecimalsEdit.Text,k) then
//    TokenCreationFeeLabel.Text := Format('Creation token fee: %d TET',
//      [AppCore.GetNewTokenFee(l,k)])
//  else
//    TokenCreationFeeLabel.Text := 'Creation token fee: 0 TET';
end;

procedure TMainForm.CreateTokenShortNameEditKeyDown(Sender: TObject;
  var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
//  if CreateTokenButton.Enabled and (Key = 13) then
//    CreateTokenButtonClick(Self);
end;

procedure TMainForm.CreateTokenSymbolEditChangeTracking(Sender: TObject);
begin
//  CreateTokenSymbolEdit.Text := CreateTokenSymbolEdit.Text.ToUpper;
//  CreateTokenEditChangeTracking(Self);
end;

function TMainForm.DecimalsCount(const AValue: string): Integer;
begin
  const TrimmedValue = AValue //
    .Trim //
    .Replace('.', FormatSettings.DecimalSeparator) //
    .Replace(',', FormatSettings.DecimalSeparator);
  const DecimalPos = Pos(FormatSettings.DecimalSeparator, TrimmedValue);
  if DecimalPos = 0 then
  begin
    Result := 0;
    Exit;
  end;
  Result := Length(TrimmedValue) - DecimalPos;
end;

procedure TMainForm.TokenItemClick(Sender: TObject);
//var
//  TokenICO: TTokenICODat;
begin
//  FChosenToken := Sender as TListBoxItem;
//  TokenNameEdit.Text := FChosenToken.Text;
//  RefreshHeaderBalance(TokenNameEdit.Text);
//  MainRectangleMouseDown(nil, TMouseButton.mbLeft, [], 0, 0);
//
//  if AppCore.TryGetTokenICO(TokenNameEdit.Text, TokenICO) then
//  begin
//    TokenShortNameEdit.Text := TokenICO.ShortName;
//    TokenInfoMemo.Text := TokenICO.FullName;
//  end else
//  begin
//    TokenShortNameEdit.Text := '';
//    TokenInfoMemo.Text := '';
//  end;
end;

procedure TMainForm.FloatAnimation1Finish(Sender: TObject);
begin
//  FloatAnimation1.Inverse := not FloatAnimation1.Inverse;
//  if FloatAnimation1.Inverse then
//    HideTokenMessageTimer.Enabled := True;
end;

procedure TMainForm.FloatAnimation2Finish(Sender: TObject);
begin
//  FloatAnimation2.Inverse := not FloatAnimation2.Inverse;
//  if FloatAnimation2.Inverse then
//    HideTETMessageTimer.Enabled := True;
end;

procedure TMainForm.FloatAnimation3Finish(Sender: TObject);
begin
//  FloatAnimation3.Inverse := not FloatAnimation3.Inverse;
//  if FloatAnimation3.Inverse then
//    HideCreatingMessageTimer.Enabled := True;
end;

procedure TMainForm.FloatAnimation4Finish(Sender: TObject);
begin
//  FloatAnimation4.Inverse := not FloatAnimation4.Inverse;
//  FloatAnimation4.Enabled := False;
//  HideTransactionNotFoundTimer.Enabled := FloatAnimation4.Inverse;
end;

procedure TMainForm.FormCreate(Sender: TObject);
//var
//  SmartKey: TCSmartKey;
begin
  Caption := 'LNode' + ' ' + Updater.CurVersion;
  FBalances := TDictionary<string, Double>.Create;
//  SetLength(FSearchResultTrans, 0);
//  FSelectedFrame := nil;
//  FTickersFrames := TList<TTickerFrame>.Create;
//  FTickersFrames.Capacity := 100;
//  AddTickerFrame('Search results');
//  AddTickerFrame('Tectum');
//  for SmartKey in AppCore.GetAllSmartKeyBlocks do
//    AddTickerFrame(SmartKey.Abreviature, SmartKey.SmartID);
//  FChosenToken := nil;
//  AppCore.TryGetDynTETBlock(AppCore.TETAddress, FDynTETBlockNum, FDynTET);
//
//  TETCopyLoginLayout.OnMouseEnter := StylesForm.OnCopyLayoutMouseEnter;
//  TETCopyLoginLayout.OnMouseLeave := StylesForm.OnCopyLayoutMouseLeave;
//  TETCopyLoginLayout.OnMouseDown := StylesForm.OnCopyLayoutMouseDown;
//  TETCopyLoginLayout.OnMouseUp := StylesForm.OnCopyLayoutMouseUp;
//
//  TETCopyAddressLayout.OnMouseEnter := StylesForm.OnCopyLayoutMouseEnter;
//  TETCopyAddressLayout.OnMouseLeave := StylesForm.OnCopyLayoutMouseLeave;
//  TETCopyAddressLayout.OnMouseDown := StylesForm.OnCopyLayoutMouseDown;
//  TETCopyAddressLayout.OnMouseUp := StylesForm.OnCopyLayoutMouseUp;
//
//  TokenCopyLoginLayout.OnMouseEnter := StylesForm.OnCopyLayoutMouseEnter;
//  TokenCopyLoginLayout.OnMouseLeave := StylesForm.OnCopyLayoutMouseLeave;
//  TokenCopyLoginLayout.OnMouseDown := StylesForm.OnCopyLayoutMouseDown;
//  TokenCopyLoginLayout.OnMouseUp := StylesForm.OnCopyLayoutMouseUp;
//
//  TokenCopyAddressLayout.OnMouseEnter := StylesForm.OnCopyLayoutMouseEnter;
//  TokenCopyAddressLayout.OnMouseLeave := StylesForm.OnCopyLayoutMouseLeave;
//  TokenCopyAddressLayout.OnMouseDown := StylesForm.OnCopyLayoutMouseDown;
//  TokenCopyAddressLayout.OnMouseUp := StylesForm.OnCopyLayoutMouseUp;
//
//  CopyLoginLayout.OnMouseEnter := StylesForm.OnCopyLayoutMouseEnter;
//  CopyLoginLayout.OnMouseLeave := StylesForm.OnCopyLayoutMouseLeave;
//  CopyLoginLayout.OnMouseDown := StylesForm.OnCopyLayoutMouseDown;
//  CopyLoginLayout.OnMouseUp := StylesForm.OnCopyLayoutMouseUp;
//
//  CopyFromLayout.OnMouseEnter := StylesForm.OnCopyLayoutMouseEnter;
//  CopyFromLayout.OnMouseLeave := StylesForm.OnCopyLayoutMouseLeave;
//  CopyFromLayout.OnMouseDown := StylesForm.OnCopyLayoutMouseDown;
//  CopyFromLayout.OnMouseUp := StylesForm.OnCopyLayoutMouseUp;
//
//  CopyToLayout.OnMouseEnter := StylesForm.OnCopyLayoutMouseEnter;
//  CopyToLayout.OnMouseLeave := StylesForm.OnCopyLayoutMouseLeave;
//  CopyToLayout.OnMouseDown := StylesForm.OnCopyLayoutMouseDown;
//  CopyToLayout.OnMouseUp := StylesForm.OnCopyLayoutMouseUp;
//
//  PrevPageLayout.OnMouseEnter := StylesForm.OnCopyLayoutMouseEnter;
//  PrevPageLayout.OnMouseLeave := StylesForm.OnCopyLayoutMouseLeave;
//  NextPageLayout.OnMouseEnter := StylesForm.OnCopyLayoutMouseEnter;
//  NextPageLayout.OnMouseLeave := StylesForm.OnCopyLayoutMouseLeave;
//
//  const Digitals = '0123456789' + FormatSettings.DecimalSeparator;
//  AmountTETEdit.FilterChar := Digitals;
//  AmountTokenEdit.FilterChar := Digitals;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
//  FTickersFrames.Free;
  FBalances.Free;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
//  AddressTETLabel.Text := AppCore.TETAddress;
//  AddressTokenLabel.Text := AppCore.TETAddress;
//  RefreshTokensBalances;
  Tabs.TabIndex := 0;
  Tabs.OnChange(nil);
//  FTickersFrames.Items[1].RoundRect.OnMouseDown(FTickersFrames.Items[1].RoundRect,
//    TMouseButton.mbLeft, [], 0, 0);
end;

procedure TMainForm.HideCreatingMessageTimerTimer(Sender: TObject);
begin
//  HideCreatingMessageTimer.Enabled := False;
//  FloatAnimation3.Start;
end;

procedure TMainForm.HideTETMessageTimerTimer(Sender: TObject);
begin
//  HideTETMessageTimer.Enabled := False;
//  FloatAnimation2.Start;
end;

procedure TMainForm.HideTokenMessageTimerTimer(Sender: TObject);
begin
//  HideTokenMessageTimer.Enabled := False;
//  FloatAnimation1.Start;
end;

procedure TMainForm.HideTransactionNotFoundTimerTimer(Sender: TObject);
begin
//  HideTransactionNotFoundTimer.Enabled := False;
//  FloatAnimation4.Enabled := True;
end;

procedure TMainForm.HistoryTETVertScrollBoxResized(Sender: TObject);
begin
  AlignTETHeaders;
end;

procedure TMainForm.HistoryTokenVertScrollBoxResized(Sender: TObject);
begin
//  AlignTokensHeaders;
end;

procedure TMainForm.InputPrKeyButtonClick(Sender: TObject);
begin
//  UI.ShowEnterPrivateKeyForm;
end;

procedure TMainForm.TabsChange(Sender: TObject);
begin
  case Tabs.TabIndex of
    0:
      begin
        RefreshTETBalance;
        RefreshTETHistory;
        AlignTETHeaders;
        SendTETToEdit.SetFocus;
      end;
//    1:
//      begin
//        RefreshTokenHistory;
//        AlignTokensHeaders;
//        RecepientAddressEdit.SetFocus;
//      end;
//    2: CreateTokenShortNameEdit.SetFocus;
    3: begin
         ExplorerTabControl.TabIndex := 0;
//         AlignExplorerHeaders(TickerExplorerHeaderLabel.Visible);
         SearchEdit.SetFocus;
       end;
  end;
end;

procedure TMainForm.TETCopyAddressLayoutClick(Sender: TObject);
//var
//  Service: IFMXClipBoardService;
begin
//  if TPlatformServices.Current.SupportsPlatformService(IFMXClipBoardService, Service) then
//    Service.SetClipboard(TETAddressDetailsText.Text);
end;

procedure TMainForm.TETCopyLoginLayoutClick(Sender: TObject);
//var
//  Service: IFMXClipBoardService;
begin
//  if TPlatformServices.Current.SupportsPlatformService(IFMXClipBoardService, Service) then
//    Service.SetClipboard(TETHashDetailsText.Text);
end;

//procedure TMainForm.TETTransferCallBack(const AResponse: string);
//var
//  Splitted: TArray<string>;
//begin
//  if not AResponse.StartsWith('URKError') then
//  begin
//    SendTETToEdit.Text := '';
//    AmountTETEdit.Text := '';
//    ShowTETTransferStatus('Transaction successful');
//  end else
//  begin
//    Splitted := AResponse.Split([' ']);
//    case Splitted[3].ToInteger of
//      20: ShowTETTransferStatus(KeyExpiredErrorText, True);
//      55: ShowTETTransferStatus(AddressNotExistsErrorText, True);
//      110: ShowTETTransferStatus(InsufficientFundsErrorText, True);
//      4042: ShowTETTransferStatus(UnableSendToTyourselfErrorText, True);
//      else
//        begin
//          Logs.DoLog('Unknown error during TET transfer with code ' +
//            Splitted[3], TLogType.ERROR, tcp);
//          ShowTETTransferStatus('Unknown error with code ' + Splitted[3], True);
//        end;
//    end;
//  end;
//end;

procedure TMainForm.TokenBackCircleMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
//  TokenTabControl.Previous;
end;

procedure TMainForm.TokenCopyAddressLayoutClick(Sender: TObject);
//var
//  Service: IFMXClipBoardService;
begin
//  if TPlatformServices.Current.SupportsPlatformService(IFMXClipBoardService, Service) then
//    Service.SetClipboard(TokenAddressDetailsText.Text);
end;

procedure TMainForm.TokenCopyLoginLayoutClick(Sender: TObject);
//var
//  Service: IFMXClipBoardService;
begin
//  if TPlatformServices.Current.SupportsPlatformService(IFMXClipBoardService, Service) then
//    Service.SetClipboard(TokenHashDetailsText.Text);
end;

procedure TMainForm.MainRectangleMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
//  MainRectangle.Visible := False;
//  SearchTokenEdit.Text := '';
end;

procedure TMainForm.NewTETChainBlocksEvent(ANeedRefreshBalance: Boolean);
begin
  if ANeedRefreshBalance and (Tabs.TabIndex = 0) then
  begin
    RefreshTETBalance;
    RefreshTETHistory;
  end;
//  if (Tabs.TabIndex = 3) and (FSelectedFrame.Ticker = 'Tectum') then
//    RefreshPagesLayout;
end;

//procedure TMainForm.NewTokenEvent(ASmartKey: TCSmartKey);
//begin
//  AddTickerFrame(ASmartKey.Abreviature, ASmartKey.SmartID);
//  AddOrRefreshBalance(ASmartKey);
//end;

//procedure TMainForm.OnPageSelected;
//var
//  frame: TPageNumFrame;
//  i: Integer;
//begin
//  for i := 0 to PagesPanelLayout.ComponentCount-1 do
//  begin
//    if (PagesPanelLayout.Components[i] is TPageNumFrame) then
//    begin
//      frame := PagesPanelLayout.Components[i] as TPageNumFrame;
//      if ((PagesPanelLayout.Components[i] as TPageNumFrame).Tag = FPageNum) then
//        frame.PageNumText.TextSettings.FontColor := $FF4285F4
//      else
//        frame.PageNumText.TextSettings.FontColor := MOUSE_LEAVE_COLOR;
//    end;
//  end;
//
//  PrevPageLayout.Enabled := FPageNum > 1;
//  NextPageLayout.Enabled := FPageNum < FTotalPagesAmount;
//end;

//procedure TMainForm.NewTokenBlocksEvent(ASmartKey: TCSmartKey;
//  ANeedRefreshBalance: Boolean);
//begin
//  if ANeedRefreshBalance then
//  begin
//    AddOrRefreshBalance(ASmartKey);
//    RefreshTokenHistory;
//  end;
//  if (Tabs.TabIndex = 3) and (FSelectedFrame.Tag = ASmartKey.SmartID) then
//    RefreshPagesLayout;
//end;

procedure TMainForm.NextPageLayoutMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
//  Inc(FPageNum);
//  RefreshPagesLayout;
end;

//procedure TMainForm.onExplorerFrameClick(Sender: TObject);
//begin
//  with (Sender as TExplorerTransactionFrame) do
//  begin
//    ShowExplorerTransactionDetails(TickerLabel.Text, DateTimeLabel.Text,
//      BlockLabel.Text, HashLabel.Text, FromLabel.Text, ToLabel.Text,
//      AmountLabel.Text);
//  end;
//end;

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

//procedure TMainForm.onTETHistoryFrameClick(Sender: TObject);
//var
//  ICOBlock: TTokenICODat;
//begin
//  if not AppCore.TryGetTokenICO('TET', ICOBlock) then
//    exit;
//
//  with (Sender as THistoryTransactionFrame) do
//  begin
//    SetText(TETDateTimeDetailsText, DateTimeLabel.Text);
//    SetText(TETBlockDetailsText, BlockLabel.Text);
//    SetText(TETAddressDetailsText, AddressLabel.Text);
//    SetText(TETHashDetailsText, HashLabel.Text);
//    SetText(TETAmountDetailsText, AmountLabel.Text);
//    SetText(TETDetailsText, Format('%s (%s)', [ICOBlock.Abreviature,
//      ICOBlock.ShortName]));
//    SetText(TETInfoDetailsLabelValue, ICOBlock.FullName);
//    if IncomText.Text = 'OUT' then
//      TETAddressDetailsLabel.Text := 'To'
//    else
//      TETAddressDetailsLabel.Text := 'From';
//  end;
//  TETTransactionDetailsRectangle.Height := TETInfoDetailsLabelValue.Height + 381;
//  TETTabControl.Next;
//end;

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

//procedure TMainForm.RefreshExplorer(
//  ATransactions: TArray<TExplorerTransactionInfo>; AShowTicker: Boolean);
//var
//  NewTransFrame: TExplorerTransactionFrame;
//  i: Integer;
//  Format: string;
//begin
//  CleanScrollBox(ExplorerVertScrollBox);
//  ExplorerVertScrollBox.BeginUpdate;
//  try
//    for i := 0 to Length(ATransactions) - 1 do
//    begin
//      Format := '0.' + string.Create('0', ATransactions[i].FloatSize);
//      NewTransFrame := TExplorerTransactionFrame.Create(ExplorerVertScrollBox,
//                                                        ATransactions[i].DateTime,
//                                                        ATransactions[i].BlockNum,
//                                                        ATransactions[i].Ticker,
//                                                        ATransactions[i].TransFrom,
//                                                        ATransactions[i].TransTo,
//                                                        ATransactions[i].Hash,
//                                                        FormatFloat(Format,
//                                                          ATransactions[i].Amount),
//                                                        AShowTicker);
//      NewTransFrame.OnClick := onExplorerFrameClick;
//      NewTransFrame.Parent := ExplorerVertScrollBox;
//    end;
//  finally
//    ExplorerVertScrollBox.EndUpdate;
//  end;
//end;

procedure TMainForm.RefreshHeaderBalance(ATicker: string);
var
  Value: Double;
begin
  if FBalances.TryGetValue(ATicker, Value) then
    BalanceTokenValueLabel.Text :=
      Format('%s %s', [FormatFloat('0.########', Value), ATicker]);
end;

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

procedure TMainForm.RefreshTETBalance;
var
  val: Double;
begin
  try
//    val := AppCore.GetTETBalance(FDynTETBlockNum, FDynTET);
    FBalances.AddOrSetValue('TET', val);
    BalanceTETValueLabel.Text := FormatFloat('0.########', val) + ' TET';
  except
    on E:ENoInfoForThisAccountError do
      BalanceTETValueLabel.Text := '<ERROR: DATA NOT FOUND>';
    on E:Exception do
      BalanceTETValueLabel.Text := '<UNKNOWN ERROR>';
  end;
end;

procedure TMainForm.RefreshTETHistory;
const
  MaxTransactionsNumber = 20;
var
//  TETTransactions: TArray<THistoryTransactionInfo>;
//  TETTransactionFrame: THistoryTransactionFrame;
  i: Integer;
begin
//  TETTransactions := AppCore.GetTETUserLastTransactions(AppCore.UserID, 0,
//    MaxTransactionsNumber);

//  NoTETHistoryLabel.Visible := Length(TETTransactions) = 0;
  HistoryTETHeaderLayout.Visible := not NoTETHistoryLabel.Visible;
  HistoryTETVertScrollBox.Visible := not NoTETHistoryLabel.Visible;
  if NoTETHistoryLabel.Visible then
    exit;

//  HistoryTETVertScrollBox.BeginUpdate;
//  CleanScrollBox(HistoryTETVertScrollBox);
//  try
//    for i := 0 to Length(TETTransactions) - 1 do
//    begin
//      with TETTransactions[i] do
//        TETTransactionFrame := THistoryTransactionFrame.Create(
//          HistoryTETVertScrollBox, DateTime, BlockNum, Address, Hash,
//          FormatFloat('0.00000000', Value), Incom);
//      TETTransactionFrame.OnClick := onTETHistoryFrameClick;
//      TETTransactionFrame.Parent := HistoryTETVertScrollBox;
//    end;
//  finally
//    HistoryTETVertScrollBox.EndUpdate;
//    AlignTETHeaders;
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
//var
//  BlockNum: Integer;
begin
//  SearchEdit.Enabled := False;
//  if TryStrToInt(SearchEdit.Text, BlockNum) then
//    SearchByBlockNumber(BlockNum)
//  else
//    if Length(SearchEdit.Text) = 64 then
//      SearchByHash
//  else
//    SearchByAddress;
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
//  SendTETButton.Enabled := False;
//  TransTETAniIndicator.Visible := True;
//  TransTETAniIndicator.Enabled := True;
//
//  try
//    AppCore.DoTETTransfer('*', AppCore.SessionKey, SendTETToEdit.Text,
//      AmountTETEdit.Text.ToDouble, TETTransferCallBack);
//  except
//    on E:EValidError do
//      ShowTETTransferStatus(E.Message, True);
//    on E:Exception do
//    begin
//      Logs.DoLog('Unknown error during TET transfer with message: ' + E.Message,
//        TLogType.ERROR, tcp);
//      ShowTETTransferStatus('Unknown error', True);
//    end;
//  end;
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

//procedure TMainForm.ShowExplorerTransactionDetails(ATicker, ADateTime,
//  ABlockNum, AHash, ATransFrom, ATransTo, AAmount: string);
//var
//  TokenICO: TTokenICODat;
//begin
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
//  if ExplorerTabControl.Index = 0 then
//    ExplorerTabControl.Next;
//end;

//procedure TMainForm.ShowTETTransferStatus(const AMessage: string;
//  AIsError: Boolean);
//begin
//  TransTETAniIndicator.Enabled := False;
//  TransTETAniIndicator.Visible := False;
//
//  TransferTETStatusLabel.Text := AMessage;
//  if AIsError then
//    TransferTETStatusLabel.TextSettings.FontColor := ERROR_TEXT_COLOR
//  else
//    TransferTETStatusLabel.TextSettings.FontColor := SUCCESS_TEXT_COLOR;
//
//  FloatAnimation2.Start;
//end;

//procedure TMainForm.ShowTokenCreatingStatus(const AMessage: string;
//  AIsError: Boolean);
//begin
//  CreateTokenAniIndicator.Enabled := False;
//  CreateTokenAniIndicator.Visible := False;
//
//  TokenCreatingStatusLabel.Text := AMessage;
//  if AIsError then
//    TokenCreatingStatusLabel.TextSettings.FontColor := ERROR_TEXT_COLOR
//  else
//    TokenCreatingStatusLabel.TextSettings.FontColor := SUCCESS_TEXT_COLOR;
//
//  FloatAnimation3.Start;
//end;

//procedure TMainForm.ShowTokenTransferStatus(const AMessage: string; AIsError: Boolean);
//begin
//  TransTokenAniIndicator.Enabled := False;
//  TransTokenAniIndicator.Visible := False;
//
//  TransferTokenStatusLabel.Text := AMessage;
//  if AIsError then
//    TransferTokenStatusLabel.TextSettings.FontColor := ERROR_TEXT_COLOR
//  else
//    TransferTokenStatusLabel.TextSettings.FontColor := SUCCESS_TEXT_COLOR;
//
//  FloatAnimation1.Start;
//end;

end.
