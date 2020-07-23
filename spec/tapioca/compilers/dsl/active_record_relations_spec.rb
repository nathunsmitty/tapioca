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
        parlour.rbi#.tap { |out| $stderr.puts(out) }
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

      class Post::ActiveRecord_AssociationRelation < ActiveRecord::AssociationRelation
        include Post::GeneratedAssociationRelationMethods
      end

      class Post::ActiveRecord_Associations_CollectionProxy < ActiveRecord::Associations::CollectionProxy
        include Post::GeneratedAssociationRelationMethods

        sig { params(records: T.any(Post, T::Array[Post], T::Array[Post::ActiveRecord_Associations_CollectionProxy])).returns(Post::ActiveRecord_Associations_CollectionProxy) }
        def <<(*records); end

        sig { params(other: T.untyped).returns(T::Boolean) }
        def ==(other); end

        sig { returns(T::Boolean) }
        def any?; end

        sig { params(records: T.any(Post, T::Array[Post], T::Array[Post::ActiveRecord_Associations_CollectionProxy])).returns(Post::ActiveRecord_Associations_CollectionProxy) }
        def append(*records); end

        sig { params(operation: T.untyped, column_name: T.untyped).returns(T.untyped) }
        def calculate(operation, column_name); end

        sig { returns(Post::ActiveRecord_Associations_CollectionProxy) }
        def clear; end

        sig { params(records: T.any(Post, T::Array[Post], T::Array[Post::ActiveRecord_Associations_CollectionProxy])).returns(Post::ActiveRecord_Associations_CollectionProxy) }
        def concat(*records); end

        sig { params(records: T.any(Post, T::Array[Post], T::Array[Post::ActiveRecord_Associations_CollectionProxy])).returns(T::Array[Post]) }
        def delete(*records); end

        sig { params(dependent: T.untyped).returns(Integer) }
        def delete_all(dependent = nil); end

        sig { params(records: T.any(Post, T::Array[Post], T::Array[Post::ActiveRecord_Associations_CollectionProxy])).returns(T::Array[Post]) }
        def destroy(*records); end

        sig { returns(T::Array[Post]) }
        def destroy_all; end

        sig { params(value: T::Boolean).returns(Post::ActiveRecord_Associations_CollectionProxy) }
        def distinct(value); end

        sig { returns(T::Boolean) }
        def empty?; end

        sig { params(record: Post).returns(T::Boolean) }
        def include?(record); end

        sig { returns(Integer) }
        def length; end

        sig { void }
        def load_target; end

        sig { returns(T::Boolean) }
        def loaded?; end

        sig { returns(T::Boolean) }
        def many?; end

        sig { returns(T.untyped) }
        def proxy_association; end

        sig { params(records: T.any(Post, T::Array[Post], T::Array[Post::ActiveRecord_Associations_CollectionProxy])).returns(Post::ActiveRecord_Associations_CollectionProxy) }
        def push(*records); end

        sig { void }
        def reload; end

        sig { params(other_array: T.any(Post, T::Array[Post], T::Array[Post::ActiveRecord_Associations_CollectionProxy])).void }
        def replace(other_array); end

        sig { void }
        def reset; end

        sig { returns(Post::ActiveRecord_AssociationRelation) }
        def scope; end

        sig { params(fields: T.any(Symbol, String), blk: T.proc.params(object: Post).returns(T.untyped)).returns(Post::ActiveRecord_Associations_CollectionProxy) }
        def select(*fields, &blk); end

        sig { returns(Integer) }
        def size; end

        sig { returns(T.untyped) }
        def target; end
      end

      class Post::ActiveRecord_Relation < ActiveRecord::Relation
        include Post::GeneratedRelationMethods
      end

      module Post::GeneratedAssociationRelationMethods
        sig { returns(Post::ActiveRecord_AssociationRelation) }
        def all; end

        sig { params(attributes: ::Hash, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
        def build(attributes = {}, &block); end

        sig { params(attributes: ::Hash, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
        def create(attributes = {}, &block); end

        sig { params(attributes: ::Hash, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
        def create!(attributes = {}, &block); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def create_with(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def distinct(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def eager_load(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def except(*args); end

        sig { params(conditions: T.untyped).returns(T::Boolean) }
        def exists?(conditions = :none); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def extract_associated(*args); end

        sig { returns(Post) }
        def fifth; end

        sig { returns(T.nilable(Post)) }
        def fifth!; end

        sig { params(args: T.untyped).returns(Post) }
        def find(*args); end

        sig { params(args: T.untyped).returns(T.nilable(Post)) }
        def find_by(*args); end

        sig { params(args: T.untyped).returns(Post) }
        def find_by!(*args); end

        sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
        def find_or_create_by(attributes, &block); end

        sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
        def find_or_create_by!(attributes, &block); end

        sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
        def find_or_initialize_by(attributes, &block); end

        sig { params(limit: T.untyped).returns(T.untyped) }
        def first(limit = nil); end

        sig { returns(T.nilable(Post)) }
        def first!; end

        sig { params(attributes: ::Hash, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
        def first_or_create(attributes = {}, &block); end

        sig { params(attributes: ::Hash, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
        def first_or_create!(attributes = {}, &block); end

        sig { params(attributes: ::Hash, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
        def first_or_initialize(attributes = {}, &block); end

        sig { returns(Post) }
        def fourth; end

        sig { returns(T.nilable(Post)) }
        def fourth!; end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def from(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def group(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def having(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def includes(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def joins(*args); end

        sig { params(limit: T.untyped).returns(T.untyped) }
        def last(limit = nil); end

        sig { returns(T.nilable(Post)) }
        def last!; end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def left_joins(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def left_outer_joins(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def limit(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def lock(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def merge(*args); end

        sig { params(attributes: ::Hash, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
        def new(attributes = {}, &block); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def none(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def offset(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def only(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def optimizer_hints(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def or(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def order(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def preload(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def readonly(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def references(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def reorder(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def reselect(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def rewhere(*args); end

        sig { returns(Post) }
        def second; end

        sig { returns(T.nilable(Post)) }
        def second!; end

        sig { returns(Post) }
        def second_to_last; end

        sig { returns(T.nilable(Post)) }
        def second_to_last!; end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def select(*args); end

        sig { params(limit: T.untyped).returns(T.untyped) }
        def take(limit = nil); end

        sig { returns(T.nilable(Post)) }
        def take!; end

        sig { returns(Post) }
        def third; end

        sig { returns(T.nilable(Post)) }
        def third!; end

        sig { returns(Post) }
        def third_to_last; end

        sig { returns(T.nilable(Post)) }
        def third_to_last!; end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def unscope(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_AssociationRelation) }
        def where(*args); end
      end

      module Post::GeneratedRelationMethods
        sig { returns(Post::ActiveRecord_Relation) }
        def all; end

        sig { params(attributes: ::Hash, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
        def build(attributes = {}, &block); end

        sig { params(attributes: ::Hash, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
        def create(attributes = {}, &block); end

        sig { params(attributes: ::Hash, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
        def create!(attributes = {}, &block); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def create_with(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def distinct(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def eager_load(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def except(*args); end

        sig { params(conditions: T.untyped).returns(T::Boolean) }
        def exists?(conditions = :none); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def extract_associated(*args); end

        sig { returns(Post) }
        def fifth; end

        sig { returns(T.nilable(Post)) }
        def fifth!; end

        sig { params(args: T.untyped).returns(Post) }
        def find(*args); end

        sig { params(args: T.untyped).returns(T.nilable(Post)) }
        def find_by(*args); end

        sig { params(args: T.untyped).returns(Post) }
        def find_by!(*args); end

        sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
        def find_or_create_by(attributes, &block); end

        sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
        def find_or_create_by!(attributes, &block); end

        sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
        def find_or_initialize_by(attributes, &block); end

        sig { params(limit: T.untyped).returns(T.untyped) }
        def first(limit = nil); end

        sig { returns(T.nilable(Post)) }
        def first!; end

        sig { params(attributes: ::Hash, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
        def first_or_create(attributes = {}, &block); end

        sig { params(attributes: ::Hash, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
        def first_or_create!(attributes = {}, &block); end

        sig { params(attributes: ::Hash, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
        def first_or_initialize(attributes = {}, &block); end

        sig { returns(Post) }
        def fourth; end

        sig { returns(T.nilable(Post)) }
        def fourth!; end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def from(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def group(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def having(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def includes(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def joins(*args); end

        sig { params(limit: T.untyped).returns(T.untyped) }
        def last(limit = nil); end

        sig { returns(T.nilable(Post)) }
        def last!; end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def left_joins(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def left_outer_joins(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def limit(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def lock(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def merge(*args); end

        sig { params(attributes: ::Hash, block: T.nilable(T.proc.params(object: Post).void)).returns(Post) }
        def new(attributes = {}, &block); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def none(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def offset(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def only(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def optimizer_hints(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def or(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def order(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def preload(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def readonly(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def references(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def reorder(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def reselect(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def rewhere(*args); end

        sig { returns(Post) }
        def second; end

        sig { returns(T.nilable(Post)) }
        def second!; end

        sig { returns(Post) }
        def second_to_last; end

        sig { returns(T.nilable(Post)) }
        def second_to_last!; end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def select(*args); end

        sig { params(limit: T.untyped).returns(T.untyped) }
        def take(limit = nil); end

        sig { returns(T.nilable(Post)) }
        def take!; end

        sig { returns(Post) }
        def third; end

        sig { returns(T.nilable(Post)) }
        def third!; end

        sig { returns(Post) }
        def third_to_last; end

        sig { returns(T.nilable(Post)) }
        def third_to_last!; end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def unscope(*args); end

        sig { params(args: T.untyped).returns(Post::ActiveRecord_Relation) }
        def where(*args); end
      end
    RUBY

      assert_equal(expected, rbi_for(content))
    end
  end
end
