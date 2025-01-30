unit App.Intf;

interface

uses
  Blockchain.Data,
  Blockchain.Txn,
  Blockchain.Validation,
  BlockChain.Reward,
  Net.Server,
  Classes,
  SysUtils;

type
  IUI = interface
    procedure Run;
    procedure DoMessage(const AMessage: string);
    procedure DoTerminate;
    procedure ShowVersionDidNotMatch;
    procedure NotifyNewTETBlocks;
  end;

  IAppCore = interface
    procedure Run;
    procedure Stop;
    procedure Reset;
    function GetPrKey: string;
    function GetPubKey: string;
    function GetAddress: string;
    function GetNodeServer: TNodeServer;
    function GetNeedAutoUpdate: Boolean;

    procedure GenNewKeys(var ASeedPhrase, APrKey, APubKey, AAddress: string);
    function DoRecoverKeys(ASeed: string; out APubKey: string;
      out APrKey: string; out AAddress: string): string;
    function GetBlocksCount: Int64;
    function GetNewTokenFee(AAmount: Int64; ADecimals: Integer): Integer;
    function DoTokenTransfer(AAddrFrom, AAddrTo: string; AAmount: UInt64; APrKey: string): string;
    function DoTokenMigrate(AAddrFrom, AAddrTo: string; AAmount: UInt64; APrKey: string): string;
    function DoTokenStake(AAddr: string; AAmount: UInt64; APrKey: string): string;
    function DoTokenUnstake(AAddr: string; AAmount: UInt64; APrKey: string): string;
    function GetTokenBalance(AAddress: string): UInt64;
    function GetStakingBalance(AAddress: string): UInt64;
    function GetStakingReward(StartIndex: UInt64; AAddress: string): TRewardTotalInfo;
    function GetUserLastTransactions(AAddress: string; Skip,Count: Int64): TArray<TTransactionInfo>;
    function GetLastTransactions(Skip,Count: Int64): TArray<TTransactionInfo>;
    function TrySaveKeysToFile(APrivateKey: string): Boolean;
    procedure ChangePrivateKey(const PrKey: string);

    function DoValidation(const [Ref] ATxn: TMemBlock<TTxn>;
      out ASign: TMemBlock<TValidation>): Boolean;
    function DoRequestToArchivator(const ACommandCode: Byte; ARequest: TBytes): TBytes;

    function GetAppVersion: string;
    function GetAppVersionText: string;
    procedure StartUpdate;
    procedure WaitForStop;

    property PrKey: string read GetPrKey;
    property PubKey: string read GetPubKey;
    property Address: string read GetAddress;
    property NodeServer: TNodeServer read GetNodeServer;
    property NeedAutoUpdate: Boolean read GetNeedAutoUpdate;
  end;

var
  AppCore: IAppCore = nil;
  UI: IUI = nil;

implementation

end.
