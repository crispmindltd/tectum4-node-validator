unit Blockchain.Data;

interface

uses
  System.TypInfo,
  System.Generics.Collections,
  System.SyncObjs,
  System.IOUtils,
  System.Hash,
  System.SysUtils,
  System.Classes;

type

  TMemBlock<T> = record
    Data: T;
    class operator Implicit(const AHexStr: string): TMemBlock<T>;
    class operator Implicit(const ABytes: TBytes): TMemBlock<T>;
    class operator Implicit(const AValue: TMemBlock<T>): string;
    class operator Implicit(const AValue: TMemBlock<T>): TBytes;
//    class operator Implicit(const AValue: TMemBlock<T>): T;
//    class operator Implicit(const AValue: T): TMemBlock<T>;
    class operator Equal(a, b: TMemBlock<T>): Boolean;

    function Hash(): TBytes;
    class function LastHash(const AFilename: string): TBytes; static;
    procedure SaveToFile(const AFilename: string); overload; // save data to the end of file
    procedure SaveToFile(const AFilename: string; AId: UInt64); overload;
    class function RecordsCount(const AFilename: string): UInt64; static;
    class function ByteArrayFromFile(const AFilename: string; AIdFrom, AAmount: Integer): TBytes; static;
    class procedure ByteArrayToFile(const AFilename: string; const [Ref] AData: TBytes); static;
    constructor ReadFromFile(const AFilename: string; AId: UInt64);
  end;

  // Private key, Hash
  T32Bytes = TMemBlock < array [0 .. 31] of Byte >;

  TSign = record
    Data: array [0 .. 71] of Byte;
    class operator Implicit(const ABytes: TBytes): TSign;
    class operator Implicit(const AHexStr: string): TSign;
    class operator Implicit(const AValue: TSign): TBytes;
    class operator Implicit(const AValue: TSign): string;
  end;

  TCSMap = class(TObjectDictionary<string, TCriticalSection>)
    constructor Create;
    procedure Enter(const AFilename: string);
    procedure Leave(const AFilename: string);
  end;

const
  _1_TET = UInt64(10000000);
  MinFee = _1_TET div 1000; // 0.001 TET
  MaxFee = _1_TET; // 1 TET
  TET_Id = 0;
  TreasuryId = 0;
  INVALID = UInt64.MaxValue;

var CSMap: TCSMap;

function CalculateFee(ASendValue: UInt64): UInt64;

// возвращает массив сумм вознаграждений соответственно застейканным суммам
function GetRewards(AFee: UInt64; const AStakes: TArray<UInt64>): TArray<UInt64>;

implementation

function CalculateFee(ASendValue: UInt64): UInt64;
begin
  Result := ASendValue div 1000;
  if Result < MinFee then
    Result := MinFee
  else if Result > MaxFee then
    Result := MaxFee;
end;

function GetRewards(AFee: UInt64; const AStakes: TArray<UInt64>): TArray<UInt64>;
begin
  var StakeSum: UInt64 := 0;
  for var Stake in AStakes do
    inc(StakeSum, Stake);

  Assert(StakeSum > 0, 'Sum of all validator`s stakes must not be zero');

  var Remains: UInt64 := AFee;
  for var i := 0 to high(AStakes) do begin
    if i = high(AStakes) then begin
      Result := Result + [Remains];
      Exit;
    end;
    const Reward = (Remains * AStakes[i]) div StakeSum;
    Dec(Remains, Reward);
    Dec(StakeSum, AStakes[i]);
    Result := Result + [Reward];
  end;
end;

{ TMemBlock<T> }

class function TMemBlock<T>.ByteArrayFromFile(const AFilename: string; AIdFrom, AAmount: Integer): TBytes;
begin
  CSMap.Enter(AFilename);
  try
    const fs = TFileStream.Create(AFilename, fmOpenRead);
    begin
    end;
    try
      const readFrom = AIdFrom * SizeOf(T);
      Assert(fs.Size > readFrom, 'Can not read blocks after the end of file');
      fs.Position := readFrom;

      const BufferSize = AAmount * SizeOf(T);
      SetLength(Result, BufferSize);
      const BytesCount = (fs.Read(Result, BufferSize));
      Assert(BytesCount mod SizeOf(T) = 0, 'Incorrect block size on file read');

      SetLength(Result, BytesCount);
    finally
      fs.Free;
    end;
  finally
    CSMap.Leave(AFilename);
  end;
end;

class procedure TMemBlock<T>.ByteArrayToFile(const AFilename: string; const [Ref] AData: TBytes);
begin
  if Length(AData) = 0 then
    Exit;
  const BytesCount = Length(AData);
  Assert(BytesCount mod SizeOf(T) = 0);

  CSMap.Enter(AFilename);
  try
    const fs = TFileStream.Create(AFilename, fmOpenWrite);
    begin
    end;
    try
      const FileBytes = fs.Size;
      Assert(FileBytes mod SizeOf(T) = 0, 'Incorrect block size on file write');
      fs.Seek(0, TSeekOrigin.soEnd);
      fs.Write(AData[0], BytesCount);
    finally
      fs.Free;
    end;
  finally
    CSMap.Leave(AFilename);
  end;
end;

class operator TMemBlock<T>.Equal(a, b: TMemBlock<T>): Boolean;
begin
  Result := CompareMem(@a, @b, SizeOf(T));
end;

