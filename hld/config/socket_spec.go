package config

import (
	"fmt"
	"runtime"
	"strconv"
	"strings"
)

// SocketSpec describes how to connect to the daemon socket.
type SocketSpec struct {
	// Network is passed to net.Listen/net.Dial (e.g. "unix" or "tcp").
	Network string
	// Address is the address component for the chosen network.
	Address string
	// Raw preserves the user-provided value (after home expansion for paths).
	Raw string
}

// ParseSocketSpec translates a socket path/config string into a concrete
// network/address tuple that net.Dial/net.Listen can understand.
func ParseSocketSpec(raw string) (SocketSpec, error) {
	value := strings.TrimSpace(raw)
	if value == "" {
		return SocketSpec{}, fmt.Errorf("socket path cannot be empty")
	}

	// Explicit tcp:// prefix always wins.
	if strings.HasPrefix(value, "tcp://") {
		address := strings.TrimPrefix(value, "tcp://")
		if address == "" {
			return SocketSpec{}, fmt.Errorf("tcp socket address cannot be empty")
		}
		return SocketSpec{
			Network: "tcp",
			Address: address,
			Raw:     value,
		}, nil
	}

	// Bare host:port on Windows defaults to TCP (avoid confusing with drive letters).
	if runtime.GOOS == "windows" && looksLikeTCPAddress(value) {
		return SocketSpec{
			Network: "tcp",
			Address: value,
			Raw:     value,
		}, nil
	}

	// Fallback to Unix-style socket path (expanded to absolute path if ~ is present).
	expanded := expandHome(value)
	return SocketSpec{
		Network: "unix",
		Address: expanded,
		Raw:     expanded,
	}, nil
}

func looksLikeTCPAddress(value string) bool {
	// Avoid treating Windows drive letters or UNC paths as TCP addresses.
	if strings.ContainsAny(value, `/\`) {
		return false
	}

	idx := strings.LastIndex(value, ":")
	if idx <= 0 || idx == len(value)-1 {
		return false
	}

	portStr := value[idx+1:]
	if _, err := strconv.Atoi(portStr); err != nil {
		return false
	}
	return true
}
