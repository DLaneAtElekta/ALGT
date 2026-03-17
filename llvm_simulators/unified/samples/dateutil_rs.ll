; ModuleID = 'dateutil_wrapper.3bf8ffcd3d58f44c-cgu.0'
source_filename = "dateutil_wrapper.3bf8ffcd3d58f44c-cgu.0"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"

@alloc_076954a9d94c5a19b8b2a223a5054431 = private unnamed_addr constant [47 x i8] c"*CALL SubDates({3/15/2024}, {3/1/2024}) -> \C0\01\0A\00", align 1
@alloc_47e6b87f2bb2b800e68f6482e6f48808 = private unnamed_addr constant [49 x i8] c",CALL SubDates({1/15/2025}, {12/15/2024}) -> \C0\01\0A\00", align 1
@alloc_3851f6d243e8110bf25b1d75017d2aaa = private unnamed_addr constant [64 x i8] c";CALL CompareDates({6/15/2024 14:30}, {6/15/2024 14:30}) -> \C0\01\0A\00", align 1
@alloc_35eb599c6b327c93f947177bf3495a40 = private unnamed_addr constant [52 x i8] c"/CALL CompareDates({6/15/2024}, {3/15/2024}) -> \C0\01\0A\00", align 1
@alloc_8911cf399c4b092a1c620761190d85ed = private unnamed_addr constant [42 x i8] c"%CALL CompareDates({2025}, {2024}) -> \C0\01\0A\00", align 1
@alloc_d83c19a3096a13ce4563fe8496947616 = private unnamed_addr constant [39 x i8] c"\22CALL FindDayOfWeek(2024, 1, 1) -> \C0\01\0A\00", align 1
@alloc_49cbdffa499493cae0a744b49ae62156 = private unnamed_addr constant [39 x i8] c"\22CALL FindDayOfWeek(1984, 1, 1) -> \C0\01\0A\00", align 1
@alloc_c69ebd1115a44dc34dbc229dfcd7854f = private unnamed_addr constant [40 x i8] c"#CALL FindDayOfWeek(2024, 3, 15) -> \C0\01\0A\00", align 1
@alloc_e6b64db078d7580f363eaef491709978 = private unnamed_addr constant [30 x i8] c"\19CALL IsLeapYear(2024) -> \C0\01\0A\00", align 1
@alloc_593b8880142fc3327bbcd440742fdf6a = private unnamed_addr constant [30 x i8] c"\19CALL IsLeapYear(2023) -> \C0\01\0A\00", align 1
@alloc_bcbe207f0c869ae80abd148d7a9718f7 = private unnamed_addr constant [30 x i8] c"\19CALL IsLeapYear(1900) -> \C0\01\0A\00", align 1
@alloc_26cef72a70434dc858e4cfb26513db91 = private unnamed_addr constant [30 x i8] c"\19CALL IsLeapYear(2000) -> \C0\01\0A\00", align 1
@alloc_de2669663914e5841b509ad13581f197 = private unnamed_addr constant [38 x i8] c"!CALL DaysInMonthFunc(2024, 2) -> \C0\01\0A\00", align 1
@alloc_a39ad91e807590a312b379f5e1e605de = private unnamed_addr constant [38 x i8] c"!CALL DaysInMonthFunc(2023, 2) -> \C0\01\0A\00", align 1
@vtable.0 = private unnamed_addr constant <{ [24 x i8], ptr, ptr, ptr }> <{ [24 x i8] c"\00\00\00\00\00\00\00\00\08\00\00\00\00\00\00\00\08\00\00\00\00\00\00\00", ptr @"_ZN4core3ops8function6FnOnce40call_once$u7b$$u7b$vtable.shim$u7d$$u7d$17ha47574cceb033e45E", ptr @"_ZN3std2rt10lang_start28_$u7b$$u7b$closure$u7d$$u7d$17h14852af7a2d26fbeE", ptr @"_ZN3std2rt10lang_start28_$u7b$$u7b$closure$u7d$$u7d$17h14852af7a2d26fbeE" }>, align 8

