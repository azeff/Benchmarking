// Copyright © 2017 Károly Lőrentey.
// This file is part of Attabench: https://github.com/attaswift/Benchmarking
// For licensing information, see the file LICENSE.md in the Git repository above.

import ArgumentParser
import Foundation

struct ListCommand: ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List available tasks"
    )

    func run() throws {
        let flattenTasksString = activeBenchmark.benchmarkNames.joined(separator: ", ")
        print(flattenTasksString)
    }
}
