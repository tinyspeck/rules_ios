"""
This provides a resource bundle implementation that builds the resource bundle
only once for iOS

NOTE: This rule only exists because of this issue
https://github.com/bazelbuild/rules_apple/issues/319
if this is ever fixed in bazel it should be removed
"""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@build_bazel_rules_apple//apple/internal:partials.bzl", "partials")  # buildifier: disable=bzl-visibility
load("@build_bazel_rules_apple//apple/internal:rule_factory.bzl", "rule_factory")  # buildifier: disable=bzl-visibility
load("@build_bazel_rules_apple//apple/internal:platform_support.bzl", "platform_support")  # buildifier: disable=bzl-visibility
load("@build_bazel_rules_apple//apple:providers.bzl", "AppleResourceBundleInfo", "AppleResourceInfo", "AppleSupportToolchainInfo")

def _precompiled_apple_resource_bundle_impl(ctx):
    bundle_name = ctx.attr.bundle_name or ctx.label.name

    # The label of this fake_ctx is used as the swift module associated with storyboards, nibs, xibs
    # and CoreData models.
    # * For storyboards, nibs and xibs: https://github.com/bazelbuild/rules_apple/blob/master/apple/internal/partials/support/resources_support.bzl#L446
    # * For CoreData models: https://github.com/bazelbuild/rules_apple/blob/master/apple/internal/partials/support/resources_support.bzl#L57
    #
    # Such swift module is required in the following cases:
    # 1- When the storyboard, nib or xib contains the value <customModuleProvider="target">.
    # 2- When the CoreData model sets "Current Product Module" for its Module property.
    # If none of above scenarios, the swift module is not important and could be any arbitrary string.
    # For the full context see https://github.com/bazel-ios/rules_ios/issues/113
    #
    # Usage:
    # The most common scenario happens when the bundle name is the same as the corresponding swift module.
    # If that is not the case, it is possible to customize the swift module by explicitly
    # passing a swift_module attr
    fake_rule_label = Label("//fake_package:" + (ctx.attr.swift_module or bundle_name))

    apple_toolchain_info = ctx.attr._toolchain[AppleSupportToolchainInfo]
    platform_prerequisites = platform_support.platform_prerequisites(
        apple_fragment = ctx.fragments.apple,
        config_vars = ctx.var,
        device_families = ["iphone"],
        disabled_features = ctx.disabled_features,
        explicit_minimum_os = None,
        features = ctx.features,
        objc_fragment = None,
        platform_type_string = str(ctx.fragments.apple.single_arch_platform.platform_type),
        uses_swift = False,
        xcode_path_wrapper = ctx.executable._xcode_path_wrapper,
        xcode_version_config = ctx.attr._xcode_config[apple_common.XcodeVersionConfig],
    )

    rule_descriptor = struct(
        additional_infoplist_values = None,
        binary_infoplist = True,
        bundle_extension = ".bundle",
        bundle_package_type = None,
        product_type = "com.apple.product-type.bundle",  # apple_product_type.bundle
        requires_pkginfo = False,
    )

    partial_output = partial.call(partials.resources_partial(
        actions = ctx.actions,
        apple_toolchain_info = apple_toolchain_info,
        bundle_extension = rule_descriptor.bundle_extension,
        bundle_id = ctx.attr.bundle_id or "com.cocoapods." + bundle_name,
        bundle_name = bundle_name,
        executable_name = None,
        environment_plist = ctx.file._environment_plist,
        launch_storyboard = None,
        platform_prerequisites = platform_prerequisites,
        plist_attrs = ["infoplist"],
        rule_attrs = ctx.attr,
        rule_descriptor = rule_descriptor,
        rule_label = fake_rule_label,
        top_level_attrs = ["resources"],
    ))

    # This is a list of files to pass to bundletool using its format, this has
    # a struct with a src and dest mapping that bundle tool uses to copy files
    # https://github.com/bazelbuild/rules_apple/blob/d29df97b9652e0442ebf21f1bc0e04921b584f76/tools/bundletool/bundletool_experimental.py#L29-L35
    control_files = []
    input_files = []
    output_files = []
    output_bundle_dir = ctx.actions.declare_directory(ctx.label.name + ".bundle")

    # `target_location` is a special identifier that tells you in a generic way
    # where the resource should end up. This corresponds to:
    # https://github.com/bazelbuild/rules_apple/blob/d29df97b9652e0442ebf21f1bc0e04921b584f76/apple/internal/processor.bzl#L107-L119
    # in this use case both "resource" and "content" correspond to the root
    # directory of the final Foo.bundle/
    #
    # `parent` is the directory the resource should be nested in
    # (under `target_location`) for example Base.lproj would be the parent for
    # a Localizable.strings file. If there is no `parent`, put it in the root
    #
    # `sources` is a depset of files or directories that we need to copy into
    # the bundle. If it's a directory this likely means the compiler could
    # output any number of files (like ibtool from a storyboard) and all the
    # contents should be copied to the bundle (this is handled by bundletool)
    for target_location, parent, sources in partial_output.bundle_files:
        parent_output_directory = parent or ""
        if target_location != "resource" and target_location != "content":
            # For iOS resources these are the only ones we've hit, if we need
            # to add more in the future we should be sure to double check where
            # the need to end up
            fail("Got unexpected target location '{}' for '{}'"
                .format(target_location, sources.to_list()))

        input_files.extend(sources.to_list())
        for source in sources.to_list():
            target_path = parent_output_directory

            if not source.is_directory:
                target_path = paths.join(target_path, source.basename)
            output_files.append(target_path)

            control_files.append(struct(src = source.path, dest = target_path))

    # Create a file for bundletool to know what files to copy
    # https://github.com/bazelbuild/rules_apple/blob/d29df97b9652e0442ebf21f1bc0e04921b584f76/tools/bundletool/bundletool_experimental.py#L29-L46
    bundletool_instructions = struct(
        bundle_merge_files = control_files,
        bundle_merge_zips = [],
        output = output_bundle_dir.path,
        code_signing_commands = "",
        post_processor = "",
    )

    bundletool_instructions_file = ctx.actions.declare_file(
        paths.join(
            "{}-intermediates".format(ctx.label.name),
            "bundletool_actions.json",
        ),
    )

    ctx.actions.write(
        output = bundletool_instructions_file,
        content = json.encode(bundletool_instructions),
    )

    resolved_bundletool = apple_toolchain_info.resolved_bundletool_experimental
    ctx.actions.run(
        executable = resolved_bundletool.executable,
        mnemonic = "BundleResources",
        progress_message = "Bundling " + ctx.label.name,
        inputs = depset(
            input_files + [bundletool_instructions_file],
            transitive = [resolved_bundletool.inputs],
        ),
        input_manifests = resolved_bundletool.input_manifests,
        outputs = [output_bundle_dir],
        arguments = [bundletool_instructions_file.path],
    )

    return [
        AppleResourceInfo(
            unowned_resources = depset(),
            owners = depset([(output_bundle_dir.short_path, ctx.label)]),
            # This is a list of the resources to propagate without changing further
            # In this case the tuple parameters are:
            # 1. The final directory the resources should end up in, ex Foo.bundle
            #    would result in Bar.app/Foo.bundle
            # 2. The Swift module associated with the resources, this isn't
            #    required for us since we don't use customModuleProvider in IB
            # 3. The resources to propagate, in our case this is just the final
            #    Foo.bundle directory that contains our real resources
            unprocessed = [
                (output_bundle_dir.basename, None, depset([output_bundle_dir])),
            ],
        ),
        AppleResourceBundleInfo(),
        apple_common.new_objc_provider(),
    ]

precompiled_apple_resource_bundle = rule(
    implementation = _precompiled_apple_resource_bundle_impl,
    fragments = ["apple"],
    attrs = dict(
        rule_factory.common_tool_attributes,
        bundle_name = attr.string(
            mandatory = False,
            doc = "The name of the resource bundle. Defaults to the target name.",
        ),
        bundle_id = attr.string(
            mandatory = False,
            doc = "The bundle identifier of the resource bundle.",
        ),
        swift_module = attr.string(
            mandatory = False,
            doc = "The swift module to use when compiling storyboards, nibs and xibs that contain a customModuleProvider",
        ),
        infoplist = attr.label(
            allow_files = [".plist"],
        ),
        resources = attr.label_list(
            allow_empty = False,
            allow_files = True,
        ),
        _environment_plist = attr.label(
            allow_single_file = True,
            default = "@build_bazel_rules_apple//apple/internal:environment_plist_ios",
        ),
    ),
)
