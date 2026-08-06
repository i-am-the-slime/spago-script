module Script.Command.Grammars where

import Prim (Symbol)
import Script.Command.Grammar
  ( AddOption
  , AddPositional
  , AddSubcommand
  , CharValue
  , Command
  , IntValue
  , Many
  , Name
  , NoNames
  , NoOperand
  , NoOptions
  , NoPositionals
  , NumberValue
  , NoSubcommands
  , Once
  , One
  , Optional
  , Options
  , Repeatable
  , RequiredOperand
  , TextValue
  , Some
  )

-- Small constructors keep each command below a declarative list. Option names
-- are complete tokens; there is deliberately no character-level flag grammar.
type N1 (name :: Symbol) = Name name NoNames
type N2 (short :: Symbol) (long :: Symbol) = Name short (Name long NoNames)
type N3 (first :: Symbol) (second :: Symbol) (third :: Symbol) =
  Name first (Name second (Name third NoNames))

type Flag1 (name :: Symbol) (rest :: Options) =
  AddOption (N1 name) NoOperand Once rest
type Flag2 (short :: Symbol) (long :: Symbol) (rest :: Options) =
  AddOption (N2 short long) NoOperand Once rest
type Flag3 (first :: Symbol) (second :: Symbol) (third :: Symbol) (rest :: Options) =
  AddOption (N3 first second third) NoOperand Once rest
type Text1 (name :: Symbol) (rest :: Options) =
  AddOption (N1 name) (RequiredOperand TextValue) Once rest
type Text2 (short :: Symbol) (long :: Symbol) (rest :: Options) =
  AddOption (N2 short long) (RequiredOperand TextValue) Once rest
type TextMany1 (name :: Symbol) (rest :: Options) =
  AddOption (N1 name) (RequiredOperand TextValue) Repeatable rest
type TextMany2 (short :: Symbol) (long :: Symbol) (rest :: Options) =
  AddOption (N2 short long) (RequiredOperand TextValue) Repeatable rest
type Int1 (name :: Symbol) (rest :: Options) =
  AddOption (N1 name) (RequiredOperand IntValue) Once rest
type Int2 (short :: Symbol) (long :: Symbol) (rest :: Options) =
  AddOption (N2 short long) (RequiredOperand IntValue) Once rest
type Number2 (short :: Symbol) (long :: Symbol) (rest :: Options) =
  AddOption (N2 short long) (RequiredOperand NumberValue) Once rest
type Char1 (name :: Symbol) (rest :: Options) =
  AddOption (N1 name) (RequiredOperand CharValue) Once rest
type Char2 (short :: Symbol) (long :: Symbol) (rest :: Options) =
  AddOption (N2 short long) (RequiredOperand CharValue) Once rest

type FileOne = AddPositional "FILE" TextValue One NoPositionals
type FilesMany = AddPositional "FILE" TextValue Many NoPositionals
type FilesSome = AddPositional "FILE" TextValue Some NoPositionals

-- Portable BSD/GNU intersection for filesystem and text utilities.
type CatOptions =
  Flag1 "-b"
    (Flag1 "-e"
      (Flag1 "-n"
        (Flag1 "-s"
          (Flag1 "-t"
            (Flag1 "-u" (Flag1 "-v" NoOptions))))))
type CatGrammarDefinition = Command "cat" CatOptions FilesSome NoSubcommands

type RmOptions =
  Flag1 "-d"
    (Flag1 "-f"
      (Flag1 "-i"
        (Flag1 "-R"
          (Flag1 "-r" (Flag1 "-v" NoOptions)))))
type RmGrammarDefinition = Command "rm" RmOptions FilesSome NoSubcommands

type MkdirOptions = Flag1 "-p" (Flag1 "-v" (Text1 "-m" NoOptions))
type MkdirGrammarDefinition = Command "mkdir" MkdirOptions (AddPositional "DIRECTORY" TextValue Some NoPositionals) NoSubcommands

type LsOptions =
  Flag1 "-1"
    (Flag1 "-A"
      (Flag1 "-C"
        (Flag1 "-F"
          (Flag1 "-H"
            (Flag1 "-L"
              (Flag1 "-R"
                (Flag1 "-S"
                  (Flag1 "-a"
                    (Flag1 "-c"
                      (Flag1 "-d"
                        (Flag1 "-f"
                          (Flag1 "-h"
                            (Flag1 "-i"
                              (Flag1 "-k"
                                (Flag1 "-l"
                                  (Flag1 "-n"
                                    (Flag1 "-q"
                                      (Flag1 "-r"
                                        (Flag1 "-s"
                                          (Flag1 "-t"
                                            (Flag1 "-u" (Flag1 "-x" NoOptions))))))))))))))))))))))
type LsGrammarDefinition = Command "ls" LsOptions FilesMany NoSubcommands

type MvOptions = Flag1 "-f" (Flag1 "-i" (Flag1 "-n" (Flag1 "-v" NoOptions)))
type MvPositionals =
  AddPositional "SOURCE" TextValue Some
    (AddPositional "DEST" TextValue One NoPositionals)
type MvGrammarDefinition = Command "mv" MvOptions MvPositionals NoSubcommands

type CpOptions =
  Flag1 "-H"
    (Flag1 "-L"
      (Flag1 "-R"
        (Flag1 "-a"
          (Flag1 "-f"
            (Flag1 "-i"
              (Flag1 "-n"
                (Flag1 "-p" (Flag1 "-v" NoOptions))))))))
type CpPositionals =
  AddPositional "SOURCE" TextValue Some
    (AddPositional "DEST" TextValue One NoPositionals)
type CpGrammarDefinition = Command "cp" CpOptions CpPositionals NoSubcommands

