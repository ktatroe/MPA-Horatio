//
//  NewServiceRequestOperation.swift
//  Horatio
//
//  Created by Kyle Watson on 5/29/18.
//  Copyright © 2018 Mudpot Apps. All rights reserved.
//

import Foundation

protocol ResponseDataContainable {
    var responseData: Data? { get }
}

public protocol ResponseFetching {
    var request: ServiceRequest { get }
}

public protocol ResponseProcessing {
    var request: ServiceRequest { get }
    var responseProcessor: ServiceResponseProcessor { get }
}

/**
 Handles downloading and processing of a `ServiceRequest`. Callers provide a `ServiceResponseProcessor`
 responsible for processing the response once it's successfully fetched.
 */
public class ServiceRequestOperation: GroupOperation {
    
    typealias ServiceFetchOperation = Operation & ResponseFetching & ResponseDataContainable
    typealias ServiceProcessOperation = Operation & ResponseProcessing & ResponseDataContainable
    
    // MARK: - Initialization
    
    public init(request: ServiceRequest,
                session: ServiceSession? = nil,
                urlSession: URLSession = URLSession.shared,
                responseProcessor: ServiceResponseProcessor) {
        
        let fetchOperation = ServiceRequestOperation.fetchOperation(for: request, session: session, urlSession: urlSession)
        let processOperation = ProcessServiceResponseOperation(request: request, responseProcessor: responseProcessor)
        let dataOperation = BlockOperation {
            processOperation.responseData = fetchOperation.responseData
        }
        
        dataOperation.addDependency(fetchOperation)
        processOperation.addDependency(dataOperation)
        
        super.init(operations: [fetchOperation, processOperation, dataOperation])
        
        #if os(iOS) || os(tvOS)
        let timeout = TimeoutObserver(timeout: 20.0)
        addObserver(timeout)
        #endif
        
        let networkObserver = NetworkObserver()
        addObserver(networkObserver)
        
        name = "Fetch Service Request Operation"
    }
    
    // TODO: remove cache file
//    override open func finished(_ errors: [NSError]) {
//        do {
//            try FileManager.default.removeItem(at: cacheFile)
//        } catch { }
//    }
    
    // MARK: - Private
    
    private static func fetchOperation(for request: ServiceRequest, session: ServiceSession?, urlSession: URLSession) -> ServiceFetchOperation {
        let fetchOperation: ServiceFetchOperation
        
        switch request.requestMethod {
        case .data:
            fetchOperation = ServiceDataTaskOperation(request: request, session: session, urlSession: urlSession)
            
        case .download:
            let cacheFileURL = constructCacheFileURL(for: request)
            fetchOperation = ServiceDownloadTaskOperation(request: request, cacheFileURL: cacheFileURL, session: session, urlSession: urlSession)
        }
        
        return fetchOperation
    }
    
    private static func constructCacheFileURL(for request: ServiceRequest) -> URL {
        let cachesFolder = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        let cacheFileName = generatedCacheFileName(request)
        return cachesFolder.appendingPathComponent(cacheFileName)
    }
    
    private static func generatedCacheFileName(_ request: ServiceRequest) -> String {
        guard let url = request.url else { return UUID().uuidString }
        
        let cacheComponent = url.lastPathComponent
        let hasValidCacheComponent = !(url.hasDirectoryPath && cacheComponent.count == 1)
        return hasValidCacheComponent ? cacheComponent : UUID().uuidString
    }
}

public class ServiceDataTaskOperation: GroupOperation, ResponseFetching, ResponseDataContainable {
    
    // MARK: - Properties
    
    public let request: ServiceRequest
    
    private(set) var responseData: Data?
    
    // MARK: - Initialization
    
    public init(request: ServiceRequest, session: ServiceSession? = nil, urlSession: URLSession = URLSession.shared) {
        self.request = request
        
        super.init(operations: [])
        
        guard let urlRequest = request.makeURLRequest(session),
            let url = urlRequest.url else {
                return
        }
        
        name = "Service DataTask Operation \(url)"
        
        let task = urlSession.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            guard error == nil else {
                self?.finishWithError(error)
                return
            }
            
            self?.responseData = data
        }
        
