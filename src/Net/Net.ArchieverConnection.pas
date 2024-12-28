unit Net.ArchieverConnection;

interface

uses
  App.Exceptions,
  App.Intf,
  Crypto,
  Net.Data,
  Net.Socket,
  Sync.Base,
  SysUtils;

type
  TArchieverConnection = class(TSyncChain)
    private
      FAddress: string;
      FPort: Word;

      function GetFullAddress: string;
      function GetValidationRequest: string;
    protected
      procedure Execute; override;
    public
      constructor Create(AAddress: string; APort: Word);
      destructor Destroy; override;

      function SendRequest(const ABytes: TBytes): string;

      property FullAddress: string read GetFullAddress;
  end;

implementation

{ TArchieverConnection }

constructor TArchieverConnection.Create(AAddress: string; APort: Word);
begin
  inherited Create(AAddress, APort);

  FAddress := AAddress;
  FPort := APort;
  FSocket.ReceiveTimeout := -1;
end;

destructor TArchieverConnection.Destroy;
begin

  inherited;
end;

procedure TArchieverConnection.Execute;
var
  CommandByte: Byte;
begin
  inherited;
  FSocket.Send([ValidatorConnection], 0, 1);

  repeat
    while not Terminated and (FSocket.ReceiveLength = 0) do
      BreakableSleep(200);
    if Terminated then
      exit;

    FSocket.Receive(CommandByte, 0, 1, [TSocketFlag.WAITALL]);
    case CommandByte of
      ValidateCommandCode: GetValidationRequest;
    end;

  until Terminated;

  try
//    FSocket.Receive(CommandByte, 0, 1, [TSocketFlag.WAITALL]);

    if Status = 0 then
      FSocket.Send([DisconnectingCode], 0, 1);
  except
    on E:EReceiveTimeout do
      if not DoTryReconnect then
        raise;
  end;
end;

function TArchieverConnection.GetValidationRequest: string;
var
  IncomCountBytes: array[0..3] of Byte;
  IncomCount: Integer absolute IncomCountBytes;
  IncomBytes: TBytes;
  IncomStr: string;
  Splitted: TArray<string>;
  PrKey, PubKey, Sign: string;
begin
  FSocket.Receive(IncomCountBytes, 0, 4, [TSocketFlag.WAITALL]);
  SetLength(IncomBytes, IncomCount);
  FSocket.Receive(IncomBytes, 0, IncomCount, [TSocketFlag.WAITALL]);

  IncomStr := TEncoding.ANSI.GetString(Copy(IncomBytes, 0, Length(IncomBytes) - 65));
  Splitted := IncomStr.Trim.Split([' '], '<', '>');
  if ECDSACheckTextSign(Splitted[0].Trim(['<','>']), Splitted[1],
    Copy(IncomBytes, Length(IncomBytes) - 65, 65)) then
  begin
    AppCore.TryExtractKeysFromFile(PrKey, PubKey);
    ECDSASignText(Splitted[1], HexToBytes(PrKey), Sign);
    FSocket.Send([ValidationDoneCode]);
    FSocket.Send(Sign);
  end else
    FSocket.Send([ValidationDoneCode, ErrorCode]);
end;

function TArchieverConnection.GetFullAddress: string;
begin
  Result := Format('%s:%d', [FAddress, FPort]);
end;

function TArchieverConnection.SendRequest(const ABytes: TBytes): string;
var
  IncomCountBytes: array[0..3] of Byte;
  IncomCount: Integer absolute IncomCountBytes;
  Received: TBytes;
begin
  FSocket.Send(ABytes, 0, Length(ABytes));

  FSocket.Receive(IncomCountBytes, 0, 4, [TSocketFlag.WAITALL]);
  SetLength(Received, IncomCount);
  GetResponse(Received);
  Result := TEncoding.ANSI.GetString(Received);
end;

end.
