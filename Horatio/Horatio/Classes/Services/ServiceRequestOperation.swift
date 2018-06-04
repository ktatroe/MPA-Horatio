//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation

/// Contains Data from the service response
public protocol ServiceResponseDataContainable {
    var responseData: Data? { get }
}

/// Responsible for fetching a response from a service
public protocol ServiceResponseFetching {
    var request: ServiceRequest { get }
}

/// Responsible for processing the service response
public protocol ServiceResponseProcessing {
    var request: ServiceRequest { get }
    var responseProcessor: ServiceResponseProcessor { get }
}

public typealias ServiceFetchOperation = Operation & ServiceResponseFetching & ServiceResponseDataContainable
public typealias ServiceProcessOperation = Operation & ServiceResponseProcessing & ServiceResponseDataContainable

/**
 Handles downloading and processing of a `ServiceRequest`. Callers provide a `ServiceResponseProcessor`
 responsible for processing the response once it's successfully fetched.
 */
public class FetchServiceResponseOperation: GroupOperation {
    
    private var errorHandler: (([Error]) -> Void)?
    
    // MARK: - Initialization
    
    public init(request: ServiceRequest, session: ServiceSession? = nil, urlSession: URLSession = URLSession.shared, responseProcessor: ServiceResponseProcessor) {
        
        let fetchOperation: ServiceFetchOperation
        switch request.requestMethod {
        case .data:
            fetchOperation = DataServiceResponseOperation(request: request, session: session, urlSession: urlSession)
            
        case .download:
            let cacheFileURL = FetchServiceResponseOperation.constructCacheFileURL(for: request)
            fetchOperation = DownloadServiceResponseOperation(request: request, session: session, cacheFileURL: cacheFileURL, urlSession: urlSession)
            errorHandler = { _ in
                try? FileManager.default.removeItem(at: cacheFileURL)
            }
        }

        let processOperation = ProcessServiceResponseOperation(request: request, responseProcessor: responseProcessor)
        
        let dataPassingOperation = BlockOperation {
            processOperation.responseData = fetchOperation.responseData
        }
        
        dataPassingOperation.addDependency(fetchOperation)
        processOperation.addDependency(dataPassingOperation)
        
        super.init(operations: [fetchOperation, processOperation, dataPassingOperation])
        
        #if os(iOS) || os(tvOS)
        let timeout = TimeoutObserver(timeout: 20.0)
        addObserver(timeout)
        #endif
        
        let networkObserver = NetworkObserver()
        addObserver(networkObserver)
        
        name = "Fetch Service Request Operation"
    }
    
    override open func finished(_ errors: [NSError]) {
        errorHandler?(errors)
    }
    
    // MARK: - Private
    
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

/**
 Handles the downloading of an HTTP request via a `NSURLSession` data task.
 */
public class DataServiceResponseOperation: GroupOperation, ServiceResponseFetching, ServiceResponseDataContainable {
    
    // MARK: - Properties
    
    public let request: ServiceRequest
    
    public private(set) var responseData: Data?
    
    // MARK: - Initialization
    
    public init(request: ServiceRequest, session: ServiceSession? = nil, urlSession: URLSession = URLSession.shared) {
        self.request = request
        
        super.init(operations: [])
        
        guard let urlRequest = request.makeURLRequest(session),
            let url = urlRequest.url else {
                return
        }
        
        name = "Data Service Request Operation \(url)"
        
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

/**
 Handles the downloading of an HTTP request via a `NSURLSession` download task and
 storing the downloaded file in a cache file location that continued operations can
 pick up and manipulate.
 */
public class DownloadServiceResponseOperation: GroupOperation, ServiceResponseFetching, ServiceResponseDataContainable {
    
    // MARK: - Properties
    
    public let request: ServiceRequest
    public let cacheFileURL: URL
    
    public var responseData: Data? {
        return try? Data(contentsOf: cacheFileURL)
    }
    
    // MARK: - Initialization
    
    public init(request: ServiceRequest, session: ServiceSession? = nil, cacheFileURL: URL, urlSession: URLSession = URLSession.shared) {
        self.request = request
        self.cacheFileURL = cacheFileURL
        
        super.init(operations: [])
        
        guard let urlRequest = request.makeURLRequest(session),
            let url = urlRequest.url else {
                return
        }
        
        name = "Download Service Request Operation \(url)"
        
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

/**
 Uses a provided `ServiceResponseProcessor` to process a response downloaded
 into a cache file.
 */
public class ProcessServiceResponseOperation: Operation, ServiceResponseProcessing, ServiceResponseDataContainable {
    
    // MARK: - Properties
    
    public let request: ServiceRequest
    public let responseProcessor: ServiceResponseProcessor
    
    public fileprivate(set) var responseData: Data?
    
    // MARK: - Initialization
    
    public init(request: ServiceRequest, responseProcessor: ServiceResponseProcessor, responseData: Data? = nil) {
        self.request = request
        self.responseProcessor = responseProcessor
        self.responseData = responseData
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

