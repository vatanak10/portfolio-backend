# Portfolio Backend

A Go-based backend service for a portfolio application.

## Prerequisites

- Go 1.22+
- direnv (for environment variable management)
- Air (for hot reload during development)
- Goose (for database migrations)
- PostgreSQL (database)

## Environment Setup with direnv

This project uses [direnv](https://direnv.net/) to automatically load environment variables from `.envrc` when you enter the project directory.

### Installing direnv

#### Windows (Git Bash/MINGW64)

1. Download and install direnv:

   ```bash
   mkdir -p ~/bin
   curl -L https://github.com/direnv/direnv/releases/latest/download/direnv.windows-amd64.exe -o ~/bin/direnv.exe
   chmod +x ~/bin/direnv.exe
   ```

2. Add direnv to your PATH and configure the bash hook:

   ```bash
   echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
   echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
   source ~/.bashrc
   ```

#### macOS

```bash
brew install direnv
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc  # or ~/.zshrc for zsh
source ~/.bashrc  # or ~/.zshrc
```

#### Linux

```bash
curl -sfL https://direnv.net/install.sh | bash
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
source ~/.bashrc
```

### Installing Air (Hot Reload)

Air is a live reload tool for Go applications that automatically rebuilds and restarts your application when files change.

Install Air globally using Go:

```bash
go install github.com/cosmtrek/air@latest
```

You can verify the installation by checking the version:

```bash
air -v
```

### Installing Goose (Database Migrations)

Goose is a database migration tool that supports SQL migrations and Go functions.

#### Installation

Install Goose globally using Go:

```bash
go install github.com/pressly/goose/v3/cmd/goose@latest
```

You can verify the installation by checking the version:

```bash
goose -version
```

#### Usage

Goose migrations are located in the `cmd/migrate/migrations/` directory.

**Create a new migration:**

```bash
goose -dir cmd/migrate/migrations -s create migration_name sql
```

**Run migrations:**

```bash
goose -dir cmd/migrate/migrations postgres "postgres://admin:password@localhost:5432/portfolio?sslmode=disable" up
```

**Check migration status:**

```bash
goose -dir cmd/migrate/migrations postgres "postgres://admin:password@localhost:5432/portfolio?sslmode=disable" status
```

**Rollback last migration:**

```bash
goose -dir cmd/migrate/migrations postgres "postgres://admin:password@localhost:5432/portfolio?sslmode=disable" down
```

### Using direnv in this project

1. **First time setup**: When you first clone this repository and enter the directory, direnv will show a warning that the `.envrc` file is blocked. Allow it by running:

   ```bash
   direnv allow
   ```

2. **Automatic loading**: After allowing, direnv will automatically:

   - Load environment variables when you `cd` into the project directory
   - Unload them when you leave the directory
   - Show a message like: `direnv: loading .envrc` and `direnv: export +ADDR`

3. **Editing environment variables**:
   - Edit the `.envrc` file to add or modify environment variables
   - After editing, run `direnv allow` again to approve the changes
   - Variables will be automatically reloaded

### Current Environment Variables

The `.envrc` file currently sets:

- `ADDR=":8080"` - The server address and port

You can add database configuration to your `.envrc` file:

```bash
export ADDR=":8080"
export DB_ADDR="postgres://admin:password@localhost:5432/portfolio?sslmode=disable"
export DB_MAX_OPEN_CONNS=30
export DB_MAX_IDLE_CONNS=30
export DB_MAX_IDLE_TIME="15m"
```

After editing, run `direnv allow` to load the new variables.

### Verifying direnv is working

You can verify that environment variables are loaded by:

```bash
echo $ADDR  # Should output ":8080"
```

## Project Structure

```text
├── .envrc              # Environment variables (auto-loaded by direnv)
├── .air.toml           # Air configuration for hot reload
├── Makefile            # Build automation and common tasks
├── docker-compose.yml  # PostgreSQL database configuration
├── go.mod              # Go module definition
├── go.sum              # Go module checksums
├── bin/                # Compiled binaries
├── cmd/                # Application entry points
│   ├── api/            # API server
│   └── migrate/        # Database migrations
│       └── migrations/ # Goose migration files
├── docs/               # Documentation
├── internal/           # Private application code
│   └── env/            # Environment configuration
└── scripts/            # Build and deployment scripts
```

## Quick Start

This project includes a Makefile for common development tasks. To see all available commands:

```bash
make help
```

### One-command setup

```bash
# Install tools, start database, and run migrations
make install-tools
make setup
```

### Common commands

```bash
# Development
make dev              # Start with hot reload
make run              # Run without hot reload
make build            # Build the application

# Database
make docker-up        # Start PostgreSQL
make migration-up     # Run migrations
make migration-status # Check migration status

# Code quality
make fmt              # Format code
make lint             # Run linter
make test             # Run tests
make all              # Format, lint, test, and build
```

## Database Setup

This project uses PostgreSQL as the database and Goose for migrations.

### Starting the Database

The project includes a `docker-compose.yml` file for easy database setup:

```bash
# Start PostgreSQL in the background
docker-compose up -d --build

# Verify it's running
docker-compose ps
```

The database will be available at:

- **Host:** localhost:5432
- **Database:** portfolio
- **Username:** admin
- **Password:** password

### Running Migrations

After starting the database, run the migrations to set up the schema:

```bash
# Run all pending migrations
goose -dir cmd/migrate/migrations postgres "postgres://admin:password@localhost:5432/portfolio?sslmode=disable" up

# Check migration status
goose -dir cmd/migrate/migrations postgres "postgres://admin:password@localhost:5432/portfolio?sslmode=disable" status
```

## Development

### Using Makefile (Recommended)

The project includes a Makefile with convenient commands:

```bash
# Start development server with hot reload
make dev

# Run without hot reload
make run

# Build the application
make build
```

### Running the API server manually

#### With Air (Hot Reload - Recommended for development)

```bash
# The ADDR environment variable will be automatically available
air
```

Air will watch for file changes and automatically rebuild and restart the server.

#### Without Air (Manual restart required)

```bash
# The ADDR environment variable will be automatically available
go run cmd/api/*.go
```

### Building manually

```bash
go build -o ./bin/main.exe ./cmd/api
```

## Troubleshooting

### direnv

- **"direnv: error .envrc is blocked"**: Run `direnv allow` in the project directory
- **Environment variables not loading**: Check if direnv hook is properly added to your shell configuration
- **Check direnv status**: Run `direnv status` to see current state
- **Reload manually**: Run `direnv reload` to manually reload the `.envrc` file

### Air

- **"air: command not found"**: Make sure Air is installed with `go install github.com/cosmtrek/air@latest`
- **Air not detecting changes**: Check that your file extensions are included in the `.air.toml` configuration
- **Port already in use**: Make sure no other instance of the server is running, or change the `ADDR` in `.envrc`
- **Build errors**: Check the `build-errors.log` file created by Air for detailed error information

### Database & Goose

- **"goose: command not found"**: Make sure Goose is installed with `go install github.com/pressly/goose/v3/cmd/goose@latest`
- **Connection refused error**: Ensure PostgreSQL is running with `docker-compose up -d`
- **Migration failed**: Check that the database connection string is correct and the database exists
- **Permission denied**: Verify the database user has the necessary permissions to create tables and run migrations
- **Migration file format**: Ensure migration files follow the Goose naming convention: `YYYYMMDDHHMMSS_description.sql`

## Contributing

When adding new environment variables:

1. Add them to `.envrc`
2. Run `direnv allow` to approve changes
3. Update this README with the new variables
4. Consider adding example values or documentation for the variables
