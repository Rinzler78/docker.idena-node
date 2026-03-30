## ADDED Requirements

### Requirement: MIT License File Present
The repository MUST contain a `LICENSE` file at the root level whose content is the
standard MIT License text, listing the current copyright year and `Rinzler78` as author.
The README badge `[![License: MIT](…)]` MUST link to this file via the relative path
`./LICENSE`.

#### Scenario: LICENSE file is present and valid
- **WHEN** a user visits the repository root on GitHub
- **THEN** a `LICENSE` file is visible
- **AND** its content matches the standard MIT License template
- **AND** the copyright line reads `Copyright (c) 2025 Rinzler78`

#### Scenario: README badge links to LICENSE
- **WHEN** a user clicks the `License: MIT` badge in `README.md`
- **THEN** they are navigated to the `LICENSE` file in the repository
- **AND** the file displays the full MIT License text
