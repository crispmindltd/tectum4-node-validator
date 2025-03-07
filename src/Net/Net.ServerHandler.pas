unit Net.ServerHandler;

interface

uses
  System.IOUtils,
  System.SysUtils,
  System.Generics.Collections,
  System.SyncObjs,
  System.Threading,
  System.DateUtils,
  System.Diagnostics,
  System.Hash,
  Blockchain.Utils,
  Blockchain.Data,
  Blockchain.Reward,
  Blockchain.Txn,
  Blockchain.Validation,
  Blockchain.Address,
  BlockChain.DataCache,
  System.Net.Socket,
  Crypto,
  App.Intf,
  App.Types,
  Net.Types,
  Net.Data,
  Net.Intf,
  Net.SocketA,
  Net.Peer,
  Net.Event,
  Net.CustomHandler;

type
  TServerHandler = class(TCustomHandler)
  private
    FBytesForSign: TBytes;
    FPubKey: TPublicKey;
    FShortAddress: string;
    function GetBlocks<T>(const AFileName: string; const Data: TBytes): TBytes;
  protected
    procedure DoReceived(const Request: TRequest); override;
  public
    constructor Create(Client: TServerClient; NetCore: INetCore);
    destructor Destroy; override;
    procedure Start;
    procedure Ping;
    property PubKey: TPublicKey read FPubKey;
    property ShortAddress: string read FShortAddress;
  end;

implementation

const
  SReceivedData = 'Received %s data %d bytes';

constructor TServerHandler.Create(Client: TServerClient; NetCore: INetCore);
begin
  inherited Create(Client, NetCore);
  FReceiverName := Client.RemoteAddress;
end;

destructor TServerHandler.Destroy;
begin
  Client.Free;
  inherited;
end;

procedure TServerHandler.Start;
begin

  AddQueue(procedure
  begin
    if PubKey.IsEmpty then
    begin
      OnLog('Close connection (key verification time expired) ' + Client.Name, INFO);
      Client.Close;
    end;
  end, 5000);

  OnLog('Send version and sample for signature to ' + Client.Name, INFO);

  SendRequest(CheckVersionCommandCode, BytesOf(AppCore.GetAppVersion));
  Randomize;
  FBytesForSign := BytesOf(THash.GetRandomString(32));
  SendRequest(InitConnectCode, FBytesForSign);

end;

procedure TServerHandler.Ping;
begin

  var FPinged := False;

  AddQueue(procedure
  begin
    if not FPinged then
    begin
      OnLog('Close connection (ping time expired) ' + ReceiverName, INFO);
      Client.Close;
    end;
  end, 5000);

  SendRequest(PingCommandCode, nil, nil, procedure(Data: TBytes; Success: Boolean)
  begin
    FPinged := True;
  end);

end;

function TServerHandler.GetBlocks<T>(const AFileName: string; const Data: TBytes): TBytes;
const
  MaxBlocks = 1000;
begin
  Assert(Length(Data) > 0);
  const BlocksFrom = PUInt64(@Data[0])^;

  Assert(Length(Data) = (8 + SizeOf(T32Bytes)));
  const ClientLastHash:T32Bytes = Copy(Data, 8, SizeOf(T32Bytes));

  const RecordsCount = TMemBlock<T>.RecordsCount(AFilename);

  Result := [BlockchainCorruptedErrorCode];

  const shortFilename = TPath.GetFileNameWithoutExtension(AFileName);

  if RecordsCount < BlocksFrom then begin
    OnLog(ReceiverName  + ' (RecordsCount:' +RecordsCount.ToString + ' < BlocksFrom:' + BlocksFrom.ToString +') ! ' + shortFilename, TLevel.ERROR);
    OnLog(ReceiverName  + ' has corrupted blockchain ! ' + shortFilename, TLevel.ERROR);
    Exit;
  end;

  if BlocksFrom > 0 then begin
    const LBlock = TMemBlock<T>.ReadFromFile(AFileName, BlocksFrom - 1);
    const LHash = T32Bytes(LBlock.Hash());

    if ClientLastHash <> LHash then begin
      OnLog(ReceiverName  + ' (ClientLastHash:' + ClientLastHash + ' <> LHash:' + LHash + ') ! ' + shortFilename, TLevel.ERROR);
      OnLog(ReceiverName  + ' has corrupted blockchain ! ' + shortFilename, TLevel.ERROR);
      Exit;
    end;
  end;
  Result := [SuccessCode];

  if RecordsCount > BlocksFrom then
    Result := Result + TMemBlock<T>.ByteArrayFromFile(AFilename, BlocksFrom, MaxBlocks);
end;

procedure TServerHandler.DoReceived(const Request: TRequest);
begin
  case Request.CommandCode of
    ResponseCode:
      begin
        var Header: TRequestTask;
        if GetRequestFor(Request.Id, Request.Body, Header) then
          case Header.CommandCode of
            InitConnectCode:
            try
              const PubKey: TPublicKey = Copy(Request.Body, 0, SizeOf(TPublicKey));
              const Sign = Copy(Request.Body, SizeOf(TPublicKey));

              if ECDSACheckBytesSign(FBytesForSign, Sign, PubKey) then
                if FNetCore.ServerClientExists(PubKey) then
                  SendResponse(KeyAlreadyUsesErrorCode, BytesOf('Key already in use'))
                else begin
                  FState := TConnectionState.Passed;
                  FPubKey := PubKey;
                  FShortAddress := PubKey.ShortAddress;
                  OnLog('Connection ' + Client.Name + ' passed', INFO);
                  SendResponse(SuccessCode, BytesOf('Passed'));
                end
              else
                raise Exception.Create('Incorrect sign');

            except on E: Exception do
              SendResponse(InitConnectErrorCode, BytesOf(E.Message));
            end;
          end; // case
      end;

    InfoCommandCode:
      SendResponse(Request.Id, ResponseCode, TCode.B(TMemBlock<TValidation>.RecordsCount(TValidation.FileName)));

    GetRewardsCommandCode:
      SendResponse(Request.Id, ResponseCode, GetBlocks<TReward>(TReward.Filename, Request.Body));

    GetTxnsCommandCode:
      SendResponse(Request.Id, ResponseCode, GetBlocks<TTxn>(TTxn.Filename, Request.Body));

    GetValidationsCommandCode:
      SendResponse(Request.Id, ResponseCode, GetBlocks<TValidation>(TValidation.Filename, Request.Body));

    GetAddressesCommandCode:
      SendResponse(Request.Id, ResponseCode, GetBlocks<TAccount>(TAccount.Filename, Request.Body));

    else // other commands
      SendResponse(Request.Id, ResponseCode, [ErrorCode] + BytesOf('Unsupported'));

  end; // case
end;

end.
