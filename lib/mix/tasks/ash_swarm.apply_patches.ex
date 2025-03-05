defmodule Mix.Tasks.AshSwarm.ApplyPatches do
  @moduledoc """
  Applies semantic patches to Ash resources.
  
  ## Usage
  
  ```
  mix ash_swarm.apply_patches --path=lib/your_app/resources --patches=add_timestamps,add_soft_delete
  ```
  
  ## Options
  
  * `--path` - Path to the directory containing resources to patch (required)
  * `--patches` - Comma-separated list of patch names to apply (required)
  * `--dry-run` - Preview changes without applying them
  * `--verbose` - Output detailed information
  """
  
  use Mix.Task
  
  @shortdoc "Apply semantic patches to Ash resources"
  
  alias AshSwarm.Foundations.IgniterSemanticPatching.Example
  
  @impl Mix.Task
  def run(args) do
    {opts, _} = OptionParser.parse!(args,
      strict: [
        path: :string,
        patches: :string,
        dry_run: :boolean,
        verbose: :boolean
      ]
    )
    
    path = opts[:path] || raise "Please specify a path with --path"
    patch_names = opts[:patches] || raise "Please specify patches with --patches"
    dry_run = Keyword.get(opts, :dry_run, false)
    verbose = Keyword.get(opts, :verbose, false)
    
    # Convert patch names from string to atoms
    patches = patch_names
    |> String.split(",")
    |> Enum.map(&String.to_atom/1)
    
    # Ensure the path exists
    unless File.dir?(path) do
      Mix.raise "Path does not exist: #{path}"
    end
    
    # Analyze the codebase
    Mix.shell().info("Analyzing codebase at #{path}...")
    
    # Get available patches from the Example module
    available_patches = Example.semantic_patches()
    
    # Validate that all requested patches exist
    missing_patches = Enum.filter(patches, fn patch ->
      not Enum.any?(available_patches, fn p -> p.name == patch end)
    end)
    
    unless Enum.empty?(missing_patches) do
      Mix.raise "Unknown patches: #{Enum.join(missing_patches, ", ")}"
    end
    
    # Find resources to patch
    resources = find_resources(path)
    
    if Enum.empty?(resources) do
      Mix.shell().info("No resources found in #{path}")
      return()
    end
    
    Mix.shell().info("Found #{length(resources)} resources")
    
    if verbose do
      Mix.shell().info("Resources:")
      Enum.each(resources, fn resource ->
        Mix.shell().info("  - #{resource}")
      end)
    end
    
    # Apply patches
    Mix.shell().info("Applying patches: #{patch_names}")
    
    if dry_run do
      Mix.shell().info("Dry run mode, no changes will be made")
    end
    
    stats = %{succeeded: 0, failed: 0, skipped: 0}
    
    results = Enum.map(resources, fn resource ->
      Mix.shell().info("Processing resource: #{resource}")
      
      # For each patch
      Enum.reduce(patches, {resource, stats}, fn patch_name, {_, stats} ->
        patch = Enum.find(available_patches, fn p -> p.name == patch_name end)
        
        if verbose do
          Mix.shell().info("  Applying patch: #{patch_name} - #{patch.description}")
        end
        
        if dry_run do
          # In dry run mode, just report what would happen
          {resource, Map.update!(stats, :skipped, &(&1 + 1))}
        else
          # Apply the patch
          case Example.apply_patch(patch_name, resource, []) do
            {:ok, result} ->
              if verbose do
                Mix.shell().info("  ✓ Successfully applied #{patch_name}")
              end
              {resource, Map.update!(stats, :succeeded, &(&1 + 1))}
              
            {:error, reason} ->
              Mix.shell().error("  ✗ Failed to apply #{patch_name}: #{reason}")
              {resource, Map.update!(stats, :failed, &(&1 + 1))}
          end
        end
      end)
    end)
    
    # Get the final stats from the last result
    {_, stats} = List.last(results, {nil, stats})
    
    # Print summary
    Mix.shell().info("\nSummary:")
    Mix.shell().info("  Succeeded: #{stats.succeeded}")
    Mix.shell().info("  Failed: #{stats.failed}")
    Mix.shell().info("  Skipped: #{stats.skipped}")
    
    if stats.failed > 0 do
      Mix.shell().info("\nSome patches failed to apply. Check the logs for details.")
    else
      Mix.shell().info("\nAll patches applied successfully!")
    end
  end
  
  # Helper function to find resources in a path
  defp find_resources(path) do
    # This is a simple implementation that looks for Elixir files
    # with "use Ash.Resource" in them. A real implementation would
    # use Igniter for more accurate detection.
    Path.wildcard("#{path}/**/*.ex")
    |> Enum.filter(fn file ->
      case File.read(file) do
        {:ok, content} ->
          String.contains?(content, "use Ash.Resource")
        _ -> false
      end
    end)
    |> Enum.map(fn file ->
      file
      |> Path.relative_to(File.cwd!())
      |> Path.rootname()
      |> String.replace("/", ".")
      |> String.capitalize()
    end)
  end
end