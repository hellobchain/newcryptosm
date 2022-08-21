package sm4

import (
	"crypto/cipher"
	"strconv"
)

// BlockSize if the SM4 block size in bytes.
const BlockSize = 16

//KeySizeError is the error for wrong key size
type KeySizeError int

func (k KeySizeError) Error() string {
	return "sm4: invalid key size " + strconv.Itoa(int(k))
}

// sm4Cipher is an instance of SM4 encryption.
type sm4Cipher struct {
	subkeys [32]uint32
}

// NewCipher creates and returns a new cipher.Block.
func NewCipher(key []byte) (cipher.Block, error) {
	if len(key) != 16 {
		return nil, KeySizeError(len(key))
	}

	c := new(sm4Cipher)
	c.expandKey(key)
	return c, nil
}

func (c *sm4Cipher) BlockSize() int { return BlockSize }

func (c *sm4Cipher) Encrypt(dst, src []byte) { encryptBlock(c.subkeys[:], dst, src) }

func (c *sm4Cipher) Decrypt(dst, src []byte) { decryptBlock(c.subkeys[:], dst, src) }
