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

### Get:

You will need a `Decodable` object that conforms with the `json` file that you will receive from the API.  

#### Example:

```Swift
struct MyObject: Decodable {
    let id: String
    let name: String
}
```

Then you can use the `get` method, it is recomended using the `do/catch` to handle errors.

```Swift
let service: APIServiceProtocol = APIService()

do {
    let myObject: MyObject = try await service.get(endpoint: "endpoint") 
    // Do what you need with your object.
} catch(let error) {
    // Handle with error
}
```

### Post:

To use the Post, besides the `Decodable` object to convert the API response into your Swift project, you will need a `Encodable` object to send to the API that you need.

#### Example:

```Swift
struct AnotherObject: Encodable {
    let name: String
}
```
Then you can use the `post` method, passing the object as a payload, like the `get` method, it is recomended using the `do/catch` to handle errors.

```Swift
let service: APIServiceProtocol = APIService()

do {
    let anotherObject = AnotherObject(name: "Some Name")
    let myObject: MyObject = try await service.post(endpoint: "endpoint", payload: accountToCreate) 
    // Do what you need with your object.
} catch(let error) {
    // Handle with error
}
```

### Put:

To use the `put` method, it is the same as the `post` method.

```Swift
let service: APIServiceProtocol = APIService()

do {
    let anotherObject = AnotherObject(name: "Some Name")
    let myObject: MyObject = try await service.put(endpoint: "endpoint", payload: accountToCreate) 
    // Do what you need with your object.
} catch(let error) {
    // Handle with error
}
