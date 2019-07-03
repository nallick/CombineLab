//
//  SquareOperator.swift
//

import Combine

public struct SquareOperator<Upstream, Output>: Publisher where Upstream: Publisher, Output: Numeric, Output == Upstream.Output {
    public typealias Failure = Upstream.Failure

    private var upstreamSubscriber: AnySubscriber<Output, Failure>!
    private var downstreamSubscription = DownstreamSubscription()

    public init(_ upstreamPublisher: Upstream) {
        self.upstreamSubscriber = AnySubscriber(receiveSubscription: self.receiveUpstream(subscription:),
                                                receiveValue: self.receiveUpstream,
                                                receiveCompletion: self.receiveUpstream(completion:))
        upstreamPublisher.subscribe(self.upstreamSubscriber)
    }

    public func receive<S>(subscriber: S) where Output == S.Input, Failure == S.Failure, S: Subscriber {
        self.downstreamSubscription.subscriber = AnySubscriber(subscriber)
        subscriber.receive(subscription: self.downstreamSubscription)
    }

    private func receiveUpstream(subscription: Subscription) {
        self.downstreamSubscription.upstreamSubscription = subscription
        subscription.request(self.downstreamSubscription.demand)
    }

    private func receiveUpstream(_ input: Output) -> Subscribers.Demand {
        let demand = self.downstreamSubscription.demand
        if demand > .none, let downstreamSubscriber = self.downstreamSubscription.subscriber {
            let value = self.performOperator(input)
            _ = downstreamSubscriber.receive(value)
        }

        return demand
    }

    private func receiveUpstream(completion: Subscribers.Completion<Upstream.Failure>) {
        self.downstreamSubscription.subscriber?.receive(completion: completion)
        self.downstreamSubscription.cancel()
    }

    private func performOperator(_ value: Output) -> Output {
        return value*value
    }

    private final class DownstreamSubscription: Subscription {
        fileprivate var subscriber: AnySubscriber<Output, Failure>?
        fileprivate var upstreamSubscription: Subscription?
        fileprivate var demand: Subscribers.Demand = .none

        fileprivate func request(_ demand: Subscribers.Demand) {
            self.demand = demand
            self.upstreamSubscription?.request(demand)
        }

        fileprivate func cancel() {
            self.subscriber = nil   // TODO: thread safe?
            self.upstreamSubscription = nil
            self.demand = .none
        }
    }
}

extension Publisher {
    public func square<Output>() -> SquareOperator<Self, Output> where Output == Self.Output {
        return SquareOperator<Self, Output>(self)
    }
}
