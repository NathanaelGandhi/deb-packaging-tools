# <!-- <Repository name> -->

<!-- <About/description> -->

## Getting Started

<!-- ### Prerequisites -->

### Installation

- Clone this repo locally.

  ```sh
  git clone <repository-url>
  ```

<!-- ### Usage -->

---

## Development

### Git Hooks

- Install [pre-commit](https://pre-commit.com/#install) on your system.

- Install pre-commit hooks into your local repo clone.

  ```sh
  pre-commit install
  ```

### Release Management

<!-- This repository does not follow a release branching strategy. -->
"This repository follows a release branching strategy that publishes stable versions to the `release` branch."
<!-- This repository follows a release branching strategy that starts with `release-candidate` and publishes stable versions to `release`. -->
<!-- This repository follows a release branching strategy that begins with `release-beta`, progresses to `release-candidate`, and publishes stable versions to `release`. -->

This repository automatically creates releases from corresponding release branches. See [release_workflows.md](docs/release_workflows.md).

### Updating from the Template Repository

Fetch the latest changes from the `release` branch of the _remote template repository_, and then merge those changes into your current branch, allowing for unrelated histories.

- Fetch upstream template via HTTPS:

  ```sh
  git fetch https://github.com/NathanaelGandhi/template-repo release \
    && git merge FETCH_HEAD --allow-unrelated-histories
  ```

- Fetch upstream template via SSH:

  ```sh
  git fetch git@github.com:NathanaelGandhi/template-repo.git release \
    && git merge FETCH_HEAD --allow-unrelated-histories
  ```

_If there are merge conflicts, resolve them, `git add` the changes, and continue the merge with `git commit`._

---

## Code Owners

For details on code ownership and responsibilities, check out the [CODEOWNERS](docs/CODEOWNERS) file.

---

## License

For information about the project's licensing, please see the [LICENSE](LICENSE) file.

---

## Additional Documentation

For additional docs, check out the [docs](docs/) folder.
