package main

import (
	"net/http"

	"github.com/go-chi/chi/v5"
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

func (app *application) listExperiencesHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	experiences, err := app.store.Experiences.List(ctx)
	if err != nil {
		app.internalServerError(w, r, err)
		return
	}

	if err := app.jsonResponse(w, http.StatusOK, experiences); err != nil {
		app.internalServerError(w, r, err)
		return
	}
}

func (app *application) getExperienceHandler(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	ctx := r.Context()

	experience, err := app.store.Experiences.Get(ctx, id)
	if err != nil {
		app.notFoundResponse(w, r, err)
		return
	}

	if err := app.jsonResponse(w, http.StatusOK, experience); err != nil {
		app.internalServerError(w, r, err)
		return
	}
}
