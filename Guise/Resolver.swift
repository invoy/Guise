//
//  Resolver.swift
//  Guise
//
//  Created by Gregory Higley on 12/11/17.
//  Copyright © 2017 Gregory Higley. All rights reserved.
//

import Foundation

public class Resolver: Guising {
    
    private var lock = Lock()
    private var registrations = [AnyKey: Registration]()
    
    public func register<Parameter, RegisteredType>(key: Key<RegisteredType>, metadata: Any = (), cached: Bool = false, resolution: @escaping Resolution<Parameter, RegisteredType>) -> Key<RegisteredType> {
        lock.write { registrations[AnyKey(key: key)!] = _Registration(metadata: metadata, cached: cached, resolution: resolution) }
        return key
    }

    public func unregister<K: Keyed>(keys: Set<K>) -> Int {
        return lock.write {
            let count = registrations.count
            registrations = registrations.filter{ element in !keys.contains{ $0 == element.key } }
            return count - registrations.count
        }
    }
    
    public func filter<K: Keyed>(key: K.Type, name: AnyHashable? = nil, container: AnyHashable? = nil) -> [K: Registration] {
        return lock.read {
            var result = Dictionary<K, Registration>()
            for element in registrations {
                guard let key = K(key: element.key) else { continue }
                if let name = name, key.name != name { continue }
                if let container = container, key.container != container { continue }
                result[key] = element.value
            }
            return result
        }
    }
}
