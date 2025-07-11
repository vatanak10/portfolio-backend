package main

import (
	"net/http"

	"github.com/vatanak10/portfolio-backend/internal/store"
)

type createExperiencePayload struct {
	Title       string   `json:"title" validate:"required"`
	Description []string `json:"description" validate:"required"`
	Company     string   `json:"company" validate:"required"`
	StartDate   string   `json:"start_date" validate:"required"`
	EndDate     string   `json:"end_date" validate:"required"`
}

func (app *application) createExperienceHandler(w http.ResponseWriter, r *http.Request) {
	var payload createExperiencePayload

	if err := readJSON(w, r, &payload); err != nil {
		app.badRequestResponse(w, r, err)
		return
	}

	if err := Validate.Struct(payload); err != nil {
		app.badRequestResponse(w, r, err)
		return
	}

	experience := &store.Experience{
		Title:       payload.Title,
		Description: payload.Description,
		Company:     payload.Company,
		StartDate:   payload.StartDate,
		EndDate:     payload.EndDate,
	}

	ctx := r.Context()

	if err := app.store.Experiences.Create(ctx, experience); err != nil {
		app.internalServerError(w, r, err)
		return
	}

	if err := app.jsonResponse(w, http.StatusCreated, experience); err != nil {
		app.internalServerError(w, r, err)
		return
	}
}
