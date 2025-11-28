unit Miner.Utils;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Threading,
  System.Hash,
  Blockchain.Types;

function GetNonceHash(const Nonce: UInt64; const Data: TBytes): TBytes;
function HashDifficulty(const Hash: TBytes): UInt64;
function CalcDifficulty(StakingAmount: TAmount): UInt64;

implementation

procedure Reverse(Source: PByte; Length: Integer; Dest: PByte);
begin
  for var I in [0..Length - 1] do
    Dest[Length - I - 1] := Source[I];
end;

function CalcDifficulty(StakingAmount: TAmount): UInt64;
begin
  Result := $000000FFF0000000 + StakingAmount;
end;

function HashDifficulty(const Hash: TBytes): UInt64;
begin
  Reverse(@Hash[0], SizeOf(Result), @Result); // to Little-Endian
end;

function GetNonceHash(const Nonce: UInt64; const Data: TBytes): TBytes;
begin
  var Hash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
  Hash.Update(BytesOf(@Nonce, SizeOf(Nonce)) + Data);
  Result := Hash.HashAsBytes;
end;

end.
