package daemon

import (
	"net"
	"os"
	"testing"

	"github.com/humanlayer/humanlayer/hld/config"
)

func dialSocket(t *testing.T, socketPath string) net.Conn {
	t.Helper()

	spec, err := config.ParseSocketSpec(socketPath)
	if err != nil {
		t.Fatalf("failed to parse socket path %s: %v", socketPath, err)
	}

	conn, err := net.Dial(spec.Network, spec.Address)
	if err != nil {
		t.Fatalf("failed to connect to daemon at %s: %v", spec.Raw, err)
	}

	return conn
}

func socketShouldBeRemoved(t *testing.T, socketPath string) {
	t.Helper()

	spec, err := config.ParseSocketSpec(socketPath)
	if err != nil {
		t.Fatalf("failed to parse socket path %s: %v", socketPath, err)
	}

	if spec.Network == "unix" {
		if _, err := os.Stat(spec.Address); !os.IsNotExist(err) {
			t.Error("socket file not cleaned up after shutdown")
		}
	}
}
