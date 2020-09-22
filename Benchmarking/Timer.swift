// Copyright © 2017 Károly Lőrentey.
// This file is part of Attabench: https://github.com/attaswift/Benchmarking
// For licensing information, see the file LICENSE.md in the Git repository above.

import Foundation
import QuartzCore

public class BenchmarkTimer {
   
    private var elapsedTime: TimeInterval? = nil

    @inline(never)
    static func measure(_ body: (BenchmarkTimer) throws -> Void) rethrows -> TimeInterval {
        let timer = BenchmarkTimer()
        let start = CACurrentMediaTime()
        try body(timer)
        let end = CACurrentMediaTime()
        return timer.elapsedTime ?? (end - start)
    }

    @inline(never)
    public func measure(_ body: () -> ()) {
        let start = CACurrentMediaTime()
        body()
        let end = CACurrentMediaTime()
        elapsedTime = end - start
    }
}

