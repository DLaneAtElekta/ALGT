// vectorbase_wrapper.cpp -- C-struct vector operations for LLVM IR simulation
//
// Mirrors CVectorBase<double> behavior using plain C structs to produce
// clean LLVM IR with GEP, struct access, and array indexing patterns.
//
// Compile to LLVM IR:
//   clang -S -emit-llvm -O1 -std=c++17 -o vectorbase.ll vectorbase_wrapper.cpp
//
// Compile to native (for trace comparison):
//   clang++ -O1 -std=c++17 vectorbase_wrapper.cpp -o vectorbase_test -lm

#include <cstdio>
#include <cmath>

// Simple fixed-size vector struct (mirrors CVectorD<3, double> layout)
struct Vec3 {
    int dim;
    double elements[3];
};

extern "C" {

void Vec3_init(Vec3* v, double x, double y, double z) {
    v->dim = 3;
    v->elements[0] = x;
    v->elements[1] = y;
    v->elements[2] = z;
}

double Vec3_getElement(const Vec3* v, int idx) {
    return v->elements[idx];
}

void Vec3_setElement(Vec3* v, int idx, double val) {
    v->elements[idx] = val;
}

int Vec3_getDim(const Vec3* v) {
    return v->dim;
}

double Vec3_getLength(const Vec3* v) {
    double len = 0.0;
    for (int i = 0; i < v->dim; i++) {
        len += v->elements[i] * v->elements[i];
    }
    return sqrt(len);
}

void Vec3_normalize(Vec3* v) {
    double len = Vec3_getLength(v);
    if (len > 0.0) {
        for (int i = 0; i < v->dim; i++) {
            v->elements[i] /= len;
        }
    }
}

double Vec3_dot(const Vec3* v1, const Vec3* v2) {
    double prod = 0.0;
    for (int i = 0; i < v1->dim; i++) {
        prod += v1->elements[i] * v2->elements[i];
    }
    return prod;
}

void Vec3_add(const Vec3* v1, const Vec3* v2, Vec3* result) {
    result->dim = v1->dim;
    for (int i = 0; i < v1->dim; i++) {
        result->elements[i] = v1->elements[i] + v2->elements[i];
    }
}

void Vec3_scale(Vec3* v, double scalar) {
    for (int i = 0; i < v->dim; i++) {
        v->elements[i] *= scalar;
    }
}

void Vec3_cross(const Vec3* v1, const Vec3* v2, Vec3* result) {
    result->dim = 3;
    result->elements[0] =  v1->elements[1] * v2->elements[2] - v1->elements[2] * v2->elements[1];
    result->elements[1] = -(v1->elements[0] * v2->elements[2] - v1->elements[2] * v2->elements[0]);
    result->elements[2] =  v1->elements[0] * v2->elements[1] - v1->elements[1] * v2->elements[0];
}

} // extern "C"

// Trace output for comparison
int main() {
    Vec3 v1, v2, result;

    // Init and GetLength
    Vec3_init(&v1, 3.0, 4.0, 0.0);
    printf("CALL Vec3_getLength({3,4,0}) -> %g\n", Vec3_getLength(&v1));

    Vec3_init(&v1, 1.0, 2.0, 3.0);
    printf("CALL Vec3_getLength({1,2,3}) -> %g\n", Vec3_getLength(&v1));

    // Dot product
    Vec3_init(&v1, 1.0, 0.0, 0.0);
    Vec3_init(&v2, 0.0, 1.0, 0.0);
    printf("CALL Vec3_dot({1,0,0}, {0,1,0}) -> %g\n", Vec3_dot(&v1, &v2));

    Vec3_init(&v1, 1.0, 2.0, 3.0);
    Vec3_init(&v2, 4.0, 5.0, 6.0);
    printf("CALL Vec3_dot({1,2,3}, {4,5,6}) -> %g\n", Vec3_dot(&v1, &v2));

    // Normalize
    Vec3_init(&v1, 3.0, 4.0, 0.0);
    Vec3_normalize(&v1);
    printf("CALL Vec3_normalize({3,4,0}) -> {%g, %g, %g}\n",
           v1.elements[0], v1.elements[1], v1.elements[2]);

    // Add
    Vec3_init(&v1, 1.0, 2.0, 3.0);
    Vec3_init(&v2, 10.0, 20.0, 30.0);
    Vec3_add(&v1, &v2, &result);
    printf("CALL Vec3_add({1,2,3}, {10,20,30}) -> {%g, %g, %g}\n",
           result.elements[0], result.elements[1], result.elements[2]);

    // Scale
    Vec3_init(&v1, 1.0, 2.0, 3.0);
    Vec3_scale(&v1, 2.5);
    printf("CALL Vec3_scale({1,2,3}, 2.5) -> {%g, %g, %g}\n",
           v1.elements[0], v1.elements[1], v1.elements[2]);

    // Cross product
    Vec3_init(&v1, 1.0, 0.0, 0.0);
    Vec3_init(&v2, 0.0, 1.0, 0.0);
    Vec3_cross(&v1, &v2, &result);
    printf("CALL Vec3_cross({1,0,0}, {0,1,0}) -> {%g, %g, %g}\n",
           result.elements[0], result.elements[1], result.elements[2]);

    return 0;
}
