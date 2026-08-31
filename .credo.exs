%{
  configs: [
    %{
      name: "default",
      strict: false,
      files: %{
        included: [
          "lib/",
          "src/",
          "test/",
          "web/",
          "apps/*/lib/",
          "apps/*/src/",
          "apps/*/test/",
          "apps/*/web/"
        ],
        excluded: [~r/\/_build\//, ~r/\/deps\//, ~r/\/node_modules\//]
      },
      # Custom checks are compiled with the application. Requiring their source
      # here redefines every module when Credo runs inside this repository.
      requires: [],
      color: true,
      plugins: [],
      parse_timeout: 5000,
      checks: %{
        disabled: [
          {Credo.Check.Readability.Specs, []},
          {Credo.Check.Refactor.ABCSize, []},
          {Credo.Check.Refactor.ModuleDependencies, []},
          {Credo.Check.Warning.LazyLogging, []},
          {Credo.Check.Warning.MixEnv, []},
          {Credo.Check.Warning.UnsafeToAtom, []}
        ],
        enabled: [
          {Credo.Check.Consistency.ExceptionNames, []},
          {Credo.Check.Consistency.LineEndings, []},
          {Credo.Check.Consistency.ParameterPatternMatching, []},
          {Credo.Check.Consistency.SpaceAroundOperators, []},
          {Credo.Check.Consistency.SpaceInParentheses, []},
          {Credo.Check.Consistency.TabsOrSpaces, []},
          # Keep the original tuned policy for the package namespaces. The
          # installer and generator intentionally use qualified Igniter/Rewrite
          # APIs while constructing consumer source files.
          {Credo.Check.Design.AliasUsage,
           [
             priority: :low,
             if_nested_deeper_than: 2,
             if_called_more_often_than: 0,
             excluded_namespaces: ["NbInertia", "Phoenix", "Plug"],
             files: %{
               excluded: [
                 ~r{(^|/)lib/mix/tasks/nb_inertia\.install\.ex$},
                 ~r{(^|/)lib/mix/tasks/nb_inertia\.gen\.realtime\.ex$},
                 ~r{(^|/)lib/mix/tasks/nb\.setup\.credo\.ex$}
               ]
             }
           ]},
          {Credo.Check.Design.TagTODO, [exit_status: 2]},
          {Credo.Check.Design.TagFIXME, []},
          {Credo.Check.Readability.AliasOrder, []},
          {Credo.Check.Readability.FunctionNames, []},
          {Credo.Check.Readability.LargeNumbers, []},
          {Credo.Check.Readability.MaxLineLength, [priority: :low, max_length: 120]},
          {Credo.Check.Readability.ModuleAttributeNames, []},
          {Credo.Check.Readability.ModuleDoc, [files: %{excluded: ["test/"]}]},
          {Credo.Check.Readability.ModuleNames, []},
          {Credo.Check.Readability.ParenthesesOnZeroArityDefs, []},
          {Credo.Check.Readability.ParenthesesInCondition, []},
          {Credo.Check.Readability.PipeIntoAnonymousFunctions, []},
          {Credo.Check.Readability.PredicateFunctionNames, []},
          {Credo.Check.Readability.PreferImplicitTry, []},
          {Credo.Check.Readability.RedundantBlankLines, []},
          {Credo.Check.Readability.Semicolons, []},
          {Credo.Check.Readability.SpaceAfterCommas, []},
          {Credo.Check.Readability.StringSigils, []},
          {Credo.Check.Readability.TrailingBlankLine, []},
          {Credo.Check.Readability.TrailingWhiteSpace, []},
          {Credo.Check.Readability.UnnecessaryAliasExpansion, []},
          {Credo.Check.Readability.VariableNames, []},
          {Credo.Check.Refactor.Apply,
           [
             # Wallaby is optional and these adapters must stay dynamically
             # dispatched so nb_inertia compiles without Wallaby installed.
             files: %{excluded: [~r{(^|/)lib/nb_inertia/wallaby_helpers\.ex$}]}
           ]},
          {Credo.Check.Refactor.CondStatements, []},
          # Keep a meaningful complexity ceiling for normal application code.
          # Installer/generator modules are intentionally branch-heavy because
          # they encode many mutually exclusive source-generation options.
          {Credo.Check.Refactor.CyclomaticComplexity,
           [
             max_complexity: 20,
             files: %{
               excluded: [
                 ~r{(^|/)lib/mix/tasks/nb_inertia\.install\.ex$},
                 ~r{(^|/)lib/mix/tasks/nb_inertia\.gen\.realtime\.ex$},
                 ~r{(^|/)lib/mix/tasks/nb\.setup\.credo\.ex$}
               ]
             }
           ]},
          {Credo.Check.Refactor.FunctionArity, [max_arity: 8]},
          {Credo.Check.Refactor.LongQuoteBlocks, []},
          {Credo.Check.Refactor.MapJoin, []},
          {Credo.Check.Refactor.MatchInCondition, []},
          {Credo.Check.Refactor.NegatedConditionsInUnless, []},
          {Credo.Check.Refactor.NegatedConditionsWithElse, []},
          # Depth five occurs only in source-generation DSL; retain the check
          # for deeper nesting elsewhere without penalizing those templates.
          {Credo.Check.Refactor.Nesting,
           [
             max_nesting: 4,
             files: %{
               excluded: [
                 ~r{(^|/)lib/mix/tasks/nb_inertia\.install\.ex$},
                 ~r{(^|/)lib/mix/tasks/nb_inertia\.gen\.realtime\.ex$}
               ]
             }
           ]},
          {Credo.Check.Refactor.UnlessWithElse, []},
          {Credo.Check.Refactor.WithClauses, []},
          {Credo.Check.Refactor.FilterFilter, []},
          {Credo.Check.Refactor.RejectReject, []},
          {Credo.Check.Refactor.RedundantWithClauseResult, []},
          {Credo.Check.Warning.ApplicationConfigInModuleAttribute, []},
          {Credo.Check.Warning.BoolOperationOnSameValues, []},
          {Credo.Check.Warning.ExpensiveEmptyEnumCheck, []},
          {Credo.Check.Warning.IExPry, []},
          {Credo.Check.Warning.IoInspect, []},
          {Credo.Check.Warning.OperationOnSameValues, []},
          {Credo.Check.Warning.OperationWithConstantResult, []},
          {Credo.Check.Warning.RaiseInsideRescue, []},
          {Credo.Check.Warning.SpecWithStruct, []},
          {Credo.Check.Warning.WrongTestFileExtension, []},
          {Credo.Check.Warning.UnusedEnumOperation, []},
          {Credo.Check.Warning.UnusedFileOperation, []},
          {Credo.Check.Warning.UnusedKeywordOperation, []},
          {Credo.Check.Warning.UnusedListOperation, []},
          {Credo.Check.Warning.UnusedPathOperation, []},
          {Credo.Check.Warning.UnusedRegexOperation, []},
          {Credo.Check.Warning.UnusedStringOperation, []},
          {Credo.Check.Warning.UnusedTupleOperation, []},
          {Credo.Check.Warning.UnsafeExec, []},
          # These fixtures intentionally exercise generic maps/lists/any values
          # and are not production page contracts. Keep the safety check active
          # for all other source and test files.
          {NbInertia.Credo.Check.Warning.UntypedInertiaProps,
           [
             files: %{
               excluded: [
                 "lib/nb_inertia/examples/example_controller.ex",
                 "lib/nb_inertia/perf/fixtures.ex",
                 "test/integration/form_inputs_ts_integration_test.exs",
                 "test/nb_inertia/controller/render_api_test.exs",
                 "test/nb_inertia/dsl_options_test.exs",
                 "test/nb_inertia/form_inputs_test.exs",
                 "test/nb_inertia/modal_props_test.exs",
                 "test/nb_inertia/modal_renderer_test.exs",
                 "test/nb_inertia/type_name_option_test.exs"
               ]
             }
           ]},
          {NbInertia.Credo.Check.Design.DeclareInertiaPage, []},
          {NbInertia.Credo.Check.Design.FormInputsOptionalFieldConsistency, []},
          {NbInertia.Credo.Check.Readability.InertiaPageComponentNameCase, []},
          {NbInertia.Credo.Check.Readability.PropFromAssigns, []},
          {NbInertia.Credo.Check.Warning.AvoidRawInertiaRender, []},
          {NbInertia.Credo.Check.Warning.DirectRepoInController, []},
          {NbInertia.Credo.Check.Warning.InconsistentOptionalProps, []},
          {NbInertia.Credo.Check.Warning.MissingInertiaPageProps, []},
          {NbInertia.Credo.Check.Warning.MissingInertiaSharedProps, []},
          {NbInertia.Credo.Check.Warning.MissingSerializerInertiaProps, []},
          {NbInertia.Credo.Check.Warning.MixedInertiaControllerType, []},
          {NbInertia.Credo.Check.Warning.ModalRequiresBaseUrl, []},
          {NbInertia.Credo.Check.Warning.UseNbInertiaController, []}
        ]
      }
    }
  ]
}
