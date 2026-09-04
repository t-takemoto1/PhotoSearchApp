//
//  PhotoDetailViewController.swift
//  PhotoSearchApp
//
//  Created by takemoto on 2026/09/03.
//

import UIKit
import RxSwift

final class PhotoDetailViewController: UIViewController {

    private let photo: Photo
    private let asyncImage: AsyncImage
    private let disposeBag = DisposeBag()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("閉じる", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    init(photo: Photo, asyncImage: AsyncImage) {
        self.photo = photo
        self.asyncImage = asyncImage
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        setupLayout()
        setupActions()
        loadImage()
    }

    private func setupLayout() {
        view.addSubview(imageView)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func setupActions() {
        closeButton.addTarget(
            self,
            action: #selector(closeButtonTapped),
            for: .touchUpInside
        )
    }

    private func loadImage() {
        asyncImage.loadImage(urlString: photo.src.large2x)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] data in
                    guard let data else {
                        return
                    }

                    self?.imageView.image = UIImage(data: data)
                },
                onFailure: { error in
                    print(error)
                }
            )
            .disposed(by: disposeBag)
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}
