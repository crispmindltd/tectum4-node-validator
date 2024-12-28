unit Blockchain.TET;

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
  TBlockchainTET = class(TChainFileBase)
  private
    FFile: file of Tbc2;
    FIsOpened: Boolean;
  public
    constructor Create;
    destructor Destroy;
    function DoOpen: Boolean;
    procedure DoClose;

    function GetBlockSize: Integer; override;
    function GetBlocksCount: Integer; override;
    procedure WriteBlocksAsBytes(ASkipBlocks: Integer; ABytes: TBytes); override;
    function ReadBlocksAsBytes(ASkipBlocks: Integer;
      ANumber: Integer = MaxBlocksNumber): TBytes; override;
    function ReadBlocks(ASkip: Integer; ANumber: Integer = MaxBlocksNumber;
      AFromTheEnd: Boolean = False): TArray<Tbc2>;

    function TryGet(ASkip: Integer; out ATETBlock: Tbc2): Boolean; overload;
    function TryGet(AHash: string; out ABlockNum: Integer;
      out ATETBlock: Tbc2): Boolean; overload;
  end;

implementation

{ TBlockchainTET }

constructor TBlockchainTET.Create;
begin
  inherited Create(ConstStr.DBCPath, ConstStr.TokenCHNFileName);

  FIsOpened := False;
  if not FileExists(FFullFilePath) then
    TFile.WriteAllBytes(FFullFilePath, []);
end;

destructor TBlockchainTET.Destroy;
begin

  inherited;
end;

procedure TBlockchainTET.DoClose;
begin
  if FIsOpened then
  begin
    CloseFile(FFile);
    FIsOpened := False;
    FLock.Leave;
  end;
end;

function TBlockchainTET.DoOpen: Boolean;
begin
  Result := not FIsOpened;
  if Result then
  begin
    FLock.Enter;
    AssignFile(FFile, FFullFilePath);
    Reset(FFile);
    FIsOpened := True;
  end;
end;

function TBlockchainTET.GetBlocksCount: Integer;
var
  NeedClose: Boolean;
begin
  NeedClose := DoOpen;
  try
    Result := FileSize(FFile);
  finally
    if NeedClose then
      DoClose;
  end;
end;

function TBlockchainTET.GetBlockSize: Integer;
begin
  Result := SizeOf(Tbc2);
end;

function TBlockchainTET.ReadBlocks(ASkip, ANumber: Integer;
  AFromTheEnd: Boolean): TArray<Tbc2>;
var
  NeedClose: Boolean;
  i: Integer;
begin
  Result := [];
  NeedClose := DoOpen;
  try
    if (ASkip < 0) or (ASkip >= FileSize(FFile)) then
      exit;

    if AFromTheEnd then
    begin
      SetLength(Result, Min(ANumber, FileSize(FFile) - ASkip));
      for i := 0 to Length(Result) - 1 do
      begin
        Seek(FFile, FileSize(FFile) - ASkip - i - 1);
        Read(FFile, Result[i]);
      end;
    end else
    begin
      Seek(FFile, ASkip);
      SetLength(Result, Min(ANumber, FileSize(FFile) - ASkip));
      for i := 0 to Length(Result) - 1 do
        Read(FFile, Result[i]);
    end;
  finally
    if NeedClose then
      DoClose;
  end;
end;

function TBlockchainTET.ReadBlocksAsBytes(ASkipBlocks, ANumber: Integer): TBytes;
var
  NeedClose: Boolean;
  BlockBytes: array[0..SizeOf(Tbc2) - 1] of Byte;
  Tbc2Block: Tbc2 absolute BlockBytes;
  i: Integer;
begin
  Result := [];
  NeedClose := DoOpen;
  try
    if (ASkipBlocks >= FileSize(FFile)) or
      (ASkipBlocks < 0) then
      exit;

    Seek(FFile, ASkipBlocks);
    SetLength(Result, Min(ANumber, FileSize(FFile) - ASkipBlocks) * GetBlockSize);
    for i := 0 to (Length(Result) div GetBlockSize) - 1 do
    begin
      Read(FFile, Tbc2Block);
      Move(BlockBytes[0], Result[i * GetBlockSize], GetBlockSize);
    end;
  finally
    if NeedClose then
      DoClose;
  end;
end;

function TBlockchainTET.TryGet(AHash: string; out ABlockNum: Integer;
  out ATETBlock: Tbc2): Boolean;
var
  NeedClose: Boolean;
  HashHex: string;
  i, j: Integer;
begin
  Result := False;
  NeedClose := DoOpen;
  try
    Seek(FFile, 0);
    for i := 0 to FileSize(FFile) - 1 do
    begin
      Read(FFile, ATETBlock);
      HashHex := '';
      for j := 1 to TokenLength do
        HashHex := HashHex + IntToHex(ATETBlock.Hash[j], 2);
      if HashHex.ToLower = AHash then
      begin
        ABlockNum := i;
        exit(true);
      end;
    end;
  finally
    if NeedClose then
      DoClose;
  end;
end;

function TBlockchainTET.TryGet(ASkip: Integer; out ATETBlock: Tbc2): Boolean;
var
  NeedClose: Boolean;
begin
  NeedClose := DoOpen;
  try
    Result := (ASkip >= 0) and (ASkip < GetBlocksCount);
    if Result then
    begin
      Seek(FFile, ASkip);
      Read(FFile, ATETBlock);
    end;
  finally
    if NeedClose then
      DoClose;
  end;
end;

procedure TBlockchainTET.WriteBlocksAsBytes(ASkipBlocks: Integer; ABytes: TBytes);
var
  NeedClose: Boolean;
  BlockBytes: array[0..SizeOf(Tbc2) - 1] of Byte;
  Tbc2Block: Tbc2 absolute BlockBytes;
  i: Integer;
begin
  if (Length(ABytes) mod GetBlockSize <> 0) or (ASkipBlocks < 0) then
    exit;

  NeedClose := DoOpen;
  try
    Seek(FFile, ASkipBlocks);
    for i := 0 to (Length(ABytes) div GetBlockSize) - 1 do
    begin
      Move(ABytes[i * GetBlockSize], BlockBytes[0], GetBlockSize);
      Write(FFile, Tbc2Block);
    end;
  finally
    if NeedClose then
      DoClose;
  end;
end;

end.
