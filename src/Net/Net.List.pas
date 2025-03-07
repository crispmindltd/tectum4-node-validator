unit Net.List;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  TSafeList<T: class> = class(TEnumerable<T>)
  private
    FItems: TArray<T>;
    function Extract(const Value: T): T;
    type
      TEnumerator = class(TEnumerator<T>)
      private
        FItems: TArray<T>;
        FIndex: NativeInt;
        function GetCurrent: T; inline;
      protected
        function DoGetCurrent: T; override;
        function DoMoveNext: Boolean; override;
      public
        constructor Create(const AList: TSafeList<T>);
        function MoveNext: Boolean; inline;
        property Current: T read GetCurrent;
      end;
  protected
    function DoGetEnumerator: TEnumerator<T>; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const Value: T);
    procedure Remove(const Value: T);
    procedure Clear;
    function Count: NativeInt;
    function GetEnumerator: TEnumerator; reintroduce; inline;
  end;

implementation

constructor TSafeList<T>.Create;
begin
end;

destructor TSafeList<T>.Destroy;
begin
  Clear;
  inherited;
end;

procedure TSafeList<T>.Clear;
begin

  TMonitor.Enter(Self);
  try
    for var Item in Self do Item.Free;
    FItems := nil;
  finally
    TMonitor.Exit(Self);
  end;

end;

procedure TSafeList<T>.Add(const Value: T);
begin

  TMonitor.Enter(Self);
  try
    FItems := FItems + [Value];
  finally
    TMonitor.Exit(Self);
  end;

end;

function TSafeList<T>.Count: NativeInt;
begin

  TMonitor.Enter(Self);
  try
    Result := Length(FItems);
  finally
    TMonitor.Exit(Self);
  end;

end;

function TSafeList<T>.Extract(const Value: T): T;
begin

  Result := nil;

  for var I := 0 to High(FItems) do
  if FItems[I] = Value then
  begin
    Result := FItems[I];
    Delete(FItems, I, 1);
    Exit;
  end;

end;

procedure TSafeList<T>.Remove(const Value: T);
begin

  TMonitor.Enter(Self);
  try
    Extract(Value).Free;
  finally
    TMonitor.Exit(Self);
  end;

end;

function TSafeList<T>.DoGetEnumerator: TEnumerator<T>;
begin
  Result := TEnumerator.Create(Self);
end;

constructor TSafeList<T>.TEnumerator.Create(const AList: TSafeList<T>);
begin
  inherited Create;
  FItems:=AList.FItems;
  FIndex := -1;
end;

function TSafeList<T>.TEnumerator.GetCurrent: T;
begin
  Result := FItems[FIndex];
end;

function TSafeList<T>.TEnumerator.MoveNext: Boolean;
begin
  Result := FIndex < Length(FItems) - 1;
  if Result then
    Inc(FIndex);
end;

function TSafeList<T>.TEnumerator.DoGetCurrent: T;
begin
  Result := Current;
end;

function TSafeList<T>.TEnumerator.DoMoveNext: Boolean;
begin
  Result := MoveNext;
end;

function TSafeList<T>.GetEnumerator: TEnumerator;
begin
  Result := TEnumerator.Create(Self);
end;

end.
