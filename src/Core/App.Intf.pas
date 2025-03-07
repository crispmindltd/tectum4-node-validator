unit App.Intf;

interface

uses
  System.SysUtils,
  Blockchain.Data,
  Blockchain.Txn,
  Blockchain.Validation,
  BlockChain.Reward,
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
    procedure NotifyNewTETBlocks;
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

  IAppCore = interface
    procedure Start;
    procedure Stop;
    procedure Reset;
    function GetPrKey: string;
    function GetPubKey: string;
    function GetAddress: string;

    procedure GenNewKeys(var ASeedPhrase, APrKey, APubKey, AAddress: string);
    function DoRecoverKeys(ASeed: string; out APubKey: string;
      out APrKey: string; out AAddress: string): string;
    procedure ChangePrivateKey(const PrKey: string);
    function GetBlocksCount: Int64;
    function GetNewTokenFee(AAmount: Int64; ADecimals: Integer): Integer;
    function DoTokenTransfer(AAddrFrom, AAddrTo: string; AAmount: UInt64; APrKey: string): string;
    function DoTokenMigrate(AAddrFrom, AAddrTo: string; AAmount: UInt64; APrKey: string): string;
    function DoTokenStake(AAddr: string; AAmount: UInt64; APrKey: string): string;
    function DoTokenUnstake(AAddr: string; AAmount: UInt64; APrKey: string): string;
    function GetTokenBalance(AAddress: string): UInt64;
    function GetStakingBalance(AAddress: string): UInt64;
    function GetStakingReward(AAddress: string): TRewardTotalInfo;
    function GetUserLastTransactions(AAddress: string; Skip,Count: Int64): TArray<TTransactionInfo>;
    function GetLastTransactions(Skip,Count: Int64): TArray<TTransactionInfo>;
    procedure SetBlockchainSynchronized(Synchronized: Boolean);
    procedure DoHalt(const Reason: string);
    function GetStates: TAppStates;
    function GetNetStats: TNetStatistics;

    function DoValidation(const [Ref] ATxn: TMemBlock<TTxn>; out ASign: TMemBlock<TValidation>): Boolean;
    function SendTransaction(ARequest: TBytes): TBytes;

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
