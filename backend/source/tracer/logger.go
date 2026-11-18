package tracer

import (
	"context"
	"log"
	"sync"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

type contextKey string

const RequestIdKey contextKey = "requestId"
const UserIdKey contextKey = "userId"

var (
	logger *zap.SugaredLogger
	once   sync.Once
)

func Errorf(ctx context.Context, format string, args ...interface{}) {
	WithContext(ctx).Errorf(format, args...)
}

func Infof(ctx context.Context, format string, args ...interface{}) {
	WithContext(ctx).Infof(format, args...)
}

func Debugf(ctx context.Context, format string, args ...interface{}) {
	WithContext(ctx).Debugf(format, args...)
}

func Warnf(ctx context.Context, format string, args ...interface{}) {
	WithContext(ctx).Warnf(format, args...)
}

func Debug(ctx context.Context, args ...interface{}) {
	WithContext(ctx).Debug(args...)
}

func Fatal(ctx context.Context, args ...interface{}) {
	WithContext(ctx).Fatal(args...)
}

func WithContext(ctx context.Context) *zap.SugaredLogger {
	once.Do(func() {
		logger = initLogger()
	})
	l := logger
	if requestId, ok := ctx.Value(RequestIdKey).(string); ok {
		l = l.With("requestId", requestId)
	}
	if userId, ok := ctx.Value(UserIdKey).(int64); ok {
		l = l.With("userId", userId)
	}
	return l
}

func initLogger() *zap.SugaredLogger {
	config := zap.Config{
		Level:       zap.NewAtomicLevelAt(zapcore.DebugLevel),
		Development: false,
		Encoding:    "console",
		EncoderConfig: zapcore.EncoderConfig{
			MessageKey:       "message",
			LevelKey:         "level",
			TimeKey:          "timestamp",
			NameKey:          "name",
			CallerKey:        "caller",
			StacktraceKey:    "stack",
			LineEnding:       "\n",
			EncodeLevel:      zapcore.CapitalColorLevelEncoder,
			EncodeTime:       zapcore.RFC3339TimeEncoder,
			EncodeDuration:   zapcore.StringDurationEncoder,
			EncodeCaller:     zapcore.ShortCallerEncoder,
			ConsoleSeparator: " | ",
		},
		OutputPaths:      []string{"stderr"},
		ErrorOutputPaths: []string{"stderr"},
	}

	zapLogger, err := config.Build()
	if err != nil {
		log.Fatalf("Failed to initialize logger: %v", err)
	}

	return zapLogger.Sugar()
}
