// Copyright © 2017 Károly Lőrentey.
// This file is part of Attabench: https://github.com/attaswift/Benchmarking
// For licensing information, see the file LICENSE.md in the Git repository above.

import Foundation

public class BenchmarkSuite {
    
    private(set) var benchmarks: [Benchmark]
    
    public init(benchmarks: [Benchmark] = []) {
        self.benchmarks = benchmarks
    }
    
    public func add(_ benchmarks: Benchmark...) {
        for b in benchmarks {
            self.benchmarks.append(b)
        }
    }
}

extension BenchmarkSuite {
    
    public func add<T>(name: String, generator: @escaping (Int) -> T, closure: @escaping (T) -> Void) {
        add(ClosureBenchmark(name: name, generator: generator, closure: closure))
    }
}

extension BenchmarkSuite {
    public var benchmarkNames: [String] {
        benchmarks.map(\.name)
    }
}

public let defaultBenchmarkSuite = BenchmarkSuite()
