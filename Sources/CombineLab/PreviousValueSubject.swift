//
//  PreviousValueSubject.swift
//

import Combine

public final class PreviousValueSubject<Output>: Subject {
    public typealias Failure = Never

    public private(set) var currentValue: Output?
    public private(set) var previousValue: Output?

    private var subscriptions: [PreviousValueSubscription] = []

    public init() {}

    public func receive<S>(subscriber: S) where Output == S.Input, Failure == S.Failure, S: Subscriber {
        let subscription = PreviousValueSubscription(subject: self, subscriber: AnySubscriber(subscriber))
        self.subscriptions.append(subscription)
        subscriber.receive(subscription: subscription)
    }

    public func send(_ newValue: Output) {
        self.previousValue = self.currentValue
        self.currentValue = newValue
        if let value = self.previousValue {
            for subscription in subscriptions {
                subscription.sendValue(value)
            }
        }
    }

    public func send(completion: Subscribers.Completion<Failure>) {
        for subscription in subscriptions {
            subscription.completed(completion)
        }

        self.subscriptions.removeAll()
    }

    public func send(subscription: Subscription) {
    }

    private final class PreviousValueSubscription: Subscription {
        private var subscriber: AnySubscriber<Output, Failure>?
        private weak var subject: PreviousValueSubject?

        fileprivate init(subject: PreviousValueSubject, subscriber: AnySubscriber<Output, Failure>) {
            self.subscriber = subscriber
            self.subject = subject
        }

        fileprivate func request(_ demand: Subscribers.Demand) {
            if demand > .none, let previousValue = self.subject?.previousValue {
                self.sendValue(previousValue)
            }
        }

        fileprivate func cancel() {
            self.subscriber = nil   // TODO: thread safe?
        }

        fileprivate func sendValue(_ value: Output) {
            _ = self.subscriber?.receive(value)
        }

        fileprivate func completed(_ completion: Subscribers.Completion<Failure>) {
            self.subscriber?.receive(completion: completion)
        }
    }
}
