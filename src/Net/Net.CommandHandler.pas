unit Net.CommandHandler;

interface

uses
  Blockchain.Address,
  Blockchain.Data,
  Blockchain.Reward,
  Blockchain.Txn,
  Blockchain.Validation,
//  Net.Connection,
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
      class function GetBlocks<T>(const AFileName: string;
        const AData: TBytes): TBytes;

      class function DoInitConnect(const AIncomData: TResponseData): TBytes;
      class function GetRewardsBlocks(const AIncomData: TResponseData): TBytes;
      class function GetTxnsBlocks(const AIncomData: TResponseData): TBytes;
      class function GetAddressesBlocks(const AIncomData: TResponseData): TBytes;
      class function GetValidationsBlocks(const AIncomData: TResponseData): TBytes;
      class function DoValidation(const AIncomData: TResponseData): TBytes;
      class procedure DoCheckVersion(const AIncomData: TResponseData);
    public
      class var FCustomCommandProcessor:TProcessCommand;
      class function ProcessCommand(const AIncomData: TResponseData; AConnection:TObject): TBytes;
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

class function TCommandHandler.GetAddressesBlocks(
  const AIncomData: TResponseData): TBytes;
begin
  Result := GetBlocks<TAccount>(TAccount.Filename, AIncomData.Data);
end;

class function TCommandHandler.GetBlocks<T>(const AFileName: string;
  const AData: TBytes): TBytes;
const
  MaxBlocks = 100;
var
  BlocksFrom: UInt64;
begin
  Result := [];
  Move(AData[0], BlocksFrom, 8);
  if TMemBlock<T>.RecordsCount(AFilename) <= BlocksFrom then
    exit;

  Result := TMemBlock<T>.ByteArrayFromFile(AFilename, BlocksFrom, MaxBlocks);
end;

class function TCommandHandler.GetRewardsBlocks(
  const AIncomData: TResponseData): TBytes;
begin
  Result := GetBlocks<TReward>(TReward.Filename, AIncomData.Data);
end;

class function TCommandHandler.GetTxnsBlocks(const AIncomData: TResponseData): TBytes;
begin
  Result := GetBlocks<TTxn>(TTxn.Filename, AIncomData.Data);
end;

class function TCommandHandler.GetValidationsBlocks(
  const AIncomData: TResponseData): TBytes;
begin
  Result := GetBlocks<TValidation>(TValidation.FileName, AIncomData.Data);
end;

class function TCommandHandler.ProcessCommand(const AIncomData: TResponseData;
  AConnection: TObject): TBytes;
begin
  try
    case AIncomData.Code of
      InitConnectCode:
        Result := DoInitConnect(AIncomData);

      GetRewardsCommandCode:
        Result := GetRewardsBlocks(AIncomData);

      GetTxnsCommandCode:
        Result := GetTxnsBlocks(AIncomData);

      GetAddressesCommandCode:
        Result := GetAddressesBlocks(AIncomData);

      GetValidationsCommandCode:
        Result := GetValidationsBlocks(AIncomData);

      ValidateCommandCode:
        Result := DoValidation(AIncomData);

      CheckVersionCommandCode:
        DoCheckVersion(AIncomData);
    else
      if Assigned(FCustomCommandProcessor) then
        Result := FCustomCommandProcessor(AIncomData, AConnection);
    end;
  except
    on E: Exception do
      Result := [ErrorCode] + TEncoding.ANSI.getbytes(E.Message);
  end;
end;

end.
