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
  App.Exceptions,
  Blockchain.Data,
  Blockchain.Reward,
  Blockchain.Txn,
  Blockchain.Validation,
  Blockchain.Address,
  BlockChain.DataCache,
  Blockchain.Utils,
  Net.Types,
  Net.Intf,
  Net.SocketA,
  Net.Peer,
  Net.Event,
  Net.CustomHandler;

type
  TClientHandler = class(TCustomHandler)
  private type
    TSyncData = set of (Rewards, Transactions, Addresses, Validations);
  private const
    SyncDataAll: TSyncData = [Rewards, Transactions, Addresses, Validations];
  private
    FSyncData: TSyncData;
    FSyncCount: UInt64;
    class var SyncHandler: TClientHandler; // singleton
    procedure SendSynchronizeBlockchain(Data: TSyncData);
    procedure SyncData(Data: TSyncData);
    procedure ResetSyncData;
    function GetBlockRequestBytes<T>(const AFileName: string): TBytes;
    function IsSync: Boolean;
  protected
    procedure Reset;
    procedure DoReceived(const Request: TRequest); override;
  public
    constructor Create(Client: TClient; NetCore: INetCore);
    procedure DoConnectedClient(Client: TClient);
    procedure DoDisconnectedClient(Client: TClient);
  end;

implementation

uses
  Net.Data,
  Crypto,
  App.Intf;

const
  SReceivedData = 'Received %s data %d bytes';

function TClientHandler.GetBlockRequestBytes<T>(const AFileName: string): TBytes;
begin
  const BlocksCount = TMemBlock<T>.RecordsCount(AFileName);
  var Hash:T32Bytes;
  if BlocksCount > 0 then begin
    const LastBlock = TMemBlock<T>.ReadFromFile(AFilename, BlocksCount - 1);
    Hash := LastBlock.Hash;
  end else
    FillChar(Hash, SizeOf(T32Bytes), 0);
  Result := BytesOf(@BlocksCount, SizeOf(UInt64)) + TBytes(Hash);
end;

constructor TClientHandler.Create(Client: TClient; NetCore: INetCore);
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
  Data := nil;
  FQueue := nil;
  FSyncData := [];
end;

function TClientHandler.IsSync: Boolean;
begin
  Result := SyncHandler = Self;
end;

procedure TClientHandler.ResetSyncData;
begin
  FSyncData := [];
  if SyncHandler = Self then
  if Assigned(AppCore) then
    AppCore.SetBlockchainSynchronized(False);
end;

procedure TClientHandler.SyncData(Data: TSyncData);
begin
  if FSyncData <> SyncDataAll then
  begin
    FSyncData := FSyncData + Data;
    if FSyncData = SyncDataAll then
    begin
      OnLog('Blockchain synchronized from ' + ReceiverName, INFO);
      AppCore.SetBlockchainSynchronized(True);
    end;
  end;
end;

procedure TClientHandler.SendSynchronizeBlockchain(Data: TSyncData);
begin
  if not IsSync then Exit;
  if Addresses in Data then SendRequest(GetAddressesCommandCode,
    GetBlockRequestBytes<TAccount>(TAccount.Filename));
  if Rewards in Data then SendRequest(GetRewardsCommandCode,
    GetBlockRequestBytes<TReward>(TReward.Filename));
  if Transactions in Data then SendRequest(GetTxnsCommandCode,
    GetBlockRequestBytes<TTxn>(TTxn.Filename));
  if Validations in Data then SendRequest(GetValidationsCommandCode,
    GetBlockRequestBytes<TValidation>(TValidation.Filename));
end;

procedure TClientHandler.DoReceived(const Request: TRequest);
  procedure CleanFile(const AFilename:string);
  begin
    CSMap.Enter(AFilename);
    try
      TFile.WriteAllText(AFilename, '');
    finally
      CSMap.Leave(AFilename);
    end;
  end;
