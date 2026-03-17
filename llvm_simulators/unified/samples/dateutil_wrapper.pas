{ dateutil_wrapper.pas -- Standalone wrapper for DATEUTIL.PAS pure functions }
{ Outputs CALL trace lines for comparison against Prolog simulator. }
{ Compile: fpc dateutil_wrapper.pas }

program dateutil_wrapper;

type
  DateRec = record
    Month  : byte;
    Day    : byte;
    Year   : integer;
    Hour   : byte;
    Minute : byte;
  end;

const
  DaysInMonth : array [1..12] of byte =
    (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

  DaysInYear : array [1..12] of integer =
    (0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334);

  DayNames : array [0..6] of string[9] =
    ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');

function SubDates(Date1, Date2 : DateRec) : integer;
var
  Days : integer;
begin
  Days := DaysInYear[Date1.Month] + Date1.Day -
          (DaysInYear[Date2.Month] + Date2.Day);
  if (Date2.Year <> Date1.Year) then
    Days := Days + 365 * (Date1.Year - Date2.Year);
  SubDates := Days;
end;

function CompareDates(Date1, Date2 : DateRec) : integer;
begin
  if (Date1.Year = Date2.Year) then
    if (Date1.Month = Date2.Month) then
      if (Date1.Day = Date2.Day) then
        if (Date1.Hour = Date2.Hour) then
          CompareDates := Date1.Minute - Date2.Minute
        else
          CompareDates := Date1.Hour - Date2.Hour
      else
        CompareDates := Date1.Day - Date2.Day
    else
      CompareDates := Date1.Month - Date2.Month
  else
    CompareDates := Date1.Year - Date2.Year;
end;

function FindDayOfWeek(Year, Month, Day : integer) : integer;
{ Returns day-of-week index 0=Sunday..6=Saturday }
{ Based on the original FindDay algorithm, epoch 1984-01-01 = Sunday }
var
  numOfYears : integer;
  numOfDays  : real;
begin
  numOfYears := Year - 1984;
  numOfDays := numOfYears * 365 + ((numOfYears - 1) div 4);
  if ((numOfYears mod 4) = 0) then
    if (Month >= 3) then
      numOfDays := numOfDays + 1;
  numOfDays := numOfDays + DaysInYear[Month] + Day;
  FindDayOfWeek := Trunc(numOfDays - Int(numOfDays / 7) * 7);
end;

function IsLeapYear(Year : integer) : boolean;
begin
  IsLeapYear := ((Year mod 4 = 0) and (Year mod 100 <> 0)) or (Year mod 400 = 0);
end;

function DaysInMonthFunc(Year, Month : integer) : integer;
begin
  if (Month = 2) and IsLeapYear(Year) then
    DaysInMonthFunc := 29
  else
    DaysInMonthFunc := DaysInMonth[Month];
end;

var
  d1, d2 : DateRec;
  result : integer;
begin
  { SubDates: same month, different days }
  d1.Month := 3; d1.Day := 15; d1.Year := 2024; d1.Hour := 10; d1.Minute := 30;
  d2.Month := 3; d2.Day := 1;  d2.Year := 2024; d2.Hour := 8;  d2.Minute := 0;
  result := SubDates(d1, d2);
  WriteLn('CALL SubDates({3/15/2024}, {3/1/2024}) -> ', result);

  { SubDates: different years }
  d1.Month := 1; d1.Day := 15; d1.Year := 2025;
  d2.Month := 12; d2.Day := 15; d2.Year := 2024;
  result := SubDates(d1, d2);
  WriteLn('CALL SubDates({1/15/2025}, {12/15/2024}) -> ', result);

  { CompareDates: equal dates }
  d1.Month := 6; d1.Day := 15; d1.Year := 2024; d1.Hour := 14; d1.Minute := 30;
  d2.Month := 6; d2.Day := 15; d2.Year := 2024; d2.Hour := 14; d2.Minute := 30;
  result := CompareDates(d1, d2);
  WriteLn('CALL CompareDates({6/15/2024 14:30}, {6/15/2024 14:30}) -> ', result);

  { CompareDates: different months }
  d2.Month := 3;
  result := CompareDates(d1, d2);
  WriteLn('CALL CompareDates({6/15/2024}, {3/15/2024}) -> ', result);

  { CompareDates: different years }
  d1.Year := 2025; d2.Year := 2024;
  result := CompareDates(d1, d2);
  WriteLn('CALL CompareDates({2025}, {2024}) -> ', result);

  { FindDayOfWeek: 2024-01-01 = Monday (1) }
  result := FindDayOfWeek(2024, 1, 1);
  WriteLn('CALL FindDayOfWeek(2024, 1, 1) -> ', result);

  { FindDayOfWeek: 1984-01-01 = Sunday (0) - epoch }
  result := FindDayOfWeek(1984, 1, 1);
  WriteLn('CALL FindDayOfWeek(1984, 1, 1) -> ', result);

  { FindDayOfWeek: 2024-03-15 = Friday (5) }
  result := FindDayOfWeek(2024, 3, 15);
  WriteLn('CALL FindDayOfWeek(2024, 3, 15) -> ', result);

  { IsLeapYear }
  if IsLeapYear(2024) then WriteLn('CALL IsLeapYear(2024) -> 1')
  else WriteLn('CALL IsLeapYear(2024) -> 0');
  if IsLeapYear(2023) then WriteLn('CALL IsLeapYear(2023) -> 1')
  else WriteLn('CALL IsLeapYear(2023) -> 0');
  if IsLeapYear(1900) then WriteLn('CALL IsLeapYear(1900) -> 1')
  else WriteLn('CALL IsLeapYear(1900) -> 0');
  if IsLeapYear(2000) then WriteLn('CALL IsLeapYear(2000) -> 1')
  else WriteLn('CALL IsLeapYear(2000) -> 0');

  { DaysInMonthFunc }
  result := DaysInMonthFunc(2024, 2);
  WriteLn('CALL DaysInMonthFunc(2024, 2) -> ', result);
  result := DaysInMonthFunc(2023, 2);
  WriteLn('CALL DaysInMonthFunc(2023, 2) -> ', result);
end.