; dateutil_wrapper::main
; Function Attrs: uwtable
define hidden void @_ZN16dateutil_wrapper4main17h167b8638bcfeb8f1E() unnamed_addr #0 {
start:
  %args29 = alloca [16 x i8], align 8
  %result28 = alloca [4 x i8], align 4
  %args27 = alloca [16 x i8], align 8
  %result26 = alloca [4 x i8], align 4
  %args25 = alloca [16 x i8], align 8
  %_103 = alloca [4 x i8], align 4
  %args24 = alloca [16 x i8], align 8
  %_95 = alloca [4 x i8], align 4
  %args23 = alloca [16 x i8], align 8
  %_87 = alloca [4 x i8], align 4
  %args22 = alloca [16 x i8], align 8
  %_79 = alloca [4 x i8], align 4
  %args21 = alloca [16 x i8], align 8
  %result20 = alloca [4 x i8], align 4
  %args19 = alloca [16 x i8], align 8
  %result18 = alloca [4 x i8], align 4
  %args17 = alloca [16 x i8], align 8
  %result16 = alloca [4 x i8], align 4
  %args15 = alloca [16 x i8], align 8
  %result14 = alloca [4 x i8], align 4
  %args11 = alloca [16 x i8], align 8
  %result10 = alloca [4 x i8], align 4
  %args8 = alloca [16 x i8], align 8
  %result7 = alloca [4 x i8], align 4
  %args4 = alloca [16 x i8], align 8
  %result3 = alloca [4 x i8], align 4
  %args = alloca [16 x i8], align 8
  %result = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %result)
  store i32 14, ptr %result, align 4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %args)
  store ptr %result, ptr %args, align 8
  %_10.sroa.4.0.args.sroa_idx = getelementptr inbounds nuw i8, ptr %args, i64 8
  store ptr @"_ZN4core3fmt3num3imp52_$LT$impl$u20$core..fmt..Display$u20$for$u20$i32$GT$3fmt17hd62cc4f32673e356E", ptr %_10.sroa.4.0.args.sroa_idx, align 8
; call std::io::stdio::_print
  call void @_ZN3std2io5stdio6_print17h381dc97f2e78cfd6E(ptr noundef nonnull @alloc_076954a9d94c5a19b8b2a223a5054431, ptr noundef nonnull %args)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %args)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %result3)
  store i32 31, ptr %result3, align 4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %args4)
  store ptr %result3, ptr %args4, align 8
  %_21.sroa.4.0.args4.sroa_idx = getelementptr inbounds nuw i8, ptr %args4, i64 8
  store ptr @"_ZN4core3fmt3num3imp52_$LT$impl$u20$core..fmt..Display$u20$for$u20$i32$GT$3fmt17hd62cc4f32673e356E", ptr %_21.sroa.4.0.args4.sroa_idx, align 8
; call std::io::stdio::_print
  call void @_ZN3std2io5stdio6_print17h381dc97f2e78cfd6E(ptr noundef nonnull @alloc_47e6b87f2bb2b800e68f6482e6f48808, ptr noundef nonnull %args4)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %args4)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %result7)
  store i32 0, ptr %result7, align 4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %args8)
  store ptr %result7, ptr %args8, align 8
  %_32.sroa.4.0.args8.sroa_idx = getelementptr inbounds nuw i8, ptr %args8, i64 8
  store ptr @"_ZN4core3fmt3num3imp52_$LT$impl$u20$core..fmt..Display$u20$for$u20$i32$GT$3fmt17hd62cc4f32673e356E", ptr %_32.sroa.4.0.args8.sroa_idx, align 8
; call std::io::stdio::_print
  call void @_ZN3std2io5stdio6_print17h381dc97f2e78cfd6E(ptr noundef nonnull @alloc_3851f6d243e8110bf25b1d75017d2aaa, ptr noundef nonnull %args8)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %args8)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %result10)
  store i32 3, ptr %result10, align 4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %args11)
  store ptr %result10, ptr %args11, align 8
  %_42.sroa.4.0.args11.sroa_idx = getelementptr inbounds nuw i8, ptr %args11, i64 8
  store ptr @"_ZN4core3fmt3num3imp52_$LT$impl$u20$core..fmt..Display$u20$for$u20$i32$GT$3fmt17hd62cc4f32673e356E", ptr %_42.sroa.4.0.args11.sroa_idx, align 8
; call std::io::stdio::_print
  call void @_ZN3std2io5stdio6_print17h381dc97f2e78cfd6E(ptr noundef nonnull @alloc_35eb599c6b327c93f947177bf3495a40, ptr noundef nonnull %args11)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %args11)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %result14)
  store i32 1, ptr %result14, align 4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %args15)
  store ptr %result14, ptr %args15, align 8
  %_53.sroa.4.0.args15.sroa_idx = getelementptr inbounds nuw i8, ptr %args15, i64 8
  store ptr @"_ZN4core3fmt3num3imp52_$LT$impl$u20$core..fmt..Display$u20$for$u20$i32$GT$3fmt17hd62cc4f32673e356E", ptr %_53.sroa.4.0.args15.sroa_idx, align 8
