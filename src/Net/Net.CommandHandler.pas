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
  TCommonRequestData = record
    Code: Byte;
    ID: Int64;
  end;

  TOutgoRequestData = record
    RequestData: TCommonRequestData;
    DoneEvent: TEvent;
    Data: TBytes;
  end;

  TResponseData = record
    RequestData: TCommonRequestData;
//    _PubKey: T65Bytes;
    Data: TBytes;
  end;

  TProcessCommand = reference to function (const AResponse: TResponseData; AConnection:TObject): TBytes;

  TCommandHandler = class
    private
      class function DoSign(const AToSign: TBytes): TBytes;
      class function GetBlocks<T>(const AFileName: string;
        const AData: TBytes): TBytes;
    public
      class var FCustomCommandProcessor:TProcessCommand;
      class function ProcessCommand(const AIncomData: TResponseData; AConnection:TObject): TBytes;
      class procedure ProcessResponseData(const AResponseData: TResponseData);
  end;

implementation

uses
  App.Intf;

{ TCommandHandler }

class function TCommandHandler.DoSign(const AToSign: TBytes): TBytes;
begin
  Result := ECDSASignBytes(AToSign, HexToBytes(AppCore.PrKey));
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

class function TCommandHandler.ProcessCommand(const AIncomData: TResponseData; AConnection:TObject): TBytes;
begin
  try
    case AIncomData.RequestData.Code of
      InitConnectCode:
        Result := HexToBytes(AppCore.PubKey) + ECDSASignBytes(AIncomData.Data, HexToBytes(AppCore.PrKey));

      GetRewardsCommandCode:
        Result := GetBlocks<TReward>(TReward.Filename, AIncomData.Data);

      GetTxnsCommandCode:
        Result := GetBlocks<TTxn>(TTxn.Filename, AIncomData.Data);

      GetAddressesCommandCode:
        Result := GetBlocks<TAccount>(TAccount.Filename, AIncomData.Data);

      GetValidationsCommandCode:
        Result := GetBlocks<TValidation>(TValidation.FileName, AIncomData.Data);

      ValidateCommandCode:
        begin
          const Tx = AIncomData.Data;
          var Validation: TMemBlock<TValidation>;
          Assert(AppCore.DoValidation(Tx, Validation));
          Result := Validation;
        end;
    else
      if Assigned(FCustomCommandProcessor) then
        Result := FCustomCommandProcessor(AIncomData, AConnection);
    end;
  except
    on E: Exception do
      Result := [ErrorCode] + TEncoding.ANSI.getbytes(E.Message);
  end;
end;

class procedure TCommandHandler.ProcessResponseData(
  const AResponseData: TResponseData);
begin

end;

end.
