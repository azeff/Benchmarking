// Copyright © 2017 Károly Lőrentey.
// This file is part of Attabench: https://github.com/attaswift/Benchmarking
// For licensing information, see the file LICENSE.md in the Git repository above.

import Foundation

public protocol Benchmark {
    var name: String { get }
    
    func setUp(size: Int) -> Bool
    func run() throws
    func tearDown()
}

public class ClosureBenchmark<Input>: Benchmark {
    
    public let name: String
    
    private var input: Input?
    
    private let generator: (Int) -> Input
    private let closure: (Input) -> Void
    
    public init(name: String, generator: @escaping (Int) -> Input, closure: @escaping (Input) -> Void) {
        self.name = name
        self.generator = generator
        self.closure = closure
    }
    
    public func setUp(size: Int) -> Bool {
        input = generator(size)
        return true
    }
    
    public func run() throws {
        closure(input!)
    }
    
    public func tearDown() {
        input = nil
    }
}

public func benchmark<T>(name: String, generator: @escaping (Int) -> T, closure: @escaping (T) -> Void) {
    defaultBenchmarkSuite.add(name: name, generator: generator, closure: closure)
}
