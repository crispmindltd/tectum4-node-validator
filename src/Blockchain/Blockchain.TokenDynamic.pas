unit Blockchain.TokenDynamic;

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
  TBlockchainTokenDynamic = class(TChainFileBase)
  private
    FFile: file of TCTokensBase;
    FIsOpened: Boolean;
  public
    constructor Create(ATokenID: Integer);
    destructor Destroy;
    function DoOpen: Boolean;
    procedure DoClose;

    function GetBlockSize: Integer; override;
    function GetBlocksCount: Integer; override;
    procedure WriteBlocksAsBytes(ASkipBlocks: Integer; ABytes: TBytes); override;
    procedure WriteBlock(ASkip: Integer; ABlock: TCTokensBase);
    function TryReadBlock(ASkip: Integer; out ABlock: TCTokensBase): Boolean;
    function ReadBlocksAsBytes(ASkipBlocks: Integer;
      ANumber: Integer = MaxBlocksNumber): TBytes; override;

    function TryGet(AUserID: Integer; out ABlockID: Integer;
      out ATokenDyn: TCTokensBase): Boolean; overload;
    function TryGet(ATETAddress: string; out ABlockID: Integer;
      out ATokenDyn: TCTokensBase): Boolean; overload;
  end;

implementation

{ TBlockchainTokenDynamic }

constructor TBlockchainTokenDynamic.Create(ATokenID: Integer);
begin
  inherited Create(ConstStr.SmartCPath, ATokenID.ToString + '.tkn');

  FIsOpened := False;
end;

destructor TBlockchainTokenDynamic.Destroy;
begin

  inherited;
end;

procedure TBlockchainTokenDynamic.DoClose;
begin
  if FIsOpened then
  begin
    CloseFile(FFile);
    FIsOpened := False;
    FLock.Leave;
  end;
end;

function TBlockchainTokenDynamic.DoOpen: Boolean;
begin
  Result := not FIsOpened;
  if Result then
  begin
    FLock.Enter;
    if not FileExists(FFullFilePath) then
      TFile.WriteAllBytes(FFullFilePath, []);
    AssignFile(FFile, FFullFilePath);
    Reset(FFile);
    FIsOpened := True;
  end;
end;

function TBlockchainTokenDynamic.GetBlocksCount: Integer;
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

function TBlockchainTokenDynamic.GetBlockSize: Integer;
begin
  Result := SizeOf(TCTokensBase);
end;

function TBlockchainTokenDynamic.TryGet(AUserID: Integer; out ABlockID: Integer;
  out ATokenDyn: TCTokensBase): Boolean;
var
  NeedClose: Boolean;
  i: Integer;
begin
  Result := False;
  NeedClose := DoOpen;
  try
    Seek(FFile, 0);
    for i := 0 to FileSize(FFile) - 1 do
    begin
      Read(FFile, ATokenDyn);
      if ATokenDyn.OwnerID = AUserID then
      begin
        ABlockID := i;
        exit(True);
      end;
    end;
  finally
    if NeedClose then
      DoClose;
  end;
end;

function TBlockchainTokenDynamic.TryGet(ATETAddress: string;
  out ABlockID: Integer; out ATokenDyn: TCTokensBase): Boolean;
var
  NeedClose: Boolean;
  i: Integer;
begin
  Result := False;
  NeedClose := DoOpen;
  try
    Seek(FFile, 0);
    for i := 0 to FileSize(FFile) - 1 do
    begin
      Read(FFile, ATokenDyn);
      if ATokenDyn.Token = ATETAddress then
      begin
        ABlockID := i;
        exit(True);
      end;
    end;
  finally
    if NeedClose then
      DoClose;
  end;
end;

function TBlockchainTokenDynamic.TryReadBlock(ASkip: Integer;
  out ABlock: TCTokensBase): Boolean;
var
  NeedClose: Boolean;
begin
  NeedClose := DoOpen;
  try
    Result := (ASkip >= 0) and (ASkip < GetBlocksCount);
    if Result then
    begin
      Seek(FFile, ASkip);
      Read(FFile, ABlock);
    end;
  finally
    if NeedClose then
      DoClose;
  end;
end;

function TBlockchainTokenDynamic.ReadBlocksAsBytes(ASkipBlocks: Integer;
  ANumber: Integer): TBytes;
var
  NeedClose: Boolean;
  BlockBytes: array[0..SizeOf(TCTokensBase) - 1] of Byte;
  TokenBaseBlock: TCTokensBase absolute BlockBytes;
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
      Read(FFile, TokenBaseBlock);
      Move(BlockBytes[0], Result[i * GetBlockSize], GetBlockSize);
    end;
  finally
    if NeedClose then
      DoClose;
  end;
end;

procedure TBlockchainTokenDynamic.WriteBlock(ASkip: Integer; ABlock: TCTokensBase);
var
  NeedClose: Boolean;
begin
  if ASkip < 0 then
    exit;

  NeedClose := DoOpen;
  try
    Seek(FFile, ASkip);
    Write(FFile, ABlock);
  finally
    if NeedClose then
      DoClose;
  end;
end;

procedure TBlockchainTokenDynamic.WriteBlocksAsBytes(ASkipBlocks: Integer;
  ABytes: TBytes);
var
  NeedClose: Boolean;
  BlockBytes: array[0..SizeOf(TCTokensBase) - 1] of Byte;
  TokenBaseBlock: TCTokensBase absolute BlockBytes;
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
      Write(FFile, TokenBaseBlock);
    end;
  finally
    if NeedClose then
      DoClose;
  end;
end;

end.
