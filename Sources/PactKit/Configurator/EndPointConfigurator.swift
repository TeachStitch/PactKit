//
//  EndPointConfigurator.swift
//  
//
//  Created by Arsenii Kovalenko on 16.08.2023.
//

import UIKit

final class EndpointConfigurator: UIViewController {

    private lazy var container = UIStackView(arrangedSubviews: [
        pathTextField,
        methodTextField,
        queryTextField,
        bodyTextView
    ])

    private lazy var pathTextField = UITextField()
    private lazy var methodTextField = UITextField()
    private lazy var queryTextField = UITextField()
    private lazy var bodyTextView = UITextView()

    private let callback: (MockedEndpoint) -> Void
    private var current: MockedEndpoint?

    init(data: MockedEndpoint? = nil, callback: @escaping (MockedEndpoint) -> Void) {
        self.current = data
        self.callback = callback

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSubviews()
        setupAutolayout()
        setupNavBarButtons()
    }

    private func setupNavBarButtons() {
        navigationItem.rightBarButtonItem = .init(
            image: .checkmark,
            style: .done,
            target: self,
            action: #selector(save)
        )
    }

    private func setupSubviews() {
        view.addSubview(container)

        view.backgroundColor = .lightGray

        container.axis = .vertical
        container.alignment = .fill
        container.distribution = .fill
        container.spacing = 16
        container.setCustomSpacing(32, after: queryTextField)
        container.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        container.isLayoutMarginsRelativeArrangement = true

        if let current = current {
            pathTextField.text = current.path
            methodTextField.text = current.method
            queryTextField.text = current.queryString
            bodyTextView.text = current.jsonString
        } else {
            pathTextField.placeholder = "PATH. e.x /v0/cms/widget/some-id"
            methodTextField.placeholder = "METHOD. e.x GET"
            queryTextField.placeholder = "QUERY. e.x type=slider&id=123"
            bodyTextView.text = "JSON"
        }
    }

    private func setupAutolayout() {
        container.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            container.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    @objc private func save() {
        guard
            let path = pathTextField.text, !path.isEmpty,
            let method = methodTextField.text?.uppercased(), !method.isEmpty
        else {
            return
        }

        let mock = MockedEndpoint(
            path: path,
            queryString: queryTextField.text,
            method: method,
            jsonString: bodyTextView.text
        )

        current = mock
        callback(mock)
    }

    
}

