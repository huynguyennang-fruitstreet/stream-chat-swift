//
//  ClientLogger.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 02/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

/// A Client logger.
public final class ClientLogger {
    
    /// A logger level.
    public enum Level: String, CustomStringConvertible {
        case error
        case debug
        case info
        
        public var description: String {
            return rawValue.uppercased()
        }
        
        static func level(_ options: Options) -> Level {
            if options.isError {
                return .error
            }
            
            if options.isDebug {
                return .debug
            }
            
            return .info
        }
        
        func isEnabled(with level: Level) -> Bool {
            switch (self, level) {
            case (.error, .debug): return false
            case (.error, .info): return false
            case (.debug, .info): return false
            default: return true
            }
        }
    }
    
    /// A client logger options.
    ///
    /// It has several levels: Error, Debug and Info.
    ///  - 🐴 for REST requests: `.requestsError`, `.requests`, `.requestsInfo`
    ///  - 🦄 for web socket events: `.webSocketError`, `.webSocket`, `.webSocketInfo`
    ///  - 🗞 for notifications: `.notificationsError`, `.notifications`
    ///  - 💽 for a database: `.databaseError`, `.database`, `.databaseInfo`
    ///  - for all error logs: `.error`
    ///  - for all debug logs: `.debug`
    ///  - full logs: `.info`
    public struct Options: OptionSet {
        public let rawValue: Int
        
        /// Logs for requests 🐴. [Error]
        public static let requestsError = Options(rawValue: 1 << 0)
        /// Logs for a web socket 🦄. [Error]
        public static let webSocketError = Options(rawValue: 1 << 1)
        /// Logs for notifications 🗞. [Error]
        public static let notificationsError = Options(rawValue: 1 << 2)
        /// Logs for a database 💽. [Error]
        public static let databaseError = Options(rawValue: 1 << 3)
        
        /// Logs for requests 🐴. [Debug]
        public static let requests = Options(rawValue: 1 << 10)
        /// Logs for a web socket 🦄. [Debug]
        public static let webSocket = Options(rawValue: 1 << 11)
        /// Logs for notifications 🗞. [Debug]
        public static let notifications = Options(rawValue: 1 << 12)
        /// Logs for a database 💽. [Debug]
        public static let database = Options(rawValue: 1 << 13)
        
        /// Logs for requests 🐴. [Info]
        public static let requestsInfo = Options(rawValue: 1 << 20)
        /// Logs for a web socket 🦄. [Info]
        public static let webSocketInfo = Options(rawValue: 1 << 21)
        /// Logs for a database 💽. [Info]
        public static let databaseInfo = Options(rawValue: 1 << 23)
        
        /// All errors.
        public static let error: Options = [.requestsError, .webSocketError, .notificationsError, databaseError]
        
        /// All debug logs.
        public static let debug: Options = [.requests, .webSocket, .notifications, .database]
        
        /// Full logs.
        public static let info: Options = [.requestsInfo, .webSocketInfo, .notifications, .databaseInfo]
        
        // FIXME: Shouldn't be like that.
        var isEnabled: Bool {
            return self.rawValue > 0
        }
        
        /// Checks if the level is error.
        public var isError: Bool {
            return rawValue < (1 << 10)
        }
        
        /// Checks if the level is debug.
        public var isDebug: Bool {
            return rawValue < (1 << 20)
        }
        
        /// Checks if the level is info.
        public var isInfo: Bool {
            return rawValue < (1 << 31)
        }
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        /// Create a logger with intersected log options.
        /// - Parameters:
        ///   - icon: a logger icon.
        ///   - subOptions: a subset of options.
        public func logger(icon: String, for subOptions: Options) -> ClientLogger? {
            guard subOptions.isEnabled else {
                return nil
            }
            
            let intersectedOptions = intersection(subOptions)
            return intersectedOptions.isEnabled ? ClientLogger(icon: icon, level: .level(intersectedOptions)) : nil
        }
    }
    
