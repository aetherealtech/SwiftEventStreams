//
//  Created by Daniel Coleman on 11/18/21.
//

import XCTest

import Observer
@testable import EventStreams

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
class AwaitTests: XCTestCase {

    class Results {

        var result = Set<Int>()
    }

    func testAwait() async throws {
        
        let source: AnyTypedChannel<Task<Int, Never>> = SimpleChannel().asTypedChannel()
        
        let testEvents = Set<Int>(0..<10)

        let sourceStream = source.asStream()
        let awaitedStream = sourceStream.await()
        
        let receivedEvents = Results()
        
        let subscription = awaitedStream.subscribe { (event: Int) in

            DispatchQueue.main.async {

                receivedEvents.result.insert(event)
            }
        }
        
        for event in testEvents {

            source.publish(Task<Int, Never> {

                try! await Task.sleep(nanoseconds: UInt64(1e3))

                return event
            })
        }

        try await Task.sleep(nanoseconds: UInt64(1e9))

        XCTAssertEqual(receivedEvents.result, testEvents)

        withExtendedLifetime(subscription) { }
    }
}