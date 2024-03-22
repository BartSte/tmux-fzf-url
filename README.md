# README

![demo](https://github.com/BartSte/tmux-fzf-url/raw/master/demo.gif)

This is a fork of [wfxr/tmux-fzf-url](https://github.com/wfxr/tmux-fzf-url) with
a set of features added to it as is explained below. The goal is to keep this
repo up-to-date with the original one, and extend it with new features were
possible.

The following features have been added to this fork:

- **preview window**: a preview window can be enabled that shows the content of
  the tmux buffer. The selected fzf line will be highlighted in the preview
  window. The preview window is disabled by default, and can be enabled by
  setting:

  ```tmux
  set -g @fzf-url-fzf-preview true
  ```

  Note that it may be desirable to set a custom sort command, as is explained
  below.

- **sort command**: after searching the tmux buffer, the results are presented
  in the following format: `line_number:match`. Here `line_number` is the line
  number in the tmux buffer, and `match` is the match. Before passing them to
  fzf, any duplicates are removed by using the `sort -u` command. Next, they are
  fed to a command that can be specified by the user. By default, the command is

  ```tmux
  set -g @fzf-url-sort-cmd "sort -u -t: -k2"
  ```

  which means that only the `match` part is used for sorting this time, instead
  of the entire line. It will remove any duplicates, even if the `line_number`
  part is different. This will limit the number of lines that are shown in the
  fzf window, and will make it easier to find the desired line. However, when
  using the preview window, it may be desirable to display all the lines, such
  that you can scroll through them. In this case, the following may be more
  suitable:

  ```tmux
  set -g @fzf-url-sort-cmd "sort -n"
  ```

  This will only sort the `line_number` part, and will not remove any
  duplicates.

Below you will find the original README of the repository.

# tmux-fzf-url

[![TPM](https://img.shields.io/badge/tpm--support-true-blue)](https://github.com/tmux-plugins/tpm)
[![Awesome](https://img.shields.io/badge/Awesome-tmux-d07cd0?logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAABVklEQVRIS+3VvWpVURDF8d9CRAJapBAfwWCt+FEJthIUUcEm2NgIYiOxsrCwULCwktjYKSgYLfQF1JjCNvoMNhYRCwOO7HAiVw055yoBizvN3nBmrf8+M7PZsc2RbfY3AfRWeNMSVdUlHEzS1t6oqvt4n+TB78l/AKpqHrdwLcndXndU1WXcw50k10c1PwFV1fa3cQVzSR4PMd/IqaoLeIj2N1eTfG/f1gFVtQMLOI+zSV6NYz4COYFneIGLSdZSVbvwCMdxMsnbvzEfgRzCSyzjXAO8xlHcxMq/mI9oD+AGlhqgxjD93OVOD9TUuICdXd++/VeAVewecKKv2NPlfcHUAM1qK9FTnBmQvJjkdDfWzzE7QPOkAfZiEce2ECzhVJJPHWAfGuTwFpo365pO0NYjmEFr5Eas4SPeJfll2rqb38Z7/yaaD+0eNM3kPejt86REvSX6AamgdXkgoxLxAAAAAElFTkSuQmCC)](https://github.com/rothgar/awesome-tmux)
[![License](https://img.shields.io/badge/License-MIT-brightgreen.svg)](https://wfxr.mit-license.org/2018)

A tmux plugin for opening urls from browser quickly without mouse.

![screenshot](https://raw.githubusercontent.com/wfxr/i/master/tmux-fzf-url.gif)

### 📥 Installation

Prerequisites:

- [`fzf`](https://github.com/junegunn/fzf)
- [`bash`](https://www.gnu.org/software/bash/)

**Install using [TPM](https://github.com/tmux-plugins/tpm)**

Add this line to your tmux config file, then hit `prefix + I`:

```tmux
set -g @plugin 'wfxr/tmux-fzf-url'
```

**Install manually**

Clone this repo somewhere and source `fzf-url.tmux` at the config file.

### 📝 Usage

The default key-binding is `u`(of course prefix hit is needed), it can be modified by
setting value to `@fzf-url-bind` at the tmux config like this:

```tmux
set -g @fzf-url-bind 'x'
```

You can also extend the capture groups by defining `@fzf-url-extra-filter`:

```tmux
# simple example for capturing files like 'abc.txt'
set -g @fzf-url-extra-filter 'grep -oE "\b[a-zA-Z]+\.txt\b"'
```

The plugin default captures the current screen. You can set `history_limit` to capture
the scrollback history:

```tmux
set -g @fzf-url-history-limit '2000'
```

You can use custom fzf options by defining `@fzf-url-fzf-options`.

```
# open tmux-fzf-url in a tmux v3.2+ popup
set -g @fzf-url-fzf-options '-w 50% -h 50% --multi -0 --no-preview --no-border'
```

By default, `tmux-fzf-url` will use `xdg-open`, `open`, or the `BROWSER`
environment variable to open the url, respectively. If you want to use a
different command, you can set `@fzf-url-open` to the command you want to use.

```tmux
set -g @fzf-url-open "firefox"
```

### 💡 Tips

- You can mark multiple urls and open them at once.
- The tmux theme showed in the screenshot is [tmux-power](https://github.com/wfxr/tmux-power).

### 🔗 Other plugins

- [tmux-power](https://github.com/wfxr/tmux-power)
- [tmux-net-speed](https://github.com/wfxr/tmux-net-speed)

### 📃 License

[MIT](https://wfxr.mit-license.org/2018) (c) Wenxuan Zhang
