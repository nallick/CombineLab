//
//  LoggingSubscriber.swift
//

import Combine

public struct LoggingSubscriber<Upstream>: Subscriber where Upstream: Publisher {
    public typealias Input = Upstream.Output
    public typealias Failure = Upstream.Failure
    public typealias Logger = (String) -> Void

    public let maxRequest: Int
    public var hasSubscribed: Bool { self.subscriberState.hasSubscribed }
    public var isComplete: Bool { self.subscriberState.isComplete }

    public private(set) var combineIdentifier: CombineIdentifier
    private var subscriberState = SubscriberState()
    private let log: (Logger)?

    public init(_ upstreamPublisher: Upstream, maxCount: Int, maxRequest: Int, logger: Logger?) {
        self.log = logger
        self.maxRequest = maxRequest
        self.combineIdentifier = CombineIdentifier(self.subscriberState)
        self.subscriberState.maxCount = maxCount
        upstreamPublisher.subscribe(self)
    }

    public func receive(subscription: Subscription) {
        log?("LoggingSubscriber.receive.subscription: \(subscription)")
        self.subscriberState.hasSubscribed = true
        subscription.request(.max(self.maxRequest))
    }

    public func receive(_ input: Input) -> Subscribers.Demand {
        log?("LoggingSubscriber.receive.input: \(input)")
        self.subscriberState.maxCount -= 1
        let demandCount = max(0, min(self.subscriberState.maxCount, self.maxRequest))
        return .max(demandCount)
    }

    public func receive(completion: Subscribers.Completion<Upstream.Failure>) {
        log?("LoggingSubscriber.receive.completion: \(completion)")
        self.subscriberState.isComplete = true
    }

    private final class SubscriberState {
        fileprivate var maxCount = Int.max
        fileprivate var hasSubscribed = false
        fileprivate var isComplete = false
    }
}

extension Publisher {
    public func logger(maxCount: Int = Int.max, maxRequest: Int = 1, logger: ((String) -> Void)? = { Swift.print($0) }) -> LoggingSubscriber<Self> {
        return LoggingSubscriber(self, maxCount: maxCount, maxRequest: maxRequest, logger: logger)
    }
}
