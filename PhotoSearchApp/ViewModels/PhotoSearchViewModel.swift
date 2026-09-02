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
    
    func searchNextPage() -> Single<[Photo]> {
        guard !currentQuery.isEmpty else {
            return Single.just([])
        }

        guard !isLoading else {
            return Single.just([])
        }

        isLoading = true
        currentPage += 1

        return apiClient.search(
            query: currentQuery,
            page: currentPage
        )
        .map { response in
            response.photos
        }
        .do(
            onSuccess: { [weak self] _ in
                self?.isLoading = false
            },
            onError: { [weak self] _ in
                self?.isLoading = false
            }
        )
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
