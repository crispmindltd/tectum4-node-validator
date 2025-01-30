unit App.Logs;

interface

uses
  Blockchain.Address,
  Blockchain.Reward,
  Blockchain.Txn,
  Blockchain.Validation,
  Classes,
  IOUtils,
  Net.Data,
  SyncObjs,
  SysUtils;

const
  NoneLvlLogs = 0;
  CmnLvlLogs = 1;
  AdvLvlLogs = 2;
  DbgLvlLogs = 3;

type
  TLogType = (ltIncom, ltOutgo, ltNone, ltError);

  TLog = class
    const
      KByte = 1024;
      MByte = KByte * 1024;
      MaxLogFileSize = 2 * MByte;
      MainLogsFolderName = 'logs';
    private
      FLogLevel: Byte;
      FPath: string;
      FLogNum: UInt64;
      FLock: TCriticalSection;

      function CutLogString(const ALogStr: string): string;
    public
      constructor Create(ALogsLevel: Byte = CmnLvlLogs);
      destructor Destroy; override;

      procedure DoLog(AText: string; ALogLevel: Byte; AType: TLogType = ltIncom);
      procedure DoSyncLog(AAddress: string; AReqCode: Byte; ALogBytes: TBytes;
        ALogLevel: Byte; AType: TLogType = ltIncom);
  end;

var
  Logs: TLog;

implementation

{ TLog }

uses
  App.Intf;

constructor TLog.Create(ALogsLevel: Byte);
begin
  FLogLevel := ALogsLevel;
  FPath := TPath.Combine(ExtractFilePath(ParamStr(0)), MainLogsFolderName);
  FLogNum := 0;
  FLock := TCriticalSection.Create;
end;

function TLog.CutLogString(const ALogStr: string): string;
var
  len: Integer;
begin
  len := Length(ALogStr);
  if len <= 600 then
    Result := ALogStr
  else
    Result := Format('%s ... %s', [ALogStr.Substring(0, 300),
      ALogStr.Substring(len - 300, 300)]);
end;

destructor TLog.Destroy;
begin
  FLock.Free;

  inherited;
end;

procedure TLog.DoSyncLog(AAddress: string; AReqCode: Byte; ALogBytes: TBytes;
  ALogLevel: Byte; AType: TLogType);
var
  ToLog: string;
begin
  if (ALogLevel > FLogLevel) or (FLogLevel = NoneLvlLogs) or (ALogLevel = NoneLvlLogs) or
    (Length(ALogBytes) = 0) then
    exit;

  case AReqCode of
    GetTxnsCommandCode:
      ToLog := Format('<%s>[%d]: %d blocks',
        [AAddress, AReqCode, Length(ALogBytes) div SizeOf(TTxn)]);

    GetAddressesCommandCode:
      ToLog := Format('<%s>[%d]: %d blocks',
        [AAddress, AReqCode, Length(ALogBytes) div SizeOf(TAccount)]);

    GetValidationsCommandCode:
      ToLog := Format('<%s>[%d]: %d blocks',
        [AAddress, AReqCode, Length(ALogBytes) div SizeOf(TValidation)]);

    GetRewardsCommandCode:
      ToLog := Format('<%s>[%d]: %d blocks',
        [AAddress, AReqCode, Length(ALogBytes) div SizeOf(TReward)]);
  end;

  DoLog(ToLog, ALogLevel, AType);
end;

procedure TLog.DoLog(AText: string; ALogLevel: Byte; AType: TLogType);
var
  FileName: string;
  i: Integer;
  ToLog: TStringBuilder;

  function GetFileSize(APath: string): Int64;
  var
    FS: TFileStream;
  begin
    try
      FS := TFileStream.Create(APath, fmOpenRead);
      try
        Result := FS.Size;
      finally
        FS.Free;
      end;
    except
      Result := -1;
    end;
  end;

begin
  if (ALogLevel > FLogLevel) or (FLogLevel = NoneLvlLogs) or (ALogLevel = NoneLvlLogs) then
    exit;

  FLock.Enter;
  ToLog := TStringBuilder.Create;
  try
    if not DirectoryExists(FPath) then
      TDirectory.CreateDirectory(FPath);

    i := 0;
    FileName := TPath.Combine(FPath, FormatDateTime('yyyy.mm.dd', Now) + '.log');
    while FileExists(FileName) and (GetFileSize(FileName) >= MaxLogFileSize) do  //group the logs into files no larger than 2 megabytes
    begin
      FileName := Format('%s(%d).log', [TPath.Combine(FPath, FormatDateTime('yyyy.mm.dd', Now) + '.log'), i]);
      Inc(i);
    end;

    ToLog.Append(FLogNum.ToString);
    ToLog.Append(#9);
    ToLog.Append(FormatDateTime('dd.mm.yy hh:mm:ss:zzz', Now));
    case AType of
      ltIncom:
        ToLog.Append(' <- ');
      ltOutgo:
        ToLog.Append(' -> ');
      ltNone:
        ToLog.Append(' -- ');
      ltError:
        ToLog.Append(' !! ');
    end;
    ToLog.Append(CutLogString(AText));

    UI.DoMessage(ToLog.ToString);
    TFile.AppendAllText(FileName, ToLog.ToString + sLineBreak, TEncoding.ANSI);
    Inc(FLogNum);
  finally
    FreeAndNil(ToLog);
    FLock.Leave;
  end;
end;

end.