        let taskOperation = URLSessionTaskOperation(task: task)
        addOperation(taskOperation)
    }
}

public class ServiceDownloadTaskOperation: GroupOperation, ResponseFetching, ResponseDataContainable {
    
    // MARK: - Properties
    
    public let request: ServiceRequest
    public let cacheFileURL: URL
    
    var responseData: Data? {
        return try? Data(contentsOf: cacheFileURL)
    }
    
    // MARK: - Initialization
    
    public init(request: ServiceRequest, cacheFileURL: URL, session: ServiceSession? = nil, urlSession: URLSession = URLSession.shared) {
        self.request = request
        self.cacheFileURL = cacheFileURL
        
        super.init(operations: [])
        
        guard let urlRequest = request.makeURLRequest(session),
            let url = urlRequest.url else {
                return
        }
        
        name = "Service DownloadTask Operation \(url)"
        
        let task = urlSession.downloadTask(with: urlRequest) { [weak self] (url, response, error) in
            self?.downloadFinished(url, error: error)
        }
        
        let taskOperation = URLSessionTaskOperation(task: task)
        addOperation(taskOperation)
    }
    
    
    // MARK: - Private
    
    private func downloadFinished(_ url: URL?, error: Error?) {
        if let localURL = url {
            try? FileManager.default.removeItem(at: cacheFileURL)
            
            do {
                try FileManager.default.moveItem(at: localURL, to: cacheFileURL)
            } catch let error as NSError {
                aggregateError(error)
            }
            
        } else if let error = error {
            aggregateError(error)
        } else {
            // do nothing and let the operation complete
        }
    }
}

public enum ProcessServiceResponseError: Error {
    case noData
    case notProcessed
}

public class ProcessServiceResponseOperation: Operation, ResponseProcessing, ResponseDataContainable {
    
    // MARK: - Properties
    
    public let request: ServiceRequest
    public let responseProcessor: ServiceResponseProcessor
    
    fileprivate(set) var responseData: Data?
    
    // MARK: - Initialization
    
    public init(request: ServiceRequest, responseProcessor: ServiceResponseProcessor) {
        self.request = request
        self.responseProcessor = responseProcessor
    }
    
    // MARK: - Operation execute override
    
    override public func execute() {
        
        guard let data = responseData else {
            finishWithError(ProcessServiceResponseError.noData)
            return
        }
        
        self.responseProcessor.process(request, input: .data(data)) { (response: ServiceResponseProcessorParam) in
            switch response {
            case .stream(_), .data(_):
                self.finish()
                
            case .processed(let processed):
                let error = processed ? nil : ProcessServiceResponseError.notProcessed
                self.finishWithError(error)
                
            case .error(let error):
                self.finishWithError(error)
            }
        }
    }
}

/**
 Handles moving data from one processor to another. A value may either be terminal or
 non-terminal. Terminal values indicate that processing is complete and the input is
 "consumed". Non-terminal values provide new input that may be further processed (for
 example, in a pipeline of processors).
 */
public enum ServiceResponseProcessorParam {
    /// Initial input is typically a memory-efficient `NSInputStream`.
    case stream(InputStream)
    
    /// `NSData` can be used to pipe data from one processor to the next.
    case data(Data)
    
    /// The processor was terminal, with an indication of whether the data was completely processed.
    case processed(Bool)
    
    /// The processor was terminal, and ended with a known error.
    case error(NSError)
}


/**
 Handles input delivered via `ServiceResponseProcessorParam`, processes the data, and returns
 a new `ServiceResponseProcessorParam`, which can then be further processed or, if terminal,
 complete the processing stage of the operation.
 */
public protocol ServiceResponseProcessor: class {
    func process(_ request: ServiceRequest, input: ServiceResponseProcessorParam, completionBlock: @escaping (ServiceResponseProcessorParam) -> Void)
}

