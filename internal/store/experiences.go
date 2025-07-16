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

func (s *ExperiencesStore) List(ctx context.Context, params ...PaginationParams) (*PaginatedResponse[*Experience], error) {
	// First, get the total count
	countQuery := `SELECT COUNT(*) FROM experiences`

	var total int
	if err := s.db.QueryRowContext(ctx, countQuery).Scan(&total); err != nil {
		return nil, err
	}

	var query string
	var args []interface{}
	var limit, offset int

	// Check if pagination parameters are provided, if not use default values
	if len(params) > 0 && (params[0].Limit > 0 || params[0].Offset > 0) {
		// Use pagination
		p := params[0]
		limit = p.Limit
		offset = p.Offset
		query = `SELECT id, title, description, company, start_date, end_date, created_at, updated_at 
				 FROM experiences ORDER BY created_at DESC
				 LIMIT $1 OFFSET $2`
		args = []interface{}{limit, offset}
	} else {
		// No pagination - return all results
		limit = 10 // Default limit
		offset = 0
		query = `SELECT id, title, description, company, start_date, end_date, created_at, updated_at 
				 FROM experiences ORDER BY created_at DESC`
		args = []interface{}{}
	}

	rows, err := s.db.QueryContext(ctx, query, args...)
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

	// Create pagination metadata
	metadata := NewPaginationMetadata(limit, offset, total)

	return &PaginatedResponse[*Experience]{
		Data:       experiences,
		Pagination: metadata,
	}, nil
}

func (s *ExperiencesStore) Get(ctx context.Context, id string) (*Experience, error) {
	query := `SELECT id, title, description, company, start_date, end_date, created_at, updated_at 
			  FROM experiences WHERE id = $1`

	ctx, cancel := context.WithTimeout(ctx, QueryTimeoutDuration)
	defer cancel()

	var experience Experience
	if err := s.db.QueryRowContext(ctx, query, id).Scan(&experience.ID, &experience.Title, pq.Array(&experience.Description),
		&experience.Company, &experience.StartDate, &experience.EndDate,
		&experience.CreatedAt, &experience.UpdatedAt); err != nil {
		if err == sql.ErrNoRows {
			return nil, ErrNotFound
		}
		return nil, err
	}

	return &experience, nil
}

func (s *ExperiencesStore) Update(ctx context.Context, experience *Experience) error {
	query := `UPDATE experiences 
			  SET title = $1, description = $2, company = $3, start_date = $4, end_date = $5, updated_at = NOW() 
			  WHERE id = $6`

	ctx, cancel := context.WithTimeout(ctx, QueryTimeoutDuration)
	defer cancel()

	_, err := s.db.ExecContext(ctx, query,
		experience.Title, pq.Array(experience.Description), experience.Company,
		experience.StartDate, experience.EndDate, experience.ID)

	if err != nil {
		if err == sql.ErrNoRows {
			return ErrNotFound
		}
		return err
	}

	return nil
}

func (s *ExperiencesStore) Delete(ctx context.Context, id string) error {
	query := `DELETE FROM experiences WHERE id = $1`

	ctx, cancel := context.WithTimeout(ctx, QueryTimeoutDuration)
	defer cancel()

	_, err := s.db.ExecContext(ctx, query, id)

	if err != nil {
		if err == sql.ErrNoRows {
			return ErrNotFound
		}
		return err
	}

	return nil
}
