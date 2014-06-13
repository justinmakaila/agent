//
//  Agent.swift
//  Agent
//
//  Created by Christoffer Hallas on 6/2/14.
//  Copyright (c) 2014 Christoffer Hallas. All rights reserved.
//

import Foundation

typealias RequestSuccessBlock = (NSHTTPURLResponse!, AnyObject!, NSError!) -> ()
typealias RequestFailureBlock = (NSHTTPURLResponse!, AnyObject!, NSError!) -> ()

class Agent {
    typealias Headers = Dictionary<String, String>
    typealias JSONDictionary = Dictionary<String, AnyObject>
    
    var request: NSMutableURLRequest
    let queue = NSOperationQueue()
    
    var requestSuccess: RequestSuccessBlock!
    var requestFailure: RequestFailureBlock!
    
    init() {
        self.request = NSMutableURLRequest()
    }
    
    init(method: String, url: String, headers: Headers?) {
        self.request = NSMutableURLRequest(URL: NSURL(string: url))
        self.request.HTTPMethod = method;
        self.setHeaders(headers)
    }
    
    /**
     *  GET
     */
    
    class func _constructQueryString(parameters: JSONDictionary?) -> String {
        var queryString = ""
        
        if parameters {
            var firstParameter = true
            for (key, value: AnyObject) in parameters! {
                if firstParameter {
                    queryString += "?\(key)=\(value)"
                    firstParameter = false
                }else {
                    queryString += "&\(key)=\(value)"
                }
            }
        }
        
        return queryString
    }
    
    class func get(url: String) -> Agent {
        return Agent.get(url, headers: nil)
    }
    
    class func get(url: String, headers: Headers?) -> Agent {
        return Agent.get(url, headers: headers, parameters: nil)
    }
    
    class func get(url: String, headers: Headers?, parameters: JSONDictionary?) -> Agent {
        return Agent.get(url, headers: headers, parameters: parameters, success: nil, failure: nil)
    }
    
    class func get(url: String, headers: Headers?, parameters: JSONDictionary?, success: RequestSuccessBlock?, failure: RequestFailureBlock?) -> Agent {
        var requestURL = url + self._constructQueryString(parameters)
        
        return Agent(method: "GET", url: requestURL, headers: headers)
            .setSuccess(success)
            .setFailure(failure)
            .run()
    }
    
    /**
     *  POST
     */
    class func post(url: String) -> Agent {
        return self.post(url, headers: nil)
    }
    
    class func post(url: String, headers: Headers?) -> Agent {
        return self.post(url, headers: headers, parameters: nil)
    }
    
    class func post(url: String, headers: Headers?, parameters: JSONDictionary?) -> Agent {
        return self.post(url, headers: headers, parameters: parameters, success: nil, failure: nil)
    }
    
    class func post(url: String, headers: Headers?, parameters: JSONDictionary?, success: RequestSuccessBlock?, failure: RequestFailureBlock?) -> Agent {
        return Agent(method: "POST", url: url, headers: headers)
            .setSuccess(success)
            .setFailure(failure)
            .sendJSON(parameters)
            .run()
    }
    
    /**
     *  PUT
     */
    class func put(url: String) -> Agent {
        return self.put(url, headers: nil)
    }
    
    class func put(url: String, headers: Headers?) -> Agent {
        return self.put(url, headers: headers, success: nil, failure: nil)
    }
    
    class func put(url: String, headers: Headers?, success: RequestSuccessBlock?, failure: RequestFailureBlock?) -> Agent {
        return Agent(method: "PUT", url: url, headers: headers)
            .setSuccess(success)
            .setFailure(failure)
            .run()
    }
    
    /**
     *  DELETE
     */
    class func delete(url: String) -> Agent {
        return self.delete(url, headers: nil)
    }
    
    class func delete(url: String, headers: Headers?) -> Agent {
        return self.delete(url, headers: headers, success: nil, failure: nil)
    }
    
    class func delete(url: String, headers: Headers?, success: RequestSuccessBlock?, failure: RequestFailureBlock?) -> Agent {
        return Agent(method: "DELETE", url: url, headers: headers)
            .setSuccess(success)
            .setFailure(failure)
            .run()
    }
    
    /**
     *  Instance Methods
     */
    func sendJSON(data: JSONDictionary?) -> Agent {
        var jsonData: NSData? = nil
        
        if data {
            var error: NSError?
            jsonData = NSJSONSerialization.dataWithJSONObject(data!, options: nil, error: &error)
        }
        
        return self.send(jsonData, contentType: "application/json")
    }
    
    /**
     *  Sets the content type header to `contentType`
     *  and sets data as the HTTP request body.
     *
     *  @param data The data to set as the request body.
     *  @param contentType The value to be set as the Content-Type header.
     */
    func send(data: NSData?, contentType: String?) -> Agent {
        if contentType {
            self.setHeader("Content-Type", value: contentType!)
        }
        
        if data {
            self.request.HTTPBody = data!
        }
        
        return self
    }
    
    /**
     *  Sets the request's HTTP header fields to
     *  the supplied Headers dictionary.
     *  
     *  @discussion Using this method to set the headers
     *  will clear any existing headers.
     *
     *  @param headers a Dictionary<String, String> of HTTP
     *  headers for the pending request.
     */
    func setHeaders(headers: Headers?) -> Agent {
        if headers {
            self.request.allHTTPHeaderFields = headers!
        }
        
        return self
    }
    
    /**
     *  Sets value for key header in the HTTP header
     *  fields.
     *
     *  @param header A string for the HTTP header key
     *  @param value A string for the HTTP header value
     */
    func setHeader(header: String, value: String) -> Agent {
        self.request.setValue(value, forHTTPHeaderField: header)
        
        return self
    }
    
    /**
     *  Sets the HTTP method on the request
     *
     *  @param method A string representing the HTTP method.
     */
    func setHTTPMethod(method: String) -> Agent {
        self.request.HTTPMethod = method
        
        return self
    }
    
    func setURL(url: String) -> Agent {
        self.request.URL = NSURL(string: url)
        
        return self
    }
    
    func setSuccess(success: RequestSuccessBlock?) -> Agent {
        if success {
            self.requestSuccess = success!
        }
        
        return self
    }
    
    func setFailure(failure: RequestFailureBlock?) -> Agent {
        if failure {
            self.requestFailure = failure!
        }
        
        return self
    }
    
    func run() -> Agent {
        let completion = { (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            let httpResponse = response as NSHTTPURLResponse!
            if (error) {
                self.requestFailure(httpResponse, data, error)
                return
            }
            
            // !!!: This serializes ALL objects into JSON...
            // TODO: Introduce some sort of serializer class
            var json: AnyObject!
            
            var JSONError: NSError?
            if (data) {
                json = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &JSONError)
                
                if (JSONError) {
                    println("Handle a serialization error")
                }
            }
            
            self.requestSuccess(httpResponse, json, error)
        }
        
        NSURLConnection.sendAsynchronousRequest(self.request, queue: self.queue, completionHandler: completion)
        return self
    }
    
    func cancel() -> Agent {
        // TODO: Cancel the request
        return self
    }
}
