package main

import (
	"log"

	"go.uber.org/zap"

	"github.com/vatanak10/portfolio-backend/internal/db"
	"github.com/vatanak10/portfolio-backend/internal/env"
	"github.com/vatanak10/portfolio-backend/internal/store"
)

func main() {

	cfg := config{
		addr: env.GetString("ADDR", ":8080"),
		db: dbConfig{
			addr:         env.GetString("DB_ADDR", "postgres://admin:password@localhost:5432/portfolio?sslmode=disable"),
			maxOpenConns: env.GetInt("DB_MAX_OPEN_CONNS", 30),
			maxIdleConns: env.GetInt("DB_MAX_IDLE_CONNS", 30),
			maxIdleTime:  env.GetString("DB_MAX_IDLE_TIME", "15m"),
		},
	}

	db, err := db.New(
		cfg.db.addr,
		cfg.db.maxOpenConns,
		cfg.db.maxIdleConns,
		cfg.db.maxIdleTime,
	)

	if err != nil {
		log.Panic(err)
	}

	defer db.Close()
	log.Println("Connected to database.")

	store := store.NewPostgresStorage(db)

	logger, err := zap.NewProduction()
	if err != nil {
		log.Panic(err)
	}
	defer logger.Sync()

	app := &application{config: cfg, store: store, logger: logger.Sugar()}

	mux := app.mount()

	log.Fatal(app.run(mux))

}
