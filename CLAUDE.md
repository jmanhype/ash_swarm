# AshSwarm Project Commands & Guidelines

## Build & Run Commands
- Setup project: `mix setup`
- Run servers: `./start_ash_swarm.sh` (starts Phoenix & Livebook) or `mix phx.server` (Phoenix only)
- Run tests: `mix test`
- Run single test: `mix test path/to/test_file.exs:line_number`
- Run module tests: `mix test test/ash_swarm/domain_reasoning_yaml_test.exs`
- Compile with warnings: `mix compile --warnings-as-errors`
- Database: `mix ecto.setup`, `mix ecto.reset`, `mix ecto.migrate`
- Format code: `mix format`
- Assets: `mix assets.setup`, `mix assets.build`, `mix assets.deploy`
- Routes: `mix phx.routes`

## Code Style Guidelines
- Module structure: use/alias/require statements, module attributes, types, public API, private functions
- Naming: PascalCase for modules (AshSwarm.Module.Name), snake_case for functions/variables
- Functions: Verb-first naming (create_user, validate_model), descriptive names
- Documentation: Detailed @moduledoc and @doc with markdown, specify parameters and return values
- Pattern matching: Prefer function heads and guards over conditionals in function bodies
- Error handling: Return {:ok, result} | {:error, reason}, use with statements for operation chains
- Clean pipelines: Use |> for sequential operations with consistent indentation
- Testing: BDD-style Given/When/Then comments, descriptive names, proper setup/teardown
- DSL patterns: Follow Ash Framework conventions for resources, actions, and reactors
- Reactors: Create composable workflow steps with clear inputs/outputs