type GrepOptions =
  Int1 "-A"
    (Int1 "-B"
      (Int1 "-C"
        (Flag1 "-E"
          (Flag1 "-F"
            (Flag1 "-H"
              (Flag1 "-I"
                (Flag1 "-L"
                  (Flag1 "-R"
                    (Flag1 "-b"
                      (Flag1 "-c"
                        (TextMany1 "-e"
                          (TextMany1 "-f"
                            (Flag1 "-h"
                              (Flag1 "-i"
                                (Flag1 "-l"
                                  (Int1 "-m"
                                    (Flag1 "-n"
                                      (Flag1 "-o"
                                        (Flag1 "-q"
                                          (Flag1 "-r"
                                            (Flag1 "-s"
                                              (Flag1 "-v"
                                                (Flag1 "-w" (Flag1 "-x" NoOptions))))))))))))))))))))))))
type GrepPositionals =
  AddPositional "PATTERN" TextValue Optional
    (AddPositional "FILE" TextValue Many NoPositionals)
type GrepGrammarDefinition = Command "grep" GrepOptions GrepPositionals NoSubcommands

type FindOptions =
  Flag1 "-H"
    (Flag1 "-L"
      (Flag1 "-P"
        (Flag1 "-depth"
          (Text1 "-group"
            (Text1 "-iname"
              (Text1 "-ipath"
                (Text1 "-links"
                  (Text1 "-name"
                    (Text1 "-newer"
                      (Flag1 "-nogroup"
                        (Flag1 "-nouser"
                          (Text1 "-path"
                            (Flag1 "-print"
                              (Flag1 "-prune"
                                (Text1 "-size"
                                  (Char1 "-type"
                                    (Text1 "-user"
                                      (Int1 "-atime"
                                        (Int1 "-ctime" (Int1 "-mtime" NoOptions))))))))))))))))))))
type FindGrammarDefinition = Command "find" FindOptions (AddPositional "PATH" TextValue Some NoPositionals) NoSubcommands

type SortOptions =
  Flag1 "-M"
    (Flag1 "-b"
      (Flag1 "-d"
        (Flag1 "-f"
          (Flag1 "-g"
            (Flag1 "-i"
              (TextMany1 "-k"
                (Flag1 "-n"
                  (Text1 "-o"
                    (Flag1 "-r"
                      (Flag1 "-s"
                        (Char1 "-t" (Flag1 "-u" NoOptions))))))))))))
type SortGrammarDefinition = Command "sort" SortOptions FilesMany NoSubcommands

type UniqOptions =
  Flag1 "-c"
    (Flag1 "-d"
      (Int1 "-f"
        (Flag1 "-i"
          (Int1 "-s" (Flag1 "-u" NoOptions)))))
type UniqPositionals =
  AddPositional "INPUT" TextValue Optional
    (AddPositional "OUTPUT" TextValue Optional NoPositionals)
type UniqGrammarDefinition = Command "uniq" UniqOptions UniqPositionals NoSubcommands

type SedOptions =
  Flag1 "-E"
    (TextMany1 "-e"
      (TextMany1 "-f"
        (Text1 "-i" (Flag1 "-n" NoOptions))))
type SedPositionals =
  AddPositional "SCRIPT" TextValue Optional
    (AddPositional "FILE" TextValue Many NoPositionals)
type SedGrammarDefinition = Command "sed" SedOptions SedPositionals NoSubcommands

type HeadOptions = Int1 "-c" (Int1 "-n" NoOptions)
type HeadGrammarDefinition = Command "head" HeadOptions FilesMany NoSubcommands

type TailOptions = Flag1 "-F" (Flag1 "-f" (Int1 "-c" (Int1 "-n" NoOptions)))
type TailGrammarDefinition = Command "tail" TailOptions FilesMany NoSubcommands

type WcOptions = Flag1 "-c" (Flag1 "-l" (Flag1 "-m" (Flag1 "-w" NoOptions)))
type WcGrammarDefinition = Command "wc" WcOptions FilesMany NoSubcommands

type TeeOptions = Flag1 "-a" (Flag1 "-i" NoOptions)
type TeeGrammarDefinition = Command "tee" TeeOptions FilesMany NoSubcommands

type TouchOptions =
  Flag1 "-a"
    (Flag1 "-c"
      (Flag1 "-m"
        (Text1 "-r" (Text1 "-t" NoOptions))))
type TouchGrammarDefinition = Command "touch" TouchOptions FilesSome NoSubcommands

type WhichOptions = Flag1 "-a" NoOptions
type WhichGrammarDefinition = Command "which" WhichOptions (AddPositional "COMMAND" TextValue Some NoPositionals) NoSubcommands

-- git 2.x stable porcelain. Subcommand grammars intentionally live beside the
-- root declaration so extending one command does not alter generic validation.
type GitRootOptions =
  Text1 "-C"
    (Text2 "-c" "--config-env"
      (Flag1 "--bare"
        (Flag1 "--no-pager"
          (Flag1 "--paginate"
            (Text1 "--exec-path"
              (Text1 "--git-dir"
                (Text1 "--namespace"
                  (Text1 "--work-tree" NoOptions))))))))
type GitCloneOptions =
  Text2 "-b" "--branch"
    (Int1 "--depth"
      (Flag1 "--mirror"
        (Text2 "-o" "--origin"
          (Flag1 "--recurse-submodules"
            (Flag1 "--single-branch" (Flag1 "--bare" NoOptions))))))
type GitClone = Command "clone" GitCloneOptions
  (AddPositional "REPOSITORY" TextValue One (AddPositional "DIRECTORY" TextValue Optional NoPositionals)) NoSubcommands
