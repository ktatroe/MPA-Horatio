//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import Foundation


/// Todo: Assemblers and Assemblies to handle switching out a set of services at once?

/**
 `Container` is a basic dependency-injection handler for services, such as
 service bridges, request services, persistent store managers, etc. Dependency-injection
 handlers can get really gnarly really quickly, so this is by design a minimal
 implementation.

 To register, simply call register class and name to register. In the following example,
 we register two instances of classes confirming to the ParkServiceBridge protocol, and
 register a default implementation:

 let container = Container()
 container.register(ParkServiceBridge.self, "WebServices") { WebServicesParkServiceBridge() }
 container.register(ParkServiceBridge.self, "CloudKit") { CloudKitParkServiceBridge() }
 container.register(ParkServiceBridge.self) { container.resolve(ParkServiceBridge.self, "WebServices") } }

 To fetch a service, call resolve:

 if let bridge = container.resolve(ParkServiceBridge.self) { }

 A shared container is also provided, for use in the general case of globaly-available
 injectable services:

 Container.register(ParkServiceBridge.self) { WebServicesParkServiceBridge() }

 ...

 if let bridge = Container.resolve(ParkServiceBridge.self) { }
 */
public class Container {
    static internal var sharedContainer = Container()

    private var services = [ContainerItemKey: ContainerItemType]()

    // we need a recursive lock, because sometimes we do a resolve() inside a resolve()
    private let servicesLock = NSRecursiveLock()

    public func register<T>(serviceType: T.Type, name: String? = nil, factory: Resolvable -> T) -> ContainerEntry<T> {
        return registerFactory(serviceType, factory: factory, name: name)
    }

    internal func registerFactory<T, Factory>(serviceType: T.Type, factory: Factory, name: String?) -> ContainerEntry<T> {
        let key = ContainerItemKey(factoryType: factory.dynamicType, name: name)
        let entry = ContainerEntry(serviceType: serviceType, factory: factory)

        // ensure no other access while writing
        servicesLock.lock()

        defer {
            servicesLock.unlock()
        }

        services[key] = entry

        return entry
    }

    static public func register<T>(serviceType: T.Type, name: String? = nil, factory: Resolvable -> T) -> ContainerEntry<T> {
        return sharedContainer.register(serviceType, name: name, factory: factory)
    }
}


extension Container : Resolvable {
    public func resolve<T>(serviceType: T.Type, name: String? = nil) -> T? {
        typealias FactoryType = Resolvable -> T

        return resolveFactory(name) { (factory: FactoryType) in factory(self) }
    }

    static public func resolve<T>(serviceType: T.Type, name: String? = nil) -> T? {
        return sharedContainer.resolve(serviceType, name: name)
    }

    internal func resolveFactory<T, Factory>(name: String?, invoker: Factory -> T) -> T? {
        let key = ContainerItemKey(factoryType: Factory.self, name: name)

        var lockedEntry: ContainerItemType? = nil

        // read from data structure in a thread-safe manner
        servicesLock.lock()

        defer {
            servicesLock.unlock()
        }

        lockedEntry = services[key]

        if let entry = lockedEntry as? ContainerEntry<T> {
            if entry.instance == nil {
                // this is doing a write to a shared object, and also must happen inside the lock
                entry.instance = resolveEntry(entry, key: key, invoker: invoker) as Any
            }

            return entry.instance as? T
        }

        return nil
    }

    private func resolveEntry<T, Factory>(entry: ContainerEntry<T>, key: ContainerItemKey, invoker: Factory -> T) -> T {
        let resolvedInstance = invoker(entry.factory as! Factory)

        return resolvedInstance
    }
}


public typealias FunctionType = Any

public protocol Resolvable {
    func resolve<T>(serviceType: T.Type, name: String?) -> T?
}


internal struct ContainerItemKey {
    private let factoryType: FunctionType.Type
    private let name: String?

    internal init(factoryType: FunctionType.Type, name: String? = nil) {
        self.factoryType = factoryType
        self.name = name
    }
}


extension ContainerItemKey : Hashable {
    var hashValue: Int {
        return String(factoryType).hashValue ^ (name?.hashValue ?? 0)
    }
}

func == (lhs: ContainerItemKey, rhs: ContainerItemKey) -> Bool {
    return (lhs.factoryType == rhs.factoryType) && (lhs.name == rhs.name)
}


internal typealias ContainerItemType = Any

public class ContainerEntry<T> : ContainerItemType {
    private let serviceType: T.Type
    let factory: FunctionType

    var instance: Any? = nil

    init(serviceType: T.Type, factory: FunctionType) {
        self.serviceType = serviceType
        self.factory = factory
    }
}
