//
//  File.swift
//  
//
//  Created by Evgeny Kazakov on 9/21/20.
//

import ArgumentParser
import BenchmarkIPC
import Foundation

struct RunCommand: ParsableCommand {
    
    enum OutputFormat: String, CaseIterable, ExpressibleByArgument {
        case pretty
        case json
    }

    static var configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Run selected benchmarks."
    )

    @Option(
        name: [.short, .long],
        parsing: .upToNextOption,
        help: "Benchmark tasks to run."
    )
    var tasks: [String]

    @Flag(
        name: [.short, .customLong("all-tasks")],
        help: "Run all benchmark tasks."
    )
    var all: Bool = false

    @Option(
        name: [.short, .long],
        parsing: .upToNextOption,
        help: "Input sizes to measure."
    )
    var sizes: [Int]

    @Option(
        name: [.short, .long],
        help: "Number of iterations to run."
    )
    var iterations: Int = 1

    @Option(
        help: "Repeat each task for at least this amount of seconds."
    )
    var minDuration: Double = 0

    @Option(
        help: "Stop repeating tasks after this amount of time."
    )
    var maxDuration: Double = Double.infinity

    @Option(
        name: [.short, .long],
        help: "Output format: 'pretty' or 'json'."
    )
    var format: OutputFormat = .pretty

    func validate() throws {
        guard iterations > 0 else {
            throw ValidationError("Value provided via '--iterations' must be a positive integer.")
        }
        guard !sizes.isEmpty else {
            throw ValidationError("Need at least one size.")
        }
        if sizes.firstIndex(where: { $0 < 1 }) != nil {
            throw ValidationError("Values provided via '--sizes' must be a positive integers.")
        }
    }
    
    func run() throws {
        let options = RunOptions(
            tasks: all ? [] : tasks,
            sizes: sizes,
            outputFormat: RunOptions.OutputFormat(rawValue: format.rawValue)!,
            iterations: iterations,
            minimumDuration: minDuration,
            maximumDuration: maxDuration
        )
        
        let output: OutputProtocol
        switch format {
        case .pretty:
            output = PrettyOutput(to: OutputFile(.standardOutput))
        case .json:
            output = JSONOutput(to: OutputFile(.standardOutput))
        }
        let runner = BenchmarkRunner(suite: activeBenchmark, options: options, output: output)
        try runner.run()
    }
}
