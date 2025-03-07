unit Net.Intf;

interface

uses
  System.SysUtils,
  Blockchain.Address,
  Net.Event;

type
{$SCOPEDENUMS ON}

  TConnectionState = (None, Connected, Passed, Failed);

  IConnection = interface
    function DoRequest(CommandCode: Byte; const Body: TBytes): TBytes;
    procedure SendRequest(CommandCode: Byte; Body: TBytes; Wait: IWait = nil;
      CallbackProc: TProc<TBytes,Boolean> = nil);
    function GetReceiverName: string;
    function GetState: TConnectionState;
    property ReceiverName: string read GetReceiverName;
    property State: TConnectionState read GetState;
  end;

  INetCore = interface
    function ServerClientExists(const PubKey: TPublicKey): Boolean;
    function SendRequestToAnyServer(Command: Byte; Body: TBytes): TBytes;
    function GetValidators(const IgnorePubKey: TPublicKey): TArray<IConnection>;
    function GetAnyServer(Required: Boolean = True): IConnection;
  end;

const
  ConnectionStateNames: array[TConnectionState] of string = ('none', 'connected', 'passed', 'failed');

implementation

end.
