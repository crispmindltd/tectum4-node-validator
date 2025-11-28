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
  Crypto,
  Crypto.EthereumSigner,
  Net.Intf,
  Net.SocketA,
  Net.Peer,
  Net.Event,
  App.Types,
  App.Logs,
  App.Exceptions,
  App.Intf,
  Net.Data;

type
  TRequestTask = record
    Id: UInt64;
    PacketType: TNetPacketType;
    Wait: IWait;
    CallbackProc: TProc<TBytes,Boolean>;
  end;

  TRequest = record
    Id: UInt64;
    PacketType: TNetPacketType;
    Body: TBytes;
  end;

  TQueueTask = record
    ExecuteTime: UInt64;
    Proc: TProc;
  end;

  TCustomHandler = class(TNoRefCountObject, IConnection)
  private class var
    FId: UInt64;
  private class var
    Timer: TStopwatch;
  private
    FClient: TConnection;
    FOnLog: TLogEvent;
  protected
    FState: TConnectionState;
    FReceiverName: string;
    FData: TBytes;
    FNetCore: INetCore;
    FRequests: TArray<TRequestTask>;
    FQueue: TArray<TQueueTask>;
    FQueueLock: TObject;
    procedure Send(const AData: TBytes);
    function GetRequestFor(Id: UInt64; const BodyResult: TBytes; out Request: TRequestTask): Boolean;
    function GenRequestId: UInt64;
    function ExtractRequest(out Request: TRequest): Boolean;
    function CreateResponse(PacketType: TNetPacketType; Body: TBytes = nil): TBytes; overload;
    function CreateResponse(Id: UInt64; PacketType: TNetPacketType; Body: TBytes = nil): TBytes; overload;
    function CreateRequest(PacketType: TNetPacketType; Body: TBytes; Wait: IWait = nil;
      CallbackProc: TProc<TBytes,Boolean> = nil): TBytes; overload;
    procedure AddQueue(Proc: TProc; DelayMilliseconds: Uint64);
    procedure DoReceiveClient(Client: TConnection; const Bytes: TBytes);
    procedure DoReceived(const Request: TRequest); virtual; abstract;
    function GetReceiverName: string;
    function GetState: TConnectionState;
  public
    constructor Create(Client: TConnection; NetCore: INetCore);
    destructor Destroy; override;
    procedure DoQueue;
    procedure SendRequest(PacketType: TNetPacketType; Body: TBytes; Wait: IWait = nil; CallbackProc: TProc<TBytes,Boolean> = nil);
    procedure SendResponse(Id: UInt64; PacketType: TNetPacketType; Body: TBytes = nil); overload;
    procedure SendResponse(PacketType: TNetPacketType; Body: TBytes = nil); overload;
    function DoRequest(PacketType: TNetPacketType; const Body: TBytes): TBytes;
    property ReceiverName: string read GetReceiverName;
    property State: TConnectionState read GetState;
    property Client: TConnection read FClient;
    property OnLog: TLogEvent read FOnLog write FOnLog;
  end;

implementation

constructor TCustomHandler.Create(Client: TConnection; NetCore: INetCore);
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

procedure TCustomHandler.Send(const AData: TBytes);
begin
  FClient.Send(AData);
end;

procedure TCustomHandler.SendRequest(PacketType: TNetPacketType; Body: TBytes; Wait: IWait = nil; CallbackProc: TProc<TBytes,Boolean> = nil);
begin
  Send(CreateRequest(PacketType, Body, Wait, CallbackProc));
  Logs.DoLog('Request sent', INFO);
end;

procedure TCustomHandler.SendResponse(Id: UInt64; PacketType: TNetPacketType; Body: TBytes = nil);
begin
  Send(CreateResponse(Id, PacketType, Body));
end;

procedure TCustomHandler.SendResponse(PacketType: TNetPacketType; Body: TBytes = nil);
begin
  Send(CreateResponse(PacketType, Body));
end;

