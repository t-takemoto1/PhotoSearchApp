//
//  ImageLoader.swift
//  PhotoSearchApp
//

import Foundation
import UIKit
import RxSwift

protocol ImageLoading {
    func loadImage(urlString: String) -> Single<Data?>
}

final class ImageLoader: ImageLoading {

    private let session: URLSession
    private let cache: NSCache<NSString, NSData>

    init(
        session: URLSession = .shared,
        cache: NSCache<NSString, NSData> = NSCache<NSString, NSData>()
    ) {
        self.session = session
        self.cache = cache
    }

    func loadImage(urlString: String) -> Single<Data?> {
        Single.deferred { [weak self] in
            guard let self else {
                return .just(nil)
            }

            if let cachedData = cache.object(forKey: urlString as NSString) {
                return .just(cachedData as Data)
            }

            guard let url = URL(string: urlString) else {
                return .error(URLError(.badURL))
            }

            let request = URLRequest(
                url: url,
                cachePolicy: .reloadIgnoringLocalCacheData
            )
            let session = self.session

            return Single.create { [weak self] observer in
                let task = session.dataTask(with: request) {
                    [weak self] data, response, error in

                    if let error {
                        observer(.failure(error))
                        return
                    }

                    guard let response = response as? HTTPURLResponse,
                          200..<300 ~= response.statusCode else {
                        observer(.failure(URLError(.badServerResponse)))
                        return
                    }

                    guard let data,
                          UIImage(data: data) != nil else {
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
}
