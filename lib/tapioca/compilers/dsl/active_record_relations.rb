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
          root.path(constant) do |model|
            RelationGenerator.new(self, model, constant).generate
          end
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

          sig do
            params(
              compiler: Base,
              model: Parlour::RbiGenerator::Namespace,
              constant: T.class_of(::ActiveRecord::Base)
            ).void
          end
          def initialize(compiler, model, constant)
            @compiler = compiler
            @model = model
            @constant = constant
            @relation_methods_module_name = T.let("GeneratedRelationMethods", String)
            @association_relation_methods_module_name = T.let("GeneratedAssociationRelationMethods", String)
            @common_relation_methods_module_name = T.let("CommonRelationMethods", String)
            @relation_class_name = T.let("PrivateRelation", String)
            @association_relation_class_name = T.let("PrivateAssociationRelation", String)
            @associations_collection_proxy_class_name = T.let("PrivateCollectionProxy", String)
            @relation_methods_module = T.let(
              model.create_module(@relation_methods_module_name),
              Parlour::RbiGenerator::ModuleNamespace
            )
            @association_relation_methods_module = T.let(
              model.create_module(@association_relation_methods_module_name),
              Parlour::RbiGenerator::ModuleNamespace
            )
            @common_relation_methods_module = T.let(
              model.create_module(@common_relation_methods_module_name),
              Parlour::RbiGenerator::ModuleNamespace
            )
          end

          sig { void }
          def generate
            create_classes_and_includes
            create_common_methods
            create_relation_methods
          end

          private

          sig { returns(Parlour::RbiGenerator::Namespace) }
          attr_reader :model

          sig { void }
          def create_classes_and_includes
            model.create_extend(@common_relation_methods_module_name)
            # The model always extends the generated relation module
            model.create_extend(@relation_methods_module_name)
            create_relation_class
            create_association_relation_class
            create_association_collection_proxy_class
          end

          sig { void }
          def create_relation_class
            superclass = "::ActiveRecord::Relation"

            # The relation subclass includes the generated relation module
            model.create_class(@relation_class_name, superclass: superclass) do |klass|
              klass.create_include(@common_relation_methods_module_name)
              klass.create_include(@relation_methods_module_name)
              klass.create_constant("Elem", value: "type_member(fixed: #{@constant})")
            end
          end

          sig { void }
          def create_association_relation_class
            superclass = "::ActiveRecord::AssociationRelation"

            # Association subclasses include the generated association relation module
            model.create_class(@association_relation_class_name, superclass: superclass) do |klass|
              klass.create_include(@common_relation_methods_module_name)
              klass.create_include(@association_relation_methods_module_name)
              klass.create_constant("Elem", value: "type_member(fixed: #{@constant})")

              create_association_methods(klass)
            end
          end

          sig { void }
          def create_association_collection_proxy_class
            superclass = "::ActiveRecord::Associations::CollectionProxy"

            # The relation subclass includes the generated relation module
            model.create_class(@associations_collection_proxy_class_name, superclass: superclass) do |klass|
              klass.create_include(@common_relation_methods_module_name)
              klass.create_include(@association_relation_methods_module_name)
              klass.create_constant("Elem", value: "type_member(fixed: #{@constant})")

              create_association_methods(klass)
              create_collection_proxy_methods(klass)
            end
          end

          sig { params(klass: Parlour::RbiGenerator::ClassNamespace).void }
          def create_association_methods(klass)
            association_methods = ::ActiveRecord::AssociationRelation.instance_methods -
              ::ActiveRecord::Relation.instance_methods

            association_methods.each do |method_name|
              case method_name
              when :insert_all, :insert_all!, :upsert_all
                create_method(
                  klass,
                  method_name,
                  parameters: [
                    Parlour::RbiGenerator::Parameter.new("attributes", type: "T::Array[Hash]"),
                    Parlour::RbiGenerator::Parameter.new("returning:", type: "T::Array[Symbol]", default: "nil"),
                    Parlour::RbiGenerator::Parameter.new(
                      "unique_by:",
                      type: "T.any(T::Array[Symbol], Symbol)",
                      default: "nil"
                    ),
                  ],
                  return_type: "ActiveRecord::Result"
                )
              when :insert, :insert!, :upsert
                create_method(
                  klass,
                  method_name,
                  parameters: [
                    Parlour::RbiGenerator::Parameter.new("attributes", type: "Hash"),
                    Parlour::RbiGenerator::Parameter.new("returning:", type: "T::Array[Symbol]", default: "nil"),
                    Parlour::RbiGenerator::Parameter.new(
                      "unique_by:",
                      type: "T.any(T::Array[Symbol], Symbol)",
                      default: "nil"
                    ),
                  ],
                  return_type: "ActiveRecord::Result"
                )
              when :proxy_association
                create_method(
                  klass,
                  method_name,
                  parameters: [],
                  return_type: "ActiveRecord::Associations::Association"
                )
              end
            end
          end

          sig { params(klass: Parlour::RbiGenerator::ClassNamespace).void }
          def create_collection_proxy_methods(klass)
            const_collection = "T.any(" + [
              @constant.to_s,
              "T::Array[#{@constant}]",
              "T::Array[#{@associations_collection_proxy_class_name}]",
            ].join(", ") + ")"

            collection_proxy_methods = ::ActiveRecord::Associations::CollectionProxy.instance_methods -
              ::ActiveRecord::AssociationRelation.instance_methods

            collection_proxy_methods.each do |method_name|
              case method_name
              when :<<, :append, :concat, :prepend, :push
                create_method(
                  klass,
                  method_name,
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
                  method_name,
                  parameters: [Parlour::RbiGenerator::Parameter.new("*records", type: const_collection)],
                  return_type: "T::Array[#{@constant}]"
                )
              when :load_target
                create_method(
                  klass,
                  method_name,
                  parameters: [],
                  return_type: "T::Array[#{@constant}]"
                )
              when :replace
                create_method(
                  klass,
                  method_name,
                  parameters: [Parlour::RbiGenerator::Parameter.new("other_array", type: const_collection)],
                  return_type: nil
                )
              when :reset_scope
                # skip
              when :scope
                create_method(
                  klass,
                  method_name,
                  parameters: [],
                  return_type: @association_relation_class_name
                )
              when :target
                create_method(
                  klass,
                  method_name,
                  parameters: [],
                  return_type: "T::Array[#{@constant}]"
                )
              end
            end
          end

          sig { void }
          def create_relation_methods
            add_relation_method("all")
            add_relation_method(
              "not",
              parameters: [
                Parlour::RbiGenerator::Parameter.new("opts", type: "T.untyped"),
                Parlour::RbiGenerator::Parameter.new("*rest", type: "T.untyped"),
              ]
            )

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
          end

          sig { void }
          def create_common_methods
            add_common_method("destroy_all", return_type: "T::Array[#{@constant}]")

            ActiveRecord::FinderMethods.instance_methods(false).each do |method_name|
              case method_name
              when :exists?
                add_common_method(
                  "exists?",
                  parameters: [Parlour::RbiGenerator::Parameter.new("conditions", type: "T.untyped", default: ":none")],
                  return_type: "T::Boolean"
                )
              when :include?
                add_common_method(
                  "include?",
                  parameters: [Parlour::RbiGenerator::Parameter.new("record", type: "T.untyped")],
                  return_type: "T::Boolean"
                )
              when :find, :find_by!
                add_common_method(
                  "find",
                  parameters: [Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped")],
                  return_type: "T.untyped"
                )
              when :find_by
                add_common_method(
                  "find_by",
                  parameters: [Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped")],
                  return_type: "T.nilable(#{@constant})"
                )
              when :first, :last, :take
                add_common_method(
                  method_name,
                  parameters: [Parlour::RbiGenerator::Parameter.new("limit", type: "T.untyped", default: "nil")],
                  return_type: "T.untyped"
                )
              when :raise_record_not_found_exception!
                # skip
              else
                add_common_method(
                  method_name,
                  return_type: method_name.to_s.end_with?("!") ? @constant.to_s : "T.nilable(#{@constant})"
                )
              end
            end

            ActiveRecord::Calculations.instance_methods(false).each do |method_name|
              case method_name
              when :average, :maximum, :minimum
                add_common_method(
                  method_name,
                  parameters: [Parlour::RbiGenerator::Parameter.new("column_name", type: "T.any(String, Symbol)")],
                  return_type: "T.nilable(Numeric)"
                )
              when :calculate
                add_common_method(
                  "calculate",
                  parameters: [
                    Parlour::RbiGenerator::Parameter.new("operation", type: "Symbol"),
                    Parlour::RbiGenerator::Parameter.new("column_name", type: "T.any(String, Symbol)"),
                  ],
                  return_type: "T.nilable(Numeric)"
                )
              when :count
                add_common_method(
                  "count",
                  parameters: [Parlour::RbiGenerator::Parameter.new("column_name", type: "T.untyped", default: "nil")],
                  return_type: "T.untyped"
                )
              when :ids
                add_common_method("ids", return_type: "Array")
              when :pick, :pluck
                add_common_method(
                  method_name,
                  parameters: [
                    Parlour::RbiGenerator::Parameter.new("*column_names", type: "T.untyped"),
                  ],
                  return_type: "T.untyped"
                )
              when :sum
                add_common_method(
                  "sum",
                  parameters: [
                    Parlour::RbiGenerator::Parameter.new(
                      "column_name",
                      type: "T.nilable(T.any(String, Symbol))",
                      default: "nil"
                    ),
                    Parlour::RbiGenerator::Parameter.new(
                      "&block",
                      type: "T.nilable(T.proc.params(record: #{@constant}).returns(T.untyped))"
                    ),
                  ],
                  return_type: "T.untyped"
                )
              end
            end

            enumerable_query_methods = %i[any? many? none? one?]
            enumerable_query_methods.each do |method_name|
              add_common_method(
                method_name,
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
              find_or_create_by find_or_create_by! find_or_initialize_by create_or_find_by create_or_find_by!
            ]

            find_or_create_methods.each do |method_name|
              add_common_method(
                method_name,
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

            %i[new build create create!].each do |method_name|
              add_common_method(
                method_name,
                parameters: [
                  Parlour::RbiGenerator::Parameter.new(
                    "attributes",
                    type: "T.nilable(T.any(::Hash, T::Array[::Hash]))",
                    default: "nil"
                  ),
                  Parlour::RbiGenerator::Parameter.new(
                    "&block",
                    type: "T.nilable(T.proc.params(object: #{@constant}).void)",
                  ),
                ],
                return_type: @constant.to_s
              )
            end
          end

          sig do
            params(
              mod: Parlour::RbiGenerator::Namespace,
              name: T.any(Symbol, String),
              parameters: T::Array[Parlour::RbiGenerator::Parameter],
              return_type: T.nilable(String),
              type_parameters: T.nilable(T::Array[Symbol]),
            ).void
          end
          def create_method(mod, name, parameters:, return_type:, type_parameters: nil)
            @compiler.send(
              :create_method,
              mod,
              name.to_s,
              type_parameters: type_parameters,
              parameters: parameters,
              return_type: return_type
            )
          end

          sig do
            params(
              name: T.any(Symbol, String),
              parameters: T::Array[Parlour::RbiGenerator::Parameter],
              return_type: T.nilable(String)
            ).void
          end
          def add_common_method(name, parameters: [], return_type: nil)
            create_method(
              @common_relation_methods_module,
              name,
              parameters: parameters,
              return_type: return_type
            )
          end

          sig { params(name: T.any(Symbol, String), parameters: T::Array[Parlour::RbiGenerator::Parameter]).void }
          def add_relation_method(name, parameters: [])
            create_method(
              @relation_methods_module,
              name,
              parameters: parameters,
              return_type: @relation_class_name
            )
            create_method(
              @association_relation_methods_module,
              name,
              parameters: parameters,
              return_type: @association_relation_class_name
            )
          end
        end
      end
    end
  end
end
