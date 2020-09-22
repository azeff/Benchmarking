// Copyright © 2017 Károly Lőrentey.
// This file is part of Attabench: https://github.com/attaswift/Benchmarking
// For licensing information, see the file LICENSE.md in the Git repository above.

import ArgumentParser

struct MainCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "",
        subcommands: [ListCommand.self, AttabenchCommand.self, RunCommand.self]
    )
}
