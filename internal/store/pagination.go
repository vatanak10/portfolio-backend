package store

// PaginationParams holds pagination parameters
type PaginationParams struct {
	Limit  int `json:"limit"`
	Offset int `json:"offset"`
}

// PaginatedResponse holds paginated data with metadata
type PaginatedResponse[T any] struct {
	Data       []T                `json:"data"`
	Pagination PaginationMetadata `json:"pagination"`
}

// PaginationMetadata holds pagination metadata
type PaginationMetadata struct {
	Limit      int  `json:"limit"`
	Offset     int  `json:"offset"`
	Total      int  `json:"total"`
	TotalPages int  `json:"total_pages"`
	HasNext    bool `json:"has_next"`
	HasPrev    bool `json:"has_prev"`
}

// NewPaginationParams creates pagination parameters with defaults
func NewPaginationParams(limit, offset int) PaginationParams {
	if limit <= 0 || limit > 100 {
		limit = 10 // Default limit
	}
	if offset < 0 {
		offset = 0
	}
	return PaginationParams{
		Limit:  limit,
		Offset: offset,
	}
}

// NewPaginationMetadata creates pagination metadata
func NewPaginationMetadata(limit, offset, total int) PaginationMetadata {
	totalPages := (total + limit - 1) / limit // Ceiling division
	if totalPages < 1 {
		totalPages = 1
	}

	return PaginationMetadata{
		Limit:      limit,
		Offset:     offset,
		Total:      total,
		TotalPages: totalPages,
		HasNext:    offset+limit < total,
		HasPrev:    offset > 0,
	}
}
