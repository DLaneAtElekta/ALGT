; ModuleID = 'vectorbase_wrapper.cpp'
source_filename = "vectorbase_wrapper.cpp"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc19.44.35223"

%struct.Vec3 = type { i32, [3 x double] }

$printf = comdat any

$__local_stdio_printf_options = comdat any

$"??_C@_0CE@EAPGDEGH@CALL?5Vec3_getLength?$CI?$HL3?04?00?$HN?$CJ?5?9?$DO?5@" = comdat any

$"??_C@_0CE@NBHHDMCK@CALL?5Vec3_getLength?$CI?$HL1?02?03?$HN?$CJ?5?9?$DO?5@" = comdat any

$"??_C@_0CH@FNCNBJHL@CALL?5Vec3_dot?$CI?$HL1?00?00?$HN?0?5?$HL0?01?00?$HN?$CJ?5@" = comdat any

$"??_C@_0CH@HOKEFIIH@CALL?5Vec3_dot?$CI?$HL1?02?03?$HN?0?5?$HL4?05?06?$HN?$CJ?5@" = comdat any

$"??_C@_0CO@GLKAJKGB@CALL?5Vec3_normalize?$CI?$HL3?04?00?$HN?$CJ?5?9?$DO?5@" = comdat any

$"??_C@_0DE@ILBAJPJD@CALL?5Vec3_add?$CI?$HL1?02?03?$HN?0?5?$HL10?020?030@" = comdat any

$"??_C@_0CP@POBEJGAG@CALL?5Vec3_scale?$CI?$HL1?02?03?$HN?0?52?45?$CJ?5?9?$DO@" = comdat any

$"??_C@_0DD@OJGLBFFP@CALL?5Vec3_cross?$CI?$HL1?00?00?$HN?0?5?$HL0?01?00?$HN@" = comdat any

$"?_OptionsStorage@?1??__local_stdio_printf_options@@9@4_KA" = comdat any

