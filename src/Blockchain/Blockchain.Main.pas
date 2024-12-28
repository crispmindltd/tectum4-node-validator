unit Blockchain.Main;

interface

uses
  App.Constants,
  App.Exceptions,
  App.Intf,
  Classes,
  Generics.Collections,
  IOUtils,
  Math,
  SysUtils;

type
  TBlockchain = class
  private

  public
    constructor Create;
    destructor Destroy; override;

  end;

implementation

function SortCompare(AList: TStringList; Index1,
  Index2: Integer): Integer;
begin
  Result := Length(AList[Index1]) - Length(AList[Index2]);
  if Result = 0 then
    Result := AnsiCompareText(AList[Index1],AList[Index2]);
end;

{ TBlockchain }

constructor TBlockchain.Create;
begin

end;

destructor TBlockchain.Destroy;
begin

  inherited;
end;

end.

