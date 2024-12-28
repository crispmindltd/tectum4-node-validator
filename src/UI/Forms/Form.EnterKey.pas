unit Form.EnterKey;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Memo.Types, FMX.ScrollBox,
  FMX.Memo, Styles, FMX.Objects, Crypto, App.Intf, FMX.Effects, OpenURL;

type
  TEnterPrivateKeyForm = class(TForm)
    PrivateKeyLabel: TLabel;
    TextInfoLabel: TLabel;
    PrKeyMemo: TMemo;
    PrKeyRectangle: TRectangle;
    SaveKeyButton: TButton;
    CancelButton: TButton;
    ErrorLabel: TLabel;
    ShadowEffect1: TShadowEffect;
    LinkLabel: TLabel;
    MainRectangle: TRectangle;
    procedure PrKeyMemoChangeTracking(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CancelButtonClick(Sender: TObject);
    procedure SaveKeyButtonClick(Sender: TObject);
    procedure LinkLabelMouseEnter(Sender: TObject);
    procedure LinkLabelMouseLeave(Sender: TObject);
    procedure LinkLabelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
  private
    function CheckPrKeyFormat: Boolean;
  public
    { Public declarations }
  end;

var
  EnterPrivateKeyForm: TEnterPrivateKeyForm;

implementation

{$R *.fmx}

procedure TEnterPrivateKeyForm.CancelButtonClick(Sender: TObject);
begin
  Self.Close;
end;

function TEnterPrivateKeyForm.CheckPrKeyFormat: Boolean;
const
  Accepted = '0123456789abcdef';
var
  i: Integer;
begin
  Result := False;
  for i := 1 to Length(PrKeyMemo.Text) do
    if Accepted.IndexOf(PrKeyMemo.Text[i]) = -1 then
      exit;
  Result := True;
end;

procedure TEnterPrivateKeyForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TEnterPrivateKeyForm.FormShow(Sender: TObject);
begin
  PrKeyMemo.Text := '';
end;

procedure TEnterPrivateKeyForm.LinkLabelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  TOpenURL.Open(LinkLabel.Text);
end;

procedure TEnterPrivateKeyForm.LinkLabelMouseEnter(Sender: TObject);
begin
  LinkLabel.TextSettings.Font.Style := [TFontStyle.fsUnderline];
end;

procedure TEnterPrivateKeyForm.LinkLabelMouseLeave(Sender: TObject);
begin
  LinkLabel.TextSettings.Font.Style := [];
end;

procedure TEnterPrivateKeyForm.PrKeyMemoChangeTracking(Sender: TObject);
begin
  SaveKeyButton.Enabled := Length(PrKeyMemo.Text) = 64;
end;

procedure TEnterPrivateKeyForm.SaveKeyButtonClick(Sender: TObject);
var
  sign: String;
begin
  try
    ErrorLabel.Visible := not CheckPrKeyFormat;
    if not ErrorLabel.Visible then
    begin
      ECDSASignText('test text',HexToBytes(PrKeyMemo.Text),sign);
      ErrorLabel.Visible := sign.IsEmpty;
    end;
  finally
    if ErrorLabel.Visible then
      ModalResult := mrNone
    else
      ModalResult := mrOk;
  end;
end;

end.
