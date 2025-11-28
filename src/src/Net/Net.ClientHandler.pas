unit Net.ClientHandler;

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
  App.Types,
  App.Intf,
  Crypto.EthereumSigner,
  Net.Intf,
  Net.SocketA,
  Net.Event,
  Net.CustomHandler,
  Net.Data;

type
  TClientHandler = class(TCustomHandler)
  private
    FSynchronized: Boolean;
    FSyncCount: UInt64;
    FSyncRequestCount: UInt64;
    class var SyncHandler: TClientHandler; // singleton
    procedure SendSynchronizeBlockchain;
    function IsSync: Boolean;
    procedure SetSynchronized(Value: Boolean);
    procedure DoConnectedClient(Client: TClientConnection);
    procedure DoDisconnectedClient(Client: TConnection);
  protected
    procedure Reset;
    procedure DoReceived(const Request: TRequest); override;
  public
    constructor Create(Client: TClientConnection; NetCore: INetCore);
  end;

implementation

uses
  Crypto;

const
  SServerApprovedConnection = 'Server %s approved the connection: %s';
  SServerVersion = 'Server %s is version %s';
  SReceivedBlockchainData = 'Received blockchain data from %s (%d bytes)';

constructor TClientHandler.Create(Client: TClientConnection; NetCore: INetCore);
begin
  inherited Create(Client, NetCore);
  Client.OnConnected := DoConnectedClient;
  Client.OnDisconnect := DoDisconnectedClient;
  FReceiverName := Client.Address;
  Reset;
end;

procedure TClientHandler.Reset;
begin
  FState := TConnectionState.None;
  FRequests := nil;
  FData := nil;
  FQueue := nil;
  FSynchronized := False;
end;

function TClientHandler.IsSync: Boolean;
begin
  Result := SyncHandler = Self;
end;

procedure TClientHandler.SetSynchronized(Value: Boolean);
begin
  if FSynchronized <> Value then begin
    FSynchronized := Value;
    if FSynchronized then
      OnLog('Blockchain synchronized from ' + ReceiverName, INFO);
    if Assigned(AppCore) then
      AppCore.SetBlockchainSynchronized(FSynchronized);
  end;
end;

procedure TClientHandler.SendSynchronizeBlockchain;
begin
  if IsSync and Assigned(AppCore) then begin
    FSyncRequestCount := AppCore.RecordsCount;
    SendResponse(ptGetRawData, TCode.BytesOf(FSyncRequestCount));
  end;
end;

procedure TClientHandler.DoReceived(const Request: TRequest);
begin
  case Request.PacketType of
    ptCheckVersion: begin
      var Version := StringOf(Request.Body);
      OnLog(Format(SServerVersion, [ReceiverName, Version]), INFO);
      if Assigned(AppCore) and (AppCore.GetAppVersion <> Version) then
        AppCore.StartUpdate;
    end;

    ptInitConnect: begin
      OnLog('Send signed received sample to ' + ReceiverName, INFO);
      if Assigned(AppCore) then
        SendResponse(Request.ID, ptResponse, HexToBytes(AppCore.PubKey) +
        SignWithKey(Request.Body, HexToBytes(AppCore.PrKey)));
    end;

    ptSuccess: begin
      OnLog(Format(SServerApprovedConnection, [ReceiverName, StringOf(Request.Body)]), INFO);
      FState := TConnectionState.Passed;
      if not Assigned(SyncHandler) then begin
        SyncHandler := Self;
        OnLog('Send count request for synchronization to ' + ReceiverName, INFO);
        SendRequest(ptInfo, nil);
        OnLog('Send synchronize blockchain request to ' + ReceiverName, INFO);
        SendSynchronizeBlockchain;
      end;
    end;

    ptInitConnectError: begin
      OnLog('InitConnectError: ' + StringOf(Request.Body), ERROR);
      FState := TConnectionState.Failed;
      Client.Disconnect;
      AppCore.DoHalt(StringOf(Request.Body));
    end;

    ptKeyAlreadyUsed: begin
      OnLog('KeyAlreadyUsesError: ' + StringOf(Request.Body), ERROR);
      FState := TConnectionState.Failed;
      Client.Disconnect;
      AppCore.DoHalt(StringOf(Request.Body));
    end;

    ptPing: begin
      OnLog('Ping ' + ReceiverName, INFO);
      SendResponse(Request.Id, ptResponse);
    end;

    ptRawData:
    if IsSync then
      if Assigned(AppCore) then begin
        if FSyncRequestCount = AppCore.RecordsCount then // number of records has not changed since the blockchain data was requested
          if Length(Request.Body) = 0 then
            SetSynchronized(True)
          else begin
            OnLog(Format(SReceivedBlockchainData,[ReceiverName, Length(Request.Body)]), INFO);
            SetSynchronized(False);
            AppCore.WriteRawData(Request.Body);
          end
        else
          OnLog('Blockchain data ignored', INFO);
        AddQueue(SendSynchronizeBlockchain, 500);
      end;

    ptResponse: begin
      var Source: TRequestTask;
      if GetRequestFor(Request.ID, Request.Body, Source) then
        if Source.PacketType = ptInfo then
          if Length(Request.Body) >= SizeOf(FSyncCount) then
            FSyncCount := TCode.ValueOf<UInt64>(Request.Body);
    end;
  end; // case
end;

procedure TClientHandler.DoConnectedClient(Client: TClientConnection);
begin
  Reset;
end;

procedure TClientHandler.DoDisconnectedClient(Client: TConnection);
begin
  if IsSync then SyncHandler := nil;
  Reset;
end;

end.
