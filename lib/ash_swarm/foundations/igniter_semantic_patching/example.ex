defmodule AshSwarm.Foundations.IgniterSemanticPatching.Example do
  @moduledoc """
  Example implementation of the IgniterSemanticPatching pattern.
  
  This module demonstrates how to define and use semantic patches,
  code generators, and patch composers.
  """
  
  use AshSwarm.Foundations.IgniterSemanticPatching
  
  # Define a semantic patch for adding timestamps to resources
  semantic_patch :add_timestamps, 
    description: "Adds timestamp fields to Ash resources",
    matcher: fn module_info -> 
      # Match only Ash resources without timestamps
      __MODULE__.has_attribute?(module_info, "use Ash.Resource") && 
      not __MODULE__.has_section?(module_info, "timestamps")
    end,
    transformer: fn module_info ->
      # Add timestamps section
      __MODULE__.add_section(module_info, 
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
      __MODULE__.has_section?(transformed, "timestamps")
    end
  
  # Define a semantic patch for adding soft deletion to resources
  semantic_patch :add_soft_delete, 
    description: "Adds soft delete functionality to Ash resources",
    matcher: fn module_info -> 
      # Match only Ash resources without soft delete
      __MODULE__.has_attribute?(module_info, "use Ash.Resource") && 
      not __MODULE__.has_section?(module_info, "soft_delete")
    end,
    transformer: fn module_info ->
      # Add soft delete section
      __MODULE__.add_section(module_info, 
        "soft_delete", 
        """
        soft_delete do
          attribute :deleted_at, :utc_datetime
        end
        """
      )
    end,
    validator: fn transformed ->
      # Validate the transformation
      __MODULE__.has_section?(transformed, "soft_delete")
    end
  
  # Define a semantic patch for updating relationship cardinality
  semantic_patch :update_relationship_cardinality, 
    description: "Updates relationship cardinality in Ash resources",
    matcher: fn module_info -> 
      # Match only Ash resources with relationships
      __MODULE__.has_attribute?(module_info, "use Ash.Resource") && 
      __MODULE__.has_section?(module_info, "relationships")
    end,
    transformer: fn module_info ->
      # Update relationships section
      __MODULE__.update_section(module_info, 
        "relationships",
        fn section_content ->
          section_content
          |> String.replace("has_many", "has_many :unordered")
        end
      )
    end,
    validator: fn transformed ->
      # Validate the transformation
      __MODULE__.has_section?(transformed, "relationships")
    end
  
  # Define a code generator for creating a CRUD API
  code_generator :crud_api,
    description: "Generates a CRUD API for a resource",
    context_builder: fn resource_module, options ->
      resource_name = resource_module |> Module.split() |> List.last()
      api_name = options[:api_name] || "#{resource_name}API"
      
      %{
        resource_module: resource_module,
        resource_name: resource_name,
        api_name: api_name,
        actions: options[:actions] || [:create, :read, :update, :destroy]
      }
    end,
    template: """
    defmodule <%= @api_name %> do
      use Ash.Api
      
      resources do
        resource <%= @resource_module %>
      end
      
      <%= for action <- @actions do %>
      def <%= action %>(input, options \\\\ []) do
        <%= @resource_module %>
        |> Ash.Query.<%= action %>(input)
        |> run(options)
      end
      <% end %>
      
      defp run(query, options) do
        Ash.read(query, options)
      end
    end
    """,
    validator: fn code ->
      # Basic validation to ensure we have valid Elixir code
      case Code.string_to_quoted(code) do
        {:ok, _ast} -> true
        _error -> false
      end
    end
  
  # Define a code generator for creating an Event module
  code_generator :event_module,
    description: "Generates an Event module for a resource",
    context_builder: fn resource_module, options ->
      resource_name = resource_module |> Module.split() |> List.last()
      
      %{
        resource_module: resource_module,
        resource_name: resource_name,
        events: options[:events] || [:created, :updated, :destroyed]
      }
    end,
    template: """
    defmodule <%= @resource_module %>.Event do
      use Ash.Event
      
      events do
        <%= for event <- @events do %>
        event :<%= event %>
        <% end %>
      end
    end
    """,
    validator: fn code ->
      # Basic validation to ensure we have valid Elixir code
      case Code.string_to_quoted(code) do
        {:ok, _ast} -> true
        _error -> false
      end
    end
  
  # Define a patch composer for upgrading resources
  compose_patches :upgrade_resource_v1_to_v2,
    description: "Upgrades a resource from v1 to v2 format",
    patches: [:add_timestamps, :add_soft_delete, :update_relationship_cardinality],
    sequence: :sequential,
    validator: fn result ->
      # Final validation after all patches are applied
      result != nil
    end
  
  # Define a patch composer for creating event-sourced resources
  compose_patches :create_event_sourced_resource,
    description: "Creates an event-sourced resource suite",
    patches: [:add_timestamps, :add_soft_delete],
    sequence: fn patches, target, options ->
      # Apply resource patches
      {:ok, updated_resource} = Enum.reduce_while(patches, {:ok, nil}, fn patch, {:ok, _} ->
        case apply_patch(patch, target, options) do
          {:ok, updated} -> {:cont, {:ok, updated}}
          error -> {:halt, error}
        end
      end)
      
      # Generate event and event store modules
      {:ok, _} = generate_code(:event_module, "#{target}.Event", options)
      
      # Return the final result
      {:ok, updated_resource}
    end,
    validator: fn result ->
      # Final validation
      result != nil
    end
  
  # Helper functions that would use Igniter in a real implementation
  def has_attribute?(module_info, attribute) do
    # This would use Igniter.Code.Module.has_attribute? in a real implementation
    Map.get(module_info, :attributes, []) |> Enum.member?(attribute)
  end
  
  def has_section?(module_info, section_name) do
    # This would use Igniter.Code.Module.has_section? in a real implementation
    Map.get(module_info, :sections, []) |> Enum.member?(section_name)
  end
  
  def add_section(module_info, section_name, content) do
    # This would use Igniter.Code.Module.add_section in a real implementation
    sections = Map.get(module_info, :sections, [])
    updated_sections = [section_name | sections]
    Map.put(module_info, :sections, updated_sections)
  end
  
  def update_section(module_info, section_name, transformer) do
    # This would use Igniter.Code.Module.update_section in a real implementation
    module_info
  end
  
  @doc """
  Example function that demonstrates how to use semantic patches.
  
  This function analyzes resources in the given paths, applies patches to upgrade
  them, and generates associated APIs and event modules.
  
  ## Parameters
  
  - `paths`: List of file paths to analyze.
  
  ## Returns
  
  - `{:ok, results}` if the operations were successful.
  - `{:error, reason}` if there was an error.
  """
  def upgrade_resources(paths) do
    # Analyze the codebase
    project = analyze_codebase(paths)
    
    # Find all resources in the project
    resources = find_resources(project)
    
    # Apply patches to each resource
    results = Enum.map(resources, fn resource ->
      # Apply individual patch
      {:ok, _} = apply_patch(:add_timestamps, resource, [])
      
      # Apply composed patches
      {:ok, _} = compose_and_apply(
        :upgrade_resource_v1_to_v2,
        resource,
        all_patches: semantic_patches()
      )
      
      # Generate API for the resource
      {:ok, _} = generate_code(
        :crud_api,
        "#{resource}API",
        actions: [:create, :read, :update, :destroy, :list]
      )
      
      # Generate event module for the resource
      {:ok, _} = generate_code(
        :event_module,
        "#{resource}.Event",
        events: [:created, :updated, :destroyed]
      )
      
      resource
    end)
    
    {:ok, results}
  end
  
  # Helper function to find resources (would use Igniter in a real implementation)
  defp find_resources(_project) do
    # This would use Igniter to find resources in the project
    []
  end
end