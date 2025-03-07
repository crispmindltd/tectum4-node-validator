unit Net.CustomHandler;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.SyncObjs,
  System.Threading,
  System.DateUtils,
  System.Diagnostics,
  System.Net.Socket,
  Net.Intf,
  Net.SocketA,
  Net.Peer,
  Net.Event,
  Net.Types,
  App.Types,
  App.Logs,
  App.Intf,
  Net.Data;

type
  TRequestTask = record
    Id: UInt64;
    CommandCode: Byte;
    Wait: IWait;
    CallbackProc: TProc<TBytes,Boolean>;
  end;

  TRequest = record
    Id: UInt64;
    CommandCode: Byte;
    Body: TBytes;
  end;

  TQueueTask = record
    ExecuteTime: UInt64;
    Proc: TProc;
  end;

  EReceivedException = class(Exception);

  TCustomHandler = class(TNoRefCountObject, IConnection)
  private class var
    FId: UInt64;
  private class var
    Timer: TStopwatch;
  private
    FClient: TSameClient;
    FOnLog: TLogEvent;
  protected
    FState: TConnectionState;
    FReceiverName: string;
    Data: TBytes;
    FNetCore: INetCore;
    FRequests: TArray<TRequestTask>;
    FQueue: TArray<TQueueTask>;
    FQueueLock: TObject;
    procedure Send(const Data: TBytes);
    function GetRequestFor(Id: UInt64; const BodyResult: TBytes; out Request: TRequestTask): Boolean;
    function GenRequestId: UInt64;
    function ExtractRequest(out Request: TRequest): Boolean;
    function CreateResponse(CommandCode: Byte; Body: TBytes = nil): TBytes; overload;
    function CreateResponse(Id: UInt64; CommandCode: Byte; Body: TBytes = nil): TBytes; overload;
    function CreateRequest(CommandCode: Byte; Body: TBytes; Wait: IWait = nil;
      CallbackProc: TProc<TBytes,Boolean> = nil): TBytes; overload;
    procedure AddQueue(Proc: TProc; DelayMilliseconds: Uint64);
    procedure DoReceiveClient(Client: TSameClient; const Bytes: TBytes);
    procedure DoReceived(const Request: TRequest); virtual; abstract;
    function GetReceiverName: string;
    function GetState: TConnectionState;
  public
    constructor Create(Client: TSameClient; NetCore: INetCore);
    destructor Destroy; override;
    procedure DoQueue;
    procedure SendRequest(CommandCode: Byte; Body: TBytes; Wait: IWait = nil; CallbackProc: TProc<TBytes,Boolean> = nil);
    procedure SendResponse(Id: UInt64; CommandCode: Byte; Body: TBytes = nil); overload;
    procedure SendResponse(CommandCode: Byte; Body: TBytes = nil); overload;
    function DoRequest(CommandCode: Byte; const Body: TBytes): TBytes;
    property ReceiverName: string read GetReceiverName;
    property State: TConnectionState read GetState;
    property Client: TSameClient read FClient;
    property OnLog: TLogEvent read FOnLog write FOnLog;
  end;

implementation

constructor TCustomHandler.Create(Client: TSameClient; NetCore: INetCore);
begin
  FState := TConnectionState.None;
  FQueueLock := TObject.Create;
  FNetCore := NetCore;
  FClient := Client;
  Client.OnReceive := DoReceiveClient;
end;

destructor TCustomHandler.Destroy;
begin
  FQueueLock.Free;
  inherited;
end;

function TCustomHandler.GetReceiverName: string;
begin
  Result := FReceiverName;
end;

function TCustomHandler.GetState: TConnectionState;
begin
  Result := FState;
end;

procedure TCustomHandler.Send(const Data: TBytes);
begin
  FClient.Send(Data);
end;

procedure TCustomHandler.SendRequest(CommandCode: Byte; Body: TBytes; Wait: IWait = nil; CallbackProc: TProc<TBytes,Boolean> = nil);
begin
   Send(CreateRequest(CommandCode, Body, Wait, CallbackProc));
end;

procedure TCustomHandler.SendResponse(Id: UInt64; CommandCode: Byte; Body: TBytes = nil);
begin
  Send(CreateResponse(Id, CommandCode, Body));
end;

procedure TCustomHandler.SendResponse(CommandCode: Byte; Body: TBytes = nil);
begin
  Send(CreateResponse(CommandCode, Body));
end;

function TCustomHandler.DoRequest(CommandCode: Byte; const Body: TBytes): TBytes;
begin

  var Wait := TWait.Create as IWait;

  SendRequest(CommandCode, Body, Wait);

  Wait.ResultBytes := BytesOf('No response');

  if Wait.WaitFor(5000) then
    Result:= Wait.ResultBytes
  else
    raise EReceivedException.Create(StringOf(Wait.ResultBytes));

