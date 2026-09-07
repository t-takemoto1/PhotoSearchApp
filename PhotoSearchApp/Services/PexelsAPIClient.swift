//
//  PexelsAPIClient.swift
//  PhotoSearchApp
//
//  Created by takemoto on 2026/08/30.
//

import Foundation
import RxSwift

protocol PexelsAPIClientProtocol {
    func search(query: String, page: Int) -> Single<PexelsResponse>
    func fetchCurated(page: Int) -> Single<PexelsResponse>
}

enum PexelsAPIClientError: LocalizedError, Equatable {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case server(statusCode: Int)
    case missingResponseData

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Pexels APIキーが設定されていません。"
        case .invalidURL:
            return "リクエストURLを作成できませんでした。"
        case .invalidResponse:
            return "サーバーから不正なレスポンスが返されました。"
        case let .server(statusCode):
            return "サーバーエラーが発生しました（HTTP \(statusCode)）。"
        case .missingResponseData:
            return "サーバーからデータを受け取れませんでした。"
        }
    }
}

final class PexelsAPIClient: PexelsAPIClientProtocol {

    private enum Constants {
        static let pageSize = 20
        static let apiKeyInfoPlistKey = "PEXELS_API_KEY"
    }

    private let apiKey: String?
    private let session: URLSession

    init(
        apiKey: String? = nil,
        session: URLSession = .shared,
        bundle: Bundle = .main
    ) {
        let configuredAPIKey = apiKey ?? bundle.object(
            forInfoDictionaryKey: Constants.apiKeyInfoPlistKey
        ) as? String

        self.apiKey = configuredAPIKey?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.session = session
    }

    func search(query: String, page: Int = 1) -> Single<PexelsResponse> {
        request(
            endpoint: APIEndpoints.searchPhotos,
            queryItems: [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "per_page", value: String(Constants.pageSize))
            ]
        )
    }

    func fetchCurated(page: Int = 1) -> Single<PexelsResponse> {
        request(
            endpoint: APIEndpoints.curatedPhotos,
            queryItems: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "per_page", value: String(Constants.pageSize))
            ]
        )
    }

    private func request(
        endpoint: URL,
        queryItems: [URLQueryItem]
    ) -> Single<PexelsResponse> {
        guard let apiKey, !apiKey.isEmpty, !apiKey.contains("$(") else {
            return .error(PexelsAPIClientError.missingAPIKey)
        }

        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            return .error(PexelsAPIClientError.invalidURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return Single.create { [session] observer in
            let task = session.dataTask(with: request) { data, response, error in
                if let error {
                    observer(.failure(error))
                    return
                }

                guard let response = response as? HTTPURLResponse else {
                    observer(.failure(PexelsAPIClientError.invalidResponse))
                    return
                }

                guard 200..<300 ~= response.statusCode else {
                    observer(
                        .failure(
                            PexelsAPIClientError.server(
                                statusCode: response.statusCode
                            )
                        )
                    )
                    return
                }

                guard let data else {
                    observer(.failure(PexelsAPIClientError.missingResponseData))
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    observer(.success(try decoder.decode(PexelsResponse.self, from: data)))
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
