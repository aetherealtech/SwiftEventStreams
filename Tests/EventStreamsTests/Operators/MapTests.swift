//
//  Created by Daniel Coleman on 11/18/21.
//

import XCTest

import Observer
@testable import EventStreams

class MapTests: XCTestCase {

    func testMap() throws {
        
        let source = SimpleChannel<Int>()
        
        let testEvents = Array(0..<10)
        
        let transform: (Int) -> String = { value in "\(value)" }
        
        let expectedEvents = testEvents.map(transform)
        
        let sourceStream = source.asStream()
        let mappedStream = sourceStream.map(transform)
        
        var receivedEvents = [String]()
        
        let subscription = mappedStream.subscribe { event in receivedEvents.append(event) }
        
        for event in testEvents {
            source.publish(event)
        }
        
        XCTAssertEqual(receivedEvents, expectedEvents)

        withExtendedLifetime(subscription) { }
    }
}
