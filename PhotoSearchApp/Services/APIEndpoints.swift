//
//  APIEndpoints.swift
//  PhotoSearchApp
//
//  Created by takemoto on 2026/08/29.
//

enum APIEndpoints {
    static let baseURL = "https://api.pexels.com/v1/"
    
    static let getPhotosURL = "\(baseURL)photos/"
    static let searchPhotosURL = "\(baseURL)search"
    static let curatedURL = "\(baseURL)curated"
}
