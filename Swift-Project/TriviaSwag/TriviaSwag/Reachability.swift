//
//  Reachability.swift
//  TriviaSwag
//
//  Created by 谢乾坤 on 5/10/16.
//  Copyright © 2016 QiankunXie. All rights reserved.
//

import SystemConfiguration
import Foundation

public enum ReachabilityError: ErrorType {
    case FailedToCreateWithAddress(sockaddr_in)
    case FailedToCreateWithHostname(String)
    case UnableToSetCallback
    case UnableToSetDispatchQueue
}

public let ReachabilityChangedNotification = "ReachabilityChangedNotification"

func callback(reachability:SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutablePointer<Void>) {
    let reachability = Unmanaged<Reachability>.fromOpaque(COpaquePointer(info)).takeUnretainedValue()
    
    dispatch_async(dispatch_get_main_queue()) {
        reachability.reachabilityChanged(flags)
    }
}


public class Reachability: NSObject {
    
    public typealias NetworkReachable = (Reachability) -> ()
    public typealias NetworkUnreachable = (Reachability) -> ()
    
    public enum NetworkStatus: CustomStringConvertible {
        
        case NotReachable, ReachableViaWiFi, ReachableViaWWAN
        
        public var description: String {
            switch self {
            case .ReachableViaWWAN:
                return "Cellular"
            case .ReachableViaWiFi:
                return "WiFi"
            case .NotReachable:
                return "No Connection"
            }
        }
    }
    
    // MARK: - *** Public properties ***
    public var whenReachable: NetworkReachable?
    public var whenUnreachable: NetworkUnreachable?
    public var reachableOnWWAN: Bool
    public var notificationCenter = NSNotificationCenter.defaultCenter()
    
    public var currentReachabilityStatus: NetworkStatus {
        if isReachable() {
            if isReachableViaWiFi() {
                return .ReachableViaWiFi
            }
            if isRunningOnDevice {
                return .ReachableViaWWAN
            }
        }
        return .NotReachable
    }
    
    public var currentReachabilityString: String {
        return "\(currentReachabilityStatus)"
    }
    
    private var previousFlags: SCNetworkReachabilityFlags?
    
    // MARK: - *** Initialisation methods ***
    
    required public init(reachabilityRef: SCNetworkReachability) {
        reachableOnWWAN = true
        self.reachabilityRef = reachabilityRef
    }
    
    public convenience init(hostname: String) throws {
        
        let nodename = (hostname as NSString).UTF8String
        guard let ref = SCNetworkReachabilityCreateWithName(nil, nodename) else { throw ReachabilityError.FailedToCreateWithHostname(hostname) }
        
        self.init(reachabilityRef: ref)
    }
    
    public class func reachabilityForInternetConnection() throws -> Reachability {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let ref = withUnsafePointer(&zeroAddress, {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }) else { throw ReachabilityError.FailedToCreateWithAddress(zeroAddress) }
        
        return Reachability(reachabilityRef: ref)
    }
    
    public class func reachabilityForLocalWiFi() throws -> Reachability {
        
        var localWifiAddress: sockaddr_in = sockaddr_in(sin_len: __uint8_t(0), sin_family: sa_family_t(0), sin_port: in_port_t(0), sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        localWifiAddress.sin_len = UInt8(sizeofValue(localWifiAddress))
        localWifiAddress.sin_family = sa_family_t(AF_INET)
        
        // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
        let address: UInt32 = 0xA9FE0000
        localWifiAddress.sin_addr.s_addr = in_addr_t(address.bigEndian)
        
        guard let ref = withUnsafePointer(&localWifiAddress, {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }) else { throw ReachabilityError.FailedToCreateWithAddress(localWifiAddress) }
        
        return Reachability(reachabilityRef: ref)
    }
    
    // MARK: - *** Notifier methods ***
    public func startNotifier() throws {
        
        guard !notifierRunning else { return }
        
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutablePointer(Unmanaged.passUnretained(self).toOpaque())
        
        if !SCNetworkReachabilitySetCallback(reachabilityRef!, callback, &context) {
            stopNotifier()
            throw ReachabilityError.UnableToSetCallback
        }
        
        if !SCNetworkReachabilitySetDispatchQueue(reachabilityRef!, reachabilitySerialQueue) {
            stopNotifier()
            throw ReachabilityError.UnableToSetDispatchQueue
        }
        
        // Perform an intial check
        dispatch_async(reachabilitySerialQueue) { () -> Void in
            let flags = self.reachabilityFlags
            self.reachabilityChanged(flags)
        }
        
        notifierRunning = true
    }
    
    public func stopNotifier() {
        defer { notifierRunning = false }
        guard let reachabilityRef = reachabilityRef else { return }
        
        SCNetworkReachabilitySetCallback(reachabilityRef, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachabilityRef, nil)
    }
    
    // MARK: - *** Connection test methods ***
    public func isReachable() -> Bool {
        let flags = reachabilityFlags
        return isReachableWithFlags(flags)
    }
    
    public func isReachableViaWWAN() -> Bool {
        
        let flags = reachabilityFlags
        
        // Check we're not on the simulator, we're REACHABLE and check we're on WWAN
        return isRunningOnDevice && isReachable(flags) && isOnWWAN(flags)
    }
    
