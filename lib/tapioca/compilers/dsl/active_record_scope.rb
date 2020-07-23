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
          scope_method_names = T.let(
            constant.send(:generated_relation_methods).instance_methods(false),
            T::Array[Symbol]
          )
          return if scope_method_names.empty?

          relation_methods_module_name = "#{constant}::GeneratedRelationMethods"
          relation_methods_module = root.create_module(relation_methods_module_name)
          association_relation_methods_module_name = "#{constant}::GeneratedAssociationRelationMethods"
          association_relation_methods_module = root.create_module(association_relation_methods_module_name)

          scope_method_names.each do |scope_method|
            generate_scope_method(
              relation_methods_module,
              scope_method.to_s,
              "#{constant}::ActiveRecord_Relation"
            )
            generate_scope_method(
              association_relation_methods_module,
              scope_method.to_s,
              "#{constant}::ActiveRecord_AssociationRelation"
            )
          end

          root.path(constant) do |k|
            k.create_extend(relation_methods_module_name)
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          ::ActiveRecord::Base.descendants.reject(&:abstract_class?)
        end

        private

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
