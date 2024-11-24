package config

import (
	"os"
	"testing"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

const (
	testValidConfig = `
db:
  type: "psql"
  host: "postgres:5432"
  name: "accounting_db"
  user: "pguser"
  password: "pgpwd"
logger:
  level: "debug"
users:
  - pass: "1234"
    role: user
  - pass: "0123"
    role: admin
roles:
  - name: admin
    wrights: [read, write, modify, delete]
  - name: user
    wrights: [read]
`
	testInvalidConfig = `
\db:
  type: "psql"
  host: "po
    wrights: [read]
`
)

var (
	testExpectedConfig = Config{
		DbConfig: DbConfig{
			Type:     "psql",
			Host:     "postgres:5432",
			Name:     "accounting_db",
			User:     "pguser",
			Password: "pgpwd",
		},
		LoggerConfig: LoggerConfig{
			Level: "debug",
		},
		Users: []User{
			{
				Pass: "1234",
				Role: "user",
			},
			{
				Pass: "0123",
				Role: "admin",
			},
		},
		Roles: []Role{
			{
				Name:    "admin",
				Wrights: []string{"read", "write", "modify", "delete"},
			},
			{
				Name:    "user",
				Wrights: []string{"read"},
			},
		},
	}
)

func TestConfig(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Config Suite")
}

var _ = Describe("Config", func() {
	Context("ReadConfigFromYAML", func() {
		var (
			configFile *os.File
		)

		BeforeEach(func() {
			tempDir := GinkgoT().TempDir()
			var err error
			configFile, err = os.Create(tempDir + "/config.yaml")
			Expect(err).To(Succeed())

			DeferCleanup(func() {
				configFile.Close()
			})
		})

		It("Sunny", func() {
			_, err := configFile.Write([]byte(testValidConfig))
			Expect(err).To(Succeed())

			conf, err := ReadConfigFromYAML[Config](configFile.Name())
			Expect(err).To(Succeed())
			Expect(*conf).To(Equal(testExpectedConfig))
		})

		It("Rainy", func() {
			_, err := configFile.Write([]byte(testInvalidConfig))
			Expect(err).To(Succeed())

			_, err = ReadConfigFromYAML[Config](configFile.Name())
			Expect(err).NotTo(Succeed())
		})
	})

	Context("ValidateConfig", func() {
		It("Sunny", func() {
			Expect(ValidateConfig(&testExpectedConfig)).To(Succeed())
		})

		It("Rainy", func() {
			invalidConfig := testExpectedConfig
			invalidConfig.Roles = []Role{{Name: "some", Wrights: []string{"unknown"}}}
			Expect(ValidateConfig(&invalidConfig)).NotTo(Succeed())
		})
	})
})
