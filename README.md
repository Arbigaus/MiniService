# MiniService

This is a MiniService API to use in my projects.  
This project was created to learn about SPM Library, using the ***await/async***.  
It will be receiving improvements in future.

## How to use

To install the library, you need to use the SPM in Xcode, using the Github url from project:

```
https://github.com/Arbigaus/MiniService
```

First of all, set the `baseURL` by the code below, this can be set just one time:

```Swift
APIService.setBaseURL("https://url.com/")
````

After setting the **baseURL**, you can use the `APIService` class in your `Models`

### General Request: `makeRequest`

The `makeRequest` method combines the functionality of the `get`, `post`, and `put` methods into one, simplifying HTTP requests. You can specify the HTTP method, endpoint, and an optional payload.

#### Example:

```Swift
struct User: Codable {
    let id: Int
    let name: String
}

struct NewUser: Codable {
    let name: String
}

let service: APIServiceProtocol = APIService()

do {
    // Example of a POST request
    let newUser = NewUser(name: "John Doe")
    let createdUser: User = try await service.makeRequest(
        method: .post,
        endpoint: "users",
        payload: newUser
    )
    print("User created with ID: \(createdUser.id)")
    
    // Example of a GET request
    let fetchedUser: User = try await service.makeRequest(
        method: .get,
        endpoint: "users/\(createdUser.id)"
    )
    print("Fetched user: \(fetchedUser.name)")
    
} catch(let error) {
    print("An error occurred: \(error.localizedDescription)")
}

### Headers:

To pass `Headers` in the requests, you can use the method `insertHeader`, passing a dictionary as parameter.

```Swift
let headers: [String: String] = ["Content-Type": "application/json", "Authorization": "Bearer token"]

do {
    let newUser = NewUser(name: "John Doe")
    let createdUser: User = try await service
        .insertHeader(headers)
        .makeRequest(method: .post, endpoint: "users", payload: newUser)
    print("User created with ID: \(createdUser.id)")
} catch(let error) {
    print("An error occurred: \(error.localizedDescription)")
}
```
