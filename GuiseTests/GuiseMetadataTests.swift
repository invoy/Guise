//
//  GuiseMetadataTests.swift
//  Guise
//
//  Created by Gregory Higley on 10/20/17.
//  Copyright © 2017 Gregory Higley. All rights reserved.
//

import XCTest
@testable import Guise

class GuiseMetadataTests: XCTestCase {

    func testMetadata() {
        let key = Guise.register(instance: 3, metadata: 4)
        let type = Int.self
        guard let _ = Guise.metadata(forKey: key, metatype: type) else {
            XCTFail("Metadata was not of type \(type).")
            return
        }
        // Although this key has metadata, it is not castable to `String`,
        // so `metadata(for:type:)` returns nil.
        XCTAssertNil(Guise.metadata(forKey: key) as String?)
    }

}