function TCustomHandler.DoRequest(PacketType: TNetPacketType; const Body: TBytes): TBytes;
begin
  var Wait := TWait.Create as IWait;
  SendRequest(PacketType, Body, Wait);
  Wait.ResultBytes := BytesOf('Timeout');

  if Wait.WaitFor(86400000) then
    if Wait.Success then
      Result:= Wait.ResultBytes
    else
      raise Exception.Create(StringOf(Wait.ResultBytes))
  else
    raise ERequestTimeout.Create(StringOf(Wait.ResultBytes));
end;

function TCustomHandler.GetRequestFor(Id: UInt64; const BodyResult: TBytes; out Request: TRequestTask): Boolean;
var
  isSuccess: Boolean;
  DataResult: TBytes;
begin
  Result := False;
  Lock(Self);

  for var I := 0 to High(FRequests) do
    if FRequests[I].Id = Id then begin
      Request := FRequests[I];
      Delete(FRequests, I, 1);
      if Request.PacketType in ResponseWithResultCodes then begin
        isSuccess := TNetPacketType(BodyResult[0]) = ptSuccess;
        DataResult := Copy(BodyResult, 1);
      end else begin
        isSuccess := True;
        DataResult := BodyResult;
      end;
      if Assigned(Request.Wait) then begin
        Request.Wait.Success := isSuccess;
        Request.Wait.ResultBytes := DataResult;
        Request.Wait.Complete;
      end;
      // Attention! The callback function will be executed in lock mode.
      if Assigned(Request.CallbackProc) then
        Request.CallbackProc(DataResult, isSuccess);
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
  // [DataLength: Integer][Data: Bytes]...[DataLength: Integer][Data: Bytes]
  //                     |
  // Step 1:             Offset
  // Step 2: Read Data [Id: UInt64][Command: Byte][Body: Bytes]
  Request := Default(TRequest);
  Result := Length(FData) >= SizeOf(Integer);

  if Result then begin
    var Offset := Integer(0);
    var DataLength := TCode.ValueOf<Integer>(FData, Offset);

    Result := (DataLength > 0) and (Length(FData) >= Offset + DataLength);

    if Result then begin
      Request.Id := TCode.ValueOf<UInt64>(FData, Offset);
      Request.PacketType := TCode.ValueOf<TNetPacketType>(FData, Offset);
      var BodyLength := DataLength - Offset + SizeOf(DataLength);
      if BodyLength > 0 then
        Request.Body := BytesOf(@FData[Offset], BodyLength);

      Delete(FData, 0, SizeOf(DataLength) + DataLength);
    end;
  end;

end;

function TCustomHandler.CreateResponse(PacketType: TNetPacketType; Body: TBytes = nil): TBytes;
begin
  Result := CreateResponse(UInt64.MaxValue, PacketType, Body);
end;

type
  THeader = packed record
    Id: UInt64;
    PacketType: TNetPacketType;
  end;

function TCustomHandler.CreateResponse(Id: UInt64; PacketType: TNetPacketType; Body: TBytes): TBytes;
var Header: THeader;
begin
  Header.Id := Id;
  Header.PacketType := PacketType;
  Result := TCode.BytesOf(Header) + Body;
  var L: Integer := Length(Result);
  Result := TCode.BytesOf(L) + Result;
end;

function TCustomHandler.CreateRequest(PacketType: TNetPacketType; Body: TBytes; Wait: IWait = nil;
  CallbackProc: TProc<TBytes,Boolean> = nil): TBytes;
begin
  var RequestId := GenRequestId;

  Result := CreateResponse(RequestId, PacketType, Body);

  var RequestTask: TRequestTask;

  RequestTask.Id := RequestId;
  RequestTask.PacketType := PacketType;
  RequestTask.Wait := Wait;
  RequestTask.CallbackProc := CallbackProc;

  Lock(Self);

  FRequests := FRequests + [RequestTask];

  Logs.DoLog(Format('Request created, length = %d bytes',[Length(Result)]), INFO);
end;

procedure TCustomHandler.DoReceiveClient(Client: TConnection; const Bytes: TBytes);
var Request: TRequest;
begin
  FData := FData + Bytes;
  while ExtractRequest(Request) do
    DoReceived(Request);
end;

initialization
  TCustomHandler.Timer := TStopwatch.StartNew;

end.