; call std::io::stdio::_print
  call void @_ZN3std2io5stdio6_print17h381dc97f2e78cfd6E(ptr noundef nonnull @alloc_8911cf399c4b092a1c620761190d85ed, ptr noundef nonnull %args15)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %args15)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %result16)
  store i32 1, ptr %result16, align 4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %args17)
  store ptr %result16, ptr %args17, align 8
  %_60.sroa.4.0.args17.sroa_idx = getelementptr inbounds nuw i8, ptr %args17, i64 8
  store ptr @"_ZN4core3fmt3num3imp52_$LT$impl$u20$core..fmt..Display$u20$for$u20$i32$GT$3fmt17hd62cc4f32673e356E", ptr %_60.sroa.4.0.args17.sroa_idx, align 8
; call std::io::stdio::_print
  call void @_ZN3std2io5stdio6_print17h381dc97f2e78cfd6E(ptr noundef nonnull @alloc_d83c19a3096a13ce4563fe8496947616, ptr noundef nonnull %args17)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %args17)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %result18)
  store i32 1, ptr %result18, align 4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %args19)
  store ptr %result18, ptr %args19, align 8
  %_67.sroa.4.0.args19.sroa_idx = getelementptr inbounds nuw i8, ptr %args19, i64 8
  store ptr @"_ZN4core3fmt3num3imp52_$LT$impl$u20$core..fmt..Display$u20$for$u20$i32$GT$3fmt17hd62cc4f32673e356E", ptr %_67.sroa.4.0.args19.sroa_idx, align 8
; call std::io::stdio::_print
  call void @_ZN3std2io5stdio6_print17h381dc97f2e78cfd6E(ptr noundef nonnull @alloc_49cbdffa499493cae0a744b49ae62156, ptr noundef nonnull %args19)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %args19)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %result20)
  store i32 5, ptr %result20, align 4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %args21)
  store ptr %result20, ptr %args21, align 8
  %_74.sroa.4.0.args21.sroa_idx = getelementptr inbounds nuw i8, ptr %args21, i64 8
  store ptr @"_ZN4core3fmt3num3imp52_$LT$impl$u20$core..fmt..Display$u20$for$u20$i32$GT$3fmt17hd62cc4f32673e356E", ptr %_74.sroa.4.0.args21.sroa_idx, align 8
; call std::io::stdio::_print
  call void @_ZN3std2io5stdio6_print17h381dc97f2e78cfd6E(ptr noundef nonnull @alloc_c69ebd1115a44dc34dbc229dfcd7854f, ptr noundef nonnull %args21)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %args21)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %_79)
  store i32 1, ptr %_79, align 4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %args22)
  store ptr %_79, ptr %args22, align 8
  %_82.sroa.4.0.args22.sroa_idx = getelementptr inbounds nuw i8, ptr %args22, i64 8
  store ptr @"_ZN4core3fmt3num3imp52_$LT$impl$u20$core..fmt..Display$u20$for$u20$i32$GT$3fmt17hd62cc4f32673e356E", ptr %_82.sroa.4.0.args22.sroa_idx, align 8
; call std::io::stdio::_print
  call void @_ZN3std2io5stdio6_print17h381dc97f2e78cfd6E(ptr noundef nonnull @alloc_e6b64db078d7580f363eaef491709978, ptr noundef nonnull %args22)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %args22)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %_79)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %_87)
  store i32 0, ptr %_87, align 4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %args23)
  store ptr %_87, ptr %args23, align 8
  %_90.sroa.4.0.args23.sroa_idx = getelementptr inbounds nuw i8, ptr %args23, i64 8
  store ptr @"_ZN4core3fmt3num3imp52_$LT$impl$u20$core..fmt..Display$u20$for$u20$i32$GT$3fmt17hd62cc4f32673e356E", ptr %_90.sroa.4.0.args23.sroa_idx, align 8
; call std::io::stdio::_print
  call void @_ZN3std2io5stdio6_print17h381dc97f2e78cfd6E(ptr noundef nonnull @alloc_593b8880142fc3327bbcd440742fdf6a, ptr noundef nonnull %args23)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %args23)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %_87)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %_95)
  store i32 0, ptr %_95, align 4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %args24)
  store ptr %_95, ptr %args24, align 8
  %_98.sroa.4.0.args24.sroa_idx = getelementptr inbounds nuw i8, ptr %args24, i64 8
  store ptr @"_ZN4core3fmt3num3imp52_$LT$impl$u20$core..fmt..Display$u20$for$u20$i32$GT$3fmt17hd62cc4f32673e356E", ptr %_98.sroa.4.0.args24.sroa_idx, align 8
