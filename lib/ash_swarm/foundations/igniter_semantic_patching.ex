defmodule AshSwarm.Foundations.IgniterSemanticPatching do
  @moduledoc """
  Implements the Igniter Semantic Patching Pattern, providing tools for
  intelligent, context-aware code generation and modification.

  This pattern leverages the Igniter framework to enable:
  1. Semantic understanding of code structure
  2. Intelligent generation of new code that integrates with existing components
  3. Patching and updating existing code without destroying manual modifications
  4. Composition of multiple generators to create complex transformations

  In the Ash ecosystem, this creates a powerful foundation for self-extending applications,
  where the system can continually evolve by generating its own extensions and adapting
  existing code to changing requirements.
  """

  @doc """
  Defines a module as implementing the IgniterSemanticPatching pattern.

  This macro introduces DSL functions for defining semantic patches, code generators,
  and patch composers.
  """
  defmacro __using__(opts) do
    quote do
      Module.register_attribute(__MODULE__, :semantic_patches, accumulate: true)
      Module.register_attribute(__MODULE__, :generators, accumulate: true)
      Module.register_attribute(__MODULE__, :patch_composers, accumulate: true)
      
      @before_compile AshSwarm.Foundations.IgniterSemanticPatching
      
      import AshSwarm.Foundations.IgniterSemanticPatching, only: [
        semantic_patch: 2,
        code_generator: 2,
        compose_patches: 2
      ]
    end
  end

  @doc """
  Defines helper functions for modules using the IgniterSemanticPatching pattern.

  These functions enable:
  - Retrieving registered patches, generators, and composers
  - Analyzing codebase structure
  - Applying semantic patches
  - Generating code based on templates and context
  - Composing and applying multiple patches
  """
  defmacro __before_compile__(_env) do
    quote do
      @doc """
      Returns all registered semantic patches for this module.
      """
      def semantic_patches do
        @semantic_patches
      end
      
      @doc """
      Returns all registered code generators for this module.
      """
      def generators do
        @generators
      end
      
      @doc """
      Returns all registered patch composers for this module.
      """
      def patch_composers do
        @patch_composers
      end
      
      @doc """
      Analyzes the structure of code in the given paths.

      ## Parameters

      - `paths`: List of file paths to analyze.

      ## Returns

      - An Igniter project struct containing the analysis.
      """
      def analyze_codebase(paths) do
        AshSwarm.Foundations.IgniterSemanticPatching.analyze_codebase(paths)
      end
      
      @doc """
      Applies a semantic patch to a target module.

      ## Parameters

      - `patch_name`: The name of the patch to apply.
      - `target`: The target module for the patch.
      - `options`: Options for applying the patch.

      ## Returns

      - `{:ok, result}` if the patch was successfully applied.
      - `{:error, reason}` if there was an error applying the patch.
      """
      def apply_patch(patch_name, target, options \\ []) do
        patch = Enum.find(semantic_patches(), fn patch -> patch.name == patch_name end)
        
        if patch do
          AshSwarm.Foundations.IgniterSemanticPatching.apply_patch(patch, target, options)
        else
          {:error, "Unknown patch: #{patch_name}"}
        end
      end
      
      @doc """
      Generates code based on a registered generator.

      ## Parameters

      - `generator_name`: The name of the generator to use.
      - `target`: The target module path for the generated code.
      - `options`: Options for the generator.

      ## Returns

      - `{:ok, result}` if the code was successfully generated.
      - `{:error, reason}` if there was an error generating the code.
      """
      def generate_code(generator_name, target, options \\ []) do
        generator = Enum.find(generators(), fn gen -> gen.name == generator_name end)
        
        if generator do
          AshSwarm.Foundations.IgniterSemanticPatching.generate_code(generator, target, options)
        else
          {:error, "Unknown generator: #{generator_name}"}
        end
      end
      
      @doc """
      Applies a composition of patches to a target module.

      ## Parameters

      - `composer_name`: The name of the composer to use.
      - `target`: The target module for the patches.
      - `options`: Options for the composer.

      ## Returns

      - `{:ok, result}` if the composition was successfully applied.
      - `{:error, reason}` if there was an error applying the composition.
      """
      def compose_and_apply(composer_name, target, options \\ []) do
        composer = Enum.find(patch_composers(), fn comp -> comp.name == composer_name end)
        
        if composer do
          AshSwarm.Foundations.IgniterSemanticPatching.compose_and_apply(composer, target, options)
        else
          {:error, "Unknown patch composer: #{composer_name}"}
        end
      end
    end
  end
  
  @doc """
  Defines a semantic patch for modifying code with semantic understanding.

  ## Parameters

  - `name`: The name of the patch.
  - `opts`: Options for the patch, including:
    - `:description`: A description of what the patch does.
    - `:matcher`: Function to determine if the patch applies.
    - `:transformer`: Function to transform the module.
    - `:validator`: Function to validate the transformation.
    - `:options`: Default options for the patch.
  """
  defmacro semantic_patch(name, opts) do
    quote do
      patch_def = %{
        name: unquote(name),
        description: unquote(opts[:description] || ""),
        matcher: unquote(opts[:matcher]),
        transformer: unquote(opts[:transformer]),
        validator: unquote(opts[:validator]),
        options: unquote(opts[:options] || [])
      }
      
      @semantic_patches patch_def
    end
  end
  
  @doc """
  Defines a code generator for creating new code from templates.

  ## Parameters

  - `name`: The name of the generator.
  - `opts`: Options for the generator, including:
    - `:description`: A description of what the generator does.
    - `:template`: The EEx template for code generation.
    - `:context_builder`: Function to build context for the template.
    - `:validator`: Function to validate the generated code.
    - `:options`: Default options for the generator.
  """
  defmacro code_generator(name, opts) do
    quote do
      generator_def = %{
        name: unquote(name),
        description: unquote(opts[:description] || ""),
        template: unquote(opts[:template]),
        context_builder: unquote(opts[:context_builder]),
        validator: unquote(opts[:validator]),
        options: unquote(opts[:options] || [])
      }
      
      @generators generator_def
    end
  end
  
  @doc """
  Defines a patch composer for applying multiple patches in sequence.

  ## Parameters

  - `name`: The name of the composer.
  - `opts`: Options for the composer, including:
    - `:description`: A description of what the composer does.
    - `:patches`: List of patch names to compose.
    - `:sequence`: How to sequence patches (:sequential, :parallel, or a custom function).
    - `:validator`: Function to validate the final result.
    - `:options`: Default options for the composer.
  """
  defmacro compose_patches(name, opts) do
    quote do
      composer_def = %{
        name: unquote(name),
        description: unquote(opts[:description] || ""),
        patches: unquote(opts[:patches] || []),
        sequence: unquote(opts[:sequence] || :sequential),
        validator: unquote(opts[:validator]),
        options: unquote(opts[:options] || [])
      }
      
      @patch_composers composer_def
    end
  end
  
  @doc """
  Analyzes the codebase structure in the given paths.

  ## Parameters

  - `paths`: List of file paths to analyze.

  ## Returns

  - An Igniter project struct containing the analysis.
  """
  def analyze_codebase(paths) do
    # Use Igniter to analyze the codebase structure
    igniter = Igniter.new()
    
    Enum.reduce(paths, igniter, fn path, acc ->
      Igniter.Project.analyze_path(acc, path)
    end)
  end
  
  @doc """
  Applies a semantic patch to a target module.

  ## Parameters

  - `patch`: The patch to apply.
  - `target`: The target module for the patch.
  - `options`: Options for applying the patch.

  ## Returns

  - `{:ok, result}` if the patch was successfully applied.
  - `{:error, reason}` if there was an error applying the patch.
  """
  def apply_patch(patch, target, options \\ []) do
    # Use Igniter to apply a semantic patch
    igniter = Igniter.new()
    
    igniter
    |> Igniter.Project.Module.find_module(target)
    |> case do
      {:ok, module_info} ->
        if patch.matcher.(module_info) do
          transformed = patch.transformer.(module_info)
          
          if patch.validator.(transformed) do
            {:ok, Igniter.Project.Module.update_module(igniter, target, fn _ -> transformed end)}
          else
            {:error, "Patch validation failed"}
          end
        else
          {:error, "Patch matcher did not match target"}
        end
      error -> error
    end
  end
  
  @doc """
  Generates code based on a template and context.

  ## Parameters

  - `generator`: The generator to use.
  - `target`: The target module path for the generated code.
  - `options`: Options for the generator.

  ## Returns

  - `{:ok, result}` if the code was successfully generated.
  - `{:error, reason}` if there was an error generating the code.
  """
  def generate_code(generator, target, options \\ []) do
    # Use Igniter to generate code
    igniter = Igniter.new()
    
    context = generator.context_builder.(target, options)
    code = EEx.eval_string(generator.template, assigns: context)
    
    if generator.validator.(code) do
      case Igniter.Code.Module.parse_string(code) do
        {:ok, module_code} ->
          {:ok, Igniter.Project.Module.create_module(igniter, target, module_code)}
        error -> error
      end
    else
      {:error, "Generated code validation failed"}
    end
  end
  
  @doc """
  Applies a composition of patches to a target module.

  ## Parameters

  - `composer`: The composer to use.
  - `target`: The target module for the patches.
  - `options`: Options for the composer.

  ## Returns

  - `{:ok, result}` if the composition was successfully applied.
  - `{:error, reason}` if there was an error applying the composition.
  """
  def compose_and_apply(composer, target, options \\ []) do
    # Apply a composition of patches
    igniter = Igniter.new()
    
    # Get all available patches to look up by name
    all_patches = options[:all_patches] || []
    
    # Look up each patch by name
    patches = Enum.map(composer.patches, fn patch_name -> 
      patch = Enum.find(all_patches, fn p -> p.name == patch_name end)
      if patch, do: {:ok, patch}, else: {:error, "Unknown patch: #{patch_name}"}
    end)
    
    # Check if any patches are missing
    if Enum.any?(patches, fn patch -> match?({:error, _}, patch) end) do
      {:error, "One or more patches could not be found"}
    else
      patches = Enum.map(patches, fn {:ok, patch} -> patch end)
      
      case composer.sequence do
        :sequential ->
          Enum.reduce_while(patches, {:ok, igniter}, fn patch, {:ok, current} ->
            case apply_patch(patch, target, options) do
              {:ok, updated} -> {:cont, {:ok, updated}}
              error -> {:halt, error}
            end
          end)
        
        :parallel ->
          # Apply patches in parallel if they don't conflict
          # This would require more complex implementation
          {:error, "Parallel patch application not implemented"}
        
        custom when is_function(custom) ->
          # Custom sequencing function
          custom.(patches, target, options)
      end
    end
  end
end