@"??_C@_0CE@EAPGDEGH@CALL?5Vec3_getLength?$CI?$HL3?04?00?$HN?$CJ?5?9?$DO?5@" = linkonce_odr dso_local unnamed_addr constant [36 x i8] c"CALL Vec3_getLength({3,4,0}) -> %g\0A\00", comdat, align 1
@"??_C@_0CE@NBHHDMCK@CALL?5Vec3_getLength?$CI?$HL1?02?03?$HN?$CJ?5?9?$DO?5@" = linkonce_odr dso_local unnamed_addr constant [36 x i8] c"CALL Vec3_getLength({1,2,3}) -> %g\0A\00", comdat, align 1
@"??_C@_0CH@FNCNBJHL@CALL?5Vec3_dot?$CI?$HL1?00?00?$HN?0?5?$HL0?01?00?$HN?$CJ?5@" = linkonce_odr dso_local unnamed_addr constant [39 x i8] c"CALL Vec3_dot({1,0,0}, {0,1,0}) -> %g\0A\00", comdat, align 1
@"??_C@_0CH@HOKEFIIH@CALL?5Vec3_dot?$CI?$HL1?02?03?$HN?0?5?$HL4?05?06?$HN?$CJ?5@" = linkonce_odr dso_local unnamed_addr constant [39 x i8] c"CALL Vec3_dot({1,2,3}, {4,5,6}) -> %g\0A\00", comdat, align 1
@"??_C@_0CO@GLKAJKGB@CALL?5Vec3_normalize?$CI?$HL3?04?00?$HN?$CJ?5?9?$DO?5@" = linkonce_odr dso_local unnamed_addr constant [46 x i8] c"CALL Vec3_normalize({3,4,0}) -> {%g, %g, %g}\0A\00", comdat, align 1
@"??_C@_0DE@ILBAJPJD@CALL?5Vec3_add?$CI?$HL1?02?03?$HN?0?5?$HL10?020?030@" = linkonce_odr dso_local unnamed_addr constant [52 x i8] c"CALL Vec3_add({1,2,3}, {10,20,30}) -> {%g, %g, %g}\0A\00", comdat, align 1
@"??_C@_0CP@POBEJGAG@CALL?5Vec3_scale?$CI?$HL1?02?03?$HN?0?52?45?$CJ?5?9?$DO@" = linkonce_odr dso_local unnamed_addr constant [47 x i8] c"CALL Vec3_scale({1,2,3}, 2.5) -> {%g, %g, %g}\0A\00", comdat, align 1
@"??_C@_0DD@OJGLBFFP@CALL?5Vec3_cross?$CI?$HL1?00?00?$HN?0?5?$HL0?01?00?$HN@" = linkonce_odr dso_local unnamed_addr constant [51 x i8] c"CALL Vec3_cross({1,0,0}, {0,1,0}) -> {%g, %g, %g}\0A\00", comdat, align 1
@"?_OptionsStorage@?1??__local_stdio_printf_options@@9@4_KA" = linkonce_odr dso_local global i64 0, comdat, align 8

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) uwtable
define dso_local void @Vec3_init(ptr noundef writeonly captures(none) initializes((0, 4), (8, 32)) %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  store i32 3, ptr %0, align 8
  %5 = getelementptr inbounds nuw i8, ptr %0, i64 8
  store double %1, ptr %5, align 8
  %6 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store double %2, ptr %6, align 8
  %7 = getelementptr inbounds nuw i8, ptr %0, i64 24
  store double %3, ptr %7, align 8
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define dso_local double @Vec3_getElement(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #1 {
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %4 = sext i32 %1 to i64
  %5 = getelementptr inbounds [3 x double], ptr %3, i64 0, i64 %4
  %6 = load double, ptr %5, align 8
  ret double %6
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) uwtable
define dso_local void @Vec3_setElement(ptr noundef writeonly captures(none) %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %5 = sext i32 %1 to i64
  %6 = getelementptr inbounds [3 x double], ptr %4, i64 0, i64 %5
  store double %2, ptr %6, align 8
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define dso_local i32 @Vec3_getDim(ptr noundef readonly captures(none) %0) local_unnamed_addr #1 {
  %2 = load i32, ptr %0, align 8
  ret i32 %2
}

; Function Attrs: mustprogress nofree norecurse nounwind memory(argmem: read, errnomem: write) uwtable
define dso_local double @Vec3_getLength(ptr noundef readonly captures(none) %0) local_unnamed_addr #2 {
  %2 = load i32, ptr %0, align 8
  %3 = icmp sgt i32 %2, 0
  br i1 %3, label %4, label %7

4:                                                ; preds = %1
  %5 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %6 = zext nneg i32 %2 to i64
  br label %10

7:                                                ; preds = %10, %1
  %8 = phi double [ 0.000000e+00, %1 ], [ %15, %10 ]
  %9 = tail call double @sqrt(double noundef %8) #15
  ret double %9

10:                                               ; preds = %4, %10
  %11 = phi i64 [ 0, %4 ], [ %16, %10 ]
  %12 = phi double [ 0.000000e+00, %4 ], [ %15, %10 ]
  %13 = getelementptr inbounds nuw [3 x double], ptr %5, i64 0, i64 %11
  %14 = load double, ptr %13, align 8
  %15 = tail call double @llvm.fmuladd.f64(double %14, double %14, double %12)
  %16 = add nuw nsw i64 %11, 1
  %17 = icmp eq i64 %16, %6
  br i1 %17, label %7, label %10, !llvm.loop !13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #3

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(errnomem: write)
declare dso_local double @sqrt(double noundef) local_unnamed_addr #5

; Function Attrs: mustprogress nofree norecurse nounwind memory(argmem: readwrite, errnomem: write) uwtable
define dso_local void @Vec3_normalize(ptr noundef captures(none) %0) local_unnamed_addr #6 {
  %2 = load i32, ptr %0, align 8
  %3 = icmp sgt i32 %2, 0
  br i1 %3, label %4, label %15

4:                                                ; preds = %1
  %5 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %6 = zext nneg i32 %2 to i64
  br label %7

7:                                                ; preds = %7, %4
  %8 = phi i64 [ 0, %4 ], [ %13, %7 ]
  %9 = phi double [ 0.000000e+00, %4 ], [ %12, %7 ]
  %10 = getelementptr inbounds nuw [3 x double], ptr %5, i64 0, i64 %8
  %11 = load double, ptr %10, align 8
  %12 = tail call double @llvm.fmuladd.f64(double %11, double %11, double %9)
  %13 = add nuw nsw i64 %8, 1
  %14 = icmp eq i64 %13, %6
  br i1 %14, label %15, label %7, !llvm.loop !13

15:                                               ; preds = %7, %1
  %16 = phi double [ 0.000000e+00, %1 ], [ %12, %7 ]
  %17 = tail call double @sqrt(double noundef %16) #15
  %18 = fcmp ogt double %17, 0.000000e+00
  br i1 %18, label %19, label %32

19:                                               ; preds = %15
  %20 = load i32, ptr %0, align 8
  %21 = icmp sgt i32 %20, 0
  br i1 %21, label %22, label %32

22:                                               ; preds = %19
  %23 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %24 = zext nneg i32 %20 to i64
  br label %25

25:                                               ; preds = %22, %25
  %26 = phi i64 [ 0, %22 ], [ %30, %25 ]
  %27 = getelementptr inbounds nuw [3 x double], ptr %23, i64 0, i64 %26
  %28 = load double, ptr %27, align 8
  %29 = fdiv double %28, %17
  store double %29, ptr %27, align 8
  %30 = add nuw nsw i64 %26, 1
  %31 = icmp eq i64 %30, %24
  br i1 %31, label %32, label %25, !llvm.loop !16

32:                                               ; preds = %25, %19, %15
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define dso_local double @Vec3_dot(ptr noundef readonly captures(none) %0, ptr noundef readonly captures(none) %1) local_unnamed_addr #1 {
  %3 = load i32, ptr %0, align 8
  %4 = icmp sgt i32 %3, 0
  br i1 %4, label %5, label %9

5:                                                ; preds = %2
  %6 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %7 = getelementptr inbounds nuw i8, ptr %1, i64 8
  %8 = zext nneg i32 %3 to i64
  br label %11

9:                                                ; preds = %11, %2
  %10 = phi double [ 0.000000e+00, %2 ], [ %18, %11 ]
  ret double %10

11:                                               ; preds = %5, %11
  %12 = phi i64 [ 0, %5 ], [ %19, %11 ]
  %13 = phi double [ 0.000000e+00, %5 ], [ %18, %11 ]
  %14 = getelementptr inbounds nuw [3 x double], ptr %6, i64 0, i64 %12
  %15 = load double, ptr %14, align 8
  %16 = getelementptr inbounds nuw [3 x double], ptr %7, i64 0, i64 %12
  %17 = load double, ptr %16, align 8
  %18 = tail call double @llvm.fmuladd.f64(double %15, double %17, double %13)
  %19 = add nuw nsw i64 %12, 1
  %20 = icmp eq i64 %19, %8
  br i1 %20, label %9, label %11, !llvm.loop !17
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable
define dso_local void @Vec3_add(ptr noundef readonly captures(none) %0, ptr noundef readonly captures(none) %1, ptr noundef writeonly captures(none) initializes((0, 4)) %2) local_unnamed_addr #7 {
  %4 = load i32, ptr %0, align 8
  store i32 %4, ptr %2, align 8
  %5 = load i32, ptr %0, align 8
  %6 = icmp sgt i32 %5, 0
  br i1 %6, label %7, label %11

7:                                                ; preds = %3
  %8 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %9 = getelementptr inbounds nuw i8, ptr %1, i64 8
  %10 = getelementptr inbounds nuw i8, ptr %2, i64 8
  br label %12

11:                                               ; preds = %12, %3
  ret void

12:                                               ; preds = %7, %12
  %13 = phi i64 [ 0, %7 ], [ %20, %12 ]
  %14 = getelementptr inbounds nuw [3 x double], ptr %8, i64 0, i64 %13
  %15 = load double, ptr %14, align 8
  %16 = getelementptr inbounds nuw [3 x double], ptr %9, i64 0, i64 %13
  %17 = load double, ptr %16, align 8
  %18 = fadd double %15, %17
  %19 = getelementptr inbounds nuw [3 x double], ptr %10, i64 0, i64 %13
  store double %18, ptr %19, align 8
  %20 = add nuw nsw i64 %13, 1
  %21 = load i32, ptr %0, align 8
  %22 = sext i32 %21 to i64
  %23 = icmp slt i64 %20, %22
  br i1 %23, label %12, label %11, !llvm.loop !18
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable
define dso_local void @Vec3_scale(ptr noundef captures(none) %0, double noundef %1) local_unnamed_addr #7 {
  %3 = load i32, ptr %0, align 8
  %4 = icmp sgt i32 %3, 0
  br i1 %4, label %5, label %8

5:                                                ; preds = %2
  %6 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %7 = zext nneg i32 %3 to i64
  br label %9

8:                                                ; preds = %9, %2
  ret void

9:                                                ; preds = %5, %9
  %10 = phi i64 [ 0, %5 ], [ %14, %9 ]
  %11 = getelementptr inbounds nuw [3 x double], ptr %6, i64 0, i64 %10
  %12 = load double, ptr %11, align 8
  %13 = fmul double %1, %12
  store double %13, ptr %11, align 8
  %14 = add nuw nsw i64 %10, 1
  %15 = icmp eq i64 %14, %7
  br i1 %15, label %8, label %9, !llvm.loop !19
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite) uwtable
define dso_local void @Vec3_cross(ptr noundef readonly captures(none) %0, ptr noundef readonly captures(none) %1, ptr noundef writeonly captures(none) initializes((0, 4), (8, 32)) %2) local_unnamed_addr #8 {
  store i32 3, ptr %2, align 8
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %5 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %6 = load double, ptr %5, align 8
  %7 = getelementptr inbounds nuw i8, ptr %1, i64 8
  %8 = getelementptr inbounds nuw i8, ptr %1, i64 24
  %9 = load double, ptr %8, align 8
  %10 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %11 = load double, ptr %10, align 8
  %12 = getelementptr inbounds nuw i8, ptr %1, i64 16
  %13 = load double, ptr %12, align 8
  %14 = fneg double %13
  %15 = fmul double %11, %14
  %16 = tail call double @llvm.fmuladd.f64(double %6, double %9, double %15)
  %17 = getelementptr inbounds nuw i8, ptr %2, i64 8
  store double %16, ptr %17, align 8
  %18 = load double, ptr %4, align 8
  %19 = load double, ptr %8, align 8
  %20 = load double, ptr %10, align 8
  %21 = load double, ptr %7, align 8
  %22 = fneg double %21
  %23 = fmul double %20, %22
  %24 = tail call double @llvm.fmuladd.f64(double %18, double %19, double %23)
  %25 = fneg double %24
  %26 = getelementptr inbounds nuw i8, ptr %2, i64 16
  store double %25, ptr %26, align 8
  %27 = load double, ptr %4, align 8
  %28 = load double, ptr %12, align 8
  %29 = load double, ptr %5, align 8
  %30 = load double, ptr %7, align 8
  %31 = fneg double %30
  %32 = fmul double %29, %31
  %33 = tail call double @llvm.fmuladd.f64(double %27, double %28, double %32)
  %34 = getelementptr inbounds nuw i8, ptr %2, i64 24
  store double %33, ptr %34, align 8
  ret void
}

