// CA-Certificates Bundler
package main

import (
	"bytes"
	"encoding/pem"
	"fmt"
	"io"
	"os"
	"slices"

	"github.com/Luzifer/rconfig/v2"
	"github.com/sirupsen/logrus"
	"golang.org/x/crypto/x509roots/nss"
)

var (
	cfg = struct {
		Input          string `flag:"input,i" default:"certdata.txt" description:"NSS provided certdata.txt"`
		LogLevel       string `flag:"log-level" default:"info" description:"Log level (debug, info, warn, error, fatal)"`
		Output         string `flag:"output,o" default:"-" description:"Where to write the PEM list ('-' for stdout)"`
		VersionAndExit bool   `flag:"version" default:"false" description:"Prints current version and exits"`
	}{}

	version = "dev"
)

func initApp() error {
	rconfig.AutoEnv(true)
	if err := rconfig.ParseAndValidate(&cfg); err != nil {
		return fmt.Errorf("parsing cli options: %w", err)
	}

	l, err := logrus.ParseLevel(cfg.LogLevel)
	if err != nil {
		return fmt.Errorf("parsing log-level: %w", err)
	}
	logrus.SetLevel(l)

	return nil
}

func main() {
	var err error
	if err = initApp(); err != nil {
		logrus.WithError(err).Fatal("initializing app")
	}

	if cfg.VersionAndExit {
		logrus.WithField("version", version).Info("ca-certificates builder")
		os.Exit(0)
	}

	infile, err := os.Open(cfg.Input)
	if err != nil {
		logrus.WithError(err).Fatal("opening input")
	}
	defer func() {
		_ = infile.Close() // Will be closed by process exit either way
	}()

	var output io.WriteCloser = os.Stdout
	if cfg.Output != "-" {
		if output, err = os.Create(cfg.Output); err != nil {
			logrus.WithError(err).Fatal("opening output")
		}
	}

	certs, err := nss.Parse(infile)
	if err != nil {
		logrus.WithError(err).Fatal("parsing input")
	}

	slices.SortFunc(certs, func(a, b *nss.Certificate) int {
		// Body of certs cannot be equal or they would be the SAME cert
		// so we take the comparison of the body to create a stable order
		return bytes.Compare(a.X509.Raw, b.X509.Raw)
	})

	for _, cert := range certs {
		if err = pem.Encode(output, &pem.Block{
			Type:  "CERTIFICATE",
			Bytes: cert.X509.Raw,
		}); err != nil {
			logrus.WithError(err).Fatal("encoding to pem")
		}
	}

	if err = output.Close(); err != nil {
		logrus.WithError(err).Fatal("closing output")
	}
}
