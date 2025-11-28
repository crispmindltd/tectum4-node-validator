unit Blockchain.Utils;

interface

uses
  System.SysUtils;

function AmountToStr(const Amount: UInt64; Ticker: string = ''; Digits: Byte = 8): string;
function StrToAmount(S: string; Digits: Byte = 8): UInt64;
function SafeSub(V, S: UInt64): UInt64;

implementation

var Invariant: TFormatSettings;

function AmountToStr(const Amount: UInt64; Ticker: string = ''; Digits: Byte = 8): string;
begin
  Result := Amount.ToString.PadLeft(Digits + 1, '0');
  Result := Format('%s %s',[Result.Insert(Result.Length - Digits, Invariant.DecimalSeparator), Ticker]).TrimRight([' ']);
end;

function StrToAmount(S: string; Digits: Byte = 8): UInt64;
begin
  var I := S.IndexOfAny(['.',',']);
  if I = -1 then
    I := S.Length
  else
    S := S.Remove(I, 1);
  Result := (S + ''.Create('0', Digits)).Substring(0, I + Digits).ToInt64;
end;

function SafeSub(V, S: UInt64): UInt64;
begin
  if V > S then Result := V - S else Result := 0;
end;

initialization
  Invariant := TFormatSettings.Invariant;

end.
