# typed: strict
# frozen_string_literal: true

require "parlour"

begin
  require "active_record"
rescue LoadError
  return
end

module Tapioca
  module Compilers
    module Dsl
      class ActiveRecordRelations < Base
        extend T::Sig

        sig do
          override
            .params(root: ::Parlour::RbiGenerator::Namespace, constant: T.class_of(::ActiveRecord::Base))
            .void
        end
        def decorate(root, constant)
          RelationGenerator.new(self, root, constant).generate
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          ActiveRecord::Base.descendants.reject(&:abstract_class?)
        end

        class RelationGenerator
          extend T::Sig

          MethodDefinition = T.type_alias do
            {
              params: T.nilable(T::Array[Parlour::RbiGenerator::Parameter]),
              return_type: T.nilable(String),
            }
          end

          sig { params(compiler: Base, root: T.untyped, constant: T.class_of(::ActiveRecord::Base)).void }
          def initialize(compiler, root, constant)
            @compiler = compiler
            @root = root
            @constant = constant
            @relation_methods_module_name = T.let(
              "#{constant}::GeneratedRelationMethods",
              String
            )
            @association_relation_methods_module_name = T.let(
              "#{constant}::GeneratedAssociationRelationMethods",
              String
            )
            @relation_class_name = T.let(
              "#{constant}::ActiveRecord_Relation",
              String
            )
            @association_relation_class_name = T.let(
              "#{constant}::ActiveRecord_AssociationRelation",
              String
            )
            @associations_collection_proxy_class_name = T.let(
              "#{constant}::ActiveRecord_Associations_CollectionProxy",
              String
            )
            @relation_methods_module = T.let(
              @root.create_module(@relation_methods_module_name),
              Parlour::RbiGenerator::ModuleNamespace
            )
            @association_relation_methods_module = T.let(
              @root.create_module(@association_relation_methods_module_name),
              Parlour::RbiGenerator::ModuleNamespace
            )
          end

          sig { void }
          def generate
            create_classes_and_includes
            create_common_methods
          end

          private

          sig { void }
          def create_common_methods
            add_relation_method("all")
            add_relation_method(
              "not",
              parameters: [
                Parlour::RbiGenerator::Parameter.new("opts", type: "T.untyped"),
                Parlour::RbiGenerator::Parameter.new("*rest", type: "T.untyped"),
              ]
            )

            add_method("destroy_all", return_type: "T::Array[#{@constant}]")

            query_methods = ActiveRecord::QueryMethods.instance_methods(false)
            query_methods |= ActiveRecord::SpawnMethods.instance_methods(false)

            query_methods.each do |method_name|
              case method_name
              when :_select!, :arel, :build_subquery, :construct_join_dependency, :extensions, :extract_associated
                # skip
              when /(_clause|_values?|=)$/
                # skip
              else
                add_relation_method(
                  method_name.to_s,
                  parameters: [
                    Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped"),
                    Parlour::RbiGenerator::Parameter.new("&blk", type: "T.untyped"),
                  ]
                )
              end
            end

            ActiveRecord::FinderMethods.instance_methods(false).each do |method_name|
              case method_name
              when :exists?
                add_method(
                  "exists?",
                  parameters: [Parlour::RbiGenerator::Parameter.new("conditions", type: "T.untyped", default: ":none")],
                  return_type: "T::Boolean"
                )
              when :find, :find_by!
                add_method(
                  "find",
                  parameters: [Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped")],
                  return_type: "T.untyped"
                )
              when :find_by
                add_method(
                  "find_by",
                  parameters: [Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped")],
                  return_type: "T.nilable(#{@constant})"
                )
              when :first, :last, :take
                add_method(
                  method_name.to_s,
                  parameters: [Parlour::RbiGenerator::Parameter.new("limit", type: "T.untyped", default: "nil")],
                  return_type: "T.untyped"
                )
              when :raise_record_not_found_exception!
                # skip
              else
                add_method(
                  method_name.to_s,
                  return_type: method_name.end_with?("!") ? @constant.to_s : "T.nilable(#{@constant})"
                )
              end
            end

            ActiveRecord::Calculations.instance_methods(false).each do |method_name|
              case method_name
              when :average, :maximum, :minimum
                add_method(
                  method_name.to_s,
                  parameters: [Parlour::RbiGenerator::Parameter.new("column_name", type: "T.any(String, Symbol)")],
                  return_type: "T.nilable(Numeric)"
                )
              when :calculate
                add_method(
                  method_name.to_s,
                  parameters: [
                    Parlour::RbiGenerator::Parameter.new("operation", type: "Symbol"),
                    Parlour::RbiGenerator::Parameter.new("column_name", type: "T.any(String, Symbol)"),
                  ],
                  return_type: "T.nilable(Numeric)"
                )
              when :count
                add_method(
                  "count",
                  parameters: [Parlour::RbiGenerator::Parameter.new("column_name", type: "T.untyped")],
                  return_type: "T.untyped"
                )
              when :ids
                add_method("ids", return_type: "Array")
              when :pick, :pluck
                add_method(
                  "pluck",
                  parameters: [Parlour::RbiGenerator::Parameter.new("*column_names", type: "T.untyped")],
                  return_type: "T.untyped"
                )
              when :sum
                add_method(
                  "sum",
                  parameters: [
                    Parlour::RbiGenerator::Parameter.new(
                      "column_name",
                      type: "T.nilable(T.any(String, Symbol))"
                    ),
                    Parlour::RbiGenerator::Parameter.new(
                      "&block",
                      type: "T.nilable(T.proc.params(record: #{@constant}).returns(Numeric))"
                    ),
                  ],
                  return_type: "Numeric"
                )
              end
            end

            enumerable_query_methods = %i[any? many? none? one?]
            enumerable_query_methods.each do |method_name|
              add_method(
                method_name.to_s,
                parameters: [
                  Parlour::RbiGenerator::Parameter.new(
                    "&block",
                    type: "T.nilable(T.proc.params(record: #{@constant}).returns(T.untyped))"
                  ),
                ],
                return_type: "T::Boolean"
              )
            end

            find_or_create_methods = %i[
              first_or_create first_or_create! first_or_initialize find_or_create_by
              find_or_create_by! find_or_initialize_by create_or_find_by create_or_find_by!
            ]

            find_or_create_methods.each do |method_name|
              add_method(
                method_name.to_s,
                parameters: [
                  Parlour::RbiGenerator::Parameter.new("attributes", type: "T.untyped"),
                  Parlour::RbiGenerator::Parameter.new(
                    "&block",
                    type: "T.nilable(T.proc.params(object: #{@constant}).void)"
                  ),
                ],
                return_type: @constant.to_s
              )
            end

            creation_methods = %i[create create! new build]
            creation_methods.each do |method_name|
              add_method(
                method_name.to_s,
                parameters: [
                  Parlour::RbiGenerator::Parameter.new("attributes", type: "::Hash", default: "{}"),
                  Parlour::RbiGenerator::Parameter.new(
                    "&block",
                    type: "T.nilable(T.proc.params(object: #{@constant}).void)",
                  ),
                ],
                return_type: @constant.to_s
              )
            end
          end

          sig { void }
          def create_classes_and_includes
            # The model always extends the generated relation module
            @root.path(@constant) do |klass|
              klass.create_extend(@relation_methods_module_name)
            end
            create_relation_class
            create_association_relation_class
            create_association_collection_proxy_class
          end

          sig { void }
          def create_relation_class
            superclass = "ActiveRecord::Relation"

            # The relation subclass includes the generated relation module
            @root.create_class(@relation_class_name, superclass: superclass) do |klass|
              klass.create_include(@relation_methods_module_name)
              klass.create_constant("Elem", value: "type_member(fixed: #{@constant})")
            end
          end

          sig { void }
          def create_association_relation_class
            superclass = "ActiveRecord::AssociationRelation"

            # Association subclasses include the generated association relation module
            @root.create_class(@association_relation_class_name, superclass: superclass) do |klass|
              klass.create_include(@association_relation_methods_module_name)
              klass.create_constant("Elem", value: "type_member(fixed: #{@constant})")
            end
          end

          sig { void }
          def create_association_collection_proxy_class
            superclass = "ActiveRecord::Associations::CollectionProxy"

            # The relation subclass includes the generated relation module
            @root.create_class(@associations_collection_proxy_class_name, superclass: superclass) do |klass|
              klass.create_include(@association_relation_methods_module_name)
              klass.create_constant("Elem", value: "type_member(fixed: #{@constant})")

              const_collection = "T.any(" + [
                @constant.to_s,
                "T::Array[#{@constant}]",
                "T::Array[#{@associations_collection_proxy_class_name}]",
              ].join(", ") + ")"

              collection_proxy_methods = ActiveRecord::Associations::CollectionProxy.instance_methods
              collection_proxy_methods -= ActiveRecord::AssociationRelation.instance_methods

              collection_proxy_methods.each do |method_name|
                case method_name
                when :<<, :append, :concat, :prepend, :push
                  create_method(
                    klass,
                    method_name.to_s,
                    parameters: [Parlour::RbiGenerator::Parameter.new("*records", type: const_collection)],
                    return_type: @associations_collection_proxy_class_name
                  )
                when :clear
                  create_method(
                    klass,
                    "clear",
                    parameters: [],
                    return_type: @associations_collection_proxy_class_name
                  )
                when :delete, :destroy
                  create_method(
                    klass,
                    method_name.to_s,
                    parameters: [Parlour::RbiGenerator::Parameter.new("*records", type: const_collection)],
                    return_type: "T::Array[#{@constant}]"
                  )
                when :load_target
                  create_method(
                    klass,
                    method_name.to_s,
                    parameters: [],
                    return_type: "T::Array[#{@constant}]"
                  )
                when :replace
                  create_method(
                    klass,
                    "replace",
                    parameters: [Parlour::RbiGenerator::Parameter.new("other_array", type: const_collection)],
                    return_type: nil
                  )
                when :reset_scope
                  # skip
                when :scope
                  create_method(
                    klass,
                    "scope",
                    parameters: [],
                    return_type: @association_relation_class_name
                  )
                when :target
                  create_method(
                    klass,
                    "target",
                    parameters: [],
                    return_type: "T.untyped"
                  )
                end
              end

              methods = T.let({
                "==": {
                  params: [
                    Parlour::RbiGenerator::Parameter.new("other", type: "T.untyped"),
                  ],
                  return_type: "T::Boolean",
                },
                delete_all: {
                  params: [
                    Parlour::RbiGenerator::Parameter.new("dependent", type: "T.untyped", default: "nil"),
                  ],
                  return_type: "Integer",
                },
                proxy_association: {
                  return_type: "T.untyped",
                },
                reload: {
                  return_type: nil,
                },
                reset: {
                  return_type: nil,
                },
              }, T::Hash[Symbol, MethodDefinition])

              methods.each_pair do |method, props|
                create_method(
                  klass,
                  method.to_s,
                  parameters: props[:params],
                  return_type: props[:returns]
                )
              end
            end
          end

          sig do
            params(
              mod: Parlour::RbiGenerator::Namespace,
              name: String,
              parameters: T::Array[Parlour::RbiGenerator::Parameter],
              return_type: String
            ).void
          end
          def create_method(mod, name, parameters:, return_type:)
            @compiler.send(:create_method, mod, name, parameters: parameters, return_type: return_type)
          end

          sig { params(name: String, parameters: T::Array[Parlour::RbiGenerator::Parameter]).void }
          def add_relation_method(name, parameters: [])
            add_method(
              name,
              parameters: parameters,
              return_type: [@relation_class_name, @association_relation_class_name]
            )
          end

          sig do
            params(
              name: String,
              parameters: T::Array[Parlour::RbiGenerator::Parameter],
              return_type: T.any(String, [String, String])
            ).void
          end
          def add_method(name, parameters: [], return_type: "")
            relation_return = Array(return_type).first
            association_relation_return = Array(return_type).last

            create_method(
              @relation_methods_module,
              name,
              parameters: parameters,
              return_type: relation_return
            )
            create_method(
              @association_relation_methods_module,
              name,
              parameters: parameters,
              return_type: association_relation_return
            )
          end
        end
      end
    end
  end
end
