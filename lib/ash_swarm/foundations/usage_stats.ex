defmodule AshSwarm.Foundations.UsageStats do
  @moduledoc """
  Tracks usage statistics for modules and functions in the system.
  
  This module provides the ability to store and retrieve usage statistics
  for code, which is essential for the AdaptiveCodeEvolution pattern to
  make data-driven optimization decisions.
  
  It also provides functions for tracking code generators and their usage
  for the BootstrapEvolutionPipeline pattern.
  """
  
  use GenServer
  
  @table_name :adaptive_code_usage_stats
  @generator_table :code_generators_registry
  @generator_events_table :code_generator_events
  
  @doc """
  Starts the UsageStats server.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Updates usage statistics for a module and action.
  
  ## Parameters
  
    - `module`: The module being used.
    - `action`: The action being performed.
    - `context`: Additional context about the usage.
  
  ## Returns
  
    - `:ok`
  """
  def update_stats(module, action, context \\ %{}) do
    key = get_key(module, action)
    timestamp = DateTime.utc_now()
    
    update = %{
      timestamp: timestamp,
      context: context
    }
    
    GenServer.cast(__MODULE__, {:record_usage, key, update})
    :ok
  end
  
  @doc """
  Gets usage statistics for a module and action.
  
  ## Parameters
  
    - `module`: The module to get statistics for.
    - `action`: The action to get statistics for.
    - `options`: Options for retrieving statistics, such as:
      - `:period`: How far back to look, in seconds (default: all time)
      - `:metrics`: Which metrics to include (default: all)
  
  ## Returns
  
    - A map containing the usage statistics.
  """
  def get_stats(module, action, options \\ []) do
    key = get_key(module, action)
    period = Keyword.get(options, :period, :all)
    metrics = Keyword.get(options, :metrics, [:call_count, :avg_duration, :contexts])
    
    GenServer.call(__MODULE__, {:get_stats, key, period, metrics})
  end
  
  @doc """
  Clears all usage statistics.
  
  ## Returns
  
    - `:ok`
  """
  def clear_stats do
    GenServer.call(__MODULE__, :clear_stats)
  end
  
  @doc """
  Lists all modules and actions that have usage statistics.
  
  ## Returns
  
    - A list of {module, action} tuples.
  """
  def list_tracked_items do
    GenServer.call(__MODULE__, :list_tracked_items)
  end
  
  # GenServer callbacks
  
  @impl true
  def init(_opts) do
    # Create ETS table for storing usage statistics
    table = :ets.new(@table_name, [:named_table, :set, :protected])
    
    # Create table for storing code generators
    generator_table = :ets.new(@generator_table, [:named_table, :set, :protected])
    
    # Create table for storing generator events
    event_table = :ets.new(@generator_events_table, [:named_table, :bag, :protected])
    
    # Store metadata about tracked items
    :ets.insert(table, {:_tracked_items, []})
    
    {:ok, %{
      table: table,
      generator_table: generator_table,
      event_table: event_table
    }}
  end
  
  @impl true
  def handle_cast({:record_usage, key, update}, state) do
    # Get existing data or create new entry
    current_data = case :ets.lookup(state.table, key) do
      [{^key, data}] -> data
      [] -> 
        # This is a new item, add it to the tracked items list
        [{:_tracked_items, tracked_items}] = :ets.lookup(state.table, :_tracked_items)
        [module, action] = String.split(key, ".")
        module = String.to_atom(module)
        new_tracked_items = [{module, action} | tracked_items]
        :ets.insert(state.table, {:_tracked_items, new_tracked_items})
        
        # Initialize empty data
        %{
          usage_history: [],
          call_count: 0,
          first_used_at: update.timestamp,
          last_used_at: update.timestamp,
          contexts: []
        }
    end
    
    # Update the data
    updated_data = %{
      current_data |
      usage_history: [update | current_data.usage_history] |> Enum.take(100),
      call_count: current_data.call_count + 1,
      last_used_at: update.timestamp,
      contexts: [update.context | current_data.contexts] |> Enum.take(20)
    }
    
    # Store updated data
    :ets.insert(state.table, {key, updated_data})
    
    {:noreply, state}
  end
  
  @impl true
  def handle_call({:get_stats, key, period, metrics}, _from, state) do
    result = case :ets.lookup(state.table, key) do
      [{^key, data}] -> 
        # Filter data by period if necessary
        filtered_data = if period == :all do
          data
        else
          cutoff = DateTime.add(DateTime.utc_now(), -period, :second)
          %{
            data |
            usage_history: Enum.filter(
              data.usage_history, 
              fn entry -> DateTime.compare(entry.timestamp, cutoff) in [:gt, :eq] end
            )
          }
        end
        
        # Extract requested metrics
        metrics_map = %{}
        metrics_map = if :call_count in metrics do
          if period == :all do
            Map.put(metrics_map, :call_count, filtered_data.call_count)
          else
            Map.put(metrics_map, :call_count, length(filtered_data.usage_history))
          end
        else
          metrics_map
        end
        
        metrics_map = if :first_used_at in metrics do
          Map.put(metrics_map, :first_used_at, filtered_data.first_used_at)
        else
          metrics_map
        end
        
        metrics_map = if :last_used_at in metrics do
          Map.put(metrics_map, :last_used_at, filtered_data.last_used_at)
        else
          metrics_map
        end
        
        metrics_map = if :contexts in metrics do
          Map.put(metrics_map, :contexts, filtered_data.contexts)
        else
          metrics_map
        end
        
        metrics_map = if :usage_history in metrics do
          Map.put(metrics_map, :usage_history, filtered_data.usage_history)
        else
          metrics_map
        end
        
        metrics_map
        
      [] -> %{error: "No statistics available for #{key}"}
    end
    
    {:reply, result, state}
  end
  
  @impl true
  def handle_call(:clear_stats, _from, state) do
    :ets.delete_all_objects(state.table)
    :ets.insert(state.table, {:_tracked_items, []})
    
    {:reply, :ok, state}
  end
  
  @impl true
  def handle_call(:list_tracked_items, _from, state) do
    [{:_tracked_items, tracked_items}] = :ets.lookup(state.table, :_tracked_items)
    
    {:reply, tracked_items, state}
  end
  
  # Helper functions
  
  defp get_key(module, action) do
    "#{module}.#{action}"
  end
  
  # BootstrapEvolutionPipeline functions
  
  @doc """
  Stores a generator in the registry.
  
  ## Parameters
  
    - `generator`: The generator to store, which should be a map with at least an `id` field.
  
  ## Returns
  
    - `:ok`
  """
  def store_generator(generator) do
    GenServer.call(__MODULE__, {:store_generator, generator})
  end
  
  @doc """
  Gets a generator from the registry.
  
  ## Parameters
  
    - `generator_id`: The ID of the generator to retrieve.
  
  ## Returns
  
    - The generator map if found, or a default empty map if not found.
  """
  def get_generator(generator_id) do
    GenServer.call(__MODULE__, {:get_generator, generator_id})
  end
  
  @doc """
  Records a generation event for a generator.
  
  ## Parameters
  
    - `generator_id`: The ID of the generator.
    - `context`: The context in which the generator was used.
    - `metadata`: Additional metadata about the generation.
  
  ## Returns
  
    - `:ok`
  """
  def record_generation_event(generator_id, context, metadata) do
    event = %{
      generator_id: generator_id,
      context: context,
      metadata: metadata,
      timestamp: DateTime.utc_now()
    }
    
    GenServer.cast(__MODULE__, {:record_generation_event, event})
  end
  
  @doc """
  Analyzes generated code and stores the analysis.
  
  ## Parameters
  
    - `generator_id`: The ID of the generator.
    - `code`: The generated code.
    - `context`: The context in which the generator was used.
  
  ## Returns
  
    - `:ok`
  """
  def analyze_generated_code(generator_id, code, context) do
    analysis = %{
      generator_id: generator_id,
      code_size: String.length(code),
      context: context,
      timestamp: DateTime.utc_now()
    }
    
    GenServer.cast(__MODULE__, {:store_code_analysis, generator_id, analysis})
  end
  
  @doc """
  Gets usage data for a generator.
  
  ## Parameters
  
    - `generator_id`: The ID of the generator.
    - `time_period`: The time period to retrieve data for, either `:all` or a number of seconds.
  
  ## Returns
  
    - A list of generation events for the generator.
  """
  def get_usage_data(generator_id, time_period) do
    GenServer.call(__MODULE__, {:get_generator_usage, generator_id, time_period})
  end
  
  @doc """
  Gets feedback data for a generator.
  
  ## Parameters
  
    - `generator_id`: The ID of the generator.
    - `time_period`: The time period to retrieve data for, either `:all` or a number of seconds.
  
  ## Returns
  
    - A list of feedback events for the generator.
  """
  def get_feedback_data(generator_id, time_period) do
    GenServer.call(__MODULE__, {:get_generator_feedback, generator_id, time_period})
  end
  
  @doc """
  Stores feedback for a generator.
  
  ## Parameters
  
    - `generator_id`: The ID of the generator.
    - `feedback`: The feedback data.
  
  ## Returns
  
    - `:ok`
  """
  def store_generator_feedback(generator_id, feedback) do
    feedback_event = Map.put(feedback, :timestamp, DateTime.utc_now())
    GenServer.cast(__MODULE__, {:store_generator_feedback, generator_id, feedback_event})
  end
  
  # GenServer callbacks for BootstrapEvolutionPipeline
  
  @impl true
  def handle_call({:store_generator, generator}, _from, state) do
    :ets.insert(state.generator_table, {generator.id, generator})
    {:reply, :ok, state}
  end
  
  @impl true
  def handle_call({:get_generator, generator_id}, _from, state) do
    result = case :ets.lookup(state.generator_table, generator_id) do
      [{^generator_id, generator}] -> generator
      [] -> %{}
    end
    
    {:reply, result, state}
  end
  
  @impl true
  def handle_cast({:record_generation_event, event}, state) do
    :ets.insert(state.event_table, {{:generation, event.generator_id}, event})
    {:noreply, state}
  end
  
  @impl true
  def handle_cast({:store_code_analysis, generator_id, analysis}, state) do
    :ets.insert(state.event_table, {{:analysis, generator_id}, analysis})
    {:noreply, state}
  end
  
  @impl true
  def handle_cast({:store_generator_feedback, generator_id, feedback}, state) do
    :ets.insert(state.event_table, {{:feedback, generator_id}, feedback})
    {:noreply, state}
  end
  
  @impl true
  def handle_call({:get_generator_usage, generator_id, time_period}, _from, state) do
    events = :ets.match_object(state.event_table, {{:generation, generator_id}, :_})
    
    filtered_events = if time_period == :all do
      events
    else
      cutoff = DateTime.add(DateTime.utc_now(), -time_period, :second)
      
      Enum.filter(events, fn {_, event} -> 
        DateTime.compare(event.timestamp, cutoff) in [:gt, :eq]
      end)
    end
    
    # Extract just the event data
    events_data = Enum.map(filtered_events, fn {_, event} -> event end)
    
    {:reply, events_data, state}
  end
  
  @impl true
  def handle_call({:get_generator_feedback, generator_id, time_period}, _from, state) do
    feedback = :ets.match_object(state.event_table, {{:feedback, generator_id}, :_})
    
    filtered_feedback = if time_period == :all do
      feedback
    else
      cutoff = DateTime.add(DateTime.utc_now(), -time_period, :second)
      
      Enum.filter(feedback, fn {_, event} -> 
        DateTime.compare(event.timestamp, cutoff) in [:gt, :eq]
      end)
    end
    
    # Extract just the feedback data
    feedback_data = Enum.map(filtered_feedback, fn {_, event} -> event end)
    
    {:reply, feedback_data, state}
  end
end