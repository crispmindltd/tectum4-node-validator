unit Blockchain.Types;

interface

uses
  System.SysUtils,
  App.Types,
  App.DateUtils,
  Crypto.Types;

type
  TAmount = UInt64;

  TToken = record
    Id: UInt64;
    Name: string;
    Ticker: string;
    Digits: Byte;
    Description: string;
    IconURL: string;
    AddressOwner: TAddress;
    function ToString(const Amount: TAmount; WithName: Boolean = False): string;
    function ToAmount(S: string): TAmount;
    class operator Implicit(const Token: TToken): TBytes;
    class function From(const Bytes: TBytes; var Offset: Integer): TToken; static;
  end;

  TTokenBalance = record
    Token: TToken;
    Balance: UInt64;
  end;

  TRewardInfo = record
    TypeName: string;
    Address: string;
    Amount: TAmount;
  end;

  TStakingInfo = record
    RewardAmount: TAmount;
    Days: Integer;
  end;

  TTransactionInfo = record
    Id: UInt64;
    No: UInt32;
    DateTime: TUnixTimestamp;
    TxType: string;
    AddressFrom: string;
    AddressTo: string;
    IndexFrom: UInt64;
    IndexTo: UInt64;
    Amount: TAmount;
    Hash: string;
    Fee: TAmount;
    Rewards: TArray<TRewardInfo>;
    Name: string;
    Ticker: string;
    Decimals: Byte;
    Description: string;
    IconURL: string;
  end;

  TBlockInfo = record
    Id: UInt64;
    Nonce: UInt64;
    IndexTo: UInt64;
    DateTime: TUnixTimestamp;
    Address: string;
    Reward: TAmount;
    StakeAmount: TAmount;
    PrevHash: string;
    Hash: string;
  end;

  TTxFilterPredicate = reference to procedure(const Tx: TTransactionInfo; var Continued: Boolean);

implementation

function TToken.ToString(const Amount: TAmount; WithName: Boolean = False): string;
begin
  Result := Amount.ToString.PadLeft(Digits + 1, '0');
  Result := Result.Insert(Result.Length - Digits, '.');
  if WithName then
    Result := Result + ' ' + Name;
end;

function TToken.ToAmount(S: string): TAmount;
begin
  var I := S.IndexOfAny(['.',',']);
  if I = -1 then
    I := S.Length
  else
    S := S.Remove(I, 1);
  Result := (S + string.Create('0', Digits)).Substring(0, I + Digits).ToInt64;
end;

class operator TToken.Implicit(const Token: TToken): TBytes;
begin
  Result :=
    Tcode.BytesOf<UInt64>(Token.Id)
  + TCode.BytesOf(Token.Ticker)
  + TCode.BytesOf(Token.Name)
  + TCode.BytesOf(Token.Digits)
  + TCode.BytesOf(Token.Description)
  + TCode.BytesOf(Token.IconURL)
  + TCode.BytesOf(Token.AddressOwner);
end;

class function TToken.From(const Bytes: TBytes; var Offset: Integer): TToken;
begin
  Result.Id := TCode.ValueOf<UInt64>(Bytes, Offset);
  Result.Ticker := TCode.StringOf(Bytes, Offset);
  Result.Name := TCode.StringOf(Bytes, Offset);
  Result.Digits := TCode.ValueOf<Byte>(Bytes, Offset);
  Result.Description := TCode.StringOf(Bytes, Offset);
  Result.IconURL := TCode.StringOf(Bytes, Offset);
  Result.AddressOwner := TCode.ValueOf<TAddress>(Bytes, Offset);
end;

end.
