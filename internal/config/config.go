package config

import (
	"fmt"
	"os"
	"sync"

	"github.com/go-playground/validator/v10"
	"gopkg.in/yaml.v3"
)

type Config struct {
	DbConfig     DbConfig     `yaml:"db" validate:"required"`
	LoggerConfig LoggerConfig `yaml:"logger" validate:"required"`
	Users        []User       `yaml:"users" validate:"required,dive"`
	Roles        []Role       `yaml:"roles" validate:"required,dive"`
}

type LoggerConfig struct {
	Level string `yaml:"level" validate:"required,oneof='info' 'error' 'warn' 'debug'"`
}

type DbConfig struct {
	Type     string `yaml:"type" validate:"required,oneof='psql'"`
	Host     string `yaml:"host" validate:"required"`
	Name     string `yaml:"name" validate:"required"`
	User     string `yaml:"user" validate:"required"`
	Password string `yaml:"password" validate:"required"`
}

type User struct {
	Pass string `yaml:"pass" validate:"required"`
	Role string `yaml:"role" validate:"required"`
}

type Role struct {
	Name    string   `yaml:"name"`
	Wrights []string `yaml:"wrights" validate:"required,dive,oneof=write delete modify read"`
}

var (
	validate *validator.Validate
	once     sync.Once
)

func ValidateConfig(config interface{}) error {
	once.Do(func() {
		validate = validator.New()
	})

	err := validate.Struct(config)
	if err != nil {
		return err
	}
	return nil
}

func ReadConfigFromYAML[T any](path string) (*T, error) {
	file, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read file from %s, due to: %w", path, err)
	}
	var conf T
	err = yaml.Unmarshal(file, &conf)
	if err != nil {
		return nil, fmt.Errorf("failed to parse config from %s, due to: %w", path, err)
	}

	return &conf, nil
}
