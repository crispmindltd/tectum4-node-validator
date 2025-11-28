unit IconUtils;

interface

uses
  App.Types,
  Database.Types,
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  Blockchain.Data;

type
  PNGBufferArr = array[0..7] of Byte;

const
  IconWidthMin = 256;
  IconWidthMax = 512;
  PNGFileSizeMin = 10; //10 bytes
  PNGFileSizeMax = 92160;  //90 kB

procedure DoCheckPNG(const Stream: TStream);
function isValidIcon(const Bytes: TBytes): Boolean;
function IconToBytes(const Filename: string): TBytes;
procedure WriteNewIcon(const IconBytes: TBytes; Ticker: string);

implementation

procedure DoCheckPNG(const Stream: TStream);
var
  Header: array[0..23] of Byte;
const
  PNG_SIGNATURE: PNGBufferArr = ($89, $50, $4E, $47, $0D, $0A, $1A, $0A);
begin
  if (Stream.Size < PNGFileSizeMin) or (Stream.Size > PNGFileSizeMax) then
    raise Exception.Create('Invalid file size');

  Stream.Position := 0;
  Stream.Read(Header, SizeOf(Header));

  if not CompareMem(@Header, @PNG_SIGNATURE, SizeOf(PNG_SIGNATURE)) then
    raise Exception.Create('Invalid file signature');

  const W = (Header[16] shl 24) or (Header[17] shl 16) or (Header[18] shl 8) or Header[19];
  const H = (Header[20] shl 24) or (Header[21] shl 16) or (Header[22] shl 8) or Header[23];

  if (H > IconWidthMax) or (W > IconWidthMax)
    or (H < IconWidthMin) or (W < IconWidthMin) or (H <> W) then
    raise Exception.Create('Invalid file resolution');
end;

function IconToBytes(const Filename: string): TBytes;
var
  FS: TFileStream;
begin
  Result := [];
  if FileName.IsEmpty then exit;

  if not FileExists(Filename) then
    raise Exception.Create('File not exists');

  FS := TFileStream.Create(Filename, fmOpenRead or fmShareDenyWrite);
  AddRelease(FS);
  SetLength(Result, FS.Size);
  if FS.Size > 0 then
    FS.Read(Result[0], FS.Size);
end;

procedure WriteNewIcon(const IconBytes: TBytes; Ticker: string);
begin
  if Length(IconBytes) = 0 then exit;

  var DirPath := System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetAppPath, 'icons');
  if not TDirectory.Exists(DirPath) then
    TDirectory.CreateDirectory(DirPath);

  var FullPath := System.IOUtils.TPath.Combine(DirPath, Ticker.ToLower + '.png');

  if Length(IconBytes) > 0 then begin
    var FS := TFileStream.Create(FullPath, fmCreate);
    AddRelease(FS);
    FS.Write(IconBytes, Length(IconBytes));
  end;
end;

function isValidIcon(const Bytes: TBytes): Boolean;
begin
  Result := True;
  if Length(Bytes) = 0 then exit;

  const MS: TMemoryStream = TMemoryStream.Create;
  AddRelease(MS);
  try
    MS.Position := 0;
    MS.Write(Bytes, Length(Bytes));
    DoCheckPNG(MS);
  except
    Result := False;
  end;
end;

end.
