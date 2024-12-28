unit Net.ServerConnection;

interface

uses
  App.Logs,
  Blockchain.Address,
  Blockchain.Data,
  Classes,
  Crypto,
  Hash,
  Net.CommandHandler,
  Net.Connection,
  Net.Data,
  Net.Socket,
  SyncObjs,
  SysUtils,
  Types;

type
  TServerConnection = class(TConnection)
    strict private
      FPubKey: T65Bytes;
    private
      FStatus: Byte;
      FOnConnectionChecked: TNotifyEvent;

      procedure DoDisconnect; override;
      procedure ProcessCommand(const AResponse: TResponseData); override;
      procedure ReceiveCallBack(const ASyncResult: IAsyncResult); override;
    public
      constructor Create(ASocket: TSocket; ACommandHandler: TCommandHandler;
        AOnDisconnected: TNotifyEvent; AOnConnectionChecked: TNotifyEvent);
      destructor Destroy; override;

      procedure Stop; override;

      property PubKey: T65Bytes read FPubKey;
      property Status: Byte write FStatus;
  end;

implementation

{ TServerConnection }

constructor TServerConnection.Create(ASocket: TSocket; ACommandHandler: TCommandHandler;
  AOnDisconnected: TNotifyEvent; AOnConnectionChecked: TNotifyEvent);
begin
  inherited Create(ASocket, ACommandHandler, AOnDisconnected);

  FStatus := 0;
  FOnConnectionChecked := AOnConnectionChecked;

  BeginReceive;
  Randomize;

  try
    const Answer = DoRequest(CheckVersionCommandCode, []{, 500});
    const ToSign = TEncoding.ANSI.GetBytes(THash.GetRandomString(32));
    try
      const KeyAndSign = DoRequest(InitConnectCode, ToSign{, 500});
      FPubKey := Copy(KeyAndSign, 0, 65);
      const Sign = Copy(KeyAndSign, 65, Length(KeyAndSign));
      FConnectionChecked := ECDSACheckBytesSign(ToSign, Sign, FPubKey);
    except
      FConnectionChecked := False;
    end;
  finally
    if FConnectionChecked then
    begin
      FOnConnectionChecked(Self);
      FSocket.Send([PingCode]);
    end else
      FOnDisconnected(Self);
  end;
end;

destructor TServerConnection.Destroy;
begin
  if FStatus <> 0 then
    FSocket.Send([KeyAlreadyUsesErrorCode]);

  inherited;
end;

procedure TServerConnection.DoDisconnect;
begin
  FOnDisconnected(Self);
end;

procedure TServerConnection.ProcessCommand(const AResponse: TResponseData);
begin

end;

procedure TServerConnection.ReceiveCallBack(const ASyncResult: IAsyncResult);
var
  IncomData: TResponseData;
  LengthBytes: array[0..3] of Byte;
  Length: Integer absolute LengthBytes;
begin
  if FIsShuttingDown then
    exit;
  try
    IncomData.Data := FSocket.EndReceiveBytes(ASyncResult);
    if Assigned(IncomData.Data) then
    begin
      FSocket.Receive(IncomData.RequestData.Code, 1, [TSocketFlag.WAITALL]);
      if not FConnectionChecked and (IncomData.RequestData.Code <> ResponseCode) then
        raise ESocketError.Create('');

      case IncomData.RequestData.Code of
        PingCode:
          begin
            FSocket.BeginReceive(ReceiveCallBack, -1, [TSocketFlag.PEEK]);
            FSocket.Send([PongCode]);
          end;

        else
          begin
//            IncomData._PubKey := Self.FPubKey;

            FSocket.Receive(IncomData.RequestData.ID, 8, [TSocketFlag.WAITALL]);
            FSocket.Receive(LengthBytes, 4, [TSocketFlag.WAITALL]);
            FSocket.Receive(IncomData.Data, Length, [TSocketFlag.WAITALL]);
            FSocket.BeginReceive(ReceiveCallBack, -1, [TSocketFlag.PEEK]);

            if IncomData.RequestData.Code in [ResponseCode, ResponseSyncCode] then
              WriteResponseData(IncomData, IncomData.RequestData.Code = ResponseCode)
            else
              AddIncomRequest(IncomData);
          end;
      end;
    end else
      raise ESocketError.Create('');
  except
    on E:ESocketError do
      DoDisconnect;
  end;
end;

procedure TServerConnection.Stop;
begin
  FSocket.Send([ImShuttingDownCode]);

  inherited;
end;

end.