    /// Controls whether connection error dialogue is shown on WebSocket errors.
    /// you can check `showConnectionErrorAlert` function to see how the dialogue is being shown.
    public static var showConnectionErrorAlert = false
    
    /// Controls whether to display icons in logs
    /// Only valid when default `ClientLogger.logger` block is used, if you've overridden that, this is not valid.
    public static var iconEnabled = false
    
    /// Controls whether to display date in logs
    /// Only valid when default `ClientLogger.logger` block is used, if you've overridden that, this is not valid.
    public static var dateEnabled = true
    
    /// Controls whether to display log level in logs
    /// Only valid when default `ClientLogger.logger` block is used, if you've overridden that, this is not valid.
    public static var levelEnabled = true
    
    /// Checks if a user has overridden `logger` block.
    /// Needed for backwards compatibility.
    private static var usingLegacyLogger = false
    
    /// A customizable logger block.
    /// By default error messages will print to the console, but you can customize it to use own logger.
    ///
    /// - Parameters:
    ///     - icon: a small icon string like a tag for messages, e.g. 🦄
    ///     - dateAndTime: a formatted string of date and time, could be empty.
    ///     - message: a message.
    @available(*, deprecated, message: """
    Customizing the logger block with `ClientLogger.logger` is deprecated.
    Please use `ClientLogger.log` to customize your logging logic.
    """)
    public static var logger: (String, String, String) -> Void = legacyLogger {
        didSet {
            usingLegacyLogger = true
            legacyLogger = logger
        }
    }
    
    private static var legacyLogger: (String, String, String) -> Void = { icon, dateTime, message in
        if iconEnabled {
            print(icon, terminator: " ")
        }
        
        if dateEnabled {
            if dateTime.isEmpty {
                print("[\(Date().log)]", terminator: " ")
            } else {
                print("[\(dateTime)]", terminator: " ")
            }
        }
        
        print(message)
    }
    
    /// A customizable log block.
    /// By default error messages will print to the console, but you can customize it to use your own log block.
    ///
    /// - Parameters:
    ///     - icon: a small icon string like a tag for messages, e.g. 🦄
    ///     - dateAndTime: a formatted string of date and time, could be empty.
    ///     - level: Log level
    ///     - message: a message.
    public static var log: (String, String, Level, String) -> Void = { icon, dateTime, level, message in
        if iconEnabled {
            print(icon, terminator: " ")
        }
        
        if dateEnabled {
            if dateTime.isEmpty {
                print("[\(Date().log)]", terminator: " ")
            } else {
                print("[\(dateTime)]", terminator: " ")
            }
        }
        
        if levelEnabled {
            print("[\(level)]", terminator: " ")
        }
        
        print(message)
    }
    
    private let icon: String
    private var lastTime: CFTimeInterval
    private var startTime: CFTimeInterval
    private let level: Level
    
    private var measuredTasksStart: Atomic<[UUID: (start: CFTimeInterval, description: String)]> = .init([:])
    
    /// Init a client logger.
    /// - Parameters:
    ///   - icon: a string icon.
    ///   - level: level (see `ClientLogger.Level`).
    public init(icon: String, level: Level) {
        self.icon = icon
        self.level = level
        startTime = CACurrentMediaTime()
        lastTime = startTime
    }
    
    /// Creates a measurement log task. Call it before a heavy operation then call `logTaskFinished` with a specified `taskId`.
    ///
    /// Example:
    /// ```
    /// let taskId = logger.logTaskStarted("Parsing the JSON response")
    /// // Parse data...
    /// logger.logTaskFinished(taskId: taskId)
    /// ```
    /// The output will be like this:
    /// ```
    /// [28 Aug 11:01:07.047] [DEBUG] ⏱ Parsing the JSON response finished in 0.144 seconds.
    /// ```
    ///
    /// - Parameters:
    ///   - message: a log message.
    ///   - taskId: a measurement task id `UUID`. You can skip this parameter and use the generated id from the function result.
    /// - Returns: a generated task id `UUID`.
    @discardableResult
    public func logTaskStarted(_ message: String, taskId: UUID = .init()) -> UUID {
        measuredTasksStart.update {
            var tasks = $0
            tasks[taskId] = (start: CACurrentMediaTime(), description: message)
            return tasks
        }
        
        return taskId
    }
    
