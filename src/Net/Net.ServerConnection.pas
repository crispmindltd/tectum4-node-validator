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
  TCheckConnectFunc = function(Sender: TObject): Boolean of object;

  TServerConnection = class(TConnection)
    strict private
      FBytesToSign: TBytes;
      FPubKey: T65Bytes;
    private
      FStatus: Byte;
      FOnConnectionChecked: TCheckConnectFunc;

      procedure DoDisconnect; override;
      procedure ProcessCommand(const AResponse: TResponseData); override;
      procedure ReceiveCallBack(const ASyncResult: IAsyncResult); override;
    public
      constructor Create(ASocket: TSocket; ACommandHandler: TCommandHandler;
        AOnDisconnected: TNotifyEvent; AOnConnectionChecked: TCheckConnectFunc);
      destructor Destroy; override;

      procedure Stop; override;

      property PubKey: T65Bytes read FPubKey;
      property Status: Byte write FStatus;
  end;

implementation

uses
  App.Intf;

{ TServerConnection }

constructor TServerConnection.Create(ASocket: TSocket; ACommandHandler: TCommandHandler;
  AOnDisconnected: TNotifyEvent; AOnConnectionChecked: TCheckConnectFunc);
begin
  inherited Create(ASocket, ACommandHandler, AOnDisconnected);

  FStatus := 0;
  FOnConnectionChecked := AOnConnectionChecked;

  Randomize;
  FBytesToSign := TEncoding.ANSI.GetBytes(THash.GetRandomString(32));
  SendRequest(InitConnectCode, FBytesToSign, False);
  BeginReceive;
end;

destructor TServerConnection.Destroy;
begin
  if FStatus <> 0 then
    FSocket.Send([FStatus]);

  inherited;
end;

procedure TServerConnection.DoDisconnect;
begin
  FOnDisconnected(Self);
end;

procedure TServerConnection.ProcessCommand(const AResponse: TResponseData);
begin
  case AResponse.RequestData.Code of
    InitConnectCode:
      begin
        FPubKey := Copy(AResponse.Data, 0, 65);
        const Sign = Copy(AResponse.Data, 65, Length(AResponse.Data));
        FConnectionChecked := ECDSACheckBytesSign(FBytesToSign, Sign, FPubKey);
        if FConnectionChecked then
        begin
          if FOnConnectionChecked(Self) then
            FSocket.Send([SuccessCode])
          else begin
            FStatus := KeyAlreadyUsesErrorCode;
            DoDisconnect;
          end;
        end else
        begin
          FStatus := InitConnectErrorCode;
          DoDisconnect;
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

      if not (FConnectionChecked or (IncomData.RequestData.Code = ResponseCode)) then
          raise ESocketError.Create('Identification error');

      case IncomData.RequestData.Code of
        PingCode:
          begin
            if not FIsShuttingDown then
              BeginReceive;
            FSocket.Send([PongCode]);
          end;

        else
          begin
            FSocket.Receive(IncomData.RequestData.ID, 8, [TSocketFlag.WAITALL]);
            FSocket.Receive(LengthBytes, 4, [TSocketFlag.WAITALL]);
            FSocket.Receive(IncomData.Data, Length, [TSocketFlag.WAITALL]);
            if not FIsShuttingDown then
              BeginReceive;

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
    begin
//      if not E.Message.IsEmpty then
//        UI.DoMessage(Format('%s. Disconnect...', [E.Message]));
      DoDisconnect;
    end;
  end;
end;

procedure TServerConnection.Stop;
begin
  inherited;

  FSocket.Send([ImShuttingDownCode]);
  if IsReadyToStop then
    DoDisconnect;
end;

end.
