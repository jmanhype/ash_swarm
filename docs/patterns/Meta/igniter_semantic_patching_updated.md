# Igniter Semantic Patching Pattern

**Status:** Implemented

## Description

The Igniter Semantic Patching Pattern leverages the Igniter framework to enable intelligent, context-aware code generation and modification capabilities throughout an application. This pattern goes beyond simple template-based code generation by understanding the semantic structure of code, allowing for precise, targeted modifications that preserve developer intent while automating repetitive tasks.

Using [Igniter](https://github.com/ash-project/igniter), a code generation and project patching framework from the Ash Project, this pattern enables applications to:

1. Semantically understand the structure of existing code
2. Intelligently generate new code that integrates with existing components
3. Patch and update existing code without destroying manual modifications
4. Compose multiple generators to create complex transformations

In the Ash ecosystem, this creates a powerful foundation for self-extending applications, where the system can continually evolve by generating its own extensions and adapting existing code to changing requirements.

## Current Implementation

AshSwarm implements the Igniter Semantic Patching Pattern through a comprehensive foundation module that provides tools and abstractions for semantic code patching and generation. The implementation includes:

1. **A DSL for Semantic Patching**: Define matchers, transformers, and validators for semantic code patches
2. **Code Generators**: Template-based code generation with contextual awareness
3. **Patch Composition**: Mechanisms for composing multiple patches into cohesive transformations
4. **Mix Task Integration**: CLI tools for applying patches and generators

The implementation leverages Igniter's capabilities to provide a higher-level, more integrated pattern for semantic code manipulation within the AshSwarm framework.

## Implementation Details

The Igniter Semantic Patching pattern is implemented through the following components:

### Core Module

The main foundation module is `AshSwarm.Foundations.IgniterSemanticPatching`, which provides the core abstractions and functions for the pattern:

```elixir
defmodule AshSwarm.Foundations.IgniterSemanticPatching do
  @moduledoc """
  Implements the Igniter Semantic Patching Pattern, providing tools for
  intelligent, context-aware code generation and modification.
  """
  
  # Main module implementation
  # ...
end
```

### DSL Features

The pattern includes DSL functions for defining semantic patches, code generators, and patch composers:

```elixir
# Define a semantic patch
semantic_patch :add_timestamps, 
  description: "Adds timestamp fields to Ash resources",
  matcher: fn module_info -> 
    # Match only Ash resources without timestamps
    has_attribute?(module_info, "use Ash.Resource") and
    not has_section?(module_info, "timestamps")
  end,
  transformer: fn module_info ->
    # Add timestamps section
    add_section(module_info, 
      "timestamps", 
      """
      timestamps do
        attribute :inserted_at, :utc_datetime
        attribute :updated_at, :utc_datetime
      end
      """
    )
  end,
  validator: fn transformed ->
    # Validate the transformation
    has_section?(transformed, "timestamps")
  end

# Define a code generator
code_generator :crud_api,
  description: "Generates a CRUD API for a resource",
  context_builder: fn resource_module, options ->
    # Build context for the template
    # ...
  end,
  template: "...",
  validator: fn code ->
    # Validate the generated code
    # ...
  end

# Define a patch composer
compose_patches :upgrade_resource_v1_to_v2,
  description: "Upgrades a resource from v1 to v2 format",
  patches: [:add_timestamps, :add_soft_delete, :update_relationship_cardinality],
  sequence: :sequential,
  validator: fn result ->
    # Validate the final result
    # ...
  end
```

### Example Implementation

An example implementation showing how to use the pattern is provided in `AshSwarm.Foundations.IgniterSemanticPatching.Example`:

```elixir
defmodule AshSwarm.Foundations.IgniterSemanticPatching.Example do
  @moduledoc """
  Example implementation of the IgniterSemanticPatching pattern.
  """
  
  use AshSwarm.Foundations.IgniterSemanticPatching
  
  # Define patches, generators, and composers
  # ...
  
  def upgrade_resources(paths) do
    # Example function that uses the pattern
    # ...
  end
end
```

### Mix Task Integration

The pattern includes a Mix task for applying semantic patches from the command line:

```elixir
defmodule Mix.Tasks.AshSwarm.ApplyPatches do
  @moduledoc """
  Applies semantic patches to Ash resources.
  """
  
  use Mix.Task
  
  # Implementation of the Mix task
  # ...
end
```

## Usage Examples

### Defining and Applying Semantic Patches

```elixir
defmodule MyApp.CodePatchers do
  use AshSwarm.Foundations.IgniterSemanticPatching
  
  # Define a semantic patch for adding timestamps to resources
  semantic_patch :add_timestamps, 
    description: "Adds timestamp fields to Ash resources",
    matcher: fn module_info -> 
      # Match logic
    end,
    transformer: fn module_info ->
      # Transformation logic
    end,
    validator: fn transformed ->
      # Validation logic
    end
    
  # More patch definitions...
end

# Apply a patch to a module
MyApp.CodePatchers.apply_patch(:add_timestamps, MyApp.Resources.User, [])
```

### Generating Code

```elixir
# Generate a CRUD API for a resource
MyApp.CodePatchers.generate_code(
  :crud_api,
  MyApp.UserAPI,
  actions: [:create, :read, :update, :destroy, :list]
)
```

### Composing and Applying Multiple Patches

```elixir
# Apply a composition of patches to upgrade a resource
MyApp.CodePatchers.compose_and_apply(
  :upgrade_resource_v1_to_v2,
  MyApp.Resources.User,
  all_patches: MyApp.CodePatchers.semantic_patches()
)
```

### Using the Mix Task

```bash
# Apply patches to resources in a directory
mix ash_swarm.apply_patches --path=lib/my_app/resources --patches=add_timestamps,add_soft_delete --verbose
```

## Benefits of Implementation

1. **Semantic Understanding**: Changes to code maintain the semantic intent rather than just textual replacement.

2. **Intelligent Code Generation**: Generators can adapt their output based on the existing code context.

3. **Incremental Adoption**: Enables gradual adoption of patterns and practices across a codebase.

4. **Automated Upgrades**: Simplifies upgrading applications when dependencies change their APIs.

5. **Composable Transformations**: Complex code transformations can be built from simpler, reusable parts.

6. **Contextual Awareness**: Patches can adapt based on the specific context of each code module.

7. **Migration Support**: Facilitates smooth migrations between different versions of generated code.

8. **Developer Experience**: Eliminates repetitive manual code updates while preserving custom modifications.

## Related Resources

- [Igniter GitHub Repository](https://github.com/ash-project/igniter)
- [Igniter Hexdocs Documentation](https://hexdocs.pm/igniter/readme.html)
- [Semantic Patching Concepts](https://en.wikipedia.org/wiki/Semantic_patch)
- [Ash Framework Documentation](https://www.ash-hq.org)
- [Code Generation Bootstrapping Pattern](./code_generation_bootstrapping.md)
- [Self-Extending Build System Pattern](./self_extending_build_system.md) 