unit Blockchain.Validation;

interface

uses
  App.Exceptions,
  App.Types,
  System.SysUtils,
  System.IOUtils,
  System.Math,
  Blockchain.Address,
  Blockchain.Data;

type
  TValidation = record // (TValidation, TWitness, ... ??? )
  class var
    FileName:string;
  public
    SignerId: UInt64; // link to TAddress
    StartedAt: TDateTime; // when archiver sent request to validator
    FinishedAt: TDateTime; // when archiver recieved response from validator
    SignerPubKey: T65Bytes;
    Sign: TSign;
    TxnId: UInt64;    // link to TTxn
    PreviousHash: T32Bytes;
    class function NextId: UInt64; static;
  end;

  function GetTxValidations(const AFirstBlockID: UInt64; ATxID: UInt64): TArray<TValidation>;

implementation

{ TValidation }

class function TValidation.NextId: UInt64;
begin
  Result := TMemBlock<TValidation>.RecordsCount(TValidation.FileName);
end;

procedure RaiseOnInvalidHash(ABlockID:Uint64;const [ref] AHash:T32Bytes);
begin
  try
    const Block = TMemBlock<TValidation>.ReadFromFile(TValidation.FileName, ABlockID - 1);
    Require(Block.Data.PreviousHash = AHash, '');
  except
    on E:Exception do
      raise EblockchainCorrupted.Create();
  end;
end;

function GetTxValidations(const AFirstBlockID: UInt64; ATxID: UInt64): TArray<TValidation>;
begin
  Result := [];

  var BlockSize := SizeOf(TValidation);
  var i := 0;
  repeat
    var BytesBlock := TMemBlock<TValidation>.ByteArrayFromFile(TValidation.FileName,
      AFirstBlockID + i, 1);
    var ValidBlock: TMemBlock<TValidation> := Copy(BytesBlock, 0, BlockSize);
    if ValidBlock.Data.TxnId <> ATxID then
      exit;

    Result := Result + [ValidBlock.Data];
    Inc(i);
  until (i = TMemBlock<TValidation>.RecordsCount(TValidation.FileName)) or (Length(Result) = 4);
end;

end.

