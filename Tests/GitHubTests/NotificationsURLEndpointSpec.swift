import Quick
import Nimble
import Difference
@testable import GitHub
import Combine
import Foundation

class NotificationsURLEndpointSpec: QuickSpec {
    override func spec() {
        var endpoint: Notifications.Endpoint!
        var didURLRequest: [URLRequest]!
        var urlResponseSubject: PassthroughSubject<(data: Data, response: URLResponse), Error>!

        beforeEach {
            didURLRequest = []
            urlResponseSubject = PassthroughSubject()
            endpoint = Notifications.urlEndpoint(publisherFactory: { request in
                didURLRequest.append(request)
                return urlResponseSubject.eraseToAnyPublisher()
            })
        }

        afterEach {
            endpoint = nil
            didURLRequest = nil
            urlResponseSubject = nil
        }

        context("request") {
            var request: Notifications.Request!
            var didReceiveResponse: [Notifications.Response]!
            var didCompleteWithSuccess: Bool?
            var didCompleteWithError: Error?
            var cancellables: Set<AnyCancellable>!

            beforeEach {
                request = Notifications.Request(
                    auth: Auth(username: "user", accessToken: "1234"),
                    all: true
                )
                didReceiveResponse = []
                cancellables = Set()

                endpoint(request)
                    .sink(receiveCompletion: { completion in
                        if case Subscribers.Completion<Error>.failure(let error) = completion {
                            didCompleteWithError = error
                        } else {
                            didCompleteWithSuccess = true
                        }
                    }, receiveValue: { response in
                        didReceiveResponse.append(response)
                    })
                    .store(in: &cancellables)
            }

            afterEach {
                didReceiveResponse = nil
                didCompleteWithSuccess = nil
                didCompleteWithError = nil
                cancellables = nil
            }

            it("should send correct URL request") {
                expect(didURLRequest).to(haveCount(1))
                expect(didURLRequest.first?.url?.absoluteString)
                    == "https://api.github.com/notifications?all=true"
                expect(didURLRequest.first?.httpMethod) == "GET"
                expect(didURLRequest.first?.value(forHTTPHeaderField: "Authorization"))
                    == "Basic \("user:1234".data(using: .utf8)!.base64EncodedString())"
                expect(didURLRequest.first?.cachePolicy) == .reloadIgnoringLocalAndRemoteCacheData
            }

            context("when correct URL response is received") {
                beforeEach {
                    let jsonString = "[\(Notification.fixtureJSON)]"
                    let data = jsonString.data(using: .utf8)!
                    let response = HTTPURLResponse(
                        url: URL(fileURLWithPath: "test"),
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                        )!
                    urlResponseSubject.send((data: data, response: response))
                    urlResponseSubject.send(completion: .finished)
                }

                it("should complete with response") {
                    expect(didReceiveResponse).to(haveCount(1))
                    expect(didReceiveResponse.first?.notifications).to(equalDiff([.fixture()]))
                    expect(didCompleteWithSuccess) == true
                    expect(didCompleteWithError).to(beNil())
                }
            }

            context("when network error occurs") {
                var error: NSError!

                beforeEach {
                    error = NSError(domain: "test", code: 1234, userInfo: nil)
                    urlResponseSubject.send(completion: .failure(error))
                }

                it("should complete with error") {
                    expect(didReceiveResponse).to(beEmpty())
                    expect(didCompleteWithError) === error
                }
            }

            context("when invalid URL response is received") {
                var data: Data!
                var response: URLResponse!

                beforeEach {
                    data = Data()
                    response = URLResponse()
                    urlResponseSubject.send((data: data, response: response))
                    urlResponseSubject.send(completion: .finished)
                }

                it("should complete with error") {
                    expect(didReceiveResponse).to(beEmpty())
                    expect(didCompleteWithError as? URLResponseError)
                        == URLResponseError(data: data, response: response)
                }
            }

            context("when invalid HTTP status code is received") {
                var data: Data!
                var response: HTTPURLResponse!

                beforeEach {
                    data = Data()
                    response = HTTPURLResponse(
                        url: URL(fileURLWithPath: "test"),
                        statusCode: 404,
                        httpVersion: nil,
                        headerFields: nil
                    )
                    urlResponseSubject.send((data: data, response: response))
                    urlResponseSubject.send(completion: .finished)
                }

                it("should complete with error") {
                    expect(didReceiveResponse).to(beEmpty())
                    expect(didCompleteWithError as? HTTPURLResponseError)
                        == HTTPURLResponseError(data: data, response: response)
                }
            }
        }
    }
}
