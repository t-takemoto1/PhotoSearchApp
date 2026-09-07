//
//  PhotoSearchViewController.swift
//  PhotoSearchApp
//
//  Created by takemoto on 2026/08/29.
//

import UIKit
import RxSwift

final class PhotoSearchViewController: UIViewController {

    @IBOutlet private weak var searchTextField: UITextField!
    @IBOutlet private weak var searchButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!

    private let viewModel: PhotoSearchViewModel
    private let imageLoader: ImageLoading
    private var requestDisposeBag = DisposeBag()
    private var photos: [Photo] = []

    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    init(viewModel: PhotoSearchViewModel, imageLoader: ImageLoading) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }

    convenience init() {
        let imageLoader = ImageLoader()
        let viewModel = PhotoSearchViewModel(
            apiClient: PexelsAPIClient()
        )
        self.init(viewModel: viewModel, imageLoader: imageLoader)
    }

    required init?(coder: NSCoder) {
        let imageLoader = ImageLoader()
        self.viewModel = PhotoSearchViewModel(
            apiClient: PexelsAPIClient()
        )
        self.imageLoader = imageLoader
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSearchUI()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.accessibilityIdentifier = "photoTableView"
        loadInitialPhotos(viewModel.fetchCurated())
    }

    private func setupSearchUI() {
        searchTextField.placeholder = "写真を検索"
        searchTextField.borderStyle = .none
        searchTextField.backgroundColor = .secondarySystemBackground
        searchTextField.layer.cornerRadius = 10
        searchTextField.delegate = self
        searchTextField.accessibilityIdentifier = "searchTextField"

        let paddingView = UIView(
            frame: CGRect(x: 0, y: 0, width: 12, height: 1)
        )
        searchTextField.leftView = paddingView
        searchTextField.leftViewMode = .always

        var configuration = UIButton.Configuration.filled()
        configuration.title = "検索"
        configuration.cornerStyle = .medium
        searchButton.configuration = configuration
        searchButton.accessibilityIdentifier = "searchButton"

        searchTextField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        searchButton.heightAnchor.constraint(equalTo: searchTextField.heightAnchor).isActive = true
        searchButton.widthAnchor.constraint(equalToConstant: 72).isActive = true

        if let stackView = searchTextField.superview as? UIStackView {
            stackView.spacing = 12
        }
    }

    private func loadInitialPhotos(_ request: Single<[Photo]>) {
        setSearchLoading(true)
        photos.removeAll()
        tableView.backgroundView = nil
        tableView.reloadData()

        request
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] photos in
                    guard let self else { return }
                    self.setSearchLoading(false)
                    self.photos = photos
                    self.updateEmptyState()
                    self.tableView.reloadData()
                },
                onFailure: { [weak self] error in
                    self?.setSearchLoading(false)
                    self?.handle(error: error)
                }
            )
            .disposed(by: requestDisposeBag)
    }

    @IBAction func searchButtonTapped(_ sender: Any) {
        search()
    }

    private func search() {
        searchTextField.resignFirstResponder()
        cancelCurrentRequest()
        loadInitialPhotos(viewModel.search(query: searchTextField.text ?? ""))
    }

    private func updateEmptyState() {
        if photos.isEmpty {
            emptyStateLabel.text = "写真が見つかりません"
            tableView.backgroundView = emptyStateLabel
        } else {
            tableView.backgroundView = nil
        }
    }

    private func setSearchLoading(_ isLoading: Bool) {
        searchButton.isEnabled = !isLoading
    }

    private func cancelCurrentRequest() {
        requestDisposeBag = DisposeBag()
    }

    private func handle(error: Error) {
        guard (error as? URLError)?.code != .cancelled else {
            return
        }

        showAlert(
            title: "通信エラー",
            message: error.localizedDescription
        )
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(title: "OK", style: .default)
        )

        present(alert, animated: true)
    }

    private func loadNextPage() {
        viewModel.fetchNextPage()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] nextPhotos in
                    guard let self, !nextPhotos.isEmpty else {
                        return
                    }

                    self.photos.append(contentsOf: nextPhotos)
                    self.tableView.reloadData()
                },
                onFailure: { [weak self] error in
                    self?.handle(error: error)
                }
            )
            .disposed(by: requestDisposeBag)
    }
}

extension PhotoSearchViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "PhotoTableViewCell",
            for: indexPath
        ) as? PhotoTableViewCell else {
            return UITableViewCell()
        }

        let photo = photos[indexPath.row]
        cell.configure(with: photo, imageLoader: imageLoader)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard photos.indices.contains(indexPath.row) else {
            return
        }

        let photo = photos[indexPath.row]
        showFullScreenPhoto(photo)
    }

    private func showFullScreenPhoto(_ photo: Photo) {
        let viewController = PhotoDetailViewController(
            photo: photo,
            imageLoader: imageLoader
        )
        present(viewController, animated: true)
    }
}

extension PhotoSearchViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height

        guard contentHeight > frameHeight,
              offsetY + frameHeight > contentHeight - 200 else {
            return
        }

        loadNextPage()
    }
}

extension PhotoSearchViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        search()
        return true
    }
}
