package sm4

// Encrypt one block from src into dst, using the expanded key xk.
func encryptBlock(xk []uint32, dst, src []byte) {
	var s0, s1, s2, s3, t0 uint32

	s0 = uint32(src[0])<<24 | uint32(src[1])<<16 | uint32(src[2])<<8 | uint32(src[3])
	s1 = uint32(src[4])<<24 | uint32(src[5])<<16 | uint32(src[6])<<8 | uint32(src[7])
	s2 = uint32(src[8])<<24 | uint32(src[9])<<16 | uint32(src[10])<<8 | uint32(src[11])
	s3 = uint32(src[12])<<24 | uint32(src[13])<<16 | uint32(src[14])<<8 | uint32(src[15])

	for r := 0; r < 32; r++ {
		t0 = s1 ^ s2 ^ s3 ^ xk[r]
		t0 = s0 ^ te0[uint8(t0>>24)] ^ te1[uint8(t0>>16)] ^ te2[uint8(t0>>8)] ^ te3[uint8(t0)]
		s0 = s1
		s1 = s2
		s2 = s3
		s3 = t0
	}

	dst[0], dst[1], dst[2], dst[3] = byte(s3>>24), byte(s3>>16), byte(s3>>8), byte(s3)
	dst[4], dst[5], dst[6], dst[7] = byte(s2>>24), byte(s2>>16), byte(s2>>8), byte(s2)
	dst[8], dst[9], dst[10], dst[11] = byte(s1>>24), byte(s1>>16), byte(s1>>8), byte(s1)
	dst[12], dst[13], dst[14], dst[15] = byte(s0>>24), byte(s0>>16), byte(s0>>8), byte(s0)
}

// Decrypt one block from src into dst, using the expanded key xk.
func decryptBlock(xk []uint32, dst, src []byte) {
	var s0, s1, s2, s3, t0 uint32

	s0 = uint32(src[0])<<24 | uint32(src[1])<<16 | uint32(src[2])<<8 | uint32(src[3])
	s1 = uint32(src[4])<<24 | uint32(src[5])<<16 | uint32(src[6])<<8 | uint32(src[7])
	s2 = uint32(src[8])<<24 | uint32(src[9])<<16 | uint32(src[10])<<8 | uint32(src[11])
	s3 = uint32(src[12])<<24 | uint32(src[13])<<16 | uint32(src[14])<<8 | uint32(src[15])

	for r := 31; r >= 0; r-- {
		t0 = s1 ^ s2 ^ s3 ^ xk[r]
		t0 = s0 ^ te0[uint8(t0>>24)] ^ te1[uint8(t0>>16)] ^ te2[uint8(t0>>8)] ^ te3[uint8(t0)]
		s0 = s1
		s1 = s2
		s2 = s3
		s3 = t0
	}

	dst[0], dst[1], dst[2], dst[3] = byte(s3>>24), byte(s3>>16), byte(s3>>8), byte(s3)
	dst[4], dst[5], dst[6], dst[7] = byte(s2>>24), byte(s2>>16), byte(s2>>8), byte(s2)
	dst[8], dst[9], dst[10], dst[11] = byte(s1>>24), byte(s1>>16), byte(s1>>8), byte(s1)
	dst[12], dst[13], dst[14], dst[15] = byte(s0>>24), byte(s0>>16), byte(s0>>8), byte(s0)
}

// Key expansion algorithm.
func (c *sm4Cipher) expandKey(key []byte) {
	var k0, k1, k2, k3, t0, t1, t2, t3 uint32

	k0 = (uint32(key[0]) << 24) | (uint32(key[1]) << 16) | (uint32(key[2]) << 8) | (uint32(key[3]))
	k1 = (uint32(key[4]) << 24) | (uint32(key[5]) << 16) | (uint32(key[6]) << 8) | (uint32(key[7]))
	k2 = (uint32(key[8]) << 24) | (uint32(key[9]) << 16) | (uint32(key[10]) << 8) | (uint32(key[11]))
	k3 = (uint32(key[12]) << 24) | (uint32(key[13]) << 16) | (uint32(key[14]) << 8) | (uint32(key[15]))

	k0 = k0 ^ sm4Fk[0]
	k1 = k1 ^ sm4Fk[1]
	k2 = k2 ^ sm4Fk[2]
	k3 = k3 ^ sm4Fk[3]

	for i := 0; i < 32; i++ {
		t0 = k1 ^ k2 ^ k3 ^ sm4Ck[i]
		t1 = uint32(sbox[uint8(t0>>24)])<<24 ^ uint32(sbox[uint8(t0>>16)])<<16 ^ uint32(sbox[uint8(t0>>8)])<<8 ^ uint32(sbox[uint8(t0)])
		t2 = (t1 << 23) ^ (t1 >> 9)
		t3 = (t1 << 13) ^ (t1 >> 19)
		c.subkeys[i] = k0 ^ t1 ^ t2 ^ t3
		k0 = k1
		k1 = k2
		k2 = k3
		k3 = c.subkeys[i]
	}
}
