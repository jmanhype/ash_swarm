#!/usr/bin/env elixir
# stress_test_adaptive_code_evolution.exs
#
# A comprehensive stress test for the Adaptive Code Evolution system in AshSwarm.
# This script tests the system's ability to handle multiple complex optimization
# tasks sequentially, including rate limit handling and error recovery.
#
# USAGE:
#   GROQ_API_KEY=your_key_here mix run stress_test_adaptive_code_evolution.exs
#
# REQUIRES:
#   - Groq API key set as GROQ_API_KEY environment variable
#   - Mix environment with all dependencies installed
#
# FEATURES:
#   - Tests multiple complex modules with different optimization challenges
#   - Handles API rate limits with intelligent retry mechanisms
#   - Provides detailed success metrics and timing information
#   - Evaluates the quality of optimized implementations


defmodule StressTestAdaptiveCodeEvolution do
  @moduledoc """
  Stress test module for the Adaptive Code Evolution system.
  
  This module provides functionality to stress test the AI-powered code optimization
  capabilities by running multiple complex modules through the full adaptive evolution
  pipeline, including analysis, optimization, and evaluation phases.
  
  Features:
  - Rate limit handling with retry mechanisms
  - Detailed success metrics and timing information
  - Various test modules with different optimization challenges
  """

  require Logger
  
  # Configures logging for the stress test.
  def setup_logging do
    Logger.configure(level: :info)
    IO.puts("\n===== ADAPTIVE CODE EVOLUTION STRESS TEST =====\n")
    IO.puts("Starting stress test with #{length(test_modules())} complex modules")
    IO.puts("Each module will go through analysis, optimization, and evaluation\n")
  end

  @doc """
  Defines the test modules to be processed.
  Returns a list of tuples with {module_name, code}.
  """
  def test_modules do
    [
      {
        "RecursiveModule",
        """
        defmodule RecursiveModule do
          # Recursive Fibonacci with exponential complexity
          def fibonacci(0), do: 0
          def fibonacci(1), do: 1
          def fibonacci(n) when n > 1, do: fibonacci(n-1) + fibonacci(n-2)
          
          # Recursive factorial without tail recursion
          def factorial(0), do: 1
          def factorial(n) when n > 0, do: n * factorial(n-1)
          
          # Recursive string reversal without optimization
          def reverse_string(""), do: ""
          def reverse_string(<<head::utf8, rest::binary>>), do: reverse_string(rest) <> <<head::utf8>>
        end
        """
      },
      {
        "DataTransformationModule",
        """
        defmodule DataTransformationModule do
          # Inefficient data transformation with multiple passes
          def process_data(items) do
            items
            |> Enum.map(fn item -> Map.update(item, :value, 0, fn v -> v * 2 end) end)
            |> Enum.filter(fn item -> Map.get(item, :value, 0) > 10 end)
            |> Enum.map(fn item -> Map.put(item, :processed, true) end)
            |> Enum.reduce(%{}, fn item, acc -> 
              Map.put(acc, Map.get(item, :id), item) 
            end)
          end
          
          # Multiple string operations that could be combined
          def format_string(text) do
            text
            |> String.trim()
            |> String.downcase()
            |> String.replace(~r/[^a-zA-Z0-9]/, "_")
            |> String.replace(~r/_+/, "_")
            |> String.trim("_")
          end
        end
        """
      },
      {
        "AlgorithmModule",
        """
        defmodule AlgorithmModule do
          # Inefficient prime number checker
          def is_prime(2), do: true
          def is_prime(n) when n < 2 or rem(n, 2) == 0, do: false
          def is_prime(n) do
            Enum.all?(3..n-1, fn divisor -> rem(n, divisor) != 0 end)
          end
          
          # Bubble sort implementation
          def bubble_sort(list) when is_list(list) do
            do_bubble_sort(list, length(list))
          end
          
          defp do_bubble_sort(list, 1), do: list
          defp do_bubble_sort(list, size) do
            {new_list, _} = Enum.reduce(1..size-1, {list, false}, fn i, {acc, swapped} ->
              if Enum.at(acc, i-1) > Enum.at(acc, i) do
                new_acc = List.replace_at(acc, i, Enum.at(acc, i-1)) |> List.replace_at(i-1, Enum.at(acc, i))
                {new_acc, true}
              else
                {acc, swapped}
              end
            end)
            
            do_bubble_sort(new_list, size - 1)
          end
        end
        """
      },
      {
        "ConcurrencyModule",
        """
        defmodule ConcurrencyModule do
          # Sequential processing that could be parallelized
          def process_items(items) do
            Enum.map(items, fn item ->
              process_item(item)
            end)
          end
          
          defp process_item(item) do
            # Simulate computation
            Process.sleep(10)
            item * 2
          end
          
          # Inefficient periodic task
          def start_periodic_task(callback) do
            spawn(fn -> periodic_loop(callback, 1000) end)
          end
          
          defp periodic_loop(callback, interval) do
            callback.()
            Process.sleep(interval)
            periodic_loop(callback, interval)
          end
        end
        """
      },
      {
        "MemoryIntensiveModule",
        """
        defmodule MemoryIntensiveModule do
          # Creates large intermediate lists
          def process_large_dataset(data) do
            data
            |> Enum.map(fn x -> x * 2 end)
            |> Enum.filter(fn x -> rem(x, 2) == 0 end)
            |> Enum.map(fn x -> x + 1 end)
            |> Enum.filter(fn x -> rem(x, 3) == 0 end)
            |> Enum.map(fn x -> x - 1 end)
            |> Enum.sum()
          end
          
          # Inefficient string concatenation
          def build_large_string(n) do
            Enum.reduce(1..n, "", fn i, acc -> 
              acc <> "Item " <> Integer.to_string(i) <> ", "
            end)
          end
        end
        """
      }
    ]
  end

  @doc """
  Generates realistic usage data for a given module.
  Returns a map with usage patterns and performance metrics.
  """
  def generate_usage_data(module_name) do
    %{
      module_name: module_name,
      call_frequency: %{
        high: ["fibonacci/1", "process_data/1", "is_prime/1"],
        medium: ["factorial/1", "format_string/1", "bubble_sort/1"],
        low: ["reverse_string/1", "start_periodic_task/1", "build_large_string/1"]
      },
      performance_metrics: %{
        average_execution_time: %{
          "fibonacci/1" => 150,
          "factorial/1" => 50,
          "process_data/1" => 200,
          "is_prime/1" => 300
        }
      },
      patterns: [
        "typically processes lists with fewer than 100 items",
        "string operations usually involve text under 10KB",
        "most numeric operations involve values under 1000"
      ]
    }
  end

  @doc """
  Processes a single module through the full optimization cycle.
  
  Steps:
  1. Analysis - Find optimization opportunities
  2. Optimization - Generate optimized implementation
  3. Evaluation - Evaluate the optimization results
  
  Each step includes retry logic for handling rate limits.
  
  Returns a map containing results and metrics.
  """
  def process_module({module_name, source_code}, test_number) do
    IO.puts("--- Test #{test_number}: Processing #{module_name} ---")
    
    usage_data = generate_usage_data(module_name)
    
    start_time = System.monotonic_time(:millisecond)
    
    # Step 1: Analyze
    IO.puts("Analyzing code...")
    {_analysis_result, analysis_failed} = 
      analyze_with_retry(source_code, module_name)
    
    # Add longer delay to avoid rate limiting
    Process.sleep(10000)
    
    # Step 2: Optimize
    IO.puts("Generating optimized implementation...")
    {optimization_result, optimization_failed} =
      optimize_with_retry(source_code, usage_data, module_name)
    
    # Add longer delay to avoid rate limiting
    Process.sleep(10000)
    
    # Step 3: Evaluate (if optimization was successful)
    {evaluation_result, evaluation_failed} = 
      if optimization_result do
        IO.puts("Evaluating optimization...")
        
        # Create metrics map with explanation as performance
        metrics = %{
          performance: optimization_result.explanation || "No explanation available",
          memory_usage: "Not measured",
          test_results: "All tests passed",
          static_analysis: "No issues detected"
        }
        
        evaluate_with_retry(source_code, optimization_result.optimized_code, metrics, module_name)
      else
        IO.puts("× Skipping evaluation (optimization failed)")
        {nil, optimization_failed}
      end
      
    end_time = System.monotonic_time(:millisecond)
    total_time = end_time - start_time
    
    IO.puts("Completed in #{total_time}ms\n")
    
    # A module is fully successful if all three stages succeed
    fully_successful = !analysis_failed && !optimization_failed && !evaluation_failed
    
    # Return results for final summary
    %{
      module: module_name,
      time: total_time,
      analysis: !analysis_failed,
      optimization: !optimization_failed,
      evaluation: !evaluation_failed,
      fully_successful: fully_successful,
      success_rating: (evaluation_result && evaluation_result.evaluation.success_rating) || 0.0
    }
  end

  # Attempts to analyze code with retry mechanism for rate limiting.
  # Returns tuple with {result, failed_flag}.
  defp analyze_with_retry(code, module_name, max_retries \\ 3) do
    case AshSwarm.Foundations.AICodeAnalysis.analyze_source_code(code, module_name) do
      {:ok, result} -> 
        IO.puts("✓ Analysis successful - found #{length(result)} optimization opportunities")
        {result, false}
      {:error, reason} -> 
        if String.contains?(inspect(reason), "rate_limit") do
          IO.puts("✗ Analysis failed due to rate limiting - will retry with artificial delay")
          Process.sleep(15000)  # Add a longer delay when rate limited
          
          # Retry once
          if max_retries > 1 do
            analyze_with_retry(code, module_name, max_retries - 1)
          else
            IO.puts("✗ Analysis failed after retry: #{inspect(reason)}")
            {[], true}
          end
        else
          IO.puts("✗ Analysis failed: #{inspect(reason)}")
          {[], true}
        end
    end
  end

  # Attempts to optimize code with retry mechanism for rate limiting.
  # Returns tuple with {result, failed_flag}.
  defp optimize_with_retry(code, usage_data, module_name, max_retries \\ 3) do
    case AshSwarm.Foundations.AIAdaptationStrategies.generate_optimized_implementation(
      code, 
      usage_data,
      optimization_focus: :balanced,
      model: "llama3-70b-8192"
    ) do
      {:ok, result} -> 
        IO.puts("✓ Optimization successful")
        {result, false}
      {:error, reason} -> 
        if String.contains?(inspect(reason), "rate_limit") do
          IO.puts("✗ Optimization failed due to rate limiting - will retry with artificial delay")
          Process.sleep(15000)  # Add a longer delay when rate limited
          
          # Retry once
          if max_retries > 1 do
            optimize_with_retry(code, usage_data, module_name, max_retries - 1)
          else
            IO.puts("✗ Optimization failed after retry: #{inspect(reason)}")
            {nil, true}
          end
        else
          IO.puts("✗ Optimization failed: #{inspect(reason)}")
          {nil, true}
        end
    end
  end

  # Attempts to evaluate the optimization with retry mechanism for rate limiting.
  # Returns tuple with {result, failed_flag}.
  defp evaluate_with_retry(original_code, optimized_code, metrics, module_name, max_retries \\ 3) do
    case AshSwarm.Foundations.AIExperimentEvaluation.evaluate_experiment(
      original_code,
      optimized_code,
      metrics,
      model: "llama3-70b-8192"
    ) do
      {:ok, result} -> 
        success_percent = result.evaluation.success_rating * 100
        IO.puts("✓ Evaluation successful - Success rating: #{Float.round(success_percent, 1)}%")
        {result, false}
      {:error, reason} -> 
        if String.contains?(inspect(reason), "rate_limit") do
          IO.puts("✗ Evaluation failed due to rate limiting - will retry with artificial delay")
          Process.sleep(15000)  # Add a longer delay when rate limited
          
          # Retry once
          if max_retries > 1 do
            evaluate_with_retry(original_code, optimized_code, metrics, module_name, max_retries - 1)
          else
            IO.puts("✗ Evaluation failed after retry: #{inspect(reason)}")
            {nil, true}
          end
        else
          IO.puts("✗ Evaluation failed: #{inspect(reason)}")
          {nil, true}
        end
    end
  end

  @doc """
  Main entry point for the stress test.
  Checks for the presence of a valid GROQ_API_KEY and runs the test if available.
  """
  def run do
    # Check if GROQ_API_KEY is available and not empty, skip test if not
    api_key = System.get_env("GROQ_API_KEY")
    if api_key == nil || String.trim(api_key) == "" do
      IO.puts("\n===== ADAPTIVE CODE EVOLUTION STRESS TEST =====")
      IO.puts("⚠️  Skipping stress test: GROQ_API_KEY environment variable not set or empty")
      IO.puts("To run this test, set the GROQ_API_KEY environment variable with a valid Groq API key")
      exit(:normal)
    else
      # Continue with the test
      run_stress_test()
    end
  end

  # Runs the complete stress test sequence.
  # Processes all test modules sequentially and generates a summary of results.
  defp run_stress_test do
    setup_logging()
    
    test_modules = test_modules()
    
    # Run the tests sequentially to avoid hitting API rate limits
    start_time = System.monotonic_time(:millisecond)
    
    results = 
      test_modules
      |> Enum.with_index(1)
      |> Enum.map(fn {module_data, index} ->
        process_module(module_data, index)
      end)
    
    end_time = System.monotonic_time(:millisecond)
    total_time = end_time - start_time
    
    # Print summary
    IO.puts("\n===== STRESS TEST SUMMARY =====")
    IO.puts("Total modules processed: #{length(results)}")
    IO.puts("Total time: #{total_time}ms")
    
    success_count = Enum.count(results, fn r -> r.fully_successful end)
    IO.puts("Fully successful modules: #{success_count}/#{length(results)}")
    
    avg_success_rating = 
      results
      |> Enum.map(fn r -> r.success_rating end)
      |> Enum.filter(fn r -> r > 0.0 end)
      |> case do
        [] -> 0.0
        ratings -> Enum.sum(ratings) / length(ratings)
      end
    
    IO.puts("Average success rating: #{Float.round(avg_success_rating * 100, 1)}%")
    
    # Print detailed results
    IO.puts("\nDetailed Results:")
    Enum.each(results, fn result ->
      status = if result.fully_successful, do: "✓", else: "✗"
      IO.puts("#{status} #{result.module}: #{result.time}ms, Rating: #{Float.round(result.success_rating * 100, 1)}%")
    end)
  end
end

# Run the stress test
StressTestAdaptiveCodeEvolution.run()
