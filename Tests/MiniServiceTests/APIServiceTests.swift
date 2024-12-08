//
//  APIServiceTests.swift
//  
//
//  Created by Gerson Arbigaus on 03/07/23.
//

import XCTest
@testable import MiniService

final class APIServiceTests: XCTestCase {

    struct FakeResponseType: Decodable, Equatable {
        let id: Int
        let title: String
    }

    struct FakePayloadType: Encodable, Equatable {
        let id: Int
        let title: String
    }

    private enum FakeResult {
        case success([FakeResponseType])
        case failure(NSError)
    }

    private enum RequestMethod: CaseIterable {
        case get, post, put
    }

    override class func setUp() {
        super.setUp()
        URLProtocolMock.startInterceptingRequests()
    }

    override class func tearDown() {
        URLProtocolMock.stopInterceptingRequests()
        super.tearDown()
    }

    func test_getFromURL_succeddsWithDataAndResponse200() async {
        let (_, data) = makePayload()
        let expectedObject = makeFakeResponseObject()
        let response = makeResponse()

        await expect(wit: response,data: data, endpoint: "success200Response", expectedResult: .success([expectedObject]))
    }

    func test_getFromURL_failsOnRequestWithIncorrectData() async {
        let response = makeResponse()
        do {
            let _ = try JSONDecoder().decode(FakeResponseType.self, from: Data())
            XCTFail("Should do error")
        }
        catch(let expectedError as NSError) {
            await expect(wit: response, endpoint: "incorrectData", expectedResult: .failure(expectedError))
        }
    }

    func test_allMethods_deliversErrorOnNon200HttpResponse() async {
        let samples = [199, 300, 400, 500]

        for sample in samples {
            for method in RequestMethod.allCases {
                let response = makeResponse(sample)
                let expectedError: FakeResult = .failure(NSError(domain: "Response error", code: sample))

                await expect(wit: response, endpoint: "non200Errors", expectedResult: expectedError, method: method)
            }
        }
    }

    func test_allMethods_deliversErrorOnNon200HttpResponseUsingMakeRequest() async {
        let samples = [199, 300, 400, 500]

        for sample in samples {
            for method in RequestMethod.allCases {
                let response = makeResponse(sample)
                let expectedError: FakeResult = .failure(NSError(domain: "Response error", code: sample))

                await expect(wit: response, endpoint: "non200Errors", expectedResult: expectedError, method: method, makeRequest: true)
            }
        }
    }

    func test_postToURL_succeddsWithDataAndResponse200() async {
        let (_, jsonData) = makePayload()
        let expectedObject = makeFakeResponseObject()
        let response = makeResponse()

        await expect(wit: response,
                     data: jsonData,
                     endpoint: "postTest",
                     expectedResult: .success([expectedObject]),
                     method: .post)
    }

    func test_postToURL_succeddsWithDataAndResponse200UsingMakeRequest() async {
        let (_, jsonData) = makePayload()
        let expectedObject = makeFakeResponseObject()
        let response = makeResponse()

        await expect(wit: response,
                     data: jsonData,
                     endpoint: "postTest",
                     expectedResult: .success([expectedObject]),
                     method: .post,
                     makeRequest: true)
    }

    func test_putToURL_succeddsWithDataAndResponse200() async {
        let (_, jsonData) = makePayload()
        let expectedObject = makeFakeResponseObject()
        let response = makeResponse()

        await expect(wit: response,
                     data: jsonData,
                     endpoint: "putTest",
                     expectedResult: .success([expectedObject]),
                     method: .put)
    }

    func test_requestHeaders() async {
        let expectedHeaders: [String: String] = ["Content-Type": "application/json", "Authorization": "Bearer token"]

        URLProtocolMock.requestHandler = { request in
            let response = self.makeResponse()
            return (response!, Data())
        }

        let payload = FakePayloadType(id: 1, title: "Some Title")
        _ = await makePostFromSUT(with: "postTest", payload: payload, headers: expectedHeaders)

        guard let lastRequest = URLProtocolMock.headers else {
            XCTFail("Expected a request to be made")
            return
        }
        expectedHeaders.forEach { key, value in
            XCTAssertEqual(lastRequest[key], value, "Expected value for header \(key) to be \(value)")
        }
    }