type GitInitOptions = Flag1 "--bare" (Text2 "-b" "--initial-branch" (Text1 "--template" NoOptions))
type GitInit = Command "init" GitInitOptions (AddPositional "DIRECTORY" TextValue Optional NoPositionals) NoSubcommands
type GitAddOptions = Flag2 "-A" "--all" (Flag2 "-f" "--force" (Flag2 "-n" "--dry-run" (Flag2 "-p" "--patch" (Flag2 "-u" "--update" NoOptions))))
type GitAdd = Command "add" GitAddOptions (AddPositional "PATHSPEC" TextValue Some NoPositionals) NoSubcommands
type GitCommitOptions =
  Flag2 "-a" "--all"
    (Flag1 "--amend"
      (Text2 "-C" "--reuse-message"
        (Flag1 "--no-edit"
          (Flag2 "-n" "--no-verify"
            (TextMany2 "-m" "--message" NoOptions)))))
type GitCommit = Command "commit" GitCommitOptions (AddPositional "PATHSPEC" TextValue Many NoPositionals) NoSubcommands
type GitStatusOptions = Flag2 "-b" "--branch" (Flag2 "-s" "--short" (Flag1 "--porcelain" (Flag1 "--show-stash" NoOptions)))
type GitStatus = Command "status" GitStatusOptions (AddPositional "PATHSPEC" TextValue Many NoPositionals) NoSubcommands
type GitDiffOptions =
  Flag1 "--cached"
    (Flag1 "--check"
      (Flag1 "--name-only"
        (Flag1 "--name-status"
          (Flag1 "--staged"
            (Flag1 "--stat" (Int2 "-U" "--unified" (Flag2 "-w" "--ignore-all-space" NoOptions)))))))
type GitDiff = Command "diff" GitDiffOptions (AddPositional "COMMIT_OR_PATH" TextValue Many NoPositionals) NoSubcommands
type GitLogOptions =
  Flag1 "--all"
    (TextMany1 "--author"
      (Flag1 "--graph"
        (TextMany1 "--grep"
          (Int2 "-n" "--max-count"
            (Flag1 "--oneline"
              (Text1 "--since" (Text1 "--until" NoOptions)))))))
type GitLog = Command "log" GitLogOptions (AddPositional "REVISION_OR_PATH" TextValue Many NoPositionals) NoSubcommands
type GitShowOptions = Flag1 "--name-only" (Flag1 "--name-status" (Flag1 "--stat" (Flag1 "--oneline" NoOptions)))
type GitShow = Command "show" GitShowOptions (AddPositional "OBJECT" TextValue Many NoPositionals) NoSubcommands
type GitBranchOptions =
  Flag2 "-a" "--all"
    (Flag2 "-d" "--delete"
      (Flag1 "-D"
        (Flag2 "-m" "--move"
          (Flag1 "-M"
            (Flag2 "-r" "--remotes"
              (Flag1 "--show-current" (Flag2 "-v" "--verbose" NoOptions)))))))
type GitBranch = Command "branch" GitBranchOptions (AddPositional "BRANCH_OR_COMMIT" TextValue Many NoPositionals) NoSubcommands
type GitCheckoutOptions = Text1 "-B" (Text2 "-b" "--branch" (Flag2 "-f" "--force" (Flag1 "--detach" (Flag1 "--ours" (Flag1 "--theirs" NoOptions)))))
type GitCheckout = Command "checkout" GitCheckoutOptions (AddPositional "BRANCH_OR_PATH" TextValue Some NoPositionals) NoSubcommands
type GitSwitchOptions = Text1 "-C" (Text2 "-c" "--create" (Flag2 "-d" "--detach" (Flag2 "-f" "--force" (Flag1 "--discard-changes" NoOptions))))
type GitSwitch = Command "switch" GitSwitchOptions (AddPositional "BRANCH" TextValue Optional NoPositionals) NoSubcommands
type GitRestoreOptions = Text2 "-s" "--source" (Flag1 "--staged" (Flag1 "--worktree" (Flag1 "--ours" (Flag1 "--theirs" NoOptions))))
type GitRestore = Command "restore" GitRestoreOptions (AddPositional "PATHSPEC" TextValue Some NoPositionals) NoSubcommands
type GitMergeOptions =
  Flag1 "--abort"
    (Flag1 "--continue"
      (Flag1 "--ff-only"
        (Text2 "-m" "--message"
          (Flag1 "--no-commit" (Flag1 "--quit" (Flag1 "--squash" NoOptions))))))
type GitMerge = Command "merge" GitMergeOptions (AddPositional "COMMIT" TextValue Some NoPositionals) NoSubcommands
type GitRebaseOptions = Flag1 "--abort" (Flag1 "--continue" (Flag1 "--skip" (Flag2 "-i" "--interactive" (Flag1 "--autosquash" (Text1 "--onto" NoOptions)))))
type GitRebase = Command "rebase" GitRebaseOptions (AddPositional "UPSTREAM_OR_BRANCH" TextValue Many NoPositionals) NoSubcommands
type GitResetOptions = Flag1 "--hard" (Flag1 "--keep" (Flag1 "--merge" (Flag1 "--mixed" (Flag1 "--soft" NoOptions))))
type GitReset = Command "reset" GitResetOptions (AddPositional "COMMIT_OR_PATH" TextValue Many NoPositionals) NoSubcommands
type GitFetchOptions = Flag1 "--all" (Int1 "--depth" (Flag1 "--prune" (Flag1 "--tags" (Flag2 "-v" "--verbose" NoOptions))))
type GitFetch = Command "fetch" GitFetchOptions (AddPositional "REPOSITORY_OR_REFSPEC" TextValue Many NoPositionals) NoSubcommands
type GitPullOptions = Flag1 "--ff-only" (Flag1 "--no-rebase" (Flag1 "--rebase" (Flag1 "--tags" NoOptions)))
type GitPull = Command "pull" GitPullOptions (AddPositional "REPOSITORY_OR_REFSPEC" TextValue Many NoPositionals) NoSubcommands
type GitPushOptions =
  Flag1 "--delete"
    (Flag2 "-f" "--force"
      (Flag1 "--force-with-lease"
        (Flag2 "-n" "--dry-run"
          (Flag1 "--tags" (Flag2 "-u" "--set-upstream" NoOptions)))))
