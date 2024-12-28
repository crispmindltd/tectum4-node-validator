unit Net.Data;

interface

uses
  Classes,
  SysUtils;

const
  DefaultNodeAddress = //
    'arch1.open.tectum.io:50000,arch2.open.tectum.io:50000,arch3.open.tectum.io:50000,' //
    + 'arch4.open.tectum.io:50000,arch5.open.tectum.io:50000,arch6.open.tectum.io:50000,' //
    + 'arch7.open.tectum.io:50000,arch8.open.tectum.io:50000,arch9.open.tectum.io:50000,' //
    + 'arch10.open.tectum.io:50000,arch11.open.tectum.io:50000,arch12.open.tectum.io:50000';

  DefaultTCPListenTo = '0.0.0.0:50000';
  DefaultPortHTTP = 8917;

  ImShuttingDownCode = 0;
  ResponseCode = 1;
  ResponseSyncCode = 2;
  SuccessCode = 3;
  ErrorCode = 4;
  InitConnectCode = 5;
  PingCode = 38;
  PongCode = 39;
  CheckVersionCommandCode = 99;

  NewTransactionCommandCode = 100;

  ValidateCommandCode = 101;
  ValidationDoneCode = 102;

  NewValidatedTransactionCommandCode = 103;

  GetTxnsCommandCode = 104;
  GetAddressesCommandCode = 105;
  GetValidationsCommandCode = 106;
  GetRewardsCommandCode = 107;

  KeyAlreadyUsesErrorCode = 200;

type
  TNodesConnectManager = class
  private
    FNodesPool: TStringList;

    function IsPoolEmpty: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddNodeToPool(const ANodeAddress: string);
    function GetNodeToConnect: string;
    function GetAnotherNodeToConnect(const ACurNode: string): string;
    function GetNodesArray: TArray<string>;

    property IsEmpty: Boolean read IsPoolEmpty;
  end;

var
  Nodes: TNodesConnectManager;
  ListenTo: string;
  HTTPPort: Word;

implementation

{ TNodesConnectManager }

procedure TNodesConnectManager.AddNodeToPool(const ANodeAddress: string);
begin
  FNodesPool.Add(ANodeAddress);
end;

constructor TNodesConnectManager.Create;
begin
  FNodesPool := TStringList.Create(dupIgnore, True, False);
end;

destructor TNodesConnectManager.Destroy;
begin
  FNodesPool.Free;

  inherited;
end;

function TNodesConnectManager.GetAnotherNodeToConnect(const ACurNode: string): string;
var
  i: Integer;
begin
  if FNodesPool.Count > 1 then begin
    Randomize;
    repeat
      i := Random(FNodesPool.Count);
    until not FNodesPool.Strings[i].Equals(ACurNode);
    Result := FNodesPool.Strings[i];
  end
  else
    Result := FNodesPool[0];
end;

function TNodesConnectManager.GetNodesArray: TArray<string>;
begin
  Result := FNodesPool.ToStringArray;
end;

function TNodesConnectManager.GetNodeToConnect: string;
begin
  if FNodesPool.Count = 0 then
    exit('');

  Randomize;
  Result := FNodesPool.Strings[Random(FNodesPool.Count)];
end;

function TNodesConnectManager.IsPoolEmpty: Boolean;
begin
  Result := FNodesPool.Count = 0;
end;

initialization

Nodes := TNodesConnectManager.Create;

finalization

Nodes.Free;

end.
