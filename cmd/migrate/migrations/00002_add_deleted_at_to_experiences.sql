-- +goose Up
-- +goose StatementBegin
ALTER TABLE experiences ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP NULL;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE experiences DROP COLUMN IF EXISTS deleted_at;
-- +goose StatementEnd
