package store

import (
	"context"
	"database/sql"
	"errors"
	"time"
)

var (
	ErrNotFound          = errors.New("resource not found")
	ErrConflict          = errors.New("resource already exists")
	QueryTimeoutDuration = time.Second * 5
)

type Storage struct {
	Experiences interface {
		Create(context.Context, *Experience) error
		List(context.Context, ...PaginationParams) (*PaginatedResponse[*Experience], error)
		Get(context.Context, string) (*Experience, error)
		Update(context.Context, *Experience) error
		Delete(context.Context, string) error
	}
}

func NewPostgresStorage(db *sql.DB) *Storage {
	return &Storage{
		Experiences: &ExperiencesStore{
			db: db,
		},
	}
}
