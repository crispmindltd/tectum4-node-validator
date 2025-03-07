unit Desktop;

interface

uses
  System.Classes,
  System.SysUtils,
  System.UITypes,
  System.SyncObjs,
  System.Math,
  System.Messaging,
  FMX.Dialogs,
  FMX.DialogService,
  FMX.Forms,
  FMX.Platform,
  App.Exceptions,
  App.Types,
  App.Intf,
  Styles,
  Form.Main;

type
  TAccessCommonCustomForm = class(TCommonCustomForm);

type
  TUICore = class(TInterfacedObject, IUI)
  private
    procedure CreateForm(const InstanceClass: TComponentClass;
      var Reference; AsMainForm: Boolean = False);
    procedure SetMainForm(const Reference);
    procedure ShowForm(Form: TCommonCustomForm; AsMainForm: Boolean = False);
    procedure CreateAndShowForm(const InstanceClass: TComponentClass;
      var Reference; AsMainForm: Boolean = False);
    procedure ReleaseForm(var Form);
    procedure DoReleaseForm(Form: TCommonCustomForm);
    procedure NullForm(var Form);
    procedure FormsCreatedHandler(const Sender: TObject; const M: System.Messaging.TMessage);
  public
    constructor Create;
    destructor Destroy; override;
    procedure DoMessage(const AMessage: string);
    procedure ShowMessage(const AMessage: string; OnCloseProc: TProc);
    procedure ShowException(const Reason: string; OnCloseProc: TProc);
    procedure ShowWarning(const Reason: string; OnCloseProc: TProc);
    procedure DoTerminate;
    procedure Run;
    procedure NotifyNewTETBlocks;
    procedure DoSynchronize(const Position, Count: UInt64);
    procedure DoConnectionFailed(const Address: string);
  end;

procedure CopyToClipboard(const Text: string);

implementation

{ TUI }

constructor TUICore.Create;
begin
  Application.Initialize;
  CreateAndShowForm(TMainForm, MainForm, True);
  CreateForm(TStylesForm, StylesForm);
  TMessageManager.DefaultManager.SubscribeToMessage(TFormsCreatedMessage,FormsCreatedHandler);
end;

destructor TUICore.Destroy;
begin
  TMessageManager.DefaultManager.Unsubscribe(TFormsCreatedMessage,FormsCreatedHandler);
  inherited;
end;

procedure TUICore.FormsCreatedHandler(const Sender: TObject; const M: System.Messaging.TMessage);
begin
  try
    AppCore.Start;
  except on E: Exception do
    ApplicationHandleException(E);
  end;
end;

procedure TUICore.CreateAndShowForm(const InstanceClass: TComponentClass;
  var Reference; AsMainForm: Boolean);
begin
  CreateForm(InstanceClass,Reference,AsMainForm);
  ShowForm(TCommonCustomForm(Reference));
end;

procedure TUICore.CreateForm(const InstanceClass: TComponentClass; var Reference;
  AsMainForm: Boolean);
begin
  if TObject(Reference) = nil then
  begin
    Application.CreateForm(InstanceClass,Reference);
    if AsMainForm then SetMainForm(Reference);
  end;
end;

procedure TUICore.ReleaseForm(var Form);
var
  F: TCommonCustomForm;
begin
  F := TCommonCustomForm(Form);

  if Assigned(F) then DoReleaseForm(F);
end;

procedure TUICore.Run;
begin
  Application.Run;
end;

procedure TUICore.SetMainForm(const Reference);
begin
//  if Assigned(TObject(Reference)) then
  Application.MainForm := TCommonCustomForm(Reference);
end;

procedure TUICore.ShowForm(Form: TCommonCustomForm; AsMainForm: Boolean);
begin
  if Assigned(Form) then
  begin
    if Form.Visible then TAccessCommonCustomForm(Form).DoShow;
    Form.Show;
    if AsMainForm then SetMainForm(Form);
  end;
end;

procedure TUICore.DoMessage(const AMessage: string);
begin

end;

procedure TUICore.ShowMessage(const AMessage: string; OnCloseProc: TProc);
begin
  TCode.InMainThread(procedure
  begin
    TDialogService.MessageDialog(AMessage, TMsgDlgType.mtInformation, [TMsgDlgBtn.mbOK],
      TMsgDlgBtn.mbOK, 0, procedure(const AResult: TModalResult)
      begin
        if Assigned(OnCloseProc) then OnCloseProc;
      end);
  end);
end;

procedure TUICore.ShowException(const Reason: string; OnCloseProc: TProc);
begin
  TCode.InMainThread(procedure
  begin
    TDialogService.MessageDialog(Reason, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK],
      TMsgDlgBtn.mbOK, 0, procedure(const AResult: TModalResult)
      begin
        if Assigned(OnCloseProc) then OnCloseProc;
      end);
  end);
end;

procedure TUICore.ShowWarning(const Reason: string; OnCloseProc: TProc);
begin
  TCode.InMainThread(procedure
  begin
    TDialogService.MessageDialog(Reason, TMsgDlgType.mtWarning, [TMsgDlgBtn.mbOK],
      TMsgDlgBtn.mbOK, 0, procedure(const AResult: TModalResult)
      begin
        if Assigned(OnCloseProc) then OnCloseProc;
      end);
  end);
end;

procedure TUICore.DoReleaseForm(Form: TCommonCustomForm);
begin
  TAccessCommonCustomForm(Form).ReleaseForm;
end;

procedure TUICore.DoTerminate;
begin
  Application.Terminate;
end;

procedure TUICore.NotifyNewTETBlocks;
begin
  TCode.InMainThread(procedure
  begin
    if Assigned(AppCore) then
      MainForm.NewTETChainBlocksEvent;
  end);
end;

procedure TUICore.DoSynchronize(const Position, Count: UInt64);
begin
  TCode.InMainThread(procedure
  begin
    if Assigned(AppCore) then
      MainForm.DoSynchronize(Position, Count);
  end);
end;

procedure TUICore.DoConnectionFailed(const Address: string);
begin
  TCode.InMainThread(procedure
  begin
    if Assigned(AppCore) then
      MainForm.DoConnectionFailed(Address);
  end);
end;

procedure TUICore.NullForm(var Form);
begin
  TAccessCommonCustomForm(Form) := nil;
end;

procedure CopyToClipboard(const Text: string);
var
  Service: IFMXClipBoardService;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXClipBoardService, Service) then
    Service.SetClipboard(Text);
end;

end.
