//
//  PhotoSearchViewController.swift
//  PhotoSearchApp
//
//  Created by takemoto on 2026/08/29.
//

import UIKit
import RxSwift

class PhotoSearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    private let viewModel: PhotoSearchViewModel
    private let asyncImage = AsyncImage()
    private let disposeBag = DisposeBag()
    private var photos: [Photo] = []
    
    init() {
        let apiClient = PexelsAPIClient()
        self.viewModel = PhotoSearchViewModel(apiClient: apiClient, asyncImage: asyncImage)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        let apiClient = PexelsAPIClient()
        self.viewModel = PhotoSearchViewModel(apiClient: apiClient, asyncImage: asyncImage)
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchUI()
        tableView.dataSource = self
        tableView.delegate = self

        fetchCurated()
    }

    private func setupSearchUI() {
        searchTextField.placeholder = "写真を検索"
        searchTextField.borderStyle = .none
        searchTextField.backgroundColor = .secondarySystemBackground
        searchTextField.layer.cornerRadius = 10

        let paddingView = UIView(
            frame: CGRect(x: 0, y: 0, width: 12, height: 1)
        )
        searchTextField.leftView = paddingView
        searchTextField.leftViewMode = .always

        var configuration = UIButton.Configuration.filled()
        configuration.title = "検索"
        configuration.cornerStyle = .medium
        searchButton.configuration = configuration

        searchTextField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        searchButton.heightAnchor.constraint(equalTo: searchTextField.heightAnchor).isActive = true
        searchButton.widthAnchor.constraint(equalToConstant: 72).isActive = true

        if let stackView = searchTextField.superview as? UIStackView {
            stackView.spacing = 12
        }
    }
    
    private func fetchCurated() {
        viewModel.fetchCurated()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] photos in
                    self?.photos = photos
                    self?.tableView.reloadData()
                },
                onFailure: { error in
                    print(error)
                }
            )
            .disposed(by: disposeBag)
    }
    
    @IBAction func searchButtonTapped(_ sender: Any) {
        guard let query = searchTextField.text,
              !query.isEmpty else {
            return
        }

        viewModel.search(query: query)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] photos in
                    guard let self else {
                        return
                    }

                    self.photos = photos
                    self.tableView.reloadData()

                    if photos.isEmpty {
                        let label = UILabel()
                        label.text = "写真が見つかりません"
                        label.textAlignment = .center
                        label.textColor = .secondaryLabel
                        self.tableView.backgroundView = label
                    } else {
                        self.tableView.backgroundView = nil
                    }
                },
                onFailure: { error in
                    print(error)
                }
            )
            .disposed(by: disposeBag)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoTableViewCell", for: indexPath) as! PhotoTableViewCell
        let photo = photos[indexPath.row]
        cell.configure(with: photo, asyncImage: asyncImage)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let photo = photos[indexPath.row]
        showFullScreenPhoto(photo)
    }

    private func showFullScreenPhoto(_ photo: Photo) {
        let viewController = PhotoDetailViewController(
            photo: photo,
            asyncImage: asyncImage
        )
        present(viewController, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height

        if offsetY > contentHeight - frameHeight - 200 {
            loadNextPage()
        }
    }
    
    private func loadNextPage() {
        viewModel.fetchNextPage()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] photos in
                    guard let self else {
                        return
                    }

                    self.photos.append(contentsOf: photos)
                    self.tableView.reloadData()
                },
                onFailure: { error in
                    print(error)
                }
            )
            .disposed(by: disposeBag)
    }
}
