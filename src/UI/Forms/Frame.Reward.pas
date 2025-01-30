unit Frame.Reward;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation;

type
  TRewardFrame = class(TFrame)
    AddressLabel: TLabel;
    AmountLabel: TLabel;
    Rectangle1: TRectangle;
  private
    { Private declarations }
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.fmx}

{ TRewardFrame }

constructor TRewardFrame.Create(AOwner: TComponent);
begin
  inherited;
  Name:='';
end;

end.
