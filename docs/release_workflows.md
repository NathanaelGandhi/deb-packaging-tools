# Release Workflows

## Release Strategy Overview

At a high level, branches represent stages and PRs (GitHub pull requests) represent gates. Code will progress from a development stage to a final release stage through an optional number of intermediate stages. PRs act as the formal gate (between all stages) to facilitate code review, feedback and sign-off.

| Gate | Developer Workflow | PR Example |
| ---- | ------------------ | ---------- |
| Feature development | PR >> `main` | "feat: my new features" |
| Initial release testing | PR >> `release-beta` | "deploy(beta): my new beta release" |
| Final release testing | PR >> `release-candidate` | "deploy(rc): my new rc release" |
| Stable release | PR >> `release` | "deploy(release): my new release" |

## Github Workflows

This repository includes workflows to assist with publishing releases:

- [Beta Release](../.github/workflows/publish-release-beta.yml) (release-beta branch): This workflow creates a GitHub release tagged with a beta identifier. It is intended for pre-release versions and is marked as a prerelease, allowing for testing and feedback before the final release.

- [Release Candidate](../.github/workflows/publish-release-candidate.yml) (release-candidate branch): Use this workflow to create a GitHub prerelease tagged with an rc identifier. This workflow is for release candidates, providing a final testing phase before the stable release.

- [Stable Release](../.github/workflows/publish.yml) (release branch): This workflow publishes a stable GitHub release and is intended for official releases. It does not include prerelease tags and makes the release available as a final version.

## Usage

To create a release using the provided workflows, merge changes into the corresponding release branch. This action triggers the associated workflow to create the release or prerelease.

These workflows are provided for convenience and are optional. Use them as needed based on your release strategy and requirements. Each workflow is designed to streamline tagging and releasing different stages of your project.
