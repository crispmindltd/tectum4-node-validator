unit Net.ServerConnection;

interface

uses
  App.Exceptions,
  App.Logs,
  Blockchain.Address,
  Blockchain.Data,
  System.Classes,
  Crypto,
  System.Hash,
  Net.CommandHandler,
  Net.Connection,
  Net.Data,
  Net.Socket,
  System.SyncObjs,
  System.SysUtils,
  System.Types;

type
  TCheckConnectFunc = function(Sender: TObject): Boolean of object;

  TServerConnection = class(TConnection)
    strict private
      FBytesToSign: TBytes;
      FPubKey: T65Bytes;
    private
      FRemoteAddress: string;
      FOnConnectionChecked: TCheckConnectFunc;

      procedure DoDisconnect(const AErrorMsg: string = ''); override;
      procedure ProcessCommand(const AResponse: TResponseData); override;
      procedure ReceiveCallBack(const ASyncResult: IAsyncResult); override;
      function GetRemoteAddress: string; override;
    public
      shortAddr: string;

      constructor Create(ASocket: TSocket; ACommandHandler: TCommandHandler;
        AOnDisconnected: TNotifyEvent; AOnConnectionChecked: TCheckConnectFunc);
      destructor Destroy; override;

      property PubKey: T65Bytes read FPubKey;
      property Status: Byte write FStatus;
      property Address: string read GetRemoteAddress;
  end;

implementation

uses
  App.Intf;

{ TServerConnection }

constructor TServerConnection.Create(ASocket: TSocket; ACommandHandler: TCommandHandler;
  AOnDisconnected: TNotifyEvent; AOnConnectionChecked: TCheckConnectFunc);
begin
  inherited Create(ASocket, ACommandHandler, AOnDisconnected);

  FRemoteAddress := Format('%s:%d', [FSocket.RemoteEndpoint.Address.Address,
    FSocket.RemoteEndpoint.Port]);
  FOnConnectionChecked := AOnConnectionChecked;
  FRemoteIsAvailable := True;

  SendRequest(CheckVersionCommandCode, TEncoding.ANSI.GetBytes(AppCore.GetAppVersion));
  WaitForReceive(True);
end;

destructor TServerConnection.Destroy;
begin

  inherited;
end;

procedure TServerConnection.DoDisconnect(const AErrorMsg: string);
var
  LogStr: string;
begin
  LogStr := Format('%s disconnected', [Address]);
  if not AErrorMsg.IsEmpty then
    LogStr := Format('%s: %s', [LogStr, AErrorMsg]);

  Logs.DoLog(LogStr, AdvLvlLogs, ltNone);
  FOnDisconnected(Self);
end;

function TServerConnection.GetRemoteAddress: string;
begin
  Result := FRemoteAddress;
end;

procedure TServerConnection.ProcessCommand(const AResponse: TResponseData);
begin
  case AResponse.RequestData.Code of
    InitConnectCode:
      begin
        FPubKey := Copy(AResponse.Data, 0, 65);
        shortAddr := Copy(FPubKey.Address, 35);
        FRemoteAddress := Format('%s:%d:%s', [FSocket.RemoteEndpoint.Address.Address,
          FSocket.RemoteEndpoint.Port, shortAddr]);
        const Sign = Copy(AResponse.Data, 65, Length(AResponse.Data));
        const SignVerified = ECDSACheckBytesSign(FBytesToSign, Sign, FPubKey);
        if SignVerified then
        begin
          FConnectionChecked := FOnConnectionChecked(Self);
          if FConnectionChecked then
          begin
            WaitForReceive;
            FSocket.Send([SuccessCode]);
            Logs.DoLog(Format('Connection to %s checked', [Address]), CmnLvlLogs, ltNone);
          end else
          begin
            FStatus := KeyAlreadyUsesErrorCode;
            raise EConnectionClosed.Create('key is already in use');
          end;
        end else
        begin
          FStatus := InitConnectErrorCode;
          raise EConnectionClosed.Create('init connection error');
        end;
      end;

    CheckVersionCommandCode:
      begin
        if (Length(AResponse.Data) > 0) and (AResponse.Data[0] = SuccessCode) then
        begin
          Randomize;
          FBytesToSign := TEncoding.ANSI.GetBytes(THash.GetRandomString(32));
          SendRequest(InitConnectCode, FBytesToSign, '[bytes for signing]');
          WaitForReceive(True);
        end;
      end;
  end;
end;

procedure TServerConnection.ReceiveCallBack(const ASyncResult: IAsyncResult);
var
  IncomData: TResponseData;
  LengthBytes: array[0..3] of Byte;
  Length: Integer absolute LengthBytes;
begin
  try
    IncomData.Data := FSocket.EndReceiveBytes(ASyncResult);

    if Assigned(IncomData.Data) then
    begin
      FSocket.Receive(IncomData.RequestData.Code, 1, [TSocketFlag.WAITALL]);
      if not (IncomData.RequestData.Code in CommandsCodes) then
      begin
        FIsShuttingDown := True;
        raise EConnectionClosed.CreateFmt('unknown command(code %d) received',
          [IncomData.RequestData.Code]);
      end;

      if not (FConnectionChecked or (IncomData.RequestData.Code = ResponseCode)) then
      begin
        FIsShuttingDown := True;
        raise EConnectionClosed.Create('identification error');
      end;

      case IncomData.RequestData.Code of
        ImShuttingDownCode:
        begin
          FRemoteIsAvailable := False;
          WaitForReceive;
        end;

        UnknownCommandErrorCode:
        begin
          FIsShuttingDown := True;
          raise EConnectionClosed.Create('remote node has terminated the connection: unknown command sended');
        end

        else
          begin
            FSocket.Receive(IncomData.RequestData.ID, 8, [TSocketFlag.WAITALL]);
            FSocket.Receive(LengthBytes, 4, [TSocketFlag.WAITALL]);
            FSocket.Receive(IncomData.Data, Length, [TSocketFlag.WAITALL]);

            case IncomData.RequestData.Code of
              ResponseCode:
                WriteResponseData(IncomData)
              else begin
                WaitForReceive;
                AddIncomRequest(IncomData);
              end;
            end;
          end;
      end;
    end else
      raise EConnectionClosed.Create('');
  except
    on E:EConnectionClosed do
      DoDisconnect(E.Message);
    on E:ESocketError do
      DoDisconnect('timeout data receiving');
    on E:Exception do
      DoDisconnect('Server receiveCallBack disconnect: ' + E.Message);
  end;
end;

end.
