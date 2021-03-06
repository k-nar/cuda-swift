//
//  Types.swift
//  CUDA
//
//  Created by Richard Wei on 11/5/16.
//
//

import CCuBLAS

public extension BLAS {
    public enum DataType : UInt32 {
        case float = 0
        case double = 1
        case half = 2
        case int8 = 3
        case uint8 = 8
        case int32 = 10
        case uint32 = 12

        init?(_ dataType: cublasDataType_t) {
            /// Complex data types are not yet supported
            self.init(rawValue: dataType.rawValue)
        }
    }
}

public protocol BLASDataProtocol {
    static var blasDataType: BLAS.DataType { get }
}

extension BLASDataProtocol {
    static var cType: cublasDataType_t {
        return cublasDataType_t(blasDataType.rawValue)
    }
}

extension Float : BLASDataProtocol {
    public static let blasDataType: BLAS.DataType = .float
}

extension Double : BLASDataProtocol {
    public static let blasDataType: BLAS.DataType = .double
}

extension Int8 : BLASDataProtocol {
    public static let blasDataType: BLAS.DataType = .int8
}

extension UInt8 : BLASDataProtocol {
    public static let blasDataType: BLAS.DataType = .uint8
}