type GitPush = Command "push" GitPushOptions (AddPositional "REPOSITORY_OR_REFSPEC" TextValue Many NoPositionals) NoSubcommands
type GitTagOptions = Flag2 "-a" "--annotate" (Flag2 "-d" "--delete" (Flag2 "-f" "--force" (Flag2 "-l" "--list" (Text2 "-m" "--message" NoOptions))))
type GitTag = Command "tag" GitTagOptions (AddPositional "TAG_OR_OBJECT" TextValue Many NoPositionals) NoSubcommands
type GitConfigOptions = Flag1 "--global" (Flag1 "--local" (Flag1 "--system" (Flag1 "--get" (Flag1 "--get-all" (Flag1 "--unset" (Flag1 "--unset-all" NoOptions))))))
type GitConfig = Command "config" GitConfigOptions (AddPositional "NAME_OR_VALUE" TextValue Many NoPositionals) NoSubcommands
type GitCherryPickOptions = Flag1 "--abort" (Flag1 "--continue" (Flag1 "--no-commit" (Flag1 "--quit" NoOptions)))
type GitCherryPick = Command "cherry-pick" GitCherryPickOptions (AddPositional "COMMIT" TextValue Some NoPositionals) NoSubcommands
type GitRevertOptions = Flag1 "--abort" (Flag1 "--continue" (Flag1 "--no-commit" (Flag1 "--quit" NoOptions)))
type GitRevert = Command "revert" GitRevertOptions (AddPositional "COMMIT" TextValue Some NoPositionals) NoSubcommands
type GitCleanOptions = Flag2 "-d" "--dirs" (Flag2 "-f" "--force" (Flag2 "-n" "--dry-run" (Flag1 "-X" (Flag2 "-x" "--ignored" NoOptions))))
type GitClean = Command "clean" GitCleanOptions (AddPositional "PATHSPEC" TextValue Many NoPositionals) NoSubcommands
type GitSubcommands =
  AddSubcommand "add" GitAdd
    (AddSubcommand "branch" GitBranch
      (AddSubcommand "checkout" GitCheckout
        (AddSubcommand "cherry-pick" GitCherryPick
          (AddSubcommand "clean" GitClean
            (AddSubcommand "clone" GitClone
              (AddSubcommand "commit" GitCommit
                (AddSubcommand "config" GitConfig
                  (AddSubcommand "diff" GitDiff
                    (AddSubcommand "fetch" GitFetch
                      (AddSubcommand "init" GitInit
                        (AddSubcommand "log" GitLog
                          (AddSubcommand "merge" GitMerge
                            (AddSubcommand "pull" GitPull
                              (AddSubcommand "push" GitPush
                                (AddSubcommand "rebase" GitRebase
                                  (AddSubcommand "reset" GitReset
                                    (AddSubcommand "restore" GitRestore
                                      (AddSubcommand "revert" GitRevert
                                        (AddSubcommand "show" GitShow
                                          (AddSubcommand "status" GitStatus
                                            (AddSubcommand "switch" GitSwitch
                                              (AddSubcommand "tag" GitTag NoSubcommands))))))))))))))))))))))
type GitGrammarDefinition = Command "git" GitRootOptions NoPositionals GitSubcommands

-- Spago 1.0.4. Common options are repeated in command declarations because
-- they occur after the subcommand in Spago's argv grammar.
type SpagoCommonOptions =
  Flag1 "--migrate"
    (Flag3 "--monochrome" "--no-color" "--no-colour"
      (Flag1 "--offline"
        (Flag1 "--refresh"
          (Flag2 "-q" "--quiet" (Flag2 "-v" "--verbose" NoOptions)))))
type SpagoBuildOptions =
  Text1 "--backend-args"
    (Flag1 "--ensure-ranges"
      (Flag1 "--json-errors"
        (Text1 "--output"
          (Text2 "-p" "--package"
            (Flag1 "--pedantic-packages"
              (Flag1 "--pure"
                (Text1 "--purs-args"
                  (Flag1 "--strict"
                    (Flag1 "--verbose-stats"
                      (Flag1 "--censor-stats" SpagoCommonOptions))))))))))
type SpagoBuild = Command "build" SpagoBuildOptions NoPositionals NoSubcommands
type SpagoBundleOptions =
  Text1 "--bundler-args"
    (Flag1 "--force"
      (Text2 "-m" "--module"
        (Flag1 "--minify"
          (Text1 "--outfile"
            (Text1 "--platform"
              (Flag1 "--source-maps" (Text1 "--bundle-type" SpagoBuildOptions)))))))
