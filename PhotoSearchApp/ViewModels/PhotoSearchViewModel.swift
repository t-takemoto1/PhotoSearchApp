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
    
    init(apiClient: PexelsAPIClient, asyncImage: AsyncImage) {
        self.apiClient = apiClient
        self.asyncImage = asyncImage
    }

    func search(query: String) -> Single<[Photo]> {
        return apiClient.search(query: query)
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
