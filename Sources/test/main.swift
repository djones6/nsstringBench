/*
 * Copyright IBM Corporation 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

extension String {

    func equalsLowercased(_ aString: String) -> Bool {
        assert(aString == aString.lowercased(), "equalsLowercased() should be passed a lowercased string, not '\(aString)'")
        return self.lowercased() == aString
    }

    /// Trims space and tab characters from the start and end of a string.
    func trimAsciiWhitespace() -> String {
        return String(self.drop {
            char in
            return char == " " || char == "\u{0009}"
            }.reversed().drop {
                char in
                return char == " " || char == "\u{0009}"
            }.reversed())
    }

    /// Trims space and tab characters from the start and end of a string.
    func trimAsciiWhitespace2() -> String {
        // trim whitespace from the front of a string
        let trimmedPrefix = self.drop {
            char in
            return char == " " || char == "\u{0009}"
        }
        // Early exit if resulting string is now empty
        guard !trimmedPrefix.isEmpty else {
            return ""
        }
        // (hopefully) faster way to trim whitespace from the end of a string
        let startIndex = trimmedPrefix.startIndex
        var endIndex = trimmedPrefix.endIndex
        repeat {
            let prevIndex = trimmedPrefix.index(before: endIndex)
            if trimmedPrefix[prevIndex] != " " && trimmedPrefix[prevIndex] != "\u{0009}" {
                break
            }
            endIndex = prevIndex
        } while endIndex > startIndex
        return String(trimmedPrefix.prefix(upTo: endIndex))
    }

    /// Trims space and tab characters from the start and end of a string.
    func trimAsciiWhitespace3() -> String {
        // This seems to be marginally slower than using drop(while:)
        var startIndex1 = self.startIndex
        let endIndex1 = self.endIndex
        repeat {
            if self[startIndex1] != " " && self[startIndex1] != "\u{0009}" {
                break
            }
            startIndex1 = self.index(after: startIndex1)
        } while startIndex1 < endIndex1
        let trimmedPrefix = self.suffix(from: startIndex1)
        // (hopefully) faster way to trim whitespace from the end of a string
        let startIndex = trimmedPrefix.startIndex
        var endIndex = trimmedPrefix.endIndex
        repeat {
            let prevIndex = trimmedPrefix.index(before: endIndex)
            if trimmedPrefix[prevIndex] != " " && trimmedPrefix[prevIndex] != "\u{0009}" {
                break
            }
            endIndex = prevIndex
        } while endIndex > startIndex
        return String(trimmedPrefix.prefix(upTo: endIndex))
    }

    /// Trims space and tab characters from the start and end of a string.
    mutating func trimAsciiWhitespace4() {
        // trim whitespace from the front of a string
        while self.first == " " || self.first == "\u{0009}" {
            self.removeFirst()
        }
        while self.last == " " || self.last == "\u{0009}" {
            self.removeLast()
        }
    }

    /// Trims space and tab characters from the start and end of a string.
    mutating func trimAsciiWhitespace5() {
        // trim whitespace from the front of a string
        while self.first == " " || self.first == "\u{0009}" {
            self.remove(at: self.startIndex)
        }
        while self.last == " " || self.last == "\u{0009}" {
            self.remove(at: self.index(before: self.endIndex))
        }
    }
}


// Determine how many concurrent blocks to schedule (user specified, or 10)
var CONCURRENCY:Int = 1

// Determines how many times to convert per block
var EFFORT:Int = 1000

// Test duration (milliseconds)
var TEST_DURATION:Int = 5000

// Data to be converted
//var DATA:String = "acCepT"
var DATA:String = "  \u{0009}This is some string  \u{0009}"

// Method of conversion
var METHOD = 1

// Determines how many times each block should be dispatched before terminating
var NUM_LOOPS:Int = 9999999

// Debug
var DEBUG = false

func usage() {
    print("Options are:")
    print("  -c, --concurrency n: number of concurrent Dispatch blocks (default: \(CONCURRENCY))")
    print("  -n, --num_loops n: no. of times to invoke each block (default: \(NUM_LOOPS))")
    print("  -e, --effort n: no. of conversions to perform per block (default: \(EFFORT))")
    print("  -t, --time n: maximum runtime of the test (in ms) (default: \(TEST_DURATION))")
    print("  -s, --data s: String to be converted from Data to String (default: \(DATA))")
    print("  -m, --method n: method of conversion:")
    print("          1 = equality: Foundation caseInsensitiveCompare")
    print("          2 = equality: Stdlib lowercased")
    print("          101 = non-equality: Foundation caseInsensitiveCompare")
    print("          102 = non-equality: Stdlib lowercased")
    print("          3 = trimming: Foundation trimmingCharacters(in: .whitespaces)")
    print("          4 = trimming: Stdlib drop/reverse/drop/reverse")
    print("          5 = trimming: Stdlib drop/repeat to discover last index")
    print("          6 = trimming: Stdlib repeat/repeat to discover first + last indices")
    print("          7 = trimming: Stdlib while self.removeFirst / removeLast")
    print("          8 = trimming: Stdlib while self.remove(at:)")
    print("  -d, --debug: print a lot of debugging output (default: \(DEBUG))")
    exit(1)
}

// Parse an expected int value provided on the command line
func parseInt(param: String, value: String) -> Int {
    if let userInput = Int(value) {
        return userInput
    } else {
        print("Invalid value for \(param): '\(value)'")
        exit(1)
    }
}

// Parse command line options
var param:String? = nil
var remainingArgs = CommandLine.arguments.dropFirst(1)
for arg in remainingArgs {
    if let _param = param {
        param = nil
        switch _param {
        case "-c", "--concurrency":
            CONCURRENCY = parseInt(param: _param, value: arg)
        case "-e", "--effort":
            EFFORT = parseInt(param: _param, value: arg)
        case "-t", "--time":
            TEST_DURATION = parseInt(param: _param, value: arg)
        case "-s", "--string":
            DATA = arg
        case "-m", "--method":
            METHOD = parseInt(param: _param, value: arg)
        case "-n", "--num_loops":
            NUM_LOOPS = parseInt(param: _param, value: arg)
        default:
            print("Invalid option '\(arg)'")
            usage()
        }
    } else {
        switch arg {
        case "-c", "--concurrency", "-e", "--effort", "-t", "--time", "-s", "--string", "-n", "--num_loops", "-m", "--method":
            param = arg
        case "-d", "--debug":
            DEBUG = true
        case "-?", "-h", "--help", "--?":
            usage()
        default:
            print("Invalid option '\(arg)'")
            usage()
        }
    }
}

if (DEBUG) {
    print("Concurrency: \(CONCURRENCY)")
    print("Effort: \(EFFORT)")
    print("Debug: \(DEBUG)")
}

var MAX_CONCURRENCY:Int = CONCURRENCY

// Separate data for each thread
var STRINGS:[String] = [String]()
for _ in 1...MAX_CONCURRENCY {
    let s = String(DATA)
    STRINGS.append(s)
}

// Create a queue to run blocks in parallel
let queue = DispatchQueue(label: "hello", attributes: .concurrent)
let group = DispatchGroup()
let lock = DispatchSemaphore(value: 1)
var completeLoops:Int = 0
var RUNNING = true

// Block to be scheduled
func code(block: Int, loops: Int) -> () -> Void {
    return {
        let lSTRING = STRINGS[block-1]
        let checkLowerCase = lSTRING.lowercased()
        let checkDifferent = "x" + checkLowerCase
        var result: Bool = false
        var resultStr: String = ""
        switch METHOD {
        case 1:
            for _ in 1...EFFORT {
                result = lSTRING.caseInsensitiveCompare(checkLowerCase) == .orderedSame
                if !result {
                    print("Error - compare failed")
                    return
                }
            }
        case 2:
            for _ in 1...EFFORT {
                result = lSTRING.equalsLowercased(checkLowerCase)
                if !result {
                    print("Error - compare failed")
                    return
                }
           }
        case 101:
            for _ in 1...EFFORT {
                result = lSTRING.caseInsensitiveCompare(checkDifferent) == .orderedSame
                if result {
                    print("Error - compare succeeded")
                    return
                }
            }
        case 102:
            for _ in 1...EFFORT {
                result = lSTRING.equalsLowercased(checkDifferent)
                if result {
                    print("Error - compare succeeded")
                    return
                }
           }
        case 3:
            for _ in 1...EFFORT {
                resultStr = lSTRING.trimmingCharacters(in: .whitespaces)
            }
        case 4:
            for _ in 1...EFFORT {
                resultStr = lSTRING.trimAsciiWhitespace()
            }
        case 5:
            for _ in 1...EFFORT {
                resultStr = lSTRING.trimAsciiWhitespace2()
            }
        case 6:
            for _ in 1...EFFORT {
                resultStr = lSTRING.trimAsciiWhitespace3()
            }
        case 7:
            for _ in 1...EFFORT {
                resultStr = lSTRING
                resultStr.trimAsciiWhitespace4()
            }
        case 8:
            for _ in 1...EFFORT {
                resultStr = lSTRING
                resultStr.trimAsciiWhitespace5()
            }
       default:
            print("Error - unknown method \(METHOD)")
            return
        }
        // Compare to reference impl
        switch METHOD {
        case 1,2,101,102:
            break
        case 3,4,5,6,7,8:
            if resultStr != lSTRING.trimmingCharacters(in: .whitespaces) {
                print("FAILED trimming: '\(resultStr)'")
                return
            }
        default:
            print("Unexpected method")
        }

        if DEBUG && loops == 1 {
            print("Instance \(block) done")
            print("Converted data: '\(result)'")
        }
        // Update loop completion stats
        queue.async(group: group) {
            _ = lock.wait(timeout: .distantFuture)
            completeLoops += 1
            lock.signal()
        }
        if RUNNING && loops < NUM_LOOPS {
            // Dispatch a new block to replace this one
            queue.async(group: group, execute: code(block: block, loops: loops+1))
        } else {
            if DEBUG { print("Block \(block) completed \(loops) loops") }
        }
    }
}

// warmup
queue.async(group: group, execute: code(block: 1, loops: 1))
_ = group.wait(timeout: .now() + DispatchTimeInterval.milliseconds(1000)) // 1 second
RUNNING = false
_ = group.wait(timeout: .distantFuture) // allow final blocks to finish
if DEBUG { print("Warmup complete") }

for c in 1...MAX_CONCURRENCY {
    CONCURRENCY = c
    completeLoops = 0
    RUNNING = true
    if DEBUG {
        print("Concurrency: \(CONCURRENCY), Effort: \(EFFORT), Loops: \(NUM_LOOPS), Time limit: \(TEST_DURATION)ms")
    }
    let startTime = Date()
    // Queue the initial blocks
    for i in 1...CONCURRENCY {
        queue.async(group: group, execute: code(block: i, loops: 1))
    }

    // Go
    _ = group.wait(timeout: .now() + DispatchTimeInterval.milliseconds(TEST_DURATION)) // 5 seconds
    RUNNING = false
    _ = group.wait(timeout: .distantFuture) // allow final blocks to finish

    let elapsedTime = -startTime.timeIntervalSinceNow
    let completedOps = completeLoops * EFFORT

    var displayOps = Double(completedOps)
    var opsUnit:NSString = "%.0f"
    if completedOps > 100000000 {
        displayOps = displayOps / 1000000
        opsUnit = "%.2fm"
    } else if completedOps > 100000 {
        displayOps = displayOps / 1000
        opsUnit = "%.2fk"
    }
    let opsPerSec = displayOps / elapsedTime

    let output = String(format: "Concurrency %d: completed %d loops (\(opsUnit) ops) in %.2f seconds, \(opsUnit) ops/sec", CONCURRENCY, completeLoops, displayOps, elapsedTime, opsPerSec)
    print("\(output)")
}
