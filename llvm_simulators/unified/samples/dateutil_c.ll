; ModuleID = 'dateutil_wrapper.c'
source_filename = "dateutil_wrapper.c"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc19.44.35224"

$printf = comdat any

$__local_stdio_printf_options = comdat any

$"??_C@_0CO@FAFKBKFE@CALL?5SubDates?$CI?$HL3?115?12024?$HN?0?5?$HL3?11?1@" = comdat any

$"??_C@_0DA@POFKDLMF@CALL?5SubDates?$CI?$HL1?115?12025?$HN?0?5?$HL12?11@" = comdat any

$"??_C@_0DP@HFNIMKGD@CALL?5CompareDates?$CI?$HL6?115?12024?514?3@" = comdat any

$"??_C@_0DD@CCFADKMM@CALL?5CompareDates?$CI?$HL6?115?12024?$HN?0?5?$HL@" = comdat any

$"??_C@_0CJ@HNMGABF@CALL?5CompareDates?$CI?$HL2025?$HN?0?5?$HL2024?$HN@" = comdat any

$"??_C@_0CG@NOHLODFK@CALL?5FindDayOfWeek?$CI2024?0?51?0?51?$CJ?5?9@" = comdat any

$"??_C@_0CG@LHACKCEH@CALL?5FindDayOfWeek?$CI1984?0?51?0?51?$CJ?5?9@" = comdat any

$"??_C@_0CH@FMDOJOHI@CALL?5FindDayOfWeek?$CI2024?0?53?0?515?$CJ?5@" = comdat any

$"??_C@_0BN@FNCOPIFH@CALL?5IsLeapYear?$CI2024?$CJ?5?9?$DO?5?$CFd?6?$AA@" = comdat any

$"??_C@_0BN@LPPCODCO@CALL?5IsLeapYear?$CI2023?$CJ?5?9?$DO?5?$CFd?6?$AA@" = comdat any

$"??_C@_0BN@CMMKLHLD@CALL?5IsLeapYear?$CI1900?$CJ?5?9?$DO?5?$CFd?6?$AA@" = comdat any

$"??_C@_0BN@MKJOBOM@CALL?5IsLeapYear?$CI2000?$CJ?5?9?$DO?5?$CFd?6?$AA@" = comdat any

$"??_C@_0CF@GKECHDC@CALL?5DaysInMonthFunc?$CI2024?0?52?$CJ?5?9?$DO@" = comdat any

$"??_C@_0CF@HLNHCBGK@CALL?5DaysInMonthFunc?$CI2023?0?52?$CJ?5?9?$DO@" = comdat any

