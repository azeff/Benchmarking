// Copyright © 2017 Károly Lőrentey.
// This file is part of Attabench: https://github.com/attaswift/Benchmarking
// For licensing information, see the file LICENSE.md in the Git repository above.

import Foundation
import BenchmarkIPC

struct BenchmarkRunner {
    
    let suite: BenchmarkSuite
    let options: RunOptions
    let output: OutputProtocol
    
    func run() throws {
        let taskNames = options.tasks
        let sizes = options.sizes
        print("Running \(taskNames.count) tasks at \(sizes.count) sizes from \(sizes.min()!) to \(sizes.max()!)")
        
        let startCycle = Date()
        for size in sizes {
            for benchmark in suite.benchmarks {
                guard benchmark.setUp(size: size) else { continue }
                defer { benchmark.tearDown() }
                
                try run(benchmark: benchmark, size: size)
            }
        }
        print("Finished cycle in \(Date().timeIntervalSince(startCycle)) seconds.")
    }
    
    private func run(benchmark: Benchmark, size: Int) throws {
        try output.begin(task: benchmark.name, size: size)

        var minimum: TimeInterval = .infinity
        var duration: TimeInterval = 0
        var iteration = 0

        repeat {
            defer { iteration += 1 }
            
            let elapsed = try BenchmarkTimer.measure { _ in
                try benchmark.run()
            }
            minimum = min(elapsed, minimum)
            try output.progress(task: benchmark.name, size: size, time: elapsed)
            duration += elapsed
        } while (duration < options.maximumDuration ?? .infinity)
            && (iteration < options.iterations || duration < options.minimumDuration ?? 0)

        // TODO: EK - why minimum time ?
        try output.finish(task: benchmark.name, size: size, time: minimum)
    }
    
    private func benchmarks() throws -> [Benchmark] {
        let names = Set(options.tasks)
        return suite.benchmarks.filter { names.contains($0.name) }
    }
}
