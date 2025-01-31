unit Frame.Navigation;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Math,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Layouts, Desktop.Controls, Blockchain.Utils;

type
  TNavigationFrame = class(TFrame)
    PagesPanelLayout: TLayout;
    NextPageLayout: TLayout;
    NextPagePath: TPath;
    PrevPageLayout: TLayout;
    PrevPagePath: TPath;
    PageText: TText;
    procedure PrevPageLayoutClick(Sender: TObject);
    procedure NextPageLayoutClick(Sender: TObject);
  private
    FCount, FPageNum: UInt64;
    FOnChange: TNotifyEvent;
    procedure SetPageNum(Value: UInt64);
    procedure SetPagesCount(Value: UInt64);
    procedure CreateControls;
    function CreateLabel(const Text: string; Page: UInt64): TControl;
    procedure OnPageClick(Sender: TObject);
    procedure DoChange;
  public
    constructor Create(AOwner: TComponent); override;
    property PageNum: UInt64 read FPageNum write SetPageNum;
    property PagesCount: UInt64 read FCount write SetPagesCount;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

{$R *.fmx}

constructor TNavigationFrame.Create(AOwner: TComponent);
begin
  inherited;
  PageText.Parent:=nil;
end;

procedure TNavigationFrame.SetPageNum(Value: UInt64);
begin
  Value := EnsureRange(Value,1,Max(FCount,1));
  if Value <> FPageNum then
  begin
    FPageNum := Value;
    CreateControls;
  end;
end;

procedure TNavigationFrame.SetPagesCount(Value: UInt64);
begin
  Value := EnsureRange(Value,0,Value.MaxValue);
  if Value <> FCount then
  begin
    FCount := Value;
    FPageNum := EnsureRange(FPageNum,1,Max(FCount,1));
    CreateControls;
  end;
end;

procedure TNavigationFrame.CreateControls;
begin

  PagesPanelLayout.BeginUpdate;

  PagesPanelLayout.DeleteChildren;

  var SkipPage := True;

  for var I := 1 to FCount do
  begin

    if (I=1) or (I=FCount) or InRange(I, SafeSub(FPageNum, 2), FPageNum+2) then
    begin
      CreateLabel(I.ToString, I);
      SkipPage := True;
    end
    else if SkipPage then
    begin
      CreateLabel('...', 0);
      SkipPage := False;
    end;

  end;

  PagesPanelLayout.EndUpdate;

  Width := GetContentRect(PagesPanelLayout).Width + PrevPageLayout.Width + NextPageLayout.Width + 6;

  PrevPageLayout.Enabled := FPageNum > 1;
  NextPageLayout.Enabled := FPageNum < FCount;

end;

function TNavigationFrame.CreateLabel(const Text: string; Page: UInt64): TControl;
begin

  var L := PageText.Clone(Self) as TText;

  L.Text := Text;
  L.Tag := Page;
  L.Position.Point := Point(200,0);

  if Page = FPageNum then
    L.TextSettings.FontColor := $FF4285F4;

  if (Page <> FPageNum) and (Page <> 0) then
  begin
    L.Cursor := crHandPoint;
    L.OnClick := OnPageClick;
  end;

  L.Parent := PagesPanelLayout;

  Result := L;

end;

procedure TNavigationFrame.DoChange;
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TNavigationFrame.PrevPageLayoutClick(Sender: TObject);
begin
  PageNum := PageNum - 1;
  DoChange;
end;

procedure TNavigationFrame.NextPageLayoutClick(Sender: TObject);
begin
  PageNum := PageNum + 1;
  DoChange;
end;

procedure TNavigationFrame.OnPageClick(Sender: TObject);
begin
  TThread.ForceQueue(nil, procedure
  begin
    PageNum := TControl(Sender).Tag;
    DoChange;
  end);
end;

end.
