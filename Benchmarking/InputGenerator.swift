// Copyright © 2017 Károly Lőrentey.
// This file is part of Attabench: https://github.com/attaswift/Benchmarking
// For licensing information, see the file LICENSE.md in the Git repository above.

public protocol InputGeneratorProtocol {
    associatedtype Value
    func generate(_ size: Int) -> Value
}

public struct RandomArrayGenerator: InputGeneratorProtocol {
    public init() {}
    
    public func generate(_ size: Int) -> [Int] {
        (0 ..< size).shuffled()
    }
}

public struct PairGenerator<G1: InputGeneratorProtocol, G2: InputGeneratorProtocol>: InputGeneratorProtocol {
    public typealias Value = (G1.Value, G2.Value)
    
    var firstGenerator: G1
    var secondGenerator: G2
    
    public init(_ firstGenerator: G1, _ secondGenerator: G2) {
        self.firstGenerator = firstGenerator
        self.secondGenerator = secondGenerator
    }
    
    public func generate(_ size: Int) -> Value {
        (firstGenerator.generate(size), secondGenerator.generate(size))
    }
}

public struct ClosureGenerator<Value>: InputGeneratorProtocol {
    private let generator: (Int) -> Value
    
    public init(_ generator: @escaping (Int) -> Value) {
        self.generator = generator
    }
    
    public func generate(_ size: Int) -> Value {
        generator(size)
    }
}
