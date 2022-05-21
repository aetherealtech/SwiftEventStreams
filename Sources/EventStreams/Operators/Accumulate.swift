//
//  Created by Daniel Coleman on 1/9/22.
//

import Foundation
import Observer

extension EventStream {

    public func accumulate<Result>(
        initialValue: Result,
        _ accumulator: @escaping (Result, Value) -> Result
    ) -> EventStream<Result> {

        AccumulateEventStream(
            source: self,
            initialValue: initialValue,
            accumulator: accumulator
        )
    }
}

class AccumulateEventStream<Value, Result> : EventStream<Result>
{
    init(
        source: EventStream<Value>,
        initialValue: Result,
        accumulator: @escaping (Result, Value) -> Result
    ) {

        let channel = SimpleChannel<Event<Result>>()
        self.source = source

        var last = initialValue

        subscription = source.subscribe(
            onValue: { value in

                last = accumulator(last, value)
                channel.publish(last)
            }
        )

        super.init(
            channel: channel
        )
    }

    let source: EventStream<Value>

    let subscription: Subscription
}
