package main

import (
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/vatanak10/portfolio-backend/internal/store"
)

type experiencePayload struct {
	Title       string   `json:"title" validate:"required"`
	Description []string `json:"description" validate:"required"`
	Company     string   `json:"company" validate:"required"`
	StartDate   string   `json:"start_date" validate:"required"`
	EndDate     string   `json:"end_date" validate:"required"`
}

func (app *application) createExperienceHandler(w http.ResponseWriter, r *http.Request) {
	var payload experiencePayload

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

	// Check if pagination parameters are provided
	limitStr := r.URL.Query().Get("limit")
	offsetStr := r.URL.Query().Get("offset")

	var result *store.PaginatedResponse[*store.Experience]
	var err error

	// If pagination parameters are provided, use them
	if limitStr != "" || offsetStr != "" {
		limit, err := strconv.Atoi(limitStr)
		if err != nil || limit <= 0 {
			limit = 10 // Default limit
		}

		offset, err := strconv.Atoi(offsetStr)
		if err != nil || offset < 0 {
			offset = 0 // Default offset
		}

		params := store.NewPaginationParams(limit, offset)
		result, err = app.store.Experiences.List(ctx, params)

		if err != nil {
			app.internalServerError(w, r, err)
			return
		}
	} else {
		// No pagination parameters - get all results
		result, err = app.store.Experiences.List(ctx)
	}

	if err != nil {
		app.internalServerError(w, r, err)
		return
	}

	// Return the result
	if err := writeJSON(w, http.StatusOK, result); err != nil {
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

func (app *application) updateExperienceHandler(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	var payload experiencePayload

	if err := readJSON(w, r, &payload); err != nil {
		app.badRequestResponse(w, r, err)
		return
	}

	if err := Validate.Struct(payload); err != nil {
		app.badRequestResponse(w, r, err)
		return
	}

	ctx := r.Context()

	experience, err := app.store.Experiences.Get(ctx, id)
	if err != nil {
		app.notFoundResponse(w, r, err)
		return
	}

	experience.Title = payload.Title
	experience.Description = payload.Description
	experience.Company = payload.Company
	experience.StartDate = payload.StartDate
	experience.EndDate = payload.EndDate

	// Convert id from string to int64
	idInt, err := strconv.ParseInt(id, 10, 64)
	if err != nil {
		app.badRequestResponse(w, r, err)
		return
	}
	experience.ID = idInt

	if err := app.store.Experiences.Update(ctx, experience); err != nil {
		app.internalServerError(w, r, err)
		return
	}

	if err := app.jsonResponse(w, http.StatusOK, experience); err != nil {
		app.internalServerError(w, r, err)
		return
	}
}

func (app *application) deleteExperienceHandler(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	ctx := r.Context()

	if err := app.store.Experiences.Delete(ctx, id); err != nil {
		app.notFoundResponse(w, r, err)
		return
	}

	if err := app.jsonResponse(w, http.StatusOK, map[string]string{"message": "deleted successfully"}); err != nil {
		app.internalServerError(w, r, err)
		return
	}
}
