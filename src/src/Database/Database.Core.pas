unit Database.Core;

interface

uses
  System.Classes,
  System.SysUtils,
  System.IOUtils,
  System.Math,
  System.Hash,
  System.Generics.Defaults,
  System.Generics.Collections,
  Database.Types,
  App.Types;

type
  TFileSignature = UInt32;
  TOffset = Int64;

const
  DATA_SIGNATURE: TFileSignature = $41544144; // DATA
  INDEX_SIGNATURE: TFileSignature = $30584449; // IDX0
  FILE_BOUNDARY = 50 * 1024 * 1024; // 50 Mb

type

  TFileHeader = packed record            // 1024 bytes:
    Sign: TFileSignature;                //    4 bytes
    DataOffset: TOffset;                 //    8 bytes
    DataHeader: array[0..1011] of Byte;  // 1012 bytes
  end;

  TDataHeader = record  // 8 bytes:
    DataNum: Int64;     // 8 bytes
  end;

  TDataFile = record
    FileName: string;
    DataOffset: TOffset;
    DataNum: Int64;
    Data: TStream;
    constructor Create(const Path: string; const DataNum: Int64); overload;
    constructor Create(const FileName: string; const FileHeader: TFileHeader); overload;
    procedure Open;
    procedure Close;
    procedure Append(const Bytes: TBytes);
    procedure AppendRaw(const Bytes: TBytes);
    function Read: TBytes;  // read data record
    function Size: TOffset;
  end;

  TIndexData = record           // 16 bytes:
    DataNum: Int64;             // 8 bytes
    DataOffset: TOffset;        // 8 bytes
    constructor Create(const DataNum: Int64; DataOffset: TOffset);
  end;

  TIndexIn = (Memory, Disk);

  TIndexFile = record
    FileName: string;
    DataOffset: TOffset;
    IndexIn: TIndexIn;
    Data: TStream;
    procedure Open(const Path: string);
    procedure Close;
    function Count: Int64;
    procedure AppendRaw(const Bytes: TBytes);
    function Get(I: Int64): TIndexData;
    function Last: TIndexData;
  end;

  /// <summary>
  ///    This simple database for arbitrary size records
  /// </summary>
  TDatabase = class
  private
    FDataPath: string;
    FDataFiles: TArray<TDataFile>;
    FIndexFile: TIndexFile;
    FIndexIn: TIndexIn;
    procedure InitData;
    procedure SortDataFiles;
    function AddDataFile(const FileName: string; const FileHeader: TFileHeader): TDataFile;
    procedure SetIndexFile(const FileName: string; const FileHeader: TFileHeader);
    function OpenIndexFile: Boolean;
    function CreateDataFile: TDataFile;
    function GetLastDataFile: TDataFile;
    function GetCount: Int64;
    function ReadRawRange(const IndexFrom, IndexTo: TIndexData): TBytes;
  public
    constructor Create(const DataPath: string);
    destructor Destroy; override;
    procedure Open;
    procedure Close;
    procedure AppendData(const Data: TArray<TBytes>);
    procedure AppendRawData(const RawData: TBytes);
    function Read(Index: Int64): TBytes;
    function ReadData(Index, Count: Int64): TArray<TBytes>;
    function ReadRawData(Index, Count: Int64): TBytes;
    function ReadRawSize(Index: Int64; Size: UInt64): TBytes;
    property Count: Int64 read GetCount;
    property IndexIn: TIndexIn read FIndexIn write FIndexIn;
    property DataPath: string read FDataPath;
  end;

implementation

// use Stream.ReadBuffer this raise exception on read error
// Stream.Read or Stream.ReadData not raise exception

function GetUniqueFileName(const Path: string): string;
begin
  repeat
    Result := TPath.Combine(Path, THashBobJenkins.GetHashString(THash.GetRandomString).ToLower);
  until not TFile.Exists(Result);
end;

{ TDataFile }

constructor TDataFile.Create(const Path: string; const DataNum: Int64);
begin

  var FileHeader := Default(TFileHeader);
  FileHeader.Sign := DATA_SIGNATURE;
  FileHeader.DataOffset := SizeOf(TFileHeader);
  var DataHeader:= Default(TDataHeader);
  DataHeader.DataNum := DataNum;
  Move(DataHeader, FileHeader.DataHeader, SizeOf(DataHeader));

  Create(GetUniqueFileName(Path), FileHeader);

  Open;
  AppendRaw(BytesOf(@FileHeader, SizeOf(FileHeader)));
  Close;

end;

