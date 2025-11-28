unit Blockchain.Data;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  App.Types,
  App.DateUtils,
  Crypto.EthereumSigner,
  Crypto.Types,
  Database.Types,
  Blockchain.Types;

const
  TRANSFER_TRANSACTION: TDataType = $0001;
  MINT_TRANSACTION: TDataType = $0002;
  STAKING_TRANSACTION: TDataType = $0003;
  UNSTAKING_TRANSACTION: TDataType = $0004;
  MIGRATE_TRANSACTION: TDataType = $0005;
  VALIDATE1_TRANSACTION: TDataType = $0006;
  VALIDATE4_TRANSACTION: TDataType = $0007;
  MINEBLOCK_TRANSACTION: TDataType = $0008;
  VALIDATE_TRANSACTION: TDataType = $0009;
  TOKEN_ICON_DATA: TDataType = $0010;

type
  TMint = record // non-fixed size!
    SenderAddress:TAddress;
    No: UInt32;
    Name: string;
    Ticker:string;
    Digits: Byte;
    Amount: TAmount;
    Fee: TAmount;
    Description: string;
    IconURL:string;
    Date: TUnixTimestamp;
    Sign: TSign;
    function DataForHash(): TBytes;
    function DataHash(): TBlockHash;
    function Hash(): TBlockHash;
    function RecoverAddress():TAddress;
    procedure SignBy(const PrivateKey: TPrivateKey);
    procedure CheckSign();
    class operator Implicit(const Mint: TMint): TBytes;
    class operator Implicit(const P: Pointer): TMint;
  end;

  TTransaction<T: record> = record // fixed size
    SenderAddress:TAddress;
    Data: T;
    Date: TUnixTimestamp;
    Sign: TSign;
    function DataForHash: TBytes;
    function DataHash: TBlockHash;
    function Hash: TBlockHash;
    function RecoverAddress():TAddress;
    procedure SignBy(const PrivateKey: TPrivateKey);
    procedure CheckSign;
    class operator Implicit(const Transaction: TTransaction<T>): TBytes;
  end;

  TTransferData = record
    No: UInt32;
    TokenId:Uint64;
    AddressTo: TAddress;
    Amount: TAmount;
    Fee: TAmount;
  end;

  TTransfer = TTransaction<TTransferData>;

  TStakingData = record
    No: UInt32;
    Amount: TAmount;
    Fee: TAmount;
  end;

  TStaking = TTransaction<TStakingData>;

  TUnstakingData = record
    No: UInt32;
    Amount: TAmount;
    Fee: TAmount;
  end;

  TUnstaking = TTransaction<TUnstakingData>;

  TMigrateData = record
    No: UInt32;
    AddressTo: TAddress;
    Amount: TAmount;
  end;

  TMigrate = TTransaction<TMigrateData>;

  TIconData = record
    Bytes: TBytes;
    class operator Implicit(const IconData: TIconData): TBytes;
    class operator Implicit(const P: Pointer): TIconData;
  end;

  TValidator = record
    ValidatorType: Byte;
    Date: TUnixTimestamp;
    Address: TAddress;
    Reward: TAmount;
  end;

  TValidate1Data = record
    No: UInt32;
    TxHash: TBlockHash;
    Validator: TValidator;
  end;

  TValidate1 = TTransaction<TValidate1Data>;

  TValidate4Data = record
    No: UInt32;
    TxHash: TBlockHash;
    Validators: array[0..3] of TValidator;
  end;

  TValidate4 = TTransaction<TValidate4Data>;

  TBlockData = record
    Nonce: UInt64;
    Hash: TBlockHash;
    PrevBlockHash: TBlockHash;
    IndexTo: UInt64;
    StakeAmount: TAmount;
    Reward: TAmount;
  end;

  TBlock = record
    SenderAddress:TAddress;
    Data: TBlockData;
    Date: TUnixTimestamp;
    Sign: TSign;
    function DataHash: TBlockHash;
    function RecoverAddress():TAddress;
    procedure SignBy(const PrivateKey: TPrivateKey);
    procedure CheckSign;
    class operator Implicit(const Block: TBlock): TBytes;
  end;

  TValidateData = record
    No: UInt32;
    ToHash: TBlockHash;
    Reward: TAmount;
  end;

  TValidate = TTransaction<TValidateData>;

  PDataType = ^TDataType;
  PDataLength = ^TDataLength;
  PTransfer = ^TTransfer;
  PStaking = ^TStaking;
  PUnstaking = ^TUnstaking;
  PMigrate = ^TMigrate;
  PValidate1 = ^TValidate1;
  PValidate4 = ^TValidate4;
  PBlock = ^TBlock;
  PValidate = ^TValidate;
  PIconData = ^TIconData;

implementation

{ TMint }

function TMint.DataForHash(): TBytes;
begin
  Result := TCode.BytesOf(No)
    + TCode.BytesOf(Name)
    + TCode.BytesOf(Ticker)
    + TCode.BytesOf(Digits)
    + TCode.BytesOf(Amount)
    + TCode.BytesOf(Fee)
    + TCode.BytesOf(Description)
    + TCode.BytesOf(IconURL);
