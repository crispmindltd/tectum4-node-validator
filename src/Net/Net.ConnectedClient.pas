unit Net.ConnectedClient;

interface

uses
  Blockchain.Data,
  Blockchain.Txn,
  Blockchain.Validation,
  Blockchain.Reward,
  Blockchain.Address,
  App.Intf,
  App.Logs,
  App.Updater,
  System.Generics.Collections,
  Classes,
  Crypto,
  Net.Data,
  Net.Socket,
  SysUtils;

type
  TConnectedClient = class(TThread)
  const
    RECEIVE_DATA_TIMEOUT = 5000;
  private
    function GetAddress: string;
  protected

    FSocket: TSocket;
    FID: string;
    FIsActual: Boolean;
    FOnDoTerminate: TNotifyEvent;
    FLastCommandCode: Byte;
    procedure Execute; override;
    procedure DoTerminate; override;

    procedure Disconnect;
    procedure ReceiveRequest;
    procedure SendVersionInfo;
    function ReceiveDataInSocket: TBytes;
    function Receive: UInt64;
    procedure ProcessGetTxnCommand;
    procedure ProcessGetAddressCommand;
    procedure ProcessGetValidationCommand;
    procedure ProcessGetRewardCommand;
    procedure ProcessComand<T>(const AFilename:string);
  public
    constructor Create(ASocket: TSocket);
    destructor Destroy; override;

    property Socket: TSocket read FSocket;
    property Address: string read GetAddress;
    property ID: string read FID;
    property IsActual: Boolean read FIsActual;
    property OnDoTerminate: TNotifyEvent write FOnDoTerminate;
  end;

  TCommandProcessor = TProc<TConnectedClient>;

var
  CustomSocketCommands: TDictionary<Byte, TCommandProcessor>;

implementation

{ TConnectedClient }

constructor TConnectedClient.Create(ASocket: TSocket);
begin
  inherited Create;

  FSocket := ASocket;
  FreeOnterminate := True;
  FIsActual := True;
  Socket.ReceiveTimeout := RECEIVE_DATA_TIMEOUT;
  FID := 'C' + Socket.Handle.ToString;

  // UI.DoMessage(Format('%s connected, ID = %s',[GetAddress, ID]));
  Logs.DoLog(Format('%s connected, ID = %s', [GetAddress, ID]), INCOM);
end;

destructor TConnectedClient.Destroy;
begin
  Disconnect;
  Socket.Free;

  inherited;
end;

procedure TConnectedClient.Disconnect;
begin
  if TSocketState.Connected in Socket.State then
{$IFDEF MSWINDOWS}
    Socket.Close(True);
{$ELSE IFDEF LINUX}
    Socket.Close;
{$ENDIF}
end;

procedure TConnectedClient.DoTerminate;
begin
  inherited;

  FOnDoTerminate(Self);
end;

procedure TConnectedClient.Execute;
begin
  inherited;

  try
    repeat
      ReceiveRequest;
    until Terminated or not FIsActual;
  except
    on E: ESocketError do begin
      // UI.DoMessage(Format('%s unexpectedly disconnected', [ID]));
      Logs.DoLog(Format('%s unexpectedly disconnected', [ID]), OUTGO);
      FIsActual := False;
    end;
  end;
end;

function TConnectedClient.GetAddress: string;
begin
  Result := Format('%s:%d', [Socket.Endpoint.Address.Address, Socket.Endpoint.Port]);
end;

procedure TConnectedClient.ProcessComand<T>(const AFilename:string);
const
  MaxBlocks = 100;
begin
  const BlocksFrom = Receive;
  var AmountBytes: Integer := 0;
  if TMemBlock<T>.RecordsCount(AFilename) <= BlocksFrom then begin
    Socket.Send(AmountBytes, 4);
    Exit;
  end;

  const BytesToSend = TMemBlock<T>.ByteArrayFromFile(AFilename, BlocksFrom, MaxBlocks);
  AmountBytes := Length(BytesToSend);
  Socket.Send(AmountBytes, 4);
  Socket.Send(BytesToSend);
end;

procedure TConnectedClient.ProcessGetAddressCommand;
begin
 ProcessComand<TAccount>(TAccount.Filename);
