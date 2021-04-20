"""Definitions for handling Bazel repositories used by the Apple rules."""

load(
    "@bazel_tools//tools/build_defs/repo:http.bzl",
    "http_archive",
)

def _maybe(repo_rule, name, **kwargs):
    """Executes the given repository rule if it hasn't been executed already.

    Args:
      repo_rule: The repository rule to be executed (e.g.,
          `http_archive`.)
      name: The name of the repository to be defined by the rule.
      **kwargs: Additional arguments passed directly to the repository rule.
    """
    if not native.existing_rule(name):
        repo_rule(name = name, **kwargs)

def github_repo(name, project, repo, ref, sha256 = None):
    """Downloads a repository from GitHub as a tarball.

    Args:
        name: The name of the repository.
        project: The project (user or organization) on GitHub that hosts the repository.
        repo: The name of the repository on GitHub.
        ref: The reference to be downloaded. Can be any named ref, e.g. a commit, branch, or tag.
        sha256: The sha256 of the downloaded tarball.
    """

    github_url = "https://github.com/{project}/{repo}/archive/{ref}.zip".format(
        project = project,
        repo = repo,
        ref = ref,
    )
    http_archive(
        name = name,
        strip_prefix = "%s-%s" % (repo, ref.replace("/", "-")),
        url = github_url,
        sha256 = sha256,
        canonical_id = github_url,
    )

def rules_ios_dependencies():
    """Fetches repositories that are dependencies of the `rules_apple` workspace.
    """
    _maybe(
        github_repo,
        name = "build_bazel_rules_apple",
        ref = "0.31.1",
        project = "bazelbuild",
        repo = "rules_apple",
        sha256 = "0d95a266753e133302662721d0a924e0c57f198825d89813131a75e92ec6b1bb",
    )

    # TODO: rebase fork on tag 0.20.0 of rules_swift.
    # Note: this ref is a cherry-pick of the rules_swift PR
    # https://github.com/bazelbuild/rules_swift/pull/567
    _maybe(
        github_repo,
        name = "build_bazel_rules_swift",
        ref = "0.20.0",
        project = "bazelbuild",
        repo = "rules_swift",
        sha256 = "7214a8e65b57c9d39eb2dd184c4eccef1e0dc03770dde917531ba315f94f851d",
    )

    _maybe(
        github_repo,
        name = "build_bazel_apple_support",
        ref = "0.10.0",
        project = "bazelbuild",
        repo = "apple_support",
        sha256 = "856ec8129b513443b11043cd96553b324ac87e5618b782af6dde6f8ddba52c43",
    )

    _maybe(
        http_archive,
        name = "bazel_skylib",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
        ],
        sha256 = "1c531376ac7e5a180e0237938a2536de0c54d93f5c278634818e0efc952dd56c",
    )

    # Note: it relies on `index-import` to import indexes. Longer term this
    # dependency may be added by rules_swift
    # This release is a build of this PR https://github.com/lyft/index-import/pull/53
    _maybe(
        http_archive,
        name = "build_bazel_rules_swift_index_import",
        build_file_content = """\
load("@bazel_skylib//rules:native_binary.bzl", "native_binary")

native_binary(
    name = "index_import",
    src = "index-import",
    out = "index-import",
    visibility = ["//visibility:public"],
)

native_binary(
    name = "validate_index",
    src = "validate-index",
    out = "validate-index",
    visibility = ["//visibility:public"],
)

native_binary(
    name = "absolute_unit",
    src = "absolute-unit",
    out = "absolute-unit",
    visibility = ["//visibility:public"],
)
""",
        canonical_id = "index-import-5.3.2.5",
        urls = ["https://github.com/bazel-ios/index-import/releases/download/5.3.2.5/index-import.zip"],
        sha256 = "79e9b2cd3e988155b86668c56d95705e1a4a7c7b6d702ff5ded3a18d1291a39a",
    )

    _maybe(
        http_archive,
        name = "com_github_yonaskolb_xcodegen",
        build_file_content = """\
load("@bazel_skylib//rules:native_binary.bzl", "native_binary")

native_binary(
    name = "xcodegen",
    src = "bin/xcodegen",
    out = "xcodegen",
    data = glob(["share/**/*"]),
    visibility = ["//visibility:public"],
)
""",
        canonical_id = "xcodegen-2.18.0-12-g04d6749",
        sha256 = "3742eee89850cea75367b0f67662a58da5765f66c1be9b4189a59529b4e5099e",
        strip_prefix = "xcodegen",
        urls = ["https://github.com/segiddins/XcodeGen/releases/download/2.18.0-12-g04d6749/xcodegen.zip"],
    )