; Function Attrs: mustprogress norecurse uwtable
define dso_local noundef i32 @main() local_unnamed_addr #9 {
  %1 = alloca %struct.Vec3, align 8
  %2 = alloca %struct.Vec3, align 8
  %3 = alloca %struct.Vec3, align 8
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %1) #15
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #15
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3) #15
  store i32 3, ptr %1, align 8
  %4 = getelementptr inbounds nuw i8, ptr %1, i64 8
  store double 3.000000e+00, ptr %4, align 8
  %5 = getelementptr inbounds nuw i8, ptr %1, i64 16
  store double 4.000000e+00, ptr %5, align 8
  %6 = getelementptr inbounds nuw i8, ptr %1, i64 24
  store double 0.000000e+00, ptr %6, align 8
  br label %7

7:                                                ; preds = %7, %0
  %8 = phi i64 [ 0, %0 ], [ %13, %7 ]
  %9 = phi double [ 0.000000e+00, %0 ], [ %12, %7 ]
  %10 = getelementptr inbounds nuw [3 x double], ptr %4, i64 0, i64 %8
  %11 = load double, ptr %10, align 8
  %12 = tail call double @llvm.fmuladd.f64(double %11, double %11, double %9)
  %13 = add nuw nsw i64 %8, 1
  %14 = icmp eq i64 %13, 3
  br i1 %14, label %15, label %7, !llvm.loop !13

