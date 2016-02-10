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

extension NSURL {
    
    /// Get mime type
    func getMime() -> String? {
        var mime: String?
        let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, self.pathExtension!, nil)
        let MIMEType = UTTypeCopyPreferredTagWithClass(UTI!.takeRetainedValue(), kUTTagClassMIMEType)
        var isDir = ObjCBool(false)
        if let mimet = MIMEType {
            mime = mimet.takeRetainedValue() as String
        } else if NSFileManager.defaultManager().fileExistsAtPath(self.path!, isDirectory: &isDir) {
            if isDir {
                mime = "application/x-directory"
            } else {
                // if the file exists but it's not a directory and has no known mime type
                var foundEncoding: UInt = 0
                if let _ = try? NSString(contentsOfURL: self, usedEncoding: &foundEncoding) {
                    mime = "text/plain"
                } else {
                    mime = "application/octet-stream"
                }
            }
        }
        return mime
    }
}