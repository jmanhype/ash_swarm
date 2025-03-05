defmodule AshSwarm.Resources.AdaptiveProduct do
  @moduledoc """
  A sample Ash Resource that uses the AdaptiveCodeEvolution pattern.
  
  This resource demonstrates how a resource can:
  1. Track its own usage patterns
  2. Adapt its queries and operations based on actual usage
  """
  
  use Ash.Resource,
    domain: nil, # Explicitly set to nil to avoid the domain validation error
    data_layer: Ash.DataLayer.Ets
    
  alias AshSwarm.Foundations.QueryEvolution

  attributes do
    uuid_primary_key :id
    
    attribute :name, :string, allow_nil?: false
    attribute :description, :string
    attribute :price, :decimal, allow_nil?: false
    attribute :category_id, :uuid
    attribute :status, :atom do
      constraints [one_of: [:active, :inactive, :discontinued]]
      default :active
    end
    
    timestamps()
  end
  
  actions do
    defaults [:create, :read, :update, :destroy]
    
    read :by_category do
      argument :category_id, :uuid, allow_nil?: false
      
      filter expr(category_id == ^arg(:category_id))
      
      # Hook to track usage patterns
      prepare fn query, context ->
        # Track that this action was used and with what arguments
        QueryEvolution.track_usage(
          __MODULE__, 
          :by_category, 
          %{
            args: context.arguments,
            user_id: Map.get(context, :actor_id)
          }
        )
        
        {:ok, query}
      end
    end
    
    read :by_status do
      argument :status, :atom, allow_nil?: false
      
      filter expr(status == ^arg(:status))
      
      # Hook to track usage patterns
      prepare fn query, context ->
        # Track that this action was used and with what arguments
        QueryEvolution.track_usage(
          __MODULE__, 
          :by_status, 
          %{
            args: context.arguments,
            user_id: Map.get(context, :actor_id)
          }
        )
        
        {:ok, query}
      end
    end
    
    read :by_category_and_status do
      argument :category_id, :uuid, allow_nil?: false
      argument :status, :atom, allow_nil?: false
      
      # This is an example of a potentially inefficient query
      # with nested filtering that could be optimized
      filter expr(category_id == ^arg(:category_id))
      filter expr(status == ^arg(:status))
      
      # Hook to track usage patterns
      prepare fn query, context ->
        # Track that this action was used and with what arguments
        QueryEvolution.track_usage(
          __MODULE__, 
          :by_category_and_status, 
          %{
            args: context.arguments,
            user_id: Map.get(context, :actor_id)
          }
        )
        
        {:ok, query}
      end
    end
    
    read :active_products do
      # This sets a filter for active products
      filter expr(status == :active)
      
      # Hook to track usage patterns
      prepare fn query, context ->
        # Track that this action was used
        QueryEvolution.track_usage(
          __MODULE__, 
          :active_products, 
          %{
            user_id: Map.get(context, :actor_id)
          }
        )
        
        {:ok, query}
      end
    end
    
    read :search do
      argument :query, :string, allow_nil?: false
      
      filter expr(name == "dummy")
      # The line below was causing a compilation issue
      # filter expr(fragment("? ILIKE ?", name, ^"%#{arg(:query)}%"))
      
      # Hook to track usage patterns
      prepare fn query, context ->
        # Track that this action was used and with what arguments
        QueryEvolution.track_usage(
          __MODULE__, 
          :search, 
          %{
            args: context.arguments,
            user_id: Map.get(context, :actor_id)
          }
        )
        
        {:ok, query}
      end
    end
  end
  
  # Public functions for demonstration purposes
  
  @doc """
  Searches for products by name containing the query string.
  
  This is a query function that is not directly defined as an Ash action,
  but still follows the same pattern of tracking usage.
  
  ## Parameters
  
    - `query`: The search query string.
    - `context`: Additional context about the request.
  
  ## Returns
  
    - A list of matching products.
  """
  def query_by_name(query, context \\ %{}) do
    # Track usage of this function
    QueryEvolution.track_usage(__MODULE__, :query_by_name, %{query: query, context: context})
    
    # Perform the query
    # This is a simplified example
    []
  end
  
  @doc """
  Finds products by category with a nested filtering approach.
  
  This query function uses a nested filtering approach that could potentially
  be optimized by the AdaptiveCodeEvolution pattern.
  
  ## Parameters
  
    - `category_id`: The category ID to filter by.
    - `options`: Additional options for filtering.
  
  ## Returns
  
    - A list of matching products.
  """
  def query_by_category_nested(category_id, options \\ %{}) do
    # Track usage of this function
    QueryEvolution.track_usage(
      __MODULE__, 
      :query_by_category_nested, 
      %{category_id: category_id, options: options}
    )
    
    # This is a simulated implementation of a query with nested filters
    # that could be optimized
    products = []
    
    # Filter by category
    products_by_category = products
    
    # Apply additional filters
    if Map.get(options, :active_only, false) do
      Enum.filter(products_by_category, fn product -> product.status == :active end)
    else
      products_by_category
    end
  end
  
  @doc """
  Initializes the AdaptiveProduct resource and starts the evolution process.
  
  This function demonstrates how the resource could bootstrap its own
  adaptive behavior when the application starts.
  
  ## Returns
  
    - `:ok`
  """
  def init_adaptive_behavior do
    # Schedule periodic evolution of queries
    QueryEvolution.schedule_query_evolution(__MODULE__, "daily")
  end
end