type SpagoBundle = Command "bundle" SpagoBundleOptions NoPositionals NoSubcommands
type SpagoDocsOptions = Flag1 "--deps-only" (Text2 "-f" "--format" (Flag2 "-o" "--open" SpagoCommonOptions))
type SpagoDocs = Command "docs" SpagoDocsOptions NoPositionals NoSubcommands
type SpagoFetchOptions = Flag1 "--ensure-ranges" (Flag1 "--pure" (Text2 "-p" "--package" (Flag1 "--test-deps" SpagoCommonOptions)))
type SpagoFetch = Command "fetch" SpagoFetchOptions (AddPositional "PACKAGE" TextValue Optional NoPositionals) NoSubcommands
type SpagoInitOptions = Text1 "--name" (Text1 "--package-set" (Text1 "--subpackage" (Flag1 "--use-solver" SpagoCommonOptions)))
type SpagoInit = Command "init" SpagoInitOptions NoPositionals NoSubcommands
type SpagoInstallOptions = Flag1 "--test-deps" SpagoBuildOptions
type SpagoInstall = Command "install" SpagoInstallOptions (AddPositional "PACKAGE" TextValue Optional NoPositionals) NoSubcommands
type SpagoRunOptions = Text2 "-m" "--main" SpagoBuildOptions
type SpagoRun = Command "run" SpagoRunOptions (AddPositional "ARGS" TextValue Optional NoPositionals) NoSubcommands
type SpagoTest = Command "test" SpagoRunOptions (AddPositional "ARGS" TextValue Optional NoPositionals) NoSubcommands
type SpagoRepl = Command "repl" (Text1 "--backend-args" (Text1 "--purs-args" (Text2 "-p" "--package" SpagoCommonOptions))) NoPositionals NoSubcommands
type SpagoSources = Command "sources" (Flag1 "--json" (Text2 "-p" "--package" SpagoCommonOptions)) NoPositionals NoSubcommands
type SpagoPublish = Command "publish" (Text2 "-p" "--package" SpagoCommonOptions) NoPositionals NoSubcommands
type SpagoUninstall = Command "uninstall" (Text2 "-p" "--package" (Flag1 "--test-deps" SpagoCommonOptions)) (AddPositional "PACKAGE" TextValue Optional NoPositionals) NoSubcommands
type SpagoUpgrade = Command "upgrade" (Text1 "--package-set" (Text2 "-p" "--package" SpagoCommonOptions)) NoPositionals NoSubcommands
type SpagoAuth = Command "auth" (Text1 "-i" SpagoCommonOptions) NoPositionals NoSubcommands
type SpagoGraphSubcommands =
  AddSubcommand "modules" (Command "modules" NoOptions NoPositionals NoSubcommands)
    (AddSubcommand "packages" (Command "packages" NoOptions NoPositionals NoSubcommands) NoSubcommands)
type SpagoGraph = Command "graph" NoOptions NoPositionals SpagoGraphSubcommands
type SpagoLsSubcommands =
  AddSubcommand "deps" (Command "deps" NoOptions NoPositionals NoSubcommands)
    (AddSubcommand "packages" (Command "packages" NoOptions NoPositionals NoSubcommands)
      (AddSubcommand "paths" (Command "paths" NoOptions NoPositionals NoSubcommands) NoSubcommands))
type SpagoLs = Command "ls" NoOptions NoPositionals SpagoLsSubcommands
type Spago104Subcommands =
  AddSubcommand "auth" SpagoAuth
    (AddSubcommand "build" SpagoBuild
      (AddSubcommand "bundle" SpagoBundle
        (AddSubcommand "docs" SpagoDocs
          (AddSubcommand "fetch" SpagoFetch
            (AddSubcommand "graph" SpagoGraph
              (AddSubcommand "init" SpagoInit
                (AddSubcommand "install" SpagoInstall
                  (AddSubcommand "ls" SpagoLs
                    (AddSubcommand "publish" SpagoPublish
                      (AddSubcommand "repl" SpagoRepl
                        (AddSubcommand "run" SpagoRun
                          (AddSubcommand "sources" SpagoSources
                            (AddSubcommand "test" SpagoTest
                              (AddSubcommand "uninstall" SpagoUninstall
                                (AddSubcommand "upgrade" SpagoUpgrade NoSubcommands)))))))))))))))
type SpagoGrammarDefinition = Command "spago" (Flag2 "-v" "--version" NoOptions) NoPositionals Spago104Subcommands

-- ripgrep 15 stable search interface.
type RgOptions =
  Flag2 "-F" "--fixed-strings"
    (Flag2 "-H" "--with-filename"
      (Flag2 "-I" "--no-filename"
        (Flag2 "-L" "--follow"
          (Flag2 "-N" "--no-line-number"
            (Flag2 "-P" "--pcre2"
              (Flag2 "-S" "--smart-case"
                (Flag2 "-U" "--multiline"
                  (Int2 "-A" "--after-context"
                    (Int2 "-B" "--before-context"
                      (Int2 "-C" "--context"
                        (Flag2 "-a" "--text"
                          (Flag2 "-c" "--count"
                            (TextMany2 "-e" "--regexp"
                              (TextMany2 "-f" "--file"
                                (TextMany2 "-g" "--glob"
                                  (Flag2 "-i" "--ignore-case"
                                    (Int2 "-j" "--threads"
                                      (Flag2 "-l" "--files-with-matches"
                                        (Int2 "-m" "--max-count"
                                          (Flag2 "-n" "--line-number"
                                            (Flag2 "-o" "--only-matching"
                                              (Flag2 "-q" "--quiet"
                                                (TextMany2 "-t" "--type"
                                                  (Flag2 "-u" "--unrestricted"
                                                    (Flag2 "-v" "--invert-match"
                                                      (Flag2 "-w" "--word-regexp"
                                                        (Flag2 "-x" "--line-regexp"
                                                          (Flag2 "--files" "--type-list"
                                                            (Flag1 "--hidden"
                                                              (Int1 "--max-depth"
                                                                (Text1 "--pre"
                                                                  (TextMany1 "--pre-glob"
                                                                    (Flag1 "--stats" NoOptions)))))))))))))))))))))))))))))))))
