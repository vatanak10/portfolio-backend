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
	// Implement the logic to create an experience in the database
	// This is a placeholder implementation

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