begin
  case Request.CommandCode of
    CheckVersionCommandCode: begin
      var Version := StringOf(Request.Body);
      OnLog('Server ' + ReceiverName + ' is version ' + Version, INFO);
      if Assigned(AppCore) and (AppCore.GetAppVersion <> Version) then
        AppCore.StartUpdate;
    end;

    InitConnectCode: begin
      OnLog('Send signed received sample to ' + ReceiverName, INFO);
      if Assigned(AppCore) then
        SendResponse(Request.ID, ResponseCode, HexToBytes(AppCore.PubKey) +
        ECDSASignBytes(Request.Body, HexToBytes(AppCore.PrKey)));
    end;

    SuccessCode: begin
      OnLog('Server ' + ReceiverName + ' approved the connection: ' + StringOf(Request.Body), INFO);
      FState := TConnectionState.Passed;
      if not Assigned(SyncHandler) then begin
        SyncHandler := Self;
        OnLog('Send count request for synchronization to ' + ReceiverName, INFO);
        SendRequest(InfoCommandCode, nil);
        OnLog('Send synchronize blockchain request to ' + ReceiverName, INFO);
        SendSynchronizeBlockchain(SyncDataAll);
      end;
    end;

    InitConnectErrorCode: begin
      OnLog('InitConnectError: ' + StringOf(Request.Body), ERROR);
      FState := TConnectionState.Failed;
      Client.Disconnect;
      AppCore.DoHalt(StringOf(Request.Body));
    end;

    KeyAlreadyUsesErrorCode: begin
      OnLog('KeyAlreadyUsesError: ' + StringOf(Request.Body), ERROR);
      FState := TConnectionState.Failed;
      Client.Disconnect;
      AppCore.DoHalt(StringOf(Request.Body));
    end;

    PingCommandCode: begin
      OnLog('Ping: ' + ReceiverName, INFO);
      SendResponse(Request.Id, ResponseCode);
    end;

    ResponseCode: begin
      var Header: TRequestTask;
      if GetRequestFor(Request.ID, Request.Body, Header) then begin
        if Header.CommandCode = InfoCommandCode then begin

          if Length(Request.Body) >= SizeOf(FSyncCount) then
            FSyncCount := PUInt64(Request.Body)^; // Count of Validation chain for show progress

        end

        else if Header.CommandCode in [GetRewardsCommandCode,
          GetValidationsCommandCode, GetTxnsCommandCode,
          GetAddressesCommandCode] then begin

          try
            if not IsSync then Exit;
            Assert(Length(Request.Body) > 0);

            const SyncResultCode = Request.Body[0];
            if SyncResultCode = BlockchainCorruptedErrorCode then begin
              OnLog(ReceiverName + ' sent BlockchainCorruptedErrorCode ' + Header.CommandCode.ToString, TLevel.FATAL);

              raise EBlockchainCorrupted.Create();   // >> app exception
            end;

            Assert(SyncResultCode = SuccessCode);
            const NewBlocks = Copy(Request.Body, 1);
            const NewBlocksLength = Length(NewBlocks);

            case Header.CommandCode of
              GetRewardsCommandCode: begin
                if NewBlocksLength > 0 then begin
                  OnLog(Format(SReceivedData, ['rewards', NewBlocksLength]), INFO);
                  ResetSyncData;
                  const DataPreviousHash = TMemBlock<TReward>(Copy(NewBlocks, 0, SizeOf(TReward))).Data.PreviousHash;
                  TMemBlock<TReward>.ByteArrayToFile(TReward.Filename, NewBlocks, DataPreviousHash);
                  // update cache
                  var i := 0;
                  while i < NewBlocksLength do begin
                    const reward: TMemBlock<TReward> = Copy(NewBlocks, i, SizeOf(TReward));
                    DataCache.UpdateCache(reward);
                    Inc(i, SizeOf(TReward));
                  end;
                end else
                  SyncData([Rewards]);
                AddQueue(procedure begin SendSynchronizeBlockchain([Rewards]) end, 500);
              end;

              GetTxnsCommandCode: begin
                if NewBlocksLength > 0 then begin
                  OnLog(Format(SReceivedData, ['transactions', NewBlocksLength]), INFO);
                  ResetSyncData;
                  var FromID := TMemBlock<TTxn>.RecordsCount(TTxn.Filename);
                  const DataPreviousHash = TMemBlock<TTxn>(Copy(NewBlocks, 0, SizeOf(TTxn))).Data.PreviousHash;
                  TMemBlock<TTxn>.ByteArrayToFile(TTxn.Filename, NewBlocks, DataPreviousHash);
                  // update cache
                  var i := 0;
                  while i < NewBlocksLength do begin
                    const txn: TMemBlock<TTxn> = Copy(NewBlocks, i, SizeOf(TTxn));
                    DataCache.UpdateCache(txn, FromID + i div SizeOf(TTxn));
                    Inc(i, SizeOf(TTxn));
                  end;
                end else
                  SyncData([Transactions]);
                AddQueue(procedure begin SendSynchronizeBlockchain([Transactions]) end, 500);
              end;

              GetValidationsCommandCode: begin
                if NewBlocksLength > 0 then begin
                  OnLog(Format(SReceivedData, ['validations', NewBlocksLength]), INFO);
                  ResetSyncData;
                  const DataPreviousHash = TMemBlock<TValidation>(Copy(NewBlocks, 0, SizeOf(TValidation))).Data.PreviousHash;
                  TMemBlock<TValidation>.ByteArrayToFile(TValidation.Filename, NewBlocks, DataPreviousHash);
                  UI.DoSynchronize(TMemBlock<TValidation>.RecordsCount(TValidation.Filename), FSyncCount);
                end else
                  SyncData([Validations]);
                AddQueue(procedure begin SendSynchronizeBlockchain([Validations]) end, 500);
              end;

              GetAddressesCommandCode: begin
                if NewBlocksLength > 0 then begin
                  OnLog(Format(SReceivedData, ['addresses', NewBlocksLength]), INFO);
                  ResetSyncData;
                  const DataPreviousHash = TMemBlock<TAccount>(Copy(NewBlocks, 0, SizeOf(TAccount))).Data.PreviousHash;
                  TMemBlock<TAccount>.ByteArrayToFile(TAccount.Filename, NewBlocks, DataPreviousHash);
                end else
                  SyncData([Addresses]);
                AddQueue(procedure begin SendSynchronizeBlockchain([Addresses]) end, 500);
              end;
            end;
          except on E:EBlockchainCorrupted do
            begin
              if not Assigned(AppCore) then Exit;

              OnLog('Blockchain is corrupted', ERROR);
              CleanFile(TTxn.Filename);                    // >> unit blockchain core
              CleanFile(TReward.Filename);
              CleanFile(TValidation.Filename);
              CleanFile(TAccount.Filename);
              AppCore.DoHalt('Blockchain is corrupted');
              raise;
            end;
          end;
        end;
      end;
    end;

    ValidateCommandCode:
      try
        var Validation: TMemBlock<TValidation>;
        if AppCore.DoValidation(Request.Body, Validation) then begin
          OnLog('Send tx validation to ' + ReceiverName, INFO);
          SendResponse(Request.ID, ResponseCode, [SuccessCode] + TBytes(Validation));
        end else
          raise Exception.Create('Can`t do tx validation for ' + ReceiverName);

      except on E: Exception do begin
          OnLog(E.Message, ERROR);
          SendResponse(Request.ID, ResponseCode, [ErrorCode] + BytesOf(E.Message));
        end;
      end;
  end;
end;

procedure TClientHandler.DoConnectedClient(Client: TClient);
begin
  Reset;
end;

procedure TClientHandler.DoDisconnectedClient(Client: TClient);
begin
  if SyncHandler = Self then SyncHandler := nil;
  Reset;
end;

end.
