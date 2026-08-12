# slurm-cd (scd)

A small Bash utility for jumping to the working directory of a pending or running Slurm job.

## Requirements

* Bash
* Slurm

## User Installation

Clone the repository

Add the following to your `~/.bashrc`:

```bash
source ~/scd/scd.sh
```

Then reload your shell:

```bash
source ~/.bashrc
```

## HPC System-Wide Installation

To make `scd` available to all users on systems that load `/etc/profile.d/*.sh`:

```bash
sudo cp scd.sh /etc/profile.d/scd.sh
sudo chown root:root /etc/profile.d/scd.sh
sudo chmod 0644 /etc/profile.d/scd.sh
```

Users will receive `scd` on their next login. To load it immediately:

```bash
source /etc/profile.d/scd.sh
```

## Usage

```bash
scd JOBID
```

Print the working directory without changing directory:

```bash
scd -p JOBID
scd --print JOBID
```

Show help:

```bash
scd --help
```

Works with any job available through `scontrol`, including running and pending jobs.


Use `TAB` after `scd` to complete job IDs for RUNNING and PENDING jobs currently visible through Slurm:

```bash
scd <TAB>
scd 11<TAB>
scd -p <TAB>
```

Completion uses `squeue`, which is optional. If it is unavailable, normal `scd JOBID` functionality still works.

## Notes

`scd` uses the `WorkDir` reported by Slurm. Normal filesystem permissions still apply.

The script must be sourced rather than executed because `scd` needs to change the current shell's working directory.
