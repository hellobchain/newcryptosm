package ecdsa

import (
	"bytes"
	"encoding/binary"
	"github.com/hellobchain/newcryptosm/sm2"
	"github.com/hellobchain/newcryptosm/sm3"
	"math/big"
)

func big2Bytes(big *big.Int) []byte {
	r := make([]byte, 32)
	bigBytes := big.Bytes()
	copy(r[32-len(bigBytes):], bigBytes)
	return r
}

func GetZ(key *PublicKey) []byte {
	return GetZWithID(key, []byte("1234567812345678"))
}

func msgHash(za, msg []byte) *big.Int {
	e := sm3.New()
	e.Write(za)
	e.Write(msg)
	return new(big.Int).SetBytes(e.Sum(nil)[:32])
}

func GetEWithID(key *PublicKey, msg []byte, uid []byte) *big.Int {
	za := GetZWithID(key, uid)
	return msgHash(za, msg)
}

func GetE(key *PublicKey, msg []byte) *big.Int {
	za := GetZ(key)
	return msgHash(za, msg)
}

func GetZWithID(key *PublicKey, id []byte) []byte {
	entl := make([]byte, 2)
	binary.BigEndian.PutUint16(entl, uint16(len(id)*8))
	a := big2Bytes(new(big.Int).Sub(key.Curve.Params().P, new(big.Int).SetInt64(3)))
	b := big2Bytes(key.Curve.Params().B)
	xG := big2Bytes(key.Curve.Params().Gx)
	yG := big2Bytes(key.Curve.Params().Gy)
	x := big2Bytes(key.X)
	y := big2Bytes(key.Y)
	h := sm3.New()
	h.Write(entl)
	h.Write(id)
	h.Write(a)
	h.Write(b)
	h.Write(xG)
	h.Write(yG)
	h.Write(x)
	h.Write(y)
	return h.Sum(nil)
}

func getZBefore(uidValue []byte) []byte {
	uidValueLen := len(uidValue)
	var entl []byte
	var zHashLen int
	if uidValueLen != 0 {
		zHashLen = 6
		entl = make([]byte, 2)
		binary.BigEndian.PutUint16(entl, uint16(uidValueLen<<3))
	} else {
		zHashLen = 4
		entl = nil
	}

	a := big2Bytes(new(big.Int).Sub(sm2.SM2().Params().P, new(big.Int).SetInt64(3)))
	b := big2Bytes(sm2.SM2().Params().B)
	xG := big2Bytes(sm2.SM2().Params().Gx)
	yG := big2Bytes(sm2.SM2().Params().Gy)
	zHashed := make([][]byte, zHashLen)
	if zHashLen == 4 {
		zHashed[0] = a
		zHashed[1] = b
		zHashed[2] = xG
		zHashed[3] = yG
	} else {
		zHashed[0] = entl
		zHashed[1] = uidValue
		zHashed[2] = a
		zHashed[3] = b
		zHashed[4] = xG
		zHashed[5] = yG
	}
	return bytes.Join(zHashed, nil)
}
