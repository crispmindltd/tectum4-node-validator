unit SbpBase58;

{$I ..\Include\SimpleBaseLib.inc}

interface

uses
  Math,
  SbpSimpleBaseLibTypes,
  SbpUtilities,
  SbpBase58Alphabet,
  SbpIBase58Alphabet;

const
    baseLength = Int32(58);
    AlphabetValue = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

function BytesToBase58(const Bytes: TSimpleBaseLibByteArray): String;
function Base58ToBytes(const Text: String): TSimpleBaseLibByteArray;

implementation

{ TBase58 }

function Base58ToBytes(const Text: String): TSimpleBaseLibByteArray;
const
  // https://github.com/bitcoin/bitcoin/blob/master/src/base58.cpp
  reductionFactor = Int32(733);
var
  FAlphabet: IBase58Alphabet;
  textLen, numZeroes, outputLen, carry, resultLen, LowPoint: Int32;
  tempDouble: Double;
  inputPtr, pEnd, pInput: PChar;
  outputPtr, pOutputEnd, pDigit, pOutput: PByte;
  FirstChar, c: Char;
  Value: string;
  output, table: TSimpleBaseLibByteArray;
  chars: TSimpleBaseLibCharArray;
begin
  FAlphabet := TBase58Alphabet.Create(AlphabetValue);
  chars := TUtilities.StringToCharArray(Text);

  result := Nil;
  textLen := System.Length(chars);
  if (textLen = 0) then
  begin
    Exit;
  end;

  inputPtr := PChar(chars);

  pEnd := inputPtr + textLen;
  pInput := inputPtr;
{$IFDEF DELPHIXE3_UP}
  LowPoint := System.Low(String);
{$ELSE}
  LowPoint := 1;
{$ENDIF DELPHIXE3_UP}
  Value := Falphabet.Value;
  FirstChar := Value[LowPoint];
  while ((pInput^ = FirstChar) and (pInput <> pEnd)) do
  begin
    System.Inc(pInput);
  end;

  numZeroes := Int32(pInput - inputPtr);
  if (pInput = pEnd) then
  begin
    System.SetLength(result, numZeroes);
    Exit;
  end;

  tempDouble := ((textLen * reductionFactor) / 1000.0) + 1;
  outputLen := Int32(Round(tempDouble));
  table := Falphabet.ReverseLookupTable;
  System.SetLength(output, outputLen);
  outputPtr := PByte(output);

  pOutputEnd := outputPtr + outputLen - 1;
  while (pInput <> pEnd) do
  begin
    c := pInput^;
    System.Inc(pInput);
    carry := table[Ord(c)] - 1;
    if (carry < 0) then
    begin
      Falphabet.InvalidCharacter(c);
    end;
    pDigit := pOutputEnd;
    while pDigit >= outputPtr do
    begin
      carry := carry + (baseLength * pDigit^);
      pDigit^ := Byte(carry);
      // carry := carry div 256;
      carry := carry shr 8;
      System.Dec(pDigit);
    end;

  end;

  pOutput := outputPtr;
  while ((pOutput <> pOutputEnd) and (pOutput^ = 0)) do
  begin
    System.Inc(pOutput);
  end;

  resultLen := Int32(pOutputEnd - pOutput) + 1;
  if (resultLen = outputLen) then
  begin
    result := output;
    Exit;
  end;
  System.SetLength(result, numZeroes + resultLen);
  System.Move(output[Int32(pOutput - outputPtr)], result[numZeroes], resultLen);

end;

function BytesToBase58(const Bytes: TSimpleBaseLibByteArray): String;
const
  growthPercentage = Int32(138);
var
  FAlphabet: IBase58Alphabet;
  bytesLen, numZeroes, outputLen, Length, carry, i, resultLen: Int32;
  inputPtr, pInput, pEnd, outputPtr, pOutputEnd, pDigit, pOutput: PByte;
  alphabetPtr, resultPtr, pResult: PChar;
  ZeroChar: Char;
  output: TSimpleBaseLibByteArray;
  Value: String;
begin
  FAlphabet := TBase58Alphabet.Create(AlphabetValue);

  result := '';
  bytesLen := System.Length(bytes);
  if (bytesLen = 0) then
  begin
    Exit;
  end;
  inputPtr := PByte(bytes);
  Value := Falphabet.Value;
  alphabetPtr := PChar(Value);

  pInput := inputPtr;
  pEnd := inputPtr + bytesLen;
  while ((pInput <> pEnd) and (pInput^ = 0)) do
  begin
    System.Inc(pInput);
  end;
  numZeroes := Int32(pInput - inputPtr);

  ZeroChar := alphabetPtr^;

  if (pInput = pEnd) then
  begin
    result := StringOfChar(ZeroChar, numZeroes);
    Exit;
  end;

  outputLen := bytesLen * growthPercentage div 100 + 1;
  Length := 0;
  System.SetLength(output, outputLen);
  outputPtr := PByte(output);

  pOutputEnd := outputPtr + outputLen - 1;
  while (pInput <> pEnd) do
  begin
    carry := pInput^;
    i := 0;
    pDigit := pOutputEnd;
    while (((carry <> 0) or (i < Length)) and (pDigit >= outputPtr)) do
    begin
      carry := carry + (256 * pDigit^);
      pDigit^ := Byte(carry mod baseLength);
      carry := carry div baseLength;
      System.Dec(pDigit);
      System.Inc(i);
    end;

    Length := i;
    System.Inc(pInput);
  end;

  System.Inc(pOutputEnd);
  pOutput := outputPtr;
  while ((pOutput <> pOutputEnd) and (pOutput^ = 0)) do
  begin
    System.Inc(pOutput);
  end;

  resultLen := numZeroes + Int32(pOutputEnd - pOutput);
  result := StringOfChar(ZeroChar, resultLen);
  resultPtr := PChar(result);

  pResult := resultPtr + numZeroes;
  while (pOutput <> pOutputEnd) do
  begin
    pResult^ := alphabetPtr[pOutput^];
    System.Inc(pOutput);
    System.Inc(pResult);
  end;

end;

end.
