unit App.Mutex;

interface

uses
  Classes,
  SysUtils,
  IOUtils;

type
  TMutex = class
  private
    FFilePath: string;
    FFileStream: TFileStream;
  public
    constructor Create(const AName: string);
    destructor Destroy; override;
  end;

implementation

function GetTempDir: string;
begin
  Result := TPath.Combine(TPath.GetTempPath,'tmp');
end;

{ TMutex }

constructor TMutex.Create(const AName: string);
var
  LMask: UInt16;
begin
  if not DirectoryExists(GetTempDir) then
    TDirectory.CreateDirectory(GetTempDir);

  FFilePath := IncludeTrailingPathDelimiter(GetTempDir) + AName + '.pid';
  LMask := fmOpenReadWrite or fmShareExclusive;
  if not FileExists(FFilePath) then
    LMask := LMask or fmCreate;
  FFileStream := TFileStream.Create(FFilePath, LMask);
end;

destructor TMutex.Destroy;
begin
  FFileStream.Free;

  inherited;
end;

end.
