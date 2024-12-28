unit App.Logs;

interface

uses
  Classes,
  IOUtils,
  SyncObjs,
  SysUtils;

type
  TLogType = (ltIncom, ltOutgo, ltNone, ltError);

  TLog = class
    const
      MainLogsFolderName = 'logs';
    private
      FPath: string;
      FLogNum: Int64;
      FLock: TCriticalSection;

      function CutLogString(const ALogStr: string): string;
    public
      constructor Create;
      destructor Destroy; override;

      procedure DoLog(AText: string; AType: TLogType = ltIncom);
  end;

var
  Logs: TLog;

implementation

{ TLog }

constructor TLog.Create;
begin
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

procedure TLog.DoLog(AText: string; AType: TLogType);
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
  FLock.Enter;
  ToLog := TStringBuilder.Create;
  try
    if not DirectoryExists(FPath) then
      TDirectory.CreateDirectory(FPath);

    i := 0;
    FileName := TPath.Combine(FPath, FormatDateTime('yyyy.mm.dd', Now) + '.log');
    while FileExists(FileName) and (GetFileSize(FileName) >= 2097152) do  //group the logs into files no larger than 2 megabytes
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

    TFile.AppendAllText(FileName, ToLog.ToString.Replace(#10, '#10', [rfReplaceAll]).
                                                 Replace(#13, '#13', [rfReplaceAll]) + #13#10, TEncoding.ANSI);
    Inc(FLogNum);
  finally
    FreeAndNil(ToLog);
    FLock.Leave;
  end;
end;

end.

