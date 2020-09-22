// Copyright © 2017 Károly Lőrentey.
// This file is part of Attabench: https://github.com/attaswift/Benchmarking
// For licensing information, see the file LICENSE.md in the Git repository above.

public func main(
    _ suite: BenchmarkSuite = defaultBenchmarkSuite
) {
    activeBenchmark = suite
    MainCommand.main()
}

private(set) var activeBenchmark: BenchmarkSuite!
