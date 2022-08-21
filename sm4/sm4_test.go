package sm4

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"testing"
)

func Test_sm4Cipher(t *testing.T) {
	type args struct {
		plain  []byte
		cipher []byte
	}
	tests := []struct {
		name string
		key  []byte
		args args
	}{
		// TODO: Add test cases.
		{
			"one group",
			[]byte{0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF, 0xFE, 0xDC, 0xBA, 0x98, 0x76, 0x54, 0x32, 0x10},
			args{
				[]byte{0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF, 0xFE, 0xDC, 0xBA, 0x98, 0x76, 0x54, 0x32, 0x10},
				[]byte{0x68, 0x1E, 0xDF, 0x34, 0xD2, 0x06, 0x96, 0x5E, 0x86, 0xB3, 0xE9, 0x4F, 0x53, 0x6E, 0x42, 0x46},
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c, err := NewCipher(tt.key)
			if err != nil {
				t.Error("Wrong init cipher")
			}
			r := make([]byte, c.BlockSize())
			c.Encrypt(r, tt.args.plain)
			for i, v := range r {
				if v != tt.args.cipher[i] {
					t.Errorf("Wrong cipher, enc[%d] = %x, expecting %x", i, v, tt.args.cipher[i])
				}
			}
			c.Decrypt(r, tt.args.cipher)
			for i, v := range r {
				if v != tt.args.plain[i] {
					t.Errorf("Wrong plain, dec[%d] = %x, expecting %x", i, v, tt.args.plain[i])
				}
			}
		})
	}
}
func Test_sm4Cipher1M(t *testing.T) {
	type args struct {
		plain  []byte
		cipher []byte
	}
	tests := []struct {
		name string
		key  []byte
		args args
	}{
		// TODO: Add test cases.
		{
			"one group",
			[]byte{0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF, 0xFE, 0xDC, 0xBA, 0x98, 0x76, 0x54, 0x32, 0x10},
			args{
				[]byte{0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF, 0xFE, 0xDC, 0xBA, 0x98, 0x76, 0x54, 0x32, 0x10},
				[]byte{0x59, 0x52, 0x98, 0xC7, 0xC6, 0xFD, 0x27, 0x1F, 0x04, 0x02, 0xF8, 0x04, 0xC3, 0x3D, 0x3F, 0x66},
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c, err := NewCipher(tt.key)
			if err != nil {
				t.Error("Wrong init cipher")
			}
			in := make([]byte, c.BlockSize())
			out := make([]byte, c.BlockSize())
			in = tt.args.plain
			for i := 0; i < 1000000; i++ {
				c.Encrypt(out, in)
				in = out
			}
			for i, v := range out {
				if v != tt.args.cipher[i] {
					t.Errorf("Wrong cipher, enc[%d] = %x, expecting %x", i, v, tt.args.cipher[i])
				}
			}
			in = tt.args.cipher
			for i := 0; i < 1000000; i++ {
				c.Decrypt(out, in)
				in = out
			}
			for i, v := range out {
				if v != tt.args.plain[i] {
					t.Errorf("Wrong plain, dec[%d] = %x, expecting %x", i, v, tt.args.plain[i])
				}
			}
		})
	}
}

var cycle = 100
var key []byte
var src [][]byte
var dst [][]byte

func init() {
	key = make([]byte, 16)
	rand.Read(key)
	src = make([][]byte, cycle)
	dst = make([][]byte, cycle)
	for i := 0; i < cycle; i++ {
		src[i] = make([]byte, BlockSize)
		rand.Read(src[i])
		dst[i] = make([]byte, BlockSize)
		//rand.Read(dst[i])
	}
}

func BenchmarkSM4(b *testing.B) {
	for i := 0; i < b.N; i++ {
		c, _ := NewCipher(key)
		for j := 0; j < cycle; j++ {
			c.Encrypt(dst[j], src[j])
			c.Decrypt(src[j], dst[j])
		}
	}
}

func BenchmarkAES(b *testing.B) {
	for i := 0; i < b.N; i++ {
		c, _ := aes.NewCipher(key)
		for j := 0; j < cycle; j++ {
			c.Encrypt(dst[j], src[j])
			c.Decrypt(src[j], dst[j])
		}
	}
}

func BenchmarkAESCBCEncrypt1K(b *testing.B) {
	buf := make([]byte, 1024)
	b.SetBytes(int64(len(buf)))

	var key [16]byte
	var iv [16]byte
	aes, _ := aes.NewCipher(key[:])
	cbc := cipher.NewCBCEncrypter(aes, iv[:])
	for i := 0; i < b.N; i++ {
		cbc.CryptBlocks(buf, buf)
	}
}

func BenchmarkAESCBCDecrypt1K(b *testing.B) {
	buf := make([]byte, 1024)
	b.SetBytes(int64(len(buf)))

	var key [16]byte
	var iv [16]byte
	aes, _ := aes.NewCipher(key[:])
	cbc := cipher.NewCBCDecrypter(aes, iv[:])
	for i := 0; i < b.N; i++ {
		cbc.CryptBlocks(buf, buf)
	}
}

func BenchmarkSM4CBCEncrypt1K(b *testing.B) {
	buf := make([]byte, 1024)
	b.SetBytes(int64(len(buf)))

	var key [16]byte
	var iv [16]byte
	sm4, _ := NewCipher(key[:])
	cbc := cipher.NewCBCEncrypter(sm4, iv[:])
	for i := 0; i < b.N; i++ {
		cbc.CryptBlocks(buf, buf)
	}
}

func BenchmarkSM4CBCDecrypt1K(b *testing.B) {
	buf := make([]byte, 1024)
	b.SetBytes(int64(len(buf)))

	var key [16]byte
	var iv [16]byte
	sm4, _ := NewCipher(key[:])
	cbc := cipher.NewCBCDecrypter(sm4, iv[:])
	for i := 0; i < b.N; i++ {
		cbc.CryptBlocks(buf, buf)
	}
}
