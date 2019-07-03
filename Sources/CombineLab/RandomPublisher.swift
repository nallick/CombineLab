//
//  RandomPublisher.swift
//

import Combine
import Foundation

public protocol RandomNumeric: Comparable, Numeric {
    static func random(in range: ClosedRange<Self>) -> Self
}

extension Int: RandomNumeric {}
extension Double: RandomNumeric {}


public struct RandomPublisher<Output>: Publisher where Output: RandomNumeric {
    public typealias Failure = Never

    public let range: ClosedRange<Output>
    public let count: Int

    public init(range: ClosedRange<Output>, count: Int = -1) {     // negative => infinite
        self.range = range
        self.count = count
    }

    public func receive<S>(subscriber: S) where Output == S.Input, Failure == S.Failure, S: Subscriber {
        subscriber.receive(subscription: RandomSubscription(subscriber: subscriber, range: self.range, count: self.count))
    }

    private final class RandomSubscription<S>: Subscription where Output == S.Input, Failure == S.Failure, S: Subscriber {
        private let range: ClosedRange<Output>
        private var count: Int
        private var subscriber: S?

        fileprivate init(subscriber: S, range: ClosedRange<Output>, count: Int) {
            self.subscriber = subscriber
            self.range = range
            self.count = count
        }

        fileprivate func request(_ demand: Subscribers.Demand) {
            if demand > .none, let subscriber = self.subscriber {
                if self.count < 0 {
                    self.scheduleRequest()
                } else {
                    let deliveryCount = Swift.min(self.count, demand.max ?? Int.max)
                    for _ in 0 ..< deliveryCount {
                        _ = subscriber.receive(Output.random(in: self.range))
                    }

                    self.count -= deliveryCount
                    if self.count == 0 {
                        subscriber.receive(completion: .finished)
                    }
                }
            }
        }

        fileprivate func cancel() {
            self.subscriber = nil   // TODO: thread safe?
        }

        private func scheduleRequest() {
            DispatchQueue.global().async {
                if let subscriber = self.subscriber {
                    _ = subscriber.receive(Output.random(in: self.range))
                    self.scheduleRequest()
                }
            }
        }
    }
}
