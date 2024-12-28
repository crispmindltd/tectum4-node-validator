unit Blockchain.Address;

interface

uses
  Blockchain.Data;

type

  // address
  T20Bytes = TMemBlock < array [0 .. 19] of Byte >;

  // Public key
  T65Bytes = TMemBlock < array [0 .. 64] of Byte >;

  TPubKeyToAddress = record helper for T65Bytes
    function Address: T20Bytes;
  end;

  TAccount = record
  class var
    Filename: string;
    LastPrivKey: T32Bytes; // поля для получения ключей, после генерации очередного адреса
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
  // пока так, потом можно сделать более непредсказуемую генерацию
  // например FRandom := TSecureRandom.Create();
  // или через THash от нескольких GUID

  Randomize;
  var PrivKeyStr: string := StringOfChar('0', 64);
  for var i := low(PrivKeyStr) to high(PrivKeyStr) do
    PrivKeyStr[i] := '0123456789abcdef'[random(16) + 1];

  LastPrivKey := PrivKeyStr;
  var PubKeyStr: string;
  Assert(RestorePublicKey(PrivKeyStr, PubKeyStr));
  LastPubKey := PubKeyStr;

  // классовые переменные заполнили, теперь заполняем поля текущей записи
  // CreatedAt := Now();
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
    // на случай, если это нулевой адрес
    PreviousHash := string.create('0', 64);
  end;
  // пока не сохраняем в файл.
  // на клиентах адрес генерируется, но не пишется же
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
  // последние 20 байт публичного ключа, 45..64
  move(Self.Data[45], Result, 20);
end;



initialization

const ProgramPath = ExtractFilePath(ParamStr(0));

const AddressPath = TPath.Combine(ProgramPath, 'address.db');
if not TFile.Exists(AddressPath) then
  TFile.WriteAllText(AddressPath, '');

TAccount.Filename := AddressPath;


end.