15:                                               ; preds = %7
  %16 = tail call double @sqrt(double noundef %12) #15
  %17 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @"??_C@_0CE@EAPGDEGH@CALL?5Vec3_getLength?$CI?$HL3?04?00?$HN?$CJ?5?9?$DO?5@", double noundef %16)
  store i32 3, ptr %1, align 8
  store double 1.000000e+00, ptr %4, align 8
  store double 2.000000e+00, ptr %5, align 8
  store double 3.000000e+00, ptr %6, align 8
  br label %18

18:                                               ; preds = %18, %15
  %19 = phi i64 [ 0, %15 ], [ %24, %18 ]
  %20 = phi double [ 0.000000e+00, %15 ], [ %23, %18 ]
  %21 = getelementptr inbounds nuw [3 x double], ptr %4, i64 0, i64 %19
  %22 = load double, ptr %21, align 8
  %23 = tail call double @llvm.fmuladd.f64(double %22, double %22, double %20)
  %24 = add nuw nsw i64 %19, 1
  %25 = icmp eq i64 %24, 3
  br i1 %25, label %26, label %18, !llvm.loop !13

26:                                               ; preds = %18
  %27 = tail call double @sqrt(double noundef %23) #15
  %28 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @"??_C@_0CE@NBHHDMCK@CALL?5Vec3_getLength?$CI?$HL1?02?03?$HN?$CJ?5?9?$DO?5@", double noundef %27)
  store i32 3, ptr %1, align 8
  store double 1.000000e+00, ptr %4, align 8
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(16) %5, i8 0, i64 16, i1 false)
  store i32 3, ptr %2, align 8
  %29 = getelementptr inbounds nuw i8, ptr %2, i64 8
  store double 0.000000e+00, ptr %29, align 8
  %30 = getelementptr inbounds nuw i8, ptr %2, i64 16
  store double 1.000000e+00, ptr %30, align 8
  %31 = getelementptr inbounds nuw i8, ptr %2, i64 24
  store double 0.000000e+00, ptr %31, align 8
  br label %32

