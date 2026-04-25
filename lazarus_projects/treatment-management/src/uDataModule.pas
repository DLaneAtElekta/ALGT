unit uDataModule;

{$mode objfpc}{$H+}

// Shared data module — period-correct fat-client architecture.
// Owns the single TPQConnection + TSQLTransaction for the application.
// Each browse form binds its own TSQLQuery components to dmMain.Connection.

interface

uses
  Classes, SysUtils, DB, SQLDB, pqconnection, uAppConfig;

type
  TdmMain = class(TDataModule)
    Connection:    TPQConnection;
    MainTrans:     TSQLTransaction;
    qryPatients:   TSQLQuery;
    dsPatients:    TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
  public
    procedure ConnectToDatabase;
    procedure CommitWork;
    procedure RollbackWork;
  end;

var
  dmMain: TdmMain;

implementation

{$R *.lfm}

procedure TdmMain.DataModuleCreate(Sender: TObject);
begin
  Connection.HostName     := AppCfg.Db.Host;
  Connection.DatabaseName := AppCfg.Db.Database;
  Connection.UserName     := AppCfg.Db.User;
  Connection.Password     := AppCfg.Db.Password;
  Connection.Params.Clear;
  Connection.Params.Add('port=' + IntToStr(AppCfg.Db.Port));
  Connection.Params.Add('search_path=tm,public');
  if AppCfg.Db.Params <> '' then
    Connection.Params.Add(AppCfg.Db.Params);

  Connection.Transaction := MainTrans;
  MainTrans.Database     := Connection;

  ConnectToDatabase;
end;

procedure TdmMain.DataModuleDestroy(Sender: TObject);
begin
  if Assigned(Connection) and Connection.Connected then
  begin
    if MainTrans.Active then
      MainTrans.Rollback;
    Connection.Close;
  end;
end;

procedure TdmMain.ConnectToDatabase;
begin
  if not Connection.Connected then
    Connection.Open;
  if not MainTrans.Active then
    MainTrans.StartTransaction;
end;

procedure TdmMain.CommitWork;
begin
  if MainTrans.Active then
    MainTrans.CommitRetaining;
end;

procedure TdmMain.RollbackWork;
begin
  if MainTrans.Active then
    MainTrans.RollbackRetaining;
end;

end.
