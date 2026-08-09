"""
Patches the Android Gradle files (generated fresh by `flutter create` in CI)
to add the Firebase google-services plugin.

Modern `flutter create` generates Kotlin DSL Gradle files
(android/build.gradle.kts and android/app/build.gradle.kts), not the older
Groovy .gradle files. This script targets the Kotlin DSL format to match.
"""
import os
import re
import sys

build_gradle_path = 'android/build.gradle.kts'
app_build_gradle_path = 'android/app/build.gradle.kts'

# This MUST exactly match the package name registered in your Firebase
# project's google-services.json, or the build will fail with
# "No matching client found for package name ...".
TARGET_PACKAGE = 'com.radt9098.geoattend'

if not os.path.exists(build_gradle_path):
    print(f"ERROR: {build_gradle_path} not found. "
          f"'flutter create --platforms android .' may have failed, "
          f"or Flutter's project template has changed format again.")
    sys.exit(1)

if not os.path.exists(app_build_gradle_path):
    print(f"ERROR: {app_build_gradle_path} not found.")
    sys.exit(1)

# --- Patch android/build.gradle.kts (project-level) ---
with open(build_gradle_path, 'r') as f:
    build_gradle = f.read()

if 'com.google.gms:google-services' not in build_gradle:
    if 'buildscript {' in build_gradle and 'dependencies {' in build_gradle:
        # Insert the classpath into the existing buildscript dependencies block.
        build_gradle = build_gradle.replace(
            'dependencies {',
            'dependencies {\n        classpath("com.google.gms:google-services:4.4.2")',
            1,
        )
    else:
        # No buildscript block in the default template (plugins-DSL only) -
        # append one at the top, which Gradle still accepts.
        build_gradle = (
            'buildscript {\n'
            '    repositories {\n'
            '        google()\n'
            '        mavenCentral()\n'
            '    }\n'
            '    dependencies {\n'
            '        classpath("com.google.gms:google-services:4.4.2")\n'
            '    }\n'
            '}\n\n' + build_gradle
        )
    with open(build_gradle_path, 'w') as f:
        f.write(build_gradle)

# --- Patch android/app/build.gradle.kts (app-level) ---
with open(app_build_gradle_path, 'r') as f:
    app_build_gradle = f.read()

if 'com.google.gms.google-services' not in app_build_gradle:
    if 'plugins {' in app_build_gradle:
        app_build_gradle = app_build_gradle.replace(
            'plugins {',
            'plugins {\n    id("com.google.gms.google-services")',
            1,
        )
    else:
        print("ERROR: No 'plugins {' block found in app/build.gradle.kts "
              "- cannot safely patch. Aborting.")
        sys.exit(1)

# --- Fix the package name: Flutter defaults to com.example.<name>, but it
# must exactly match what's registered in google-services.json ---
app_build_gradle, ns_count = re.subn(
    r'namespace\s*=\s*"[^"]+"',
    f'namespace = "{TARGET_PACKAGE}"',
    app_build_gradle,
)
app_build_gradle, id_count = re.subn(
    r'applicationId\s*=\s*"[^"]+"',
    f'applicationId = "{TARGET_PACKAGE}"',
    app_build_gradle,
)
if ns_count == 0 or id_count == 0:
    print(f"WARNING: Could not find namespace/applicationId lines to patch "
          f"(found namespace: {ns_count}, applicationId: {id_count}). "
          f"The build may fail with a package name mismatch.")
else:
    print(f"Patched package name to {TARGET_PACKAGE}.")

with open(app_build_gradle_path, 'w') as f:
    f.write(app_build_gradle)

# --- Move MainActivity.kt to match the new package's folder structure ---
default_kotlin_dir = 'android/app/src/main/kotlin/com/example/geoattend'
target_kotlin_dir = 'android/app/src/main/kotlin/' + TARGET_PACKAGE.replace('.', '/')
main_activity_src = os.path.join(default_kotlin_dir, 'MainActivity.kt')

if os.path.exists(main_activity_src):
    os.makedirs(target_kotlin_dir, exist_ok=True)
    with open(main_activity_src, 'r') as f:
        content = f.read()
    content = content.replace('package com.example.geoattend',
                               f'package {TARGET_PACKAGE}')
    with open(os.path.join(target_kotlin_dir, 'MainActivity.kt'), 'w') as f:
        f.write(content)
    if os.path.abspath(target_kotlin_dir) != os.path.abspath(default_kotlin_dir):
        os.remove(main_activity_src)
    print(f"Moved MainActivity.kt to {target_kotlin_dir}.")
else:
    print(f"WARNING: {main_activity_src} not found - skipping "
          f"MainActivity relocation. If the package name changed from a "
          f"different default, this may need manual adjustment.")

print("Successfully patched Android Gradle (Kotlin DSL) files for Firebase.")
