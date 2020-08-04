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

        sig { override.params(root: ::Parlour::RbiGenerator::Namespace, constant: T.class_of(::ActiveRecord::Base)).void }
        def decorate(root, constant)
          RelationGenerator.new(self, root, constant).generate
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          ActiveRecord::Base.descendants.reject(&:abstract_class?)
        end

        class RelationGenerator
          extend T::Sig

          MethodDefinition = T.type_alias {
            {
              params: T.nilable(T::Array[Parlour::RbiGenerator::Parameter]),
              returns: T.nilable(String)
            }
          }

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
            create_common_relation_methods
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

            [
              :select, :reselect, :order, :reorder, :group, :limit, :offset, :joins, :left_joins, :left_outer_joins,
              :where, :rewhere, :preload, :extract_associated, :eager_load, :includes, :from, :lock, :readonly, :or,
              :having, :create_with, :distinct, :references, :none, :unscope, :optimizer_hints, :merge, :except, :only,
            ].each do |method_name|
              add_relation_method(
                method_name.to_s,
                parameters: [
                  Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped"),
                  Parlour::RbiGenerator::Parameter.new("&blk", type: "T.untyped"),
                ]
              )
            end
          end

          sig { void }
          def create_common_relation_methods
            methods = T.let({
              # ActiveRecord::FinderMethods methods
              exists?: {
                params: [ Parlour::RbiGenerator::Parameter.new("conditions", type: "T.untyped", default: ":none") ],
                returns: "T::Boolean"
              },
              find: {
                params: [ Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped") ],
                returns: "#{@constant}"
              },
              find_by: {
                params: [ Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped") ],
                returns: "T.nilable(#{@constant})"
              },
              find_by!: {
                params: [ Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped") ],
                returns: "#{@constant}"
              },
              first: {
                params: [ Parlour::RbiGenerator::Parameter.new("limit", type: "T.untyped", default: "nil") ],
                returns: "T.untyped"
              },
              first!: {
                returns: "T.nilable(#{@constant})"
              },
              second: {
                returns: "#{@constant}"
              },
              second!: {
                returns: "T.nilable(#{@constant})"
              },
              third: {
                returns: "#{@constant}"
              },
              third!: {
                returns: "T.nilable(#{@constant})"
              },
              fourth: {
                returns: "#{@constant}"
              },
              fourth!: {
                returns: "T.nilable(#{@constant})"
              },
              fifth: {
                returns: "#{@constant}"
              },
              fifth!: {
                returns: "T.nilable(#{@constant})"
              },
              third_to_last: {
                returns: "#{@constant}"
              },
              third_to_last!: {
                returns: "T.nilable(#{@constant})"
              },
              second_to_last: {
                returns: "#{@constant}"
              },
              second_to_last!: {
                returns: "T.nilable(#{@constant})"
              },
              last: {
                params: [ Parlour::RbiGenerator::Parameter.new("limit", type: "T.untyped", default: "nil") ],
                returns: "T.untyped"
              },
              last!: {
                returns: "T.nilable(#{@constant})"
              },
              take: {
                params: [ Parlour::RbiGenerator::Parameter.new("limit", type: "T.untyped", default: "nil") ],
                returns: "T.untyped"
              },
              take!: {
                returns: "T.nilable(#{@constant})"
              },
              # ActiveRecord::Relation methods
              find_or_initialize_by: {
                params: [
                  Parlour::RbiGenerator::Parameter.new("attributes", type: "T.untyped"),
                  Parlour::RbiGenerator::Parameter.new(
                    "&block",
                    type: "T.nilable(T.proc.params(object: #{@constant}).void)"
                  ),
                ],
                returns: "#{@constant}"
              },
              find_or_create_by: {
                params: [
                  Parlour::RbiGenerator::Parameter.new("attributes", type: "T.untyped"),
                  Parlour::RbiGenerator::Parameter.new(
                    "&block",
                    type: "T.nilable(T.proc.params(object: #{@constant}).void)"
                  ),
                ],
                returns: "#{@constant}"
              },
              find_or_create_by!: {
                params: [
                  Parlour::RbiGenerator::Parameter.new("attributes", type: "T.untyped"),
                  Parlour::RbiGenerator::Parameter.new(
                    "&block",
                    type: "T.nilable(T.proc.params(object: #{@constant}).void)"
                  ),
                ],
                returns: "#{@constant}"
              },
              create: {
                params: [
                  Parlour::RbiGenerator::Parameter.new("attributes", type: "::Hash", default: '{}'),
                  Parlour::RbiGenerator::Parameter.new(
                    "&block",
                    type: "T.nilable(T.proc.params(object: #{@constant}).void)",
                  ),
                ],
                returns: "#{@constant}"
              },
              create!: {
                params: [
                  Parlour::RbiGenerator::Parameter.new("attributes", type: "::Hash", default: '{}'),
                  Parlour::RbiGenerator::Parameter.new(
                    "&block",
                    type: "T.nilable(T.proc.params(object: #{@constant}).void)",
                  ),
                ],
                returns: "#{@constant}"
              },
              new: {
                params: [
                  Parlour::RbiGenerator::Parameter.new("attributes", type: "::Hash", default: '{}'),
                  Parlour::RbiGenerator::Parameter.new(
                    "&block",
                    type: "T.nilable(T.proc.params(object: #{@constant}).void)",
                  ),
                ],
                returns: "#{@constant}"
              },
              build: {
                params: [
                  Parlour::RbiGenerator::Parameter.new("attributes", type: "::Hash", default: '{}'),
                  Parlour::RbiGenerator::Parameter.new(
                    "&block",
                    type: "T.nilable(T.proc.params(object: #{@constant}).void)",
                  ),
                ],
                returns: "#{@constant}"
              },
              first_or_create: {
                params: [
                  Parlour::RbiGenerator::Parameter.new("attributes", type: "::Hash", default: '{}'),
                  Parlour::RbiGenerator::Parameter.new(
                    "&block",
                    type: "T.nilable(T.proc.params(object: #{@constant}).void)",
                  ),
                ],
                returns: "#{@constant}"
              },
              first_or_create!: {
                params: [
                  Parlour::RbiGenerator::Parameter.new("attributes", type: "::Hash", default: '{}'),
                  Parlour::RbiGenerator::Parameter.new(
                    "&block",
                    type: "T.nilable(T.proc.params(object: #{@constant}).void)",
                  ),
                ],
                returns: "#{@constant}"
              },
              first_or_initialize: {
                params: [
                  Parlour::RbiGenerator::Parameter.new("attributes", type: "::Hash", default: '{}'),
                  Parlour::RbiGenerator::Parameter.new(
                    "&block",
                    type: "T.nilable(T.proc.params(object: #{@constant}).void)",
                  ),
                ],
                returns: "#{@constant}"
              },
            }, T::Hash[Symbol, MethodDefinition])

            methods.each_pair do |method, props|
              add_method(
                method.to_s,
                parameters: props[:params],
                return_type: props[:returns],
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
            end
          end

          sig { void }
          def create_association_relation_class
            superclass = "ActiveRecord::AssociationRelation"

            # Association subclasses include the generated association relation module
            @root.create_class(@association_relation_class_name, superclass: superclass) do |klass|
              klass.create_include(@association_relation_methods_module_name)
            end
          end

          sig { void }
          def create_association_collection_proxy_class
            superclass = "ActiveRecord::Associations::CollectionProxy"

            # The relation subclass includes the generated relation module
            @root.create_class(@associations_collection_proxy_class_name, superclass: superclass) do |klass|
              klass.create_include(@association_relation_methods_module_name)

              const_collection = "T.any(" + [
                "#{@constant}",
                "T::Array[#{@constant}]",
                "T::Array[#{@associations_collection_proxy_class_name}]"
              ].join(", ") + ")"

              methods = T.let({
                "<<": {
                  params: [
                    Parlour::RbiGenerator::Parameter.new("*records", type: const_collection)
                  ],
                  returns: @associations_collection_proxy_class_name
                },
                "==": {
                  params: [
                    Parlour::RbiGenerator::Parameter.new("other", type: "T.untyped")
                  ],
                  returns: "T::Boolean"
                },
                any?: {
                  returns: "T::Boolean"
                },
                append: {
                  params: [
                    Parlour::RbiGenerator::Parameter.new("*records", type: const_collection)
                  ],
                  returns: @associations_collection_proxy_class_name
                },
                calculate: {
                  params: [
                    Parlour::RbiGenerator::Parameter.new("operation", type: "T.untyped"),
                    Parlour::RbiGenerator::Parameter.new("column_name", type: "T.untyped"),
                  ],
                  returns: "T.untyped"
                },
                clear: {
                  returns: @associations_collection_proxy_class_name
                },
                concat: {
                  params: [
                    Parlour::RbiGenerator::Parameter.new("*records", type: const_collection)
                  ],
                  returns: @associations_collection_proxy_class_name
                },
                delete: {
                  params: [
                    Parlour::RbiGenerator::Parameter.new("*records", type: const_collection)
                  ],
                  returns: "T::Array[#{@constant}]"
                },
                delete_all: {
                  params: [
                    Parlour::RbiGenerator::Parameter.new("dependent", type: "T.untyped", default: "nil")
                  ],
                  returns: "Integer"
                },
                destroy: {
                  params: [
                    Parlour::RbiGenerator::Parameter.new("*records", type: const_collection)
                  ],
                  returns: "T::Array[#{@constant}]"
                },
                destroy_all: {
                  returns: "T::Array[#{@constant}]"
                },
                distinct: {
                  params: [
                    Parlour::RbiGenerator::Parameter.new("value", type: "T::Boolean")
                  ],
                  returns: @associations_collection_proxy_class_name
                },
                empty?: {
                  returns: "T::Boolean"
                },
                include?: {
                  params: [
                    Parlour::RbiGenerator::Parameter.new("record", type: "#{@constant}")
                  ],
                  returns: "T::Boolean"
                },
                length: {
                  returns: "Integer"
                },
                load_target: {
                  returns: nil
                },
                loaded?: {
                  returns: "T::Boolean"
                },
                many?: {
                  returns: "T::Boolean"
                },
                pluck: {
                  params: [
                    Parlour::RbiGenerator::Parameter.new("*column_names", type: "T.untyped")
                  ],
                  returns: "T.untyped"
                },
                proxy_association: {
                  returns: "T.untyped"
                },
                push: {
                  params: [
                    Parlour::RbiGenerator::Parameter.new("*records", type: const_collection)
                  ],
                  returns: @associations_collection_proxy_class_name
                },
                reload: {
                  returns: nil
                },
                replace: {
                  params: [
                    Parlour::RbiGenerator::Parameter.new("other_array", type: const_collection)
                  ],
                  returns: nil
                },
                reset: {
                  returns: nil
                },
                scope: {
                  returns: @association_relation_class_name
                },
                select: {
                  params: [
                    Parlour::RbiGenerator::Parameter.new("*fields", type: "T.any(Symbol, String)"),
                    Parlour::RbiGenerator::Parameter.new(
                      "&blk",
                      type: "T.proc.params(object: #{@constant}).returns(T.untyped)"
                    )
                  ],
                  returns: @associations_collection_proxy_class_name
                },
                size: {
                  returns: "Integer"
                },
                target: {
                  returns: "T.untyped"
                }
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

          sig { params(mod: Parlour::RbiGenerator::Namespace, name: String, parameters: T::Array[Parlour::RbiGenerator::Parameter], return_type: String).void }
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
