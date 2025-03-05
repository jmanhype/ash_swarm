defmodule AshSwarm.Foundations.LivingProjectTest do
  use ExUnit.Case, async: true

  alias AshSwarm.Foundations.LivingProject

  defmodule TestKnowledgeRepository do
    def manage(operation, domain, key, value \\ nil, metadata \\ %{}) do
      case operation do
        :store ->
          Agent.update(
            __MODULE__,
            fn state ->
              Map.put(state, {domain, key}, %{value: value, metadata: metadata})
            end
          )

          :ok

        :retrieve ->
          result =
            Agent.get(
              __MODULE__,
              fn state -> Map.get(state, {domain, key}) end
            )

          case result do
            nil -> nil
            data -> data.value
          end
      end
    end
  end

  defmodule TestAnalysisEngine do
    def analyze(_context) do
      %{
        test_analysis: %{
          patterns: [%{name: :test_pattern, score: 0.8}],
          smells: [%{name: :test_smell, severity: :medium}],
          optimizations: [%{name: :test_optimization, impact: :high}]
        }
      }
    end
  end

  defmodule TestDecisionFramework do
    def decide(_context, options, _constraints) do
      best_option = Enum.max_by(options, & &1.score)

      %{
        decision: best_option.id,
        rationale: %{score: best_option.score},
        confidence: 0.8
      }
    end
  end

  defmodule TestProject do
    use AshSwarm.Foundations.LivingProject do
      # Define knowledge repositories
      knowledge_repository(AshSwarm.Foundations.LivingProjectTest.TestKnowledgeRepository, :manage)

      # Define analysis engines
      analysis_engine(AshSwarm.Foundations.LivingProjectTest.TestAnalysisEngine, :analyze)

      # Define decision frameworks
      decision_framework(AshSwarm.Foundations.LivingProjectTest.TestDecisionFramework, :decide)
    end
  end

  setup do
    # Start the repository agent
    {:ok, _} = Agent.start_link(fn -> %{} end, name: TestKnowledgeRepository)

    :ok
  end

  describe "knowledge repository" do
    test "store_knowledge/4 stores knowledge in repositories" do
      :ok = TestProject.store_knowledge(:test_domain, :test_key, "test_value")
      
      # Verify the knowledge was stored
      result = TestProject.retrieve_knowledge(:test_domain, :test_key)
      assert result == "test_value"
    end

    test "retrieve_knowledge/2 retrieves knowledge from repositories" do
      # Store knowledge
      :ok = TestProject.store_knowledge(:test_domain, :another_key, "another_value")
      
      # Retrieve knowledge
      result = TestProject.retrieve_knowledge(:test_domain, :another_key)
      assert result == "another_value"
      
      # Retrieve non-existent knowledge
      result = TestProject.retrieve_knowledge(:test_domain, :non_existent)
      assert result == nil
    end
  end

  describe "analysis engines" do
    test "analyze_project/1 analyzes the project using all registered engines" do
      result = TestProject.analyze_project(%{})
      
      assert Map.has_key?(result, :test_analysis)
      assert length(result.test_analysis.patterns) == 1
      assert length(result.test_analysis.smells) == 1
      assert length(result.test_analysis.optimizations) == 1
    end
  end

  describe "decision frameworks" do
    test "make_adaptation_decision/3 makes decisions using registered frameworks" do
      options = [
        %{id: :option1, score: 0.5},
        %{id: :option2, score: 0.8},
        %{id: :option3, score: 0.3}
      ]
      
      result = TestProject.make_adaptation_decision(%{}, options, %{})
      
      assert result.decision == :option2
      assert Map.has_key?(result, :confidence)
      assert Map.has_key?(result, :rationale)
    end
  end
end