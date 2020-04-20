load("@build_bazel_rules_apple//apple:ios.bzl", rules_apple_ios_application = "ios_application")
load("//rules:library.bzl", "apple_library", "write_file")

_IOS_APPLICATION_KWARGS = [
    "bundle_id",
    "env",
    "minimum_os_version",
    "test_host",
    "families",
    "entitlements",
    "visibility",
    "launch_storyboard",
    "frameworks",
]

def ios_application(name, apple_library = apple_library, **kwargs):
    """
    Builds and packages an iOS application.

    Args:
        name: The name of the iOS application.
        apple_library: The macro used to package sources into a library.
        kwargs: Arguments passed to the apple_library and ios_application rules as appropriate.
    """
    infoplists = kwargs.pop("infoplists", [])
    application_kwargs = {arg: kwargs.pop(arg) for arg in _IOS_APPLICATION_KWARGS if arg in kwargs}
    library = apple_library(name = name, namespace_is_module_name = False, **kwargs)

    if not infoplists:
        infoplists += ["@build_bazel_rules_ios//rules/test_host_app:Info.plist"]

    application_kwargs["launch_storyboard"] = application_kwargs.pop("launch_storyboard", library.launch_screen_storyboard_name)
    application_kwargs["families"] = application_kwargs.pop("families", ["iphone", "ipad"])

    rules_apple_ios_application(
        name = name,
        deps = library.deps,
        infoplists = infoplists,
        **application_kwargs
    )