constructor TDataFile.Create(const FileName: string; const FileHeader: TFileHeader);
begin
  var DataHeader: TDataHeader;
  Move(FileHeader.DataHeader, DataHeader, SizeOf(DataHeader));
  Self.FileName := FileName;
  Self.DataOffset := FileHeader.DataOffset;
  Self.DataNum := DataHeader.DataNum;
  Self.Data := nil;
end;

procedure TDataFile.Open;
begin
  Data := TFile.Open(FileName, TFileMode.fmOpenOrCreate);
  Data.Seek(0, TSeekOrigin.soEnd);
end;

procedure TDataFile.Close;
begin
  Data.Free;
  Data := nil;
end;

procedure TDataFile.Append(const Bytes: TBytes);
begin
  var Len: TDataLength := Length(Bytes);
  AppendRaw(TCode.BytesOf(Len) + Bytes);
end;

procedure TDataFile.AppendRaw(const Bytes: TBytes);
begin
  Data.WriteData(Bytes, Length(Bytes));
end;

function TDataFile.Read: TBytes;
begin
  var Len: TDataLength;
  Data.ReadBuffer(Len, SizeOf(Len));
  SetLength(Result, Len);
  Data.ReadBuffer(Result, Len);
end;

function TDataFile.Size: Int64;
begin
  if Assigned(Data) then
    Result := Data.Size
  else
    Result := TFile.GetSize(FileName);
end;

{ TIndexData }

constructor TIndexData.Create(const DataNum: Int64; DataOffset: TOffset);
begin
  Self.DataNum := DataNum;
  Self.DataOffset := DataOffset;
end;

{ TIndexFile }

procedure TIndexFile.Open(const Path: string);
begin
  if Assigned(Data) then Exit;

  if FileName.IsEmpty then
    FileName := GetUniqueFileName(Path);

  if IndexIn = Memory then begin
    Data := TMemoryStream.Create;
    if TFile.Exists(FileName) then
      TMemoryStream(Data).LoadFromFile(FileName);
  end else
    Data := TFile.Open(FileName, TFileMode.fmOpenOrCreate);

  if Data.Size = 0 then begin
    var FileHeader := Default(TFileHeader);
    FileHeader.Sign := INDEX_SIGNATURE;
    FileHeader.DataOffset := SizeOf(TFileHeader);
    DataOffset := FileHeader.DataOffset;
    AppendRaw(BytesOf(@FileHeader, SizeOf(FileHeader)));
  end;

end;

procedure TIndexFile.Close;
begin
  if (IndexIn = Memory) and Assigned(Data) then
    TMemoryStream(Data).SaveToFile(FileName);
  Data.Free;
  Data := nil;
end;

function TIndexFile.Count: Int64;
begin
  Result := (Data.Size - DataOffset) div SizeOf(TIndexData);
end;

function TIndexFile.Get(I: Int64): TIndexData;
begin
  Require(I >= 0,'Bad index (' + I.ToString + ')');
  Data.Position := DataOffset + I * SizeOf(TIndexData);
  Data.ReadBuffer(Result, SizeOf(TIndexData));
end;

function TIndexFile.Last: TIndexData;
begin
  Result := Get(Count - 1);
end;

procedure TIndexFile.AppendRaw(const Bytes: TBytes);
begin
  Data.Seek(0, TSeekOrigin.soEnd);
  Data.WriteData(Bytes, Length(Bytes));
end;

{ TBlockchain }

constructor TDatabase.Create(const DataPath: string);
begin
  FDataPath := DataPath;
  ForceDirectories(FDataPath);
  IndexIn := Disk;
end;

destructor TDatabase.Destroy;
begin
  Close;
end;

procedure TDatabase.Open;
begin
  InitData;
end;

procedure TDatabase.Close;
begin
  FIndexFile.Close;
end;

function TDatabase.GetCount: Int64;
begin
  if OpenIndexFile then
    Result := FIndexFile.Count
  else
    Result := 0;
end;

procedure TDatabase.SortDataFiles;
begin
  TArray.Sort<TDataFile>(FDataFiles, TComparer<TDataFile>.Construct(
    function(const L, R: TDataFile): Integer
    begin
      Result:= L.DataNum - R.DataNum;
    end));
end;

procedure TDatabase.InitData;
begin

  FDataFiles := nil;
  FIndexFile := Default(TIndexFile);

  var Files := TDirectory.GetFiles(FDataPath, '*.*');

  for var DataFileName in Files do
  begin
    var F := TFile.OpenRead(DataFileName);
    AddRelease(F);
    var FileHeader: TFileHeader;
    F.Read(FileHeader, SizeOf(FileHeader));
    if FileHeader.Sign = DATA_SIGNATURE then AddDataFile(DataFileName, FileHeader);
    if FileHeader.Sign = INDEX_SIGNATURE then SetIndexFile(DataFileName, FileHeader);
  end;

  SortDataFiles;