class function TMemBlock<T>.RecordsCount(const AFilename: string): UInt64;
begin
  Result := 0;
  if not TFile.Exists(AFilename) then
    Exit;
  const FileBytes = TFile.GetSize(AFilename);
  Assert(FileBytes mod SizeOf(T) = 0, 'Incorrect blockchain file size');
  Result := FileBytes div SizeOf(T);
end;

function TMemBlock<T>.Hash: TBytes;
begin
  const LSHA2 = THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
  LSHA2.Update(Self, SizeOf(T));
  Result := LSHA2.HashAsBytes;
end;

class operator TMemBlock<T>.Implicit(const AValue: TMemBlock<T>): string;
begin
  SetLength(Result, SizeOf(T) * 2);
  BinToHex(AValue.Data, PChar(Result), SizeOf(T));
end;

class operator TMemBlock<T>.Implicit(const ABytes: TBytes): TMemBlock<T>;
begin
  Assert(Length(ABytes) = SizeOf(T), 'incorrect bytes count on converting from bytes');
  Move(ABytes[0], Result, SizeOf(T));
end;

class operator TMemBlock<T>.Implicit(const AHexStr: string): TMemBlock<T>;
begin
  if AHexStr.StartsWith('0x') then
    Exit(AHexStr.Substring(2));
  Assert(Length(AHexStr) = SizeOf(T) * 2, 'incorrect bytes count on converting from Hex string');
  HexToBin(PChar(AHexStr), Result, SizeOf(T));
end;

class operator TMemBlock<T>.Implicit(const AValue: TMemBlock<T>): TBytes;
begin
  SetLength(Result, SizeOf(T));
  Move(AValue.Data, Result[0], SizeOf(T));
end;

class function TMemBlock<T>.LastHash(const AFilename: string): TBytes;
begin
  const LRecordsCount = RecordsCount(AFilename);

  begin
  end;

  if LRecordsCount = 0 then begin
    Result := TBytes(T32Bytes(string.Create('0', 64)));
    Exit;
  end;

  const LastBlock = TMemBlock<T>.ReadFromFile(AFilename, LRecordsCount - 1);
  Result := LastBlock.Hash;
end;

constructor TMemBlock<T>.ReadFromFile(const AFilename: string; AId: UInt64);
begin
  Self := ByteArrayFromFile(AFilename, AId, 1);
end;

procedure TMemBlock<T>.SaveToFile(const AFilename: string; AId: UInt64);
begin
  CSMap.Enter(AFilename);
  try
    const fs = TFileStream.Create(AFilename, fmOpenWrite);
    try
      if fs.Size > AId * SizeOf(T) then begin
        FreeAndNil(fs);
        SaveToFile(AFilename);
      end;
      Assert(fs.Size > AId * SizeOf(T), 'Incorrect block size on file read');
      fs.Position := AId * SizeOf(T);
      fs.Write(Data, SizeOf(T));
    finally
      fs.Free;
    end;
  finally
    CSMap.Leave(AFilename);
  end;
end;

procedure TMemBlock<T>.SaveToFile(const AFilename: string);
begin
  ByteArrayToFile(AFilename, Self);
end;

//class operator TMemBlock<T>.Implicit(const AValue: T): TMemBlock<T>;
//begin
//  Result.Data := AValue;
//end;
//
//class operator TMemBlock<T>.Implicit(const AValue: TMemBlock<T>): T;
//begin
//  Result := AValue.Data;
//end;

{ TSign }
class operator TSign.Implicit(const AValue: TSign): TBytes;
begin
  for var i := 0 to 71 do begin
    if AValue.Data[i] > 0 then begin
      const amountBytes = SizeOf(TSign) - i;
      SetLength(Result, amountBytes);
      Move(AValue.Data[i], Result[0], amountBytes);
      Exit;
    end;
  end;
end;

class operator TSign.Implicit(const ABytes: TBytes): TSign;
begin
  FillChar(Result.Data, SizeOf(TSign), 0);
  const amountBytes = Length(ABytes);
    if amountBytes = 0 then Exit;
  Assert(amountBytes <= SizeOf(TSign), 'too many bytes to convert bytes to sign');
  Move(ABytes[0], Result.Data[SizeOf(TSign) - amountBytes], amountBytes);
end;

class operator TSign.Implicit(const AValue: TSign): string;
begin
  SetLength(Result, SizeOf(TSign) * 2);
  BinToHex(AValue.Data, PChar(Result), SizeOf(TSign));
end;

class operator TSign.Implicit(const AHexStr: string): TSign;
begin
  Assert(Length(AHexStr) mod 2 = 0, 'can not convert hex string with odd size to sign');
  var LBytes:TBytes;
  SetLength(LBytes, Length(AHexStr) div 2);
  HexToBin(PChar(AHexStr), LBytes, SizeOf(TSign));
  Result := LBytes;
end;

{ TCSMap }

constructor TCSMap.Create;
begin
  inherited Create([TDictionaryOwnership.doOwnsValues]); // ownValues
end;

procedure TCSMap.Enter(const AFilename: string);
begin
  var CS: TCriticalSection;
  if not TryGetValue(AFilename, CS) then begin
    CS := TCriticalSection.Create;
    Add(AFilename, CS);
  end;
  CS.Enter;
end;

procedure TCSMap.Leave(const AFilename: string);
begin
  var CS: TCriticalSection;
  Assert(TryGetValue(AFilename, CS), 'don`t know filename: ' + AFilename);
  CS.Leave;
end;

initialization

CSMap := TCSMap.Create;

finalization

CSMap.Free;

end.
