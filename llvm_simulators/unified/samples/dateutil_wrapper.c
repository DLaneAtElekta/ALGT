/* dateutil_wrapper.c -- C translation of DATEUTIL.PAS pure functions */
/* Original: Copyright (C) 1985,1996 Derek G. Lane */
/* Source: C:\DOSBOX_C\SSM\SOURCE\DATEUTIL.PAS */
/*
 * Compile to LLVM IR:
 *   clang -S -emit-llvm -O1 -o dateutil.ll dateutil_wrapper.c
 *
 * Compile native (trace comparison):
 *   clang -O1 -o dateutil_test.exe dateutil_wrapper.c
 */

#include <stdio.h>
#include <math.h>

/* DaysInYear lookup: cumulative days before each month (1-indexed) */
static const int DaysInYear[13] = {
    0,  /* dummy for index 0 */
    0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334
};

static const int DaysInMonthTable[13] = {
    0,  /* dummy for index 0 */
    31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
};

/* SubDates: difference in days between two dates (same-year or cross-year) */
int SubDates(int m1, int d1, int y1, int m2, int d2, int y2) {
    int days = DaysInYear[m1] + d1 - (DaysInYear[m2] + d2);
    if (y2 != y1)
        days = days + 365 * (y1 - y2);
    return days;
}

/* CompareDates: lexicographic date comparison (year, month, day, hour, minute) */
int CompareDates(int y1, int mo1, int d1, int h1, int mi1,
                 int y2, int mo2, int d2, int h2, int mi2) {
    if (y1 == y2) {
        if (mo1 == mo2) {
            if (d1 == d2) {
                if (h1 == h2)
                    return mi1 - mi2;
                else
                    return h1 - h2;
            } else
                return d1 - d2;
        } else
            return mo1 - mo2;
    } else
        return y1 - y2;
}

/* FindDayOfWeek: day-of-week from date, epoch 1984-01-01
 * Returns 0-6 (the original Pascal maps these to day names) */
int FindDayOfWeek(int year, int month, int day) {
    int numOfYears = year - 1984;
    double numOfDays = numOfYears * 365.0 + ((numOfYears - 1) / 4);
    if ((numOfYears % 4) == 0) {
        if (month >= 3)
            numOfDays = numOfDays + 1.0;
    }
    numOfDays = numOfDays + DaysInYear[month] + day;
    return (int)(numOfDays - floor(numOfDays / 7.0) * 7.0);
}

/* IsLeapYear: Gregorian leap year test */
int IsLeapYear(int year) {
    return ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
}

/* DaysInMonthFunc: days in a given month, accounting for leap years */
int DaysInMonthFunc(int year, int month) {
    if (month == 2 && IsLeapYear(year))
        return 29;
    return DaysInMonthTable[month];
}

int main(void) {
    int result;

    /* SubDates: same month, different days */
    result = SubDates(3, 15, 2024, 3, 1, 2024);
    printf("CALL SubDates({3/15/2024}, {3/1/2024}) -> %d\n", result);

    /* SubDates: different years */
    result = SubDates(1, 15, 2025, 12, 15, 2024);
    printf("CALL SubDates({1/15/2025}, {12/15/2024}) -> %d\n", result);

    /* CompareDates: equal */
    result = CompareDates(2024, 6, 15, 14, 30, 2024, 6, 15, 14, 30);
    printf("CALL CompareDates({6/15/2024 14:30}, {6/15/2024 14:30}) -> %d\n", result);

    /* CompareDates: different months */
    result = CompareDates(2024, 6, 15, 14, 30, 2024, 3, 15, 14, 30);
    printf("CALL CompareDates({6/15/2024}, {3/15/2024}) -> %d\n", result);

    /* CompareDates: different years */
    result = CompareDates(2025, 6, 15, 14, 30, 2024, 3, 15, 14, 30);
    printf("CALL CompareDates({2025}, {2024}) -> %d\n", result);

    /* FindDayOfWeek */
    result = FindDayOfWeek(2024, 1, 1);
    printf("CALL FindDayOfWeek(2024, 1, 1) -> %d\n", result);

    result = FindDayOfWeek(1984, 1, 1);
    printf("CALL FindDayOfWeek(1984, 1, 1) -> %d\n", result);

    result = FindDayOfWeek(2024, 3, 15);
    printf("CALL FindDayOfWeek(2024, 3, 15) -> %d\n", result);

    /* IsLeapYear */
    printf("CALL IsLeapYear(2024) -> %d\n", IsLeapYear(2024));
    printf("CALL IsLeapYear(2023) -> %d\n", IsLeapYear(2023));
    printf("CALL IsLeapYear(1900) -> %d\n", IsLeapYear(1900));
    printf("CALL IsLeapYear(2000) -> %d\n", IsLeapYear(2000));

    /* DaysInMonthFunc */
    result = DaysInMonthFunc(2024, 2);
    printf("CALL DaysInMonthFunc(2024, 2) -> %d\n", result);
    result = DaysInMonthFunc(2023, 2);
    printf("CALL DaysInMonthFunc(2023, 2) -> %d\n", result);

    return 0;
}