type RgPositionals = AddPositional "PATTERN" TextValue Optional (AddPositional "PATH" TextValue Many NoPositionals)
type RgGrammarDefinition = Command "rg" RgOptions RgPositionals NoSubcommands

-- jj 0.38 stable top-level commands and their most common operands.
type JjRootOptions =
  Text2 "-R" "--repository"
    (Text1 "--at-operation"
      (Flag1 "--ignore-immutable"
        (Flag1 "--ignore-working-copy"
          (Flag2 "-h" "--help" (Flag2 "-V" "--version" NoOptions)))))
type JjRevOptions = TextMany2 "-r" "--revisions" NoOptions
type JjMessageOptions = Text2 "-m" "--message" NoOptions
type JjAbandon = Command "abandon" JjRevOptions NoPositionals NoSubcommands
type JjCommit = Command "commit" JjMessageOptions (AddPositional "PATH" TextValue Many NoPositionals) NoSubcommands
type JjDescribe = Command "describe" (Text2 "-m" "--message" (Text2 "-r" "--revision" NoOptions)) NoPositionals NoSubcommands
type JjDiff = Command "diff" (Text2 "-r" "--revision" (Text1 "--from" (Text1 "--to" (Flag1 "--stat" (Flag1 "--summary" NoOptions))))) (AddPositional "PATH" TextValue Many NoPositionals) NoSubcommands
type JjEdit = Command "edit" NoOptions (AddPositional "REVISION" TextValue One NoPositionals) NoSubcommands
type JjLog = Command "log" (Int2 "-n" "--limit" (Text2 "-r" "--revisions" (Text2 "-T" "--template" (Flag1 "--no-graph" NoOptions)))) (AddPositional "PATH" TextValue Many NoPositionals) NoSubcommands
type JjNew = Command "new" (Text1 "--before" (Text1 "--insert-before" (Text1 "--insert-after" JjMessageOptions))) (AddPositional "REVISION" TextValue Many NoPositionals) NoSubcommands
type JjRebase = Command "rebase" (TextMany2 "-b" "--branch" (TextMany2 "-d" "--destination" (TextMany2 "-r" "--revisions" (TextMany2 "-s" "--source" NoOptions)))) NoPositionals NoSubcommands
type JjRestore = Command "restore" (Text1 "--from" (Text1 "--to" NoOptions)) (AddPositional "PATH" TextValue Many NoPositionals) NoSubcommands
type JjShow = Command "show" (Text2 "-T" "--template" (Flag1 "--stat" NoOptions)) (AddPositional "REVISION" TextValue Optional NoPositionals) NoSubcommands
type JjSquash = Command "squash" (Text1 "--from" (Text1 "--into" JjMessageOptions)) (AddPositional "PATH" TextValue Many NoPositionals) NoSubcommands
type JjStatus = Command "status" NoOptions NoPositionals NoSubcommands
type JjGitClone = Command "clone" (Flag1 "--colocate" (Text1 "--remote" NoOptions)) (AddPositional "SOURCE" TextValue One (AddPositional "DESTINATION" TextValue Optional NoPositionals)) NoSubcommands
type JjGitFetch = Command "fetch" (TextMany2 "-b" "--branch" (TextMany1 "--remote" NoOptions)) NoPositionals NoSubcommands
type JjGitInit = Command "init" (Flag1 "--colocate" NoOptions) (AddPositional "DESTINATION" TextValue Optional NoPositionals) NoSubcommands
type JjGitPush = Command "push" (Flag1 "--all" (TextMany2 "-b" "--bookmark" (Flag1 "--deleted" NoOptions))) NoPositionals NoSubcommands
type JjGitSubcommands = AddSubcommand "clone" JjGitClone (AddSubcommand "fetch" JjGitFetch (AddSubcommand "init" JjGitInit (AddSubcommand "push" JjGitPush NoSubcommands)))
type JjGit = Command "git" NoOptions NoPositionals JjGitSubcommands
type JjBookmarkCreate = Command "create" (Text2 "-r" "--revision" NoOptions) (AddPositional "NAME" TextValue Some NoPositionals) NoSubcommands
type JjBookmarkDelete = Command "delete" NoOptions (AddPositional "NAME" TextValue Some NoPositionals) NoSubcommands
type JjBookmarkList = Command "list" (Flag2 "-a" "--all-remotes" NoOptions) (AddPositional "PATTERN" TextValue Many NoPositionals) NoSubcommands
type JjBookmarkMove = Command "move" (Text2 "-f" "--from" (Text2 "-r" "--to" NoOptions)) (AddPositional "NAME" TextValue Some NoPositionals) NoSubcommands
type JjBookmarkSubcommands = AddSubcommand "create" JjBookmarkCreate (AddSubcommand "delete" JjBookmarkDelete (AddSubcommand "list" JjBookmarkList (AddSubcommand "move" JjBookmarkMove NoSubcommands)))
type JjBookmark = Command "bookmark" NoOptions NoPositionals JjBookmarkSubcommands
type Jj038Subcommands =
  AddSubcommand "abandon" JjAbandon
    (AddSubcommand "bookmark" JjBookmark
      (AddSubcommand "commit" JjCommit
        (AddSubcommand "describe" JjDescribe
          (AddSubcommand "diff" JjDiff
            (AddSubcommand "edit" JjEdit
              (AddSubcommand "git" JjGit
                (AddSubcommand "log" JjLog
                  (AddSubcommand "new" JjNew
                    (AddSubcommand "rebase" JjRebase
                      (AddSubcommand "restore" JjRestore
                        (AddSubcommand "show" JjShow
                          (AddSubcommand "squash" JjSquash
                            (AddSubcommand "status" JjStatus NoSubcommands)))))))))))))
