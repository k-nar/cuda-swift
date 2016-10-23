//
//  Array.swift
//  CUDA
//
//  Created by Richard Wei on 10/19/16.
//
//

import CCUDARuntime

/// A non-owning pointer to a buffer of mutable elements stored contiguously
/// in graphic device memory, presenting a collection interface to the underlying 
/// elements.
public struct UnsafeMutableDeviceBufferPointer<Element> : RandomAccessCollection {

    public let baseAddress: UnsafeMutableDevicePointer<Element>?
    public let count: Int

    public init(start: UnsafeMutableDevicePointer<Element>?, count: Int) {
        self.baseAddress = start
        self.count = start == nil ? 0 : count
    }

    public func index(after i: Int) -> Int {
        return i + 1
    }

    public func index(before i: Int) -> Int {
        return i - 1
    }

    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        return count
    }

    public subscript(i: Int) -> Element {
        get {
            return baseAddress![i]
        }
        nonmutating set {
            baseAddress![i] = newValue
        }
    }

}

fileprivate final class DeviceArrayBuffer<Element> : RandomAccessCollection {

    typealias Index = Int
    typealias IndexDistance = Int

    let baseAddress: UnsafeMutableDevicePointer<Element>

    private(set) var count: Int

    required init(capacity: Int) {
        baseAddress = UnsafeMutableDevicePointer.allocate(capacity: capacity)
        count = capacity
    }

    convenience init(_ other: DeviceArrayBuffer<Element>) {
        self.init(capacity: other.count)
        self.baseAddress.assign(from: other.baseAddress, count: count)
    }

    convenience init<C: Collection>(_ elements: C) where
        C.Iterator.Element == Element, C.IndexDistance == Int
    {
        self.init(capacity: elements.count)
        self.baseAddress.assign(fromHost: elements)
    }

    deinit {
        baseAddress.deallocate()
    }

    func index(after i: Int) -> Int {
        return i + 1
    }

    func index(before i: Int) -> Int {
        return i - 1
    }

    var startIndex: Int {
        return 0
    }

    var endIndex: Int {
        return count
    }

    subscript(i: Int) -> Element {
        get {
            return baseAddress[i]
        }
        set {
            baseAddress[i] = newValue
        }
    }
    
}

public struct DeviceArray<Element> : RandomAccessCollection, ExpressibleByArrayLiteral {

    public typealias Index = Int
    public typealias IndexDistance = Int

    private var buffer: DeviceArrayBuffer<Element>

    /// Copy on write
    private var cowBuffer: DeviceArrayBuffer<Element> {
        mutating get {
            if !isKnownUniquelyReferenced(&buffer) {
                buffer = DeviceArrayBuffer(buffer)
            }
            return buffer
        }
    }

    public init(capacity: Int) {
        buffer = DeviceArrayBuffer(capacity: capacity)
    }

    public init<C: Collection>(fromHost elements: C) where
        C.Iterator.Element == Element, C.IndexDistance == Int
    {
        buffer = DeviceArrayBuffer(elements)
    }

    public init(arrayLiteral elements: Element...) {
        buffer = DeviceArrayBuffer(elements)
    }

    public init(_ other: DeviceArray<Element>) {
        self = other
    }

    public func makeHostArray() -> [Element] {
        var elements: [Element] = []
        elements.reserveCapacity(count)
        /// Temporary array copy solution
        var temp = UnsafeMutablePointer<Element>.allocate(capacity: count)
        temp.assign(fromDevice: buffer.baseAddress, count: count)
        elements.append(contentsOf: UnsafeBufferPointer(start: temp, count: count))
        temp.deallocate(capacity: count)
        return elements
    }

    public var count: Int {
        return buffer.count
    }

    public func index(after i: Int) -> Int {
        return i + 1
    }

    public func index(before i: Int) -> Int {
        return i - 1
    }

    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        return count
    }

    public subscript(i: Int) -> Element {
        get {
            return buffer[i]
        }
        mutating set {
            cowBuffer[i] = newValue
        }
    }

    public func withUnsafeDeviceMutableBufferPointer<Result>
        (_ body: (UnsafeMutableDeviceBufferPointer<Element>) throws -> Result) rethrows -> Result {
        return try body(UnsafeMutableDeviceBufferPointer(start: buffer.baseAddress, count: count))
    }

}

public extension Array {

    public init(_ elementsOnDevice: DeviceArray<Element>) {
        self = elementsOnDevice.makeHostArray()
    }
    
}