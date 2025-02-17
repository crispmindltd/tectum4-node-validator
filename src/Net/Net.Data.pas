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

  ResponseCode = 1;
  SuccessCode = 2;
  ErrorCode = 3;
  CheckVersionCommandCode = 4;
  InitConnectCode = 5;

  NewTransactionCommandCode = 100;
  ValidateCommandCode = 101;
  ValidationDoneCode = 102;
  NewValidatedTransactionCommandCode = 103;

  GetTxnsCommandCode = 104;
  GetAddressesCommandCode = 105;
  GetValidationsCommandCode = 106;
  GetRewardsCommandCode = 107;

  InitConnectErrorCode = 200;
  KeyAlreadyUsesErrorCode = 201;

  CommandsCodes = [ResponseCode..InitConnectCode,
    CheckVersionCommandCode, NewTransactionCommandCode, ValidateCommandCode,
    ValidationDoneCode, NewValidatedTransactionCommandCode,
    GetTxnsCommandCode..GetRewardsCommandCode,
    InitConnectErrorCode, KeyAlreadyUsesErrorCode];

  NoAnswerNeedCodes = [CheckVersionCommandCode, InitConnectErrorCode,
    KeyAlreadyUsesErrorCode, SuccessCode];

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

function TNodesConnectManager.GetNodesArray: TArray<string>;
begin
  Result := FNodesPool.ToStringArray;
end;

function TNodesConnectManager.GetNodeToConnect: string;
var
  id: Integer;
begin
  if FNodesPool.Count = 0 then
    exit('');

  Randomize;
  id := Random(FNodesPool.Count);
  Result := FNodesPool.Strings[id];
  FNodesPool.Delete(id);
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