end;

function TMint.DataHash(): TBlockHash;
begin
  Result.CreateFor(DataForHash);
end;

function TMint.Hash(): TBlockHash;
begin
  Result.CreateFor(DataForHash + TBytes(Sign));
end;

function TMint.RecoverAddress: TAddress;
begin
  Result := Crypto.EthereumSigner.RecoverAddress(DataHash, Sign);
end;

procedure TMint.SignBy(const PrivateKey: TPrivateKey);
begin
  Sign := SignWithKey(DataHash, PrivateKey);
end;

procedure TMint.CheckSign();
begin
  var addr: TBytes;
  Require(TryRecoverAddress(DataHash, Sign, addr), 'wrong sign');
  Require(addr = SenderAddress, 'wrong sign, address differs');
end;

class operator TMint.Implicit(const P: Pointer): TMint;
begin
  var Bytes: PByte := P;
  Result.SenderAddress := TCode.ValueOf<TAddress>(Bytes);
  Result.No := TCode.ValueOf<UInt32>(Bytes);
  Result.Name := TCode.StringOf(Bytes);
  Result.Ticker := TCode.StringOf(Bytes);
  Result.Digits := TCode.ValueOf<Byte>(Bytes);
  Result.Amount := TCode.ValueOf<TAmount>(Bytes);
  Result.Fee := TCode.ValueOf<TAmount>(Bytes);
  Result.Description := TCode.StringOf(Bytes);
  Result.IconURL := TCode.StringOf(Bytes);
  Result.Date := TCode.ValueOf<TUnixTimestamp>(Bytes);
  Result.Sign := TCode.ValueOf<TSign>(Bytes);
end;

class operator TMint.Implicit(const Mint: TMint): TBytes;
begin
  Result := TCode.BytesOf(Mint.SenderAddress)
   + TCode.BytesOf(Mint.No)
   + TCode.BytesOf(Mint.Name)
   + TCode.BytesOf(Mint.Ticker)
   + TCode.BytesOf(Mint.Digits)
   + TCode.BytesOf(Mint.Amount)
   + TCode.BytesOf(Mint.Fee)
   + TCode.BytesOf(Mint.Description)
   + TCode.BytesOf(Mint.IconURL)
   + TCode.BytesOf(Mint.Date)
   + TCode.BytesOf(Mint.Sign);
end;

{ TTransaction }

function TTransaction<T>.DataForHash: TBytes;
begin
  Result := BytesOf(@Data, SizeOf(T));
end;

function TTransaction<T>.DataHash: TBlockHash;
begin
  Result.CreateFor(DataForHash);
end;

function TTransaction<T>.Hash: TBlockHash;
begin
  Result.CreateFor(DataForHash + TBytes(Sign));
end;

function TTransaction<T>.RecoverAddress: TAddress;
begin
  Result := Crypto.EthereumSigner.RecoverAddress(DataHash, Sign);
end;

procedure TTransaction<T>.SignBy(const PrivateKey: TPrivateKey);
begin
  Sign := SignWithKey(DataHash, PrivateKey);
end;

procedure TTransaction<T>.CheckSign;
begin
  var addr: TBytes;
  Require(TryRecoverAddress(DataHash, Sign, addr), 'wrong sign, can not recover');
  Require(addr = SenderAddress, 'wrong sign, address differs');
end;

class operator TTransaction<T>.Implicit(const Transaction: TTransaction<T>): TBytes;
begin
  Result := BytesOf(@Transaction, SizeOf(Transaction));
end;

{ TBlock }

function TBlock.DataHash: TBlockHash;
begin
  Result.CreateFor(BytesOf(@Data, SizeOf(Data)));
end;

function TBlock.RecoverAddress: TAddress;
begin
  Result := Crypto.EthereumSigner.RecoverAddress(BytesOf(@Data, SizeOf(Data)), Sign);
end;

procedure TBlock.SignBy(const PrivateKey: TPrivateKey);
begin
  Sign := SignWithKey(DataHash, PrivateKey);
end;

procedure TBlock.CheckSign;
begin
  var addr: TBytes;
  Require(TryRecoverAddress(DataHash, Sign, addr), 'wrong sign');
  Require(addr = SenderAddress, 'wrong sign, address differs');
end;

class operator TBlock.Implicit(const Block: TBlock): TBytes;
begin
  Result := BytesOf(@Block, SizeOf(Block));
end;

{ TIconData }

class operator TIconData.Implicit(const P: Pointer): TIconData;
begin
  var Bytes: PByte := P;
  const Len = TCode.ValueOf<Integer>(Bytes);
  Result.Bytes := System.SysUtils.BytesOf(Bytes, Len);
end;

class operator TIconData.Implicit(const IconData: TIconData): TBytes;
begin
  Result :=
   TCode.BytesOf<Integer>(Length(IconData.Bytes)) +
   IconData.Bytes;
end;

end.
