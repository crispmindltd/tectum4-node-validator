unit Frame.Explorer;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Objects;

type
  TExplorerTransactionFrame = class(TFrame)
    DateTimeLabel: TLabel;
    BlockLabel: TLabel;
    FromLabel: TLabel;
    ToLabel: TLabel;
    HashLabel: TLabel;
    AmountLabel: TLabel;
    Rectangle: TRectangle;
    TickerLabel: TLabel;
    procedure FrameMouseEnter(Sender: TObject);
    procedure FrameMouseLeave(Sender: TObject);
    procedure FrameResized(Sender: TObject);
  private
  public
    constructor Create(AOwner: TComponent; ADateTime: TDateTime; ABlock: Integer;
      ATicker, AFrom, ATo, AHash, AAmount: string; AShowTicker: Boolean);
    destructor Destroy; override;
  end;

implementation

{$R *.fmx}

{ TExplorerTransactionFrame }

constructor TExplorerTransactionFrame.Create(AOwner: TComponent; ADateTime: TDateTime;
  ABlock: Integer; ATicker, AFrom, ATo, AHash, AAmount: string; AShowTicker: Boolean);
begin
  inherited Create(AOwner);

  TickerLabel.Visible := AShowTicker;
  if AShowTicker then
    TickerLabel.Position.X := FromLabel.Position.X - 1;
  DateTimeLabel.Text := FormatDateTime('dd.mm.yyyy hh:mm:ss', ADateTime);
  BlockLabel.Text := ABlock.ToString;
  TickerLabel.Text := ATicker;
  FromLabel.Text := AFrom;
  ToLabel.Text := ATo;
  HashLabel.Text := AHash;
  AmountLabel.Text := AAmount;
  Name := AOwner.Name + AOwner.ComponentCount.ToString;
end;

destructor TExplorerTransactionFrame.Destroy;
begin

  inherited;
end;

procedure TExplorerTransactionFrame.FrameMouseEnter(Sender: TObject);
begin
  Rectangle.Fill.Kind := TBrushKind.Solid;
end;

procedure TExplorerTransactionFrame.FrameMouseLeave(Sender: TObject);
begin
  Rectangle.Fill.Kind := TBrushKind.None;
end;

procedure TExplorerTransactionFrame.FrameResized(Sender: TObject);
var
  Width: Single;
begin
  Width := Self.Width - DateTimeLabel.Width - BlockLabel.Width -
    AmountLabel.Width - 70;
  if TickerLabel.Visible then
    Width := Width - TickerLabel.Width - 15;

  FromLabel.Width := Width * 0.25;
  ToLabel.Width := Width * 0.25;
  HashLabel.Width := Width * 0.5;
end;

end.
