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
    private var representedPhotoID: Int?

    override func prepareForReuse() {
        super.prepareForReuse()

        disposeBag = DisposeBag()
        representedPhotoID = nil
        photoImageView.image = nil
        photographerLabel.text = nil
    }

    func configure(with photo: Photo, imageLoader: ImageLoading) {
        disposeBag = DisposeBag()
        representedPhotoID = photo.id
        photoImageView.image = nil
        photographerLabel.text = photo.photographer

        imageLoader.loadImage(urlString: photo.src.medium)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] data in
                    guard let self,
                          self.representedPhotoID == photo.id,
                          let data,
                          let image = UIImage(data: data) else {
                        return
                    }
                    self.photoImageView.image = image
                }
            )
            .disposed(by: disposeBag)
    }
}