32:                                               ; preds = %32, %26
  %33 = phi i64 [ 0, %26 ], [ %40, %32 ]
  %34 = phi double [ 0.000000e+00, %26 ], [ %39, %32 ]
  %35 = getelementptr inbounds nuw [3 x double], ptr %4, i64 0, i64 %33
  %36 = load double, ptr %35, align 8
  %37 = getelementptr inbounds nuw [3 x double], ptr %29, i64 0, i64 %33
  %38 = load double, ptr %37, align 8
  %39 = tail call double @llvm.fmuladd.f64(double %36, double %38, double %34)
  %40 = add nuw nsw i64 %33, 1
  %41 = icmp eq i64 %40, 3
  br i1 %41, label %42, label %32, !llvm.loop !17

42:                                               ; preds = %32
  %43 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @"??_C@_0CH@FNCNBJHL@CALL?5Vec3_dot?$CI?$HL1?00?00?$HN?0?5?$HL0?01?00?$HN?$CJ?5@", double noundef %39)
  store i32 3, ptr %1, align 8
  store double 1.000000e+00, ptr %4, align 8
  store double 2.000000e+00, ptr %5, align 8
  store double 3.000000e+00, ptr %6, align 8
  store i32 3, ptr %2, align 8
  store double 4.000000e+00, ptr %29, align 8
  store double 5.000000e+00, ptr %30, align 8
  store double 6.000000e+00, ptr %31, align 8
  br label %44

