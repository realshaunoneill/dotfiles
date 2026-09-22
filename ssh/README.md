# SSH config

`~/.ssh/config` is three lines of `Include`. Every host block lives in a numbered fragment under
`~/.ssh/config.d/`, and the number **is** the precedence order.

Install or refresh it all with `ssh-setup` (`zSetupSsh` in `alias/functions.sh`). It is
idempotent, backs up whatever it replaces, and is safe to re-run.

## Where each fragment comes from

| Fragment | Source | Installed as | Why there |
| --- | --- | --- | --- |
| `config` | `dotfiles/ssh/config` | copy | thin, nothing but `Include` |
| `10-github.conf` | `dotfiles/ssh/config.d/` | copy | no secrets, portable |
| `20-homelab.conf` | **a private ops repo** | **symlink** | it *is* a host inventory — addresses, users, which boxes are password-only. That repo is private; this one is public |
| `30-work.conf` | **nowhere** | hand-written, local | work bastion FQDNs must not be published. Rebuild steps are in the private runbook, not in any repo |
| `90-1password.conf` | `dotfiles/ssh/config.d/` | copy, **macOS only** | the agent socket path is a macOS group container; on Linux it would dangle on every host |
| `99-defaults.conf` | `dotfiles/ssh/config.d/` | copy | the single `Host *` block |
| `agent.toml` | `dotfiles/ssh/agent.toml` | copy to `~/.config/1Password/ssh/` | restricts which 1Password keys the agent offers |

## The two invariants

**1. Specific blocks first, `Host *` last.** OpenSSH keeps the **first** value it obtains for
each single-valued keyword, and `Include` is spliced in where it appears. So a setting in
`99-defaults.conf` is only a *fallback*, and an earlier fragment is the *exception*. That is the
whole mechanism — it is how `30-work.conf` keeps `StrictHostKeyChecking no` for the work hosts
while everything else gets `accept-new`, without a second `Host *` block.

**2. Never put `IdentityFile` in a `Host *` block.** It does not behave like the others: it
accumulates, and one configured value **replaces** OpenSSH's built-in default list.

```
$ ssh -G somehost | grep ^identityfile
identityfile ~/.ssh/id_rsa          <- the built-in DEFAULT list
identityfile ~/.ssh/id_ecdsa
identityfile ~/.ssh/id_ed25519 ...

$ ssh -o 'IdentityFile=~/.ssh/id_rsa.pub' -G somehost | grep ^identityfile
identityfile ~/.ssh/id_rsa.pub      <- id_rsa is GONE
```

The work bastions in `30-work.conf` have no explicit `IdentityFile`. They work *only* because
`id_rsa` happens to be first in that default list, so a global `IdentityFile` would break all
work access. Same class of keyword: `CertificateFile`, `LocalForward`/`RemoteForward`/`DynamicForward`,
`SendEnv`/`SetEnv`.

## Which agent serves which host

`IdentityAgent` is single-valued, so it is set per group rather than globally:

| Hosts | `IdentityAgent` | Key |
| --- | --- | --- |
| personal — private hosts, `github.com-personal` | 1Password socket | ed25519, never on disk |
| work — bastions, `github.com` | `SSH_AUTH_SOCK` (= today's default agent) | `~/.ssh/id_rsa`, from disk |
| password-only hosts | `none` + `PubkeyAuthentication no` | none |

`IdentityAgent none` on hosts that only accept a password stops a pointless biometric prompt
firing *before* every password prompt.

## Copy vs symlink — deliberate, not inconsistent

`zSetupClaude` symlinks into `$ZDOTDIR`; the dotfiles SSH fragments are **copied** instead,
because `zReinstall`/`install.sh` does `rm -rf "$HOME/.zsh"` before re-cloning — so a symlinked
fragment would dangle for the duration of a clone.

**Measured, so the risk is not overstated: a dangling `Include` target is NOT fatal.** With the
symlink pointing at a missing file, `ssh -G` still exits 0, work hosts resolve normally and
`ssh -T git@github.com` authenticates fine; the only effect is that the missing fragment's
aliases silently stop resolving (`ssh -G <alias>` returns the bare name and your local
username). So this is a correctness-of-aliases concern, not an availability one — but coupling
"do my aliases exist" to "is the dotfiles checkout mid-reclone" is still a bad trade for two
near-static files, and copying matches the existing `cp -r "$ZDOTDIR/.config"` idiom in `.zshrc`.

The silent-degradation mode is the reason it matters: a vanished alias resolves to
`<alias>` as a hostname under your own username, which fails with a confusing DNS error rather
than anything pointing at the config.

**The cost: re-run `ssh-setup` after any dotfiles update that touches `ssh/`.**

The private fragment *is* symlinked, because it is actively edited there and a silently stale
copy is the worse failure. `~/.ssh/config` is a copy for a third reason — it is the file you hand-edit when
ssh is broken, and that edit must not become a dotfiles diff or get reverted by the next
`zupdate`.

## Two checkouts

`~/Personal/dotfiles` is the dev copy. The shell loads `~/.zsh`, a **separate** checkout pulled
from GitHub master. Editing the dev copy does not affect the running shell. The order is:

```sh
# edit ~/Personal/dotfiles, then
git -C ~/Personal/dotfiles commit -am '...' && git -C ~/Personal/dotfiles push
zupdate        # git -C $ZDOTDIR pull
ssh-setup
```

Run `ssh-setup` before the pull and it will just report the fragments as missing.

The private fragment's symlink points at that repo's **main** checkout, so editing it on a
branch in a worktree has no effect on `~/.ssh` until the change lands there.

## Verifying

```sh
# Which files are read, in what order, and which blocks apply. Does not connect.
ssh -Gv <host> 2>&1 | grep -E 'Reading configuration|Applying options'

# Regression guard: exactly one source of `Host *` from user config
ssh -Gv <host> 2>&1 | grep 'Applying options for \*'

# Resolved values for a host
ssh -G <host> | grep -iE '^(user|hostname|identityagent|identitiesonly|identityfile)'

# What 1Password will actually offer (bare `ssh-add -l` asks Apple's agent instead)
SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" ssh-add -l
```

Note: `-o BatchMode=yes` failing does **not** prove there is no access — it only means batch
mode declined to try a password. And `BatchMode=yes` does **not** suppress 1Password's approval
dialog, so a check that seems to hang may just be waiting on a fingerprint.

The full runbook — including how to rebuild the untracked `30-work.conf`, which exists in no
repo — is kept in a private notes vault, not here.
