//
//  _Resolving.swift
//  Guise
//
//  Created by Gregory Higley on 12/11/17.
//  Copyright © 2017 Gregory Higley. All rights reserved.
//

import Foundation

/// Used internally by Guise.
public protocol _Resolving {
    static var resolver: Resolving { get set }
    @discardableResult static func register<ParameterType, HoldingType: Holder>(key: Key<HoldingType.Held>, metadata: Any, cached: Bool, resolution: @escaping Resolution<ParameterType, HoldingType>) -> Key<HoldingType.Held>
    @discardableResult static func unregister<Keys: Sequence>(keys: Keys) -> Int where Keys.Element: Keyed
    static func filter<K: Keyed>(_ filter: @escaping (K) -> Bool) -> [K: Registration]
}
