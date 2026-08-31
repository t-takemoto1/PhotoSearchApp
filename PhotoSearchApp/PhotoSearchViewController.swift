//
//  PhotoSearchViewController.swift
//  PhotoSearchApp
//
//  Created by takemoto on 2026/08/29.
//

import UIKit

class PhotoSearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var searchTextField: UITextField!
    
    private let viewModel: PhotoSearchViewModel
    
    init() {
        let apiClient = PexelsAPIClient()
        self.viewModel = PhotoSearchViewModel(apiClient: apiClient)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        let apiClient = PexelsAPIClient()
        self.viewModel = PhotoSearchViewModel(apiClient: apiClient)
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func searchButtonTapped(_ sender: Any) {
        guard let query = searchTextField.text,
              !query.isEmpty else {
            return
        }

        viewModel.search(query: query)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "Row \(indexPath.row)"
        return cell
    }
}

