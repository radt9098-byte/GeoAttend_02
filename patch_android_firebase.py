"""
Patches the Android Gradle files (generated fresh by `flutter create` in CI)
to add the Firebase google-services plugin.

Modern `flutter create` generates Kotlin DSL Gradle files
(android/build.gradle.kts and android/app/build.gradle.kts), not the older
Groovy .gradle files. This script targets the Kotlin DSL format to match.
"""
import os
import sys

build_gradle_path = 'android/build.gradle.kts'
app_build_gradle_path = 'android/app/build.gradle.kts'

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
    with open(app_build_gradle_path, 'w') as f:
        f.write(app_build_gradle)

print("Successfully patched Android Gradle (Kotlin DSL) files for Firebase.")
