package store

import (
	"context"
	"database/sql"
)

type Storage struct {
	Experiences interface {
		Create(context.Context, *Experience) error
		List(context.Context) ([]*Experience, error)
	}
}

func NewPostgresStorage(db *sql.DB) *Storage {
	return &Storage{
		Experiences: &ExperiencesStore{
			db: db,
		},
	}
}
