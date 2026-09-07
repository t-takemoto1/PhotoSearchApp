//
//  PexelsAPIClientTests.swift
//  PhotoSearchAppTests
//

import Foundation
import RxSwift
import XCTest
@testable import PhotoSearchApp

@MainActor
final class PexelsAPIClientTests: XCTestCase {

    override func tearDown() {
        URLProtocolStub.requestHandler = nil
        super.tearDown()
    }

    func testSearchBuildsRequestAndDecodesResponse() {
        var receivedRequest: URLRequest?
        URLProtocolStub.requestHandler = { request in
            receivedRequest = request
            return Self.httpResponse(statusCode: 200, url: request.url!)
                .withData(Self.responseData)
        }

        let client = PexelsAPIClient(
            apiKey: "test-api-key",
            session: Self.makeStubSession()
        )
        let result = result(of: client.search(query: "cats", page: 2))

        guard case let .success(response) = result else {
            return XCTFail("APIレスポンスをデコードできること")
        }

        XCTAssertEqual(response.page, 1)
        XCTAssertEqual(response.photos.map(\.id), [123])
        XCTAssertEqual(receivedRequest?.httpMethod, "GET")
        XCTAssertEqual(
            receivedRequest?.value(forHTTPHeaderField: "Authorization"),
            "test-api-key"
        )

        let queryItems = URLComponents(
            url: receivedRequest!.url!,
            resolvingAgainstBaseURL: false
        )?.queryItems
        XCTAssertEqual(queryItems?.first(where: { $0.name == "query" })?.value, "cats")
        XCTAssertEqual(queryItems?.first(where: { $0.name == "page" })?.value, "2")
        XCTAssertEqual(queryItems?.first(where: { $0.name == "per_page" })?.value, "20")
    }

    func testServerErrorIncludesHTTPStatusCode() {
        URLProtocolStub.requestHandler = { request in
            Self.httpResponse(statusCode: 429, url: request.url!)
                .withData(Data())
        }

        let client = PexelsAPIClient(
            apiKey: "test-api-key",
            session: Self.makeStubSession()
        )
        let result = result(of: client.fetchCurated(page: 1))

        guard case let .failure(error) = result else {
            return XCTFail("HTTPエラーを失敗として返すこと")
        }

        XCTAssertEqual(error as? PexelsAPIClientError, .server(statusCode: 429))
    }

    func testMissingAPIKeyFailsWithoutStartingARequest() {
        var requestStarted = false
        URLProtocolStub.requestHandler = { request in
            requestStarted = true
            return Self.httpResponse(statusCode: 200, url: request.url!)
                .withData(Self.responseData)
        }

        let client = PexelsAPIClient(
            apiKey: "",
            session: Self.makeStubSession()
        )
        let result = result(of: client.fetchCurated())

        guard case let .failure(error) = result else {
            return XCTFail("APIキー未設定を失敗として返すこと")
        }

        XCTAssertEqual(error as? PexelsAPIClientError, .missingAPIKey)
        XCTAssertFalse(requestStarted)
    }

    private func result<T>(
        of single: Single<T>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Result<T, Error> {
        let expectation = expectation(description: "Single completes")
        var result: Result<T, Error>?
        let disposeBag = DisposeBag()

        single.subscribe(
            onSuccess: {
                result = .success($0)
                expectation.fulfill()
            },
            onFailure: {
                result = .failure($0)
                expectation.fulfill()
            }
        )
        .disposed(by: disposeBag)

        wait(for: [expectation], timeout: 2)
        return result ?? .failure(TestError.missingResult(file: file, line: line))
    }

    private static func makeStubSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    private static let responseData = Data(
        """
        {
          "total_results": 1,
          "page": 1,
          "per_page": 20,
          "photos": [
            {
              "id": 123,
              "width": 100,
              "height": 100,
              "url": "https://www.pexels.com/photo/123",
              "photographer": "Test Photographer",
              "photographer_url": "https://www.pexels.com/@test",
              "photographer_id": 456,
              "avg_color": "#FFFFFF",
              "src": {
                "original": "https://images.pexels.com/123/original.jpeg",
                "large2x": "https://images.pexels.com/123/large2x.jpeg",
                "large": "https://images.pexels.com/123/large.jpeg",
                "medium": "https://images.pexels.com/123/medium.jpeg",
                "small": "https://images.pexels.com/123/small.jpeg",
                "portrait": "https://images.pexels.com/123/portrait.jpeg",
                "landscape": "https://images.pexels.com/123/landscape.jpeg",
                "tiny": "https://images.pexels.com/123/tiny.jpeg"
              },
              "liked": false,
              "alt": "A test photo"
            }
          ],
          "next_page": "https://api.pexels.com/v1/search?page=2"
        }
        """.utf8
    )

    private static func httpResponse(
        statusCode: Int,
        url: URL
    ) -> HTTPURLResponse {
        HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
    }
}

private final class URLProtocolStub: URLProtocol {

    static var requestHandler: ((URLRequest) -> URLProtocolStubResponse)?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: TestError.noRequestHandler)
            return
        }

        let response = requestHandler(request)
        client?.urlProtocol(
            self,
            didReceive: response.response,
            cacheStoragePolicy: .notAllowed
        )
        client?.urlProtocol(self, didLoad: response.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private struct URLProtocolStubResponse {
    let response: HTTPURLResponse
    let data: Data

    func withData(_ data: Data) -> URLProtocolStubResponse {
        URLProtocolStubResponse(response: response, data: data)
    }
}

private extension HTTPURLResponse {

    func withData(_ data: Data) -> URLProtocolStubResponse {
        URLProtocolStubResponse(response: self, data: data)
    }
}

private enum TestError: Error {
    case missingResult(file: StaticString, line: UInt)
    case noRequestHandler
}
