# Test Isolation

- Unit tests test their unit in isolation. Mock/stub dependencies.
- Do not let unit tests drift into integration tests.

## ActiveRecord Exception

When testing ActiveRecord behaviour that genuinely requires the database (queries, associations, persistence), real DB interaction is acceptable. Use FactoryBot factories for test data.
