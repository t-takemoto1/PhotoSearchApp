//
//  PhotoSearchViewModel.swift
//  PhotoSearchApp
//
//  Created by takemoto on 2026/08/30.
//

import Foundation
import RxSwift

final class PhotoSearchViewModel {

    private enum SearchMode {
        case curated
        case query(String)
    }

    private let apiClient: PexelsAPIClientProtocol
    private var searchMode: SearchMode = .curated
    private var currentPage = 0
    private var hasNextPage = true
    private var isLoading = false

    init(apiClient: PexelsAPIClientProtocol) {
        self.apiClient = apiClient
    }

    func search(query: String) -> Single<[Photo]> {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedQuery.isEmpty else {
            return fetchCurated()
        }

        return loadFirstPage(for: .query(normalizedQuery))
    }

    func fetchNextPage() -> Single<[Photo]> {
        guard currentPage > 0, !isLoading, hasNextPage else {
            return Single.just([])
        }

        let nextPage = currentPage + 1
        return load(page: nextPage, for: searchMode)
    }

    func fetchCurated() -> Single<[Photo]> {
        loadFirstPage(for: .curated)
    }

    private func loadFirstPage(for mode: SearchMode) -> Single<[Photo]> {
        searchMode = mode
        currentPage = 0
        hasNextPage = true
        return load(page: 1, for: mode)
    }

    private func load(page: Int, for mode: SearchMode) -> Single<[Photo]> {
        isLoading = true

        let request: Single<PexelsResponse>
        switch mode {
        case .curated:
            request = apiClient.fetchCurated(page: page)
        case let .query(query):
            request = apiClient.search(query: query, page: page)
        }

        return request
            .do(
                onSuccess: { [weak self] response in
                    guard let self else { return }
                    self.currentPage = response.page
                    self.hasNextPage = response.nextPage != nil
                },
                onDispose: { [weak self] in
                    self?.isLoading = false
                }
            )
            .map(\.photos)
    }
}
