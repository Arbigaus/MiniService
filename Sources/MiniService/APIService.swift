//
//  APIService.swift
//  
//
//  Created by Gerson Arbigaus on 03/07/23.
//

import Foundation

public protocol APIServiceProtocol {
    static func setBaseURL(_ baseUrl: String)
    func insertHeader(_ headers: [String: String]?) -> APIServiceProtocol
    func get<ResponseType: Decodable>(endpoint: String) async throws -> ResponseType
    func post<ResponseType: Decodable, PayloadType: Encodable>(endpoint: String, payload: PayloadType) async throws -> ResponseType
    func put<ResponseType: Decodable, PayloadType: Encodable>(endpoint: String, payload: PayloadType) async throws -> ResponseType
    func makeRequest<ResponseType: Decodable, PayloadType: Encodable>(method: APIService.Method, endpoint: String, payload: PayloadType?) async throws -> ResponseType
    func makeRequest<ResponseType: Decodable>(method: Method, endpoint: String) async throws -> ResponseType
}

public final class APIService: APIServiceProtocol {
    // MARK: - Variables
    private static let baseUrlKey = "baseUrl"
    private var headers: [String: String]?
    var baseURL: String {
        return UserDefaults.standard.string(forKey: APIService.baseUrlKey) ?? ""
    }

    // MARK: - Intializers

    public init() {}

    public enum Method: String {
        case get    = "GET"
        case put    = "PUT"
        case post   = "POST"
        case delete = "DELETE"
    }

    // MARK: - Methods

    private func createURLRequest(_ endpoint: String, method: Method, body: Data? = nil) -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            fatalError("URL inválida.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }

    private func handleRequest<ResponseType: Decodable>(with data: Data, and response: URLResponse) throws -> ResponseType {
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            throw NSError(domain: "Response error", code: 2)
        }

        guard statusCode >= 200 && statusCode <= 204 else {
            throw NSError(domain: "Response error", code: statusCode)
        }

        let decodedData = try JSONDecoder().decode(ResponseType.self, from: data)
        return decodedData
    }

    /// Method to set the `baseURL` from your API
    /// - Parameter baseUrl: String with te base url: "https"//baseurl.com/api/
    public static func setBaseURL(_ baseUrl: String) {
        UserDefaults.standard.set(baseUrl, forKey: APIService.baseUrlKey)
    }

    /// Insert a header dictionary in the request
    /// - Parameter headers: The dictionary that will be the header in the request
    /// - Returns: Return the class itself. To be uses in the API callers.
    public func insertHeader(_ headers: [String: String]?) -> APIServiceProtocol {
        self.headers = headers
        return self
    }

