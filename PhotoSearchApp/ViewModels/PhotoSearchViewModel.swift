//
//  PhotoSearchViewModel.swift
//  PhotoSearchApp
//
//  Created by takemoto on 2026/08/30.
//

import Foundation
import RxSwift

final class PhotoSearchViewModel {
    
    private let apiClient: PexelsAPIClient
    private let asyncImage: AsyncImage
    private var currentPage = 1
    private var currentQuery = ""
    private var isLoading = false
    
    init(apiClient: PexelsAPIClient, asyncImage: AsyncImage) {
        self.apiClient = apiClient
        self.asyncImage = asyncImage
    }

    func search(query: String) -> Single<[Photo]> {
        currentPage = 1
        currentQuery = query
        
        return apiClient.search(query: query, page: currentPage)
            .map { response in
                response.photos
            }
    }
    
    func fetchNextPage() -> Single<[Photo]> {
        guard !isLoading else {
            return Single.just([])
        }

        isLoading = true
        let nextPage = currentPage + 1

        let request: Single<PexelsResponse>

        if currentQuery.isEmpty {
            // Curated表示中
            request = apiClient.fetchCurated(page: nextPage)
        } else {
            // 検索結果表示中
            request = apiClient.search(
                query: currentQuery,
                page: nextPage
            )
        }

        return request
            .do(
                onSuccess: { [weak self] response in
                    self?.currentPage = response.page
                    self?.isLoading = false
                },
                onError: { [weak self] _ in
                    self?.isLoading = false
                }
            )
            .map { response in
                response.photos
            }
    }
    
    func loadImage(for photo: Photo) -> Single<Data?> {
        return asyncImage.loadImage(urlString: photo.src.medium)
    }
    
    func fetchCurated() -> Single<[Photo]> {
        return apiClient.fetchCurated()
            .map { response in
                response.photos
            }
    }
}
