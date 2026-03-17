// dateutil_wrapper.rs -- Rust translation of DATEUTIL.PAS pure functions
// Original: Copyright (C) 1985,1996 Derek G. Lane
// Source: C:\DOSBOX_C\SSM\SOURCE\DATEUTIL.PAS
//
// Compile to LLVM IR:
//   rustc --emit=llvm-ir -C opt-level=1 -o dateutil_rs.ll dateutil_wrapper.rs
//
// Run the IR with lli:
//   lli dateutil_rs.ll
//
// Compile native (trace comparison):
//   rustc -C opt-level=1 -o dateutil_rs.exe dateutil_wrapper.rs

/// Cumulative days before each month (1-indexed, index 0 unused)
const DAYS_IN_YEAR: [i32; 13] = [
    0, // index 0
    0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334,
];

/// Days per month (1-indexed, index 0 unused)
const DAYS_IN_MONTH_TABLE: [i32; 13] = [
    0, // index 0
    31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
];

struct DateRec {
    month: i32,
    day: i32,
    year: i32,
    hour: i32,
    minute: i32,
}

/// Difference in days between two dates (same-year or cross-year)
fn sub_dates(date1: &DateRec, date2: &DateRec) -> i32 {
    let mut days = DAYS_IN_YEAR[date1.month as usize] + date1.day
        - (DAYS_IN_YEAR[date2.month as usize] + date2.day);
    if date2.year != date1.year {
        days += 365 * (date1.year - date2.year);
    }
    days
}

/// Lexicographic date comparison (year, month, day, hour, minute)
fn compare_dates(date1: &DateRec, date2: &DateRec) -> i32 {
    if date1.year == date2.year {
        if date1.month == date2.month {
            if date1.day == date2.day {
                if date1.hour == date2.hour {
                    date1.minute - date2.minute
                } else {
                    date1.hour - date2.hour
                }
            } else {
                date1.day - date2.day
            }
        } else {
            date1.month - date2.month
        }
    } else {
        date1.year - date2.year
    }
}

/// Day-of-week from date, epoch 1984-01-01 = Sunday (0)
fn find_day_of_week(year: i32, month: i32, day: i32) -> i32 {
    let num_of_years = year - 1984;
    let mut num_of_days: f64 =
        num_of_years as f64 * 365.0 + ((num_of_years - 1) / 4) as f64;
    if num_of_years % 4 == 0 && month >= 3 {
        num_of_days += 1.0;
    }
    num_of_days += DAYS_IN_YEAR[month as usize] as f64 + day as f64;
    (num_of_days - (num_of_days / 7.0).floor() * 7.0) as i32
}

/// Gregorian leap year test
fn is_leap_year(year: i32) -> bool {
    (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
}

/// Days in a given month, accounting for leap years
fn days_in_month_func(year: i32, month: i32) -> i32 {
    if month == 2 && is_leap_year(year) {
        29
    } else {
        DAYS_IN_MONTH_TABLE[month as usize]
    }
}

fn main() {
    // SubDates: same month, different days
    let d1 = DateRec { month: 3, day: 15, year: 2024, hour: 10, minute: 30 };
    let d2 = DateRec { month: 3, day: 1, year: 2024, hour: 8, minute: 0 };
    let result = sub_dates(&d1, &d2);
    println!("CALL SubDates({{3/15/2024}}, {{3/1/2024}}) -> {result}");

    // SubDates: different years
    let d1 = DateRec { month: 1, day: 15, year: 2025, hour: 0, minute: 0 };
    let d2 = DateRec { month: 12, day: 15, year: 2024, hour: 0, minute: 0 };
    let result = sub_dates(&d1, &d2);
    println!("CALL SubDates({{1/15/2025}}, {{12/15/2024}}) -> {result}");

    // CompareDates: equal
    let d1 = DateRec { month: 6, day: 15, year: 2024, hour: 14, minute: 30 };
    let d2 = DateRec { month: 6, day: 15, year: 2024, hour: 14, minute: 30 };
    let result = compare_dates(&d1, &d2);
    println!("CALL CompareDates({{6/15/2024 14:30}}, {{6/15/2024 14:30}}) -> {result}");

    // CompareDates: different months
    let d2 = DateRec { month: 3, day: 15, year: 2024, hour: 14, minute: 30 };
    let result = compare_dates(&d1, &d2);
    println!("CALL CompareDates({{6/15/2024}}, {{3/15/2024}}) -> {result}");

    // CompareDates: different years
    let d1 = DateRec { month: 6, day: 15, year: 2025, hour: 14, minute: 30 };
    let d2 = DateRec { month: 3, day: 15, year: 2024, hour: 14, minute: 30 };
    let result = compare_dates(&d1, &d2);
    println!("CALL CompareDates({{2025}}, {{2024}}) -> {result}");

    // FindDayOfWeek
    let result = find_day_of_week(2024, 1, 1);
    println!("CALL FindDayOfWeek(2024, 1, 1) -> {result}");

    let result = find_day_of_week(1984, 1, 1);
    println!("CALL FindDayOfWeek(1984, 1, 1) -> {result}");

    let result = find_day_of_week(2024, 3, 15);
    println!("CALL FindDayOfWeek(2024, 3, 15) -> {result}");

    // IsLeapYear
    println!("CALL IsLeapYear(2024) -> {}", if is_leap_year(2024) { 1 } else { 0 });
    println!("CALL IsLeapYear(2023) -> {}", if is_leap_year(2023) { 1 } else { 0 });
    println!("CALL IsLeapYear(1900) -> {}", if is_leap_year(1900) { 1 } else { 0 });
    println!("CALL IsLeapYear(2000) -> {}", if is_leap_year(2000) { 1 } else { 0 });

    // DaysInMonthFunc
    let result = days_in_month_func(2024, 2);
    println!("CALL DaysInMonthFunc(2024, 2) -> {result}");
    let result = days_in_month_func(2023, 2);
    println!("CALL DaysInMonthFunc(2023, 2) -> {result}");
}
