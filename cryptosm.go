// Copyright 2011 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Package newcryptosm Package x509 Package crypto collects common cryptographic constants.
package newcryptosm

import (
	"crypto"
	"crypto/md5"
	"crypto/sha1"
	"crypto/sha256"
	"crypto/sha512"
	"github.com/hellobchain/newcryptosm/sm3"
	"hash"
	"strconv"
)

// Hash identifies a cryptographic hash function that is implemented in another
// package.
type Hash uint

// HashFunc simply returns the value of h so that Hash implements SignerOpts.
func (h Hash) HashFunc() crypto.Hash {
	return crypto.Hash(h)
}

const (
	MD4         Hash = 1 + iota // import golang.org/x/crypto/md4
	MD5                         // import crypto/md5
	SHA1                        // import crypto/sha1
	SHA224                      // import crypto/sha256
	SHA256                      // import crypto/sha256
	SHA384                      // import crypto/sha512
	SHA512                      // import crypto/sha512
	MD5SHA1                     // no implementation; MD5+SHA1 used for TLS RSA
	RIPEMD160                   // import golang.org/x/crypto/ripemd160
	SHA3_224                    // import golang.org/x/crypto/sha3
	SHA3_256                    // import golang.org/x/crypto/sha3
	SHA3_384                    // import golang.org/x/crypto/sha3
	SHA3_512                    // import golang.org/x/crypto/sha3
	SHA512_224                  // import crypto/sha512
	SHA512_256                  // import crypto/sha512
	BLAKE2s_256                 // import golang.org/x/crypto/blake2s
	BLAKE2b_256                 // import golang.org/x/crypto/blake2b
	BLAKE2b_384                 // import golang.org/x/crypto/blake2b
	BLAKE2b_512                 // import golang.org/x/crypto/blake2b
	SM3
	maxHash
)

var digestSizes = []uint8{
	MD4:         16,
	MD5:         16,
	SHA1:        20,
	SHA224:      28,
	SHA256:      32,
	SHA384:      48,
	SHA512:      64,
	SHA512_224:  28,
	SHA512_256:  32,
	SHA3_224:    28,
	SHA3_256:    32,
	SHA3_384:    48,
	SHA3_512:    64,
	MD5SHA1:     36,
	RIPEMD160:   20,
	BLAKE2s_256: 32,
	BLAKE2b_256: 32,
	BLAKE2b_384: 48,
	BLAKE2b_512: 64,
	SM3:         32,
}

// Size returns the length, in bytes, of a digest resulting from the given hash
// function. It doesn't require that the hash function in question be linked
// into the program.
func (h Hash) Size() int {
	if h > 0 && h < maxHash {
		return int(digestSizes[h])
	}
	panic("crypto: Size of unknown hash function")
}

var hashes = make([]func() hash.Hash, maxHash)

// New returns a new hash.Hash calculating the given hash function. New panics
// if the hash function is not linked into the binary.
func (h Hash) New() hash.Hash {
	if h > 0 && h < maxHash {
		f := hashes[h]
		if f != nil {
			return f()
		}
	}
	panic("crypto: requested hash function #" + strconv.Itoa(int(h)) + " is unavailable")
}

// Available reports whether the given hash function is linked into the binary.
func (h Hash) Available() bool {
	return h < maxHash && hashes[h] != nil
}

// RegisterHash registers a function that returns a new instance of the given
// hash function. This is intended to be called from the init function in
// packages that implement hash functions.
func RegisterHash(h Hash, f func() hash.Hash) {
	if h >= maxHash {
		panic("crypto: RegisterHash of unknown hash function")
	}
	hashes[h] = f
}

func init() {
	RegisterHash(MD5, md5.New)
	RegisterHash(SHA1, sha1.New)
	RegisterHash(SHA224, sha256.New224)
	RegisterHash(SHA256, sha256.New)
	RegisterHash(SHA384, sha512.New384)
	RegisterHash(SHA512, sha512.New)
	RegisterHash(SHA512_224, sha512.New512_224)
	RegisterHash(SHA512_256, sha512.New512_256)
	RegisterHash(SM3, sm3.New)
}
