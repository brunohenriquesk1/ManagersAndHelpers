//
//  NetworkManager.swift
//
//
//  Created by Bruno on 12/15/18.
//  Copyright © 2018 Bruno. All rights reserved.
//

import Foundation
import Alamofire

class NetworkManager: Codable {
    
    typealias completeClosure <T : Decodable> = (_ data: T?, _ error: Error?)->Void
    typealias uploadHandler <T: Decodable>    = (_ response:T?, _ error: Error? ) -> Void
    
    public static var shared = NetworkManager()
    
    private init() {}
    
    
    /// Decodes Data Object to JSON
    ///
    /// - Parameters:
    ///   - data: Data object from api
    ///   - completionHandler: decoded JSON or Error if JSONDecoder fails
    
    func decodeJSONFromData<T>(_ data:Data, completionHandler:@escaping completeClosure<T>){
        do{
            let json = try JSONDecoder().decode(T.self, from: data)
            DispatchQueue.main.async {
                completionHandler(json, nil)
            }
        }
        catch let err{
            completionHandler(nil, err)
        }
    }
    
    /// Makes a http request and returns a @escaping closure with decoded JSON or nil if any error occurs.
    ///
    /// - Parameters:
    ///   - api: valid api link in string.
    ///   - headers: neccesary headers to get api result
    ///   - completionHandler: decoded JSON or Error when the request is completed.
    
    func fetchData<T>(_ api:URL, headers: [String:String]?, completionHandler:@escaping completeClosure<T>){
        Alamofire.request(api, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON {
            response in
            
            guard let data = response.data, response.error == nil else {
                return completionHandler(nil, response.error)
            }
            self.decodeJSONFromData(data, completionHandler: { (result: T?, err) in
                guard let result = result, err == nil else {
                    return completionHandler(nil, err)
                }
                
                return completionHandler(result, nil)
                
            })
        }
    }
    
    func uploadData(_ api:URL, params: [String:String]?, file:Data ,uploadProgress: @escaping (Double) -> Void, completion: @escaping (String?, Error?) -> ()) {
        
        Alamofire.upload(multipartFormData: { (form) in
            form.append(file, withName: "file", fileName: "file.gif", mimeType: "image/gif")
        }, to: api, encodingCompletion: { encodingResult in
            switch encodingResult {
            case .success(let upload, _, _):
                upload.responseJSON { response in
                    completion(response.description, nil)
                }
                upload.uploadProgress { progress in
                    uploadProgress(progress.fractionCompleted)
                }
            case .failure(let encodingError):
                completion(nil, encodingError)
            }
        })
    }
}
