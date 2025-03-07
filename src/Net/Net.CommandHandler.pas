unit Net.CommandHandler;

interface

uses
  Blockchain.Address,
  Blockchain.Data,
  Blockchain.Reward,
  Blockchain.Txn,
  Blockchain.Validation,
//  Net.Connection,
  App.Types,
  App.Exceptions,
  Crypto,
  Net.Data,
  System.SyncObjs,
  System.SysUtils;

type
  TOutgoRequestData = record
    Code: Byte;
    DoneEvent: TEvent;
    Data: TBytes;
  end;

  TResponseData = record
    Code: Byte;
    ID: UInt64;
    Data: TBytes;
  end;

  TProcessCommand = reference to function (const AResponse: TResponseData; AConnection:TObject): TBytes;

  TCommandHandler = class
    private
      class function DoSign(const AToSign: TBytes): TBytes;

//      class function GetBlocks<T>(const AFileName: string;
//        const AData: TBytes): TBytes;                         overload;

      class function GetBlocks<T>(const AFileName: string;
        ABlockId:UInt64; [ref] AClientHash:T32Bytes): TBytes;

      class function DoInitConnect(const AIncomData: TResponseData): TBytes;
      class function GetRewardsBlocks(ABlockId:UInt64; [Ref] ALastHash:T32Bytes): TBytes;
      class function GetTxnsBlocks(ABlockId:UInt64; [Ref] ALastHash:T32Bytes): TBytes;
      class function GetAddressesBlocks(ABlockId:UInt64; [Ref] ALastHash:T32Bytes): TBytes;
      class function GetValidationsBlocks(ABlockId:UInt64; [Ref] ALastHash:T32Bytes): TBytes;
      class function DoValidation(const AIncomData: TResponseData): TBytes;
      class procedure DoCheckVersion(const AIncomData: TResponseData);
    public
      class var FCustomCommandProcessor:TProcessCommand;
      class function ProcessCommand(const AIncomData: TResponseData; AConnection:TObject): TBytes;
      class function ProcessGetBlocksCommand(const AIncomData: TResponseData): TBytes;
  end;

implementation

uses
  App.Intf;

{ TCommandHandler }

class procedure TCommandHandler.DoCheckVersion(const AIncomData: TResponseData);
begin
  if AppCore.GetAppVersion <> TEncoding.ANSI.GetString(AIncomData.Data) then
    AppCore.StartUpdate;
end;

class function TCommandHandler.DoInitConnect(const AIncomData: TResponseData): TBytes;
begin
  Result := HexToBytes(AppCore.PubKey) +
    ECDSASignBytes(AIncomData.Data, HexToBytes(AppCore.PrKey));
end;

class function TCommandHandler.DoSign(const AToSign: TBytes): TBytes;
begin
  Result := ECDSASignBytes(AToSign, HexToBytes(AppCore.PrKey));
end;

class function TCommandHandler.DoValidation(const AIncomData: TResponseData): TBytes;
begin
  const Tx = AIncomData.Data;
  var Validation: TMemBlock<TValidation>;
  Assert(AppCore.DoValidation(Tx, Validation), 'can not do validation');
  Result := Validation;
end;

class function TCommandHandler.GetBlocks<T>(const AFileName: string;
  ABlockId: UInt64; [ref] AClientHash:T32Bytes): TBytes;
begin
  const MaxBlocks = 100;

  const LBlockId = TMemBlock<T>.RecordsCount(AFileName);

  if LBlockId < ABlockId then
    raise EBlockchainCorrupted.Create();

  if (LBlockId = ABlockId) and not (TMemBlock<T>.LastHash(AFileName) = AClientHash) then
    raise EBlockchainCorrupted.Create();

  Result := TMemBlock<T>.ByteArrayFromFile(AFilename, ABlockId, MaxBlocks);
end;

class function TCommandHandler.GetAddressesBlocks(ABlockId:UInt64; [Ref] ALastHash:T32Bytes): TBytes;
begin
  const Bytes = GetBlocks<TAccount>(TAccount.Filename, ABlockId, ALastHash);

  if Length(Bytes) < Sizeof(TAccount) then Exit;

  if not (TMemBlock<TAccount>(Copy(Bytes, 0, Sizeof(TAccount))).Data.PreviousHash = ALastHash) then
    raise EBlockchainCorrupted.Create();

  Result := Bytes;
end;

class function TCommandHandler.GetRewardsBlocks(ABlockId:UInt64; [Ref] ALastHash:T32Bytes): TBytes;
begin
  const Bytes = GetBlocks<TReward>(TReward.FileName, ABlockId, ALastHash);

  if Length(Bytes) < Sizeof(TReward) then Exit;

  if not (TMemBlock<TReward>(Copy(Bytes, 0, Sizeof(TReward))).Data.PreviousHash = ALastHash) then
    raise EBlockchainCorrupted.Create();

  Result := Bytes;
end;

class function TCommandHandler.GetTxnsBlocks(ABlockId:UInt64; [Ref] ALastHash:T32Bytes): TBytes;
begin
  const Bytes = GetBlocks<TTxn>(TTxn.FileName, ABlockId, ALastHash);

  if Length(Bytes) < Sizeof(TTxn) then Exit;

  if not (TMemBlock<TTxn>(Copy(Bytes, 0, Sizeof(TTxn))).Data.PreviousHash = ALastHash) then
    raise EBlockchainCorrupted.Create();

  Result := Bytes;
end;

class function TCommandHandler.GetValidationsBlocks(ABlockId:UInt64; [Ref] ALastHash:T32Bytes): TBytes;
begin

  const Bytes = GetBlocks<TValidation>(TValidation.FileName, ABlockId, ALastHash);

  if (Length(Bytes) < Sizeof(TValidation)) then Exit;

  if not (TMemBlock<TValidation>(Copy(Bytes, 0, Sizeof(TValidation))).Data.PreviousHash = ALastHash) then
    raise EBlockchainCorrupted.Create();

  Result := Bytes;
end;

class function TCommandHandler.ProcessGetBlocksCommand(
  const AIncomData: TResponseData): TBytes;
begin

  Require(Length(AIncomData.Data) = 40 {block id + hash}, 'incorrect getBlocks request');

  var BlocksFrom: UInt64;
  Move(AIncomData.Data[0], BlocksFrom, 8);

  var LastHash: T32Bytes;
  Move(AIncomData.Data[8], LastHash, SizeOf(LastHash));

  var Blocks:TBytes;

  case AIncomData.Code of
    GetRewardsCommandCode:
      Result := GetRewardsBlocks(BlocksFrom, LastHash);

    GetTxnsCommandCode:
      Result := GetTxnsBlocks(BlocksFrom, LastHash);

    GetAddressesCommandCode:
      Result := GetAddressesBlocks(BlocksFrom, LastHash);

    GetValidationsCommandCode:
      Result := GetValidationsBlocks(BlocksFrom, LastHash);
  end;
end;

class function TCommandHandler.ProcessCommand(const AIncomData: TResponseData;
  AConnection: TObject): TBytes;
begin
    case AIncomData.Code of
      InitConnectCode:
        Result := DoInitConnect(AIncomData);

      GetRewardsCommandCode,
      GetTxnsCommandCode,
      GetAddressesCommandCode,
      GetValidationsCommandCode:
        Result := ProcessGetBlocksCommand(AIncomData);

      ValidateCommandCode:
        Result := DoValidation(AIncomData);

      CheckVersionCommandCode:
        DoCheckVersion(AIncomData);
    else
      if Assigned(FCustomCommandProcessor) then
        Result := FCustomCommandProcessor(AIncomData, AConnection);
    end;
end;

end.