    /// Finishes the measurement log task and logs the result.
    /// - Parameter id: a measurement task id.
    public func logTaskFinished(taskId id: UUID?) {
        guard let id = id else { return }
        
        guard let task = measuredTasksStart[id] else {
            log("Trying to finish a logger measuring task with \(id) but the task wasn't started.", level: .error)
            return
        }
        
        let duration = CACurrentMediaTime() - task.start
        log("⏱ \(task.description) finished in \(String(format: "%.3f", duration)) seconds.", level: .debug)
    }
    
    /// Log a request.
    /// - Parameter request: an URL request.
    public func log(_ request: URLRequest, isUploading: Bool = false) {
        log("➡️ \(request.httpMethod ?? "Request") \(request.description)")
        
        if level.isEnabled(with: .debug),
            let url = request.url,
            url.query != nil,
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let queryItems = urlComponents.queryItems {
            log(queryItems)
        }
        
        if let bodyStream = request.httpBodyStream {
            log("Request Body Stream \(bodyStream.description)", level: .info)
        }
        
        if level.isEnabled(with: .debug), let body = request.httpBody {
            if isUploading {
                log("📦 Uploading \(body.count / 1024) KB data...")
            } else {
                log(body, message: "Request Body", forceToShowData: true)
            }
        }
    }
    
    /// Log request headers.
    /// - Parameter headers: headers.
    public func log(headers: [String: String]?) {
        if let headers = headers, !headers.isEmpty {
            var message = "Request headers:\n"
            headers.forEach { message += "\t◾️ \($0) = \($1)\n" }
            log(message, level: .info)
        }
    }
    
    /// Log URL query items.
    ///
    /// - Parameter queryItems: URL query items
    public func log(_ queryItems: [URLQueryItem]) {
        guard !queryItems.isEmpty else {
            return
        }
        
        var message = ""
        
        queryItems.forEach { item in
            if let value = item.value,
                value.hasPrefix("{"),
                let data = value.data(using: .utf8),
                let json = try? data.prettyPrintedJSONString() {
                message += "▫️ \(item.name)=\(json)\n"
                
            } else if item.name != "api_key" && item.name != "user_id" && item.name != "client_id" {
                message += "▫️ \(item.description)\n"
            }
        }
        
        if !message.isEmpty {
            log("URL query items:\n\(message)")
        }
    }
    
    /// Log URL response.
    ///
    /// - Parameters:
    ///   - response: an URL response.
    ///   - data: a response data.
    ///   - forceToShowData: force to always log a data.
    public func log(_ response: URLResponse?, data: Data?, forceToShowData: Bool = false) {
        if let response = response as? HTTPURLResponse, let url = response.url {
            log("⬅️ Response \(response.statusCode) (\(data?.description ?? "0 bytes")): \(url)")
        } else if let response = response {
            log("⬅️❔ Unknown response (\(data?.description ?? "0 bytes")): \(response)")
        }
        
        guard let data = data, (forceToShowData || level.isEnabled(with: .info)) else {
            return
        }
        
        if let jsonString = try? data.prettyPrintedJSONString() {
            log("📦 \(jsonString)", level: forceToShowData ? .error : .info)
        } else if let dataString = String(data: data, encoding: .utf8) {
            log("📦 \"\(dataString)\"", level: forceToShowData ? .error : .info)
        }
    }
    
