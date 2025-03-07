unit Blockchain.Address;

interface

uses
  Blockchain.Data;

type

  // address
  T20Bytes = TMemBlock < array [0 .. 19] of Byte >;

  // Public key
  T65Bytes = TMemBlock < array [0 .. 64] of Byte >;

  TAddress = T20Bytes;
  TPublicKey = T65Bytes;

  TPubKeyToAddress = record helper for T65Bytes
    function Address: TAddress;
    function ShortAddress: string;
    function IsEmpty: Boolean;
  end;

  TAccount = record
  class var
    Filename: string;
    LastPrivKey: T32Bytes;
    LastPubKey: T65Bytes;
    class function NextId: UInt64; static;
    class function GetAddressId(const AAddress: T20Bytes): UInt64; static;
  public
//    CreatedAt: TDateTime;
    TxId: UInt64;
    Address: T20Bytes;
    PreviousHash: T32Bytes;
    procedure GenerateNew();
  end;

const
  EmptyPublicKey: TPublicKey = ();

function AddressToStr(const Address: T20Bytes): string;
function RestoreAddressAsStr(const PubKeyStr: string): string;

implementation

uses
  Blockchain.Txn,
  Crypto,
  System.Hash,
  System.SysUtils,
  System.IOUtils;

{ TAddress }

procedure TAccount.GenerateNew;
begin

  Randomize;
  var PrivKeyStr: string := StringOfChar('0', 64);
  for var i := low(PrivKeyStr) to high(PrivKeyStr) do
    PrivKeyStr[i] := '0123456789abcdef'[random(16) + 1];

  LastPrivKey := PrivKeyStr;
  var PubKeyStr: string;
  Assert(RestorePublicKey(PrivKeyStr, PubKeyStr), 'Error restoring pubkey from privkey when generate new account');
  LastPubKey := PubKeyStr;

  TxId := INVALID;
  Address := LastPubKey.Address;

  try
    var LastAddress: TMemBlock<TAccount>;
    const addressesCount = LastAddress.RecordsCount(TAccount.Filename);
    if addressesCount > 0 then begin
      LastAddress.ReadFromFile(TAccount.Filename, addressesCount - 1);
      PreviousHash := LastAddress.Hash;
    end;

  except
    PreviousHash := string.create('0', 64);
  end;
end;

class function TAccount.GetAddressId(const AAddress: T20Bytes): UInt64;
begin
  Result := INVALID;
  const LNextId = NextId();
  begin
  end;

  if LNextId = 0 then
    Exit;

  for var i: UInt64 := 0 to LNextId - 1 do begin
    const addr = TMemBlock<TAccount>.ReadFromFile(TAccount.Filename, i);
    if not(addr.Data.Address = AAddress) then
      Continue;
    Result := i;
    Exit;
  end;
end;

class function TAccount.NextId: UInt64;
begin
  Result := TMemBlock<TAccount>.RecordsCount(TAccount.Filename);
end;

{ TPubKeyToAddress }

function TPubKeyToAddress.Address: T20Bytes;
begin
  var AddrStr: string;
  Assert(RestoreAddress(Self, AddrStr));
  Result := AddrStr;
end;

function TPubKeyToAddress.ShortAddress: string;
begin
  Result := Copy(Address, 35);
end;

function TPubKeyToAddress.IsEmpty: Boolean;
begin
  Result := Self = EmptyPublicKey;
end;

function AddressToStr(const Address: T20Bytes): string;
begin
  Result := ('0x' + Address).ToLower;
end;

function RestoreAddressAsStr(const PubKeyStr: string): string;
begin
  const pubKey: TPublicKey = PubKeyStr;
  Result := AddressToStr(pubKey.address);
end;

initialization

const ProgramPath = ExtractFilePath(ParamStr(0));

const ChainsDirPath = TPath.Combine(ProgramPath, 'chains');
if not DirectoryExists(ChainsDirPath) then
  TDirectory.CreateDirectory(ChainsDirPath);

const AddressPath = TPath.Combine(ChainsDirPath, 'address.db');
if not TFile.Exists(AddressPath) then
  TFile.WriteAllText(AddressPath, '');

TAccount.Filename := AddressPath;

end.