end;

function TDatabase.CreateDataFile: TDataFile;
begin
  Result := TDataFile.Create(FDataPath, Length(FDataFiles));
  FDataFiles := FDataFiles + [Result];
end;

function TDatabase.GetLastDataFile: TDataFile;
begin
  var Count := Length(FDataFiles);
  if (Count = 0) or (FDataFiles[Count - 1].Size > FILE_BOUNDARY) then
    Result := CreateDataFile
  else
    Result := FDataFiles[High(FDataFiles)];
end;

function TDatabase.AddDataFile(const FileName: string; const FileHeader: TFileHeader): TDataFile;
begin
  Result := TDataFile.Create(FileName, FileHeader);
  FDataFiles := FDataFiles + [Result];
end;

procedure TDatabase.SetIndexFile(const FileName: string; const FileHeader: TFileHeader);
begin
  FIndexFile.FileName := FileName;
  FIndexFile.DataOffset := FileHeader.DataOffset;
  FIndexFile.Data := nil;
end;

function TDatabase.OpenIndexFile: Boolean;
begin
  Result := Length(FDataFiles) > 0;
  if Result then begin
    FIndexFile.IndexIn := IndexIn;
    FIndexFile.Open(FDataPath);
  end;
end;

type
  PIndexData = ^TIndexData;
  PDataLength = ^TDataLength;

procedure TDatabase.AppendData(const Data: TArray<TBytes>);
begin
  Lock(Self);
  var DataFile := GetLastDataFile;
  DataFile.Open;
  AddFinally(DataFile.Close);
  OpenIndexFile;
  var RawData: TBytes := nil;
  var RawIndex: TBytes := nil;
  // calc data size
  begin
    var DataSize := UInt64(0);
    for var I := 0 to High(Data) do
      Inc(DataSize, SizeOf(TDataLength) + Length(Data[I]));
    // allocate data
    SetLength(RawData, DataSize);
    SetLength(RawIndex, Length(Data) * SizeOf(TIndexData));
  end;
  var FileOffset := DataFile.Size;
  var DataOffset := TOffset(0);
  for var I := 0 to High(Data) do
  begin
    // create indexes
    begin
      var P := PIndexData(@RawIndex[I * SizeOf(TIndexData)]);
      P^.DataNum := DataFile.DataNum;
      P^.DataOffset := FileOffset + DataOffset;
    end;
    // create data
    begin
      var Len: TDataLength := Length(Data[I]);
      var P := PDataLength(@RawData[DataOffset]);
      P^ := Len;
      Inc(DataOffset, SizeOf(Len));
      if Len > 0 then
        Move(Data[I][0], RawData[DataOffset], Len);
      Inc(DataOffset, Len);
    end;
  end;
  DataFile.AppendRaw(RawData);
  FIndexFile.AppendRaw(RawIndex);
end;

procedure TDatabase.AppendRawData(const RawData: TBytes);
begin
  Lock(Self);
  var DataFile := GetLastDataFile;
  DataFile.Open;
  AddFinally(DataFile.Close);
  OpenIndexFile;
  var RawIndex: TBytes := nil;
  // calc index size
  begin
    var I := TOffset(0);
    var DataCount := UInt64(0);
    while I < Length(RawData) do
    begin
      Inc(DataCount);
      // offset to next record
      Inc(I, SizeOf(TDataLength) + PDataLength(@RawData[I])^);
    end;
    SetLength(RawIndex, DataCount * SizeOf(TIndexData));
  end;
  // create indexes
  begin
    var FileOffset := DataFile.Size;
    var Offset := TOffset(0);
    var DataIndex := UInt64(0);
    while Offset < Length(RawData) do
    begin
      var P := PIndexData(@RawIndex[DataIndex * SizeOf(TIndexData)]);
      P^.DataNum := DataFile.DataNum;
      P^.DataOffset := FileOffset + Offset;
      Inc(DataIndex);
      Inc(Offset, SizeOf(TDataLength) + PDataLength(@RawData[Offset])^);
    end;
  end;
  DataFile.AppendRaw(RawData);
  FIndexFile.AppendRaw(RawIndex);
end;

function TDatabase.Read(Index: Int64): TBytes;
begin
  Lock(Self);
  OpenIndexFile;
  var IndexData := FIndexFile.Get(Index);
  var DataFile := FDataFiles[IndexData.DataNum];
  DataFile.Open;
  AddFinally(DataFile.Close);
  DataFile.Data.Position := IndexData.DataOffset;
  Result := DataFile.Read;
end;

