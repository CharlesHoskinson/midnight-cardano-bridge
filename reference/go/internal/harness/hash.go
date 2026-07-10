package harness

import (
	"crypto/sha256"
	"encoding/binary"
)

func framedDigest(domain string, body []byte) ([]byte, [32]byte) {
	preimage := make([]byte, 0, 16+len(domain)+len(body))
	length := make([]byte, 8)
	binary.BigEndian.PutUint64(length, uint64(len(domain)))
	preimage = append(preimage, length...)
	preimage = append(preimage, domain...)
	binary.BigEndian.PutUint64(length, uint64(len(body)))
	preimage = append(preimage, length...)
	preimage = append(preimage, body...)
	return preimage, sha256.Sum256(preimage)
}
