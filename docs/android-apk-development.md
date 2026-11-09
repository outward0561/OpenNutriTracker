# Android APK development workflows

This fork has two independent debug APK workflows. Neither workflow creates a
pull request or pushes changes to the original repository.

| Branch | Workflow | App label | Android application ID | Artifact |
| --- | --- | --- | --- | --- |
| `personal-dev` | Personal Android APK | OpenNutriTracker Personal | `com.opennutritracker.ont.opennutritracker.personal` | `OpenNutriTracker-Personal` |
| `feature/*` | Feature PR-Test Android APK | OpenNutriTracker PR Test | `com.opennutritracker.ont.opennutritracker.prtest` | `OpenNutriTracker-PR-Test` |

Both workflows can also be started manually from **Actions** with **Run
workflow**. They read the Flutter version from `.fvmrc`, generate localization
and Dart sources, then build a debug APK. Flutter package and Gradle caches are
used. The APKs are debug-signed and do not use production signing secrets.
Their distinct application IDs allow both to be installed alongside the
production app and alongside each other.

## Branch layout

The fork's `main` is synchronized to upstream `main` and contains the fork's
APK workflow configuration. Create personal experiments from `main` once, then
keep using the persistent `personal-dev` branch for unfinished work. Create
each upstream feature branch from the current fork `main`, which tracks the
current upstream `main` plus the fork-only workflow setup. Never create a
feature branch from `personal-dev`.

```sh
git remote add upstream https://github.com/simonoppowa/OpenNutriTracker.git
git fetch origin
git fetch upstream
git switch main
git pull --ff-only origin main
git merge upstream/main
git push origin main
git switch -c feature/my-change main
git push --set-upstream origin feature/my-change
```

The `personal-dev` branch is already created from `main`. Check it out once,
then keep pushing new experiments to the same branch:

```sh
git fetch origin
git switch --track origin/personal-dev
```

The feature workflow only builds branches named `feature/*`; the personal
workflow only builds `personal-dev`. Pushes to other branches do not start
these APK workflows. You can manually run the corresponding workflow against a
selected branch from the GitHub Actions page.

## Download an APK

1. Open the fork on GitHub and select **Actions**.
2. Open **Personal Android APK** or **Feature PR-Test Android APK**.
3. Select the completed run for the branch you built.
4. In the run summary, select **OpenNutriTracker-Personal** or
   **OpenNutriTracker-PR-Test** under **Artifacts**. GitHub downloads a ZIP;
   extract it to get the APK.

Artifacts are retained for 14 days. The APK filenames are
`app-personal-debug.apk` and `app-prtest-debug.apk`, respectively.
