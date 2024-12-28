unit Blockchain.ICODat;

interface

uses
  App.Constants,
  Blockchain.BaseTypes,
  Blockchain.Intf,
  Classes,
  IOUtils,
  Math,
  SysUtils;

type
  TBlockchainICODat = class(TChainFileBase)
  private
    FFile: file of TTokenICODat;
  public
    constructor Create;
    destructor Destroy;

    function GetBlockSize: Integer; override;
    function GetBlocksCount: Integer; override;
    procedure WriteBlocksAsBytes(ASkipBlocks: Integer; ABytes: TBytes); override;
    function ReadBlocksAsBytes(ASkipBlocks: Integer;
      ANumber: Integer = MaxBlocksNumber): TBytes; override;
    function ReadBlocks(ASkip, ANumber: Integer): TArray<TTokenICODat>;

    function TryGet(ASkip: Integer; out AICOBlock: TTokenICODat): Boolean; overload;
    function TryGet(ATicker: string; out AICOBlock: TTokenICODat): Boolean; overload;
  end;

implementation

{ TBlockchainICODat }

constructor TBlockchainICODat.Create;
begin
  inherited Create(ConstStr.DBCPath, ConstStr.ICODatFileName);

  if not FileExists(FFullFilePath) then
    TFile.WriteAllBytes(FFullFilePath, []);
end;

destructor TBlockchainICODat.Destroy;
begin

  inherited;
end;

function TBlockchainICODat.GetBlocksCount: Integer;
begin
  FLock.Enter;
  AssignFile(FFile, FFullFilePath);
  Reset(FFile);
  try
    Result := FileSize(FFile);
  finally
    CloseFile(FFile);
    FLock.Leave;
  end;
end;

function TBlockchainICODat.GetBlockSize: Integer;
begin
  Result := SizeOf(TTokenICODat);
end;

function TBlockchainICODat.ReadBlocks(ASkip,
  ANumber: Integer): TArray<TTokenICODat>;
var
  i: Integer;
begin
  Result := [];
  FLock.Enter;
  AssignFile(FFile, FFullFilePath);
  Reset(FFile);
  try
    if (ASkip >= FileSize(FFile) - 2) or (ASkip < 0) then
      exit;

    Seek(FFile, ASkip + 2);
    SetLength(Result, Min(ANumber, FileSize(FFile) - ASkip - 2));
    for i := 0 to Length(Result) - 1 do
      Read(FFile, Result[i]);
  finally
    CloseFile(FFile);
    FLock.Leave;
  end;
end;

function TBlockchainICODat.ReadBlocksAsBytes(ASkipBlocks,
  ANumber: Integer): TBytes;
var
  BlockBytes: array[0..SizeOf(TTokenICODat) - 1] of Byte;
  TokenICODatBlock: TTokenICODat absolute BlockBytes;
  i: Integer;
begin
  Result := [];
  FLock.Enter;
  AssignFile(FFile, FFullFilePath);
  Reset(FFile);
  try
    if (ASkipBlocks >= FileSize(FFile)) or
      (ASkipBlocks < 0) then
      exit;

    Seek(FFile, ASkipBlocks);
    SetLength(Result, Min(ANumber, FileSize(FFile) - ASkipBlocks) * GetBlockSize);
    for i := 0 to (Length(Result) div GetBlockSize) - 1 do
    begin
      Read(FFile, TokenICODatBlock);
      Move(BlockBytes[0], Result[i * GetBlockSize], GetBlockSize);
    end;
  finally
    CloseFile(FFile);
    FLock.Leave;
  end;
end;

procedure TBlockchainICODat.WriteBlocksAsBytes(ASkipBlocks: Integer;
  ABytes: TBytes);
var
  BlockBytes: array[0..SizeOf(TTokenICODat) - 1] of Byte;
  TokenICODatBlock: TTokenICODat absolute BlockBytes;
  i: Integer;
begin
  if (Length(ABytes) mod GetBlockSize <> 0) or (ASkipBlocks < 0) then
    exit;

  FLock.Enter;
  AssignFile(FFile, FFullFilePath);
  Reset(FFile);
  try
    Seek(FFile, ASkipBlocks);
    for i := 0 to (Length(ABytes) div GetBlockSize) - 1 do
    begin
      Move(ABytes[i * GetBlockSize], BlockBytes[0], GetBlockSize);
      Write(FFile, TokenICODatBlock);
    end;
  finally
    CloseFile(FFile);
    FLock.Leave;
  end;
end;

function TBlockchainICODat.TryGet(ASkip: Integer;
  out AICOBlock: TTokenICODat): Boolean;
begin
  FLock.Enter;
  AssignFile(FFile, FFullFilePath);
  Reset(FFile);
  try
    Result := (ASkip >= 0) and (ASkip < FileSize(FFile));
    if Result then
    begin
      Seek(FFile, ASkip);
      Read(FFile, AICOBlock);
    end;
  finally
    CloseFile(FFile);
    FLock.Leave;
  end;
end;

function TBlockchainICODat.TryGet(ATicker: string;
  out AICOBlock: TTokenICODat): Boolean;
var
  i: Integer;
begin
  Result := False;
  FLock.Enter;
  AssignFile(FFile, FFullFilePath);
  Reset(FFile);
  try
    Seek(FFile, 0);
    for i := 0 to FileSize(FFile) - 1 do
    begin
      Read(FFile, AICOBlock);
      if (AICOBlock.Abreviature = ATicker) then
        exit(True);
    end;
  finally
    CloseFile(FFile);
    FLock.Leave;
  end;
end;

end.
