unit Desktop;

interface

uses
  App.Exceptions,
  App.Intf,
  Classes,
  FMX.Dialogs,
  FMX.Forms,
  Form.Main,
  Math,
  SyncObjs,
  SysUtils,
  Styles,
  UITypes;

type
  TAccessCommonCustomForm = class(TCommonCustomForm);

type
  TUICore = class(TInterfacedObject, IUI)
  private
    FStartFormCreated: TEvent;

    procedure CreateForm(const InstanceClass: TComponentClass;
      var Reference; AsMainForm: Boolean = False);
    procedure SetMainForm(const Reference);
    procedure ShowForm(Form: TCommonCustomForm; AsMainForm: Boolean = False);
    procedure CreateAndShowForm(const InstanceClass: TComponentClass;
      var Reference; AsMainForm: Boolean = False);
    procedure ReleaseForm(var Form);
    procedure DoReleaseForm(Form: TCommonCustomForm);
    procedure NullForm(var Form);
  public
    constructor Create;
    destructor Destroy; override;

    procedure DoMessage(const AMessage: string);
    procedure DoTerminate;
    procedure Run;
    procedure ShowVersionDidNotMatch;
    procedure NotifyNewTETBlocks(const ANeedRefreshBalance: Boolean);
  end;

implementation

{ TUI }

constructor TUICore.Create;
begin
  FStartFormCreated := TEvent.Create;
  FStartFormCreated.ResetEvent;
  Application.Initialize;
  CreateAndShowForm(TMainForm, MainForm, True);
  CreateForm(TStylesForm, StylesForm);
  FStartFormCreated.SetEvent;
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

destructor TUICore.Destroy;
begin
  if Assigned(FStartFormCreated) then
    FStartFormCreated.Free;

  inherited;
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

procedure TUICore.ShowVersionDidNotMatch;
begin
  DoMessage(NewVersionAvailableText);
end;

procedure TUICore.DoMessage(const AMessage: string);
begin
//  TThread.Synchronize(nil,
//  procedure
//  begin
//    ShowMessage(AMessage);
//  end);
end;

procedure TUICore.DoReleaseForm(Form: TCommonCustomForm);
begin
  TAccessCommonCustomForm(Form).ReleaseForm;
end;

procedure TUICore.DoTerminate;
begin
end;

procedure TUICore.NotifyNewTETBlocks(const ANeedRefreshBalance: Boolean);
begin
  if Assigned(MainForm) then
    TThread.Synchronize(nil,
    procedure
    begin
      MainForm.NewTETChainBlocksEvent(ANeedRefreshBalance);
    end);
end;

procedure TUICore.NullForm(var Form);
begin
  TAccessCommonCustomForm(Form) := nil;
end;

end.