    /// Executes an HTTP request using the specified HTTP method, endpoint and payload (body in the request).
    /// - Parameters:
    ///   - method: The HTTP method to use for the request (e.g., `.get`, `.post`, `.put`, `.delete`).
    ///   - endpoint: The relative endpoint of the API (e.g., "/users", "/products/1").
    ///   - payload: An optional payload of a type conforming to `Encodable`, which will be sent as the request body. Defaults to `nil`.
    /// - Returns: A decoded instance of the specified `ResponseType`, conforming to `Decodable`.
    /// - Throws: An error if the request fails, the server returns an invalid response, or decoding the response fails.
    /// - Note: This is the primary method for making API requests. It replaces the `get`, `post`, and `put` methods, which are now deprecated.
    ///
    /// # Example:
    /// ```swift
    /// struct User: Codable {
    ///     let id: Int
    ///     let name: String
    /// }
    ///
    /// struct NewUser: Codable {
    ///     let name: String
    /// }
    ///
    /// let apiService = APIService()
    /// APIService.setBaseURL("https://example.com/api")
    ///
    /// let newUser = NewUser(name: "John Doe")
    /// do {
    ///     let createdUser: User = try await apiService.makeRequest(
    ///         method: .post,
    ///         endpoint: "/users",
    ///         payload: newUser
    ///     )
    ///     print("User created with ID: \(createdUser.id)")
    /// } catch {
    ///     print("Failed to create user: \(error.localizedDescription)")
    /// }
    /// ```
    public func makeRequest<ResponseType: Decodable, PayloadType: Encodable>(method: Method, endpoint: String, payload: PayloadType) async throws -> ResponseType {
        do {
            let body = try JSONEncoder().encode(payload)
            let request = createURLRequest(endpoint, method: method, body: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            return try handleRequest(with: data, and: response)

        } catch(let error) {
            throw NSError(domain: error.localizedDescription, code: error._code)
        }
    }

    /// Executes an HTTP request using the specified HTTP method, endpoint, without payload (body in the request).
    /// - Parameters:
    ///   - method: The HTTP method to use for the request (e.g., `.get`, `.post`, `.put`, `.delete`).
    ///   - endpoint: The relative endpoint of the API (e.g., "/users", "/products/1").
    /// - Returns: A decoded instance of the specified `ResponseType`, conforming to `Decodable`.
    /// - Throws: An error if the request fails, the server returns an invalid response, or decoding the response fails.
    /// - Note: This is the primary method for making API requests. It replaces the `get`, `post`, and `put` methods, which are now deprecated.
    ///
    /// # Example:
    /// ```swift
    /// struct User: Codable {
    ///     let id: Int
    ///     let name: String
    /// }
    ///
    /// struct NewUser: Codable {
    ///     let name: String
    /// }
    ///
    /// let apiService = APIService()
    /// APIService.setBaseURL("https://example.com/api")
    ///
    /// let newUser = NewUser(name: "John Doe")
    /// do {
    ///     let createdUser: User = try await apiService.makeRequest(
    ///         method: .post,
    ///         endpoint: "/users",
    ///         payload: newUser
    ///     )
    ///     print("User created with ID: \(createdUser.id)")
    /// } catch {
    ///     print("Failed to create user: \(error.localizedDescription)")
    /// }
    /// ```
    public func makeRequest<ResponseType: Decodable>(method: Method, endpoint: String) async throws -> ResponseType {
        do {
            let request = createURLRequest(endpoint, method: method)
            let (data, response) = try await URLSession.shared.data(for: request)

            return try handleRequest(with: data, and: response)

        } catch(let error) {
            throw NSError(domain: error.localizedDescription, code: error._code)
        }
    }

    @available(*, deprecated, message: "This method is deprecated. Use `makeRequest()` instead.")
    public func get<ResponseType: Decodable>(endpoint: String) async throws -> ResponseType {
        do {
            let request = createURLRequest(endpoint, method: .get)
            let (data, response) = try await URLSession.shared.data(for: request)

            return try handleRequest(with: data, and: response)

        } catch(let error) {
            throw NSError(domain: error.localizedDescription, code: error._code)
        }
    }

    @available(*, deprecated, message: "This method is deprecated. Use `makeRequest()` instead.")
    public func post<ResponseType: Decodable, PayloadType: Encodable>(endpoint: String, payload: PayloadType) async throws -> ResponseType {
        do {
            let body = try JSONEncoder().encode(payload)
            let request = createURLRequest(endpoint, method: .post, body: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            return try handleRequest(with: data, and: response)

        } catch (let error) {
            throw NSError(domain: error.localizedDescription, code: error._code)
        }
    }

    @available(*, deprecated, message: "This method is deprecated. Use `makeRequest()` instead.")
    public func put<ResponseType: Decodable, PayloadType: Encodable>(endpoint: String, payload: PayloadType) async throws -> ResponseType {
        do {
            let body = try JSONEncoder().encode(payload)
            let request = createURLRequest(endpoint, method: .put, body: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            return try handleRequest(with: data, and: response)
        } catch (let error) {
            throw NSError(domain: error.localizedDescription, code: error._code)
        }
    }
}
