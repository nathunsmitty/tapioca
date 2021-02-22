# typed: false
# frozen_string_literal: true

require "spec_helper"

describe("Tapioca::Compilers::Dsl::ActiveRecordRelations") do
  before(:each) do
    require "tapioca/compilers/dsl/active_record_relations"
  end

  subject do
    Tapioca::Compilers::Dsl::ActiveRecordRelations.new
  end

  describe("#initialize") do
    def constants_from(content)
      with_content(content) do
        subject.processable_constants.map(&:to_s).sort
      end
    end

    it("gathers no constants if there are no ActiveRecord classes") do
      assert_empty(subject.processable_constants)
    end

    it("gathers only ActiveRecord constants with no abstract classes") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
        end

        class Product < ActiveRecord::Base
          self.abstract_class = true
        end

        class User
        end
      RUBY

      assert_equal(["Post"], constants_from(content))
    end
  end

  describe("#decorate") do
    def rbi_for(content)
      with_content(content) do
        parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
        subject.decorate(parlour.root, Post)
        parlour.rbi # .tap { |out| $stderr.puts(out) }
      end
    end

    it("generates proper relation classes and modules") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          extend Post::GeneratedRelationMethods
        end

        class Post::PrivateAssociationRelation < ActiveRecord::AssociationRelation
          include Post::GeneratedAssociationRelationMethods
          Elem = type_member(fixed: Post)
        end

        class Post::PrivateCollectionProxy < ActiveRecord::Associations::CollectionProxy
          include Post::GeneratedAssociationRelationMethods
          Elem = type_member(fixed: Post)

          sig { params(records: T.any(Post, T::Array[Post], T::Array[Post::PrivateCollectionProxy])).returns(Post::PrivateCollectionProxy) }
          def <<(*records); end

          sig { params(other: T.untyped).void }
          def ==(other); end

          sig { params(records: T.any(Post, T::Array[Post], T::Array[Post::PrivateCollectionProxy])).returns(Post::PrivateCollectionProxy) }
          def append(*records); end

          sig { returns(Post::PrivateCollectionProxy) }
          def clear; end

          sig { params(records: T.any(Post, T::Array[Post], T::Array[Post::PrivateCollectionProxy])).returns(Post::PrivateCollectionProxy) }
          def concat(*records); end

          sig { params(records: T.any(Post, T::Array[Post], T::Array[Post::PrivateCollectionProxy])).returns(T::Array[Post]) }
          def delete(*records); end

          sig { params(dependent: T.untyped).void }
          def delete_all(dependent = nil); end

          sig { params(records: T.any(Post, T::Array[Post], T::Array[Post::PrivateCollectionProxy])).returns(T::Array[Post]) }
          def destroy(*records); end

          sig { returns(T::Array[Post]) }
          def load_target; end

          sig { params(records: T.any(Post, T::Array[Post], T::Array[Post::PrivateCollectionProxy])).returns(Post::PrivateCollectionProxy) }
          def prepend(*records); end

          sig { void }
          def proxy_association; end

          sig { params(records: T.any(Post, T::Array[Post], T::Array[Post::PrivateCollectionProxy])).returns(Post::PrivateCollectionProxy) }
          def push(*records); end

          sig { void }
          def reload; end

          sig { params(other_array: T.any(Post, T::Array[Post], T::Array[Post::PrivateCollectionProxy])).void }
          def replace(other_array); end

          sig { void }
          def reset; end

          sig { returns(Post::PrivateAssociationRelation) }
          def scope; end

          sig { returns(T.untyped) }
          def target; end
        end

        class Post::PrivateRelation < ActiveRecord::Relation
          include Post::GeneratedRelationMethods
          Elem = type_member(fixed: Post)
        end

        module Post::GeneratedAssociationRelationMethods
          sig { returns(Post::PrivateAssociationRelation) }
          def all; end

          sig { params(block: T.nilable(T.proc.params(record: Post).returns(T.untyped))).returns(T::Boolean) }
          def any?(&block); end

          sig { params(column_name: T.any(String, Symbol)).returns(T.nilable(Numeric)) }
          def average(column_name); end

          sig { params(attributes: ::Hash, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def build(attributes = {}, &block); end

          sig { params(operation: Symbol, column_name: T.any(String, Symbol)).returns(T.nilable(Numeric)) }
          def calculate(operation, column_name); end

          sig { params(column_name: T.untyped).returns(T.untyped) }
          def count(column_name); end

          sig { params(attributes: ::Hash, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def create(attributes = {}, &block); end

          sig { params(attributes: ::Hash, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def create!(attributes = {}, &block); end

          sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def create_or_find_by(attributes, &block); end

          sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def create_or_find_by!(attributes, &block); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def create_with(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def create_with!(*args, &blk); end

          sig { returns(T::Array[Post]) }
          def destroy_all; end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def distinct(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def distinct!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def eager_load(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def eager_load!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def except(*args, &blk); end

          sig { params(conditions: T.untyped).returns(T::Boolean) }
          def exists?(conditions = :none); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def extending(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def extending!(*args, &blk); end

          sig { returns(T.nilable(Post)) }
          def fifth; end

          sig { returns(Post) }
          def fifth!; end

          sig { params(args: T.untyped).returns(T.untyped) }
          def find(*args); end

          sig { params(args: T.untyped).returns(T.untyped) }
          def find(*args); end

          sig { params(args: T.untyped).returns(T.nilable(Post)) }
          def find_by(*args); end

          sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def find_or_create_by(attributes, &block); end

          sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def find_or_create_by!(attributes, &block); end

          sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def find_or_initialize_by(attributes, &block); end

          sig { params(limit: T.untyped).returns(T.untyped) }
          def first(limit = nil); end

          sig { returns(Post) }
          def first!; end

          sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def first_or_create(attributes, &block); end

          sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def first_or_create!(attributes, &block); end

          sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def first_or_initialize(attributes, &block); end

          sig { returns(T.nilable(Post)) }
          def forty_two; end

          sig { returns(Post) }
          def forty_two!; end

          sig { returns(T.nilable(Post)) }
          def fourth; end

          sig { returns(Post) }
          def fourth!; end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def from(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def from!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def group(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def group!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def having(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def having!(*args, &blk); end

          sig { returns(Array) }
          def ids; end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def includes(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def includes!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def joins(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def joins!(*args, &blk); end

          sig { params(limit: T.untyped).returns(T.untyped) }
          def last(limit = nil); end

          sig { returns(Post) }
          def last!; end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def left_joins(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def left_outer_joins(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def left_outer_joins!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def limit(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def limit!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def lock(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def lock!(*args, &blk); end

          sig { params(block: T.nilable(T.proc.params(record: Post).returns(T.untyped))).returns(T::Boolean) }
          def many?(&block); end

          sig { params(column_name: T.any(String, Symbol)).returns(T.nilable(Numeric)) }
          def maximum(column_name); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def merge(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def merge!(*args, &blk); end

          sig { params(column_name: T.any(String, Symbol)).returns(T.nilable(Numeric)) }
          def minimum(column_name); end

          sig { params(attributes: ::Hash, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def new(attributes = {}, &block); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def none(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def none!(*args, &blk); end

          sig { params(block: T.nilable(T.proc.params(record: Post).returns(T.untyped))).returns(T::Boolean) }
          def none?(&block); end

          sig { params(opts: T.untyped, rest: T.untyped).returns(Post::PrivateAssociationRelation) }
          def not(opts, *rest); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def offset(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def offset!(*args, &blk); end

          sig { params(block: T.nilable(T.proc.params(record: Post).returns(T.untyped))).returns(T::Boolean) }
          def one?(&block); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def only(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def or(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def or!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def order(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def order!(*args, &blk); end

          sig { params(column_names: T.untyped).returns(T.untyped) }
          def pluck(*column_names); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def preload(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def preload!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def readonly(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def readonly!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def references(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def references!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def reorder(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def reorder!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def reverse_order(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def reverse_order!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def rewhere(*args, &blk); end

          sig { returns(T.nilable(Post)) }
          def second; end

          sig { returns(Post) }
          def second!; end

          sig { returns(T.nilable(Post)) }
          def second_to_last; end

          sig { returns(Post) }
          def second_to_last!; end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def select(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def skip_query_cache!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def spawn(*args, &blk); end

          sig { params(column_name: T.nilable(T.any(String, Symbol)), block: T.nilable(T.proc.params(record: Post).returns(Numeric))).returns(Numeric) }
          def sum(column_name, &block); end

          sig { params(limit: T.untyped).returns(T.untyped) }
          def take(limit = nil); end

          sig { returns(Post) }
          def take!; end

          sig { returns(T.nilable(Post)) }
          def third; end

          sig { returns(Post) }
          def third!; end

          sig { returns(T.nilable(Post)) }
          def third_to_last; end

          sig { returns(Post) }
          def third_to_last!; end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def unscope(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def unscope!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def where(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateAssociationRelation) }
          def where!(*args, &blk); end
        end

        module Post::GeneratedRelationMethods
          sig { returns(Post::PrivateRelation) }
          def all; end

          sig { params(block: T.nilable(T.proc.params(record: Post).returns(T.untyped))).returns(T::Boolean) }
          def any?(&block); end

          sig { params(column_name: T.any(String, Symbol)).returns(T.nilable(Numeric)) }
          def average(column_name); end

          sig { params(attributes: ::Hash, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def build(attributes = {}, &block); end

          sig { params(operation: Symbol, column_name: T.any(String, Symbol)).returns(T.nilable(Numeric)) }
          def calculate(operation, column_name); end

          sig { params(column_name: T.untyped).returns(T.untyped) }
          def count(column_name); end

          sig { params(attributes: ::Hash, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def create(attributes = {}, &block); end

          sig { params(attributes: ::Hash, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def create!(attributes = {}, &block); end

          sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def create_or_find_by(attributes, &block); end

          sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def create_or_find_by!(attributes, &block); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def create_with(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def create_with!(*args, &blk); end

          sig { returns(T::Array[Post]) }
          def destroy_all; end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def distinct(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def distinct!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def eager_load(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def eager_load!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def except(*args, &blk); end

          sig { params(conditions: T.untyped).returns(T::Boolean) }
          def exists?(conditions = :none); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def extending(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def extending!(*args, &blk); end

          sig { returns(T.nilable(Post)) }
          def fifth; end

          sig { returns(Post) }
          def fifth!; end

          sig { params(args: T.untyped).returns(T.untyped) }
          def find(*args); end

          sig { params(args: T.untyped).returns(T.untyped) }
          def find(*args); end

          sig { params(args: T.untyped).returns(T.nilable(Post)) }
          def find_by(*args); end

          sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def find_or_create_by(attributes, &block); end

          sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def find_or_create_by!(attributes, &block); end

          sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def find_or_initialize_by(attributes, &block); end

          sig { params(limit: T.untyped).returns(T.untyped) }
          def first(limit = nil); end

          sig { returns(Post) }
          def first!; end

          sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def first_or_create(attributes, &block); end

          sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def first_or_create!(attributes, &block); end

          sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def first_or_initialize(attributes, &block); end

          sig { returns(T.nilable(Post)) }
          def forty_two; end

          sig { returns(Post) }
          def forty_two!; end

          sig { returns(T.nilable(Post)) }
          def fourth; end

          sig { returns(Post) }
          def fourth!; end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def from(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def from!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def group(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def group!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def having(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def having!(*args, &blk); end

          sig { returns(Array) }
          def ids; end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def includes(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def includes!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def joins(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def joins!(*args, &blk); end

          sig { params(limit: T.untyped).returns(T.untyped) }
          def last(limit = nil); end

          sig { returns(Post) }
          def last!; end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def left_joins(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def left_outer_joins(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def left_outer_joins!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def limit(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def limit!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def lock(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def lock!(*args, &blk); end

          sig { params(block: T.nilable(T.proc.params(record: Post).returns(T.untyped))).returns(T::Boolean) }
          def many?(&block); end

          sig { params(column_name: T.any(String, Symbol)).returns(T.nilable(Numeric)) }
          def maximum(column_name); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def merge(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def merge!(*args, &blk); end

          sig { params(column_name: T.any(String, Symbol)).returns(T.nilable(Numeric)) }
          def minimum(column_name); end

          sig { params(attributes: ::Hash, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
          def new(attributes = {}, &block); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def none(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def none!(*args, &blk); end

          sig { params(block: T.nilable(T.proc.params(record: Post).returns(T.untyped))).returns(T::Boolean) }
          def none?(&block); end

          sig { params(opts: T.untyped, rest: T.untyped).returns(Post::PrivateRelation) }
          def not(opts, *rest); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def offset(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def offset!(*args, &blk); end

          sig { params(block: T.nilable(T.proc.params(record: Post).returns(T.untyped))).returns(T::Boolean) }
          def one?(&block); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def only(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def or(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def or!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def order(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def order!(*args, &blk); end

          sig { params(column_names: T.untyped).returns(T.untyped) }
          def pluck(*column_names); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def preload(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def preload!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def readonly(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def readonly!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def references(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def references!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def reorder(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def reorder!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def reverse_order(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def reverse_order!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def rewhere(*args, &blk); end

          sig { returns(T.nilable(Post)) }
          def second; end

          sig { returns(Post) }
          def second!; end

          sig { returns(T.nilable(Post)) }
          def second_to_last; end

          sig { returns(Post) }
          def second_to_last!; end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def select(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def skip_query_cache!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def spawn(*args, &blk); end

          sig { params(column_name: T.nilable(T.any(String, Symbol)), block: T.nilable(T.proc.params(record: Post).returns(Numeric))).returns(Numeric) }
          def sum(column_name, &block); end

          sig { params(limit: T.untyped).returns(T.untyped) }
          def take(limit = nil); end

          sig { returns(Post) }
          def take!; end

          sig { returns(T.nilable(Post)) }
          def third; end

          sig { returns(Post) }
          def third!; end

          sig { returns(T.nilable(Post)) }
          def third_to_last; end

          sig { returns(Post) }
          def third_to_last!; end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def unscope(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def unscope!(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def where(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(Post::PrivateRelation) }
          def where!(*args, &blk); end
        end
      RUBY

      assert_equal(expected, rbi_for(content))
    end
  end
end
