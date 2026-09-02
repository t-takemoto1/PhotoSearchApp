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
    @IBOutlet weak var tableView: UITableView!
    
    private let viewModel: PhotoSearchViewModel
    private let asyncImage = AsyncImage()
    private let disposeBag = DisposeBag()
    private var photos: [Photo] = []
    
    init() {
        let apiClient = PexelsAPIClient()
        let asyncImage = AsyncImage()
        self.viewModel = PhotoSearchViewModel(apiClient: apiClient, asyncImage: asyncImage)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        let apiClient = PexelsAPIClient()
        let asyncImage = AsyncImage()
        self.viewModel = PhotoSearchViewModel(apiClient: apiClient, asyncImage: asyncImage)
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self

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
                    self?.photos = photos
                    self?.tableView.reloadData()
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
}
