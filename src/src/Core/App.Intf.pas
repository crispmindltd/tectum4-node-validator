unit App.Intf;

interface

uses
  System.SysUtils,
  Database.Types,
  Blockchain.Data,
  Blockchain.Types,
  Net.Intf;

type
  IUI = interface
    procedure Run;
    procedure DoTerminate;
    procedure DoMessage(const AMessage: string);
    procedure ShowMessage(const AMessage: string; OnCloseProc: TProc);
    procedure ShowException(const Reason: string; OnCloseProc: TProc);
    procedure ShowWarning(const Reason: string; OnCloseProc: TProc);
    procedure DoSynchronize(const Position, Count: UInt64);
    procedure DataChange;
    procedure DoConnectionFailed(const Address: string);
  end;

{$SCOPEDENUMS ON}

  TAppState = (Synchronized, Halted);
  TAppStates = set of TAppState;

  TNetNode = record
    Name: string;
    State: TConnectionState;
  end;

  TNetStatistics = record
    Servers: TArray<TNetNode>;
    Clients: TArray<TNetNode>;
  end;

  TTransferTo = record
    Address: string;
    Amount: TAmount;
  end;

  IAppCore = interface
    procedure Start;
    procedure Stop;
    procedure Reset;
    function GetPrKey: string;
    function GetPubKey: string;
    function GetAddress: string;
    procedure GenNewKeys(var ASeedPhrase, APrKey, APubKey, AAddress: string);
    function DoRecoverKeys(const ASeed: string; out APubKey: string;
      out APrKey: string; out AAddress: string): string;
    procedure ChangePrivateKey(const PrKey: string);
    function CalculateFee(Amount: TAmount): TAmount;
    function CalculateMaxSendValue(Amount: TAmount): TAmount;
    function RecordsCount: Int64;
    function Valid4RecordsCount: Integer;
    function ReadRawData(StartIndex: Int64): TBytes;
    procedure WriteRawData(const Data: TBytes);
    function DoTransaction(const Bytes: TBytes): TBytes;
    function DoValidation(const Bytes: TBytes): TBytes;
    function DoMineBlock(const BlockData: TBlockData): string;
    function DoTokenMint(const Name, Ticker, Description: string; Digits: Byte; AAmount, ALiquidity: TAmount; const IconBytes: TBytes; const APrKey: string): string;
    function DoTokenBurn(const AAmount: TAmount; const ATicker: string; const APrKey: string): string;
    function DoTokenTransfer(const AAddrFrom, AAddrTo: string; AAmount: TAmount; const APrKey: string; TokenId:UInt64): string;
    function DoTokenTransfers(const AAddrFrom: string; ATo: TArray<TTransferTo>; const APrKey: string): string;
    function DoTokenMigrate(const AAddrFrom, AAddrTo: string; AAmount: TAmount; const APrKey: string): string;
    function DoTokenStake(const AAddr: string; AAmount: TAmount; const APrKey: string): string;
    function DoTokenUnstake(const AAddr: string; AAmount: TAmount; const APrKey: string): string;
    function DoValidate40(const AAddr: string; TxHash: string; const Rewards: TArray<TRewardInfo>; const APrKey: string): string;
    function DoSignedTransfer(const AAddrFrom, AAddrTo: string; AAmount: TAmount; const APrKey: string): string;
    function DoSendRawTransaction(const ATxHexBytes: string): string;
    function GetTokenBalance(const AAddress: string; TokenId:Uint64): TAmount;
    function GetTokenData(const Name: string; Required: Boolean = True): TToken;
    function GetTokensData: TArray<TToken>;
    function GetStakingBalance(const AAddress: string): TAmount;
    function GetRewardBalance(const AAddress: string): TAmount;
    function GetStakingInfo(const AAddress: string): TStakingInfo;
    function GetUserLastTransactions(const AAddress: string; Skip, Count: Int64;
      Ticker: string = 'TEC'): TArray<TTransactionInfo>;
    function GetLastTransactions(Skip, Count: Int64): TArray<TTransactionInfo>;
    function GetTransactionInfo(Index: Int64): TTransactionInfo; overload;
    function GetTransactionInfo(const TxHash: string): TTransactionInfo; overload;
    function GetBlockInfo(const Hash: string): TBlockInfo;
    function GetLastBlocksInfo(Skip, Count: Int64): TArray<TBlockInfo>;
    procedure EnumTxns(Proc: TTxFilterPredicate);
    procedure SetBlockchainSynchronized(Synchronized: Boolean);
    procedure DoHalt(const Reason: string);
    function GetStates: TAppStates;
    function GetNetStats: TNetStatistics;
    function GetAppVersion: string;
    function GetAppVersionText: string;
    procedure StartUpdate;
    property PrKey: string read GetPrKey;
    property PubKey: string read GetPubKey;
    property Address: string read GetAddress;
    property States: TAppStates read GetStates;
  end;

var
  AppCore: IAppCore = nil;
  UI: IUI = nil;

implementation

end.
