//
//  File.swift
//  
//
//  Created by Gerson Arbigaus on 03/07/23.
//

import Foundation

final class URLProtocolMock: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    static func startInterceptingRequests() {
        URLProtocol.registerClass(URLProtocolMock.self)
    }

    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(URLProtocolMock.self)
    }

    override func startLoading() {
        guard let handler = URLProtocolMock.requestHandler else {
            fatalError("Undefined handler")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

