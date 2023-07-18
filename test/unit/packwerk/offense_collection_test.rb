# typed: true
# frozen_string_literal: true

require "test_helper"

module Packwerk
  class OffenseCollectionTest < Minitest::Test
    include FactoryHelper

    setup do
      @offense_collection = OffenseCollection.new(".")
      @offense = ReferenceOffense.new(
        reference: build_reference,
        violation_type: ReferenceChecking::Checkers::DependencyChecker::VIOLATION_TYPE,
        message: "some message"
      )
    end

    test "#add_violation adds entry and returns true" do
      Packwerk::PackageTodo.any_instance
        .expects(:add_entries)
        .with(@offense.reference, @offense.violation_type)
        .returns(true)

      assert @offense_collection.add_offense(@offense)
      assert @offense_collection.strict_mode_violations.empty?
    end

    test "#add_violation adds entry to strict violations" do
      Packwerk::PackageTodo.any_instance
         .expects(:add_entries)
         .with(@offense.reference, @offense.violation_type)
         .returns(true)

      ReferenceChecking::Checkers::DependencyChecker.any_instance
         .expects(:strict_mode_violation?)
         .with(@offense)
         .returns(true)

      assert @offense_collection.add_offense(@offense)
      assert @offense_collection.strict_mode_violations.any?
    end

    test "#add_violation adds entry to new violations if excluded from strict" do
      @offense_collection = OffenseCollection.new(".", {}, ["some/**"])

      Packwerk::PackageTodo.any_instance
         .expects(:add_entries)
         .with(@offense.reference, @offense.violation_type)
         .returns(true)

      ReferenceChecking::Checkers::DependencyChecker.any_instance
        .expects(:strict_mode_violation?)
        .with(@offense)
        .never

      assert @offense_collection.add_offense(@offense)
      assert @offense_collection.strict_mode_violations.empty?

      @offense_collection = OffenseCollection.new(".")
    end

    test "#stale_violations? returns true if there are stale violations" do
      @offense_collection.add_offense(@offense)
      file_set = Set.new

      Packwerk::PackageTodo.any_instance
        .expects(:stale_violations?)
        .with(file_set)
        .returns(true)

      assert @offense_collection.stale_violations?(file_set)
    end

    test "#stale_violations? returns false if no stale violations" do
      @offense_collection.add_offense(@offense)
      file_set = Set.new

      Packwerk::PackageTodo.any_instance
        .expects(:stale_violations?)
        .with(file_set)
        .returns(false)

      refute @offense_collection.stale_violations?(Set.new)
    end

    test "#listed? returns true if constant is listed in file" do
      package = Package.new(name: "buyer", config: {})
      reference = build_reference(source_package: package)
      package_todo = Packwerk::PackageTodo.new(package, ".")
      package_todo
        .stubs(:listed?)
        .with(reference, violation_type: ReferenceChecking::Checkers::DependencyChecker::VIOLATION_TYPE)
        .returns(true)
      Packwerk::PackageTodo
        .stubs(:new)
        .with(package, "./buyer/package_todo.yml")
        .returns(package_todo)

      offense = Packwerk::ReferenceOffense.new(
        reference: reference,
        violation_type: ReferenceChecking::Checkers::DependencyChecker::VIOLATION_TYPE,
        message: "some message"
      )

      assert @offense_collection.listed?(offense)
    end

    test "#listed? returns false if constant is not listed in file " do
      offense = Packwerk::ReferenceOffense.new(
        reference: build_reference,
        violation_type: ReferenceChecking::Checkers::DependencyChecker::VIOLATION_TYPE,
        message: "some message"
      )

      refute @offense_collection.listed?(offense)
    end
  end
end
