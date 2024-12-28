unit Blockchain.Token;

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
  TBlockchainToken = class(TChainFileBase)
  private
    FFile: file of TCbc4;
    FIsOpened: Boolean;
  public
    constructor Create(ATokenID: Integer);
    destructor Destroy;
    function DoOpen: Boolean;
    procedure DoClose;

    function GetBlockSize: Integer; override;
    function GetBlocksCount: Integer; override;
    procedure WriteBlocksAsBytes(ASkipBlocks: Integer; ABytes: TBytes); override;
    function ReadBlocksAsBytes(ASkipBlocks: Integer;
      ANumber: Integer = MaxBlocksNumber): TBytes; override;
    function ReadBlocks(ASkip: Integer; ANumber: Integer = MaxBlocksNumber;
      AFromTheEnd: Boolean = False): TArray<TCbc4>;

    function TryGet(ASkip: Integer; out ATokenBlock: TCbc4): Boolean; overload;
    function TryGet(AHash: string; out ABlockNum: Integer;
      out ATokenBlock: TCbc4): Boolean; overload;
  end;

implementation

{ TBlockchainToken }

constructor TBlockchainToken.Create(ATokenID: Integer);
begin
  inherited Create(ConstStr.SmartCPath, ATokenID.ToString + '.chn');

  FIsOpened := False;
end;

destructor TBlockchainToken.Destroy;
begin

  inherited;
end;

procedure TBlockchainToken.DoClose;
begin
  if FIsOpened then
  begin
    CloseFile(FFile);
    FIsOpened := False;
    FLock.Leave;
  end;
end;

function TBlockchainToken.DoOpen: Boolean;
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

function TBlockchainToken.GetBlocksCount: Integer;
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

function TBlockchainToken.GetBlockSize: Integer;
begin
  Result := SizeOf(TCbc4);
end;

function TBlockchainToken.ReadBlocks(ASkip, ANumber: Integer;
  AFromTheEnd: Boolean): TArray<TCbc4>;
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

function TBlockchainToken.ReadBlocksAsBytes(ASkipBlocks,
  ANumber: Integer): TBytes;
var
  NeedClose: Boolean;
  BlockBytes: array[0..SizeOf(TCbc4) - 1] of Byte;
  TCbc4Block: TCbc4 absolute BlockBytes;
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
      Read(FFile, TCbc4Block);
      Move(BlockBytes[0], Result[i * GetBlockSize], GetBlockSize);
    end;
  finally
    if NeedClose then
      DoClose;
  end;
end;

function TBlockchainToken.TryGet(AHash: string; out ABlockNum: Integer;
  out ATokenBlock: TCbc4): Boolean;
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
      Read(FFile, ATokenBlock);
      HashHex := '';
      for j := 1 to TokenLength do
        HashHex := HashHex + IntToHex(ATokenBlock.Hash[j], 2);
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

function TBlockchainToken.TryGet(ASkip: Integer;
  out ATokenBlock: TCbc4): Boolean;
var
  NeedClose: Boolean;
begin
  NeedClose := DoOpen;
  try
    Result := (ASkip >= 0) and (ASkip < GetBlocksCount);
    if Result then
    begin
      Seek(FFile, ASkip);
      Read(FFile, ATokenBlock);
    end;
  finally
    if NeedClose then
      DoClose;
  end;
end;

procedure TBlockchainToken.WriteBlocksAsBytes(ASkipBlocks: Integer;
  ABytes: TBytes);
var
  NeedClose: Boolean;
  BlockBytes: array[0..SizeOf(TCbc4) - 1] of Byte;
  TCbc4Block: TCbc4 absolute BlockBytes;
  i: Integer;
begin
  if (Length(ABytes) mod GetBlockSize <> 0) or (ASkipBlocks < 0) then
    exit;

  if not FileExists(FFullFilePath) then
    TFile.WriteAllBytes(FFullFilePath, []);
  NeedClose := DoOpen;
  try
    Seek(FFile, ASkipBlocks);
    for i := 0 to (Length(ABytes) div GetBlockSize) - 1 do
    begin
      Move(ABytes[i * GetBlockSize], BlockBytes[0], GetBlockSize);
      Write(FFile, TCbc4Block);
    end;
  finally
    if NeedClose then
      DoClose;
  end;
end;



end.
