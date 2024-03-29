import Combine
import CombineLab
import XCTest

final class CombineLabTests: XCTestCase {
    func testLoggingSubscriberLogsResults() {
        let expectedResult = """
            LoggingSubscriber.receive.subscription: 1...2
            LoggingSubscriber.receive.input: 1
            LoggingSubscriber.receive.input: 2
            LoggingSubscriber.receive.completion: finished
            """

        var actualResult = ""
        _ = (1...2).publisher
            .logger() {
                let prefix = actualResult.isEmpty ? "" : "\n"
                actualResult += prefix + $0
        }

        XCTAssertEqual(actualResult, expectedResult)
    }

    func testPreviousValueSubjectDelaysSentValues() {
        let expectedResult = [1, 2, 3]
        var actualResult: [Int]?

        let subject = PreviousValueSubject<Int>()
        let unusedButNeeded = subject
            .collect()
            .sink { actualResult = $0 }

        withExtendedLifetime(unusedButNeeded) {
            let testValues = expectedResult + [4]
            for value in testValues {
                subject.send(value)
            }
        }

        subject.send(completion: .finished)

        XCTAssertEqual(actualResult, expectedResult)
    }

    func testRandomPublisherProvidesRandomInts() {
        let expectedCount = 4
        let expectedRange = 1 ... 10
        var actualResult: [Int] = []

        _ = RandomPublisher(range: expectedRange, count: expectedCount)
            .sink { actualResult.append($0) }

        XCTAssertEqual(actualResult.count, expectedCount)
        for result in actualResult {
            XCTAssertTrue(expectedRange.contains(result))
        }
    }

    func testRandomPublisherProvidesRandomDoubles() {
        let expectedCount = 4
        let expectedRange = 1.0 ... 10.0
        var actualResult: [Double] = []

        _ = RandomPublisher(range: expectedRange, count: expectedCount)
            .sink { actualResult.append($0) }

        XCTAssertEqual(actualResult.count, expectedCount)
        for result in actualResult {
            XCTAssertTrue(expectedRange.contains(result))
        }
    }

    func testSquareOperatorSquaresInts() {
        let expectedResult = [1, 4, 9]
        var actualResult: [Int]?

        _ = (1...3).publisher
            .square()
            .collect()
            .sink { actualResult = $0 }

        XCTAssertEqual(actualResult, expectedResult)
    }

    func testSquareOperatorSquaresDoubles() {
        let expectedResult = [100.0, 400.0, 900.0]
        var actualResult: [Double]?

        _ = [10.0, 20.0, 30.0].publisher
            .square()
            .collect()
            .sink { actualResult = $0 }

        XCTAssertEqual(actualResult, expectedResult)
    }

    func testSubscribeToInfinteSeriesWithBackpressure() {
        let expectedResult = """
            LoggingSubscriber.receive.subscription: CollectByCount
            LoggingSubscriber.receive.input: [0, 1, 2]
            LoggingSubscriber.receive.input: [3, 4, 5]
            """

        var actualResult = ""
        let infiniteSeries = 0...
        _ = infiniteSeries.publisher
            .collect(3)
            .logger(maxCount: 2) {  // 2 => backpressure
                let prefix = actualResult.isEmpty ? "" : "\n"
                actualResult += prefix + $0
        }

        XCTAssertEqual(actualResult, expectedResult)
    }

    func testCurrentValueSubjectCompletesWhenInScope() {
        let expectedResult = [1, 2, 3]
        var actualResult: [Int]?
        var actualCompletion: Subscribers.Completion<Never>?
        weak var actualSubscription: AnyObject?

        let subject = CurrentValueSubject<Int, Never>(expectedResult.first!)
        let unusedButNeeded = subject
            .collect(expectedResult.count)
            .breakpoint(receiveSubscription: { actualSubscription = $0 as AnyObject; return false })
            .sink(receiveCompletion: { actualCompletion = $0 }, receiveValue: { actualResult = $0 })

        withExtendedLifetime(unusedButNeeded) {
            let testValues = expectedResult.dropFirst()
            for value in testValues {
                subject.send(value)
            }
        }

        XCTAssertNotNil(actualSubscription)
        XCTAssertNil(actualCompletion)

        subject.send(completion: .finished)

        XCTAssertNil(actualSubscription)
        XCTAssertNotNil(actualCompletion)
        XCTAssertEqual(actualResult, expectedResult)
    }

    func testCurrentValueSubscriptionDeletedWhenOutOfScope() {
        let expectedResult = [1, 2, 3]
        var actualResult: [Int]?
        var actualCompletion: Subscribers.Completion<Never>?
        weak var actualSubscription: AnyObject?

        let subject = CurrentValueSubject<Int, Never>(expectedResult.first!)

        func sendTestValuesToSubject() {
            let unusedButNeeded = subject
                .collect(expectedResult.count)
                .breakpoint(receiveSubscription: { actualSubscription = $0 as AnyObject; return false })
                .sink(receiveCompletion: { actualCompletion = $0 }, receiveValue: { actualResult = $0 })

            withExtendedLifetime(unusedButNeeded) {
                let testValues = expectedResult.dropFirst()
                for value in testValues {
                    subject.send(value)
                }
            }
        }

        sendTestValuesToSubject()

        XCTAssertNil(actualSubscription)
        XCTAssertNil(actualCompletion)

        subject.send(completion: .finished)

        XCTAssertNil(actualSubscription)
        XCTAssertNil(actualCompletion)
        XCTAssertEqual(actualResult, expectedResult)
    }

    static var allTests = [
        ("testLoggingSubscriberLogsResults", testLoggingSubscriberLogsResults),
        ("testPreviousValueSubjectDelaysSentValues", testPreviousValueSubjectDelaysSentValues),
        ("testRandomPublisherProvidesRandomInts", testRandomPublisherProvidesRandomInts),
        ("testRandomPublisherProvidesRandomDoubles", testRandomPublisherProvidesRandomDoubles),
        ("testSquareOperatorSquaresInts", testSquareOperatorSquaresInts),
        ("testSquareOperatorSquaresDoubles", testSquareOperatorSquaresDoubles),
        ("testSubscribeToInfinteSeriesWithBackpressure", testSubscribeToInfinteSeriesWithBackpressure),
        ("testCurrentValueSubjectCompletesWhenInScope", testCurrentValueSubjectCompletesWhenInScope),
        ("testCurrentValueSubscriptionDeletedWhenOutOfScope", testCurrentValueSubscriptionDeletedWhenOutOfScope),
    ]
}
