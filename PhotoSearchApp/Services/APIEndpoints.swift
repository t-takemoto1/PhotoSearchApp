//
//  APIEndpoints.swift
//  PhotoSearchApp
//
//  Created by takemoto on 2026/08/29.
//

import Foundation

enum APIEndpoints {
    static let searchPhotos = URL(string: "https://api.pexels.com/v1/search")!
    static let curatedPhotos = URL(string: "https://api.pexels.com/v1/curated")!
}
