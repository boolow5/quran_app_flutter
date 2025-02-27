package logger

import (
	"os"

	log "github.com/sirupsen/logrus"
)

type Fields log.Fields

func Setup() {

	// log.SetFormatter(&log.JSONFormatter{
	// 	TimestampFormat: "2006-01-02 15:04",
	// 	PrettyPrint:     true,
	// })

	log.SetOutput(os.Stdout)
	// log.SetLevel(log.DebugLevel)
	log.SetLevel(log.InfoLevel)
}

func Info(args ...interface{}) {
	log.Info(args...)
}

func Infof(format string, args ...interface{}) {
	log.Infof(format, args...)
}

func Debug(args ...interface{}) {
	log.Debug(args...)
}

func Debugf(format string, args ...interface{}) {
	log.Debugf(format, args...)
}

func Warn(args ...interface{}) {
	log.Warn(args...)
}

func Warnf(format string, args ...interface{}) {
	log.Warnf(format, args...)
}

func Fatal(args ...interface{}) {
	log.Fatal(args...)
}

func Fatalf(format string, args ...interface{}) {
	log.Fatalf(format, args...)
}

func WithFields(fields Fields) *log.Entry {
	return log.WithFields(log.Fields(fields))
}