    private func expect(wit response: HTTPURLResponse?,
                        data: Data? = nil,
                        endpoint: String,
                        expectedResult: FakeResult,
                        method: RequestMethod = .get,
                        makeRequest: Bool = false,
                        payload: FakePayloadType? = nil,
                        file: StaticString = #filePath,
                        line: UInt = #line) async {
        URLProtocolMock.requestHandler = { request in
            return (response!, data)
        }
        let receivedResult: FakeResult
        if makeRequest {
            receivedResult = await makeReceiveResultUsingMakeRequest(from: method, in: endpoint, with: payload)
        } else {
            receivedResult = await makeReceivedResult(from: method, in: endpoint, with: payload)
        }

        switch (receivedResult, expectedResult) {

        case let (.success(receivedItems), .success(expectedItems)):
            XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)

        case let (.failure(receivedError), .failure(expectedError)):
            XCTAssertEqual(receivedError.code, expectedError.code, file: file, line: line)

        default:
            XCTFail("Exptected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)

        }
    }

    private func makeReceiveResultUsingMakeRequest(from method: RequestMethod, in endpoint: String, with payload: FakePayloadType?, headers: [String: String]? = nil) async -> FakeResult {
        let apiMethod = getApiMethod(from: method)

        let (optionalPayload, data) = makePayload()
        do  {
            let result: FakeResponseType = try await makeSUT()
                .insertHeader(headers)
                .makeRequest(method: apiMethod, endpoint: endpoint, payload: payload)

            return .success([result])
        } catch (let error as NSError) {
            return .failure(error)
        }
    }

    private func makeReceivedResult(from method: RequestMethod, in endpoint: String, with payload: FakePayloadType?) async -> FakeResult {
        switch method {
        case .get:
            return await makeGetFromSUT(with: endpoint)
        case .post:
            return await makePostFromSUT(with: endpoint, payload: payload)
        case .put:
            return await makePostFromSUT(with: endpoint, payload: payload)
        }
    }

    private func makeGetFromSUT(with endpoint: String, headers: [String: String]? = nil) async -> FakeResult {
        do {
            let result: FakeResponseType = try await makeSUT()
                .insertHeader(headers)
                .get(endpoint: endpoint)

            return .success([result])
        } catch (let error as NSError) {
            return .failure(error)
        }
    }

    private func makePostFromSUT(with endpoint: String, payload: FakePayloadType?, headers: [String: String]? = nil) async -> FakeResult {
        let (optionalPayload, _) = makePayload()
        do {
            let result: FakeResponseType = try await makeSUT()
                .insertHeader(headers)
                .post(endpoint: "postTest", payload: payload ?? optionalPayload)

            return .success([result])
        } catch (let error as NSError) {
            return .failure(error)
        }
    }

    private func makePutFromSUT(with endpoint: String, payload: FakePayloadType?, headers: [String: String]? = nil) async -> FakeResult {
        let (optionalPayload, _) = makePayload()
        do {
            let result: FakeResponseType = try await makeSUT()
                .insertHeader(headers)
                .put(endpoint: "postTest", payload: payload ?? optionalPayload)

            return .success([result])
        } catch (let error as NSError) {
            return .failure(error)
        }
    }

    private func makeResponse(_ code: Int = .random(in: 200...204)) -> HTTPURLResponse? {
        HTTPURLResponse(url: anyURL(), statusCode: code, httpVersion: nil, headerFields: nil)
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> APIServiceProtocol {
        let sut = APIService()
        APIService.setBaseURL(baseURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func baseURL() -> String {
        "https://someUrl.com/"
    }

    private func anyURL() -> URL {
        URL(string: baseURL())!
    }

    private func makePayload() -> (FakePayloadType, Data?) {
        let fakePayload = FakePayloadType(id: 1, title: "Some Title")
        let data = try? JSONEncoder().encode(fakePayload)
        return (fakePayload, data)
    }

    private func makeFakeResponseObject() -> FakeResponseType {
        let (fakePayload, _) = makePayload()
        let fakeObject = FakeResponseType(id: fakePayload.id, title: fakePayload.title)

        return fakeObject
    }

    private func getApiMethod(from method: RequestMethod) -> APIService.Method {
        switch method {
        case .get:
            return .get
        case .post:
            return .post
        case .put:
            return .put
        }
    }
}

