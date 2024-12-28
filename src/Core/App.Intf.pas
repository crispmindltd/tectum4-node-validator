unit App.Intf;

interface

uses
  Blockchain.Data,
  Blockchain.Txn,
  Blockchain.Validation,
  Net.Server,
  Classes,
  SysUtils;

type
  IUI = interface
    procedure Run;
    procedure DoMessage(const AMessage: string);
    procedure DoTerminate;
    procedure ShowVersionDidNotMatch;
  end;

  IAppCore = interface
    procedure Run;
    procedure Stop;
    function GetPrKey: string;
    function GetPubKey: string;
    function GetAddress: string;
    function GetNodeServer: TNodeServer;
    function GetNeedAutoUpdate: Boolean;

    procedure GenNewKeys(var ASeedPhrase, APrKey, APubKey, AAddress: string);
    function DoRecoverKeys(ASeed: string; out APubKey: string;
      out APrKey: string; out AAddress: string): string;
    function GetNewTokenFee(AAmount: Int64; ADecimals: Integer): Integer;
    function DoTokenTransfer(AAddrFrom, AAddrTo: string; AAmount: UInt64;
      APrKey, APubKey: string): string;
    function DoTokenStake(AAddr: string; AAmount: UInt64; APrKey, APubKey: string): string;
    function GetTokenBalance(AAddress: string; out AFloatSize: Byte): UInt64;
    function TrySaveKeysToFile(APrivateKey: string): Boolean;

    function DoValidation(const ATransBytes: TBytes; out ASign: string): Boolean; overload;
    function DoValidation(const [Ref] ATxn: TMemBlock<TTxn>;
      out ASign: TMemBlock<TValidation>): Boolean; overload;

    function DoRequestToArchivator(const ACommandCode: Byte; ARequest: TBytes): TBytes;

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
