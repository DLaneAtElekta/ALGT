/* dateutil_wrapper.ts -- TypeScript translation of DATEUTIL.PAS pure functions */
/* Original: Copyright (C) 1985,1996 Derek G. Lane */
/* Source: C:\DOSBOX_C\SSM\SOURCE\DATEUTIL.PAS */
/*
 * Run natively:
 *   npx ts-node dateutil_wrapper.ts
 *   # or: tsc dateutil_wrapper.ts && node dateutil_wrapper.js
 *
 * Note: TypeScript compiles to JavaScript (V8 JIT), not LLVM IR.
 * For LLVM IR trace comparison, use the C version:
 *   clang -S -emit-llvm -O1 -o dateutil.ll dateutil_wrapper.c
 *   lli dateutil.ll
 */
var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
var DaysInYear = [
    0, /* index 0 unused */
    0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334,
];
var DaysInMonthTable = [
    0, /* index 0 unused */
    31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
];
/** Difference in days between two dates (same-year or cross-year) */
function subDates(date1, date2) {
    var days = DaysInYear[date1.month] + date1.day -
        (DaysInYear[date2.month] + date2.day);
    if (date2.year !== date1.year) {
        days = days + 365 * (date1.year - date2.year);
    }
    return days;
}
/** Lexicographic date comparison (year, month, day, hour, minute) */
function compareDates(date1, date2) {
    if (date1.year === date2.year) {
        if (date1.month === date2.month) {
            if (date1.day === date2.day) {
                if (date1.hour === date2.hour) {
                    return date1.minute - date2.minute;
                }
                else {
                    return date1.hour - date2.hour;
                }
            }
            else {
                return date1.day - date2.day;
            }
        }
        else {
            return date1.month - date2.month;
        }
    }
    else {
        return date1.year - date2.year;
    }
}
/** Day-of-week from date, epoch 1984-01-01 = Sunday (0) */
function findDayOfWeek(year, month, day) {
    var numOfYears = year - 1984;
    var numOfDays = numOfYears * 365 + Math.trunc((numOfYears - 1) / 4);
    if (numOfYears % 4 === 0) {
        if (month >= 3) {
            numOfDays = numOfDays + 1;
        }
    }
    numOfDays = numOfDays + DaysInYear[month] + day;
    return Math.trunc(numOfDays - Math.floor(numOfDays / 7) * 7);
}
/** Gregorian leap year test */
function isLeapYear(year) {
    return (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0;
}
/** Days in a given month, accounting for leap years */
function daysInMonthFunc(year, month) {
    if (month === 2 && isLeapYear(year)) {
        return 29;
    }
    return DaysInMonthTable[month];
}
// --- Trace output (matches C and Pascal versions) ---
var d1 = { month: 3, day: 15, year: 2024, hour: 10, minute: 30 };
var d2 = { month: 3, day: 1, year: 2024, hour: 8, minute: 0 };
var result;
result = subDates(d1, d2);
console.log("CALL SubDates({3/15/2024}, {3/1/2024}) -> ".concat(result));
d1 = { month: 1, day: 15, year: 2025, hour: 0, minute: 0 };
d2 = { month: 12, day: 15, year: 2024, hour: 0, minute: 0 };
result = subDates(d1, d2);
console.log("CALL SubDates({1/15/2025}, {12/15/2024}) -> ".concat(result));
d1 = { month: 6, day: 15, year: 2024, hour: 14, minute: 30 };
d2 = { month: 6, day: 15, year: 2024, hour: 14, minute: 30 };
result = compareDates(d1, d2);
console.log("CALL CompareDates({6/15/2024 14:30}, {6/15/2024 14:30}) -> ".concat(result));
d2 = __assign(__assign({}, d2), { month: 3 });
result = compareDates(d1, d2);
console.log("CALL CompareDates({6/15/2024}, {3/15/2024}) -> ".concat(result));
d1 = __assign(__assign({}, d1), { year: 2025 });
d2 = __assign(__assign({}, d2), { year: 2024 });
result = compareDates(d1, d2);
console.log("CALL CompareDates({2025}, {2024}) -> ".concat(result));
result = findDayOfWeek(2024, 1, 1);
console.log("CALL FindDayOfWeek(2024, 1, 1) -> ".concat(result));
result = findDayOfWeek(1984, 1, 1);
console.log("CALL FindDayOfWeek(1984, 1, 1) -> ".concat(result));
result = findDayOfWeek(2024, 3, 15);
console.log("CALL FindDayOfWeek(2024, 3, 15) -> ".concat(result));
console.log("CALL IsLeapYear(2024) -> ".concat(isLeapYear(2024) ? 1 : 0));
console.log("CALL IsLeapYear(2023) -> ".concat(isLeapYear(2023) ? 1 : 0));
console.log("CALL IsLeapYear(1900) -> ".concat(isLeapYear(1900) ? 1 : 0));
console.log("CALL IsLeapYear(2000) -> ".concat(isLeapYear(2000) ? 1 : 0));
result = daysInMonthFunc(2024, 2);
console.log("CALL DaysInMonthFunc(2024, 2) -> ".concat(result));
result = daysInMonthFunc(2023, 2);
console.log("CALL DaysInMonthFunc(2023, 2) -> ".concat(result));
