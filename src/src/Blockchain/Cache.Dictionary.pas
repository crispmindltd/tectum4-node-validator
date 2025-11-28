unit Cache.Dictionary;

{$R-,T-,X+,H+,B-}
{$IFDEF WIN32}
//  {$A4}
{$ENDIF}
{$INLINE ON}

interface

uses
  System.Types,
  System.SysUtils,
  System.Classes,
  System.Generics.Defaults,
  System.Generics.Collections;

type
  TDictionary<K,V> = class(TEnumerable<TPair<K,V>>)
  private type
    TItem = record
      HashCode: Integer;
      Key: K;
      Value: V;
      function IsEmpty: Boolean;
      procedure Clear;
    end {$IF Defined(CPU64BITS)} align 4 {$ENDIF CPU64BITS};
    PItem = ^TItem;
    PValue = ^V;
    TItemArray = array of TItem;
  private
    FItems: TItemArray;
    FCount: NativeInt;
    FComparer: IEqualityComparer<K>;
    FGrowThreshold: NativeInt;
    procedure InternalSetCapacity(ACapacity: NativeInt);
    procedure Rehash(NewCapPow2: NativeInt);
    procedure Grow;
    function GetBucketIndex(const Key: K; HashCode: Integer): NativeInt;
    function Hash(const Key: K): Integer;
    function GetIsEmpty: Boolean; inline;
    function Get(const Key: K): PValue;
    procedure DoAdd(HashCode: Integer; Index: NativeInt; const Key: K; const Value: V);
    procedure DoSetValue(Index: NativeInt; const Value: V);
    function GetCapacity: NativeInt;
    procedure SetCapacity(const Value: NativeInt);
    function GetCollisions: NativeInt;
  protected
    function DoGetEnumerator: TEnumerator<TPair<K,V>>; override;
  public
    constructor Create; overload;
    constructor Create(ACapacity: NativeInt); overload;
    constructor Create(ACapacity: NativeInt; const AComparer: IEqualityComparer<K>); overload;
    constructor Create(const AItems: array of TPair<K,V>); overload;
    destructor Destroy; override;
    procedure SetPairs(const AItems: array of TPair<K,V>);
    procedure Add(const Key: K; const Value: V);
    procedure Clear;
    procedure TrimExcess;
    function TryGetValue(const Key: K; var Value: V): Boolean;
    procedure AddOrSetValue(const Key: K; const Value: V);
    function ContainsKey(const Key: K): Boolean;
    function ContainsValue(const Value: V): Boolean;
    function ToArray: TArray<TPair<K,V>>; override; final;
    property Capacity: NativeInt read GetCapacity write SetCapacity;
    property Count: NativeInt read FCount;
    property IsEmpty: Boolean read GetIsEmpty;
    property GrowThreshold: NativeInt read FGrowThreshold;
    property Collisions: NativeInt read GetCollisions;
    property Comparer: IEqualityComparer<K> read FComparer;
    property Items[const Key: K]: PValue read Get; default;

    type
      TPairEnumerator = class(TEnumerator<TPair<K,V>>)
      private
        FDictionary: TDictionary<K,V>;
        FIndex: NativeInt;
        function GetCurrent: TPair<K,V>;
      protected
        function DoGetCurrent: TPair<K,V>; override;
        function DoMoveNext: Boolean; override;
      public
        constructor Create(const ADictionary: TDictionary<K,V>);
        property Current: TPair<K,V> read GetCurrent;
        function MoveNext: Boolean;
      end;

    function GetEnumerator: TPairEnumerator; reintroduce;

  end;

implementation

uses System.SysConst, System.RTLConsts;

const
  EMPTY_HASH = -1;

procedure TDictionary<K, V>.TItem.Clear;
begin
  Self := Default(TItem);
  HashCode := EMPTY_HASH;
end;

function TDictionary<K, V>.TItem.IsEmpty: Boolean;
begin
  Result := HashCode = EMPTY_HASH;
end;

constructor TDictionary<K, V>.Create;
begin
  Create(0, nil);
end;

constructor TDictionary<K,V>.Create(ACapacity: NativeInt);
begin
  Create(ACapacity, nil);
end;

constructor TDictionary<K,V>.Create(ACapacity: NativeInt; const AComparer: IEqualityComparer<K>);
begin
  inherited Create;
  if ACapacity < 0 then
    ErrorArgumentOutOfRange;
  if AComparer = nil then
    FComparer := IEqualityComparer<K>(TEqualityComparer<K>._Default)
  else
  	FComparer := AComparer;
  InternalSetCapacity(ACapacity);
end;

