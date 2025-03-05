defmodule AshSwarm.Foundations.BootstrapEvolutionPipelineTest do
  use ExUnit.Case, async: true
  
  alias AshSwarm.Foundations.BootstrapEvolutionExample
  alias AshSwarm.Foundations.UsageStats
  
  setup do
    # Start the UsageStats GenServer
    {:ok, pid} = UsageStats.start_link()
    
    on_exit(fn ->
      # Clean up after each test
      UsageStats.clear_stats()
      Process.exit(pid, :normal)
    end)
    
    :ok
  end
  
  describe "generator registration and usage" do
    test "can register and retrieve generators" do
      # Register a test generator
      generator_id = :test_generator
      generator_module = AshSwarm.Generators.ResourceGenerator
      generator_function = :generate
      metadata = %{test: true}
      
      BootstrapEvolutionExample.register_generator(
        generator_id, 
        generator_module, 
        generator_function, 
        metadata
      )
      
      # Retrieve the generator
      generator = UsageStats.get_generator(generator_id)
      
      assert generator.id == generator_id
      assert generator.module == generator_module
      assert generator.function == generator_function
      assert generator.metadata == metadata
      assert generator.version == 1
    end
    
    test "can generate code and record usage" do
      # Register a test generator
      generator_id = :test_generator
      BootstrapEvolutionExample.register_generator(
        generator_id, 
        AshSwarm.Generators.ResourceGenerator, 
        :generate
      )
      
      # Generate code
      context = %{
        name: "User",
        module: "MyApp.Resources.User",
        fields: [
          {:name, :string},
          {:email, :string},
          {:age, :integer}
        ]
      }
      
      code = BootstrapEvolutionExample.generate_code(generator_id, context)
      
      # Verify code was generated
      assert is_binary(code)
      assert String.contains?(code, "defmodule MyApp.Resources.User")
      assert String.contains?(code, "attribute :name, :string")
      
      # Verify usage was recorded
      usage_data = UsageStats.get_usage_data(generator_id, :all)
      assert length(usage_data) > 0
      
      event = List.first(usage_data)
      assert event.generator_id == generator_id
      assert event.context == context
    end
  end
  
  describe "feedback collection and analysis" do
    test "can collect and retrieve feedback" do
      # Register a test generator
      generator_id = :test_generator
      BootstrapEvolutionExample.register_generator(
        generator_id, 
        AshSwarm.Generators.ResourceGenerator, 
        :generate
      )
      
      # Generate code
      context = %{
        name: "Product",
        module: "MyApp.Resources.Product",
        fields: [
          {:name, :string},
          {:price, :decimal},
          {:description, :string}
        ]
      }
      
      code = BootstrapEvolutionExample.generate_code(generator_id, context)
      
      # Provide feedback
      feedback = %{
        satisfaction: 4,
        modifications: 2,
        comments: "Good structure, needed minor tweaks"
      }
      
      BootstrapEvolutionExample.collect_feedback(
        generator_id, 
        code, 
        "test_user", 
        :explicit, 
        feedback
      )
      
      # Retrieve feedback
      feedback_data = UsageStats.get_feedback_data(generator_id, :all)
      assert length(feedback_data) > 0
      
      stored_feedback = List.first(feedback_data)
      assert stored_feedback.satisfaction == 4
      assert stored_feedback.modifications == 2
    end
  end
  
  describe "generator evolution" do
    test "can evolve generators based on usage and feedback" do
      # Register a test generator
      generator_id = :test_generator
      BootstrapEvolutionExample.register_generator(
        generator_id, 
        AshSwarm.Generators.ResourceGenerator, 
        :generate
      )
      
      # Generate code and provide feedback
      context = %{
        name: "Order",
        module: "MyApp.Resources.Order",
        fields: [
          {:number, :string},
          {:total, :decimal},
          {:status, :string}
        ]
      }
      
      code = BootstrapEvolutionExample.generate_code(generator_id, context)
      
      BootstrapEvolutionExample.collect_feedback(
        generator_id, 
        code, 
        "test_user", 
        :explicit, 
        %{satisfaction: 3, modifications: 4}
      )
      
      # Evolve the generator
      evolved_generator = BootstrapEvolutionExample.evolve_generator(generator_id)
      
      # Verify the generator was evolved
      assert evolved_generator.version == 2
    end
  end
  
  describe "pipeline orchestration" do
    test "can run a code generation pipeline" do
      # Register the necessary generators
      BootstrapEvolutionExample.register_generator(
        :resource_generator, 
        AshSwarm.Generators.ResourceGenerator, 
        :generate
      )
      
      BootstrapEvolutionExample.register_generator(
        :api_generator, 
        AshSwarm.Generators.ApiGenerator, 
        :generate
      )
      
      # Run the pipeline
      context = %{
        name: "Customer",
        module: "MyApp.Resources.Customer",
        fields: [
          {:name, :string},
          {:email, :string}
        ]
      }
      
      result = BootstrapEvolutionExample.run_pipeline_example("Customer", context.fields)
      
      # Verify the result contains the expected components
      assert Map.has_key?(result, :resource)
      assert Map.has_key?(result, :api)
      
      assert String.contains?(result.resource, "defmodule MyApp.Resources.Customer")
      assert String.contains?(result.api, "defmodule MyApp.Api.Customer")
    end
  end
end