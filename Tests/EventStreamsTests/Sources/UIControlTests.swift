//
//  Created by Daniel Coleman on 11/18/21.
//

#if !os(macOS) && !os(watchOS)

import XCTest
import UIKit

@testable import EventStreams

class UIControlTests: XCTestCase {

    func testEventStream() throws {

        let control = UIButton()
        let event = UIControl.Event.touchUpInside
                
        let stream = control.eventStream(for: event)

        var expectedEvents: [Range<Date>] = []
        var receivedEvents: [Date] = []

        let subscription = stream.subscribe { event in

            receivedEvents.append(event.time)
        }

        for _ in 0..<10 {
            
            let timeLowerBound = Date()
            control.trigger(event: event)
            let timeUpperBound = Date()
            
            expectedEvents.append(timeLowerBound..<timeUpperBound)
        }
        
        XCTAssertTrue(receivedEvents.elementsEqual(expectedEvents, by: { eventTime, expecetedTimeRange in
            
            expecetedTimeRange.contains(eventTime)
        }))
    }
}

extension UIControl {
    
    func trigger(event: Event) {
        
        for target in allTargets {
            
            guard let actions = self.actions(forTarget: target, forControlEvent: event) else {
                continue
            }
            
            for action in actions {
                
                (target as NSObject).perform(Selector(action), with: self)
//                sendAction(Selector(action), to: target, for: UIEvent())
            }
        }
    }
}

#endif
