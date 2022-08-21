// Copyright 2013 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// +build amd64

package sm3

//go:noescape
func blockasm(dig *digest, p []byte)

func block(dig *digest, p []byte) {
	if !useAVX2 {
		blockGeneric(dig, p)
	} else {
		//		h := dig.h[:]
		blockasm(dig, p)
	}
}
