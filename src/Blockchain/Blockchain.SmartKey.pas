unit Blockchain.SmartKey;

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
  TBlockchainSmartKey = class(TChainFileBase)
  private
    FFile: file of TCSmartKey;
  public
    constructor Create;
    destructor Destroy;

    function GetBlockSize: Integer; override;
    function GetBlocksCount: Integer; override;
    procedure WriteBlocksAsBytes(ASkipBlocks: Integer; ABytes: TBytes); override;
    function ReadBlocksAsBytes(ASkipBlocks: Integer;
      ANumber: Integer = MaxBlocksNumber): TBytes; override;
    function ReadBlocks(ASkip: Integer;
      ANumber: Integer = MaxBlocksNumber): TArray<TCSmartKey>;

    function TryGet(ATickerOrAddress: string;
      var ASmartKey: TCSmartKey): Boolean; overload;
    function TryGet(ATokenID: Integer;
      var ASmartKey: TCSmartKey): Boolean; overload;
  end;

implementation

{ TBlockchainSmartKey }

constructor TBlockchainSmartKey.Create;
begin
  inherited Create(ConstStr.SmartCPath, ConstStr.SmartKeyFileName);

  if not FileExists(FFullFilePath) then
    TFile.WriteAllBytes(FFullFilePath, []);
end;

destructor TBlockchainSmartKey.Destroy;
begin

  inherited;
end;

function TBlockchainSmartKey.ReadBlocks(ASkip,
  ANumber: Integer): TArray<TCSmartKey>;
var
  i: Integer;
begin
  Result := [];
  FLock.Enter;
  AssignFile(FFile, FFullFilePath);
  Reset(FFile);
  try
    if (ASkip >= FileSize(FFile)) or (ASkip < 0) then
      exit;

    Seek(FFile, ASkip);
    SetLength(Result, Min(ANumber, FileSize(FFile) - ASkip));
    for i := 0 to Length(Result) - 1 do
      Read(FFile, Result[i]);
  finally
    CloseFile(FFile);
    FLock.Leave;
  end;
end;

function TBlockchainSmartKey.GetBlocksCount: Integer;
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

function TBlockchainSmartKey.GetBlockSize: Integer;
begin
  Result := SizeOf(TCSmartKey);
end;

function TBlockchainSmartKey.ReadBlocksAsBytes(ASkipBlocks: Integer;
  ANumber: Integer): TBytes;
var
  BlockBytes: array[0..SizeOf(TCSmartKey) - 1] of Byte;
  SmartKeyBlock: TCSmartKey absolute BlockBytes;
  i: Integer;
begin
  Result := [];
  FLock.Enter;
  AssignFile(FFile, FFullFilePath);
  Reset(FFile);
  try
    if (ASkipBlocks >= FileSize(FFile)) or (ASkipBlocks < 0) then
      exit;

    Seek(FFile, ASkipBlocks);
    SetLength(Result, Min(ANumber, FileSize(FFile) - ASkipBlocks) * GetBlockSize);
    for i := 0 to (Length(Result) div GetBlockSize) - 1 do
    begin
      Read(FFile, SmartKeyBlock);
      Move(BlockBytes[0], Result[i * GetBlockSize], GetBlockSize);
    end;
  finally
    CloseFile(FFile);
    FLock.Leave;
  end;
end;

function TBlockchainSmartKey.TryGet(ATokenID: Integer;
  var ASmartKey: TCSmartKey): Boolean;
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
      Read(FFile, ASmartKey);
      if ASmartKey.SmartID = ATokenID then
        exit(True);
    end;
  finally
    CloseFile(FFile);
    FLock.Leave;
  end;
end;

function TBlockchainSmartKey.TryGet(ATickerOrAddress: string;
  var ASmartKey: TCSmartKey): Boolean;
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
      Read(FFile, ASmartKey);
      if (ASmartKey.Abreviature = ATickerOrAddress) or
         (ASmartKey.key1 = ATickerOrAddress) then
        exit(True);
    end;
  finally
    CloseFile(FFile);
    FLock.Leave;
  end;
end;

procedure TBlockchainSmartKey.WriteBlocksAsBytes(ASkipBlocks: Integer;
  ABytes: TBytes);
var
  BlockBytes: array[0..SizeOf(TCSmartKey) - 1] of Byte;
  SmartKeyBlock: TCSmartKey absolute BlockBytes;
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
      Write(FFile, SmartKeyBlock);
    end;
  finally
    CloseFile(FFile);
    FLock.Leave;
  end;
end;

end.
