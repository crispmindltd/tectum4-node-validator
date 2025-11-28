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
  System.Net.Socket,
  System.Hash,
  Crypto,
  Crypto.EthereumSigner,
  Crypto.Types,
  App.Intf,
  App.Types,
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
  protected
    procedure DoReceived(const Request: TRequest); override;
  public
    constructor Create(Client: TServerConnection; NetCore: INetCore);
    destructor Destroy; override;
    procedure Start;
    procedure Ping;
    property PubKey: TPublicKey read FPubKey;
    property ShortAddress: string read FShortAddress;
  end;

implementation

const
  SReceivedValidatedTransactionsData = 'Received validated transactions data from %s (%d bytes)';
  SReceivedTransactionsData = 'Received transactions data from %s (%d bytes)';
  SSendBlockchainData = 'Send blockchain data to %s (%d bytes)';

constructor TServerHandler.Create(Client: TServerConnection; NetCore: INetCore);
begin
  inherited Create(Client, NetCore);
  FReceiverName := Client.Name;
end;

destructor TServerHandler.Destroy;
begin
  Client.OnDisconnect := nil;
  Client.Free;
  inherited;
end;

procedure TServerHandler.Start;
begin
  AddQueue(procedure begin
    if PubKey.IsEmpty then begin
      OnLog('Close connection (key verification time expired) ' + ReceiverName, INFO);
      Client.Close;
    end;
  end
  , 5000);

  OnLog('Send version and sample for signature to ' + ReceiverName, INFO);

  SendRequest(ptCheckVersion, BytesOf(AppCore.GetAppVersion));
  Randomize;
  FBytesForSign := BytesOf(THash.GetRandomString(32));
  SendRequest(ptInitConnect, FBytesForSign);
end;

procedure TServerHandler.Ping;
begin
  var FPinged := False;

  AddQueue(procedure begin
    if not FPinged then begin
      OnLog('Close connection (ping time expired) ' + ReceiverName, INFO);
      Client.Close;
    end;
  end
  , 5000);

  SendRequest(ptPing, nil, nil,
    procedure(Data: TBytes; Success: Boolean) begin
      FPinged := True;
    end
  );
end;

procedure TServerHandler.DoReceived(const Request: TRequest);
begin
  case Request.PacketType of
    ptTransaction:
    try
      OnLog(Format(SReceivedTransactionsData, [ReceiverName, Length(Request.Body)]), INFO);
      const ValidatedData = AppCore.DoValidation(Request.Body);

      FNetCore.GetAnyServer.SendRequest(
        ptValidTransaction,
        ValidatedData,
        nil,
        procedure (Data: TBytes; isSuccess: Boolean) begin
          SendResponse(Request.Id, ptResponse, [Byte(ResultCode[isSuccess])] + Data);
        end
      );
    except on E: Exception do begin
        OnLog('Can not validate: ' + E.Message, INFO);
        SendResponse(Request.Id, ptResponse, [Byte(ptError)] + BytesOf('arch.' + E.Message));
      end;
    end;

    ptGetRawData: begin
      if AppCore = nil then Exit;
      var RecordsCount := AppCore.RecordsCount;
      if Length(Request.Body) >= SizeOf(RecordsCount) then // check data size for UInt64
        if RecordsCount > TCode.ValueOf<UInt64>(Request.Body) then begin
          var RawData := AppCore.ReadRawData(TCode.ValueOf<UInt64>(Request.Body));
          OnLog(Format(SSendBlockchainData, [ReceiverName, Length(RawData)]), INFO);
          SendResponse(ptRawData, RawData);
        end else
          SendResponse(ptRawData, nil);
    end;

    ptResponse: begin
      var Source: TRequestTask;
      if GetRequestFor(Request.Id, Request.Body, Source) then
        case Source.PacketType of
          ptInitConnect:
          try
            const PubKey: TPublicKey = Copy(Request.Body, 0, SizeOf(TPublicKey));
            const Sign = Copy(Request.Body, SizeOf(TPublicKey));

            var addr: TBytes;
            if TryRecoverAddress(FBytesForSign, Sign, addr) then
              if FNetCore.ServerConnectionExists(PubKey) then
                SendResponse(ptKeyAlreadyUsed, BytesOf('Key already in use'))
              else begin
                FState := TConnectionState.Passed;
                FPubKey := PubKey;
                FShortAddress := PubKey.Address.ShortAddress;
                FReceiverName := Client.Name + '/' + ShortAddress;
                OnLog('Connection ' + ReceiverName + ' passed', INFO);
                SendResponse(ptSuccess, BytesOf('Passed'));
              end
            else
              raise Exception.Create('Incorrect sign');

          except on E: Exception do
            SendResponse(ptInitConnectError, BytesOf(E.Message));
          end;
        end; // case
    end;

    ptInfo:
      SendResponse(Request.Id, ptResponse, TCode.BytesOf(AppCore.RecordsCount));

    else // other commands
      SendResponse(Request.Id, ptResponse, [Byte(ptError)] + BytesOf('Unsupported'));
  end; // case
end;

end.
