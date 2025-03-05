defmodule AshSwarm.Extension do
  @moduledoc """
  Base module for AshSwarm extensions.
  
  This module provides common functionality for AshSwarm extensions, including
  lifecycle management, configuration, and utilities.
  """
  
  @doc """
  Initializes an extension with the given configuration.
  
  This is automatically called when an extension is used.
  """
  def init(_extension, config) do
    # Default implementation
    {:ok, config}
  end
  
  @doc """
  Validates an extension's configuration.
  
  This is automatically called when an extension is used.
  """
  def validate(_extension, _config) do
    # Default implementation
    :ok
  end
  
  @doc """
  Defines a module as an AshSwarm extension.
  
  This macro provides common functionality for AshSwarm extensions.
  """
  defmacro __using__(opts) do
    quote do
      @extension_config unquote(opts)
      
      def extension_config do
        @extension_config
      end
      
      def init(config) do
        AshSwarm.Extension.init(__MODULE__, config)
      end
      
      def validate(config) do
        AshSwarm.Extension.validate(__MODULE__, config)
      end
      
      defoverridable init: 1, validate: 1
    end
  end
end