type JjGrammarDefinition = Command "jj" JjRootOptions NoPositionals Jj038Subcommands

-- gh 2.x core workflows.
type GhRootOptions = Flag1 "--help" (Flag1 "--version" NoOptions)
type GhRepoClone = Command "clone" (Text2 "-u" "--upstream-remote-name" NoOptions) (AddPositional "REPOSITORY" TextValue One (AddPositional "DIRECTORY" TextValue Optional NoPositionals)) NoSubcommands
type GhRepoCreate = Command "create" (Flag1 "--add-readme" (Flag1 "--clone" (Text2 "-d" "--description" (Flag1 "--public" (Flag1 "--private" (Text2 "-s" "--source" NoOptions)))))) (AddPositional "NAME" TextValue Optional NoPositionals) NoSubcommands
type GhRepoFork = Command "fork" (Flag1 "--clone" (Text1 "--remote-name" NoOptions)) (AddPositional "REPOSITORY" TextValue Optional NoPositionals) NoSubcommands
type GhRepoView = Command "view" (Flag2 "-b" "--branch" (Flag2 "-w" "--web" NoOptions)) (AddPositional "REPOSITORY" TextValue Optional NoPositionals) NoSubcommands
type GhRepoSubcommands = AddSubcommand "clone" GhRepoClone (AddSubcommand "create" GhRepoCreate (AddSubcommand "fork" GhRepoFork (AddSubcommand "view" GhRepoView NoSubcommands)))
type GhRepo = Command "repo" NoOptions NoPositionals GhRepoSubcommands
type GhPrCheckout = Command "checkout" (Flag2 "-f" "--force" (Text2 "-b" "--branch" NoOptions)) (AddPositional "NUMBER_OR_URL" TextValue One NoPositionals) NoSubcommands
type GhPrCreate = Command "create" (Text2 "-a" "--assignee" (Text2 "-B" "--base" (Text2 "-b" "--body" (Flag2 "-d" "--draft" (Text2 "-H" "--head" (TextMany2 "-l" "--label" (Text2 "-t" "--title" (Flag2 "-w" "--web" NoOptions)))))))) NoPositionals NoSubcommands
type GhPrList = Command "list" (Text2 "-a" "--assignee" (Text2 "-A" "--author" (Text2 "-B" "--base" (Flag2 "-d" "--draft" (Int2 "-L" "--limit" (Text2 "-S" "--search" (Text2 "-s" "--state" NoOptions))))))) NoPositionals NoSubcommands
type GhPrMerge = Command "merge" (Flag1 "--admin" (Flag2 "-d" "--delete-branch" (Flag2 "-m" "--merge" (Flag2 "-r" "--rebase" (Flag2 "-s" "--squash" NoOptions))))) (AddPositional "NUMBER_OR_URL" TextValue Optional NoPositionals) NoSubcommands
type GhPrView = Command "view" (Flag2 "-c" "--comments" (Flag2 "-w" "--web" NoOptions)) (AddPositional "NUMBER_OR_URL" TextValue Optional NoPositionals) NoSubcommands
type GhPrSubcommands = AddSubcommand "checkout" GhPrCheckout (AddSubcommand "create" GhPrCreate (AddSubcommand "list" GhPrList (AddSubcommand "merge" GhPrMerge (AddSubcommand "view" GhPrView NoSubcommands))))
type GhPr = Command "pr" NoOptions NoPositionals GhPrSubcommands
type GhIssueCreate = Command "create" (TextMany2 "-a" "--assignee" (Text2 "-b" "--body" (TextMany2 "-l" "--label" (Text2 "-t" "--title" (Flag2 "-w" "--web" NoOptions))))) NoPositionals NoSubcommands
type GhIssueList = Command "list" (Text2 "-a" "--assignee" (Text2 "-A" "--author" (Int2 "-L" "--limit" (Text2 "-S" "--search" (Text2 "-s" "--state" NoOptions))))) NoPositionals NoSubcommands
type GhIssueView = Command "view" (Flag2 "-c" "--comments" (Flag2 "-w" "--web" NoOptions)) (AddPositional "NUMBER_OR_URL" TextValue Optional NoPositionals) NoSubcommands
type GhIssueSubcommands = AddSubcommand "create" GhIssueCreate (AddSubcommand "list" GhIssueList (AddSubcommand "view" GhIssueView NoSubcommands))
type GhIssue = Command "issue" NoOptions NoPositionals GhIssueSubcommands
type GhWorkflowRun = Command "run" (TextMany2 "-f" "--raw-field" (TextMany1 "--field" (Text2 "-r" "--ref" NoOptions))) (AddPositional "WORKFLOW" TextValue Optional NoPositionals) NoSubcommands
type GhWorkflowView = Command "view" (Flag2 "-w" "--web" NoOptions) (AddPositional "WORKFLOW" TextValue Optional NoPositionals) NoSubcommands
type GhWorkflowSubcommands = AddSubcommand "run" GhWorkflowRun (AddSubcommand "view" GhWorkflowView NoSubcommands)
type GhWorkflow = Command "workflow" NoOptions NoPositionals GhWorkflowSubcommands
type GhApi = Command "api" (TextMany2 "-f" "--raw-field" (TextMany1 "--field" (Text2 "-H" "--header" (Text2 "-X" "--method" (Flag1 "--paginate" NoOptions))))) (AddPositional "ENDPOINT" TextValue One NoPositionals) NoSubcommands
type GhBrowse = Command "browse" (Text2 "-b" "--branch" (Flag2 "-n" "--no-browser" NoOptions)) (AddPositional "TARGET" TextValue Optional NoPositionals) NoSubcommands
type Gh292Subcommands = AddSubcommand "api" GhApi (AddSubcommand "browse" GhBrowse (AddSubcommand "issue" GhIssue (AddSubcommand "pr" GhPr (AddSubcommand "repo" GhRepo (AddSubcommand "workflow" GhWorkflow NoSubcommands)))))
type GhGrammarDefinition = Command "gh" GhRootOptions NoPositionals Gh292Subcommands

