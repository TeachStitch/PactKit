//
//  Configurator.swift
//  
//
//  Created by Arsenii Kovalenko on 16.08.2023.
//

import UIKit

final class MockConfigurator: UIViewController {

    enum Section: Int {
        case main
    }

    private lazy var collectionView: UICollectionView = {
        var config = UICollectionLayoutListConfiguration(appearance: .grouped)
        config.trailingSwipeActionsConfigurationProvider = { [unowned self] indexPath in
            let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, actionPerformed in
                self.data.remove(at: indexPath.item)

                actionPerformed(true)
            }

            return .init(actions: [deleteAction])
        }

        let layout = UICollectionViewCompositionalLayout.list(using: config)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        return collectionView
    }()

    private lazy var dataSource = UICollectionViewDiffableDataSource<Section, MockedEndpoint>(
        collectionView: collectionView
    ) { [unowned self] collectionView, indexPath, item in

        return collectionView.dequeueConfiguredReusableCell(
            using: cellRegistration,
            for: indexPath,
            item: item
        )
    }

    private let callback: ([MockedEndpoint]) -> Void
    private let cellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, MockedEndpoint> = {
        .init { cell, _, item in
            var configuration = cell.defaultContentConfiguration()
            let options = UICellAccessory.OutlineDisclosureOptions(style: .header)
            let disclosureAccessory = UICellAccessory.outlineDisclosure(options: options)

            configuration.text = item.path
            configuration.secondaryText = "METHOD: \(item.method). QUERY: \(String(describing: item.queryString))"

            cell.contentConfiguration = configuration
            cell.accessories = [disclosureAccessory]
        }
    }()

    private var userDefaultsKey = "mock.compontent.responses"
    private var data = [MockedEndpoint]() {
        didSet {
            applySnapshot()
        }
    }

    init(callback: @escaping ([MockedEndpoint]) -> Void) {
        self.callback = callback

        if let data = UserDefaults.standard.object(forKey: userDefaultsKey) as? Data,
            let decoded = try? JSONDecoder().decode([MockedEndpoint].self, from: data) {
            self.data = decoded
        }

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        self.view = collectionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        collectionView.delegate = self
        applySnapshot()
        setupNavBarButton()
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, MockedEndpoint>()

        snapshot.appendSections([.main])
        snapshot.appendItems(data, toSection: .main)

        dataSource.apply(snapshot)
    }

    private func setupNavBarButton() {
        navigationItem.rightBarButtonItems = [
            .init(image: .add, style: .plain, target: self, action: #selector(add)),
            .init(image: .checkmark, style: .done, target: self, action: #selector(save))
        ]

        navigationItem.leftBarButtonItem = .init(
            title: "Close",
            style: .plain,
            target: self,
            action: #selector(close)
        )
    }

    @objc private func add() {
        let viewController = EndpointConfigurator { [unowned self] item in
            data.append(item)
            self.navigationController?.popViewController(animated: true)
        }

        navigationController?.pushViewController(viewController, animated: true)
    }

    @objc private func save() {
        let encoded = try? JSONEncoder().encode(data)

        UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        callback(data)
    }

    @objc private func close() {
        dismiss(animated: true)
    }
}

extension MockConfigurator: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let viewController = EndpointConfigurator(data: data[indexPath.item]) { [unowned self] item in
            data[indexPath.item] = item
            self.navigationController?.popViewController(animated: true)
        }

        navigationController?.pushViewController(viewController, animated: true)
    }
}

struct MockedEndpoint: Hashable, Codable {
    static func == (lhs: MockedEndpoint, rhs: MockedEndpoint) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    let path: String
    let queryString: String?
    let query: MockQuery
    let method: String
    let jsonString: String
    let data: AnyEncodable

    init(path: String, queryString: String?, method: String, jsonString: String) {
        self.path = path
        self.queryString = queryString
        self.query = Self.mapQuery(queryString)
        self.method = method
        self.jsonString = jsonString
        self.data = AnyEncodable(jsonString)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let jsonString = try container.decode(String.self, forKey: .jsonString)
        let queryString = try container.decodeIfPresent(String.self, forKey: .queryString)

        self.path = try container.decode(String.self, forKey: .path)
        self.method = try container.decode(String.self, forKey: .method)
        self.queryString = queryString
        self.jsonString = jsonString

        self.data = AnyEncodable(jsonString)
        self.query = Self.mapQuery(queryString)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
        hasher.combine(queryString)
        hasher.combine(jsonString)
        hasher.combine(method)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.path, forKey: .path)
        try container.encodeIfPresent(self.queryString, forKey: .queryString)
        try container.encode(self.method, forKey: .method)
        try container.encode(self.jsonString, forKey: .jsonString)
    }

    private static func mapQuery(_ queryString: String?) -> MockQuery {
        guard let queryString = queryString else { return [:] }

        let params = queryString
            .split(separator: "&")
            .map(String.init)

        return params.reduce(into: MockQuery()) { result, element in
            let splitted = element
                .split(separator: "=")
                .map(String.init)

            if splitted.count == 2 {
                result[splitted[0]] = [splitted[1]]
            }
        }
    }

    enum CodingKeys: CodingKey {
        case path
        case queryString
        case method
        case jsonString
    }
}

