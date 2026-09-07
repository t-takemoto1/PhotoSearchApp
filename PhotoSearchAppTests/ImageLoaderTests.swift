//
//  ImageLoaderTests.swift
//  PhotoSearchAppTests
//

import Foundation
import RxSwift
import UIKit
import XCTest
@testable import PhotoSearchApp

@MainActor
final class ImageLoaderTests: XCTestCase {

    override func tearDown() {
        ImageURLProtocolStub.requestHandler = nil
        super.tearDown()
    }

    func testInvalidImageDataIsNotCached() {
        var requestCount = 0
        var requestCachePolicies: [URLRequest.CachePolicy] = []
        ImageURLProtocolStub.requestHandler = { request in
            requestCount += 1
            requestCachePolicies.append(request.cachePolicy)

            let data = requestCount == 1
                ? Data("not an image".utf8)
                : Self.validImageData

            return ImageURLProtocolStubResponse(
                response: Self.httpResponse(url: request.url!),
                data: data
            )
        }

        let loader = ImageLoader(session: Self.makeStubSession())
        let firstResult = result(of: loader.loadImage(urlString: Self.imageURL))

        guard case let .success(firstData) = firstResult else {
            return XCTFail("不正な画像データはnilとして返すこと")
        }
        XCTAssertNil(firstData)

        let secondResult = result(of: loader.loadImage(urlString: Self.imageURL))

        guard case let .success(secondData) = secondResult else {
            return XCTFail("2回目の画像取得が成功すること")
        }
        XCTAssertEqual(secondData, Self.validImageData)
        XCTAssertEqual(requestCount, 2)
        XCTAssertEqual(
            requestCachePolicies,
            [.reloadIgnoringLocalCacheData, .reloadIgnoringLocalCacheData]
        )
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
        configuration.urlCache = URLCache(
            memoryCapacity: 1_000_000,
            diskCapacity: 0,
            diskPath: nil
        )
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.protocolClasses = [ImageURLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    private static func httpResponse(url: URL) -> HTTPURLResponse {
        HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: [
                "Content-Type": "image/png",
                "Cache-Control": "max-age=3600"
            ]
        )!
    }

    private static let imageURL = "https://images.example.com/photo.png"

    private static let validImageData = Data(
        base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
    )!
}

private final class ImageURLProtocolStub: URLProtocol {

    static var requestHandler: ((URLRequest) -> ImageURLProtocolStubResponse)?

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
            cacheStoragePolicy: .allowed
        )
        client?.urlProtocol(self, didLoad: response.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private struct ImageURLProtocolStubResponse {
    let response: HTTPURLResponse
    let data: Data
}

private enum TestError: Error {
    case missingResult(file: StaticString, line: UInt)
    case noRequestHandler
}
