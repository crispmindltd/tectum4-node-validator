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
      FBytesForSign: TBytes;
      FPubKey: T65Bytes;
    private
      FRemoteAddress: string;
      FOnConnectionChecked: TCheckConnectFunc;

      procedure DoDisconnect(const AReason: string = ''); override;
      function GetRemoteAddress: string; override;
      procedure ProcessCommand(const AIncomData: TResponseData); override;
      procedure ProcessResponse(const AResponse: TResponseData); override;
      function GetDisconnectMessage: string; override;
    public
      shortAddr: string;

      constructor Create(ASocket: TSocket; ACommandHandler: TCommandHandler;
        AOnDisconnected: TNotifyEvent; AOnConnectionChecked: TCheckConnectFunc);
      destructor Destroy; override;

      property PubKey: T65Bytes read FPubKey;
      property Status: Byte write FStatus;
      property Address: string read GetRemoteAddress;
      property IsChecked: Boolean read FIsChecked;
  end;

implementation

uses
  App.Intf;

{ TServerConnection }

constructor TServerConnection.Create(ASocket: TSocket; ACommandHandler: TCommandHandler;
  AOnDisconnected: TNotifyEvent; AOnConnectionChecked: TCheckConnectFunc);
begin
  inherited Create(ASocket, ACommandHandler, AOnDisconnected);

  FIsChecked := False;
  FRemoteAddress := Format('%s:%d', [FSocket.RemoteEndpoint.Address.Address,
    FSocket.RemoteEndpoint.Port]);
  FOnConnectionChecked := AOnConnectionChecked;
  SendRequest(CheckVersionCommandCode, TEncoding.ANSI.GetBytes(AppCore.GetAppVersion));

  Randomize;
  FBytesForSign := TEncoding.ANSI.GetBytes(THash.GetRandomString(32));
  SendRequest(InitConnectCode, FBytesForSign, BytesToHex(FBytesForSign));
  WaitForReceive(True);
end;

destructor TServerConnection.Destroy;
begin

  inherited;
end;

procedure TServerConnection.DoDisconnect(const AReason: string);
begin
  inherited;

  FOnDisconnected(Self);
end;

function TServerConnection.GetDisconnectMessage: string;
begin
  Result := Format('%s disconnected', [Address]);
  if not FDiscMsg.IsEmpty then
    Result := Format('%s: %s', [Result, FDiscMsg]);
end;

function TServerConnection.GetRemoteAddress: string;
begin
  Result := FRemoteAddress;
end;

procedure TServerConnection.ProcessCommand(const AIncomData: TResponseData);
begin
end;

procedure TServerConnection.ProcessResponse(const AResponse: TResponseData);
begin
  if not (FIsChecked or (AResponse.Code = InitConnectCode)) then
  begin
    FStatus := InitConnectErrorCode;
    raise EConnectionClosed.Create('identification error');
  end;

  case AResponse.Code of
    InitConnectCode:
      begin
        FPubKey := Copy(AResponse.Data, 0, 65);
        shortAddr := Copy(FPubKey.Address, 35);
        FRemoteAddress := Format('%s:%d:%s', [FSocket.RemoteEndpoint.Address.Address,
          FSocket.RemoteEndpoint.Port, shortAddr]);
        const Sign = Copy(AResponse.Data, 65, Length(AResponse.Data));
        const SignVerified = ECDSACheckBytesSign(FBytesForSign, Sign, FPubKey);
        if SignVerified then
        begin
          FIsChecked := FOnConnectionChecked(Self);
          if FIsChecked then
          begin
            Logs.DoLog(Format('Connection to %s checked', [Address]), CmnLvlLogs, ltNone);
            SendRequest(SuccessCode, []);
          end
          else begin
            FStatus := KeyAlreadyUsesErrorCode;
            raise EConnectionClosed.Create('key is already in use');
          end;
        end else
        begin
          FStatus := InitConnectErrorCode;
          raise EConnectionClosed.Create('init connection error');
        end;
      end;
  end;
end;

end.
