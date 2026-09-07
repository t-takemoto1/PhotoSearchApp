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
    private let imageLoader: ImageLoading
    private var imageDisposeBag = DisposeBag()

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

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.text = "画像を読み込めませんでした"
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        label.accessibilityIdentifier = "imageErrorLabel"
        return label
    }()

    private let retryButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.bordered()
        configuration.title = "再試行"
        configuration.baseForegroundColor = .white
        configuration.cornerStyle = .medium
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 8,
            leading: 16,
            bottom: 8,
            trailing: 16
        )
        button.configuration = configuration
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.accessibilityIdentifier = "retryImageButton"
        return button
    }()

    init(photo: Photo, imageLoader: ImageLoading) {
        self.photo = photo
        self.imageLoader = imageLoader
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
        view.addSubview(errorLabel)
        view.addSubview(retryButton)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -24),
            errorLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 32
            ),
            errorLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -32
            ),

            retryButton.topAnchor.constraint(
                equalTo: errorLabel.bottomAnchor,
                constant: 16
            ),
            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func setupActions() {
        closeButton.addTarget(
            self,
            action: #selector(closeButtonTapped),
            for: .touchUpInside
        )
        retryButton.addTarget(
            self,
            action: #selector(retryButtonTapped),
            for: .touchUpInside
        )
    }

    private func loadImage() {
        imageDisposeBag = DisposeBag()
        imageView.image = nil
        errorLabel.isHidden = true
        retryButton.isHidden = true

        imageLoader.loadImage(urlString: photo.src.large2x)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] data in
                    guard let data,
                          let image = UIImage(data: data) else {
                        self?.showImageLoadError()
                        return
                    }

                    self?.imageView.image = image
                },
                onFailure: { [weak self] _ in
                    self?.showImageLoadError()
                }
            )
            .disposed(by: imageDisposeBag)
    }

    private func showImageLoadError() {
        imageView.image = nil
        errorLabel.isHidden = false
        retryButton.isHidden = false
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func retryButtonTapped() {
        loadImage()
    }
}