44:                                               ; preds = %44, %42
  %45 = phi i64 [ 0, %42 ], [ %52, %44 ]
  %46 = phi double [ 0.000000e+00, %42 ], [ %51, %44 ]
  %47 = getelementptr inbounds nuw [3 x double], ptr %4, i64 0, i64 %45
  %48 = load double, ptr %47, align 8
  %49 = getelementptr inbounds nuw [3 x double], ptr %29, i64 0, i64 %45
  %50 = load double, ptr %49, align 8
  %51 = tail call double @llvm.fmuladd.f64(double %48, double %50, double %46)
  %52 = add nuw nsw i64 %45, 1
  %53 = icmp eq i64 %52, 3
  br i1 %53, label %54, label %44, !llvm.loop !17

54:                                               ; preds = %44
  %55 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @"??_C@_0CH@HOKEFIIH@CALL?5Vec3_dot?$CI?$HL1?02?03?$HN?0?5?$HL4?05?06?$HN?$CJ?5@", double noundef %51)
  store i32 3, ptr %1, align 8
  store double 3.000000e+00, ptr %4, align 8
  store double 4.000000e+00, ptr %5, align 8
  store double 0.000000e+00, ptr %6, align 8
  br label %56

56:                                               ; preds = %56, %54
  %57 = phi i64 [ 0, %54 ], [ %62, %56 ]
  %58 = phi double [ 0.000000e+00, %54 ], [ %61, %56 ]
  %59 = getelementptr inbounds nuw [3 x double], ptr %4, i64 0, i64 %57
  %60 = load double, ptr %59, align 8
  %61 = tail call double @llvm.fmuladd.f64(double %60, double %60, double %58)
  %62 = add nuw nsw i64 %57, 1
  %63 = icmp eq i64 %62, 3
  br i1 %63, label %64, label %56, !llvm.loop !13

64:                                               ; preds = %56
  %65 = tail call double @sqrt(double noundef %61) #15
  %66 = fcmp ogt double %65, 0.000000e+00
  br i1 %66, label %67, label %74

67:                                               ; preds = %64, %67
  %68 = phi i64 [ %72, %67 ], [ 0, %64 ]
  %69 = getelementptr inbounds nuw [3 x double], ptr %4, i64 0, i64 %68
  %70 = load double, ptr %69, align 8
  %71 = fdiv double %70, %65
  store double %71, ptr %69, align 8
  %72 = add nuw nsw i64 %68, 1
  %73 = icmp eq i64 %72, 3
  br i1 %73, label %74, label %67, !llvm.loop !16

