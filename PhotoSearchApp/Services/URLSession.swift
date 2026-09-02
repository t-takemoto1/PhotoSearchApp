//
//  URLSession.swift
//  PhotoSearchApp
//
//  Created by takemoto on 2026/09/01.
//

import Foundation
import RxSwift

final class AsyncImage {

    private let cache = NSCache<NSString, NSData>()

    func loadImage(urlString: String) -> Single<Data?> {
        return Single.create { [weak self] observer in

            guard let self else {
                observer(.success(nil))
                return Disposables.create()
            }

            if let cachedData = self.cache.object(
                forKey: urlString as NSString
            ) {
                observer(.success(cachedData as Data))
                return Disposables.create()
            }

            guard let url = URL(string: urlString) else {
                observer(.failure(URLError(.badURL)))
                return Disposables.create()
            }

            let request = URLRequest(
                url: url,
                cachePolicy: .returnCacheDataElseLoad
            )

            let task = URLSession.shared.dataTask(with: request) {
                [weak self] data, _, error in

                if let error {
                    observer(.failure(error))
                    return
                }

                guard let data else {
                    observer(.success(nil))
                    return
                }

                self?.cache.setObject(
                    data as NSData,
                    forKey: urlString as NSString
                )

                observer(.success(data))
            }

            task.resume()

            return Disposables.create {
                task.cancel()
            }
        }
    }
}
