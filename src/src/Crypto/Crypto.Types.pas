unit Crypto.Types;

interface

uses
  Crypto.EthereumSigner,
  System.SysUtils,
  System.Classes,
  System.Hash,
  App.Types,
  Crypto;

type
  TData<T> = record
    Data: T;
    class operator Implicit(const Hex: string): TData<T>;
    class operator Implicit(const Bytes: TBytes): TData<T>;
    class operator Implicit(const Value: TData<T>): string;
    class operator Implicit(const Value: TData<T>): TBytes;
    class operator Equal(const a, b: TData<T>): Boolean;
    class operator NotEqual(const a, b: TData<T>): Boolean;
  end;

  TAddress = TData<array[0..19] of Byte>;
  TPublicKey = TData<array [0..64] of Byte>;
  TPrivateKey = TData<array [0..31] of Byte>;
  TBlockHash = TData<array [0..31] of Byte>;

  TAddressHelper = record helper for TAddress
    function ShortAddress: string;
    function AsString: string;
    function IsEmpty: Boolean;
  end;

  TPublicKeyHelper = record helper for TPublicKey
    function Address: TAddress;
    function IsEmpty: Boolean;
  end;

  TPrivateKeyHelper = record helper for TPrivateKey
    function PublicKey: TPublicKey;
  end;

  TBlockHashHelper = record helper for TBlockHash
    procedure CreateFor(const Bytes: TBytes);
    function IsEmpty: Boolean;
  end;

  TSign = record
    Data: array [0..64] of Byte;
    class operator Implicit(const ABytes: TBytes): TSign;
    class operator Implicit(const AHexStr: string): TSign;
    class operator Implicit(const AValue: TSign): TBytes;
    class operator Implicit(const AValue: TSign): string;
  end;

  TTokenAddressPair = record
    TokenId:UInt64;
    Address:TAddress;
    EmptyFill: Integer;
    constructor Create(ATokenId:UInt64; AAddress:TAddress);
    class operator Equal(const a, b: TTokenAddressPair): Boolean;
    class operator NotEqual(const a, b: TTokenAddressPair): Boolean;
  end;

const
  EmptyPublicKey: TPublicKey = ();
  EmptyPrivateKey: TPrivateKey = ();
  EmptyAddress: TAddress = ();
  EmptyBlockHash: TBlockHash = ();
  EmptySign: TSign = ();

implementation

class operator TData<T>.Implicit(const Value: TData<T>): string;
begin
  SetLength(Result, SizeOf(T) * 2);
  BinToHex(Value.Data, PChar(Result), SizeOf(T));
  Result := Result.ToLower;
end;

class operator TData<T>.Implicit(const Bytes: TBytes): TData<T>;
begin
  Require(Length(Bytes) = SizeOf(T), 'incorrect bytes');
  Move(Bytes[0], Result, SizeOf(T));
end;

class operator TData<T>.Implicit(const Hex: string): TData<T>;
begin
  if Hex.StartsWith('0x') then
    Result := Hex.Substring(2)
  else
    if (Length(Hex) <> SizeOf(T) * 2) or (HexToBin(PChar(Hex), Result, SizeOf(T)) <> SizeOf(T)) then
      Result := Default(TData<T>);
end;

class operator TData<T>.Implicit(const Value: TData<T>): TBytes;
begin
  SetLength(Result, SizeOf(T));
  Move(Value.Data, Result[0], SizeOf(T));
end;

class operator TData<T>.Equal(const a, b: TData<T>): Boolean;
begin
  Result := CompareMem(@a, @b, SizeOf(T));
end;

class operator TData<T>.NotEqual(const a, b: TData<T>): Boolean;
begin
  Result := not (a = b);
end;

{ TPublicKeyHelper }

function TPublicKeyHelper.Address: TAddress;
begin
  var AddrStr: string;
  Assert(RestoreAddress(Self, AddrStr));
  Result := AddrStr;
end;

function TPublicKeyHelper.IsEmpty: Boolean;
begin
  Result := Self = EmptyPublicKey;
end;

{ TPrivateKeyHelper }

function TPrivateKeyHelper.PublicKey: TPublicKey;
begin
  var PublicKeyStr: string;
  Require(RestorePublicKey(Self, PublicKeyStr), 'restore public key error');
  Result := PublicKeyStr;
end;

{ TAddressHelper }

function TAddressHelper.ShortAddress: string;
begin
  Result := Copy(Self, 35);
end;

function TAddressHelper.IsEmpty: Boolean;
begin
  Result := Self = EmptyAddress;
end;

function TAddressHelper.AsString: string;
begin
  if IsEmpty then
    Result := '0x0000000000000000000000000000000000000000'
  else
    Result := '0x' + Self;
end;

{ TSign }

class operator TSign.Implicit(const AValue: TSign): TBytes;
begin
      const amountBytes = SizeOf(TSign);
      SetLength(Result, amountBytes);
      Move(AValue.Data[0], Result[0], amountBytes);
end;

class operator TSign.Implicit(const ABytes: TBytes): TSign;
begin
  FillChar(Result.Data, SizeOf(TSign), 0);
  const amountBytes = Length(ABytes);
  if amountBytes = 0 then Exit;
  Require(amountBytes = SizeOf(TSign), 'invalid sign size');
  Move(ABytes[0], Result.Data[SizeOf(TSign) - amountBytes], amountBytes);
end;

class operator TSign.Implicit(const AValue: TSign): string;
begin
  SetLength(Result, SizeOf(TSign) * 2);
  BinToHex(AValue.Data, PChar(Result), SizeOf(TSign));
end;

class operator TSign.Implicit(const AHexStr: string): TSign;
begin
  Require(Length(AHexStr) mod 2 = 0, 'invalid sign hex');
  var LBytes: TBytes;
  SetLength(LBytes, Length(AHexStr) div 2);
  Require(HexToBin(PChar(AHexStr), LBytes, SizeOf(TSign)) = SizeOf(TSign), 'invalid sign hex');
  Result := LBytes;
end;

procedure TBlockHashHelper.CreateFor(const Bytes: TBytes);
begin
  Self := Keccack256(Bytes);
end;

function TBlockHashHelper.IsEmpty: Boolean;
begin
  Result := Self = EmptyBlockHash;
end;

constructor TTokenAddressPair.Create(ATokenId: UInt64; AAddress: TAddress);
begin
  Address := AAddress;
  TokenId := ATokenId;
  EmptyFill := 0;
end;
class operator TTokenAddressPair.Equal(const a, b: TTokenAddressPair): Boolean;
begin
  Result := CompareMem(@a, @b, SizeOf(TTokenAddressPair));
end;

class operator TTokenAddressPair.NotEqual(const a, b: TTokenAddressPair): Boolean;
begin
  Result := not (a=b);
end;

end.