74:                                               ; preds = %67, %64
  %75 = load double, ptr %6, align 8
  %76 = load double, ptr %5, align 8
  %77 = load double, ptr %4, align 8
  %78 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @"??_C@_0CO@GLKAJKGB@CALL?5Vec3_normalize?$CI?$HL3?04?00?$HN?$CJ?5?9?$DO?5@", double noundef %77, double noundef %76, double noundef %75)
  store i32 3, ptr %1, align 8
  store double 1.000000e+00, ptr %4, align 8
  store double 2.000000e+00, ptr %5, align 8
  store double 3.000000e+00, ptr %6, align 8
  store i32 3, ptr %2, align 8
  store double 1.000000e+01, ptr %29, align 8
  store double 2.000000e+01, ptr %30, align 8
  store double 3.000000e+01, ptr %31, align 8
  store i32 3, ptr %3, align 8
  %79 = getelementptr inbounds nuw i8, ptr %3, i64 8
  br label %80

80:                                               ; preds = %80, %74
  %81 = phi i64 [ 0, %74 ], [ %88, %80 ]
  %82 = getelementptr inbounds nuw [3 x double], ptr %4, i64 0, i64 %81
  %83 = load double, ptr %82, align 8
  %84 = getelementptr inbounds nuw [3 x double], ptr %29, i64 0, i64 %81
  %85 = load double, ptr %84, align 8
  %86 = fadd double %83, %85
  %87 = getelementptr inbounds nuw [3 x double], ptr %79, i64 0, i64 %81
  store double %86, ptr %87, align 8
  %88 = add nuw nsw i64 %81, 1
  %89 = icmp eq i64 %88, 3
  br i1 %89, label %90, label %80, !llvm.loop !18

90:                                               ; preds = %80
  %91 = getelementptr inbounds nuw i8, ptr %3, i64 8
  %92 = getelementptr inbounds nuw i8, ptr %3, i64 24
  %93 = load double, ptr %92, align 8
  %94 = getelementptr inbounds nuw i8, ptr %3, i64 16
  %95 = load double, ptr %94, align 8
  %96 = load double, ptr %91, align 8
  %97 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @"??_C@_0DE@ILBAJPJD@CALL?5Vec3_add?$CI?$HL1?02?03?$HN?0?5?$HL10?020?030@", double noundef %96, double noundef %95, double noundef %93)
  store i32 3, ptr %1, align 8
  store double 1.000000e+00, ptr %4, align 8
  store double 2.000000e+00, ptr %5, align 8
  store double 3.000000e+00, ptr %6, align 8
  br label %98

98:                                               ; preds = %98, %90
  %99 = phi i64 [ 0, %90 ], [ %103, %98 ]
  %100 = getelementptr inbounds nuw [3 x double], ptr %4, i64 0, i64 %99
  %101 = load double, ptr %100, align 8
  %102 = fmul double %101, 2.500000e+00
  store double %102, ptr %100, align 8
  %103 = add nuw nsw i64 %99, 1
  %104 = icmp eq i64 %103, 3
  br i1 %104, label %105, label %98, !llvm.loop !19

105:                                              ; preds = %98
  %106 = load double, ptr %6, align 8
  %107 = load double, ptr %5, align 8
  %108 = load double, ptr %4, align 8
  %109 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @"??_C@_0CP@POBEJGAG@CALL?5Vec3_scale?$CI?$HL1?02?03?$HN?0?52?45?$CJ?5?9?$DO@", double noundef %108, double noundef %107, double noundef %106)
  store i32 3, ptr %1, align 8
  store double 1.000000e+00, ptr %4, align 8
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(16) %5, i8 0, i64 16, i1 false)
  store i32 3, ptr %2, align 8
  store double 0.000000e+00, ptr %29, align 8
  store double 1.000000e+00, ptr %30, align 8
  store double 0.000000e+00, ptr %31, align 8
  store i32 3, ptr %3, align 8
  store double 0.000000e+00, ptr %91, align 8
  store double -0.000000e+00, ptr %94, align 8
  store double 1.000000e+00, ptr %92, align 8
  %110 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @"??_C@_0DD@OJGLBFFP@CALL?5Vec3_cross?$CI?$HL1?00?00?$HN?0?5?$HL0?01?00?$HN@", double noundef 0.000000e+00, double noundef -0.000000e+00, double noundef 1.000000e+00)
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3) #15
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #15
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %1) #15
  ret i32 0
}

