//
//  PexelsAPIClient.swift
//  PhotoSearchApp
//
//  Created by takemoto on 2026/08/30.
//

import Foundation
import RxSwift

final class PexelsAPIClient {
    
    private let apiKey: String

    init(apiKey: String) {
        guard let apiKey = Bundle.main.object(
            forInfoDictionaryKey: "PEXELS_API_KEY"
        ) as? String else {
            fatalError("PEXELS_API_KEY is not configured")
        }
        
        self.apiKey = apiKey
    }
    
    // 検索
    func search(query: String) -> Single<PexelsResponse> {
        var components = URLComponents(
            string: APIEndpoints.searchPhotosURL
        )
        
        components?.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "per_page", value: "20")
        ]
        
        guard let url = components?.url else {
            return Single.error(URLError(.badURL))
        }

        var request = URLRequest(url: url)
        
        request.setValue(
            apiKey,
            forHTTPHeaderField: "Authorization"
        )

        return Single.create { observer in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error {
                    observer(.failure(error))
                    return
                }

                guard let data else {
                    observer(.failure(URLError(.badServerResponse)))
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase

                    let response = try decoder.decode(
                        PexelsResponse.self,
                        from: data
                    )

                    observer(.success(response))
                } catch {
                    observer(.failure(error))
                }
            }

            task.resume()

            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    
}
