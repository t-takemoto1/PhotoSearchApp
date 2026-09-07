//
//  PhotoSearchAppTests.swift
//  PhotoSearchAppTests
//

import Foundation
import RxSwift
import XCTest
@testable import PhotoSearchApp

@MainActor
final class PhotoSearchAppTests: XCTestCase {

    func testSearchTrimsQueryAndLoadsFirstPage() {
        let client = StubPexelsAPIClient()
        client.searchResponses[1] = makeResponse(
            page: 1,
            photos: [makePhoto(id: 1)],
            nextPage: "next"
        )
        let viewModel = makeViewModel(apiClient: client)

        let result = result(of: viewModel.search(query: "  cats  "))

        guard case let .success(photos) = result else {
            return XCTFail("検索に成功すること")
        }

        XCTAssertEqual(photos.map(\.id), [1])
        XCTAssertEqual(client.searchRequests, [SearchRequest(query: "cats", page: 1)])
    }

    func testPaginationResetsWhenSwitchingBetweenCuratedAndSearch() {
        let client = StubPexelsAPIClient()
        client.curatedResponses[1] = makeResponse(
            page: 1,
            photos: [makePhoto(id: 1)],
            nextPage: "curated-next"
        )
        client.curatedResponses[2] = makeResponse(
            page: 2,
            photos: [makePhoto(id: 2)],
            nextPage: nil
        )
        client.searchResponses[1] = makeResponse(
            page: 1,
            photos: [makePhoto(id: 3)],
            nextPage: "search-next"
        )
        client.searchResponses[2] = makeResponse(
            page: 2,
            photos: [makePhoto(id: 4)],
            nextPage: nil
        )
        let viewModel = makeViewModel(apiClient: client)

        _ = result(of: viewModel.fetchCurated())
        _ = result(of: viewModel.fetchNextPage())
        _ = result(of: viewModel.search(query: "mountain"))
        _ = result(of: viewModel.fetchNextPage())

        XCTAssertEqual(client.curatedPages, [1, 2])
        XCTAssertEqual(client.searchRequests, [
            SearchRequest(query: "mountain", page: 1),
            SearchRequest(query: "mountain", page: 2)
        ])
    }

    func testPaginationStopsWhenResponseHasNoNextPage() {
        let client = StubPexelsAPIClient()
        client.curatedResponses[1] = makeResponse(
            page: 1,
            photos: [makePhoto(id: 1)],
            nextPage: nil
        )
        let viewModel = makeViewModel(apiClient: client)

        _ = result(of: viewModel.fetchCurated())
        let nextPageResult = result(of: viewModel.fetchNextPage())

        guard case let .success(photos) = nextPageResult else {
            return XCTFail("次ページがない場合は空の成功を返すこと")
        }

        XCTAssertTrue(photos.isEmpty)
        XCTAssertEqual(client.curatedPages, [1])
    }

    func testEmptySearchShowsCuratedPhotos() {
        let client = StubPexelsAPIClient()
        client.curatedResponses[1] = makeResponse(
            page: 1,
            photos: [makePhoto(id: 10)],
            nextPage: nil
        )
        let viewModel = makeViewModel(apiClient: client)

        let result = result(of: viewModel.search(query: " \n "))

        guard case let .success(photos) = result else {
            return XCTFail("空の検索語はキュレーションを読み込むこと")
        }

        XCTAssertEqual(photos.map(\.id), [10])
        XCTAssertEqual(client.curatedPages, [1])
        XCTAssertTrue(client.searchRequests.isEmpty)
    }

    private func makeViewModel(
        apiClient: PexelsAPIClientProtocol
    ) -> PhotoSearchViewModel {
        PhotoSearchViewModel(
            apiClient: apiClient
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

        wait(for: [expectation], timeout: 1)
        return result ?? .failure(TestError.missingResult(file: file, line: line))
    }
}

private enum TestError: Error {
    case missingResult(file: StaticString, line: UInt)
    case missingStubResponse
}

private struct SearchRequest: Equatable {
    let query: String
    let page: Int
}

private final class StubPexelsAPIClient: PexelsAPIClientProtocol {

    var searchResponses: [Int: PexelsResponse] = [:]
    var curatedResponses: [Int: PexelsResponse] = [:]
    private(set) var searchRequests: [SearchRequest] = []
    private(set) var curatedPages: [Int] = []

    func search(query: String, page: Int) -> Single<PexelsResponse> {
        searchRequests.append(SearchRequest(query: query, page: page))
        guard let response = searchResponses[page] else {
            return .error(TestError.missingStubResponse)
        }
        return .just(response)
    }

    func fetchCurated(page: Int) -> Single<PexelsResponse> {
        curatedPages.append(page)
        guard let response = curatedResponses[page] else {
            return .error(TestError.missingStubResponse)
        }
        return .just(response)
    }
}

private func makeResponse(
    page: Int,
    photos: [Photo],
    nextPage: String?
) -> PexelsResponse {
    PexelsResponse(
        totalResults: photos.count,
        page: page,
        perPage: photos.count,
        photos: photos,
        nextPage: nextPage
    )
}

private func makePhoto(id: Int) -> Photo {
    Photo(
        id: id,
        width: 100,
        height: 100,
        url: "https://www.pexels.com/photo/\(id)",
        photographer: "Photographer \(id)",
        photographerUrl: "https://www.pexels.com/@photographer\(id)",
        photographerId: id,
        avgColor: "#FFFFFF",
        src: PhotoSource(
            original: "https://images.pexels.com/photos/\(id)/original.jpeg",
            large2x: "https://images.pexels.com/photos/\(id)/large2x.jpeg",
            large: "https://images.pexels.com/photos/\(id)/large.jpeg",
            medium: "https://images.pexels.com/photos/\(id)/medium.jpeg",
            small: "https://images.pexels.com/photos/\(id)/small.jpeg",
            portrait: "https://images.pexels.com/photos/\(id)/portrait.jpeg",
            landscape: "https://images.pexels.com/photos/\(id)/landscape.jpeg",
            tiny: "https://images.pexels.com/photos/\(id)/tiny.jpeg"
        ),
        liked: false,
        alt: "Photo \(id)"
    )
}
