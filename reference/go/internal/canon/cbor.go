package canon

import (
	"bytes"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"sort"
	"strconv"
)

func Encode(value any) ([]byte, error) {
	switch value := value.(type) {
	case json.Number:
		parsed, err := strconv.ParseUint(string(value), 10, 64)
		if err != nil {
			return nil, fmt.Errorf("only unsigned integers are supported: %w", err)
		}
		return encodeHead(0, parsed), nil
	case string:
		body := []byte(value)
		return append(encodeHead(3, uint64(len(body))), body...), nil
	case []any:
		out := encodeHead(4, uint64(len(value)))
		for _, item := range value {
			encoded, err := Encode(item)
			if err != nil {
				return nil, err
			}
			out = append(out, encoded...)
		}
		return out, nil
	case map[string]any:
		type entry struct{ key, value []byte }
		entries := make([]entry, 0, len(value))
		for key, item := range value {
			encodedKey, _ := Encode(key)
			encodedValue, err := Encode(item)
			if err != nil {
				return nil, err
			}
			entries = append(entries, entry{encodedKey, encodedValue})
		}
		sort.Slice(entries, func(i, j int) bool {
			if len(entries[i].key) != len(entries[j].key) {
				return len(entries[i].key) < len(entries[j].key)
			}
			return bytes.Compare(entries[i].key, entries[j].key) < 0
		})
		out := encodeHead(5, uint64(len(entries)))
		for _, entry := range entries {
			out = append(out, entry.key...)
			out = append(out, entry.value...)
		}
		return out, nil
	default:
		return nil, fmt.Errorf("unsupported deterministic-CBOR value %T", value)
	}
}

func encodeHead(major byte, value uint64) []byte {
	prefix := major << 5
	switch {
	case value < 24:
		return []byte{prefix | byte(value)}
	case value <= 0xff:
		return []byte{prefix | 24, byte(value)}
	case value <= 0xffff:
		out := []byte{prefix | 25, 0, 0}
		binary.BigEndian.PutUint16(out[1:], uint16(value))
		return out
	case value <= 0xffff_ffff:
		out := []byte{prefix | 26, 0, 0, 0, 0}
		binary.BigEndian.PutUint32(out[1:], uint32(value))
		return out
	default:
		out := []byte{prefix | 27, 0, 0, 0, 0, 0, 0, 0, 0}
		binary.BigEndian.PutUint64(out[1:], value)
		return out
	}
}