@DaysInYear = internal unnamed_addr constant [13 x i32] [i32 0, i32 0, i32 31, i32 59, i32 90, i32 120, i32 151, i32 181, i32 212, i32 243, i32 273, i32 304, i32 334], align 16
@DaysInMonthTable = internal unnamed_addr constant [13 x i32] [i32 0, i32 31, i32 28, i32 31, i32 30, i32 31, i32 30, i32 31, i32 31, i32 30, i32 31, i32 30, i32 31], align 16
@"??_C@_0CO@FAFKBKFE@CALL?5SubDates?$CI?$HL3?115?12024?$HN?0?5?$HL3?11?1@" = linkonce_odr dso_local unnamed_addr constant [46 x i8] c"CALL SubDates({3/15/2024}, {3/1/2024}) -> %d\0A\00", comdat, align 1
@"??_C@_0DA@POFKDLMF@CALL?5SubDates?$CI?$HL1?115?12025?$HN?0?5?$HL12?11@" = linkonce_odr dso_local unnamed_addr constant [48 x i8] c"CALL SubDates({1/15/2025}, {12/15/2024}) -> %d\0A\00", comdat, align 1
@"??_C@_0DP@HFNIMKGD@CALL?5CompareDates?$CI?$HL6?115?12024?514?3@" = linkonce_odr dso_local unnamed_addr constant [63 x i8] c"CALL CompareDates({6/15/2024 14:30}, {6/15/2024 14:30}) -> %d\0A\00", comdat, align 1
@"??_C@_0DD@CCFADKMM@CALL?5CompareDates?$CI?$HL6?115?12024?$HN?0?5?$HL@" = linkonce_odr dso_local unnamed_addr constant [51 x i8] c"CALL CompareDates({6/15/2024}, {3/15/2024}) -> %d\0A\00", comdat, align 1
@"??_C@_0CJ@HNMGABF@CALL?5CompareDates?$CI?$HL2025?$HN?0?5?$HL2024?$HN@" = linkonce_odr dso_local unnamed_addr constant [41 x i8] c"CALL CompareDates({2025}, {2024}) -> %d\0A\00", comdat, align 1
@"??_C@_0CG@NOHLODFK@CALL?5FindDayOfWeek?$CI2024?0?51?0?51?$CJ?5?9@" = linkonce_odr dso_local unnamed_addr constant [38 x i8] c"CALL FindDayOfWeek(2024, 1, 1) -> %d\0A\00", comdat, align 1
@"??_C@_0CG@LHACKCEH@CALL?5FindDayOfWeek?$CI1984?0?51?0?51?$CJ?5?9@" = linkonce_odr dso_local unnamed_addr constant [38 x i8] c"CALL FindDayOfWeek(1984, 1, 1) -> %d\0A\00", comdat, align 1
@"??_C@_0CH@FMDOJOHI@CALL?5FindDayOfWeek?$CI2024?0?53?0?515?$CJ?5@" = linkonce_odr dso_local unnamed_addr constant [39 x i8] c"CALL FindDayOfWeek(2024, 3, 15) -> %d\0A\00", comdat, align 1
@"??_C@_0BN@FNCOPIFH@CALL?5IsLeapYear?$CI2024?$CJ?5?9?$DO?5?$CFd?6?$AA@" = linkonce_odr dso_local unnamed_addr constant [29 x i8] c"CALL IsLeapYear(2024) -> %d\0A\00", comdat, align 1
@"??_C@_0BN@LPPCODCO@CALL?5IsLeapYear?$CI2023?$CJ?5?9?$DO?5?$CFd?6?$AA@" = linkonce_odr dso_local unnamed_addr constant [29 x i8] c"CALL IsLeapYear(2023) -> %d\0A\00", comdat, align 1
@"??_C@_0BN@CMMKLHLD@CALL?5IsLeapYear?$CI1900?$CJ?5?9?$DO?5?$CFd?6?$AA@" = linkonce_odr dso_local unnamed_addr constant [29 x i8] c"CALL IsLeapYear(1900) -> %d\0A\00", comdat, align 1
@"??_C@_0BN@MKJOBOM@CALL?5IsLeapYear?$CI2000?$CJ?5?9?$DO?5?$CFd?6?$AA@" = linkonce_odr dso_local unnamed_addr constant [29 x i8] c"CALL IsLeapYear(2000) -> %d\0A\00", comdat, align 1
@"??_C@_0CF@GKECHDC@CALL?5DaysInMonthFunc?$CI2024?0?52?$CJ?5?9?$DO@" = linkonce_odr dso_local unnamed_addr constant [37 x i8] c"CALL DaysInMonthFunc(2024, 2) -> %d\0A\00", comdat, align 1
@"??_C@_0CF@HLNHCBGK@CALL?5DaysInMonthFunc?$CI2023?0?52?$CJ?5?9?$DO@" = linkonce_odr dso_local unnamed_addr constant [37 x i8] c"CALL DaysInMonthFunc(2023, 2) -> %d\0A\00", comdat, align 1
@__local_stdio_printf_options._OptionsStorage = internal global i64 0, align 8

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @SubDates(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, i32 noundef %5) local_unnamed_addr #0 {
  %7 = sext i32 %0 to i64
  %8 = getelementptr inbounds [13 x i32], ptr @DaysInYear, i64 0, i64 %7
  %9 = load i32, ptr %8, align 4
  %10 = sext i32 %3 to i64
  %11 = getelementptr inbounds [13 x i32], ptr @DaysInYear, i64 0, i64 %10
  %12 = load i32, ptr %11, align 4
  %13 = sub nsw i32 %2, %5
  %14 = mul i32 %13, 365
  %15 = sub i32 %1, %4
  %16 = add i32 %15, %14
  %17 = add i32 %16, %9
  %18 = sub i32 %17, %12
  ret i32 %18
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @CompareDates(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, i32 noundef %5, i32 noundef %6, i32 noundef %7, i32 noundef %8, i32 noundef %9) local_unnamed_addr #0 {
  %11 = icmp eq i32 %0, %5
  br i1 %11, label %12, label %26

