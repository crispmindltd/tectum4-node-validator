unit Frame.Navigation;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Layouts, Desktop.Controls, System.Math;

type
  TNavigationFrame = class(TFrame)
    PagesPanelLayout: TLayout;
    NextPageLayout: TLayout;
    NextPagePath: TPath;
    PrevPageLayout: TLayout;
    PrevPagePath: TPath;
    Text1: TText;
    procedure PrevPageLayoutClick(Sender: TObject);
    procedure NextPageLayoutClick(Sender: TObject);
  private
    FCount, FPageNum: Int64;
    FOnChange: TNotifyEvent;
    procedure SetPageNum(Value: Int64);
    procedure SetPagesCount(Value: Int64);
    procedure CreateControls;
    function CreateLabel(const Text: string; Page: Int64): TControl;
    procedure OnPageClick(Sender: TObject);
  public
    procedure SetParams(PagesCount, PageNum: Int64);
    property PageNum: Int64 read FPageNum write SetPageNum;
    property PagesCount: Int64 read FCount write SetPagesCount;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

{$R *.fmx}

procedure TNavigationFrame.SetPageNum(Value: Int64);
begin
  Value := EnsureRange(Value,1,FCount);
  if Value <> FPageNum then
  begin
    FPageNum := Value;
    CreateControls;
  end;
end;

procedure TNavigationFrame.SetPagesCount(Value: Int64);
begin
  Value := EnsureRange(Value,0,Value.MaxValue);
  if Value <> FCount then
  begin
    FCount := Value;
    FPageNum := EnsureRange(FPageNum,1,FCount);
    CreateControls;
  end;
end;

procedure TNavigationFrame.SetParams(PagesCount, PageNum: Int64);
begin
  FCount := PagesCount;
  FPageNum := PageNum;
  CreateControls;
end;

procedure TNavigationFrame.CreateControls;
begin

  PagesPanelLayout.BeginUpdate;

  PagesPanelLayout.DeleteChildren;

  var SkipPage := True;

  for var I := 1 to FCount do
  begin

    if (I=1) or (I=FCount) or InRange(I,FPageNum-2,FPageNum+2) then
    begin
      CreateLabel(I.ToString,I);
      SkipPage := True;
    end
    else if SkipPage then
    begin
      CreateLabel('...',0);
      SkipPage := False;
    end;

  end;

  PagesPanelLayout.EndUpdate;

  Width := GetContentRect(PagesPanelLayout).Width + PrevPageLayout.Width + NextPageLayout.Width+8;

  PrevPageLayout.Enabled := FPageNum > 1;
  NextPageLayout.Enabled := FPageNum < FCount;

end;

function TNavigationFrame.CreateLabel(const Text: string; Page: Int64): TControl;
begin

  var L := TText.Create(Self);

  L.Text := Text;
  L.Tag := Page;
  L.WordWrap := False;
  L.TextSettings.Font.Family := 'Inter';
  L.TextSettings.Font.Size := 16;
  L.Position.Point := Point(200,0);
  L.Align := TAlignLayout.Left;
  L.AutoSize := True;
  L.Margins.Rect := Rect(4,2,4,4);

  if Page = FPageNum then
    L.TextSettings.FontColor := $FF4285F4
  else
    L.TextSettings.FontColor := $FF5A6773;

  if (Page <> FPageNum) and (Page <> 0) then
  begin
    L.Cursor := crHandPoint;
    L.OnClick := OnPageClick;
  end;

  L.Parent := PagesPanelLayout;

  Result := L;

end;

procedure TNavigationFrame.PrevPageLayoutClick(Sender: TObject);
begin
  PageNum := PageNum - 1;
  FOnChange(Self);
end;

procedure TNavigationFrame.NextPageLayoutClick(Sender: TObject);
begin
  PageNum := PageNum + 1;
  FOnChange(Self);
end;

procedure TNavigationFrame.OnPageClick(Sender: TObject);
begin
  FPageNum:=TControl(Sender).Tag;
  CreateControls;
  FOnChange(Self);
end;

end.