constructor TDictionary<K,V>.Create(const AItems: array of TPair<K,V>);
begin
  Create(Length(AItems), nil);
  for var Item in AItems do
    AddOrSetValue(item.Key, item.Value);
end;

destructor TDictionary<K,V>.Destroy;
begin
  Clear;
  inherited;
end;

procedure TDictionary<K,V>.Rehash(NewCapPow2: NativeInt);
var
  oldItems, newItems: TItemArray;
  i, j: NativeInt;
  P: PItem;
begin
  if NewCapPow2 = Length(FItems) then
    Exit
  else if NewCapPow2 < 0 then
    OutOfMemoryError;

  oldItems := FItems;
  SetLength(newItems, NewCapPow2);
  P := PItem(newItems);
  for i := 0 to Length(newItems) - 1 do
  begin
    P.Clear;
    Inc(P);
  end;
  FItems := newItems;
  FGrowThreshold := NewCapPow2 shr 1; // 50%

  P := PItem(oldItems);
  for i := 0 to Length(oldItems) - 1 do
  begin
    if not P.IsEmpty then
    begin
      j := not GetBucketIndex(P.Key, P.HashCode);
      FItems[j] := P^;
    end;
    Inc(P);
  end;
end;

procedure TDictionary<K,V>.InternalSetCapacity(ACapacity: NativeInt);
var
  newCap: NativeInt;
begin
  if ACapacity < Count then
    ErrorArgumentOutOfRange;

  if ACapacity = 0 then
    Rehash(0)
  else
  begin
    newCap := 4;
    while newCap shr 1 <= ACapacity do // 50%
      newCap := newCap shl 1;
    Rehash(newCap);
  end
end;

function TDictionary<K, V>.GetCapacity: NativeInt;
begin
  Result := Length(FItems);
end;

procedure TDictionary<K, V>.SetCapacity(const Value: NativeInt);
begin
  // Ensure at least one empty slot for GetBucketIndex to terminate.
  if Capacity <> Value + 1 then
    InternalSetCapacity(Value + 1);
end;

procedure TDictionary<K,V>.Grow;
var
  newCap: NativeInt;
begin
  newCap := Length(FItems) * 2;
  if newCap = 0 then
    newCap := 4;
  Rehash(newCap);
end;

function TDictionary<K,V>.GetBucketIndex(const Key: K; HashCode: Integer): NativeInt;
var
  L: NativeInt;
  P: PItem;
begin
  L := Length(FItems);
  if L = 0 then
    Exit(not High(NativeInt));

  Result := HashCode and (L - 1);
  P := @FItems[Result];
  while True do
  begin

    // Not found: return complement of insertion point.
    if P.IsEmpty then
      Exit(not Result);

    // Found: return location.
    if (P.HashCode = HashCode) and FComparer.Equals(P.Key, Key) then
      Exit(Result);

    Inc(Result);
    Inc(P);
    if Result >= L then
    begin
      Result := 0;
      P := @FItems[0];
    end;
  end;
end;

function TDictionary<K,V>.GetCollisions: NativeInt;
var
  L, I: NativeInt;
  P: PItem;
begin
  Result := 0;
  L := Length(FItems) - 1;
  P := PItem(FItems);
  for I := 0 to L do
  begin
    if not P.IsEmpty and ((P.HashCode and L) <> I) then
      Inc(Result);
    Inc(P);
  end;
end;

function TDictionary<K,V>.Hash(const Key: K): Integer;
const
  PositiveMask = Integer.MaxValue;
begin
{$IFOPT Q+}
  {$DEFINE Q_ON}
  {$Q-}
{$ENDIF}
  // Double-Abs to avoid -MaxInt and MinInt problems.
  // Not using compiler-Abs because we *must* get a positive integer;
  // for compiler, Abs(Low(Integer)) is a null op.
  Result := PositiveMask and ((PositiveMask and FComparer.GetHashCode(Key)) + 1);
{$IFDEF Q_ON}
  {$Q+}
  {$UNDEF Q_ON}
{$ENDIF}
end;

function TDictionary<K, V>.GetIsEmpty: Boolean;
begin
  Result := FCount = 0;
end;

procedure TDictionary<K,V>.SetPairs(const AItems: array of TPair<K,V>);
begin
  FCount := 0;
  for var I := 0 to High(FItems) do
    FItems[I].Clear;
  for var Item in AItems do
    AddOrSetValue(item.Key, item.Value);
end;

procedure TDictionary<K,V>.Add(const Key: K; const Value: V);
var
  index: NativeInt;
  hc: Integer;