// read raw data
// [lenght][data][lenght][data]...[lenght][data][lenght][data]
//               <--------- raw data ---------->
//               |                             |
//               IndexFrom                     IndexTo

function TDatabase.ReadRawRange(const IndexFrom, IndexTo: TIndexData): TBytes;
begin
  Lock(Self);
  Result := nil;
  OpenIndexFile;
  for var DataNum := IndexFrom.DataNum to IndexTo.DataNum do begin
    var DataFile := FDataFiles[DataNum];
    DataFile.Open;
    AddFinally(DataFile.Close);
    var ResultOffset := Length(Result);
    var OffsetFrom := DataFile.DataOffset;
    var OffsetTo := DataFile.Size;
    if IndexFrom.DataNum = DataNum then OffsetFrom := IndexFrom.DataOffset;
    if IndexTo.DataNum = DataNum then OffsetTo := IndexTo.DataOffset;
    var BufferSize := OffsetTo - OffsetFrom;
    SetLength(Result, ResultOffset + BufferSize);
    DataFile.Data.Position := OffsetFrom;
    DataFile.Data.ReadBuffer(Result, ResultOffset, BufferSize);
  end;
end;

// read raw data
// [lenght][data][lenght][data]...[lenght][data][lenght][data]
//               <--- size in bytes (nearly) -->
//               |
//               Index

function TDatabase.ReadRawSize(Index: Int64; Size: UInt64): TBytes;
const
  IndexChunk = UInt64(1000);
begin
  Lock(Self);
  Result := nil;
  OpenIndexFile;
  var IndexFrom := FIndexFile.Get(Index);
  var IndexTo := IndexFrom;
  // calc "to" index for data size
  begin
    var IndexCount := FIndexFile.Count;
    var IndexBuffer: TArray<TIndexData>;
    var DataSize := UInt64(0);
    var IndexPrev := IndexFrom;
    var IndexOffset := TOffset(0);
    for var I := Index + 1 to IndexCount do
    begin
      // index IndexCount does not exists, it is handled individually.
      if I = IndexCount then
        IndexTo.DataOffset := FDataFiles[IndexPrev.DataNum].Size
      else begin
        if IndexOffset > High(IndexBuffer) then begin
          SetLength(IndexBuffer, Min(IndexChunk, IndexCount - I)); // memory indexes buffer
          FIndexFile.Data.ReadBuffer(IndexBuffer[0], Length(IndexBuffer) * SizeOf(TIndexData));
          IndexOffset := 0;
        end;
        IndexTo := IndexBuffer[IndexOffset];
        Inc(IndexOffset);
      end;
      if IndexTo.DataNum = IndexPrev.DataNum then
        DataSize := DataSize + (IndexTo.DataOffset - IndexPrev.DataOffset)
      else // last record in data file
        DataSize := DataSize + (FDataFiles[IndexPrev.DataNum].Size - IndexPrev.DataOffset);
      if DataSize > Size then Break;
      IndexPrev := IndexTo;
    end;
  end;
  Result := ReadRawRange(IndexFrom, IndexTo);
end;

function TDatabase.ReadRawData(Index, Count: Int64): TBytes;
begin
  Result := nil;
  if Count = 0 then Exit;
  Lock(Self);
  OpenIndexFile;
  var IndexFrom := FIndexFile.Get(Index);
  var IndexTo := FIndexFile.Get(Index + Count - 1);
  if Index + Count = FIndexFile.Count then
    // offset to eof
    IndexTo.DataOffset := FDataFiles[IndexTo.DataNum].Size
  else
    // to next index
    IndexTo := FIndexFile.Get(Index + Count);
  Result := ReadRawRange(IndexFrom, IndexTo);
end;

// read data array
// [lenght][data][lenght][data]...[lenght][data][lenght][data]
//               |                             |
//               Index                         Index + Count

function TDatabase.ReadData(Index, Count: Int64): TArray<TBytes>;
begin
  Result := nil;
  if Count = 0 then Exit;
  Lock(Self);
  OpenIndexFile;
  var IndexFrom := FIndexFile.Get(Index);
  var IndexTo := FIndexFile.Get(Index + Count - 1);
  if Index + Count = FIndexFile.Count then
    // offset to eof
    IndexTo.DataOffset := FDataFiles[IndexTo.DataNum].Size
  else
    // to next index
    IndexTo := FIndexFile.Get(Index + Count);
  var Data := ReadRawRange(IndexFrom, IndexTo);
  var Offset := TOffset(0);
  while Offset < Length(Data) do
  begin
    var Len := PDataLength(@Data[Offset])^;
    Inc(Offset, SizeOf(TDataLength));
    Result := Result + [Copy(Data, Offset, Len)];
    Inc(Offset, Len);
  end;
end;

end.
