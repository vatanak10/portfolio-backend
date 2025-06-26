# Portfolio Backend

A Go-based backend service for a portfolio application.

## Prerequisites

- Go 1.22+
- direnv (for environment variable management)
- Air (for hot reload during development)

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

### Verifying direnv is working

You can verify that environment variables are loaded by:

```bash
echo $ADDR  # Should output ":8080"
```

## Project Structure

```text
├── .envrc              # Environment variables (auto-loaded by direnv)
├── .air.toml           # Air configuration for hot reload
├── go.mod              # Go module definition
├── go.sum              # Go module checksums
├── bin/                # Compiled binaries
├── cmd/                # Application entry points
│   ├── api/            # API server
│   └── migrate/        # Database migrations
├── docs/               # Documentation
├── internal/           # Private application code
│   └── env/            # Environment configuration
└── scripts/            # Build and deployment scripts
```

## Development

### Running the API server

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

### Building

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

## Contributing

When adding new environment variables:

1. Add them to `.envrc`
2. Run `direnv allow` to approve changes
3. Update this README with the new variables
4. Consider adding example values or documentation for the variables
