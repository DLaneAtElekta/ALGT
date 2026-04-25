unit uMainForm;

{$mode objfpc}{$H+}

// Main application form. Period-correct: a TForm with a TMainMenu, TStatusBar,
// and menu-item handlers that launch the modal child forms.

interface

uses
  Classes, SysUtils, Forms, Controls, Menus, ComCtrls, Dialogs, ExtCtrls,
  StdCtrls, Graphics, uAppConfig;

type
  TfrmMain = class(TForm)
    MainMenu1:        TMainMenu;
    mnuFile:          TMenuItem;
    mnuFileExit:      TMenuItem;
    mnuMaintain:      TMenuItem;
    mnuPatients:      TMenuItem;
    mnuPlans:         TMenuItem;
    mnuAppointments:  TMenuItem;
    mnuSessions:      TMenuItem;
    mnuHelp:          TMenuItem;
    mnuHelpAbout:     TMenuItem;
    StatusBar1:       TStatusBar;
    pnlBanner:        TPanel;
    lblBanner:        TLabel;
    procedure FormCreate(Sender: TObject);
    procedure mnuFileExitClick(Sender: TObject);
    procedure mnuPatientsClick(Sender: TObject);
    procedure mnuPlansClick(Sender: TObject);
    procedure mnuAppointmentsClick(Sender: TObject);
    procedure mnuSessionsClick(Sender: TObject);
    procedure mnuHelpAboutClick(Sender: TObject);
  private
    procedure NotImplemented(const What: string);
  public
  end;

var
  frmMain: TfrmMain;

implementation

uses
  uPatientForm;

{$R *.lfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Caption := 'Treatment Management System';
  StatusBar1.Panels[0].Text := 'Operator: ' + AppCfg.Operator;
  StatusBar1.Panels[1].Text := 'DB: ' + AppCfg.Db.Database +
                               ' @ ' + AppCfg.Db.Host;
end;

procedure TfrmMain.mnuFileExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.mnuPatientsClick(Sender: TObject);
var
  F: TfrmPatient;
begin
  F := TfrmPatient.Create(Self);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmMain.mnuPlansClick(Sender: TObject);
begin
  NotImplemented('Treatment Plans');
end;

procedure TfrmMain.mnuAppointmentsClick(Sender: TObject);
begin
  NotImplemented('Appointments');
end;

procedure TfrmMain.mnuSessionsClick(Sender: TObject);
begin
  NotImplemented('Treatment Sessions');
end;

procedure TfrmMain.mnuHelpAboutClick(Sender: TObject);
begin
  MessageDlg(
    'Treatment Management System',
    'Treatment Management System' + LineEnding +
    'Lazarus / FreePascal fat-client demo' + LineEnding + LineEnding +
    'INI: ' + AppCfg.IniPath,
    mtInformation, [mbOK], 0);
end;

procedure TfrmMain.NotImplemented(const What: string);
begin
  MessageDlg('Not Implemented',
    What + ' maintenance is not yet implemented in this milestone.',
    mtInformation, [mbOK], 0);
end;

end.
