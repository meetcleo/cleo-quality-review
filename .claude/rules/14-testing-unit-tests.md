# Unit Test Rules

- Every class must have its public interface tested.
- **No `setup` or `teardown` blocks. No instance variables. Each test is self-contained.**
- Use `ActiveSupport::TestCase` with the `test` method.
- Name method groups using `#instance` or `.singleton` notation.
- Use **Mocha** for mocking and stubbing. Stub dependencies where appropriate.
- Use the most relevant matcher — not raw `assert`/`refute`.
- Aim for **one clear assertion per test**.
- Avoid using the `assert` or `refute` assertions as they are too vague. Prefer `assert_prediate`, `assert_equal` etc.
- **No factory methods in tests.** Use FactoryBot factories defined in `test/factories/` instead of defining helper methods like `create_foo` in test files.
