//
//  PhotoTableViewCell.swift
//  PhotoSearchApp
//
//  Created by takemoto on 2026/09/01.
//

import Foundation
import UIKit
import RxSwift

final class PhotoTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var photoImageView: UIImageView!
    @IBOutlet private weak var photographerLabel: UILabel!

    private var disposeBag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
        photoImageView.image = nil
        photographerLabel.text = nil
    }
    
    func configure(with photo: Photo, asyncImage: AsyncImage) {
        photoImageView.image = nil
        photographerLabel.text = photo.photographer

        asyncImage.loadImage(urlString: photo.src.medium)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] data in
                    guard let data else { return }
                    self?.photoImageView.image = UIImage(data: data)
                },
                onFailure: { error in
                    print(error)
                }
            )
            .disposed(by: disposeBag)
    }
}