; call std::io::stdio::_print
  call void @_ZN3std2io5stdio6_print17h381dc97f2e78cfd6E(ptr noundef nonnull @alloc_bcbe207f0c869ae80abd148d7a9718f7, ptr noundef nonnull %args24)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %args24)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %_95)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %_103)
  store i32 1, ptr %_103, align 4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %args25)
  store ptr %_103, ptr %args25, align 8
  %_106.sroa.4.0.args25.sroa_idx = getelementptr inbounds nuw i8, ptr %args25, i64 8
  store ptr @"_ZN4core3fmt3num3imp52_$LT$impl$u20$core..fmt..Display$u20$for$u20$i32$GT$3fmt17hd62cc4f32673e356E", ptr %_106.sroa.4.0.args25.sroa_idx, align 8
; call std::io::stdio::_print
  call void @_ZN3std2io5stdio6_print17h381dc97f2e78cfd6E(ptr noundef nonnull @alloc_26cef72a70434dc858e4cfb26513db91, ptr noundef nonnull %args25)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %args25)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %_103)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %result26)
  store i32 29, ptr %result26, align 4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %args27)
  store ptr %result26, ptr %args27, align 8
  %_113.sroa.4.0.args27.sroa_idx = getelementptr inbounds nuw i8, ptr %args27, i64 8
  store ptr @"_ZN4core3fmt3num3imp52_$LT$impl$u20$core..fmt..Display$u20$for$u20$i32$GT$3fmt17hd62cc4f32673e356E", ptr %_113.sroa.4.0.args27.sroa_idx, align 8
; call std::io::stdio::_print
  call void @_ZN3std2io5stdio6_print17h381dc97f2e78cfd6E(ptr noundef nonnull @alloc_de2669663914e5841b509ad13581f197, ptr noundef nonnull %args27)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %args27)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %result28)
  store i32 28, ptr %result28, align 4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %args29)
  store ptr %result28, ptr %args29, align 8
  %_120.sroa.4.0.args29.sroa_idx = getelementptr inbounds nuw i8, ptr %args29, i64 8
  store ptr @"_ZN4core3fmt3num3imp52_$LT$impl$u20$core..fmt..Display$u20$for$u20$i32$GT$3fmt17hd62cc4f32673e356E", ptr %_120.sroa.4.0.args29.sroa_idx, align 8
; call std::io::stdio::_print
  call void @_ZN3std2io5stdio6_print17h381dc97f2e78cfd6E(ptr noundef nonnull @alloc_a39ad91e807590a312b379f5e1e605de, ptr noundef nonnull %args29)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %args29)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %result28)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %result26)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %result20)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %result18)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %result16)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %result14)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %result10)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %result7)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %result3)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %result)
  ret void
}

; std::rt::lang_start
; Function Attrs: uwtable
define hidden noundef i64 @_ZN3std2rt10lang_start17h365b5b35f9345990E(ptr noundef nonnull %main, i64 noundef %argc, ptr noundef %argv, i8 noundef %sigpipe) unnamed_addr #0 {
start:
  %_7 = alloca [8 x i8], align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %_7)
  store ptr %main, ptr %_7, align 8
; call std::rt::lang_start_internal
  %_0 = call noundef i64 @_ZN3std2rt19lang_start_internal17hb6bdd05d2d634367E(ptr noundef nonnull align 1 %_7, ptr noalias noundef readonly align 8 captures(address, read_provenance) dereferenceable(48) @vtable.0, i64 noundef %argc, ptr noundef %argv, i8 noundef %sigpipe)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %_7)
  ret i64 %_0
}

; std::rt::lang_start::{{closure}}
; Function Attrs: inlinehint uwtable
define internal noundef i32 @"_ZN3std2rt10lang_start28_$u7b$$u7b$closure$u7d$$u7d$17h14852af7a2d26fbeE"(ptr noalias noundef readonly align 8 captures(none) dereferenceable(8) %_1) unnamed_addr #1 {
start:
  %_4 = load ptr, ptr %_1, align 8, !nonnull !3, !noundef !3
; call std::sys::backtrace::__rust_begin_short_backtrace
  tail call fastcc void @_ZN3std3sys9backtrace28__rust_begin_short_backtrace17h8ed4c59b764417ceE(ptr noundef nonnull %_4) #6
  ret i32 0
}