12:                                               ; preds = %10
  %13 = icmp eq i32 %1, %6
  br i1 %13, label %14, label %24

14:                                               ; preds = %12
  %15 = icmp eq i32 %2, %7
  br i1 %15, label %16, label %22

16:                                               ; preds = %14
  %17 = icmp eq i32 %3, %8
  br i1 %17, label %18, label %20

18:                                               ; preds = %16
  %19 = sub nsw i32 %4, %9
  br label %28

20:                                               ; preds = %16
  %21 = sub nsw i32 %3, %8
  br label %28

22:                                               ; preds = %14
  %23 = sub nsw i32 %2, %7
  br label %28

24:                                               ; preds = %12
  %25 = sub nsw i32 %1, %6
  br label %28

26:                                               ; preds = %10
  %27 = sub nsw i32 %0, %5
  br label %28

28:                                               ; preds = %26, %24, %22, %20, %18
  %29 = phi i32 [ %19, %18 ], [ %21, %20 ], [ %23, %22 ], [ %25, %24 ], [ %27, %26 ]
  ret i32 %29
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @FindDayOfWeek(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = add nsw i32 %0, -1984
  %5 = sitofp i32 %4 to double
  %6 = add nsw i32 %0, -1985
  %7 = sdiv i32 %6, 4
  %8 = sitofp i32 %7 to double
  %9 = tail call double @llvm.fmuladd.f64(double %5, double 3.650000e+02, double %8)
  %10 = and i32 %0, 3
  %11 = icmp eq i32 %10, 0
  %12 = icmp sgt i32 %1, 2
  %13 = and i1 %11, %12
  %14 = fadd double %9, 1.000000e+00
  %15 = select i1 %13, double %14, double %9
  %16 = sext i32 %1 to i64
  %17 = getelementptr inbounds [13 x i32], ptr @DaysInYear, i64 0, i64 %16
  %18 = load i32, ptr %17, align 4
  %19 = sitofp i32 %18 to double
  %20 = fadd double %15, %19
  %21 = sitofp i32 %2 to double
  %22 = fadd double %20, %21
  %23 = fdiv double %22, 7.000000e+00
  %24 = tail call double @llvm.floor.f64(double %23)
  %25 = fneg double %24
  %26 = tail call double @llvm.fmuladd.f64(double %25, double 7.000000e+00, double %22)
  %27 = fptosi double %26 to i32
  ret i32 %27
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.floor.f64(double) #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 0, 2) i32 @IsLeapYear(i32 noundef %0) local_unnamed_addr #0 {
  %2 = and i32 %0, 3
  %3 = icmp ne i32 %2, 0
  %4 = srem i32 %0, 100
  %5 = icmp eq i32 %4, 0
  %6 = or i1 %3, %5
  br i1 %6, label %7, label %11

7:                                                ; preds = %1
  %8 = srem i32 %0, 400
  %9 = icmp eq i32 %8, 0
  %10 = zext i1 %9 to i32
  br label %11

11:                                               ; preds = %1, %7
  %12 = phi i32 [ %10, %7 ], [ 1, %1 ]
  ret i32 %12
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @DaysInMonthFunc(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp eq i32 %1, 2
  br i1 %3, label %4, label %13

4:                                                ; preds = %2
  %5 = and i32 %0, 3
  %6 = icmp ne i32 %5, 0
  %7 = srem i32 %0, 100
  %8 = icmp eq i32 %7, 0
  %9 = or i1 %6, %8
  %10 = srem i32 %0, 400
  %11 = icmp ne i32 %10, 0
  %12 = and i1 %11, %9
  br i1 %12, label %13, label %17

13:                                               ; preds = %4, %2
  %14 = sext i32 %1 to i64
  %15 = getelementptr inbounds [13 x i32], ptr @DaysInMonthTable, i64 0, i64 %14
  %16 = load i32, ptr %15, align 4
  br label %17

17:                                               ; preds = %4, %13
  %18 = phi i32 [ %16, %13 ], [ 29, %4 ]
  ret i32 %18
}

; Function Attrs: nounwind uwtable
define dso_local noundef i32 @main() local_unnamed_addr #3 {
  %1 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @"??_C@_0CO@FAFKBKFE@CALL?5SubDates?$CI?$HL3?115?12024?$HN?0?5?$HL3?11?1@", i32 noundef 14)
  %2 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @"??_C@_0DA@POFKDLMF@CALL?5SubDates?$CI?$HL1?115?12025?$HN?0?5?$HL12?11@", i32 noundef 31)
  %3 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @"??_C@_0DP@HFNIMKGD@CALL?5CompareDates?$CI?$HL6?115?12024?514?3@", i32 noundef 0)
  %4 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @"??_C@_0DD@CCFADKMM@CALL?5CompareDates?$CI?$HL6?115?12024?$HN?0?5?$HL@", i32 noundef 3)
  %5 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @"??_C@_0CJ@HNMGABF@CALL?5CompareDates?$CI?$HL2025?$HN?0?5?$HL2024?$HN@", i32 noundef 1)
  %6 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @"??_C@_0CG@NOHLODFK@CALL?5FindDayOfWeek?$CI2024?0?51?0?51?$CJ?5?9@", i32 noundef 1)
  %7 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @"??_C@_0CG@LHACKCEH@CALL?5FindDayOfWeek?$CI1984?0?51?0?51?$CJ?5?9@", i32 noundef 1)
  %8 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @"??_C@_0CH@FMDOJOHI@CALL?5FindDayOfWeek?$CI2024?0?53?0?515?$CJ?5@", i32 noundef 5)
  %9 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @"??_C@_0BN@FNCOPIFH@CALL?5IsLeapYear?$CI2024?$CJ?5?9?$DO?5?$CFd?6?$AA@", i32 noundef 1)
  %10 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @"??_C@_0BN@LPPCODCO@CALL?5IsLeapYear?$CI2023?$CJ?5?9?$DO?5?$CFd?6?$AA@", i32 noundef 0)
  %11 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @"??_C@_0BN@CMMKLHLD@CALL?5IsLeapYear?$CI1900?$CJ?5?9?$DO?5?$CFd?6?$AA@", i32 noundef 0)
  %12 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @"??_C@_0BN@MKJOBOM@CALL?5IsLeapYear?$CI2000?$CJ?5?9?$DO?5?$CFd?6?$AA@", i32 noundef 1)
  %13 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @"??_C@_0CF@GKECHDC@CALL?5DaysInMonthFunc?$CI2024?0?52?$CJ?5?9?$DO@", i32 noundef 29)
  %14 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @"??_C@_0CF@HLNHCBGK@CALL?5DaysInMonthFunc?$CI2023?0?52?$CJ?5?9?$DO@", i32 noundef 28)
  ret i32 0
}

