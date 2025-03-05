defmodule AshSwarm.Foundations.MetaResourceFramework do
  @moduledoc """
  Implements the Meta-Resource Framework Pattern, providing a foundation for 
  generating and managing meta-resources.
  
  This framework serves as the basis for more advanced meta-resource frameworks,
  such as the Intelligent Meta-Resource Framework.
  """
  
  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :resource_definitions, accumulate: true)
      Module.register_attribute(__MODULE__, :code_generators, accumulate: true)
      
      @before_compile AshSwarm.Foundations.MetaResourceFramework
      
      import AshSwarm.Foundations.MetaResourceFramework, only: [
        resource_definition: 2,
        code_generator: 2
      ]
    end
  end
  
  defmacro __before_compile__(_env) do
    quote do
      def resource_definitions do
        @resource_definitions
      end
      
      def code_generators do
        @code_generators
      end
      
      def generate_resource(resource_type, params) do
        definition = Enum.find(resource_definitions(), fn def -> 
          def.type == resource_type
        end)
        
        if definition do
          definition.generator_fn.(params)
        else
          {:error, "No resource definition found for type: #{resource_type}"}
        end
      end
      
      def generate_code(resource, code_type) do
        generator = Enum.find(code_generators(), fn gen -> 
          gen.type == code_type
        end)
        
        if generator do
          generator.generator_fn.(resource)
        else
          {:error, "No code generator found for type: #{code_type}"}
        end
      end
    end
  end
  
  defmacro resource_definition(type, opts) do
    quote do
      definition = %{
        type: unquote(type),
        description: unquote(opts[:description] || ""),
        schema: unquote(opts[:schema] || %{}),
        generator_fn: unquote(opts[:generator])
      }
      
      @resource_definitions definition
    end
  end
  
  defmacro code_generator(type, opts) do
    quote do
      generator = %{
        type: unquote(type),
        description: unquote(opts[:description] || ""),
        generator_fn: unquote(opts[:generator])
      }
      
      @code_generators generator
    end
  end
end