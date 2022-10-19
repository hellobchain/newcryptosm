package ecdsa_test

import (
	"github.com/hellobchain/newcryptosm/ecdsa"
	"github.com/hellobchain/newcryptosm/sm2"
	"math/big"
	"testing"
)

func TestStandardData(t *testing.T) {
	priv := &ecdsa.PrivateKey{}
	priv.Curve = sm2.SM2()
	priv.D, _ = new(big.Int).SetString("3945208F7B2144B13F36E38AC6D39F95889393692860B51A42FB81EF4DF7C5B8", 16)
	priv.X, priv.Y = priv.ScalarBaseMult(priv.D.Bytes())

	expPubX, _ := new(big.Int).SetString("09F9DF311E5421A150DD7D161E4BC5C672179FAD1833FC076BB08FF356F35020", 16)
	expPubY, _ := new(big.Int).SetString("CCEA490CE26775A52DC6EA718CC1AA600AED05FBF35E084A6632F6072DA9AD13", 16)
	if priv.X.Cmp(expPubX) != 0 || priv.Y.Cmp(expPubY) != 0 {
		t.Fatal("public key is not equal")
	}

	message := []byte("message digest")

	r, _ := new(big.Int).SetString("F5A03B0648D2C4630EEAC513E1BB81A15944DA3827D5B74143AC7EACEEE720B3", 16)
	s, _ := new(big.Int).SetString("B1B6AA29DF212FD8763182BC0D421CA1BB9038FD1F7F42D4840B69C485BBC1AA", 16)

	if verify := ecdsa.Verify(&priv.PublicKey, message, r, s); !verify {
		t.Fatal("verify fail")
	}
}