begin
  if Count >= FGrowThreshold then
    Grow;

  hc := Hash(Key);
  index := GetBucketIndex(Key, hc);
  if index >= 0 then
    raise EListError.CreateRes(@SGenericDuplicateItem);

  DoAdd(hc, not index, Key, Value);
end;

function TDictionary<K,V>.Get(const Key: K): PValue;
var
  hc: Integer;
  index: NativeInt;
begin
  hc := Hash(Key);
  index := GetBucketIndex(Key, hc);
  if index >= 0 then
    Result := @(FItems[Index].Value)
  else
  begin
    // We only grow if we are inserting a new value.
    if Count >= FGrowThreshold then
    begin
      Grow;
      // We need a new Bucket Index because the array has grown.
      index := GetBucketIndex(Key, hc);
    end;
    DoAdd(hc, not index, Key, Default(V));
    Result := @(FItems[not index].Value);
  end;
end;

procedure TDictionary<K,V>.Clear;
begin
  FCount := 0;
  SetLength(FItems, 0);
  InternalSetCapacity(0);
  FGrowThreshold := 0;
end;

function TDictionary<K, V>.ToArray: TArray<TPair<K,V>>;
begin
  Result := ToArrayImpl(Count);
end;

procedure TDictionary<K,V>.TrimExcess;
begin
  // Ensure at least one empty slot for GetBucketIndex to terminate.
  InternalSetCapacity(Count + 1);
end;

function TDictionary<K,V>.TryGetValue(const Key: K; var Value: V): Boolean;
var
  index: NativeInt;
begin
  index := GetBucketIndex(Key, Hash(Key));
  Result := index >= 0;
  if Result then
    Value := FItems[index].Value
  else
    Value := Default(V);
end;

procedure TDictionary<K,V>.DoAdd(HashCode: Integer; Index: NativeInt; const Key: K; const Value: V);
var
  P: PItem;
begin
  P := @FItems[Index];
  P.HashCode := HashCode;
  P.Key := Key;
  P.Value := Value;
  Inc(FCount);
end;

function TDictionary<K, V>.DoGetEnumerator: TEnumerator<TPair<K, V>>;
begin
  Result := GetEnumerator;
end;

procedure TDictionary<K,V>.DoSetValue(Index: NativeInt; const Value: V);
begin
  FItems[Index].Value := Value;
end;

procedure TDictionary<K,V>.AddOrSetValue(const Key: K; const Value: V);
var
  hc: Integer;
  index: NativeInt;
begin
  hc := Hash(Key);
  index := GetBucketIndex(Key, hc);
  if index >= 0 then
    DoSetValue(index, Value)
  else
  begin
    // We only grow if we are inserting a new value.
    if Count >= FGrowThreshold then
    begin
      Grow;
      // We need a new Bucket Index because the array has grown.
      index := GetBucketIndex(Key, hc);
    end;
    DoAdd(hc, not index, Key, Value);
  end;
end;

function TDictionary<K,V>.ContainsKey(const Key: K): Boolean;
begin
  Result := GetBucketIndex(Key, Hash(Key)) >= 0;
end;

function TDictionary<K,V>.ContainsValue(const Value: V): Boolean;
var
  i: NativeInt;
  c: IEqualityComparer<V>;
begin
  c := IEqualityComparer<V>(TEqualityComparer<V>._Default);

  for i := 0 to Length(FItems) - 1 do
    if not FItems[i].IsEmpty and c.Equals(FItems[i].Value, Value) then
      Exit(True);
  Result := False;
end;

// Pairs

constructor TDictionary<K,V>.TPairEnumerator.Create(const ADictionary: TDictionary<K,V>);
begin
  inherited Create;
  FIndex := -1;
  FDictionary := ADictionary;
end;

function TDictionary<K, V>.TPairEnumerator.DoGetCurrent: TPair<K, V>;
begin
  Result := GetCurrent;
end;

function TDictionary<K, V>.TPairEnumerator.DoMoveNext: Boolean;
begin
  Result := MoveNext;
end;

function TDictionary<K,V>.TPairEnumerator.GetCurrent: TPair<K,V>;
begin
  Result.Key := FDictionary.FItems[FIndex].Key;
  Result.Value := FDictionary.FItems[FIndex].Value;
end;

function TDictionary<K,V>.TPairEnumerator.MoveNext: Boolean;
begin
  while FIndex < Length(FDictionary.FItems) - 1 do
  begin
    Inc(FIndex);
    if not FDictionary.FItems[FIndex].IsEmpty then
      Exit(True);
  end;
  Result := False;
end;

function TDictionary<K,V>.GetEnumerator: TPairEnumerator;
begin
  Result := TPairEnumerator.Create(Self);
end;

end.
