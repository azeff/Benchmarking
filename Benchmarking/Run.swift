// Copyright © 2017 Károly Lőrentey.
// This file is part of Attabench: https://github.com/attaswift/Benchmarking
// For licensing information, see the file LICENSE.md in the Git repository above.

import Foundation
import BenchmarkIPC
import ArgumentParser

extension Benchmark {
    func listTasks() {
        for task in taskTitles {
            print(task)
        }
    }

    func run(tasks: [BenchmarkTask<Input>],
             sizes: [Int],
             output: OutputProtocol,
             minimumDuration: TimeInterval?,
             maximumDuration: TimeInterval?,
             iterations: Int) throws {
        print("Running \(tasks.count) tasks at \(sizes.count) sizes from \(sizes.min()!) to \(sizes.max()!)")
        var sizes = sizes
        while !sizes.isEmpty {
            let startCycle = Date()
            for size in sizes {
                let input = self.inputGenerator(size)
                var found = false
                for task in tasks {
                    try output.begin(task: task.title, size: size)
                    guard let instance = TaskInstance(task: task, size: size, input: input) else { continue }
                    var minimum: TimeInterval? = nil
                    var duration: TimeInterval = 0
                    var iteration = 0
                    repeat {
                        let elapsed = instance.run()
                        minimum = Swift.min(elapsed, minimum ?? elapsed)
                        try output.progress(task: task.title, size: size, time: elapsed)
                        duration += elapsed
                        iteration += 1
                    } while (duration < maximumDuration ?? .infinity
                        && (iteration < iterations || duration < minimumDuration ?? 0))
                    try output.finish(task: task.title, size: size, time: minimum!)
                    found = true
                }
                if !found {
                    sizes = sizes.filter { $0 != size }
                }
            }
            print("Finished one full cycle in \(Date().timeIntervalSince(startCycle)) seconds.")
        }
    }

    func run(_ options: RunOptions, output: OutputProtocol? = nil) throws {
        var tasks: [BenchmarkTask<Input>] = try options.tasks.map { title in
            guard let task = self.tasks[title] else {
                throw OptionError("Unknown task '\(title)'")
            }
            return task
        }
        if tasks.isEmpty {
            tasks = taskTitles.map { self.tasks[$0]! }
        }
        let sizes = options.sizes
        guard !sizes.isEmpty else {
            throw OptionError("Need at least one size")
        }
        if let i = sizes.firstIndex(where: { $0 < 1 }) {
            throw OptionError("Invalid size \(sizes[i])")
        }
        guard options.iterations > 0 else {
            throw OptionError("Invalid iteration count")
        }

        let output = output ?? {
            switch options.outputFormat {
            case .pretty:
                return PrettyOutput(to: OutputFile(.standardOutput))
            case .json:
                return JSONOutput(to: OutputFile(.standardOutput))
            }
        }()
        try self.run(tasks: tasks,
                 sizes: sizes,
                 output: output,
                 minimumDuration: options.minimumDuration,
                 maximumDuration: options.maximumDuration,
                 iterations: options.iterations)
    }

    func attarun(reportFile: String) throws {
        // Turn off output buffering.
        setbuf(stdout, nil)
        setbuf(stderr, nil)

        let decoder = JSONDecoder()
        guard let outputHandle = FileHandle(forWritingAtPath: reportFile) else {
            throw CocoaError.error(.fileNoSuchFile)
        }
        defer { outputHandle.closeFile() }
        let output = OutputFile(outputHandle)
        let input = FileHandle.standardInput.readDataToEndOfFile()
        let command = try decoder.decode(Command.self, from: input)
        switch command {
        case .list:
            let list = try! JSONEncoder().encode(Report.list(tasks: self.taskTitles))
            try output.write(list + [0x0a])
            sleep(1)
        case .run(let options):
            try self.run(options, output: JSONOutput(to: output))
        }
    }
}

extension Benchmark {
    public func start() {
        do {
            Benchmarking.listTasks = listTasks
            Benchmarking.attarun = attarun
            Benchmarking.run = { options in try self.run(options) }
            
            let main = try MainCommand.parseAsRoot()
            try main.run()
        } catch {
            // Print info about error or help and exit.
            MainCommand.exit(withError: error)
        }
    }
}

private struct TaskInstance<Input> {
    let task: BenchmarkTask<Input>
    let size: Int
    let instance: (BenchmarkTimer) -> Void

    init?(task: BenchmarkTask<Input>, size: Int, input: Input) {
        self.task = task
        self.size = size
        guard let instance = task.generate(input: input) else { return nil }
        self.instance = instance
    }

    @inline(never)
    func run() -> TimeInterval {
        return BenchmarkTimer.measure(instance)
    }
}

private struct OptionError: Error, CustomStringConvertible {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    public var description: String { return message }
}

// MARK: - Argument Parser Commands

private var listTasks: () throws -> Void = {
    fatalError()
}

private var attarun: (String) throws -> Void = { reportFilePath in
    fatalError()
}

private var run: (RunOptions) throws -> Void = { options in
    fatalError()
}

private struct ListCommand: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List available tasks"
    )

    func run() throws {
        try listTasks()
    }
}

private struct AttabenchCommand: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "attabench",
        abstract: "Run benchmarks inside an Attabench session"
    )

    @Argument(help: .init("Path to the report fifo", valueName: "path"))
    var reportFilePath: String

    func run() throws {
        try attarun(reportFilePath)
    }
}

private struct RunCommand: ParsableCommand {
    enum OutputFormat: String, CaseIterable, ExpressibleByArgument {
        case pretty
        case json
    }

    static var configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Run selected benchmarks"
    )

    @Option(
        name: [.short, .long],
        help: "Benchmark tasks to run."
    )
    var tasks: [String]

    @Flag(
        name: [.short, .customLong("all-tasks")],
        help: "Run all benchmark tasks"
    )
    var all: Bool

    @Option(
        name: [.short, .long],
        help: "Input sizes to measure"
    )
    var sizes: [Int]

    @Option(
        name: [.short, .long],
        default: 1,
        help: "Number of iterations to run"
    )
    var iterations: Int

    @Option(
        default: 0,
        help: "Repeat each task for at least this amount of seconds"
    )
    var minDuration: Double

    @Option(
        default: Double.infinity,
        help: "Stop repeating tasks after this amount of time"
    )
    var maxDuration: Double

    @Option(
        name: [.short, .long],
        default: .pretty,
        help: "Output format: 'pertty' or 'json'"
    )
    var format: OutputFormat

    func run() throws {
        let options = RunOptions(
            tasks: all ? [] : tasks,
            sizes: sizes,
            outputFormat: RunOptions.OutputFormat(rawValue: format.rawValue)!,
            iterations: iterations,
            minimumDuration: minDuration,
            maximumDuration: maxDuration
        )
        
        try Benchmarking.run(options)
    }
}

struct MainCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "",
        subcommands: [ListCommand.self, AttabenchCommand.self, RunCommand.self]
    )
}
