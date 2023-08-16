//
//  NetworkClient.swift
//  
//
//  Created by Arsenii Kovalenko on 16.08.2023.
//

import Foundation

final class NetworkClient: NSObject, URLSessionDelegate {

    private lazy var session = URLSession(
        configuration: .ephemeral,
        delegate: self,
        delegateQueue: .main
    )

    func perform(with request: URLRequest, callback: @escaping (Data?, URLResponse?, Error?) -> Void) {
        session.dataTask(with: request, completionHandler: callback)
            .resume()
    }

    @objc func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard
            // Ignore insecure certificates
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            ["localhost", "127.0.0.1", "0.0.0.0"].contains(where: challenge.protectionSpace.host.contains),
            let serverTrust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)
    }
}