    public func isReachableViaWiFi() -> Bool {
        
        let flags = reachabilityFlags
        
        // Check we're reachable
        if !isReachable(flags) {
            return false
        }
        
        // Must be on WiFi if reachable but not on an iOS device (i.e. simulator)
        if !isRunningOnDevice {
            return true
        }
        
        // Check we're NOT on WWAN
        return !isOnWWAN(flags)
    }
    
    // MARK: - *** Private methods ***
    private var isRunningOnDevice: Bool = {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            return false
        #else
            return true
        #endif
    }()
    
    private var notifierRunning = false
    private var reachabilityRef: SCNetworkReachability?
    private let reachabilitySerialQueue = dispatch_queue_create("uk.co.ashleymills.reachability", DISPATCH_QUEUE_SERIAL)
    
    private func reachabilityChanged(flags: SCNetworkReachabilityFlags) {
        
        guard previousFlags != flags else { return }
        
        if isReachableWithFlags(flags) {
            if let block = whenReachable {
                block(self)
            }
        } else {
            if let block = whenUnreachable {
                block(self)
            }
        }
        
        notificationCenter.postNotificationName(ReachabilityChangedNotification, object:self)
        
        previousFlags = flags
    }
    
    private func isReachableWithFlags(flags: SCNetworkReachabilityFlags) -> Bool {
        
        if !isReachable(flags) {
            return false
        }
        
        if isConnectionRequiredOrTransient(flags) {
            return false
        }
        
        if isRunningOnDevice {
            if isOnWWAN(flags) && !reachableOnWWAN {
                // We don't want to connect when on 3G.
                return false
            }
        }
        
        return true
    }
    
    // WWAN may be available, but not active until a connection has been established.
    // WiFi may require a connection for VPN on Demand.
    private func isConnectionRequired() -> Bool {
        return connectionRequired()
    }
    
    private func connectionRequired() -> Bool {
        let flags = reachabilityFlags
        return isConnectionRequired(flags)
    }
    
    // Dynamic, on demand connection?
    private func isConnectionOnDemand() -> Bool {
        let flags = reachabilityFlags
        return isConnectionRequired(flags) && isConnectionOnTrafficOrDemand(flags)
    }
    
    // Is user intervention required?
    private func isInterventionRequired() -> Bool {
        let flags = reachabilityFlags
        return isConnectionRequired(flags) && isInterventionRequired(flags)
    }
    
    private func isOnWWAN(flags: SCNetworkReachabilityFlags) -> Bool {
        #if os(iOS)
            return flags.contains(.IsWWAN)
        #else
            return false
        #endif
    }
    private func isReachable(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.Reachable)
    }
    private func isConnectionRequired(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.ConnectionRequired)
    }
    private func isInterventionRequired(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.InterventionRequired)
    }
    private func isConnectionOnTraffic(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.ConnectionOnTraffic)
    }
    private func isConnectionOnDemand(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.ConnectionOnDemand)
    }
    func isConnectionOnTrafficOrDemand(flags: SCNetworkReachabilityFlags) -> Bool {
        return !flags.intersect([.ConnectionOnTraffic, .ConnectionOnDemand]).isEmpty
    }
    private func isTransientConnection(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.TransientConnection)
    }
    private func isLocalAddress(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.IsLocalAddress)
    }
    private func isDirect(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.IsDirect)
    }
    private func isConnectionRequiredOrTransient(flags: SCNetworkReachabilityFlags) -> Bool {
        let testcase:SCNetworkReachabilityFlags = [.ConnectionRequired, .TransientConnection]
        return flags.intersect(testcase) == testcase
    }
    
    private var reachabilityFlags: SCNetworkReachabilityFlags {
        
        guard let reachabilityRef = reachabilityRef else { return SCNetworkReachabilityFlags() }
        
        var flags = SCNetworkReachabilityFlags()
        let gotFlags = withUnsafeMutablePointer(&flags) {
            SCNetworkReachabilityGetFlags(reachabilityRef, UnsafeMutablePointer($0))
        }
        
        if gotFlags {
            return flags
        } else {
            return SCNetworkReachabilityFlags()
        }
    }
    
    override public var description: String {
        
        var W: String
        if isRunningOnDevice {
            W = isOnWWAN(reachabilityFlags) ? "W" : "-"
        } else {
            W = "X"
        }
        let R = isReachable(reachabilityFlags) ? "R" : "-"
        let c = isConnectionRequired(reachabilityFlags) ? "c" : "-"
        let t = isTransientConnection(reachabilityFlags) ? "t" : "-"
        let i = isInterventionRequired(reachabilityFlags) ? "i" : "-"
        let C = isConnectionOnTraffic(reachabilityFlags) ? "C" : "-"
        let D = isConnectionOnDemand(reachabilityFlags) ? "D" : "-"
        let l = isLocalAddress(reachabilityFlags) ? "l" : "-"
        let d = isDirect(reachabilityFlags) ? "d" : "-"
        
        return "\(W)\(R) \(c)\(t)\(i)\(C)\(D)\(l)\(d)"
    }
    
    deinit {
        stopNotifier()
        
        reachabilityRef = nil
        whenReachable = nil
        whenUnreachable = nil
    }
}