end;

procedure TConnectedClient.ProcessGetRewardCommand;
begin
 ProcessComand<TReward>(TReward.Filename);
end;

procedure TConnectedClient.ProcessGetTxnCommand;
begin
 ProcessComand<TTxn>(TTxn.Filename);
end;

procedure TConnectedClient.ProcessGetValidationCommand;
begin
 ProcessComand<TValidation>(TValidation.FileName);
end;

function TConnectedClient.Receive: UInt64;
begin
  Socket.Receive(Result, SizeOf(UInt64), [TSocketFlag.WAITALL]);
end;

function TConnectedClient.ReceiveDataInSocket: TBytes;
var
  IncomCount: Integer;
begin
  Socket.Receive(IncomCount, 4, [TSocketFlag.WAITALL]);
  SetLength(Result, IncomCount);
  Socket.Receive(Result, IncomCount, [TSocketFlag.WAITALL]);
end;

procedure TConnectedClient.ReceiveRequest;
begin
  Socket.Receive(FLastCommandCode, 0, 1, [TSocketFlag.WAITALL]);
  var CustomCommandProcessor: TCommandProcessor := nil;
  var IsCommandFound: Boolean := False;

  TMonitor.Enter(CustomSocketCommands);
  try
    IsCommandFound := CustomSocketCommands.TryGetValue(FLastCommandCode, CustomCommandProcessor);
  finally
    TMonitor.Exit(CustomSocketCommands);
  end;

  if IsCommandFound then begin
    try
      CustomCommandProcessor(Self);
      Exit;
    except on E:Exception do
      Logs.DoLog(Format('%s command (%d) process raised an exception: %s', [ID, FLastCommandCode, E.Message]), OUTGO);
    end;
  end;
  // UI.DoMessage(Format('%s disconnected(unknown command)', [ID]));
  Logs.DoLog(Format('%s disconnected(unknown command)', [ID]), OUTGO);
  FIsActual := False;
end;

procedure TConnectedClient.SendVersionInfo;
var
  LinkBytes: TBytes;
begin
  FSocket.Send(Updater.CurVersionAsBytes, 0, 2);
  FSocket.Send(Updater.Status, 0, 1);
  LinkBytes := TEncoding.ANSI.GetBytes(Updater.LinkToExe);
  const BytesNumber = Length(LinkBytes);
  FSocket.Send(BytesOf(@BytesNumber, 4), 0, 4);
  FSocket.Send(LinkBytes, 0, BytesNumber);
end;

initialization

CustomSocketCommands := TDictionary<Byte, TCommandProcessor>.Create;

TMonitor.Enter(CustomSocketCommands);
try
  CustomSocketCommands.Add(DisconnectingCode,
    procedure(Sender: TConnectedClient)
    begin
      Sender.FIsActual := False;
      // UI.DoMessage(Format('%s disconnected', [Sender.ID]));
      Logs.DoLog(Format('%s disconnected', [Sender.ID]), OUTGO);
    end);

  CustomSocketCommands.Add(PingCommandCode,
    procedure(Sender: TConnectedClient)
    begin
      Sender.Socket.Send([SuccessCode], 0, 1);
    end);

  CustomSocketCommands.Add(CheckVersionCommandCode,
    procedure(Sender: TConnectedClient)
    begin
      Sender.SendVersionInfo;
    end);

  CustomSocketCommands.Add(GetTxnsCommandCode,
    procedure(Sender: TConnectedClient)
    begin
      Sender.ProcessGetTxnCommand;
    end);

  CustomSocketCommands.Add(GetAddressesCommandCode,
    procedure(Sender: TConnectedClient)
    begin
      Sender.ProcessGetAddressCommand;
    end);

  CustomSocketCommands.Add(GetValidationsCommandCode,
    procedure(Sender: TConnectedClient)
    begin
      Sender.ProcessGetValidationCommand;
    end);

  CustomSocketCommands.Add(GetRewardsCommandCode,
    procedure(Sender: TConnectedClient)
    begin
      Sender.ProcessGetRewardCommand;
    end);

finally
  TMonitor.Exit(CustomSocketCommands);
end;

finalization

CustomSocketCommands.Free;

end.