; Function Attrs: inlinehint mustprogress uwtable
define linkonce_odr dso_local i32 @printf(ptr noundef %0, ...) local_unnamed_addr #10 comdat {
  %2 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #15
  call void @llvm.va_start.p0(ptr nonnull %2)
  %3 = load ptr, ptr %2, align 8
  %4 = call ptr @__acrt_iob_func(i32 noundef 1)
  %5 = call ptr @__local_stdio_printf_options()
  %6 = load i64, ptr %5, align 8
  %7 = call i32 @__stdio_common_vfprintf(i64 noundef %6, ptr noundef %4, ptr noundef %0, ptr noundef null, ptr noundef %3)
  call void @llvm.va_end.p0(ptr %2)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #15
  ret i32 %7
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_start.p0(ptr) #11

declare dso_local ptr @__acrt_iob_func(i32 noundef) local_unnamed_addr #12

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_end.p0(ptr) #11

declare dso_local i32 @__stdio_common_vfprintf(i64 noundef, ptr noundef, ptr noundef, ptr noundef, ptr noundef) local_unnamed_addr #12

; Function Attrs: mustprogress noinline nounwind uwtable
define linkonce_odr dso_local ptr @__local_stdio_printf_options() local_unnamed_addr #13 comdat {
  ret ptr @"?_OptionsStorage@?1??__local_stdio_printf_options@@9@4_KA"
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #14

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nounwind memory(argmem: read, errnomem: write) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { mustprogress nocallback nofree nounwind willreturn memory(errnomem: write) "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { mustprogress nofree norecurse nounwind memory(argmem: readwrite, errnomem: write) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #7 = { mustprogress nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #8 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #9 = { mustprogress norecurse uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #10 = { inlinehint mustprogress uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #11 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #12 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #13 = { mustprogress noinline nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #14 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #15 = { nounwind }

!llvm.dbg.cu = !{!0}
!llvm.linker.options = !{!2, !3, !4, !5, !6}
!llvm.module.flags = !{!7, !8, !9, !10, !11}
!llvm.ident = !{!12}

!0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_14, file: !1, producer: "clang version 21.1.8", isOptimized: true, runtimeVersion: 0, emissionKind: NoDebug, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "vectorbase_wrapper.cpp", directory: "D:\\MUSIQ\\ALGT\\llvm_simulators\\unified\\samples")
!2 = !{!"/FAILIFMISMATCH:\22_CRT_STDIO_ISO_WIDE_SPECIFIERS=0\22"}
!3 = !{!"/FAILIFMISMATCH:\22_MSC_VER=1900\22"}
!4 = !{!"/FAILIFMISMATCH:\22_ITERATOR_DEBUG_LEVEL=0\22"}
!5 = !{!"/FAILIFMISMATCH:\22RuntimeLibrary=MT_StaticRelease\22"}
!6 = !{!"/DEFAULTLIB:libcpmt.lib"}
!7 = !{i32 2, !"Debug Info Version", i32 3}
!8 = !{i32 1, !"wchar_size", i32 2}
!9 = !{i32 8, !"PIC Level", i32 2}
!10 = !{i32 7, !"uwtable", i32 2}
!11 = !{i32 1, !"MaxTLSAlign", i32 65536}
!12 = !{!"clang version 21.1.8"}
!13 = distinct !{!13, !14, !15}
!14 = !{!"llvm.loop.mustprogress"}
!15 = !{!"llvm.loop.unroll.disable"}
!16 = distinct !{!16, !14, !15}
!17 = distinct !{!17, !14, !15}
!18 = distinct !{!18, !14, !15}
!19 = distinct !{!19, !14, !15}
