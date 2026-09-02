//
//  Photos.swift
//  PhotoSearchApp
//
//  Created by takemoto on 2026/08/30.
//

import Foundation

struct Photo: Codable {
    let id: Int
    let width: Int
    let height: Int
    let url: String
    let photographer: String
    let photographerUrl: String
    let photographerId: Int
    let avgColor: String
    let src: PhotoSource
    let liked: Bool
    let alt: String
}

struct PhotoSource: Codable {
    let original: String
    let large2x: String
    let large: String
    let medium: String
    let small: String
    let portrait: String
    let landscape: String
    let tiny: String
}
