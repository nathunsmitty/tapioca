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
      # `Tapioca::Compilers::Dsl::ActiveRecordScope` decorates RBI files for
      # subclasses of `ActiveRecord::Base` which declare
      # [`scope` fields](https://api.rubyonrails.org/classes/ActiveRecord/Scoping/Named/ClassMethods.html#method-i-scope).
      #
      # For example, with the following `ActiveRecord::Base` subclass:
      #
      # ~~~rb
      # class Post < ApplicationRecord
      #   scope :public_kind, -> { where.not(kind: 'private') }
      #   scope :private_kind, -> { where(kind: 'private') }
      # end
      # ~~~
      #
      # this generator will produce the RBI file `post.rbi` with the following content:
      #
      # ~~~rbi
      # # post.rbi
      # # typed: true
      # class Post
      #   extend GeneratedRelationMethods
      #
      #   module GeneratedRelationMethods
      #     sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
      #     def private_kind(*args, &blk); end
      #
      #     sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
      #     def public_kind(*args, &blk); end
      #   end
      # end
      # ~~~
      class ActiveRecordScope < Base
        extend T::Sig

        sig do
          override.params(
            root: Parlour::RbiGenerator::Namespace,
            constant: T.class_of(::ActiveRecord::Base)
          ).void
        end
        def decorate(root, constant)
          method_names = scope_method_names(constant)

          return if method_names.empty?

          root.path(constant) do |model|
            relation_methods_module_name = "GeneratedRelationMethods"
            relation_methods_module = model.create_module(relation_methods_module_name)
            association_relation_methods_module_name = "GeneratedAssociationRelationMethods"
            association_relation_methods_module = model.create_module(association_relation_methods_module_name)

            method_names.each do |scope_method|
              generate_scope_method(
                relation_methods_module,
                scope_method.to_s,
                "PrivateRelation"
              )
              generate_scope_method(
                association_relation_methods_module,
                scope_method.to_s,
                "PrivateAssociationRelation"
              )
            end

            model.create_extend(relation_methods_module_name)
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          ::ActiveRecord::Base.descendants.reject(&:abstract_class?)
        end

        private

        sig { params(constant: T.class_of(::ActiveRecord::Base)).returns(T::Array[Symbol]) }
        def scope_method_names(constant)
          scope_methods = T.let([], T::Array[Symbol])

          # Keep gathering scope methods until we hit "ActiveRecord::Base"
          until constant == ActiveRecord::Base
            scope_methods.concat(constant.send(:generated_relation_methods).instance_methods(false))

            # we are guaranteed to have a superclass that is of type "ActiveRecord::Base"
            constant = T.cast(constant.superclass, T.class_of(ActiveRecord::Base))
          end

          scope_methods
        end

        sig do
          params(
            mod: Parlour::RbiGenerator::Namespace,
            scope_method: String,
            return_type: String
          ).void
        end
        def generate_scope_method(mod, scope_method, return_type)
          create_method(
            mod,
            scope_method,
            parameters: [
              Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped"),
              Parlour::RbiGenerator::Parameter.new("&blk", type: "T.untyped"),
            ],
            return_type: return_type,
          )
        end
      end
    end
  end
end
