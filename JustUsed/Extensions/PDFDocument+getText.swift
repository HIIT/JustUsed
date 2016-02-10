//
// Copyright (c) 2015 Aalto University
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

import Foundation
import Quartz

extension PDFDocument {
    
    /// Returns a trimmed plain text of the data contained in the document, nil not preset
    func getText() -> String? {
        
        var trimmedText = string()
        trimmedText = trimmedText.stringByReplacingOccurrencesOfString("\u{fffc}", withString: "")
        trimmedText = trimmedText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) // get trimmed version of all text
        trimmedText = trimmedText.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet()) // trim newlines
        trimmedText = trimmedText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) // trim again
        if trimmedText.characters.count > 5 {  // we assume the document does contain useful text if there are more than 5 characters remaining
            return trimmedText
        } else {
            return nil
        }
    }
    
}