; std::sys::backtrace::__rust_begin_short_backtrace
; Function Attrs: noinline uwtable
define internal fastcc void @_ZN3std3sys9backtrace28__rust_begin_short_backtrace17h8ed4c59b764417ceE(ptr noundef nonnull readonly captures(none) %f) unnamed_addr #2 {
start:
  tail call void %f()
  tail call void asm sideeffect "", "~{memory}"() #7, !srcloc !4
  ret void
}

; core::ops::function::FnOnce::call_once{{vtable.shim}}
; Function Attrs: inlinehint uwtable
define internal noundef i32 @"_ZN4core3ops8function6FnOnce40call_once$u7b$$u7b$vtable.shim$u7d$$u7d$17ha47574cceb033e45E"(ptr noundef readonly captures(none) %_1) unnamed_addr #1 personality ptr @__CxxFrameHandler3 {
start:
  %0 = load ptr, ptr %_1, align 8, !nonnull !3, !noundef !3
; call std::sys::backtrace::__rust_begin_short_backtrace
  tail call fastcc void @_ZN3std3sys9backtrace28__rust_begin_short_backtrace17h8ed4c59b764417ceE(ptr noundef nonnull readonly %0) #6, !noalias !5
  ret i32 0
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #3

; std::io::stdio::_print
; Function Attrs: uwtable
declare void @_ZN3std2io5stdio6_print17h381dc97f2e78cfd6E(ptr noundef nonnull, ptr noundef nonnull) unnamed_addr #0

; std::rt::lang_start_internal
; Function Attrs: uwtable
declare noundef i64 @_ZN3std2rt19lang_start_internal17hb6bdd05d2d634367E(ptr noundef nonnull align 1, ptr noalias noundef readonly align 8 captures(address, read_provenance) dereferenceable(48), i64 noundef, ptr noundef, i8 noundef) unnamed_addr #0

; core::fmt::num::imp::<impl core::fmt::Display for i32>::fmt
; Function Attrs: uwtable
declare noundef zeroext i1 @"_ZN4core3fmt3num3imp52_$LT$impl$u20$core..fmt..Display$u20$for$u20$i32$GT$3fmt17hd62cc4f32673e356E"(ptr noalias noundef readonly align 4 captures(address, read_provenance) dereferenceable(4), ptr noalias noundef align 8 dereferenceable(24)) unnamed_addr #0

declare i32 @__CxxFrameHandler3(...) unnamed_addr #4

define noundef i32 @main(i32 %0, ptr %1) unnamed_addr #5 {
top:
  %_7.i = alloca [8 x i8], align 8
  %2 = sext i32 %0 to i64
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %_7.i)
  store ptr @_ZN16dateutil_wrapper4main17h167b8638bcfeb8f1E, ptr %_7.i, align 8
; call std::rt::lang_start_internal
  %_0.i = call noundef i64 @_ZN3std2rt19lang_start_internal17hb6bdd05d2d634367E(ptr noundef nonnull align 1 %_7.i, ptr noalias noundef readonly align 8 captures(address, read_provenance) dereferenceable(48) @vtable.0, i64 noundef %2, ptr noundef %1, i8 noundef 0)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %_7.i)
  %3 = trunc i64 %_0.i to i32
  ret i32 %3
}

attributes #0 = { uwtable "target-cpu"="x86-64" "target-features"="+cx16,+sse,+sse2,+sse3,+sahf" }
attributes #1 = { inlinehint uwtable "target-cpu"="x86-64" "target-features"="+cx16,+sse,+sse2,+sse3,+sahf" }
attributes #2 = { noinline uwtable "target-cpu"="x86-64" "target-features"="+cx16,+sse,+sse2,+sse3,+sahf" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { "target-cpu"="x86-64" }
attributes #5 = { "target-cpu"="x86-64" "target-features"="+cx16,+sse,+sse2,+sse3,+sahf" }
attributes #6 = { noinline }
attributes #7 = { nounwind }

!llvm.module.flags = !{!0, !1}
!llvm.ident = !{!2}

!0 = !{i32 8, !"PIC Level", i32 2}
!1 = !{i32 7, !"PIE Level", i32 2}
!2 = !{!"rustc version 1.94.0 (4a4ef493e 2026-03-02)"}
!3 = !{}
!4 = !{i64 8151877994477044}
!5 = !{!6}
!6 = distinct !{!6, !7, !"_ZN3std2rt10lang_start28_$u7b$$u7b$closure$u7d$$u7d$17h14852af7a2d26fbeE: %_1"}
!7 = distinct !{!7, !"_ZN3std2rt10lang_start28_$u7b$$u7b$closure$u7d$$u7d$17h14852af7a2d26fbeE"}
