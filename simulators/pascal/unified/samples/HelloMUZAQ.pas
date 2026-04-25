unit HelloMUZAQ;

interface

uses
  Classes, SysUtils;

type
  TMainForm = class(TForm)
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  end;

implementation

procedure TMainForm.FormCreate(Sender: TObject);
begin
  MyDataSet.Open;
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
  MyDataSet.Insert;
  MyDataSet.FieldByName('PatientID').AsString := 'P001';
  MyDataSet.FieldByName('Name').AsString := 'Smith';
  MyDataSet.Post;
  MyDataSet.ApplyUpdates;
  ShowMessage('Saved');
end;

end.