; Function Attrs: inlinehint nounwind uwtable
define linkonce_odr dso_local i32 @printf(ptr noundef %0, ...) local_unnamed_addr #4 comdat {
  %2 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #8
  call void @llvm.va_start.p0(ptr nonnull %2)
  %3 = load ptr, ptr %2, align 8
  %4 = call ptr @__acrt_iob_func(i32 noundef 1) #8
  %5 = call ptr @__local_stdio_printf_options()
  %6 = load i64, ptr %5, align 8
  %7 = call i32 @__stdio_common_vfprintf(i64 noundef %6, ptr noundef %4, ptr noundef %0, ptr noundef null, ptr noundef %3) #8
  call void @llvm.va_end.p0(ptr %2)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #8
  ret i32 %7
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_start.p0(ptr) #5

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_end.p0(ptr) #5

; Function Attrs: noinline nounwind uwtable
define linkonce_odr dso_local ptr @__local_stdio_printf_options() local_unnamed_addr #6 comdat {
  ret ptr @__local_stdio_printf_options._OptionsStorage
}

declare dso_local ptr @__acrt_iob_func(i32 noundef) local_unnamed_addr #7

declare dso_local i32 @__stdio_common_vfprintf(i64 noundef, ptr noundef, ptr noundef, ptr noundef, ptr noundef) local_unnamed_addr #7

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { inlinehint nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #6 = { noinline nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #7 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #8 = { nounwind }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5, !6}
!llvm.ident = !{!7}

!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "clang version 21.1.8", isOptimized: true, runtimeVersion: 0, emissionKind: NoDebug, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "dateutil_wrapper.c", directory: "D:\\MUSIQ\\ALGT\\llvm_simulators\\unified\\samples")
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 2}
!4 = !{i32 8, !"PIC Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 1, !"MaxTLSAlign", i32 65536}
!7 = !{!"clang version 21.1.8"}
