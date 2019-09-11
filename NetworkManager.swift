//
//  NetworkManager.swift
//  BitcoinTracker
//
//  Created by Bruno on 6/24/19.
//  Copyright © 2019 Bruno. All rights reserved.
//

import Foundation
import Alamofire

//TODO: - Separate in diferent files

// MARK: - Http Status code map

enum StatusCode: Int {
    case serverError = 500
    case noConnection = -1009
    case timeOutError = -1001
    case userNotFound = 302
    case noCode = 0
    
    // TODO: Map all the status from the api
    
    func description() -> String {
        switch self {
        case .noConnection: return "No connection with the Internet."
        case .serverError: return "Something went wrong with the server."
        case .timeOutError: return "Timedout."
        case .noCode: return "Error undefined." // look for custom description
        case .userNotFound: return "Please provide valid credentials."
        }
    }
}

// MARK: - Network Handlers

enum NetworkResponse<T: Decodable>: Error {
    case success(data: T?)
    case failure(error: Error?)
}

enum UploadResponse: Error {
    case success
    case failure(err: Error?)
    case progress(Double)
}

struct File {
    enum MimeType: String {
        case image = "img/png"
        case gif = "img/gif"
        case video = "..."
    }
    
    let data: Data?
    let name: String?
    let mimeType: MimeType
}

class NetworkManager {
    
    typealias ResponseHandler <T : Decodable> = (_ reponse: NetworkResponse<T>) -> Void
    typealias UploadHandler = (UploadResponse) -> ()
    typealias Headers = [String: String]
    
    public static var shared = NetworkManager()
    
    private init() {}
    
    /// Makes a http request and returns a @escaping closure with decoded JSON or failure response if any error occurs.
    ///
    /// - Parameters:
    ///   - api: valid api link in string.
    ///   - headers: neccesary headers to get api result
    ///   - completionHandler: returns success with decoded JSON or failure with a error when the request is completed.
    
    func fetchData<T>(_ api: URL, headers: Headers?, completionHandler: @escaping ResponseHandler<T>){
        Alamofire.request(api, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON {
            result in
            
            guard let data = result.data, result.error == nil else {
                let error = CustomError(code: StatusCode(rawValue: result.response?.statusCode ?? 0)!, customDescription: nil)
                
                return completionHandler(.failure(error: error))
            }
            do{
                let json = try JSONDecoder().decode(T.self, from: data)
                
                completionHandler(.success(data: json))
                
            } catch let err {
                let error = CustomError(code: .noCode, customDescription: err.localizedDescription)
                
                completionHandler(.failure(error: error))
            }
        }
    }
    
    /// Makes a http post request and returns a @escaping closure with upload progress and upload result
    ///
    /// - Parameters:
    ///   - api: valid URL.
    ///   - parameters: dictionary of string values
    //    - uploadProgress: download progress in double values
    ///   - completionHandler: success or failure response
    
    func uploadData(_ api: URL, params: Headers?, file: File, uploadProgress: @escaping UploadHandler, completion: @escaping UploadHandler) {
        Alamofire.upload(multipartFormData: { (form) in
            guard let name = file.name, let data = file.data else {
                let error = CustomError(code: .noCode, customDescription: "Invalid file attributes")
                return completion(.failure(err: error))
            }
            
            form.append(data, withName: name, fileName: name, mimeType: file.mimeType.rawValue)
            
        }, to: api, encodingCompletion: { encodingResult in
            switch encodingResult {
                
            case .success(let upload, _, _):
                upload.responseJSON { _ in
                    completion(.success)
                }
                
                upload.uploadProgress { progress in
                    uploadProgress(.progress(progress.fractionCompleted))
                }
                
            case .failure(let encodingError):
                completion(.failure(err: encodingError))
            }
        })
    }
}
