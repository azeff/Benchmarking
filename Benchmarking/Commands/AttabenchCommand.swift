// Copyright © 2017 Károly Lőrentey.
// This file is part of Attabench: https://github.com/attaswift/Benchmarking
// For licensing information, see the file LICENSE.md in the Git repository above.

import ArgumentParser
import BenchmarkIPC
import Foundation

struct AttabenchCommand: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "attabench",
        abstract: "Run benchmarks inside an Attabench session"
    )

    @Argument(help: .init("Path to the report fifo", valueName: "path"))
    var reportFilePath: String

    func run() throws {
        // Turn off output buffering.
        setbuf(stdout, nil)
        setbuf(stderr, nil)

        guard let outputHandle = FileHandle(forWritingAtPath: reportFilePath) else {
            throw CocoaError.error(.fileNoSuchFile)
        }
        defer { outputHandle.closeFile() }
        
        let output = OutputFile(outputHandle)
        let input = FileHandle.standardInput.readDataToEndOfFile()
        let command = try JSONDecoder().decode(Command.self, from: input)
        
        switch command {
        case .list:
            let list = Report.list(tasks: activeBenchmark.benchmarkNames)
            let listJSONData = try JSONEncoder().encode(list)
            try output.write(listJSONData + [0x0a]) // list + newline
            sleep(1) // TODO: EK - why?
        case .run(let options):
            let runner = BenchmarkRunner(suite: activeBenchmark, options: options, output: JSONOutput(to: output))
            try runner.run()
        }
    }
}
