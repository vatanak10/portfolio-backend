package store

import (
	"context"
	"database/sql"

	"github.com/lib/pq"
)

type Experience struct {
	ID          int64    `json:"id"`
	Title       string   `json:"title"`
	Description []string `json:"description"`
	Company     string   `json:"company"`
	StartDate   string   `json:"start_date"`
	EndDate     string   `json:"end_date"`
	CreatedAt   string   `json:"created_at"`
	UpdatedAt   string   `json:"updated_at"`
}

type ExperiencesStore struct {
	// Define methods for the ExperiencesStore
	db *sql.DB
}

func (s *ExperiencesStore) Create(ctx context.Context, experience *Experience) error {

	query := `INSERT INTO experiences (title, description, company, start_date, end_date) 
			  VALUES ($1, $2, $3, $4, $5) RETURNING id, created_at, updated_at`

	err := s.db.QueryRowContext(ctx, query,
		experience.Title, pq.Array(experience.Description), experience.Company,
		experience.StartDate, experience.EndDate).Scan(&experience.ID, &experience.CreatedAt, &experience.UpdatedAt)

	if err != nil {
		return err
	}

	return nil
}

func (s *ExperiencesStore) List(ctx context.Context) ([]*Experience, error) {
	query := `SELECT id, title, description, company, start_date, end_date, created_at, updated_at 
			  FROM experiences ORDER BY created_at DESC`

	rows, err := s.db.QueryContext(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var experiences []*Experience
	for rows.Next() {
		var experience Experience
		if err := rows.Scan(&experience.ID, &experience.Title, pq.Array(&experience.Description),
			&experience.Company, &experience.StartDate, &experience.EndDate,
			&experience.CreatedAt, &experience.UpdatedAt); err != nil {
			return nil, err
		}
		experiences = append(experiences, &experience)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return experiences, nil
}
