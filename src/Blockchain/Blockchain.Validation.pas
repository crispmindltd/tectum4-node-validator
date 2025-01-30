unit Blockchain.Validation;

interface

uses
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

implementation

{ TValidation }

class function TValidation.NextId: UInt64;
begin
  Result := TMemBlock<TValidation>.RecordsCount(TValidation.FileName);
end;

end.

