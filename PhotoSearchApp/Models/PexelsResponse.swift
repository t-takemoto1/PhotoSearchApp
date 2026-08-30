//
//  PexelsResponse.swift
//  PhotoSearchApp
//
//  Created by takemoto on 2026/08/30.
//

import Foundation

struct PexelsResponse: Codable {
    let totalResults: Int
    let page: Int
    let perPage: Int
    let photos: [Photo]
    let nextPage: String?
}
