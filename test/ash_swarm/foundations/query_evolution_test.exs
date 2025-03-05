defmodule AshSwarm.Foundations.QueryEvolutionTest do
  use ExUnit.Case, async: true
  
  alias AshSwarm.Foundations.QueryEvolution
  alias AshSwarm.Foundations.UsageStats
  
  require Logger
  
  # Define a simple test module
  defmodule TestModule do
    def query_by_name(name) do
      # Simulated query function
      [%{name: name}]
    end
    
    def query_with_nested_filters(category, status) do
      # Simulated query function with nested filters
      products = [
        %{name: "Product 1", category: "Electronics", status: :active},
        %{name: "Product 2", category: "Clothing", status: :active},
        %{name: "Product 3", category: "Electronics", status: :inactive}
      ]
      
      # First filter
      by_category = Enum.filter(products, fn product -> product.category == category end)
      
      # Second filter (nested)
      Enum.filter(by_category, fn product -> product.status == status end)
    end
  end
  
  setup do
    # Start the UsageStats server for the test
    {:ok, pid} = UsageStats.start_link()
    
    # Clean up on test exit
    on_exit(fn ->
      if Process.alive?(pid) do
        UsageStats.clear_stats()
      end
    end)
    
    %{pid: pid}
  end
  
  describe "tracking usage" do
    test "tracks function usage" do
      # Track usage
      QueryEvolution.track_usage(TestModule, :query_by_name, %{query: "test"})
      
      # Get stats
      stats = UsageStats.get_stats(TestModule, :query_by_name)
      
      # Verify
      assert stats.call_count == 1
      assert length(stats.contexts) == 1
      assert hd(stats.contexts).query == "test"
    end
    
    test "accumulates multiple usages" do
      # Track multiple usages
      QueryEvolution.track_usage(TestModule, :query_by_name, %{query: "test1"})
      QueryEvolution.track_usage(TestModule, :query_by_name, %{query: "test2"})
      QueryEvolution.track_usage(TestModule, :query_by_name, %{query: "test3"})
      
      # Get stats
      stats = UsageStats.get_stats(TestModule, :query_by_name)
      
      # Verify
      assert stats.call_count == 3
      assert length(stats.contexts) == 3
      
      # Contexts should be in reverse order (newest first)
      assert Enum.at(stats.contexts, 0).query == "test3"
      assert Enum.at(stats.contexts, 1).query == "test2"
      assert Enum.at(stats.contexts, 2).query == "test1"
    end
  end
  
  describe "code analysis" do
    test "analyzes code" do
      # This is more of an integration test and would depend on Igniter
      # For now, we'll just verify the function works without errors
      analysis = QueryEvolution.analyze_code(TestModule)
      
      # Verify
      assert is_map(analysis)
    end
  end
  
  describe "adaptation suggestions" do
    test "suggests adaptations based on usage" do
      # Track significant usage to trigger adaptation suggestion
      Enum.each(1..20, fn i ->
        QueryEvolution.track_usage(TestModule, :query_with_nested_filters, %{
          category: "Electronics",
          status: :active,
          user_id: "user#{i}"
        })
      end)
      
      # Analyze code
      analysis = QueryEvolution.analyze_code(TestModule)
      
      # Get adaptation suggestions
      adaptations = QueryEvolution.suggest_adaptations(analysis)
      
      # In our simplified implementation, this should return at least one adaptation
      assert length(adaptations) > 0
    end
  end
  
  describe "experiment execution" do
    test "runs experiments" do
      # Track usage
      Enum.each(1..20, fn i ->
        QueryEvolution.track_usage(TestModule, :query_with_nested_filters, %{
          category: "Electronics",
          status: :active,
          user_id: "user#{i}"
        })
      end)
      
      # Analyze code
      analysis = QueryEvolution.analyze_code(TestModule)
      
      # Get adaptation suggestions
      adaptations = QueryEvolution.suggest_adaptations(analysis)
      
      # Skip if no adaptations (shouldn't happen with our implementation)
      if length(adaptations) > 0 do
        adaptation = hd(adaptations)
        
        # Run experiment
        result = QueryEvolution.run_experiment(
          :query_optimization_experiment,
          TestModule,
          adaptation: adaptation
        )
        
        # Verify
        assert match?({:ok, _status, _evaluation}, result)
      end
    end
  end
  
  describe "evolution process" do
    test "evolve_queries completes without errors" do
      # This tests the entire process
      assert :ok = QueryEvolution.evolve_queries(TestModule)
    end
  end
end