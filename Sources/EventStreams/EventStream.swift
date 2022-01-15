//
// Created by Daniel Coleman on 11/18/21.
//

import Foundation
import Observer

public protocol EventStreamProtocol {

    associatedtype Value

    func subscribe(
        onEvent: @escaping (Event<Value>) -> Void,
        onComplete: @escaping () -> Void
    ) -> Subscription
}

public struct Event<Value> {
    
    public init(
        _ value: Value,
        time: Date = Date()
    ) {
     
        self.value = value
        self.time = time
    }
    
    public let value: Value
    public let time: Date
}

extension Event: Equatable where Value: Equatable {

}

extension Event: Hashable where Value: Hashable {

}

public typealias EventSource<Value> = (
    _ publish: @escaping (Event<Value>) -> Void,
    _ complete: @escaping () -> Void
) -> Any

final public class EventStream<Value> : EventStreamProtocol {

    public init<Registrant>(
        registerEvents: (
            _ publish: @escaping (Event<Value>) -> Void,
            _ complete: @escaping () -> Void
        ) -> Registrant,
        unregister: @escaping (Registrant) -> Void
    ) {

        self.eventChannel = SimpleChannel().asTypedChannel()
        self.completeChannel = SimpleChannel().asTypedChannel()

        let registrant = registerEvents(
            eventChannel.publish,
            completeChannel.publish
        )

        self.unregister = { unregister(registrant) }
    }

    public func subscribe(
        onEvent: @escaping (Event<Value>) -> Void,
        onComplete: @escaping () -> Void
    ) -> Subscription {

        let eventSubscription = eventChannel.subscribe(onEvent)
        let onCompleteSubscription = completeChannel.subscribe(onComplete)

        let aggregateSubscription = AggregateSubscription([
            eventSubscription,
            onCompleteSubscription
        ])
        
        return RetainingSubscription(
            stream: self,
            subscription: aggregateSubscription
        )
    }
    
    public func subscribe(
        onEvent: @escaping (Event<Value>) -> Void
    ) -> Subscription {

        RetainingSubscription(
            stream: self,
            subscription: eventChannel.subscribe(onEvent)
        )
    }
    
    public func subscribe(
        onValue: @escaping (Value) -> Void,
        onComplete: @escaping () -> Void
    ) -> Subscription {

        subscribe(
            onEvent: { event in onValue(event.value) },
            onComplete: onComplete
        )
    }
    
    public func subscribe(
        onValue: @escaping (Value) -> Void
    ) -> Subscription {

        subscribe(onEvent: { event in onValue(event.value) })
    }

    private class RetainingSubscription: Subscription {
        
        public init(
            stream: EventStream<Value>,
            subscription: Subscription
        ) {
            
            self.stream = stream
            self.subscription = subscription
        }
        
        let stream: EventStream<Value>
        let subscription: Subscription
    }
    
    let eventChannel: AnyTypedChannel<Event<Value>>
    let completeChannel: AnyTypedChannel<Void>

    private let unregister: () -> Void
}

extension EventStream {

    public convenience init<Registrant>(
        registerValues: (
            _ publish: @escaping (Value) -> Void,
            _ complete: @escaping () -> Void
        ) -> Registrant,
        unregister: @escaping (Registrant) -> Void
    ) {

        self.init(
            registerEvents: { publish, complete in

                registerValues({ value in publish(Event<Value>(value)) }, complete)
            },
            unregister: unregister
        )
    }
}

extension EventStream {

    public convenience init<EventChannel: TypedSubChannel, CompleteChannel: TypedSubChannel>(
        eventChannel: EventChannel,
        completeChannel: CompleteChannel
    ) where EventChannel.Value == Event<Value>, CompleteChannel.Value == Void {

        self.init(
            registerEvents: { publish, complete -> Subscription in

                let valueSubscription = eventChannel.subscribe(publish)
                let completeSubscription = completeChannel.subscribe(complete)

                return AggregateSubscription([
                    valueSubscription,
                    completeSubscription]
                )
            },
            unregister: { subscription in

            }
        )
    }

    public convenience init<ValueChannel: TypedSubChannel, CompleteChannel: TypedSubChannel>(
        valueChannel: ValueChannel,
        completeChannel: CompleteChannel
    ) where ValueChannel.Value == Value, CompleteChannel.Value == Void {

        self.init(
            registerValues: { publish, complete -> Subscription in

                let valueSubscription = valueChannel.subscribe(publish)
                let completeSubscription = completeChannel.subscribe(complete)

                return AggregateSubscription([
                    valueSubscription,
                    completeSubscription]
                )
            },
            unregister: { subscription in

            }
        )
    }
}

extension EventStream {

    public convenience init(
        source: (
            _ publish: @escaping (Event<Value>) -> Void,
            _ complete: @escaping () -> Void
        ) -> Void
    ) {

        self.init(
            registerEvents: source,
            unregister: {  }
        )
    }
}