end;

function TCustomHandler.GetRequestFor(Id: UInt64; const BodyResult: TBytes; out Request: TRequestTask): Boolean;
var
  Success: Boolean;
  DataResult: TBytes;
begin

  Result := False;

  Lock(Self);

  for var I := 0 to High(FRequests) do
  if FRequests[I].Id = Id then
  begin
    Request := FRequests[I];
    Delete(FRequests, I, 1);
    if Request.CommandCode in ResponseWithResultCodes then
    begin
      Success := BodyResult[0] = SuccessCode;
      DataResult := Copy(BodyResult,1);
    end else begin
      Success := True;
      DataResult := BodyResult;
    end;
    if Assigned(Request.Wait) then
    begin
      Request.Wait.Success := Success;
      Request.Wait.ResultBytes := DataResult;
      Request.Wait.Complete;
    end;
    // Attention! The callback function will be executed in lock mode.
    if Assigned(Request.CallbackProc) then
      Request.CallbackProc(DataResult, Success);
    Exit(True);
  end;

end;

function TCustomHandler.GenRequestId: UInt64;
begin
  Result := AtomicIncrement(FId);
end;

procedure TCustomHandler.DoQueue;
begin
  Lock(FQueueLock);
  for var I := High(FQueue) downto 0 do
  if FQueue[I].ExecuteTime < Timer.ElapsedMilliseconds then
  try
    var P := FQueue[I].Proc;
    Delete(FQueue, I, 1);
    P();
  except on E: Exception do
    OnLog('Execute queue proc exception: '+ E.Message, ERROR);
  end;
end;

procedure TCustomHandler.AddQueue(Proc: TProc; DelayMilliseconds: Uint64);
begin
  Lock(FQueueLock);
  var Task: TQueueTask;
  Task.ExecuteTime := Timer.ElapsedMilliseconds + DelayMilliseconds;
  Task.Proc := Proc;
  FQueue := FQueue + [Task];
end;

function TCustomHandler.ExtractRequest(out Request: TRequest): Boolean;
begin

  Request := Default(TRequest);
  Result := Length(Data) >= SizeOf(Integer);

  if Result then
  begin
    var RequestLength := PInteger(Data)^;
    var Offset := SizeOf(RequestLength);
    Result := Length(Data) >= Offset+RequestLength;
    if Result then
    begin
      Request.Id := PUInt64(@Data[Offset])^;
      Inc(Offset, SizeOf(Request.Id));
      Request.CommandCode := Data[Offset];
      Inc(Offset, SizeOf(Request.CommandCode));
      var BodyLength := RequestLength - Offset + SizeOf(RequestLength);
      if BodyLength > 0 then Request.Body := BytesOf(@Data[Offset], BodyLength);
      Delete(Data, 0, SizeOf(RequestLength) + RequestLength);
    end;
  end;

end;

function TCustomHandler.CreateResponse(CommandCode: Byte; Body: TBytes = nil): TBytes;
begin
  Result := CreateResponse(UInt64.MaxValue, CommandCode, Body);
end;

type
  THeader = packed record
    Id: UInt64;
    CommandCode: Byte;
  end;

function TCustomHandler.CreateResponse(Id: UInt64; CommandCode: Byte; Body: TBytes): TBytes;
var Header: THeader;
begin
  Header.Id := Id;
  Header.CommandCode := CommandCode;
  Result := BytesOf(@Header, SizeOf(Header)) + Body;
  var L: Integer := Length(Result);
  Result := BytesOf(@L, SizeOf(L)) + Result;
end;

function TCustomHandler.CreateRequest(CommandCode: Byte; Body: TBytes; Wait: IWait = nil;
  CallbackProc: TProc<TBytes,Boolean> = nil): TBytes;
begin

  var RequestId := GenRequestId;

  Result := CreateResponse(RequestId, CommandCode, Body);

  var RequestTask: TRequestTask;

  RequestTask.Id := RequestId;
  RequestTask.CommandCode := CommandCode;
  RequestTask.Wait := Wait;
  RequestTask.CallbackProc := CallbackProc;

  Lock(Self);

  FRequests := FRequests + [RequestTask];

end;

procedure TCustomHandler.DoReceiveClient(Client: TSameClient; const Bytes: TBytes);
var Request: TRequest;
begin
  Data := Data + Bytes;
  while ExtractRequest(Request) do DoReceived(Request);
end;

initialization
  TCustomHandler.Timer := TStopwatch.StartNew;

end.
