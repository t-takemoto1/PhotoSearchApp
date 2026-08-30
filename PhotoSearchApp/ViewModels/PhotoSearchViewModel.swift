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
    private let disposeBag = DisposeBag()
    
    init(apiClient: PexelsAPIClient) {
        self.apiClient = apiClient
    }

    func search(query: String) {
        apiClient.search(query: query)
            .subscribe(
                onSuccess: { response in
                    print("検索結果: \(response.photos.count)件")
                },
                onFailure: { error in
                    print("検索エラー: \(error.localizedDescription)")
                }
            )
            .disposed(by: disposeBag)
    }
}