-- PureScript 0.15.16.
type PursCompileOptions =
  TextMany2 "-x" "--exclude-files"
    (Text2 "-g" "--codegen"
      (Flag2 "-c" "--comments"
        (Flag2 "-h" "--help"
          (Flag1 "--json-errors"
            (Flag2 "-p" "--no-prefix"
              (Text2 "-o" "--output"
                (Text1 "--source-globs-file"
                  (Flag2 "-v" "--verbose-errors" NoOptions))))))))
type PursCompile = Command "compile" PursCompileOptions (AddPositional "INPUT" TextValue Some NoPositionals) NoSubcommands
type PursDocsOptions =
  Text1 "--compile-output"
    (TextMany2 "-x" "--exclude-files"
      (Text1 "--format"
        (Flag2 "-h" "--help"
          (Text2 "-o" "--output"
            (Text1 "--source-globs-file" NoOptions)))))
type PursDocs = Command "docs" PursDocsOptions (AddPositional "INPUT" TextValue Some NoPositionals) NoSubcommands
type PursGraph = Command "graph" (Flag1 "--json-errors" NoOptions) (AddPositional "INPUT" TextValue Some NoPositionals) NoSubcommands
type PursHierarchy = Command "hierarchy" NoOptions (AddPositional "INPUT" TextValue Some NoPositionals) NoSubcommands
type PursIdeServerOptions =
  Text2 "-d" "--directory"
    (Flag1 "--editor-mode"
      (TextMany2 "-x" "--exclude-files"
        (Text1 "--log-level"
          (Flag1 "--no-watch"
            (Text1 "--output-directory"
              (Flag1 "--polling"
                (Int2 "-p" "--port"
                  (Text1 "--source-globs-file" NoOptions))))))))
type PursIdeServer = Command "server" PursIdeServerOptions (AddPositional "INPUT" TextValue Many NoPositionals) NoSubcommands
type PursIdeClient = Command "client" (Int2 "-p" "--port" NoOptions) NoPositionals NoSubcommands
type PursIdeSubcommands =
  AddSubcommand "client" PursIdeClient
    (AddSubcommand "server" PursIdeServer NoSubcommands)
type PursIde = Command "ide" NoOptions NoPositionals PursIdeSubcommands
type PursPublish = Command "publish" (Flag1 "--dry-run" NoOptions) (AddPositional "INPUT" TextValue Many NoPositionals) NoSubcommands
type PursRepl = Command "repl" (TextMany1 "--foreign" (TextMany1 "--import" (Flag1 "--json-errors" NoOptions))) (AddPositional "INPUT" TextValue Many NoPositionals) NoSubcommands
type Purs01516Subcommands = AddSubcommand "compile" PursCompile (AddSubcommand "docs" PursDocs (AddSubcommand "graph" PursGraph (AddSubcommand "hierarchy" PursHierarchy (AddSubcommand "ide" PursIde (AddSubcommand "publish" PursPublish (AddSubcommand "repl" PursRepl NoSubcommands))))))
type PursGrammarDefinition = Command "purs" (Flag1 "--version" NoOptions) NoPositionals Purs01516Subcommands

-- purs-tidy 0.11.1.
type PursTidyStyleOptions =
  Flag2 "--arrow-first" "-af"
    (Flag2 "--arrow-last" "-al"
      (Flag2 "--config-ignore" "-ci"
        (Flag2 "--config-prefer" "-cp"
          (Flag2 "--config-require" "-cr"
            (Flag2 "--import-sort-ide" "-isi"
              (Flag2 "--import-sort-source" "-iss"
                (Flag2 "--import-wrap-auto" "-iwa"
                  (Flag2 "--import-wrap-source" "-iws"
                    (Int2 "--indent" "-i"
                      (Text2 "--operators" "-o"
                        (Number2 "--ribbon" "-r"
                          (Int2 "--threads" "-t"
                            (Flag1 "--timing"
                              (Flag2 "--unicode-always" "-ua"
                                (Flag2 "--unicode-never" "-un"
                                  (Flag2 "--unicode-source" "-us"
                                    (Int2 "--width" "-w" NoOptions)))))))))))))))))
type PursTidyCheck = Command "check" PursTidyStyleOptions FilesSome NoSubcommands
type PursTidyFormat = Command "format" PursTidyStyleOptions NoPositionals NoSubcommands
type PursTidyFormatInPlace = Command "format-in-place" PursTidyStyleOptions FilesSome NoSubcommands
type PursTidyGenerateConfig = Command "generate-config" PursTidyStyleOptions NoPositionals NoSubcommands
type PursTidyGenerateOperators = Command "generate-operators" NoOptions FilesMany NoSubcommands
type PursTidy011Subcommands = AddSubcommand "check" PursTidyCheck (AddSubcommand "format" PursTidyFormat (AddSubcommand "format-in-place" PursTidyFormatInPlace (AddSubcommand "generate-config" PursTidyGenerateConfig (AddSubcommand "generate-operators" PursTidyGenerateOperators NoSubcommands))))
type PursTidyGrammarDefinition = Command "purs-tidy" (Flag2 "-v" "--version" NoOptions) NoPositionals PursTidy011Subcommands
