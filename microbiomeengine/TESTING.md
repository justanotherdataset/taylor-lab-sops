# Tester walkthrough

Start with the built-in synthetic example. It is deliberately small and is not a biological study.

1. Follow README setup and launch. Note installation errors or wording that required outside help.
2. Load the synthetic example. On Data setup, review matched IDs, measurement meaning and available ranks. Change a valid rank and inspect the applied state.
3. On Composition, change top N, grouping/faceting and palette. Apply settings, download the exact table and figure, and check that labels/values agree.
4. Apply a Preparation subset or feature filter. Check the retained sample/feature counts, then reset. Original inputs should remain unchanged.
5. On Alpha, calculate a metric and inspect the source/rank/units. Explore plot styles. Only run comparisons when the example/design declarations actually meet their gates; blocked comparison messages should explain what is missing.
6. On Beta, compare Bray–Curtis with Aitchison and robust Aitchison. For zeros, ordinary Aitchison needs an explicit policy. Review robust completion settings and warnings. Changing an unapplied setting should not silently change the saved result.
7. Save to a new project path, reopen it, then export to a new folder. Inspect the report, exact tables, recorded settings and generated R script. Run the exported script in a fresh R process with the bundle and a new output directory. Keep the project's package library available; compare package versions if replay fails.
8. Report which controls were confusing, what you expected, and whether installation/export worked. Use the repository's microbiome-engine bug or usability template.

Do not use one illustrative pseudocount/rank as a default for your study. Do not declare synthetic comparison units as evidence for real data. Public reports should contain safe synthetic examples and redacted logs, not sensitive project inputs or RDS objects.

Known remaining improvements: stage-specific code/data chooser, visual style editor, narrow-window and screen-reader checks. The app already exports data/code and supports manual styles. See RELEASE-VALIDATION.md for executed checks and limitations of this release.
