//
//  KernelSources.swift
//  CUDA
//
//  Created by Richard Wei on 11/3/16.
//
//

extension StaticString : Equatable {
    public static func == (lhs: StaticString, rhs: StaticString) -> Bool {
        return lhs.utf8Start == rhs.utf8Start
    }
}

protocol CompilableKernelSource : RawRepresentable, Equatable, Hashable { }

/// Kernel source with generic TYPE
///
/// - sum: void sum(const T*, const long long, T*)
/// - asum: void asum(const T*, const long long, T*)
/// - fill: void fill(T*, const long long)
enum KernelSource: StaticString, CompilableKernelSource {
    case sum = "extern \"C\" __global__ void KERNEL(const TYPE vector[], const long long count, TYPE *result) { *result = 0; for (long i = 0; i < count; i++) *result += vector[i]; }"
    case asum = "extern \"C\" __global__ void KERNEL(const TYPE vector[], const long long count, TYPE *result) { *result = 0; for (long i = 0; i < count; i++) *result += abs(vector[i]); }"
    case fill = "extern \"C\" __global__ void KERNEL(TYPE vector[], TYPE x, const long long count) { size_t tid = blockIdx.x * blockDim.x + threadIdx.x; if (tid < count) vector[tid] = x; } "
}

/// Kernel source with generic TYPE and 1-place transformation function FUNC (eg. tan, sin)
///
/// - transform: void transform(const T*, const long long, T*)
enum FunctorialKernelSource: StaticString, CompilableKernelSource {
    case transform = "extern \"C\" __global__ void KERNEL(const TYPE vector[], const long long count, TYPE result[]) { size_t tid = blockIdx.x * blockDim.x + threadIdx.x; if (tid < count) result[tid] = FUNC(vector[tid]); } "
}


/// Kernel source with generic TYPE and binary operation OP
///
/// - elementwise: void elementwise(const T, const T*, const T, const T*, const long long, T*)
/// - scalarRight: void scalarRight(const T, const T*, const T, const long long, T*)
enum BinaryOperationKernelSource: StaticString, CompilableKernelSource {
    case elementwise = "extern \"C\" __global__ void KERNEL(const TYPE a, const TYPE x[], const TYPE b, const TYPE y[], const long long count, TYPE result[]) { size_t tid = blockIdx.x * blockDim.x + threadIdx.x; if (tid < count) result[tid] = OP(a * x[tid], b * y[tid]); } "
    case scalarRight = "extern \"C\" __global__ void KERNEL(const TYPE a, const TYPE x[], const TYPE rval, const long long count, TYPE result[]) { size_t tid = blockIdx.x * blockDim.x + threadIdx.x; if (tid < count) result[tid] = OP(a * x[tid], rval); } "
}

extension StaticString : Hashable {
    public var hashValue: Int {
        return utf8Start.hashValue
    }
}