    /// Log an error.
    ///
    /// - Parameters:
    ///   - error: an error.
    ///   - message: an additional message (optional).
    ///   - function: a callee function (auto).
    ///   - line: a callee line of a code in a function (auto).
    public func log(_ error: Error?,
                    message: String? = nil,
                    function: String = #function,
                    line: Int = #line) {
        if let error = error {
            log("❌ \(message ?? "") \(error) in \(function)[\(line)]", level: .error)
        }
    }
    
    /// Log a data as a pretty printed JSON string.
    /// - Parameter data: a data.
    public func log(_ data: Data?, message: String = "", forceToShowData: Bool = false) {
        guard forceToShowData || level.isEnabled(with: .info) else {
            return
        }
        
        guard let data = data, !data.isEmpty else {
            log("📦 \(message) Data is empty", level: .debug)
            return
        }
        
        do {
            log("📦 \(message) " + (try data.prettyPrintedJSONString()), level: .debug)
        } catch {
            log("📦 \(message) \(error)", level: .debug)
        }
    }
    
    /// Log a message with an identifier.
    ///
    /// - Parameters:
    ///   - identifier: an identifier.
    ///   - message: a message.
    public func log(_ message: String, level: Level = .debug) {
        if self.level.isEnabled(with: level) {
            ClientLogger.log(icon, dateTime: Date().log, level: level, message)
        }
    }
    
    /// Log a message.
    ///
    /// - Parameters:
    ///   - icon: a string icon, e.g. emoji.
    ///   - dateTime: a date time as a string.
    ///   - message: a message.
    public static func log(_ icon: String, dateTime: String = "", level: Level = .info, _ message: String) {
        if usingLegacyLogger {
            ClientLogger.legacyLogger(icon, dateTime, message)
        } else {
            ClientLogger.log(icon, dateTime, level, message)
        }
    }
    
    /// Performs `Swift.assert` and stops program execution if `condition` evaluated to false. In RELEASE builds only
    /// logs the failure.
    ///
    /// - Parameters:
    ///   - condition: The condition to test.
    ///   - message: A custom message to log if `condition` is evaluated to false.
    public static func logAssert(_ condition: Bool,
                                 _ message: @autoclosure () -> String,
                                 file: StaticString = #file,
                                 line: UInt = #line) {
        
        guard condition == false else { return }
        let evaluatedMessage = message()
        Swift.assert(condition, evaluatedMessage, file: file, line: line)
        ClientLogger.log("", dateTime: "", level: .error, "Assertion failure in \(file)[\(line)]: " + evaluatedMessage)
    }
    
    /// Triggers `Swift.assertionFailure`. In RELEASE builds only logs the failure.
    ///
    /// - Parameter message: A custom message to log.
    public static func logAssertionFailure(_ message: String, file: StaticString = #file, line: UInt = #line) {
        Swift.assertionFailure(message, file: file, line: line)
        ClientLogger.log("", dateTime: "", level: .error, "Assertion failure \(file)[\(line)]: " + message)
    }
    
    static func showConnectionAlert(_ error: Error, jsonError: ClientErrorResponse?) {
        #if DEBUG
        guard ClientLogger.showConnectionErrorAlert else { return }
        let jsonError = jsonError ?? ClientErrorResponse(code: 0, message: "<unknown>", statusCode: 0)
        let message = "\(jsonError.message)\n\nCode: \(jsonError.code)\nStatus Code: \(jsonError.statusCode)\n\n\(error)"
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Connection Error", message: message, preferredStyle: .alert)
            alert.addAction(.init(title: "Ok, I'll check", style: .cancel, handler: nil))
            UIApplication.shared.delegate?.window??.rootViewController?.present(alert, animated: true)
        }
        #endif
    }
}

extension Date {
    /// A string of the date for the `ClientLogger`.
    public var log: String {
        return DateFormatter.log.string(from: self)
    }
}

extension DateFormatter {
    /// A date formatter for `ClientLogger`.
    public static var log: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM HH:mm:ss.SSS"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter
    }()
}
