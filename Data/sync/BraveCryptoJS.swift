// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveShared

struct BraveCryptoJS: BrowserifyExposable, BundledJSProtocol {
    let bundle: Bundle
    let name: String
    let exposedFunctions: [ExposedJSFunction]
    
    struct Functions {
        struct FromBytesOrHex {
            static let name = "fromBytesOrHex"
            
            static let body =
            """
            function(bytes){
            return module.exports.passphrase.\(name)(bytes);
            };
            """
            
        }
        
        struct ToBytes32 {
            static let name = "toBytes32"
            
            static let body =
            """
            function(passphrase){
            return module.exports.passphrase.\(name)(passphrase);
            };
            """
        }
    }
    
    init?() {
        name = "crypto"
        bundle = Bundle.data
        
        exposedFunctions = [ExposedJSFunction(name: Functions.FromBytesOrHex.name,
                                              body: Functions.FromBytesOrHex.body),
                            ExposedJSFunction(name: Functions.ToBytes32.name,
                                              body: Functions.ToBytes32.body)]
    }
}
